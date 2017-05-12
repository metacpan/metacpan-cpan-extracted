package BigApp::Report::Create;
require Exporter;
$VERSION = 2.16;
@ISA     = qw(Exporter);
@EXPORT  = qw(new_report);
sub new_report { return bless {} }
1
