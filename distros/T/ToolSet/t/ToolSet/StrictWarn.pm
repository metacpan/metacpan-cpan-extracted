package t::ToolSet::StrictWarn;
use base 'ToolSet';

ToolSet->use_pragma('strict');
ToolSet->use_pragma('warnings');

1; # return true
