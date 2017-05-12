use strict;
use warnings;
package MooseyParameterizedRole;

use MooseX::Role::Parameterized;
with 'MooseyRole';
use Scalar::Util 'reftype';
use namespace::autoclean;

parameter foo => ( is => 'ro', isa => 'Str' );

role {
    1;
};

sub parameterized_role_stuff {}

use constant CAN => [ qw(role_stuff parameterized_role_stuff meta) ];
use constant CANT => [ qw(has with parameter role reftype) ];
1;
