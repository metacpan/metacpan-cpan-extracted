package t::ToolSet::ExportFails2;
use base 'ToolSet';

ToolSet->export( 'Bogus::Module' => [], );

1; # return true
