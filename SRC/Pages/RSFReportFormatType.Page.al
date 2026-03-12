page 70101 "RSF Report Format Card"
{
    Caption = 'Report Format Card';
    PageType = Card;
    SourceTable = "RSF Report Format Setup";
    RefreshOnActivate = true;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("Entry No."; Rec."Entry No.")
                {
                    Caption = 'Entry No.';
                    ToolTip = 'The unique entry number for this report configuration.';
                    ApplicationArea = All;
                    Editable = false;
                }
                field("User ID"; Rec."User ID")
                {
                    Caption = 'User ID';
                    ToolTip = 'The user who owns this report configuration. Automatically set to the current user.';
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Report ID"; Rec."Report ID")
                {
                    Caption = 'Report ID';
                    ToolTip = 'Select the Report ID from the list. The Report Name will auto-populate.';
                    ApplicationArea = All;
                }
                field("Report Name"; Rec."Report Name")
                {
                    Caption = 'Report Name';
                    ToolTip = 'The name of the report, auto-populated from the Report ID.';
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Output Format"; Rec."Output Format")
                {
                    Caption = 'Output Format';
                    ToolTip = 'Choose the output format: PDF, Excel, Word, HTML, or XML.';
                    ApplicationArea = All;
                }
                field(Favorite; Rec.Favorite)
                {
                    Caption = 'Favorite';
                    ToolTip = 'Mark this report as a Favorite for quick access in the list.';
                    ApplicationArea = All;
                }
                field(Category; Rec.Category)
                {
                    Caption = 'Category';
                    ToolTip = 'Assign an optional category for grouping (e.g., Sales, Finance).';
                    ApplicationArea = All;
                }
                field("Log Execution"; Rec."Log Execution")
                {
                    Caption = 'Log Execution';
                    ToolTip = 'Enable to record every execution in the Execution Log with full details. Disable (default) for zero logging overhead.';
                    ApplicationArea = All;
                }
            }
            group(EmailDefaults)
            {
                Caption = 'Email Defaults';

                field("Email To"; Rec."Email To")
                {
                    Caption = 'Email To';
                    ToolTip = 'Default recipient email address. Pre-filled when you click Email. You can change it in the email editor.';
                    ApplicationArea = All;
                }
                field("Email CC"; Rec."Email CC")
                {
                    Caption = 'Email CC';
                    ToolTip = 'Default CC addresses, separated by semicolons. Pre-filled when you click Email.';
                    ApplicationArea = All;
                }
                field("Email Subject"; Rec."Email Subject")
                {
                    Caption = 'Email Subject';
                    ToolTip = 'Default email subject. If blank, the report name will be used automatically.';
                    ApplicationArea = All;
                }
                field("Email Body"; Rec."Email Body")
                {
                    Caption = 'Email Body';
                    ToolTip = 'Default email body (HTML supported). If blank, a professional default message is generated.';
                    ApplicationArea = All;
                    MultiLine = true;
                }
            }
            group(Statistics)
            {
                Caption = 'Statistics';

                field("Run Count"; Rec."Run Count")
                {
                    Caption = 'Run Count';
                    ToolTip = 'Total number of times this report has been executed.';
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Last Run DateTime"; Rec."Last Run DateTime")
                {
                    Caption = 'Last Run DateTime';
                    ToolTip = 'The date and time of the last execution.';
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
        area(FactBoxes)
        {
            part(CardFactBox; "RSF Report Stats FactBox")
            {
                Caption = 'Report Status';
                SubPageLink = "Entry No." = field("Entry No.");
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
                ToolTip = 'Run the report and download the file to your browser.';
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
                ToolTip = 'Run the report and open the email editor with the file auto-attached.';
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
                ToolTip = 'Open the report in standard BC print preview.';
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

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."User ID" := CopyStr(UserId(), 1, MaxStrLen(Rec."User ID"));
    end;
}