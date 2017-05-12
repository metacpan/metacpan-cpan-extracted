package t::ToolSet::ExportFails;
use base 'ToolSet';

ToolSet->export( 'Bogus::Module' => undef, );

1; # return true
