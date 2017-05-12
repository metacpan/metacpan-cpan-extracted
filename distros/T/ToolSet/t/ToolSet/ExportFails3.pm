package t::ToolSet::ExportFails3;
use base 'ToolSet';

ToolSet->export( 'Bogus::Module' );

1; # return true
