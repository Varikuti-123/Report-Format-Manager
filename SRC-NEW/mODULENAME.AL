page 80405 "Module Name Input"
{
    PageType = StandardDialog;
    Caption = 'Enter Module Name';

    layout
    {
        area(Content)
        {
            field(ModuleName; ModuleNameInput)
            {
                ApplicationArea = All;
                Caption = 'Module Name';
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