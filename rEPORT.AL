report 50213 MaheGSRepairMain
{
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    DefaultLayout = RDLC;
    Caption = 'GS R & M';
    RDLCLayout = './WO_SRC/Report Layouts/GS R & M.rdlc';

    dataset
    {
        dataitem(MainRow; Integer)
        {
            column(CompanyName; CompanyInfo.Name) { }
            column(CompanyPicture; CompanyInfo.Picture) { }
            column(No; No) { }
            column(Type; Type) { }
            column(BusinessUnit; BusinessUnitCode) { }
            column(MainSerialNo; Number) { }
            column(BusinessUnitName; BusinessUnitName) { }
            column(UtilzedAmount; UtilzedAmount) { }

            dataitem(SubRow; Integer)
            {
                column(SubSerialNo; SubSerilaNo) { }
                column(Department; DepartmentCode) { }
                column(DepartmentName; DepartmentName) { }

                dataitem(Columns; Integer)
                {
                    column(Traiff; TraiffCode) { }
                    column(Amount; Amount) { }

                    trigger OnPreDataItem()
                    begin
                        if ColNoKeyDict.Count = 0 then
                            CurrReport.Break();
                        SetRange(Number, 1, ColNoKeyDict.Count);
                    end;

                    trigger OnAfterGetRecord()
                    var
                        BudgetDimensionWise: Record MAHEBudgetDimWise;
                        CurrentTraiff: Code[500];
                        CurrentGLFilter: Text;
                        CurrentDim2: Code[20];
                        CurrentDim1: Code[20];
                    begin
                        Clear(Amount);
                        Clear(TraiffCode);

                        // Safely get Traiff code
                        if not ColNoKeyDict.ContainsKey(Columns.Number) then
                            CurrReport.Skip();
                        CurrentTraiff := ColNoKeyDict.Get(Columns.Number);
                        TraiffCode := CurrentTraiff;

                        // Safely get GL filter
                        if not TraiffGlAccDict.ContainsKey(CurrentTraiff) then
                            CurrReport.Skip();
                        CurrentGLFilter := TraiffGlAccDict.Get(CurrentTraiff);

                        // Safely get Dimension codes
                        if not SafeGetSubRowValue(SubRow.Number, CurrentDim2) then
                            CurrReport.Skip();
                        if not SafeGetMainRowValue(MainRow.Number, CurrentDim1) then
                            CurrReport.Skip();

                        BudgetDimensionWise.Reset();
                        BudgetDimensionWise.SetRange("Budget Code", BudgetCode);
                        BudgetDimensionWise.SetRange("Shortcut Dimension 2 Code", CurrentDim2);
                        BudgetDimensionWise.SetRange("Shortcut Dimension 1 Code", CurrentDim1);
                        BudgetDimensionWise.SetFilter("No.", CurrentGLFilter);
                        if BudgetDimensionWise.FindSet() then
                            repeat
                                Amount += BudgetDimensionWise.UpdateTotalAdditional(BudgetDimensionWise) +
                                          BudgetDimensionWise."Sanctioned Amount" +
                                          BudgetDimensionWise."Reallocated Amount" -
                                          BudgetDimensionWise."Amount Used in Reallocation" -
                                          BudgetDimensionWise."PIP Amount" -
                                          BudgetDimensionWise."Utilized Amount";
                            until BudgetDimensionWise.Next() = 0;
                    end;
                }

                trigger OnPreDataItem()
                var
                    MainRowKey: Code[20];
                begin
                    Clear(SubRowValueDict);

                    // Safely get the MainRow key
                    if not RowNoKeyDict.ContainsKey(MainRow.Number) then begin
                        CurrReport.Break();
                        exit;
                    end;
                    MainRowKey := RowNoKeyDict.Get(MainRow.Number);

                    // Safely get the SubRow dictionary for this MainRow
                    if not RowSubRowValueDict.ContainsKey(MainRowKey) then begin
                        CurrReport.Break();
                        exit;
                    end;
                    SubRowValueDict := RowSubRowValueDict.Get(MainRowKey);

                    if SubRowValueDict.Count = 0 then begin
                        CurrReport.Break();
                        exit;
                    end;

                    SetRange(Number, 1, SubRowValueDict.Count);
                end;

                trigger OnAfterGetRecord()
                var
                    CurrentDepartmentCode: Code[20];
                begin
                    Clear(SubSerilaNo);
                    Clear(DepartmentName);
                    Clear(DepartmentCode);

                    // Safely get department code
                    if not SubRowValueDict.ContainsKey(SubRow.Number) then
                        CurrReport.Skip();

                    CurrentDepartmentCode := SubRowValueDict.Get(SubRow.Number);
                    DepartmentCode := CurrentDepartmentCode;

                    // Get department name
                    DimensionValue.Reset();
                    DimensionValue.SetRange("Global Dimension No.", 3);
                    DimensionValue.SetRange(Code, CurrentDepartmentCode);
                    if DimensionValue.FindFirst() then
                        DepartmentName := DimensionValue.Name
                    else
                        DepartmentName := CurrentDepartmentCode; // Fallback to code if name not found

                    // Build serial number safely
                    if SubRow.Number > 0 then
                        SubSerilaNo := Format(MainRow.Number) + SafeGetAlphabet(SubRow.Number)
                    else
                        SubSerilaNo := Format(MainRow.Number);
                end;
            }

            trigger OnPreDataItem()
            begin
                if RowNoKeyDict.Count = 0 then
                    CurrReport.Break();
                SetRange(Number, 1, RowNoKeyDict.Count);
            end;

            trigger OnAfterGetRecord()
            var
                BudgetDimensionWise: Record MAHEBudgetDimWise;
                CurrentDim1Code: Code[20];
            begin
                Clear(BusinessUnitName);
                Clear(BusinessUnitCode);
                Clear(UtilzedAmount);

                // Safely get dimension 1 code
                if not RowNoKeyDict.ContainsKey(MainRow.Number) then
                    CurrReport.Skip();

                CurrentDim1Code := RowNoKeyDict.Get(MainRow.Number);
                BusinessUnitCode := CurrentDim1Code;

                // Get business unit name
                DimensionValue.Reset();
                DimensionValue.SetRange("Global Dimension No.", 2);
                DimensionValue.SetRange(Code, CurrentDim1Code);
                if DimensionValue.FindFirst() then
                    BusinessUnitName := DimensionValue.Name
                else
                    BusinessUnitName := CurrentDim1Code; // Fallback to code if name not found

                // Calculate UtilzedAmount per MainRow
                BudgetDimensionWise.Reset();
                BudgetDimensionWise.SetRange("Budget Code", BudgetCode);
                BudgetDimensionWise.SetRange("Shortcut Dimension 1 Code", CurrentDim1Code);
                if GLAccountFilter <> '' then
                    BudgetDimensionWise.SetFilter("No.", GLAccountFilter);
                if BudgetDimensionWise.FindSet() then
                    repeat
                        UtilzedAmount += BudgetDimensionWise."Utilized Amount";
                    until BudgetDimensionWise.Next() = 0;
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Filters)
                {
                    field(ReportNo; No)
                    {
                        Caption = 'GS No.';
                        TableRelation = "MAHE GS Budget Header"."No." where(Type = filter("Repair and Maintenance (R&M) Budget"));
                        ApplicationArea = All;

                        trigger OnValidate()
                        begin
                            if No = '' then
                                Error('Please select a valid GS No.');
                        end;
                    }
                }
            }
        }

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            if CloseAction = Action::OK then
                if No = '' then begin
                    Message('Please select a GS No. before running the report.');
                    exit(false);
                end;
            exit(true);
        end;
    }

    procedure SetParaMeters(var CapitalNo: Code[20])
    begin
        No := CapitalNo;
    end;

    trigger OnInitReport()
    begin
        if CompanyInfo.Get() then
            CompanyInfo.CalcFields(Picture);
    end;

    trigger OnPreReport()
    begin
        GLSetup.Get();

        // Initialize alphabet list
        InitAlphabetList();

        // Validate input
        if No = '' then
            Error('GS No. must be specified.');

        // Build column dictionaries
        BuildColumnDictionaries();

        // Build row and sub-row dictionaries
        BuildRowDictionaries();
    end;

    // ============================================================
    // BUILD COLUMN DICTIONARIES
    // ============================================================
    local procedure BuildColumnDictionaries()
    var
        GSBudgetHeader: Record "MAHE GS Budget Header";
        GSBudgetLine: Record MAHE_GSRMBudgetLine;
        J: Integer;
        ExistingFilter: Text;
    begin
        GSBudgetHeader.Reset();
        GSBudgetHeader.SetRange(Type, GSBudgetHeader.Type::"Repair and Maintenance (R&M) Budget");
        GSBudgetHeader.SetRange("No.", No);
        if not GSBudgetHeader.FindFirst() then
            Error('GS Budget Header not found for No. %1', No);

        BudgetCode := GSBudgetHeader."Budget Code";
        Type := Format(GSBudgetHeader.Type);

        GSBudgetLine.Reset();
        GSBudgetLine.SetRange(Type, GSBudgetLine.Type::"Repair and Maintenance (R&M) Budget");
        GSBudgetLine.SetRange("Document No.", GSBudgetHeader."No.");
        GSBudgetLine.SetFilter("Traiff/RM", '<>%1', '');
        if GSBudgetLine.FindSet() then
            repeat
                // Build Traiff to GL Account mapping
                if not TraiffGlAccDict.ContainsKey(GSBudgetLine."Traiff/RM") then begin
                    J := J + 1;
                    TraiffGlAccDict.Add(GSBudgetLine."Traiff/RM", GSBudgetLine."G/L Account");
                    ColNoKeyDict.Add(J, GSBudgetLine."Traiff/RM");
                end else begin
                    ExistingFilter := TraiffGlAccDict.Get(GSBudgetLine."Traiff/RM");
                    // Check if GL Account already exists in filter to avoid duplicates
                    if StrPos(ExistingFilter, GSBudgetLine."G/L Account") = 0 then begin
                        ExistingFilter := ExistingFilter + '|' + GSBudgetLine."G/L Account";
                        TraiffGlAccDict.Set(GSBudgetLine."Traiff/RM", ExistingFilter);
                    end;
                end;

                // Build GL Account filter - avoid duplicates
                if GLAccountFilter = '' then
                    GLAccountFilter := GSBudgetLine."G/L Account"
                else begin
                    if StrPos(GLAccountFilter, GSBudgetLine."G/L Account") = 0 then
                        GLAccountFilter := GLAccountFilter + '|' + GSBudgetLine."G/L Account";
                end;
            until GSBudgetLine.Next() = 0;
    end;

    // ============================================================
    // BUILD ROW DICTIONARIES
    // ============================================================
    local procedure BuildRowDictionaries()
    var
        BudgetDimensionWise: Record MAHEBudgetDimWise;
        Dim1Code: Code[20];
        Dim2Code: Code[20];
        TempSubDict: Dictionary of [Integer, Code[20]];
        K: Integer;
        SubCount: Integer;
    begin
        BudgetDimensionWise.Reset();
        BudgetDimensionWise.SetRange("Budget Code", BudgetCode);
        if GLAccountFilter <> '' then
            BudgetDimensionWise.SetFilter("No.", GLAccountFilter);
        BudgetDimensionWise.SetCurrentKey("Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        BudgetDimensionWise.SetAscending("Shortcut Dimension 1 Code", true);
        BudgetDimensionWise.SetAscending("Shortcut Dimension 2 Code", true);

        if BudgetDimensionWise.FindSet() then
            repeat
                Dim1Code := BudgetDimensionWise."Shortcut Dimension 1 Code";
                Dim2Code := BudgetDimensionWise."Shortcut Dimension 2 Code";

                // Skip empty dimension codes
                if (Dim1Code <> '') and (Dim2Code <> '') then begin
                    if not RowSubRowValueDict.ContainsKey(Dim1Code) then begin
                        // New Dimension 1 Code - create new entry
                        Clear(TempSubDict);
                        TempSubDict.Add(1, Dim2Code);
                        K := K + 1;
                        RowNoKeyDict.Add(K, Dim1Code);
                        RowSubRowValueDict.Add(Dim1Code, TempSubDict);
                    end else begin
                        // Existing Dimension 1 Code - check if Dimension 2 already exists
                        Clear(TempSubDict);
                        TempSubDict := RowSubRowValueDict.Get(Dim1Code);

                        // Check ALL existing entries for duplicate
                        if not SubDictContainsValue(TempSubDict, Dim2Code) then begin
                            SubCount := TempSubDict.Count + 1;
                            TempSubDict.Add(SubCount, Dim2Code);
                            RowSubRowValueDict.Set(Dim1Code, TempSubDict);
                        end;
                    end;
                end;
            until BudgetDimensionWise.Next() = 0;
    end;

    // ============================================================
    // CHECK IF DICTIONARY ALREADY CONTAINS A VALUE
    // ============================================================
    local procedure SubDictContainsValue(var Dict: Dictionary of [Integer, Code[20]]; ValueToFind: Code[20]): Boolean
    var
        idx: Integer;
        KeysList: List of [Integer];
        CurrentKey: Integer;
    begin
        KeysList := Dict.Keys;
        foreach CurrentKey in KeysList do begin
            if Dict.Get(CurrentKey) = ValueToFind then
                exit(true);
        end;
        exit(false);
    end;

    // ============================================================
    // SAFE GET METHODS - PREVENT DICTIONARY KEY ERRORS
    // ============================================================
    local procedure SafeGetMainRowValue(KeyNo: Integer; var ResultCode: Code[20]): Boolean
    begin
        Clear(ResultCode);
        if RowNoKeyDict.ContainsKey(KeyNo) then begin
            ResultCode := RowNoKeyDict.Get(KeyNo);
            exit(true);
        end;
        exit(false);
    end;

    local procedure SafeGetSubRowValue(KeyNo: Integer; var ResultCode: Code[20]): Boolean
    begin
        Clear(ResultCode);
        if SubRowValueDict.ContainsKey(KeyNo) then begin
            ResultCode := SubRowValueDict.Get(KeyNo);
            exit(true);
        end;
        exit(false);
    end;

    // ============================================================
    // SAFE ALPHABET GENERATION
    // ============================================================
    local procedure SafeGetAlphabet(Num: Integer): Text
    begin
        if Num <= 0 then
            exit('');

        // Safety check - should never happen but prevents infinite recursion
        if Num > 17576 then // 26 * 26 * 26 = max 3 letter combinations
            exit(Format(Num));

        exit(GetAlphabet(Num));
    end;

    local procedure GetAlphabet(Num: Integer): Text
    var
        Remainder: Integer;
        Quotient: Integer;
    begin
        if Num <= 0 then
            exit('');

        if Num <= 26 then begin
            if AlphabetList.ContainsKey(Num) then
                exit(AlphabetList.Get(Num))
            else
                exit(Format(Num)); // Fallback - should never happen
        end;

        Remainder := Num mod 26;
        Quotient := Num div 26;

        // When remainder is 0, the last letter is 'z' (26th)
        // and we need to reduce the quotient by 1
        if Remainder = 0 then begin
            Remainder := 26;
            Quotient := Quotient - 1;
        end;

        if Quotient = 0 then begin
            if AlphabetList.ContainsKey(Remainder) then
                exit(AlphabetList.Get(Remainder))
            else
                exit(Format(Remainder));
        end else
            if Quotient <= 26 then begin
                if AlphabetList.ContainsKey(Quotient) and AlphabetList.ContainsKey(Remainder) then
                    exit(AlphabetList.Get(Quotient) + AlphabetList.Get(Remainder))
                else
                    exit(Format(Quotient) + Format(Remainder));
            end else
                exit(GetAlphabet(Quotient) + GetAlphabet(Remainder));
    end;

    // ============================================================
    // INITIALIZE ALPHABET LIST
    // ============================================================
    local procedure InitAlphabetList()
    var
        i: Integer;
        CharCode: Integer;
    begin
        Clear(AlphabetList);
        for i := 1 to 26 do begin
            CharCode := 96 + i; // ASCII 'a' = 97
            AlphabetList.Add(i, Format(ConvertCharCodeToText(CharCode)));
        end;
    end;

    local procedure ConvertCharCodeToText(CharCode: Integer): Text
    begin
        case CharCode of
            97:
                exit('a');
            98:
                exit('b');
            99:
                exit('c');
            100:
                exit('d');
            101:
                exit('e');
            102:
                exit('f');
            103:
                exit('g');
            104:
                exit('h');
            105:
                exit('i');
            106:
                exit('j');
            107:
                exit('k');
            108:
                exit('l');
            109:
                exit('m');
            110:
                exit('n');
            111:
                exit('o');
            112:
                exit('p');
            113:
                exit('q');
            114:
                exit('r');
            115:
                exit('s');
            116:
                exit('t');
            117:
                exit('u');
            118:
                exit('v');
            119:
                exit('w');
            120:
                exit('x');
            121:
                exit('y');
            122:
                exit('z');
            else
                exit('');
        end;
    end;

    var
        No: Code[20];
        Type: Text;
        Amount: Decimal;
        ColNoKeyDict: Dictionary of [Integer, Code[500]];
        RowNoKeyDict: Dictionary of [Integer, Code[20]];
        RowSubRowValueDict: Dictionary of [Code[20], Dictionary of [Integer, Code[20]]];
        SubRowValueDict: Dictionary of [Integer, Code[20]];
        GLAccountFilter: Text;
        AlphabetList: Dictionary of [Integer, Text];
        TraiffGlAccDict: Dictionary of [Code[500], Text];
        BudgetCode: Code[20];
        DimensionValue: Record "Dimension Value";
        GLSetup: Record "General Ledger Setup";
        BusinessUnitName: Text;
        BusinessUnitCode: Code[20];
        DepartmentName: Text;
        DepartmentCode: Code[20];
        TraiffCode: Code[500];
        UtilzedAmount: Decimal;
        SubSerilaNo: Text;
        CompanyInfo: Record "Company Information";
}