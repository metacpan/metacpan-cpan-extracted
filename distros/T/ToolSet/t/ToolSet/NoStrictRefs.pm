package t::ToolSet::NoStrictRefs;
use base 'ToolSet';

ToolSet->use_pragma('strict');
ToolSet->no_pragma( 'strict', 'refs' );

1; # return true
