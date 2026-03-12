page 70103 "RSF Report Stats FactBox"
{
    Caption = 'Report Status';
    PageType = CardPart;
    SourceTable = "RSF Report Format Setup";
    RefreshOnActivate = true;

    layout
    {
        area(Content)
        {
            // ── STATUS SECTION ──
            group(StatusGroup)
            {
                Caption = 'Status';
                ShowCaption = true;

                field(OverallStatus; OverallStatusText)
                {
                    Caption = 'Configuration';
                    ToolTip = 'Shows whether this report is fully configured and ready to run.';
                    StyleExpr = OverallStatusStyle;
                    ApplicationArea = All;
                }
                field(ReportIdStatus; ReportIdStatusText)
                {
                    Caption = 'Report ID';
                    ToolTip = 'Shows whether a Report ID has been selected.';
                    StyleExpr = ReportIdStatusStyle;
                    ApplicationArea = All;
                }
                field(FormatStatus; FormatStatusText)
                {
                    Caption = 'Output Format';
                    ToolTip = 'Shows whether an Output Format has been selected.';
                    StyleExpr = FormatStatusStyle;
                    ApplicationArea = All;
                }
                field(LoggingStatus; LoggingStatusText)
                {
                    Caption = 'Logging';
                    ToolTip = 'Shows whether execution logging is enabled for this report.';
                    StyleExpr = LoggingStatusStyle;
                    ApplicationArea = All;
                }
            }

            // ── RUN STATISTICS SECTION (only when configured) ──
            group(StatsGroup)
            {
                Caption = 'Run Statistics';
                ShowCaption = true;
                Visible = IsFullyConfigured;

                field(TotalRuns; Rec."Run Count")
                {
                    Caption = 'Total Runs';
                    ToolTip = 'Total number of times this report has been executed.';
                    ApplicationArea = All;
                }
                field(LastRun; Rec."Last Run DateTime")
                {
                    Caption = 'Last Run';
                    ToolTip = 'Date and time of the last execution.';
                    ApplicationArea = All;
                }
                field(SuccessCount; SuccessCountValue)
                {
                    Caption = 'Successful';
                    ToolTip = 'Number of successful executions (from log).';
                    StyleExpr = 'Favorable';
                    ApplicationArea = All;
                    Visible = Rec."Log Execution";
                }
                field(FailedCount; FailedCountValue)
                {
                    Caption = 'Failed';
                    ToolTip = 'Number of failed executions (from log).';
                    StyleExpr = FailedCountStyle;
                    ApplicationArea = All;
                    Visible = Rec."Log Execution";
                }
            }

            // ── EMAIL DEFAULTS SECTION (only when configured) ──
            group(EmailGroup)
            {
                Caption = 'Email Defaults';
                ShowCaption = true;
                Visible = IsFullyConfigured;

                field(EmailToStatus; EmailToStatusText)
                {
                    Caption = 'To';
                    ToolTip = 'Shows the default Email To address configured for this report.';
                    StyleExpr = EmailToStatusStyle;
                    ApplicationArea = All;
                }
                field(EmailCCStatus; EmailCCStatusText)
                {
                    Caption = 'CC';
                    ToolTip = 'Shows the default CC addresses configured for this report.';
                    ApplicationArea = All;
                }
                field(EmailSubjectStatus; EmailSubjectStatusText)
                {
                    Caption = 'Subject';
                    ToolTip = 'Shows the default email subject configured for this report.';
                    ApplicationArea = All;
                }
            }

            // ── WHAT TO DO SECTION (only when incomplete) ──
            group(WhatToDoGroup)
            {
                Caption = 'What To Do';
                ShowCaption = true;
                Visible = not IsFullyConfigured;

                field(NextStep; NextStepText)
                {
                    Caption = 'Next Step';
                    ToolTip = 'Tells you what to configure next to make this report ready to run.';
                    StyleExpr = 'Ambiguous';
                    ApplicationArea = All;
                    MultiLine = true;
                }
            }

            // ── HOW TO USE SECTION (always visible) ──
            group(HowToUseGroup)
            {
                Caption = 'How To Use';
                ShowCaption = true;

                field(HowToUse; HowToUseText)
                {
                    Caption = 'Instructions';
                    ToolTip = 'Step-by-step instructions for using Report Format Manager.';
                    ApplicationArea = All;
                    MultiLine = true;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CalculateFactBoxValues();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CalculateFactBoxValues();
    end;

    local procedure CalculateFactBoxValues()
    var
        ReportEngine: Codeunit "RSF Report Engine";
        HasReportId: Boolean;
        HasFormat: Boolean;
    begin
        HasReportId := Rec."Report ID" <> 0;
        HasFormat := Rec."Output Format" <> "RSF Output Format"::" ";
        IsFullyConfigured := HasReportId and HasFormat;

        // Report ID status
        if HasReportId then begin
            ReportIdStatusText := StrSubstNo('✅ %1 (%2)', Rec."Report Name", Rec."Report ID");
            ReportIdStatusStyle := 'Favorable';
        end else begin
            ReportIdStatusText := '❌ Not selected';
            ReportIdStatusStyle := 'Unfavorable';
        end;

        // Format status
        if HasFormat then begin
            FormatStatusText := StrSubstNo('✅ %1', Format(Rec."Output Format"));
            FormatStatusStyle := 'Favorable';
        end else begin
            FormatStatusText := '❌ Not selected';
            FormatStatusStyle := 'Unfavorable';
        end;

        // Overall status
        if IsFullyConfigured then begin
            OverallStatusText := '✅ Ready to run';
            OverallStatusStyle := 'Favorable';
        end else
            if (not HasReportId) and (not HasFormat) then begin
                OverallStatusText := '❌ Not configured';
                OverallStatusStyle := 'Unfavorable';
            end else
                if not HasFormat then begin
                    OverallStatusText := '❌ Format missing';
                    OverallStatusStyle := 'Unfavorable';
                end else begin
                    OverallStatusText := '❌ Report ID missing';
                    OverallStatusStyle := 'Unfavorable';
                end;

        // Logging status
        if Rec."Log Execution" then begin
            LoggingStatusText := '✅ Enabled';
            LoggingStatusStyle := 'Favorable';
        end else begin
            LoggingStatusText := 'Disabled';
            LoggingStatusStyle := 'Subordinate';
        end;

        // Run statistics from log
        if Rec."Log Execution" then begin
            SuccessCountValue := ReportEngine.GetSuccessCount(Rec."Entry No.");
            FailedCountValue := ReportEngine.GetFailedCount(Rec."Entry No.");
            if FailedCountValue > 0 then
                FailedCountStyle := 'Unfavorable'
            else
                FailedCountStyle := 'Subordinate';
        end else begin
            SuccessCountValue := 0;
            FailedCountValue := 0;
            FailedCountStyle := 'Subordinate';
        end;

        // Email defaults status
        if Rec."Email To" <> '' then begin
            EmailToStatusText := StrSubstNo('✅ %1', Rec."Email To");
            EmailToStatusStyle := 'Favorable';
        end else begin
            EmailToStatusText := '⚠ Not set — will be asked';
            EmailToStatusStyle := 'Ambiguous';
        end;

        if Rec."Email CC" <> '' then
            EmailCCStatusText := Rec."Email CC"
        else
            EmailCCStatusText := 'None';

        if Rec."Email Subject" <> '' then
            EmailSubjectStatusText := Rec."Email Subject"
        else
            EmailSubjectStatusText := 'Will use report name';

        // What To Do (next step)
        if (not HasReportId) and (not HasFormat) then
            NextStepText := 'Select a Report ID and choose an Output Format.'
        else
            if not HasReportId then
                NextStepText := 'Select a Report ID to continue.'
            else
                if not HasFormat then
                    NextStepText := 'Choose an Output Format.'
                else
                    NextStepText := '';

        // How To Use (permanent instructions)
        HowToUseText := '1. Select a Report ID from the list\' +
                         '2. Choose your Output Format\' +
                         '3. Click Download to save file\' +
                         '4. Click Email to send as attachment\' +
                         '5. Click Preview to open in BC\' +
                         '\' +
                         'Tip: Set email defaults on the Card page.\' +
                         'Tip: Enable Logging on Card for audit trail.';
    end;

    var
        IsFullyConfigured: Boolean;
        OverallStatusText: Text;
        OverallStatusStyle: Text;
        ReportIdStatusText: Text;
        ReportIdStatusStyle: Text;
        FormatStatusText: Text;
        FormatStatusStyle: Text;
        LoggingStatusText: Text;
        LoggingStatusStyle: Text;
        SuccessCountValue: Integer;
        FailedCountValue: Integer;
        FailedCountStyle: Text;
        EmailToStatusText: Text;
        EmailToStatusStyle: Text;
        EmailCCStatusText: Text;
        EmailSubjectStatusText: Text;
        NextStepText: Text;
        HowToUseText: Text;
}