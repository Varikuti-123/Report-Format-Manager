page 70100 "RSF Report Format List"
{
    Caption = 'Report Format Manager';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "RSF Report Format Setup";
    SourceTableView = sorting("Entry No.");
    CardPageId = "RSF Report Format Card";
    DelayedInsert = true;
    Editable = true;
    RefreshOnActivate = true;

    layout
    {
        area(Content)
        {
            repeater(ReportList)
            {
                field(Favorite; Rec.Favorite)
                {
                    Caption = '★';
                    ToolTip = 'Mark this report as a Favorite for quick access.';
                    ApplicationArea = All;
                }
                field("Report ID"; Rec."Report ID")
                {
                    Caption = 'Report ID';
                    ToolTip = 'The object ID of the report. Select from the list to auto-populate the name.';
                    ApplicationArea = All;
                }
                field("Report Name"; Rec."Report Name")
                {
                    Caption = 'Report Name';
                    ToolTip = 'The name of the report, auto-populated when Report ID is selected.';
                    ApplicationArea = All;
                }
                field("Output Format"; Rec."Output Format")
                {
                    Caption = 'Output Format';
                    ToolTip = 'The file format used when downloading or emailing this report (PDF, Excel, Word, HTML, XML).';
                    ApplicationArea = All;
                }
                field(Category; Rec.Category)
                {
                    Caption = 'Category';
                    ToolTip = 'An optional category for grouping reports (e.g., Sales, Finance, Inventory).';
                    ApplicationArea = All;
                }
                field("Log Execution"; Rec."Log Execution")
                {
                    Caption = 'Log';
                    ToolTip = 'When enabled, every execution of this report is recorded in the Execution Log. When disabled (default), no logging occurs and there is zero overhead.';
                    ApplicationArea = All;
                }
                field("Run Count"; Rec."Run Count")
                {
                    Caption = 'Runs';
                    ToolTip = 'Total number of times this report has been executed.';
                    ApplicationArea = All;
                }
                field("Last Run DateTime"; Rec."Last Run DateTime")
                {
                    Caption = 'Last Run';
                    ToolTip = 'The date and time this report was last executed.';
                    ApplicationArea = All;
                }
            }
        }
        area(FactBoxes)
        {
            part(ReportStatsFactBox; "RSF Report Stats FactBox")
            {
                Caption = 'Report Status';
                SubPageLink = "Entry No." = field("Entry No.");
                ApplicationArea = All;
            }
            systempart(Notes; Notes)
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DownloadReport)
            {
                Caption = 'Download';
                ToolTip = 'Run the report request page, generate the file in the selected format, and download it to your browser.';
                Image = Download;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ApplicationArea = All;

                trigger OnAction()
                var
                    ReportEngine: Codeunit "RSF Report Engine";
                begin
                    ReportEngine.RunAndDownload(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(EmailReport)
            {
                Caption = 'Email';
                ToolTip = 'Run the report request page, generate the file, and open the BC email editor with the file auto-attached and defaults pre-filled.';
                Image = SendMail;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ApplicationArea = All;

                trigger OnAction()
                var
                    ReportEngine: Codeunit "RSF Report Engine";
                begin
                    ReportEngine.RunAndEmail(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(PreviewReport)
            {
                Caption = 'Preview';
                ToolTip = 'Open the report using the standard Business Central print preview.';
                Image = ViewDetails;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ApplicationArea = All;

                trigger OnAction()
                var
                    ReportEngine: Codeunit "RSF Report Engine";
                begin
                    ReportEngine.RunPreview(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(ToggleFavorite)
            {
                Caption = 'Toggle Favorite';
                ToolTip = 'Mark or unmark this report as a Favorite.';
                Image = ChangeStatus;
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.Favorite := not Rec.Favorite;
                    Rec.Modify(true);
                    CurrPage.Update(false);
                end;
            }
            action(ToggleLogging)
            {
                Caption = 'Toggle Logging';
                ToolTip = 'Enable or disable execution logging for this report. When disabled, no log entries are created and there is zero overhead.';
                Image = Log;
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec."Log Execution" := not Rec."Log Execution";
                    Rec.Modify(true);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Navigation)
        {
            action(ViewLog)
            {
                Caption = 'View Execution Log';
                ToolTip = 'View the execution log entries for this report.';
                Image = Log;
                ApplicationArea = All;
                RunObject = page "RSF Execution Log List";
                RunPageLink = "Setup Entry No." = field("Entry No.");
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.FilterGroup(2);
        Rec.SetRange("User ID", UserId());
        Rec.FilterGroup(0);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."User ID" := CopyStr(UserId(), 1, MaxStrLen(Rec."User ID"));
    end;
}