package t::ToolSet::ExportBadType;
use base 'ToolSet';

ToolSet->export( 'Carp' => sub { 1 }, );

1; # return true
