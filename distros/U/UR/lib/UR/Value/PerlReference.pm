package UR::Value::PerlReference;

use strict;
use warnings;

require UR;
our $VERSION = "0.46"; # UR $VERSION;

UR::Object::Type->define(
    class_name => 'UR::Value::PerlReference',
    is => ['UR::Value'],
);


my %underlying_data_types;
sub underlying_data_types {
    my $class = shift;

    my $class_name = ref($class) ? $class->class_name : $class;

    unless (exists $underlying_data_types{$class_name}) {
        my($base_type) = ($class_name =~ m/^UR::Value::(.*)/);
        $underlying_data_types{$class_name} = [$base_type];
    }
    return @{$underlying_data_types{$class_name}};
}


1;
#$Header$
