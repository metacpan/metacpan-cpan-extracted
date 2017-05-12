package t::ToolSet::SelfExportFails;
use base 'ToolSet';

our @EXPORT = qw( wobble );

1; # return true
