table 80402 "Select Reports Formats"
{
    DataClassification = ToBeClassified;
    Caption = 'Report Selection Formats';

    fields
    {
        field(1; "Module"; Text[250])
        {
            Caption = 'Module';
        }

        field(2; "Report ID"; Integer)
        {
            DataClassification = ToBeClassified;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = Filter(Report));

            trigger OnValidate()
            var
                AllObjWithCaption: Record AllObjWithCaption;
            begin
                AllObjWithCaption.Reset();
                AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Report);
                AllObjWithCaption.SetRange("Object ID", "Report ID");

                if AllObjWithCaption.FindFirst() then
                    Description := AllObjWithCaption."Object Caption";

                // Auto-calculate indentation when Report ID is set
                CalculateIndentation();
            end;
        }

        field(3; "Run as"; Option)
        {
            OptionMembers = " ",PDF,Excel,Xml,Word,Html;
        }

        field(4; Description; Text[250])
        {
        }

        field(5; "user ID"; Code[50])
        {
            TableRelation = "User Setup"."User ID";
        }

        field(6; "Report Output"; BLOB)
        {
            Caption = 'Report Output';
        }

        field(7; Indentation; Integer)
        {
            Caption = 'Indentation Level';
            Editable = false; // Auto-calculated, not editable
        }

        // ✅ NEW: Line No for ordering
        field(8; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }

        // ✅ NEW: Is this a header row (Module header)?
        field(9; "Is Header"; Boolean)
        {
            Caption = 'Is Header';
        }

        // ✅ NEW: For Expand/Collapse
        field(10; "Expanded"; Boolean)
        {
            Caption = 'Expanded';
            InitValue = true;
        }

        // ✅ NEW: Parent Module reference
        field(11; "Parent Line No."; Integer)
        {
            Caption = 'Parent Line No.';
        }
    }

    keys
    {
        key(PK; "user ID", "Line No.")
        {
            Clustered = true;
        }
        key(SK1; Module, Indentation)
        {
        }
        key(SK2; "user ID", Module, "Line No.")
        {
        }
    }

    var
        FileDoesNotExistErr: Label 'The file does not exist.';

    // ✅ Auto-calculate Indentation
    procedure CalculateIndentation()
    begin
        if "Is Header" then
            Indentation := 0
        else
            Indentation := 1;
    end;

    // ✅ Get Next Line No
    procedure GetNextLineNo(): Integer
    var
        SelectReportsFormats: Record "Select Reports Formats";
    begin
        SelectReportsFormats.Reset();
        SelectReportsFormats.SetRange("user ID", "user ID");
        if SelectReportsFormats.FindLast() then
            exit(SelectReportsFormats."Line No." + 10000)
        else
            exit(10000);
    end;

    // ✅ Get Next Line No under a specific parent
    procedure GetNextLineNoUnderParent(ParentLineNo: Integer): Integer
    var
        SelectReportsFormats: Record "Select Reports Formats";
        ParentRec: Record "Select Reports Formats";
        NextLineNo: Integer;
    begin
        if ParentRec.Get("user ID", ParentLineNo) then begin
            SelectReportsFormats.Reset();
            SelectReportsFormats.SetRange("user ID", "user ID");
            SelectReportsFormats.SetRange("Parent Line No.", ParentLineNo);
            if SelectReportsFormats.FindLast() then
                NextLineNo := SelectReportsFormats."Line No." + 1000
            else
                NextLineNo := ParentLineNo + 1000;
        end else
            NextLineNo := GetNextLineNo();

        exit(NextLineNo);
    end;

    // ✅ Check if has children (for expand/collapse)
    procedure HasChildren(): Boolean
    var
        ChildRec: Record "Select Reports Formats";
    begin
        if not "Is Header" then
            exit(false);

        ChildRec.Reset();
        ChildRec.SetRange("user ID", "user ID");
        ChildRec.SetRange("Parent Line No.", "Line No.");
        exit(not ChildRec.IsEmpty());
    end;

    // ✅ Toggle Expand/Collapse
    procedure ToggleExpand()
    begin
        Expanded := not Expanded;
        Modify();
    end;

    procedure ShareWithOneDrive()
    var
        DocumentServiceMgt: Codeunit "Document Service Management";
        FileName: Text;
        FileExtension: Text;
        InStream: InStream;
    begin
        if "Report ID" = 0 then
            Error(FileDoesNotExistErr);

        CalcFields("Report Output");

        if not "Report Output".HasValue() then
            Error('No Report output Stored. Please run the Report first.');

        "Report Output".CreateInStream(InStream);

        FileName := GetFileNameWithoutExtension();
        FileExtension := Suffix();

        DocumentServiceMgt.ShareWithOneDrive(FileName, FileExtension, InStream);
    end;

    procedure OpenInOneDrive()
    var
        DocumentServiceMgt: Codeunit "Document Service Management";
        FileName: Text;
        FileExtension: Text;
        InStream: InStream;
    begin
        if Description = '' then
            Error(FileDoesNotExistErr);

        CalcFields("Report Output");
        "Report Output".CreateInStream(InStream);

        FileName := GetFileNameWithoutExtension();
        FileExtension := Suffix();

        DocumentServiceMgt.OpenInOneDrive(FileName, FileExtension, InStream);
    end;

    procedure GetFileNameWithoutExtension(): Text
    begin
        exit(DelChr(Description, '=', '/:*?"<>|'));
    end;

    procedure Suffix(): Text
    begin
        case "Run as" of
            "Run as"::PDF:
                exit('.pdf');
            "Run as"::Word:
                exit('.docx');
            "Run as"::Excel:
                exit('.xlsx');
            "Run as"::Html:
                exit('.html');
            "Run as"::Xml:
                exit('.xml');
        end;
    end;
}