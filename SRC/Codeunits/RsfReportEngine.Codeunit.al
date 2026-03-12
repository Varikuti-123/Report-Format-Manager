codeunit 70100 "RSF Report Engine"
{
    Caption = 'Report Engine';

    // ════════════════════════════════════════════════════════════
    // PUBLIC PROCEDURES
    // ════════════════════════════════════════════════════════════

    /// <summary>
    /// Runs the report request page, generates the file in the configured format,
    /// and downloads it to the user's browser.
    /// </summary>
    procedure RunAndDownload(var ReportSetup: Record "RSF Report Format Setup")
    var
        TempBlob: Codeunit "Temp Blob";
        RequestPageXml: Text;
        FileName: Text;
        InStr: InStream;
        StartTime: DateTime;
        DurationMs: Integer;
    begin
        ValidateSetup(ReportSetup);

        RequestPageXml := Report.RunRequestPage(ReportSetup."Report ID");
        if RequestPageXml = '' then begin
            LogIfEnabled(ReportSetup, "RSF Action Type"::Download, "RSF Execution Status"::Cancelled,
                         '', 0, '', 'User cancelled the request page.');
            exit;
        end;

        StartTime := CurrentDateTime();

        GenerateReport(ReportSetup, RequestPageXml, TempBlob);

        DurationMs := CurrentDateTime() - StartTime;

        FileName := BuildFileName(ReportSetup);
        TempBlob.CreateInStream(InStr);
        DownloadFromStream(InStr, 'Download Report', '', GetFileFilter(ReportSetup."Output Format"), FileName);

        UpdateRunStatistics(ReportSetup);

        LogIfEnabled(ReportSetup, "RSF Action Type"::Download, "RSF Execution Status"::Success,
                     FileName, DurationMs, '', '');

        OnAfterReportDownload(ReportSetup, FileName);
    end;

    /// <summary>
    /// Runs the report request page, generates the file, and opens the standard
    /// BC email editor with the file auto-attached and defaults pre-filled.
    /// </summary>
    procedure RunAndEmail(var ReportSetup: Record "RSF Report Format Setup")
    var
        TempBlob: Codeunit "Temp Blob";
        EmailMessage: Codeunit "Email Message";
        Email: Codeunit Email;
        RequestPageXml: Text;
        FileName: Text;
        InStr: InStream;
        SubjectText: Text;
        BodyText: Text;
        MimeType: Text;
        StartTime: DateTime;
        DurationMs: Integer;
        CCList: List of [Text];
        CCAddress: Text;
    begin
        ValidateSetup(ReportSetup);

        RequestPageXml := Report.RunRequestPage(ReportSetup."Report ID");
        if RequestPageXml = '' then begin
            LogIfEnabled(ReportSetup, "RSF Action Type"::Email, "RSF Execution Status"::Cancelled,
                         '', 0, '', 'User cancelled the request page.');
            exit;
        end;

        StartTime := CurrentDateTime();

        GenerateReport(ReportSetup, RequestPageXml, TempBlob);

        DurationMs := CurrentDateTime() - StartTime;

        FileName := BuildFileName(ReportSetup);
        SubjectText := GetEmailSubject(ReportSetup);
        BodyText := GetEmailBody(ReportSetup);
        MimeType := GetMimeType(ReportSetup."Output Format");

        // Create email message
        EmailMessage.Create(GetEmailTo(ReportSetup), SubjectText, BodyText, true);

        // Add CC recipients
        if ReportSetup."Email CC" <> '' then begin
            CCList := SplitAddresses(ReportSetup."Email CC");
            foreach CCAddress in CCList do
                if CCAddress <> '' then
                    EmailMessage.AddRecipient("Email Recipient Type"::Cc, CCAddress);
        end;

        // Attach the report file
        TempBlob.CreateInStream(InStr);
        EmailMessage.AddAttachment(FileName, MimeType, InStr);

        // Open in editor — user can modify To, CC, BCC, Subject, Body, add attachments, and Send
        Email.OpenInEditor(EmailMessage);

        UpdateRunStatistics(ReportSetup);

        LogIfEnabled(ReportSetup, "RSF Action Type"::Email, "RSF Execution Status"::Success,
                     FileName, DurationMs, GetEmailTo(ReportSetup), '');

        OnAfterReportEmail(ReportSetup, FileName, GetEmailTo(ReportSetup));
    end;

    /// <summary>
    /// Quick download shortcut — same as RunAndDownload but can be called from factbox or action.
    /// </summary>
    procedure QuickRun(var ReportSetup: Record "RSF Report Format Setup")
    begin
        RunAndDownload(ReportSetup);
    end;

    /// <summary>
    /// Quick email shortcut — same as RunAndEmail but can be called from factbox or action.
    /// </summary>
    procedure QuickEmail(var ReportSetup: Record "RSF Report Format Setup")
    begin
        RunAndEmail(ReportSetup);
    end;

    /// <summary>
    /// Opens the standard BC report preview (Print Preview).
    /// </summary>
    procedure RunPreview(var ReportSetup: Record "RSF Report Format Setup")
    var
        StartTime: DateTime;
        DurationMs: Integer;
    begin
        if ReportSetup."Report ID" = 0 then
            Error(ReportIdMissingErr);

        StartTime := CurrentDateTime();

        Report.Run(ReportSetup."Report ID");

        DurationMs := CurrentDateTime() - StartTime;

        UpdateRunStatistics(ReportSetup);

        LogIfEnabled(ReportSetup, "RSF Action Type"::Preview, "RSF Execution Status"::Success,
                     '', DurationMs, '', '');
    end;

    /// <summary>
    /// Returns the total successful execution count from the log for a given setup entry.
    /// </summary>
    procedure GetSuccessCount(SetupEntryNo: Integer): Integer
    var
        ExecLog: Record "RSF Execution Log";
    begin
        ExecLog.SetRange("Setup Entry No.", SetupEntryNo);
        ExecLog.SetRange(Status, "RSF Execution Status"::Success);
        exit(ExecLog.Count());
    end;

    /// <summary>
    /// Returns the total failed execution count from the log for a given setup entry.
    /// </summary>
    procedure GetFailedCount(SetupEntryNo: Integer): Integer
    var
        ExecLog: Record "RSF Execution Log";
    begin
        ExecLog.SetRange("Setup Entry No.", SetupEntryNo);
        ExecLog.SetRange(Status, "RSF Execution Status"::Failed);
        exit(ExecLog.Count());
    end;

    /// <summary>
    /// Returns the total execution count from the log for a given setup entry.
    /// </summary>
    procedure GetTotalLoggedRuns(SetupEntryNo: Integer): Integer
    var
        ExecLog: Record "RSF Execution Log";
    begin
        ExecLog.SetRange("Setup Entry No.", SetupEntryNo);
        exit(ExecLog.Count());
    end;

    // ════════════════════════════════════════════════════════════
    // INTERNAL HELPERS
    // ════════════════════════════════════════════════════════════

    local procedure ValidateSetup(ReportSetup: Record "RSF Report Format Setup")
    begin
        if ReportSetup."Report ID" = 0 then
            Error(ReportIdMissingErr);
        if ReportSetup."Output Format" = "RSF Output Format"::" " then
            Error(OutputFormatMissingErr);
    end;

    local procedure GenerateReport(ReportSetup: Record "RSF Report Format Setup"; RequestPageXml: Text; var TempBlob: Codeunit "Temp Blob")
    var
        OutStr: OutStream;
        ReportFormat: ReportFormat;
    begin
        TempBlob.CreateOutStream(OutStr);
        ReportFormat := ConvertToReportFormat(ReportSetup."Output Format");

        if not Report.SaveAs(ReportSetup."Report ID", RequestPageXml, ReportFormat, OutStr) then begin
            LogIfEnabled(ReportSetup, "RSF Action Type"::Download, "RSF Execution Status"::Failed,
                         '', 0, '', GetLastErrorText());
            Error(ReportGenerationFailedErr, ReportSetup."Report Name");
        end;
    end;

    local procedure ConvertToReportFormat(OutputFmt: Enum "RSF Output Format"): ReportFormat
    begin
        case OutputFmt of
            "RSF Output Format"::PDF:
                exit(ReportFormat::Pdf);
            "RSF Output Format"::Excel:
                exit(ReportFormat::Excel);
            "RSF Output Format"::Word:
                exit(ReportFormat::Word);
            "RSF Output Format"::HTML:
                exit(ReportFormat::Html);
            "RSF Output Format"::XML:
                exit(ReportFormat::Xml);
            else
                Error(OutputFormatMissingErr);
        end;
    end;

    local procedure BuildFileName(ReportSetup: Record "RSF Report Format Setup"): Text
    var
        CleanName: Text;
        Extension: Text;
    begin
        CleanName := CleanFileName(ReportSetup."Report Name");
        if CleanName = '' then
            CleanName := StrSubstNo('Report_%1', ReportSetup."Report ID");

        Extension := GetFileExtension(ReportSetup."Output Format");

        exit(StrSubstNo('%1_%2.%3', CleanName, Format(CurrentDateTime(), 0, '<Year4><Month,2><Day,2>_<Hours24,2><Minutes,2>'), Extension));
    end;

    local procedure CleanFileName(FileName: Text): Text
    var
        Result: Text;
        i: Integer;
        CurrentChar: Char;
        AllowedChars: Text;
    begin
        AllowedChars := 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_- ';
        Result := '';
        for i := 1 to StrLen(FileName) do begin
            CurrentChar := FileName[i];
            if StrPos(AllowedChars, Format(CurrentChar)) > 0 then
                Result := Result + Format(CurrentChar)
            else
                Result := Result + '_';
        end;
        exit(Result);
    end;

    local procedure GetFileExtension(OutputFmt: Enum "RSF Output Format"): Text
    begin
        case OutputFmt of
            "RSF Output Format"::PDF:
                exit('pdf');
            "RSF Output Format"::Excel:
                exit('xlsx');
            "RSF Output Format"::Word:
                exit('docx');
            "RSF Output Format"::HTML:
                exit('html');
            "RSF Output Format"::XML:
                exit('xml');
            else
                exit('pdf');
        end;
    end;

    local procedure GetMimeType(OutputFmt: Enum "RSF Output Format"): Text
    begin
        case OutputFmt of
            "RSF Output Format"::PDF:
                exit('application/pdf');
            "RSF Output Format"::Excel:
                exit('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
            "RSF Output Format"::Word:
                exit('application/vnd.openxmlformats-officedocument.wordprocessingml.document');
            "RSF Output Format"::HTML:
                exit('text/html');
            "RSF Output Format"::XML:
                exit('application/xml');
            else
                exit('application/octet-stream');
        end;
    end;

    local procedure GetFileFilter(OutputFmt: Enum "RSF Output Format"): Text
    begin
        case OutputFmt of
            "RSF Output Format"::PDF:
                exit('PDF Files (*.pdf)|*.pdf');
            "RSF Output Format"::Excel:
                exit('Excel Files (*.xlsx)|*.xlsx');
            "RSF Output Format"::Word:
                exit('Word Files (*.docx)|*.docx');
            "RSF Output Format"::HTML:
                exit('HTML Files (*.html)|*.html');
            "RSF Output Format"::XML:
                exit('XML Files (*.xml)|*.xml');
            else
                exit('All Files (*.*)|*.*');
        end;
    end;

    local procedure GetEmailTo(ReportSetup: Record "RSF Report Format Setup"): Text
    begin
        if ReportSetup."Email To" <> '' then
            exit(ReportSetup."Email To");
        exit('');
    end;

    local procedure GetEmailSubject(ReportSetup: Record "RSF Report Format Setup"): Text
    begin
        if ReportSetup."Email Subject" <> '' then
            exit(ReportSetup."Email Subject");
        exit(StrSubstNo('Report: %1', ReportSetup."Report Name"));
    end;

    local procedure GetEmailBody(ReportSetup: Record "RSF Report Format Setup"): Text
    begin
        if ReportSetup."Email Body" <> '' then
            exit(ReportSetup."Email Body");
        exit(StrSubstNo(
            '<p>Dear Recipient,</p><p>Please find attached the report <strong>%1</strong> generated on %2.</p><p>This report was generated automatically from Business Central.</p><p>Best regards</p>',
            ReportSetup."Report Name",
            Format(CurrentDateTime(), 0, '<Day,2>/<Month,2>/<Year4> <Hours24,2>:<Minutes,2>')
        ));
    end;

    local procedure SplitAddresses(Addresses: Text): List of [Text]
    var
        Result: List of [Text];
        Parts: List of [Text];
        Part: Text;
        TrimmedPart: Text;
    begin
        Parts := Addresses.Split(';');
        foreach Part in Parts do begin
            TrimmedPart := Part.Trim();
            if TrimmedPart <> '' then
                Result.Add(TrimmedPart);
        end;
        exit(Result);
    end;

    local procedure UpdateRunStatistics(var ReportSetup: Record "RSF Report Format Setup")
    begin
        ReportSetup."Run Count" += 1;
        ReportSetup."Last Run DateTime" := CurrentDateTime();
        ReportSetup.Modify(true);
    end;

    /// <summary>
    /// Logs execution ONLY if the "Log Execution" checkbox is ON for this specific report.
    /// If it is OFF, this procedure does absolutely nothing — zero overhead, no database write.
    /// </summary>
    local procedure LogIfEnabled(
        ReportSetup: Record "RSF Report Format Setup";
        ActionType: Enum "RSF Action Type";
        ExecStatus: Enum "RSF Execution Status";
        FileName: Text;
        DurationMs: Integer;
        EmailSentTo: Text;
        ErrorMsg: Text)
    var
        ExecLog: Record "RSF Execution Log";
    begin
        // ── THIS IS THE OPT-IN GATE ──
        // If logging is not enabled for this specific report, exit immediately.
        // No record is created, no database write occurs, zero performance overhead.
        if not ReportSetup."Log Execution" then
            exit;

        ExecLog.Init();
        ExecLog."Entry No." := 0; // AutoIncrement
        ExecLog."Setup Entry No." := ReportSetup."Entry No.";
        ExecLog."Report ID" := ReportSetup."Report ID";
        ExecLog."Report Name" := ReportSetup."Report Name";
        ExecLog."Output Format" := ReportSetup."Output Format";
        ExecLog."Action Type" := ActionType;
        ExecLog."User ID" := CopyStr(UserId(), 1, MaxStrLen(ExecLog."User ID"));
        ExecLog."Execution DateTime" := CurrentDateTime();
        ExecLog.Status := ExecStatus;
        ExecLog."Error Message" := CopyStr(ErrorMsg, 1, MaxStrLen(ExecLog."Error Message"));
        ExecLog."File Name" := CopyStr(FileName, 1, MaxStrLen(ExecLog."File Name"));
        ExecLog."Duration (ms)" := DurationMs;
        ExecLog."Session ID" := SessionId();
        ExecLog."Email Sent To" := CopyStr(EmailSentTo, 1, MaxStrLen(ExecLog."Email Sent To"));
        ExecLog.Insert(true);
    end;

    // ════════════════════════════════════════════════════════════
    // INTEGRATION EVENTS (for extensibility)
    // ════════════════════════════════════════════════════════════

    [IntegrationEvent(false, false)]
    local procedure OnAfterReportDownload(ReportSetup: Record "RSF Report Format Setup"; FileName: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReportEmail(ReportSetup: Record "RSF Report Format Setup"; FileName: Text; EmailTo: Text)
    begin
    end;

    // ════════════════════════════════════════════════════════════
    // ERROR LABELS
    // ════════════════════════════════════════════════════════════

    var
        ReportIdMissingErr: Label 'Please select a Report ID before running.';
        OutputFormatMissingErr: Label 'Please select an Output Format before running.';
        ReportGenerationFailedErr: Label 'Failed to generate report "%1". Please verify the report supports the selected format.', Comment = '%1 = Report Name';
}