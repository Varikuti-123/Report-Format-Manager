page 80405 "Module Name Input"
{
    PageType = StandardDialog;
    Caption = 'Enter Module Name';
    
    layout
    {
        area(Content)
        {
            group(General)
            {
                field(ModuleNameField; ModuleNameInput)
                {
                    ApplicationArea = All;
                    Caption = 'Module Name';
                    
                    trigger OnValidate()
                    begin
                        if ModuleNameInput = '' then
                            Error('Module Name cannot be empty.');
                    end;
                }
            }
        }
    }
    
    var
        ModuleNameInput: Text[250];
    
    procedure GetModuleName(): Text[250]
    begin
        exit(ModuleNameInput);
    end;
}