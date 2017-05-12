package t::ToolSet::SelfExport;
use base 'ToolSet';

our @EXPORT = qw( wibble );

sub wibble { return "wibble" }

1; # return true
