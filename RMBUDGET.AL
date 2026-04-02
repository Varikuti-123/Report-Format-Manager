//PwC VS_GS 110825++
page 53601 MAHEBudgetDimWiseRM
{
    Caption = 'Budget Dimension Wise R & M';
    PageType = List;
    SourceTable = MAHEBudgetDimWise;
    SourceTableTemporary = true;
    ApplicationArea = All;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(Name; Rec.Name)
                {
                    Editable = false;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    CaptionClass = Rec.GetDimCaption(1);
                    Visible = ShortCutDim1Visible;
                    Editable = false;
                }
                Field("Shortcut Dimension 1 Name"; ShortCutDimName(1))
                {
                    Editable = False;
                    Visible = ShortCutDim1Visible;
                    CaptionClass = Rec.GetDimCaption(1) + ' NAME';
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    CaptionClass = Rec.GetDimCaption(2);
                    Visible = ShortCutDim2Visible;
                    Editable = false;
                }
                Field("Shortcut Dimension 2 Name"; ShortCutDimName(2))
                {
                    Editable = False;
                    Visible = ShortCutDim2Visible;
                    CaptionClass = Rec.GetDimCaption(2) + ' Name';
                }
                field("Shortcut Dimension 3 Code"; Rec."Shortcut Dimension 3 Code")
                {
                    CaptionClass = Rec.GetDimCaption(3);
                    Visible = ShortCutDim3Visible;
                    Editable = false;
                }
                Field("Shortcut Dimension 3 Name"; ShortCutDimName(3))
                {
                    Editable = False;
                    Visible = ShortCutDim3Visible;
                    CaptionClass = Rec.GetDimCaption(3) + ' Name';
                }
                field("Proposed Amount"; Rec."Proposed Amount")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Sanctioned Amount"; Rec."Sanctioned Amount")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("PIP Amount"; Rec."PIP Amount")
                {
                    ApplicationArea = All;
                }
                field("Utilized Amount"; Rec."Utilized Amount")
                {
                    ApplicationArea = All;
                }
                field("Available Quantity"; Rec."Budgeted Quantity" - Rec."PIP Quantity" - Rec."Utilized Quantity")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Reallocated Amount"; Rec."Reallocated Amount")
                {
                    Editable = false;
                    trigger OnDrillDown()
                    var
                        MAHEReallocateHistory: Record MAHEReallocationHistory;
                    begin
                        MAHEReallocateHistory.Reset();
                        MAHEReallocateHistory.SetRange("Budget Code", Rec."Budget Code");
                        MAHEReallocateHistory.SetRange("Reallocated To No.", Rec."No.");
                        MAHEReallocateHistory.SetRange("Reallocated To Dimension 1", Rec."Shortcut Dimension 1 Code");
                        MAHEReallocateHistory.SetRange("Reallocated To Dimension 2", Rec."Shortcut Dimension 2 Code");
                        if MAHEReallocateHistory.FindSet() then
                            Page.RunModal(Page::MAHEReallocationHistoryList, MAHEReallocateHistory);
                    end;
                }
                field("Total Additional Budget"; TotalAdditionalBudgetAmt)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Balance Amount"; BalanceAmountCalc)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Amount Used in Reallocation"; Rec."Amount Used in Reallocation")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Remarks; Rec.Remarks)
                { }
                field(Justification; Rec.Justification)
                { }
                field(Purpose; Rec.Purpose)
                { }
                field("Capital Budget Type"; Rec."Capital Budget Type")
                {
                    Visible = BudgetedQtyVisible;
                }
                field("Purchase Type"; Rec."Purchase Type")
                {
                    Visible = BudgetedQtyVisible;
                }
                field("Asset Group"; Rec."Asset Group")
                {
                    Visible = BudgetedQtyVisible;
                }
                field("Profile Id"; Rec."Profile Id")
                {
                    Visible = BudgetedQtyVisible;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action("Additional Budget Allocation")
            {
                Caption = 'Additional Budget Allocation';
                Image = List;
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                trigger OnAction()
                var
                    AdditionalBudgetPage: Page MAHEAdditionalBudgetDimWise;
                    AdditionalBudgetRec: Record MAHEAdditionalBudgetDimWise;
                begin
                    AdditionalBudgetRec.Reset();
                    AdditionalBudgetRec.SetRange("Budget Code", Rec."Budget Code");
                    AdditionalBudgetRec.SetRange("No.", Rec."No.");
                    AdditionalBudgetRec.SetRange("Shortcut Dimension 1 Code", Rec."Shortcut Dimension 1 Code");
                    AdditionalBudgetRec.SetRange("Shortcut Dimension 2 Code", Rec."Shortcut Dimension 2 Code");
                    Page.RunModal(Page::MAHEAdditionalBudgetDimWise, AdditionalBudgetRec);
                end;
            }
            action(RefreshData)
            {
                Caption = 'Refresh';
                Image = Refresh;
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                trigger OnAction()
                begin
                    LoadAggregatedData();
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        Dimension: Record "Dimension Value";
        GlSetup: Record "General Ledger Setup";
        GetDimVales: Text;
    begin
        Clear(GetDimVales);
        GlSetup.Get();
        Dimension.Reset();
        Dimension.SetRange("Dimension Code", GlSetup."Shortcut Dimension 3 Code");
        Dimension.SetRange("MAHE GS Department", True);
        if Dimension.FindSet() Then
            repeat
                if GetDimVales = '' then
                    GetDimVales := Dimension.Code
                else
                    GetDimVales += '|' + Dimension.Code;
            until Dimension.Next() = 0;

        // Store filter values for use in LoadAggregatedData
        GlobalDim2Filter := GetDimVales;

        BudgetedQtyVisible := false;
        ShortCutDim1Visible := false;
        ShortCutDim2Visible := false;
        ShortCutDim3Visible := false;

        If MAHEBudgetHeader.Get(Rec.GetFilter("Budget Code")) then begin
            if MAHEBudgetHeader."Budget Type" = MAHEBudgetHeader."Budget Type"::"Capital Budget" then
                BudgetedQtyVisible := true;

            if MAHEBudgetHeader."Shortcut Dimension 1 Code" <> '' then
                ShortCutDim1Visible := true;
            if MAHEBudgetHeader."Shortcut Dimension 2 Code" <> '' then
                ShortCutDim2Visible := true;
            if MAHEBudgetHeader."Shortcut Dimension 3 Code" <> '' then
                ShortCutDim3Visible := true;
        end;

        LoadAggregatedData();
    end;

    trigger OnAfterGetRecord()
    begin
        TotalAdditionalBudgetAmt := GetTotalAdditionalBudgetAggregated(Rec);
        BalanceAmountCalc := TotalAdditionalBudgetAmt + Rec."Sanctioned Amount" - Rec."Amount Used in Reallocation" - Rec."PIP Amount" - Rec."Utilized Amount";
    end;

    var
        MAHEBudgetHeader: Record MAHEBudgetHeader;
        DimensionValue: Record "Dimension Value";
        MaheBudgetModifications: Codeunit MAHEBudgetModifications;
        BudgetedQtyVisible: Boolean;
        ShortCutDim1Visible: Boolean;
        ShortCutDim2Visible: Boolean;
        ShortCutDim3Visible: Boolean;
        GlobalDim2Filter: Text;
        TotalAdditionalBudgetAmt: Decimal;
        BalanceAmountCalc: Decimal;
        TempLineNo: Integer;

    local procedure LoadAggregatedData()
    var
        ActualRec: Record MAHEBudgetDimWise;
        TempAggRec: Record MAHEBudgetDimWise temporary;
        BudgetCodeFilter: Text;
        NoFilter: Text;
        Dim1Filter: Text;
        Dim2Filter: Text;
        Found: Boolean;
    begin
        // Clear existing temp records
        Rec.Reset();
        Rec.DeleteAll();
        TempLineNo := 0;

        // Get filters that were set on the page before it was opened (from RunPageLink etc.)
        BudgetCodeFilter := Rec.GetFilter("Budget Code");

        // Read actual data
        ActualRec.Reset();
        if BudgetCodeFilter <> '' then
            ActualRec.SetFilter("Budget Code", BudgetCodeFilter);

        // Apply the department filter
        if GlobalDim2Filter <> '' then
            ActualRec.SetFilter("Shortcut Dimension 2 Code", GlobalDim2Filter);

        if not ActualRec.FindSet() then
            exit;

        repeat
            // Check if we already have an aggregated record for this combination (ignoring Start Date)
            Found := false;
            TempAggRec.Reset();
            TempAggRec.SetRange("Budget Code", ActualRec."Budget Code");
            TempAggRec.SetRange("No.", ActualRec."No.");
            TempAggRec.SetRange("Shortcut Dimension 1 Code", ActualRec."Shortcut Dimension 1 Code");
            TempAggRec.SetRange("Shortcut Dimension 2 Code", ActualRec."Shortcut Dimension 2 Code");
            if TempAggRec.FindFirst() then begin
                // Aggregate amounts into existing temp record
                Found := true;
                Rec.Get(TempAggRec."Budget Code", TempAggRec."No.", TempAggRec."Shortcut Dimension 1 Code",
                        TempAggRec."Shortcut Dimension 2 Code", TempAggRec."Start Date");
                Rec."Proposed Amount" += ActualRec."Proposed Amount";
                Rec."Sanctioned Amount" += ActualRec."Sanctioned Amount";
                Rec."PIP Amount" += ActualRec."PIP Amount";
                Rec."Utilized Amount" += ActualRec."Utilized Amount";
                Rec."Reallocated Amount" += ActualRec."Reallocated Amount";
                Rec."Amount Used in Reallocation" += ActualRec."Amount Used in Reallocation";
                Rec."Budgeted Quantity" += ActualRec."Budgeted Quantity";
                Rec."PIP Quantity" += ActualRec."PIP Quantity";
                Rec."Utilized Quantity" += ActualRec."Utilized Quantity";
                Rec."Received From Capital Budget" += ActualRec."Received From Capital Budget";
                Rec."Transfer To Operating Budget" += ActualRec."Transfer To Operating Budget";
                Rec."Received From Operating Budget" += ActualRec."Received From Operating Budget";
                Rec."Transfer To Capital Budget" += ActualRec."Transfer To Capital Budget";
                Rec."Credit Memo Amount" += ActualRec."Credit Memo Amount";
                Rec.Modify();
            end;

            if not Found then begin
                // Insert new aggregated record
                Rec.Init();
                Rec.TransferFields(ActualRec);
                // Use the first Start Date found for this combination as the key
                Rec.Insert();
            end;
        until ActualRec.Next() = 0;

        // Position to first record
        if Rec.FindFirst() then;
    end;

    local procedure GetTotalAdditionalBudgetAggregated(BudgetDimWise: Record MAHEBudgetDimWise): Decimal
    var
        AdditionalBudget: Record MAHEAdditionalBudgetDimWise;
        TotalAmt: Decimal;
    begin
        TotalAmt := 0;
        AdditionalBudget.Reset();
        AdditionalBudget.SetRange("Budget Code", BudgetDimWise."Budget Code");
        AdditionalBudget.SetRange("No.", BudgetDimWise."No.");
        AdditionalBudget.SetRange("Shortcut Dimension 1 Code", BudgetDimWise."Shortcut Dimension 1 Code");
        AdditionalBudget.SetRange("Shortcut Dimension 2 Code", BudgetDimWise."Shortcut Dimension 2 Code");
        // Do NOT filter on Start Date - aggregate across all start dates
        AdditionalBudget.SetRange(Status, AdditionalBudget.Status::Approved);
        if AdditionalBudget.FindSet() then begin
            AdditionalBudget.CalcSums("Additional Budget Amount");
            TotalAmt := AdditionalBudget."Additional Budget Amount";
        end;
        exit(TotalAmt);
    end;

    local procedure ShortCutDimName(arg: Integer): Text[200]
    var
        DimValue: Record "Dimension Value";
        Operating: Record MAHEBudgetHeader;
    begin
        Case arg of
            1:
                begin
                    if Operating.Get(REC."Budget Code") then;
                    if DimValue.Get(Operating."Shortcut Dimension 1 Code", REC."Shortcut Dimension 1 Code") then
                        Exit(DimValue.Name);
                end;
            2:
                begin
                    if Operating.Get(REC."Budget Code") then;
                    if DimValue.Get(Operating."Shortcut Dimension 2 Code", REC."Shortcut Dimension 2 Code") then
                        Exit(DimValue.Name);
                end;
            3:
                begin
                    if Operating.Get(REC."Budget Code") then;
                    if DimValue.Get(Operating."Shortcut Dimension 3 Code", REC."Shortcut Dimension 3 Code") then
                        Exit(DimValue.Name);
                end;
        End;
    end;
}
//PwC VS_GS 110825--