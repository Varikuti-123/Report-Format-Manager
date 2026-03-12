pageextension 70100 "RSF Business Manager RC" extends "Business Manager Role Center"
{
    actions
    {
        addlast(Sections)
        {
            group(RSFReportFormatMgr)
            {
                Caption = 'Report Format Manager';

                action(RSFOpenReportFormatList)
                {
                    Caption = 'Report Format Manager';
                    ToolTip = 'Open Report Format Manager to manage your personal report favorites, download, email, or preview reports in your preferred format.';
                    Image = Report;
                    RunObject = page "RSF Report Format List";
                    ApplicationArea = All;
                }
                action(RSFOpenExecutionLog)
                {
                    Caption = 'Execution Log';
                    ToolTip = 'View the execution log of all report runs with logging enabled.';
                    Image = Log;
                    RunObject = page "RSF Execution Log List";
                    ApplicationArea = All;
                }
            }
        }
    }
}