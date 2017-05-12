use 5.008001;
use strict;
use warnings;

package TestThrower;

use Exporter;
our @ISA    = qw/Exporter/;
our @EXPORT = qw(
  deep_throw
);
our @CARP_NOT = qw/Foo/;

sub deep_throw { Foo::foo(@_) }

package Foo;

our @CARP_NOT = qw/Bar/;

sub foo { Bar::bar(@_) }

package Bar;

our @CARP_NOT = qw/Baz/;

sub bar { Baz::baz(@_) }

package Baz;

sub baz {
    my ( $class, $msg, $trace_method ) = @_;
    $class->throw( { msg => $msg, trace => failure->$trace_method } );
}

1;

