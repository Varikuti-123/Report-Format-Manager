table 70101 "RSF Execution Log"
{
    Caption = 'Execution Log';
    DataClassification = CustomerContent;
    LookupPageId = "RSF Execution Log List";
    DrillDownPageId = "RSF Execution Log List";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
            DataClassification = SystemMetadata;
        }
        field(2; "Report ID"; Integer)
        {
            Caption = 'Report ID';
            DataClassification = CustomerContent;
        }
        field(3; "Report Name"; Text[250])
        {
            Caption = 'Report Name';
            DataClassification = CustomerContent;
        }
        field(4; "Output Format"; Enum "RSF Output Format")
        {
            Caption = 'Output Format';
            DataClassification = CustomerContent;
        }
        field(5; "Action Type"; Enum "RSF Action Type")
        {
            Caption = 'Action Type';
            DataClassification = CustomerContent;
        }
        field(6; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(7; "Execution DateTime"; DateTime)
        {
            Caption = 'Execution DateTime';
            DataClassification = CustomerContent;
        }
        field(8; Status; Enum "RSF Execution Status")
        {
            Caption = 'Status';
            DataClassification = CustomerContent;
        }
        field(9; "Error Message"; Text[2048])
        {
            Caption = 'Error Message';
            DataClassification = CustomerContent;
        }
        field(10; "File Name"; Text[250])
        {
            Caption = 'File Name';
            DataClassification = CustomerContent;
        }
        field(11; "Duration (ms)"; Integer)
        {
            Caption = 'Duration (ms)';
            DataClassification = CustomerContent;
        }
        field(12; "Session ID"; Integer)
        {
            Caption = 'Session ID';
            DataClassification = CustomerContent;
        }
        field(13; "Email Sent To"; Text[250])
        {
            Caption = 'Email Sent To';
            DataClassification = CustomerContent;
        }
        field(14; "Setup Entry No."; Integer)
        {
            Caption = 'Setup Entry No.';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(UserDateTime; "User ID", "Execution DateTime")
        {
        }
        key(SetupEntry; "Setup Entry No.", "Execution DateTime")
        {
        }
        key(ReportID; "Report ID")
        {
        }
    }
}