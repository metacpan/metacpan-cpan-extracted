package t::ToolSet::UseFeature;
use base 'ToolSet';

ToolSet->use_pragma(qw/feature :5.10/);

1; # return true
