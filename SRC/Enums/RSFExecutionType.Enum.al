enum 70102 "RSF Execution Status"
{
    Extensible = true;
    Caption = 'Execution Status';

    value(0; Success)
    {
        Caption = 'Success';
    }
    value(1; Failed)
    {
        Caption = 'Failed';
    }
    value(2; Cancelled)
    {
        Caption = 'Cancelled';
    }
}