package UR::DataSource::ValueDomain;
use strict;
use warnings;

require UR;
our $VERSION = "0.46"; # UR $VERSION;

UR::Object::Type->define(
    class_name => 'UR::DataSource::ValueDomain',
    is => ['UR::DataSource'],
    is_abstract => 1,
    properties => [
    ],
    doc => 'A logical DBI-based database, independent of prod/dev/testing considerations or login details.',
);


sub get_objects_for_rule {        
    my $class = shift;    
    my $rule = shift;
    my $obj = $UR::Context::current->_construct_object($rule);
    $obj->__signal_change__("define");
    return $obj;
}

1;
