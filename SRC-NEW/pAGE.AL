page 80404 "MAHE Run Report Format"
{
    Caption = 'Run Report Selection Format';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Select Reports Formats";
    DelayedInsert = true;
    SourceTableView = SORTING("user ID", "Line No.");

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                IndentationColumn = Rec.Indentation;
                IndentationControls = Module;
                ShowAsTree = true;

                field(ExpandCollapse; GetExpandCollapseIcon())
                {
                    Caption = ' ';
                    ApplicationArea = All;
                    Width = 2;
                    Editable = false;
                    StyleExpr = ExpandCollapseStyle;

                    trigger OnDrillDown()
                    begin
                        if Rec."Is Header" and Rec.HasChildren() then begin
                            Rec.ToggleExpand();
                            CurrPage.Update(false);
                        end;
                    end;
                }

                field(Module; Rec.Module)
                {
                    ApplicationArea = All;
                    StyleExpr = ModuleStyle;
                    Editable = Rec."Is Header";

                    trigger OnValidate()
                    begin
                        if Rec."Is Header" then
                            UpdateChildrenModuleName();
                    end;
                }

                field("Run"; GetRunText())
                {
                    Caption = 'Run';
                    Editable = false;
                    Style = StrongAccent;
                    ApplicationArea = All;

                    trigger OnDrillDown()
                    begin
                        if (Rec."Report ID" <> 0) and (Rec."Run as" <> Rec."Run as"::" ") then
                            GenerateReportWithRespectiveFormat(Rec."Report ID", Format(Rec."Run as").ToUpper());
                    end;
                }

                field("Report ID"; Rec."Report ID")
                {
                    ApplicationArea = All;
                    Editable = not Rec."Is Header";
                }

                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    StyleExpr = DescriptionStyle;
                }

                field("Run as"; Rec."Run as")
                {
                    ApplicationArea = All;
                    Editable = not Rec."Is Header";
                }

                field("Is Header"; Rec."Is Header")
                {
                    ApplicationArea = All;
                    Visible = false;
                }

                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                    Visible = false;
                }

                field(Indentation; Rec.Indentation)
                {
                    ApplicationArea = All;
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            // ✅ ADD NEW MODULE HEADER - FIXED
            action(AddModuleHeader)
            {
                ApplicationArea = All;
                Caption = 'Add Module Header';
                Image = Add;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    NewRec: Record "Select Reports Formats";
                    ModuleName: Text[250];
                begin
                    // ✅ Get Module name FIRST via input dialog
                    ModuleName := GetModuleNameInput();
                    if ModuleName = '' then
                        exit;

                    NewRec.Init();
                    NewRec."user ID" := UserId;
                    NewRec."Line No." := GetNextLineNo(UserId); // ✅ FIXED: Using local procedure
                    NewRec."Is Header" := true;
                    NewRec.Indentation := 0;
                    NewRec.Expanded := true;
                    NewRec.Module := ModuleName;
                    NewRec.Description := ModuleName;
                    NewRec.Insert(true);

                    CurrPage.Update(false);
                end;
            }

            // ✅ ADD REPORT UNDER CURRENT MODULE - FIXED
            action(AddReportUnderModule)
            {
                ApplicationArea = All;
                Caption = 'Add Report';
                Image = Report;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    NewRec: Record "Select Reports Formats";
                    ParentLineNo: Integer;
                    ParentModule: Text[250];
                begin
                    // Find parent module
                    GetParentInfo(ParentLineNo, ParentModule);

                    if ParentModule = '' then
                        Error('Please select a Module header or a report under a module first.');

                    NewRec.Init();
                    NewRec."user ID" := UserId;
                    NewRec."Line No." := GetNextLineNoUnderParent(UserId, ParentLineNo); // ✅ FIXED
                    NewRec."Is Header" := false;
                    NewRec.Indentation := 1;
                    NewRec.Module := ParentModule;
                    NewRec."Parent Line No." := ParentLineNo;
                    NewRec.Insert(true);

                    CurrPage.Update(false);
                    Rec.Get(NewRec."user ID", NewRec."Line No.");
                end;
            }

            action(ExpandAll)
            {
                ApplicationArea = All;
                Caption = 'Expand All';
                Image = ExplodeBOM;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    SelectReportsFormats: Record "Select Reports Formats";
                begin
                    SelectReportsFormats.Reset();
                    SelectReportsFormats.SetRange("user ID", UserId);
                    SelectReportsFormats.SetRange("Is Header", true);
                    SelectReportsFormats.ModifyAll(Expanded, true);
                    CurrPage.Update(false);
                end;
            }

            action(CollapseAll)
            {
                ApplicationArea = All;
                Caption = 'Collapse All';
                Image = CollapseDepositLines;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    SelectReportsFormats: Record "Select Reports Formats";
                begin
                    SelectReportsFormats.Reset();
                    SelectReportsFormats.SetRange("user ID", UserId);
                    SelectReportsFormats.SetRange("Is Header", true);
                    SelectReportsFormats.ModifyAll(Expanded, false);
                    CurrPage.Update(false);
                end;
            }

            action(OpenInOneDrive)
            {
                ApplicationArea = All;
                Caption = 'Open in OneDrive';
                Image = Cloud;
                Scope = Repeater;

                trigger OnAction()
                begin
                    Rec.OpenInOneDrive();
                end;
            }

            action(ShareWithOneDrive)
            {
                ApplicationArea = All;
                Caption = 'Share';
                Image = Share;
                Scope = Repeater;

                trigger OnAction()
                begin
                    Rec.ShareWithOneDrive();
                end;
            }
        }
    }

    var
        ModuleStyle: Text;
        DescriptionStyle: Text;
        ExpandCollapseStyle: Text;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        ParentLineNo: Integer;
        ParentModule: Text[250];
    begin
        Rec."user ID" := UserId;
        Rec."Line No." := GetNextLineNo(UserId); // ✅ FIXED

        // Auto-inherit from previous record
        if xRec."Line No." <> 0 then begin
            GetParentInfo(ParentLineNo, ParentModule);
            if ParentModule <> '' then begin
                Rec.Module := ParentModule;
                Rec."Parent Line No." := ParentLineNo;
                Rec."Is Header" := false;
                Rec.Indentation := 1;
            end;
        end;
    end;

    trigger OnAfterGetRecord()
    begin
        SetStyles();
    end;

    trigger OnOpenPage()
    var
        ReportID: Text;
        IntReportID: Integer;
        RunAs: Text;
    begin
        ReportID := Rec.GetFilter("Report ID");

        if ReportID <> '' then begin
            Evaluate(IntReportID, ReportID);
            RunAs := UpperCase(Rec.GetFilter("Run as"));
            GenerateReportWithRespectiveFormat(IntReportID, RunAs);
            Error('');
        end;

        Rec.SetRange("user ID", UserId);
    end;

    // ✅ FIXED: Local procedure to get next line no
    local procedure GetNextLineNo(UserIDFilter: Code[50]): Integer
    var
        SelectReportsFormats: Record "Select Reports Formats";
    begin
        SelectReportsFormats.Reset();
        SelectReportsFormats.SetRange("user ID", UserIDFilter);
        if SelectReportsFormats.FindLast() then
            exit(SelectReportsFormats."Line No." + 10000)
        else
            exit(10000);
    end;

    // ✅ FIXED: Local procedure to get next line no under parent
    local procedure GetNextLineNoUnderParent(UserIDFilter: Code[50]; ParentLineNo: Integer): Integer
    var
        SelectReportsFormats: Record "Select Reports Formats";
        NextLineNo: Integer;
    begin
        SelectReportsFormats.Reset();
        SelectReportsFormats.SetRange("user ID", UserIDFilter);
        SelectReportsFormats.SetRange("Parent Line No.", ParentLineNo);
        
        if SelectReportsFormats.FindLast() then
            NextLineNo := SelectReportsFormats."Line No." + 1000
        else
            NextLineNo := ParentLineNo + 1000;

        exit(NextLineNo);
    end;

    local procedure GetExpandCollapseIcon(): Text
    begin
        if not Rec."Is Header" then
            exit('');

        if not Rec.HasChildren() then
            exit('');

        if Rec.Expanded then
            exit('▼')
        else
            exit('▶');
    end;

    local procedure GetRunText(): Text
    begin
        if Rec."Is Header" then
            exit('')
        else
            exit('Run');
    end;

    local procedure SetStyles()
    begin
        if Rec."Is Header" then begin
            ModuleStyle := 'Strong';
            DescriptionStyle := 'Strong';
            ExpandCollapseStyle := 'Favorable';
        end else begin
            ModuleStyle := 'Standard';
            DescriptionStyle := 'Standard';
            ExpandCollapseStyle := 'Standard';
        end;
    end;

    local procedure GetParentInfo(var ParentLineNo: Integer; var ParentModule: Text[250])
    var
        ParentRec: Record "Select Reports Formats";
    begin
        ParentLineNo := 0;
        ParentModule := '';

        if Rec."Is Header" then begin
            ParentLineNo := Rec."Line No.";
            ParentModule := Rec.Module;
        end else if Rec."Parent Line No." <> 0 then begin
            if ParentRec.Get(Rec."user ID", Rec."Parent Line No.") then begin
                ParentLineNo := ParentRec."Line No.";
                ParentModule := ParentRec.Module;
            end;
        end else if Rec.Module <> '' then begin
            ParentRec.Reset();
            ParentRec.SetRange("user ID", UserId);
            ParentRec.SetRange("Is Header", true);
            ParentRec.SetRange(Module, Rec.Module);
            if ParentRec.FindFirst() then begin
                ParentLineNo := ParentRec."Line No.";
                ParentModule := ParentRec.Module;
            end;
        end;
    end;

    local procedure UpdateChildrenModuleName()
    var
        ChildRec: Record "Select Reports Formats";
    begin
        ChildRec.Reset();
        ChildRec.SetRange("user ID", Rec."user ID");
        ChildRec.SetRange("Parent Line No.", Rec."Line No.");
        ChildRec.ModifyAll(Module, Rec.Module);
    end;

    // ✅ FIXED: Simple input dialog for module name
    local procedure GetModuleNameInput(): Text[250]
    var
        ModuleName: Text[250];
        InputPage: Page "Module Name Input";
    begin
        ModuleName := '';
        
        // Option 1: Using a simple page
        if InputPage.RunModal() = Action::OK then
            ModuleName := InputPage.GetModuleName();
        
        exit(ModuleName);
    end;

    local procedure GenerateReportWithRespectiveFormat(IntReportID: Integer; RunAs: Text)
    var
        OStream: OutStream;
        Stream: InStream;
        TempBlob: Codeunit "Temp Blob";
        FullFileName: Text;
        XmlParameter: Text;
        GetReportCaption: Text;
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Report);
        AllObjWithCaption.SetRange("Object ID", IntReportID);

        if AllObjWithCaption.FindFirst() then
            GetReportCaption := AllObjWithCaption."Object Caption";

        XmlParameter := Report.RunRequestPage(IntReportID);

        if XmlParameter = '' then
            Error('');

        TempBlob.CreateOutStream(OStream);

        case RunAs of
            'PDF':
                begin
                    Report.SaveAs(IntReportID, XmlParameter, ReportFormat::Pdf, OStream);
                    FullFileName := GetReportCaption + '.pdf';
                end;
            'EXCEL':
                begin
                    Report.SaveAs(IntReportID, XmlParameter, ReportFormat::Excel, OStream);
                    FullFileName := GetReportCaption + '.xlsx';
                end;
            'WORD':
                begin
                    Report.SaveAs(IntReportID, XmlParameter, ReportFormat::Word, OStream);
                    FullFileName := GetReportCaption + '.docx';
                end;
            'HTML':
                begin
                    Report.SaveAs(IntReportID, XmlParameter, ReportFormat::Html, OStream);
                    FullFileName := GetReportCaption + '.html';
                end;
            'XML':
                begin
                    Report.SaveAs(IntReportID, XmlParameter, ReportFormat::Xml, OStream);
                    FullFileName := GetReportCaption + '.xml';
                end;
        end;

        TempBlob.CreateInStream(Stream);
        Rec."Report Output".CreateOutStream(OStream);
        CopyStream(OStream, Stream);

        Rec."Report Output".CreateInStream(Stream);
        DownloadFromStream(Stream, 'Download File', '', '', FullFileName);
    end;
}