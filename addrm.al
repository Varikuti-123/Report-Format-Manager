//PwC VS_GS ++
page 53602 MAHEAddBudgetDimWiseRM
{
    Caption = 'Additional Budget Dimension Wise R & M';
    PageType = List;
    SourceTable = MAHEAdditionalBudgetDimWise;
    ApplicationArea = All;
    AutoSplitKey = true;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Budget Code"; Rec."Budget Code")
                {
                    Editable = false;
                }
                field("No."; Rec."No.")
                {
                    Editable = false;
                }
                field(Name; Rec.Name)
                {
                    Editable = false;
                }
                // Start Date field removed - not relevant for R&M aggregated view
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    CaptionClass = Rec.GetDimCaption(1);
                    Visible = ShortCutDim1Visible;
                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        If MAHEBudgetHeader.Get(Rec."Budget Code") then begin
                            DimensionValue.Reset();
                            DimensionValue.SetRange("Dimension Code", MAHEBudgetHeader."Shortcut Dimension 1 Code");
                            DimensionValue.SetRange(Blocked, false);
                            if DimensionValue.FindFirst() then begin
                                if Page.RunModal(0, DimensionValue) = Action::LookupOK then
                                    Rec."Shortcut Dimension 1 Code" := DimensionValue.Code;
                            end;
                        end;
                    end;
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
                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        If MAHEBudgetHeader.Get(Rec."Budget Code") then begin
                            DimensionValue.Reset();
                            DimensionValue.SetRange("Dimension Code", MAHEBudgetHeader."Shortcut Dimension 2 Code");
                            DimensionValue.SetRange(Blocked, false);
                            if DimensionValue.FindFirst() then begin
                                if Page.RunModal(0, DimensionValue) = Action::LookupOK then
                                    Rec."Shortcut Dimension 2 Code" := DimensionValue.Code;
                            end
                        end;
                    end;
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
                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        If MAHEBudgetHeader.Get(Rec."Budget Code") then begin
                            DimensionValue.Reset();
                            DimensionValue.SetRange("Dimension Code", MAHEBudgetHeader."Shortcut Dimension 3 Code");
                            DimensionValue.SetRange(Blocked, false);
                            if DimensionValue.FindFirst() then begin
                                if Page.RunModal(0, DimensionValue) = Action::LookupOK then
                                    Rec."Shortcut Dimension 3 Code" := DimensionValue.Code;
                            end;
                        end;
                    end;
                }
                Field("Shortcut Dimension 3 Name"; ShortCutDimName(3))
                {
                    Editable = False;
                    Visible = ShortCutDim3Visible;
                    CaptionClass = Rec.GetDimCaption(3) + ' Name';
                }
                field("Budgeted Quantity"; Rec."Budgeted Quantity")
                {
                    Editable = false;
                    Visible = BudgetedQtyVisible;
                }
                field("PIP Quantity"; Rec."PIP Quantity")
                {
                    Visible = BudgetedQtyVisible;
                    Editable = false;
                }
                field("Utilized Quantity"; Rec."Utilized Quantity")
                {
                    Visible = BudgetedQtyVisible;
                    Editable = false;
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
                field("Balance Amount"; Rec."Balance Amount")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Additional Budget Amount"; Rec."Additional Budget Amount")
                {
                    ApplicationArea = All;
                    Editable = EditableBoolean;
                }
                field(Status; Rec.Status)
                {
                    Editable = false;
                    StyleExpr = StyleExp;
                }
                field("Remarks/Justification"; Rec."Remarks/Justification")
                {
                    Editable = EditableBoolean;
                }
                field("Approval Date"; Rec."Approval Date")
                {
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
        area(Factboxes)
        {
            part(Factbox; "MAHE SharePoint Factbox")
            {
                ApplicationArea = All;
                Caption = 'SharePoint';
                SubPageLink = "Table ID" = const(Database::MAHEAdditionalBudgetDimWise), "No." = field("Budget Code"), "Document No. 1" = Field("No."), "Document No. 2" = Field("Shortcut Dimension 1 Code"), "Document No. 3" = Field("Shortcut Dimension 2 Code"), Date = Field("Start Date"), "Line No." = Field("Line No.");
            }
        }
    }
    actions
    {
        area(Processing)
        {
            group(RequestApproval)
            {
                Caption = 'Request Approval';
                action(ReOpnen)
                {
                    ApplicationArea = All;
                    Caption = 'ReOpen';
                    Image = ReOpen;
                    Enabled = (Rec.Status = Rec.Status::Rejected);
                    Trigger OnAction()
                    begin
                        if REC.Status = REC.Status::Rejected then
                            if Confirm('Do you want to ReOpen the Budget') then begin
                                REC.Status := rec.Status::Open;
                                Rec.Modify();
                            end;
                    end;
                }
            }
            group(Approval)
            {
                Caption = 'Approvals';
                action(Approve)
                {
                    Caption = 'Approve';
                    image = Approve;
                    ApplicationArea = all;
                    Visible = OpenApprovalEntriesExistCurrUser;

                    trigger OnAction()
                    var
                        Apprmgt: Codeunit "Approvals Mgmt.";
                    begin
                        Apprmgt.ApproveRecordApprovalRequest(rec.RecordId);
                    end;
                }
                action(Reject)
                {
                    Caption = 'Reject';
                    Image = Reject;
                    ApplicationArea = all;
                    Visible = OpenApprovalEntriesExistCurrUser;

                    trigger OnAction()
                    var
                        Apprmgt: Codeunit "Approvals Mgmt.";
                    begin
                        Apprmgt.RejectRecordApprovalRequest(rec.RecordId);
                    end;
                }
                action(Delegate)
                {
                    Caption = 'Delegate';
                    Image = Delegate;
                    ApplicationArea = all;
                    Visible = OpenApprovalEntriesExistCurrUser;

                    trigger OnAction()
                    var
                        Apprmgt: Codeunit "Approvals Mgmt.";
                    begin
                        Apprmgt.DelegateRecordApprovalRequest(rec.RecordId);
                    end;
                }
                action(Approvals)
                {
                    Caption = 'Approvals';
                    Image = Approvals;
                    ApplicationArea = all;
                    Visible = HasApprovalEntries;
                    trigger OnAction()
                    var
                        Apprmgt: Codeunit "Approvals Mgmt.";
                    begin
                        Apprmgt.OpenApprovalEntriesPage(Rec.RecordId);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Request to Approve';
                actionref(ReOpnen_Promoted; ReOpnen)
                {
                }
            }
            group(Approvalss)
            {
                Caption = 'Approvals';
                actionref(Approve_Promoted; Approve)
                {
                }
                actionref(Reject_Promoted; Reject)
                {
                }
                actionref(Delegate_Promoted; Delegate)
                {
                }
                actionref(Approvals_Promoted; Approvals)
                {
                }
            }
        }
    }

    var
        CancelApprovalForRecord: Boolean;
        EditableBoolean: Boolean;
        HasApprovalEntries: Boolean;
        OpenApprovalEntriesExist: Boolean;
        OpenApprovalEntriesExistCurrUser: Boolean;
        StyleExp: text;
        SanctionNoEditable: Boolean;
        OpenApprovalEntriesExistForCurrUser: Boolean;
        CanCancelApprovalForRecord: Boolean;
        CanRequestApprovalForFlow: Boolean;
        CanCancelApprovalForFlow: Boolean;
        UserSetUp: Record "User Setup";
        EditableFinace: Boolean;
        MAHEBudgetHeader: Record MAHEBudgetHeader;
        DimensionValue: Record "Dimension Value";
        MaheBudgetModifications: Codeunit MAHEBudgetModifications;
        BudgetedQtyVisible: Boolean;
        ShortCutDim1Visible: Boolean;
        ShortCutDim2Visible: Boolean;
        ShortCutDim3Visible: Boolean;

    trigger OnOpenPage()
    begin
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
    end;

    trigger OnAfterGetCurrRecord()
    var
        Apprmgt: Codeunit "Approvals Mgmt.";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        WorkflowWebhookMgt: Codeunit "Workflow Webhook Management";
    begin
        EditableBoolean := rec.StyleStatus(StyleExp);
        CancelApprovalForRecord := Apprmgt.CanCancelApprovalForRecord(rec.RecordId);
        WorkflowWebhookMgt.GetCanRequestAndCanCancel(Rec.RecordId(), CanRequestApprovalForFlow, CanCancelApprovalForFlow);
        OpenApprovalEntriesExistForCurrUser := ApprovalsMgmt.HasOpenApprovalEntriesForCurrentUser(Rec.RecordId());
        OpenApprovalEntriesExist := ApprovalsMgmt.HasOpenApprovalEntries(Rec.RecordId());
        CanCancelApprovalForRecord := ApprovalsMgmt.CanCancelApprovalForRecord(Rec.RecordId());
        HasApprovalEntries := ApprovalsMgmt.HasApprovalEntries(Rec.RecordId);
        OpenApprovalEntriesExistCurrUser := ApprovalsMgmt.HasOpenApprovalEntriesForCurrentUser(rec.RecordId);
    End;

    trigger OnAfterGetRecord()
    var
        Apprmgt: Codeunit "Approvals Mgmt.";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        WorkflowWebhookMgt: Codeunit "Workflow Webhook Management";
    Begin
        EditableBoolean := rec.StyleStatus(StyleExp);
        CancelApprovalForRecord := Apprmgt.CanCancelApprovalForRecord(rec.RecordId);
        WorkflowWebhookMgt.GetCanRequestAndCanCancel(Rec.RecordId(), CanRequestApprovalForFlow, CanCancelApprovalForFlow);
        OpenApprovalEntriesExistForCurrUser := ApprovalsMgmt.HasOpenApprovalEntriesForCurrentUser(Rec.RecordId());
        OpenApprovalEntriesExist := ApprovalsMgmt.HasOpenApprovalEntries(Rec.RecordId());
        CanCancelApprovalForRecord := ApprovalsMgmt.CanCancelApprovalForRecord(Rec.RecordId());
        HasApprovalEntries := ApprovalsMgmt.HasApprovalEntries(Rec.RecordId);
        OpenApprovalEntriesExistCurrUser := ApprovalsMgmt.HasOpenApprovalEntriesForCurrentUser(rec.RecordId);
    End;

    trigger OnModifyRecord(): Boolean
    var
        BudgetLockErr: Label 'Can not modify as this dimension %1 is locked in dimension value';
        BudgetLockMgmt: Codeunit "Budget Lock Matrix Mgt.";
    begin
        If MAHEBudgetHeader.Get(Rec."Budget Code") then;
        If BudgetLockMgmt.GetCellValue(rec."Shortcut Dimension 1 Code", Rec."Budget Code", False) Then
            Error(BudgetLockErr, Rec."Shortcut Dimension 1 Code");
    end;

    Trigger OnNewRecord(BelowxRec: Boolean)
    var
        DimensionTable: Record MAHEBudgetDimWise;
        TotalProposed: Decimal;
        TotalSanctioned: Decimal;
        TotalPIP: Decimal;
        TotalUtilized: Decimal;
        TotalReallocated: Decimal;
        TotalAmtUsedInRealloc: Decimal;
        TotalAdditional: Decimal;
    begin
        // Aggregate values from all Start Dates for the same Budget Code, No., Dim1, Dim2
        TotalProposed := 0;
        TotalSanctioned := 0;
        TotalPIP := 0;
        TotalUtilized := 0;
        TotalReallocated := 0;
        TotalAmtUsedInRealloc := 0;

        DimensionTable.Reset();
        DimensionTable.SetRange("Budget Code", REC."Budget Code");
        DimensionTable.SetRange("No.", REC."No.");
        DimensionTable.SetRange("Shortcut Dimension 1 Code", REC."Shortcut Dimension 1 Code");
        DimensionTable.SetRange("Shortcut Dimension 2 Code", REC."Shortcut Dimension 2 Code");
        // No filter on Start Date - aggregate all
        if DimensionTable.FindSet() then
            repeat
                TotalProposed += DimensionTable."Proposed Amount";
                TotalSanctioned += DimensionTable."Sanctioned Amount";
                TotalPIP += DimensionTable."PIP Amount";
                TotalUtilized += DimensionTable."Utilized Amount";
                TotalReallocated += DimensionTable."Reallocated Amount";
                TotalAmtUsedInRealloc += DimensionTable."Amount Used in Reallocation";
                // Take non-amount fields from first record
                if REC.Remarks = '' then begin
                    REC.Remarks := DimensionTable.Remarks;
                    REC.Justification := DimensionTable.Justification;
                    REC.Purpose := DimensionTable.Purpose;
                end;
            until DimensionTable.Next() = 0;

        REC."Proposed Amount" := TotalProposed;
        REC."Sanctioned Amount" := TotalSanctioned;
        REC."PIP Amount" := TotalPIP;
        REC."Utilized Amount" := TotalUtilized;
        REC."Reallocated Amount" := TotalReallocated;
        REC."Amount Used in Reallocation" := TotalAmtUsedInRealloc;

        // Calculate total additional budget across all start dates
        TotalAdditional := GetTotalAdditionalAcrossStartDates(
            REC."Budget Code", REC."No.",
            REC."Shortcut Dimension 1 Code", REC."Shortcut Dimension 2 Code");

        Rec."Balance Amount" := TotalAdditional + TotalSanctioned + TotalReallocated - TotalAmtUsedInRealloc - TotalPIP - TotalUtilized;
    end;

    local procedure GetTotalAdditionalAcrossStartDates(BudgetCode: Code[10]; No: Code[20]; Dim1: Code[20]; Dim2: Code[20]): Decimal
    var
        AdditionalBudget: Record MAHEAdditionalBudgetDimWise;
    begin
        AdditionalBudget.Reset();
        AdditionalBudget.SetRange("Budget Code", BudgetCode);
        AdditionalBudget.SetRange("No.", No);
        AdditionalBudget.SetRange("Shortcut Dimension 1 Code", Dim1);
        AdditionalBudget.SetRange("Shortcut Dimension 2 Code", Dim2);
        // No Start Date filter - aggregate across all
        AdditionalBudget.SetRange(Status, AdditionalBudget.Status::Approved);
        if AdditionalBudget.FindSet() then begin
            AdditionalBudget.CalcSums("Additional Budget Amount");
            exit(AdditionalBudget."Additional Budget Amount");
        end;
        exit(0);
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

    // Disable deletion of approved records
    trigger OnDeleteRecord(): Boolean
    begin
        if (Rec.Status = Rec.Status::Approved) or (Rec.Status = Rec.Status::Pending) then
            Error('You cannot delete any approved or pending records');
    end;
}
//PwC VS_GS --