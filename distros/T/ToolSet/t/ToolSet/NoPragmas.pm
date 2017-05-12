package t::ToolSet::NoPragmas;
use base 'ToolSet';

ToolSet->no_pragma('bogopragma');

1; # return true
