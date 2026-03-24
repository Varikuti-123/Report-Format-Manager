tableextension 50900 MAHESFASHFAS_TrialBalance_Ext extends MAHESFASHFAS_TrialBalance
{
    fields
    {
        field(100; "Journal Document No."; Code[20])
        {
            Caption = 'Journal Document No.';
            Editable = false;
        }
    }
}
codeunit 50900 MAHE_SFASTrailBalance
{
    //-------------------------Trail balance---------------------------//
    //------------------------SFAS Trail balance-----------------------//

    procedure CreateJournalVoucher(var ApplicationFeeAPI: Record MAHESFASHFAS_TrialBalance; IsPreview: Boolean)
    var
        GenJourLine: Record "Gen. Journal Line";
        GLSetup: Record MAHEPaymentJournalSetup;
        GenBatchName: Record "Gen. Journal Batch";
        LineNo: Integer;
        NoSeries: Codeunit "No. Series";
        GenJournalNarration: Record "Gen. Journal Narration";
        TrialBalanceRec: Record MAHESFASHFAS_TrialBalance;
        DocumentNo: Code[20];
        PostingDate: Date;
        TotalDebit: Decimal;
        TotalCredit: Decimal;
        LineNoNarration: Integer;
    begin
        // Check if already posted
        if ApplicationFeeAPI."Payment Processed" then
            Error('This record is already posted. You cannot process it again.');

        GLSetup.Get();

        // Validate Posting Date
        if not Evaluate(PostingDate, ApplicationFeeAPI."Posting Date") then
            Error('Invalid Posting Date format: "%1". Please enter a valid date.', ApplicationFeeAPI."Posting Date");

        if PostingDate = 0D then
            Error('Posting Date cannot be empty.');

        ValidatePostingDate(PostingDate);
        ValidateGroupCode(ApplicationFeeAPI."Group Code");
        ValidateBusinessUnit(ApplicationFeeAPI."Business Unit");
        ValidateDepartment(ApplicationFeeAPI.Department);

        // Filter records by Posting Date, Group, Business Unit, Department
        TrialBalanceRec.Reset();
        TrialBalanceRec.SetRange("Posting Date", ApplicationFeeAPI."Posting Date");
        TrialBalanceRec.SetRange("Group Code", ApplicationFeeAPI."Group Code");
        TrialBalanceRec.SetRange("Business Unit", ApplicationFeeAPI."Business Unit");
        TrialBalanceRec.SetRange(Department, ApplicationFeeAPI.Department);
        TrialBalanceRec.SetRange("Payment Processed", false);

        if TrialBalanceRec.IsEmpty then
            Error('No unprocessed records found for:\Posting Date: %1\Group: %2\Business Unit: %3\Department: %4',
                ApplicationFeeAPI."Posting Date",
                ApplicationFeeAPI."Group Code",
                ApplicationFeeAPI."Business Unit",
                ApplicationFeeAPI.Department);

        // Generate Document No.
        if IsPreview then
            DocumentNo := 'PREVIEW-' + Format(Today, 0, '<Day,2><Month,2><Year2>')
        else begin
            if GenBatchName.Get(GLSetup."SFAS_Application Fee Template", GLSetup."SFAS_Application Fee Batch") then
                DocumentNo := NoSeries.GetNextNo(GenBatchName."No. Series", PostingDate)
            else
                Error('Journal Batch not found for Template: %1, Batch: %2',
                    GLSetup."SFAS_Application Fee Template", GLSetup."SFAS_Application Fee Batch");
        end;

        // Clear existing lines with same document no (if any)
        GenJourLine.Reset();
        GenJourLine.SetRange("Journal Template Name", GLSetup."SFAS_Application Fee Template");
        GenJourLine.SetRange("Journal Batch Name", GLSetup."SFAS_Application Fee Batch");
        GenJourLine.SetRange("Document No.", DocumentNo);
        if not GenJourLine.IsEmpty then
            GenJourLine.DeleteAll(true);

        LineNo := 10000;
        TotalDebit := 0;
        TotalCredit := 0;

        // Create Journal Lines
        if TrialBalanceRec.FindSet() then
            repeat
                // Validate GL Account
                ValidateGLAccount(TrialBalanceRec."GL Account Code");

                // Create Debit Line
                if TrialBalanceRec."Debit Amount" > 0 then begin
                    Clear(GenJourLine);
                    GenJourLine.Init();
                    GenJourLine."Journal Template Name" := GLSetup."SFAS_Application Fee Template";
                    GenJourLine."Journal Batch Name" := GLSetup."SFAS_Application Fee Batch";
                    GenJourLine."Line No." := LineNo;
                    GenJourLine."Posting Date" := PostingDate;
                    GenJourLine."Document Date" := PostingDate;
                    GenJourLine."Document No." := DocumentNo;
                    GenJourLine.Validate("Account Type", GenJourLine."Account Type"::"G/L Account");
                    GenJourLine.Validate("Account No.", TrialBalanceRec."GL Account Code");
                    GenJourLine.Validate("Debit Amount", TrialBalanceRec."Debit Amount");

                    if TrialBalanceRec."Group Code" <> '' then
                        GenJourLine.Validate("Shortcut Dimension 1 Code", TrialBalanceRec."Group Code");
                    if TrialBalanceRec."Business Unit" <> '' then
                        GenJourLine.Validate("Shortcut Dimension 2 Code", TrialBalanceRec."Business Unit");

                    GenJourLine.Description := CopyStr(TrialBalanceRec."Line Narration", 1, 100);
                    GenJourLine.Insert(true);

                    // Create Narration
                    if TrialBalanceRec."Line Narration" <> '' then begin
                        GenJournalNarration.Reset();
                        GenJournalNarration.SetRange("Journal Template Name", GLSetup."SFAS_Application Fee Template");
                        GenJournalNarration.SetRange("Journal Batch Name", GLSetup."SFAS_Application Fee Batch");
                        GenJournalNarration.SetRange("Document No.", DocumentNo);
                        GenJournalNarration.SetRange("Gen. Journal Line No.", LineNo);
                        if GenJournalNarration.FindLast() then
                            LineNoNarration := GenJournalNarration."Line No." + 10000
                        else
                            LineNoNarration := 10000;

                        GenJournalNarration.Init();
                        GenJournalNarration."Journal Template Name" := GLSetup."SFAS_Application Fee Template";
                        GenJournalNarration."Journal Batch Name" := GLSetup."SFAS_Application Fee Batch";
                        GenJournalNarration."Document No." := DocumentNo;
                        GenJournalNarration."Gen. Journal Line No." := LineNo;
                        GenJournalNarration."Line No." := LineNoNarration;
                        GenJournalNarration.Narration := TrialBalanceRec."Line Narration";
                        GenJournalNarration.Insert();
                    end;

                    TotalDebit += TrialBalanceRec."Debit Amount";
                    LineNo += 10000;
                end;

                // Create Credit Line
                if TrialBalanceRec."Credit Amount" > 0 then begin
                    Clear(GenJourLine);
                    GenJourLine.Init();
                    GenJourLine."Journal Template Name" := GLSetup."SFAS_Application Fee Template";
                    GenJourLine."Journal Batch Name" := GLSetup."SFAS_Application Fee Batch";
                    GenJourLine."Line No." := LineNo;
                    GenJourLine."Posting Date" := PostingDate;
                    GenJourLine."Document Date" := PostingDate;
                    GenJourLine."Document No." := DocumentNo;
                    GenJourLine.Validate("Account Type", GenJourLine."Account Type"::"G/L Account");
                    GenJourLine.Validate("Account No.", TrialBalanceRec."GL Account Code");
                    GenJourLine.Validate("Credit Amount", TrialBalanceRec."Credit Amount");

                    if TrialBalanceRec."Group Code" <> '' then
                        GenJourLine.Validate("Shortcut Dimension 1 Code", TrialBalanceRec."Group Code");
                    if TrialBalanceRec."Business Unit" <> '' then
                        GenJourLine.Validate("Shortcut Dimension 2 Code", TrialBalanceRec."Business Unit");

                    GenJourLine.Description := CopyStr(TrialBalanceRec."Line Narration", 1, 100);
                    GenJourLine.Insert(true);

                    // Create Narration
                    if TrialBalanceRec."Line Narration" <> '' then begin
                        GenJournalNarration.Reset();
                        GenJournalNarration.SetRange("Journal Template Name", GLSetup."SFAS_Application Fee Template");
                        GenJournalNarration.SetRange("Journal Batch Name", GLSetup."SFAS_Application Fee Batch");
                        GenJournalNarration.SetRange("Document No.", DocumentNo);
                        GenJournalNarration.SetRange("Gen. Journal Line No.", LineNo);
                        if GenJournalNarration.FindLast() then
                            LineNoNarration := GenJournalNarration."Line No." + 10000
                        else
                            LineNoNarration := 10000;

                        GenJournalNarration.Init();
                        GenJournalNarration."Journal Template Name" := GLSetup."SFAS_Application Fee Template";
                        GenJournalNarration."Journal Batch Name" := GLSetup."SFAS_Application Fee Batch";
                        GenJournalNarration."Document No." := DocumentNo;
                        GenJournalNarration."Gen. Journal Line No." := LineNo;
                        GenJournalNarration."Line No." := LineNoNarration;
                        GenJournalNarration.Narration := TrialBalanceRec."Line Narration";
                        GenJournalNarration.Insert();
                    end;

                    TotalCredit += TrialBalanceRec."Credit Amount";
                    LineNo += 10000;
                end;

                // Update Journal Document No. in Trial Balance record (not for preview)
                if not IsPreview then begin
                    TrialBalanceRec."Journal Document No." := DocumentNo;
                    TrialBalanceRec.Modify(true);
                end;

            until TrialBalanceRec.Next() = 0;

        // Validate Debit = Credit
        if TotalDebit <> TotalCredit then
            Error('Total Debit (%1) must equal Total Credit (%2).\Difference: %3',
                TotalDebit, TotalCredit, Abs(TotalDebit - TotalCredit));

        // Show message
        if IsPreview then
            Message('PREVIEW MODE (No data saved)\Document No.: %1\Total Debit: %2\Total Credit: %3\Total Lines: %4',
                DocumentNo, TotalDebit, TotalCredit, (LineNo / 10000) - 1)
        else
            Message('Journal Voucher Created!\Document No.: %1\Total Debit: %2\Total Credit: %3\Total Lines: %4\Please review and post.',
                DocumentNo, TotalDebit, TotalCredit, (LineNo / 10000) - 1);

        // Open Journal Voucher page
        GenJourLine.Reset();
        GenJourLine.SetRange("Journal Template Name", GLSetup."SFAS_Application Fee Template");
        GenJourLine.SetRange("Journal Batch Name", GLSetup."SFAS_Application Fee Batch");
        GenJourLine.SetRange("Document No.", DocumentNo);

        if GenJourLine.FindFirst() then
            PAGE.Run(PAGE::"Journal Voucher", GenJourLine);
    end;

    procedure OpenJournalVoucher(var ApplicationFeeAPI: Record MAHESFASHFAS_TrialBalance)
    var
        GenJourLine: Record "Gen. Journal Line";
        GLSetup: Record MAHEPaymentJournalSetup;
    begin
        if ApplicationFeeAPI."Journal Document No." = '' then
            Error('No Journal Document No. found for this record.');

        GLSetup.Get();

        GenJourLine.Reset();
        GenJourLine.SetRange("Journal Template Name", GLSetup."SFAS_Application Fee Template");
        GenJourLine.SetRange("Journal Batch Name", GLSetup."SFAS_Application Fee Batch");
        GenJourLine.SetRange("Document No.", ApplicationFeeAPI."Journal Document No.");

        if GenJourLine.IsEmpty then begin
            // JV not found - check if posted
            if CheckIfPosted(ApplicationFeeAPI."Journal Document No.") then begin
                if Confirm('Journal Voucher %1 has been posted.\Do you want to view the G/L Entries?', true, ApplicationFeeAPI."Journal Document No.") then
                    OpenGLEntries(ApplicationFeeAPI);
            end else
                Error('Journal Voucher %1 not found.', ApplicationFeeAPI."Journal Document No.");
        end else
            PAGE.Run(PAGE::"Journal Voucher", GenJourLine);
    end;

    procedure OpenGLEntries(var ApplicationFeeAPI: Record MAHESFASHFAS_TrialBalance)
    var
        GLEntry: Record "G/L Entry";
    begin
        if ApplicationFeeAPI."Journal Document No." = '' then
            Error('No Journal Document No. found.');

        GLEntry.Reset();
        GLEntry.SetRange("Document No.", ApplicationFeeAPI."Journal Document No.");

        if GLEntry.IsEmpty then
            Error('No G/L Entries found for Document No.: %1', ApplicationFeeAPI."Journal Document No.");

        PAGE.Run(PAGE::"General Ledger Entries", GLEntry);
    end;

    procedure CheckIfPosted(DocumentNo: Code[20]): Boolean
    var
        GLEntry: Record "G/L Entry";
    begin
        if DocumentNo = '' then
            exit(false);

        GLEntry.Reset();
        GLEntry.SetRange("Document No.", DocumentNo);
        exit(not GLEntry.IsEmpty);
    end;

    procedure RefreshPaymentProcessedStatus()
    var
        TrialBalanceRec: Record MAHESFASHFAS_TrialBalance;
        GLEntry: Record "G/L Entry";
        UpdatedCount: Integer;
    begin
        TrialBalanceRec.Reset();
        TrialBalanceRec.SetRange("Payment Processed", false);
        TrialBalanceRec.SetFilter("Journal Document No.", '<>%1', '');

        if TrialBalanceRec.FindSet() then
            repeat
                GLEntry.Reset();
                GLEntry.SetRange("Document No.", TrialBalanceRec."Journal Document No.");

                if not GLEntry.IsEmpty then begin
                    TrialBalanceRec."Payment Processed" := true;
                    TrialBalanceRec.Modify(true);
                    UpdatedCount += 1;
                end;
            until TrialBalanceRec.Next() = 0;

        if UpdatedCount > 0 then
            Message('%1 record(s) updated to Posted status.', UpdatedCount)
        else
            Message('No records to update.');
    end;

    // ==================== VALIDATION PROCEDURES ====================

    local procedure ValidatePostingDate(PostingDate: Date)
    var
        UserSetup: Record "User Setup";
        GLSetupRec: Record "General Ledger Setup";
    begin
        if PostingDate > WorkDate() then
            Error('Posting Date %1 cannot be greater than Work Date %2.', PostingDate, WorkDate());

        GLSetupRec.Get();

        if (GLSetupRec."Allow Posting From" <> 0D) and (PostingDate < GLSetupRec."Allow Posting From") then
            Error('Posting Date %1 is before allowed period.\Allowed From: %2', PostingDate, GLSetupRec."Allow Posting From");

        if (GLSetupRec."Allow Posting To" <> 0D) and (PostingDate > GLSetupRec."Allow Posting To") then
            Error('Posting Date %1 is after allowed period.\Allowed To: %2', PostingDate, GLSetupRec."Allow Posting To");

        if UserSetup.Get(UserId) then begin
            if (UserSetup."Allow Posting From" <> 0D) and (PostingDate < UserSetup."Allow Posting From") then
                Error('Posting Date %1 is before your allowed period.\Your Allowed From: %2', PostingDate, UserSetup."Allow Posting From");

            if (UserSetup."Allow Posting To" <> 0D) and (PostingDate > UserSetup."Allow Posting To") then
                Error('Posting Date %1 is after your allowed period.\Your Allowed To: %2', PostingDate, UserSetup."Allow Posting To");
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

        if GeneralLedgerSetup."Global Dimension 1 Code" = '' then
            Error('Global Dimension 1 is not configured in General Ledger Setup.');

        DimensionValue.Reset();
        DimensionValue.SetRange("Dimension Code", GeneralLedgerSetup."Global Dimension 1 Code");
        DimensionValue.SetRange(Code, GroupCode);

        if not DimensionValue.FindFirst() then
            Error('Invalid Group Code: "%1".\Does not exist in Dimension "%2".',
                GroupCode, GeneralLedgerSetup."Global Dimension 1 Code");

        if DimensionValue.Blocked then
            Error('Group Code "%1" is blocked.', GroupCode);
    end;

    local procedure ValidateBusinessUnit(BusinessUnit: Code[20])
    var
        DimensionValue: Record "Dimension Value";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if BusinessUnit = '' then
            Error('Business Unit cannot be empty.');

        GeneralLedgerSetup.Get();

        if GeneralLedgerSetup."Global Dimension 2 Code" = '' then
            Error('Global Dimension 2 is not configured in General Ledger Setup.');

        DimensionValue.Reset();
        DimensionValue.SetRange("Dimension Code", GeneralLedgerSetup."Global Dimension 2 Code");
        DimensionValue.SetRange(Code, BusinessUnit);

        if not DimensionValue.FindFirst() then
            Error('Invalid Business Unit: "%1".\Does not exist in Dimension "%2".',
                BusinessUnit, GeneralLedgerSetup."Global Dimension 2 Code");

        if DimensionValue.Blocked then
            Error('Business Unit "%1" is blocked.', BusinessUnit);
    end;

    local procedure ValidateDepartment(Department: Code[20])
    var
        DimensionValue: Record "Dimension Value";
    begin
        if Department = '' then
            exit; // Optional field

        DimensionValue.Reset();
        DimensionValue.SetRange("Dimension Code", 'DEPARTMENT');
        DimensionValue.SetRange(Code, Department);

        if not DimensionValue.FindFirst() then
            Error('Invalid Department: "%1".', Department);

        if DimensionValue.Blocked then
            Error('Department "%1" is blocked.', Department);
    end;

    local procedure ValidateGLAccount(GLAccountNo: Code[20])
    var
        GLAccount: Record "G/L Account";
    begin
        if GLAccountNo = '' then
            Error('GL Account Code cannot be empty.');

        if not GLAccount.Get(GLAccountNo) then
            Error('GL Account "%1" does not exist.', GLAccountNo);

        if GLAccount.Blocked then
            Error('GL Account "%1" is blocked.', GLAccountNo);

        if GLAccount."Account Type" <> GLAccount."Account Type"::Posting then
            Error('GL Account "%1" is not a Posting account.', GLAccountNo);

        if not GLAccount."Direct Posting" then
            Error('GL Account "%1" does not allow Direct Posting.', GLAccountNo);
    end;

    // ==================== EVENT SUBSCRIBER ====================
    // Auto-update Payment Processed after posting

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Batch", 'OnAfterPostGenJnlLine', '', false, false)]
    local procedure OnAfterPostGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; CommitIsSuppressed: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    var
        TrialBalanceRec: Record MAHESFASHFAS_TrialBalance;
    begin
        TrialBalanceRec.Reset();
        TrialBalanceRec.SetRange("Journal Document No.", GenJournalLine."Document No.");
        TrialBalanceRec.SetRange("Payment Processed", false);

        if TrialBalanceRec.FindSet() then
            repeat
                TrialBalanceRec."Payment Processed" := true;
                TrialBalanceRec.Modify(true);
            until TrialBalanceRec.Next() = 0;
    end;
}
page 50762 MAHE_SFAS_List
{
    PageType = List;
    Caption = 'SFAS Trial Balance List';
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = MAHESFASHFAS_TrialBalance;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("GL Account Code"; Rec."GL Account Code")
                {
                    ApplicationArea = all;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = all;
                }
                field("Credit Amount"; Rec."Credit Amount")
                {
                    ApplicationArea = all;
                }
                field("Debit Amount"; Rec."Debit Amount")
                {
                    ApplicationArea = all;
                }
                field("Group Code"; Rec."Group Code")
                {
                    ApplicationArea = all;
                }
                field("Business Unit"; Rec."Business Unit")
                {
                    ApplicationArea = all;
                }
                field(Department; Rec.Department)
                {
                    ApplicationArea = all;
                }
                field(Category; Rec.Category)
                {
                    ApplicationArea = all;
                }
                field("Sub Ledger"; Rec."Sub Ledger")
                {
                    ApplicationArea = all;
                }
                field("Line Narration"; Rec."Line Narration")
                {
                    ApplicationArea = all;
                }
                field("Journal Document No."; Rec."Journal Document No.")
                {
                    ApplicationArea = all;
                    Editable = false;
                    StyleExpr = JournalDocNoStyle;

                    trigger OnDrillDown()
                    var
                        StudentFinanceCU: Codeunit MAHE_SFASTrailBalance;
                    begin
                        if Rec."Journal Document No." <> '' then
                            StudentFinanceCU.OpenJournalVoucher(Rec);
                    end;
                }
                field("Payment Processed"; Rec."Payment Processed")
                {
                    ApplicationArea = all;
                    Editable = false;
                    StyleExpr = PaymentProcessedStyle;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Preview Journal Voucher")
            {
                Caption = 'Preview Journal Voucher';
                ApplicationArea = all;
                Image = Preview;
                ToolTip = 'Preview without saving.';

                trigger OnAction()
                var
                    StudentFinanceCU: Codeunit MAHE_SFASTrailBalance;
                begin
                    StudentFinanceCU.CreateJournalVoucher(Rec, true);
                end;
            }

            action("Create Journal Voucher")
            {
                Caption = 'Create Journal Voucher';
                ApplicationArea = all;
                Image = Journal;
                ToolTip = 'Create Journal Voucher and open for posting.';

                trigger OnAction()
                var
                    StudentFinanceCU: Codeunit MAHE_SFASTrailBalance;
                begin
                    if Confirm('Create Journal Voucher for:\Posting Date: %1\Group: %2\Business Unit: %3\Department: %4?',
                        true, Rec."Posting Date", Rec."Group Code", Rec."Business Unit", Rec.Department) then begin
                        StudentFinanceCU.CreateJournalVoucher(Rec, false);
                        CurrPage.Update(false);
                    end;
                end;
            }

            action("Open Journal Voucher")
            {
                Caption = 'Open Journal Voucher';
                ApplicationArea = all;
                Image = OpenJournal;
                ToolTip = 'Open existing Journal Voucher.';

                trigger OnAction()
                var
                    StudentFinanceCU: Codeunit MAHE_SFASTrailBalance;
                begin
                    if Rec."Journal Document No." = '' then
                        Error('No Journal Voucher created for this record.')
                    else
                        StudentFinanceCU.OpenJournalVoucher(Rec);
                end;
            }

            action("View G/L Entries")
            {
                Caption = 'View G/L Entries';
                ApplicationArea = all;
                Image = GLRegisters;
                ToolTip = 'View posted G/L Entries.';

                trigger OnAction()
                var
                    StudentFinanceCU: Codeunit MAHE_SFASTrailBalance;
                begin
                    if Rec."Journal Document No." = '' then
                        Error('No Journal Document No. found.')
                    else
                        StudentFinanceCU.OpenGLEntries(Rec);
                end;
            }

            action("Refresh Status")
            {
                Caption = 'Refresh Posted Status';
                ApplicationArea = all;
                Image = Refresh;
                ToolTip = 'Check and update posted status.';

                trigger OnAction()
                var
                    StudentFinanceCU: Codeunit MAHE_SFASTrailBalance;
                begin
                    StudentFinanceCU.RefreshPaymentProcessedStatus();
                    CurrPage.Update(false);
                end;
            }
        }

        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Create Journal Voucher_Promoted"; "Create Journal Voucher") { }
                actionref("Preview Journal Voucher_Promoted"; "Preview Journal Voucher") { }
                actionref("Open Journal Voucher_Promoted"; "Open Journal Voucher") { }
            }
            group(Category_Navigate)
            {
                Caption = 'Navigate';

                actionref("View G/L Entries_Promoted"; "View G/L Entries") { }
                actionref("Refresh Status_Promoted"; "Refresh Status") { }
            }
        }
    }

    var
        PaymentProcessedStyle: Text;
        JournalDocNoStyle: Text;

    trigger OnAfterGetRecord()
    begin
        // Payment Processed Style
        if Rec."Payment Processed" then
            PaymentProcessedStyle := 'Favorable'
        else
            PaymentProcessedStyle := 'Ambiguous';

        // Journal Document No. Style
        if Rec."Journal Document No." <> '' then begin
            if Rec."Payment Processed" then
                JournalDocNoStyle := 'Favorable'
            else
                JournalDocNoStyle := 'Attention';
        end else
            JournalDocNoStyle := 'Standard';
    end;
}