table 70100 "RSF Report Format Setup"
{
    Caption = 'Report Format Setup';
    DataClassification = CustomerContent;
    LookupPageId = "RSF Report Format List";
    DrillDownPageId = "RSF Report Format List";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
            DataClassification = SystemMetadata;
        }
        field(2; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
        }
        field(3; "Report ID"; Integer)
        {
            Caption = 'Report ID';
            DataClassification = CustomerContent;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Report));

            trigger OnValidate()
            var
                AllObj: Record AllObjWithCaption;
            begin
                if Rec."Report ID" = 0 then begin
                    Rec."Report Name" := '';
                    exit;
                end;
                AllObj.SetRange("Object Type", AllObj."Object Type"::Report);
                AllObj.SetRange("Object ID", Rec."Report ID");
                if AllObj.FindFirst() then
                    Rec."Report Name" := CopyStr(AllObj."Object Caption", 1, MaxStrLen(Rec."Report Name"))
                else
                    Rec."Report Name" := '';
            end;
        }
        field(4; "Report Name"; Text[250])
        {
            Caption = 'Report Name';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(5; "Output Format"; Enum "RSF Output Format")
        {
            Caption = 'Output Format';
            DataClassification = CustomerContent;
        }
        field(6; Favorite; Boolean)
        {
            Caption = 'Favorite';
            DataClassification = CustomerContent;
        }
        field(7; Category; Text[50])
        {
            Caption = 'Category';
            DataClassification = CustomerContent;
        }
        field(8; "Log Execution"; Boolean)
        {
            Caption = 'Log Execution';
            DataClassification = CustomerContent;
            InitValue = false;
        }
        field(10; "Email To"; Text[250])
        {
            Caption = 'Email To';
            DataClassification = CustomerContent;
        }
        field(11; "Email CC"; Text[250])
        {
            Caption = 'Email CC';
            DataClassification = CustomerContent;
        }
        field(12; "Email Subject"; Text[250])
        {
            Caption = 'Email Subject';
            DataClassification = CustomerContent;
        }
        field(13; "Email Body"; Text[2048])
        {
            Caption = 'Email Body';
            DataClassification = CustomerContent;
        }
        field(20; "Run Count"; Integer)
        {
            Caption = 'Run Count';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(21; "Last Run DateTime"; DateTime)
        {
            Caption = 'Last Run DateTime';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(UserReport; "User ID", "Report ID", "Output Format")
        {
        }
        key(Favorite; "User ID", Favorite)
        {
        }
        key(Category; "User ID", Category)
        {
        }
    }

    trigger OnInsert()
    begin
        Rec."User ID" := CopyStr(UserId(), 1, MaxStrLen(Rec."User ID"));
    end;
}