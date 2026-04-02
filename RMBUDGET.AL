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
    ModifyAllowed = false;

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
                //PwC VS 190825++
                Field("Shortcut Dimension 1 Name"; ShortCutDimName(1))
                {
                    Editable = False;
                    Visible = ShortCutDim1Visible;
                    CaptionClass = Rec.GetDimCaption(1) + ' NAME';
                }
                //PwC VS 190825--
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    CaptionClass = Rec.GetDimCaption(2);
                    Visible = ShortCutDim2Visible;
                    Editable = false;
                }
                //PwC VS 190825++
                Field("Shortcut Dimension 2 Name"; ShortCutDimName(2))
                {
                    Editable = False;
                    Visible = ShortCutDim2Visible;
                    CaptionClass = Rec.GetDimCaption(2) + ' Name';
                }
                //PwC VS 190825--
                field("Shortcut Dimension 3 Code"; Rec."Shortcut Dimension 3 Code")
                {
                    CaptionClass = Rec.GetDimCaption(3);
                    Visible = ShortCutDim3Visible;
                    Editable = false;
                }
                //PwC VS 190825++
                Field("Shortcut Dimension 3 Name"; ShortCutDimName(3))
                {
                    Editable = False;
                    Visible = ShortCutDim3Visible;
                    CaptionClass = Rec.GetDimCaption(3) + ' Name';
                }
                //PwC VS 190825--
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
                    Editable = false;
                }
                field("Utilized Amount"; Rec."Utilized Amount")
                {
                    ApplicationArea = All;
                    Editable = false;
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
                field("Balance Amount"; TotalAdditionalBudgetAmt + Rec."Sanctioned Amount" - Rec."Amount Used in Reallocation" - Rec."PIP Amount" - Rec."Utilized Amount")
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
                {
                    Editable = false;
                }
                field(Justification; Rec.Justification)
                {
                    Editable = false;
                }
                field(Purpose; Rec.Purpose)
                {
                    Editable = false;
                }
                field("Capital Budget Type"; Rec."Capital Budget Type")
                {
                    Visible = BudgetedQtyVisible;
                    Editable = false;
                }
                field("Purchase Type"; Rec."Purchase Type")
                {
                    Visible = BudgetedQtyVisible;
                    Editable = false;
                }
                field("Asset Group"; Rec."Asset Group")
                {
                    Visible = BudgetedQtyVisible;
                    Editable = false;
                }
                field("Profile Id"; Rec."Profile Id")
                {
                    Visible = BudgetedQtyVisible;
                    Editable = false;
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
                    AdditionalBudgetRec: Record MAHEAdditionalBudgetDimWise;
                begin
                    AdditionalBudgetRec.Reset();
                    AdditionalBudgetRec.SetRange("Budget Code", Rec."Budget Code");
                    AdditionalBudgetRec.SetRange("No.", Rec."No.");
                    AdditionalBudgetRec.SetRange("Shortcut Dimension 1 Code", Rec."Shortcut Dimension 1 Code");
                    AdditionalBudgetRec.SetRange("Shortcut Dimension 2 Code", Rec."Shortcut Dimension 2 Code");
                    // Not filtering on Start Date as records are aggregated
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

        // Store department filter for aggregation
        GlobalDim2Filter := GetDimVales;

        BudgetedQtyVisible := false;
        ShortCutDim1Visible := false;
        ShortCutDim2Visible := false;
        ShortCutDim3Visible := false;

        // Store Budget Code filter from RunPageLink
        GlobalBudgetCodeFilter := Rec.GetFilter("Budget Code");
        GlobalNoFilter := Rec.GetFilter("No.");
        GlobalDim1Filter := Rec.GetFilter("Shortcut Dimension 1 Code");

        If MAHEBudgetHeader.Get(GlobalBudgetCodeFilter) then begin
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
        GlobalBudgetCodeFilter: Text;
        GlobalNoFilter: Text;
        GlobalDim1Filter: Text;
        TotalAdditionalBudgetAmt: Decimal;

    local procedure LoadAggregatedData()
    var
        ActualRec: Record MAHEBudgetDimWise;
        TempCheck: Record MAHEBudgetDimWise temporary;
        Found: Boolean;
    begin
        // Clear temp records
        Rec.Reset();
        Rec.DeleteAll();

        // Read actual data with existing filters
        ActualRec.Reset();
        if GlobalBudgetCodeFilter <> '' then
            ActualRec.SetFilter("Budget Code", GlobalBudgetCodeFilter);
        if GlobalNoFilter <> '' then
            ActualRec.SetFilter("No.", GlobalNoFilter);
        if GlobalDim1Filter <> '' then
            ActualRec.SetFilter("Shortcut Dimension 1 Code", GlobalDim1Filter);
        if GlobalDim2Filter <> '' then
            ActualRec.SetFilter("Shortcut Dimension 2 Code", GlobalDim2Filter);

        if not ActualRec.FindSet() then
            exit;

        repeat
            // Check if aggregated record already exists for this combination (ignoring Start Date)
            Found := false;
            Rec.Reset();
            Rec.SetRange("Budget Code", ActualRec."Budget Code");
            Rec.SetRange("No.", ActualRec."No.");
            Rec.SetRange("Shortcut Dimension 1 Code", ActualRec."Shortcut Dimension 1 Code");
            Rec.SetRange("Shortcut Dimension 2 Code", ActualRec."Shortcut Dimension 2 Code");
            if Rec.FindFirst() then begin
                // Sum amounts into existing record
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
                Found := true;
            end;

            if not Found then begin
                // Insert first record for this combination
                Rec.Reset();
                Rec.Init();
                Rec.TransferFields(ActualRec);
                Rec.Insert();
            end;
        until ActualRec.Next() = 0;

        // Reset filters and position to first
        Rec.Reset();
        if Rec.FindFirst() then;
    end;

    local procedure GetTotalAdditionalBudgetAggregated(BudgetDimWise: Record MAHEBudgetDimWise): Decimal
    var
        AdditionalBudget: Record MAHEAdditionalBudgetDimWise;
    begin
        AdditionalBudget.Reset();
        AdditionalBudget.SetRange("Budget Code", BudgetDimWise."Budget Code");
        AdditionalBudget.SetRange("No.", BudgetDimWise."No.");
        AdditionalBudget.SetRange("Shortcut Dimension 1 Code", BudgetDimWise."Shortcut Dimension 1 Code");
        AdditionalBudget.SetRange("Shortcut Dimension 2 Code", BudgetDimWise."Shortcut Dimension 2 Code");
        // No Start Date filter - aggregate across all start dates
        AdditionalBudget.SetRange(Status, AdditionalBudget.Status::Approved);
        if AdditionalBudget.FindSet() then begin
            AdditionalBudget.CalcSums("Additional Budget Amount");
            exit(AdditionalBudget."Additional Budget Amount");
        end;
        exit(0);
    end;

    //PwC VS 190825++
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
    //PwC VS 190825--
}
//PwC VS_GS 110825--