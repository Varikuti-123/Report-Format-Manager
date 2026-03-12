page 70102 "RSF Execution Log List"
{
    Caption = 'Execution Log';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = History;
    SourceTable = "RSF Execution Log";
    SourceTableView = sorting("Entry No.") order(descending);
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = true;
    RefreshOnActivate = true;

    layout
    {
        area(Content)
        {
            repeater(LogEntries)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    Caption = 'Entry No.';
                    ToolTip = 'The unique log entry number.';
                    ApplicationArea = All;
                }
                field("Execution DateTime"; Rec."Execution DateTime")
                {
                    Caption = 'Date/Time';
                    ToolTip = 'The date and time this execution occurred.';
                    ApplicationArea = All;
                }
                field("Report ID"; Rec."Report ID")
                {
                    Caption = 'Report ID';
                    ToolTip = 'The ID of the report that was executed.';
                    ApplicationArea = All;
                }
                field("Report Name"; Rec."Report Name")
                {
                    Caption = 'Report Name';
                    ToolTip = 'The name of the report that was executed.';
                    ApplicationArea = All;
                }
                field("Output Format"; Rec."Output Format")
                {
                    Caption = 'Format';
                    ToolTip = 'The output format used for this execution.';
                    ApplicationArea = All;
                }
                field("Action Type"; Rec."Action Type")
                {
                    Caption = 'Action';
                    ToolTip = 'The action performed: Download, Email, or Preview.';
                    ApplicationArea = All;
                }
                field(Status; Rec.Status)
                {
                    Caption = 'Status';
                    ToolTip = 'The result of the execution: Success, Failed, or Cancelled.';
                    ApplicationArea = All;
                    StyleExpr = StatusStyle;
                }
                field("User ID"; Rec."User ID")
                {
                    Caption = 'User ID';
                    ToolTip = 'The user who executed this report.';
                    ApplicationArea = All;
                }
                field("File Name"; Rec."File Name")
                {
                    Caption = 'File Name';
                    ToolTip = 'The generated file name.';
                    ApplicationArea = All;
                }
                field("Duration (ms)"; Rec."Duration (ms)")
                {
                    Caption = 'Duration (ms)';
                    ToolTip = 'How long the report generation took in milliseconds.';
                    ApplicationArea = All;
                }
                field("Email Sent To"; Rec."Email Sent To")
                {
                    Caption = 'Email Sent To';
                    ToolTip = 'The email address the report was sent to (for Email actions).';
                    ApplicationArea = All;
                }
                field("Error Message"; Rec."Error Message")
                {
                    Caption = 'Error Message';
                    ToolTip = 'The error message if the execution failed.';
                    ApplicationArea = All;
                }
                field("Session ID"; Rec."Session ID")
                {
                    Caption = 'Session ID';
                    ToolTip = 'The BC session ID during execution.';
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ShowMyLogs)
            {
                Caption = 'Show My Logs';
                ToolTip = 'Filter to show only your execution log entries.';
                Image = FilterLines;
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.SetRange("User ID", UserId());
                    CurrPage.Update(false);
                end;
            }
            action(ShowAllLogs)
            {
                Caption = 'Show All Logs';
                ToolTip = 'Remove the user filter to show all execution log entries.';
                Image = ClearFilter;
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Rec.SetRange("User ID");
                    CurrPage.Update(false);
                end;
            }
            action(ClearEntries)
            {
                Caption = 'Clear Entries';
                ToolTip = 'Delete all currently visible log entries. Use filters first if you want to clear selectively.';
                Image = Delete;
                ApplicationArea = All;

                trigger OnAction()
                begin
                    if not Confirm(ClearEntriesQst) then
                        exit;
                    Rec.DeleteAll(true);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        case Rec.Status of
            "RSF Execution Status"::Success:
                StatusStyle := 'Favorable';
            "RSF Execution Status"::Failed:
                StatusStyle := 'Unfavorable';
            "RSF Execution Status"::Cancelled:
                StatusStyle := 'Ambiguous';
            else
                StatusStyle := 'Standard';
        end;
    end;

    var
        StatusStyle: Text;
        ClearEntriesQst: Label 'Are you sure you want to delete all visible log entries? This cannot be undone.';
}