codeunit 50900 MAHE_SFASTrailBalance
{
    //-------------------------Trail balance---------------------------//
    //------------------------SFAS Trail balance-----------------------//

    procedure UpdateApplicationFeePaymentDetails(var ApplicationFeeAPI: Record MAHESFASHFAS_TrialBalance; IsPreview: Boolean)
    var
        GenJourLine: Record "Gen. Journal Line";
        GLSetup: Record MAHEPaymentJournalSetup;
        GenBatchName: Record "Gen. Journal Batch";
        LineNo: Integer;
        NoSeries: Codeunit "No. Series";
        GenJournalNarration: Record "Gen. Journal Narration";
        LineNoNarration: Integer;
        TrialBalanceRec: Record MAHESFASHFAS_TrialBalance;
        DocumentNo: Code[20];
        PostingDate: Date;
        GenJnlPost: Codeunit "Gen. Jnl.-Post";
        TotalDebit: Decimal;
        TotalCredit: Decimal;
    begin
        // Validate if already processed
        if ApplicationFeeAPI."Payment Processed" then
            Error('This record is already processed. You cannot post it again.');

        GLSetup.Get();

        // Validate Posting Date
        Evaluate(PostingDate, ApplicationFeeAPI."Posting Date");
        if PostingDate = 0D then
            Error('Invalid Posting Date: %1. Please enter a valid date.', ApplicationFeeAPI."Posting Date");

        if PostingDate > WorkDate() then
            Error('Posting Date %1 cannot be greater than Work Date %2.', PostingDate, WorkDate());

        // Validate Group Code
        ValidateGroupCode(ApplicationFeeAPI."Group Code");

        // Validate Business Unit
        ValidateBusinessUnit(ApplicationFeeAPI."Business Unit");

        // Validate Department
        ValidateDepartment(ApplicationFeeAPI.Department);

        // Validate GL Account
        ValidateGLAccount(ApplicationFeeAPI."GL Account Code");

        // Filter records by Posting Date, Group, Business Unit, Department
        TrialBalanceRec.Reset();
        TrialBalanceRec.SetRange("Posting Date", ApplicationFeeAPI."Posting Date");
        TrialBalanceRec.SetRange("Group Code", ApplicationFeeAPI."Group Code");
        TrialBalanceRec.SetRange("Business Unit", ApplicationFeeAPI."Business Unit");
        TrialBalanceRec.SetRange(Department, ApplicationFeeAPI.Department);
        TrialBalanceRec.SetRange("Payment Processed", false);

        if TrialBalanceRec.IsEmpty then
            Error('No unprocessed records found for Posting Date: %1, Group: %2, Business Unit: %3, Department: %4',
                ApplicationFeeAPI."Posting Date",
                ApplicationFeeAPI."Group Code",
                ApplicationFeeAPI."Business Unit",
                ApplicationFeeAPI.Department);

        // Delete existing journal lines in the batch (clean slate)
        GenJourLine.Reset();
        GenJourLine.SetRange("Journal Template Name", GLSetup."SFAS_Application Fee Template");
        GenJourLine.SetRange("Journal Batch Name", GLSetup."SFAS_Application Fee Batch");
        if not IsPreview then
            GenJourLine.DeleteAll(true);

        // Get Document No. - Use Dummy for Preview
        if IsPreview then
            DocumentNo := 'PREVIEW-' + Format(CurrentDateTime, 0, '<Year4><Month,2><Day,2><Hours24><Minutes,2>')
        else begin
            if GenBatchName.Get(GLSetup."SFAS_Application Fee Template", GLSetup."SFAS_Application Fee Batch") then
                DocumentNo := NoSeries.GetNextNo(GenBatchName."No. Series", PostingDate);
        end;

        LineNo := 10000;
        TotalDebit := 0;
        TotalCredit := 0;

        // Create Journal Lines for all filtered records
        if TrialBalanceRec.FindSet() then
            repeat
                // Create Debit Line if Debit Amount > 0
                if TrialBalanceRec."Debit Amount" > 0 then begin
                    CreateJournalLine(
                        GLSetup."SFAS_Application Fee Template",
                        GLSetup."SFAS_Application Fee Batch",
                        LineNo,
                        DocumentNo,
                        PostingDate,
                        TrialBalanceRec."GL Account Code",
                        TrialBalanceRec."Debit Amount",
                        0,
                        TrialBalanceRec."Group Code",
                        TrialBalanceRec."Business Unit",
                        TrialBalanceRec.Department,
                        TrialBalanceRec."Line Narration"
                    );
                    TotalDebit += TrialBalanceRec."Debit Amount";
                    LineNo += 10000;
                end;

                // Create Credit Line if Credit Amount > 0
                if TrialBalanceRec."Credit Amount" > 0 then begin
                    CreateJournalLine(
                        GLSetup."SFAS_Application Fee Template",
                        GLSetup."SFAS_Application Fee Batch",
                        LineNo,
                        DocumentNo,
                        PostingDate,
                        TrialBalanceRec."GL Account Code",
                        0,
                        TrialBalanceRec."Credit Amount",
                        TrialBalanceRec."Group Code",
                        TrialBalanceRec."Business Unit",
                        TrialBalanceRec.Department,
                        TrialBalanceRec."Line Narration"
                    );
                    TotalCredit += TrialBalanceRec."Credit Amount";
                    LineNo += 10000;
                end;
            until TrialBalanceRec.Next() = 0;

        // Validate Debit = Credit
        if TotalDebit <> TotalCredit then
            Error('Total Debit Amount (%1) must equal Total Credit Amount (%2). Difference: %3',
                TotalDebit, TotalCredit, Abs(TotalDebit - TotalCredit));

        // Preview Mode - Just show the journal
        if IsPreview then begin
            GenJourLine.Reset();
            GenJourLine.SetRange("Journal Template Name", GLSetup."SFAS_Application Fee Template");
            GenJourLine.SetRange("Journal Batch Name", GLSetup."SFAS_Application Fee Batch");
            GenJourLine.SetRange("Document No.", DocumentNo);
            Message('Preview Mode: Document No. %1\Total Debit: %2\Total Credit: %3\Lines Created: %4',
                DocumentNo, TotalDebit, TotalCredit, GenJourLine.Count);
            PAGE.Run(PAGE::"Journal Voucher", GenJourLine);
            exit;
        end;

        // Post the Journal
        GenJourLine.Reset();
        GenJourLine.SetRange("Journal Template Name", GLSetup."SFAS_Application Fee Template");
        GenJourLine.SetRange("Journal Batch Name", GLSetup."SFAS_Application Fee Batch");
        GenJourLine.SetRange("Document No.", DocumentNo);

        if GenJourLine.FindFirst() then begin
            CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post", GenJourLine);

            // Mark all filtered records as processed ONLY after successful posting
            if TrialBalanceRec.FindSet() then
                repeat
                    TrialBalanceRec."Payment Processed" := true;
                    TrialBalanceRec."Posted Document No." := DocumentNo; // Add this field to track
                    TrialBalanceRec.Modify(true);
                until TrialBalanceRec.Next() = 0;

            Message('Journal Voucher posted successfully with Document No.: %1', DocumentNo);
        end;
    end;

    local procedure CreateJournalLine(
        TemplateName: Code[20];
        BatchName: Code[20];
        LineNo: Integer;
        DocumentNo: Code[20];
        PostingDate: Date;
        GLAccountNo: Code[20];
        DebitAmount: Decimal;
        CreditAmount: Decimal;
        GroupCode: Code[20];
        BusinessUnit: Code[20];
        Department: Code[20];
        Narration: Text[250]
    )
    var
        GenJourLine: Record "Gen. Journal Line";
        GenJournalNarration: Record "Gen. Journal Narration";
        LineNoNarration: Integer;
    begin
        GenJourLine.Init();
        GenJourLine."Journal Template Name" := TemplateName;
        GenJourLine."Journal Batch Name" := BatchName;
        GenJourLine."Line No." := LineNo;
        GenJourLine."Posting Date" := PostingDate;
        GenJourLine."Document No." := DocumentNo;
        GenJourLine.Validate("Account Type", GenJourLine."Account Type"::"G/L Account");
        GenJourLine.Validate("Account No.", GLAccountNo);

        if DebitAmount > 0 then
            GenJourLine.Validate("Debit Amount", DebitAmount);

        if CreditAmount > 0 then
            GenJourLine.Validate("Credit Amount", CreditAmount);

        // Set Shortcut Dimensions (Group, Business Unit, Department)
        GenJourLine.Validate("Shortcut Dimension 1 Code", GroupCode);
        GenJourLine.Validate("Shortcut Dimension 2 Code", BusinessUnit);
        // If Department is Dimension 3, use:
        // GenJourLine.ValidateShortcutDimCode(3, Department);

        GenJourLine.Insert(true);

        // Create Narration
        if Narration <> '' then begin
            GenJournalNarration.Reset();
            GenJournalNarration.SetRange("Journal Template Name", TemplateName);
            GenJournalNarration.SetRange("Journal Batch Name", BatchName);
            GenJournalNarration.SetRange("Document No.", DocumentNo);
            GenJournalNarration.SetRange("Gen. Journal Line No.", LineNo);
            if GenJournalNarration.FindLast() then
                LineNoNarration := GenJournalNarration."Line No." + 10000
            else
                LineNoNarration := 10000;

            GenJournalNarration.Init();
            GenJournalNarration."Journal Template Name" := TemplateName;
            GenJournalNarration."Journal Batch Name" := BatchName;
            GenJournalNarration."Document No." := DocumentNo;
            GenJournalNarration."Gen. Journal Line No." := LineNo;
            GenJournalNarration."Line No." := LineNoNarration;
            GenJournalNarration.Narration := Narration;
            GenJournalNarration.Insert();
        end;
    end;

    local procedure ValidateGroupCode(GroupCode: Code[20])
    var
        DimensionValue: Record "Dimension Value";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if GroupCode = '' then
            Error('Group Code cannot be empty.');

        GeneralLedgerSetup.Get();
        DimensionValue.Reset();
        DimensionValue.SetRange("Dimension Code", GeneralLedgerSetup."Global Dimension 1 Code");
        DimensionValue.SetRange(Code, GroupCode);
        if not DimensionValue.FindFirst() then
            Error('Invalid Group Code: %1. Please select a valid Group from Dimension Values.', GroupCode);

        if DimensionValue.Blocked then
            Error('Group Code %1 is blocked and cannot be used.', GroupCode);
    end;

    local procedure ValidateBusinessUnit(BusinessUnit: Code[20])
    var
        DimensionValue: Record "Dimension Value";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if BusinessUnit = '' then
            Error('Business Unit cannot be empty.');

        GeneralLedgerSetup.Get();
        DimensionValue.Reset();
        DimensionValue.SetRange("Dimension Code", GeneralLedgerSetup."Global Dimension 2 Code");
        DimensionValue.SetRange(Code, BusinessUnit);
        if not DimensionValue.FindFirst() then
            Error('Invalid Business Unit: %1. Please select a valid Business Unit from Dimension Values.', BusinessUnit);

        if DimensionValue.Blocked then
            Error('Business Unit %1 is blocked and cannot be used.', BusinessUnit);
    end;

    local procedure ValidateDepartment(Department: Code[20])
    var
        DimensionValue: Record "Dimension Value";
    begin
        if Department = '' then
            exit; // Department might be optional

        DimensionValue.Reset();
        DimensionValue.SetRange("Dimension Code", 'DEPARTMENT'); // Adjust dimension code as needed
        DimensionValue.SetRange(Code, Department);
        if not DimensionValue.FindFirst() then
            Error('Invalid Department: %1. Please select a valid Department from Dimension Values.', Department);

        if DimensionValue.Blocked then
            Error('Department %1 is blocked and cannot be used.', Department);
    end;

    local procedure ValidateGLAccount(GLAccountNo: Code[20])
    var
        GLAccount: Record "G/L Account";
    begin
        if GLAccountNo = '' then
            Error('GL Account Code cannot be empty.');

        if not GLAccount.Get(GLAccountNo) then
            Error('Invalid GL Account Code: %1. Account does not exist.', GLAccountNo);

        if GLAccount.Blocked then
            Error('GL Account %1 is blocked and cannot be used.', GLAccountNo);

        if GLAccount."Account Type" <> GLAccount."Account Type"::Posting then
            Error('GL Account %1 is not a posting account. Only posting accounts can be used.', GLAccountNo);

        if not GLAccount."Direct Posting" then
            Error('GL Account %1 does not allow direct posting.', GLAccountNo);
    end;
}