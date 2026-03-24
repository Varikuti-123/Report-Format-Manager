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
                field("GL Account Code"; Rec."GL Account Code") { ApplicationArea = all; }
                field("Posting Date"; Rec."Posting Date") { ApplicationArea = all; }
                field("Credit Amount"; Rec."Credit Amount") { ApplicationArea = all; }
                field("Debit Amount"; Rec."Debit Amount") { ApplicationArea = all; }
                field("Group Code"; Rec."Group Code") { ApplicationArea = all; }
                field("Business Unit"; Rec."Business Unit") { ApplicationArea = all; }
                field(Department; Rec.Department) { ApplicationArea = all; }
                field(Category; Rec.Category) { ApplicationArea = all; }
                field("Sub Ledger"; Rec."Sub Ledger") { ApplicationArea = all; }
                field("Line Narration"; Rec."Line Narration") { ApplicationArea = all; }
                field("Payment Processed"; Rec."Payment Processed")
                {
                    ApplicationArea = all;
                    Editable = false;
                    StyleExpr = PaymentProcessedStyle;
                }
                field("Posted Document No."; Rec."Posted Document No.")
                {
                    ApplicationArea = all;
                    Editable = false;
                }
            }
        }
        area(FactBoxes)
        {
            part(SummaryFactBox; "MAHE_SFAS_Summary_FactBox")
            {
                ApplicationArea = All;
                SubPageLink = "Posting Date" = field("Posting Date"),
                              "Group Code" = field("Group Code"),
                              "Business Unit" = field("Business Unit"),
                              Department = field(Department);
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
                ToolTip = 'Preview the Journal Voucher without posting.';

                trigger OnAction()
                var
                    StudentFinanceCU: Codeunit MAHE_SFASTrailBalance;
                begin
                    StudentFinanceCU.UpdateApplicationFeePaymentDetails(Rec, true); // Preview Mode
                end;
            }

            action("Create and Post Journal Voucher")
            {
                Caption = 'Create and Post Journal Voucher';
                ApplicationArea = all;
                Image = PostDocument;
                ToolTip = 'Create and Post the Journal Voucher.';

                trigger OnAction()
                var
                    StudentFinanceCU: Codeunit MAHE_SFASTrailBalance;
                begin
                    if Confirm('Do you want to create and post the Journal Voucher for the selected filters?', false) then
                        StudentFinanceCU.UpdateApplicationFeePaymentDetails(Rec, false); // Post Mode
                end;
            }

            action("Process Selected Records")
            {
                Caption = 'Process Selected Records';
                ApplicationArea = all;
                Image = PostBatch;
                ToolTip = 'Process all selected records.';

                trigger OnAction()
                var
                    SelectedRec: Record MAHESFASHFAS_TrialBalance;
                    StudentFinanceCU: Codeunit MAHE_SFASTrailBalance;
                    ProcessedCount: Integer;
                begin
                    CurrPage.SetSelectionFilter(SelectedRec);
                    if SelectedRec.IsEmpty then
                        Error('Please select at least one record to process.');

                    if not Confirm('Do you want to process %1 selected record(s)?', false, SelectedRec.Count) then
                        exit;

                    if SelectedRec.FindFirst() then begin
                        StudentFinanceCU.UpdateApplicationFeePaymentDetails(SelectedRec, false);
                        ProcessedCount := SelectedRec.Count;
                    end;

                    Message('%1 record(s) processed successfully.', ProcessedCount);
                    CurrPage.Update(false);
                end;
            }
        }

        area(Navigation)
        {
            action("View Posted Entries")
            {
                Caption = 'View Posted G/L Entries';
                ApplicationArea = all;
                Image = GLRegisters;
                ToolTip = 'View the posted G/L entries for this record.';

                trigger OnAction()
                var
                    GLEntry: Record "G/L Entry";
                begin
                    if Rec."Posted Document No." = '' then
                        Error('This record has not been posted yet.');

                    GLEntry.Reset();
                    GLEntry.SetRange("Document No.", Rec."Posted Document No.");
                    PAGE.Run(PAGE::"General Ledger Entries", GLEntry);
                end;
            }
        }

        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Preview Journal Voucher_Promoted"; "Preview Journal Voucher") { }
                actionref("Create and Post Journal Voucher_Promoted"; "Create and Post Journal Voucher") { }
                actionref("Process Selected Records_Promoted"; "Process Selected Records") { }
            }
            group(Category_Navigate)
            {
                Caption = 'Navigate';

                actionref("View Posted Entries_Promoted"; "View Posted Entries") { }
            }
        }
    }

    var
        PaymentProcessedStyle: Text;

    trigger OnAfterGetRecord()
    begin
        if Rec."Payment Processed" then
            PaymentProcessedStyle := 'Favorable'
        else
            PaymentProcessedStyle := 'Ambiguous';
    end;
}