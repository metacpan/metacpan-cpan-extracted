package Sample;
use strict;
use warnings;

use Exporter 'import';

our @EXPORT_OK = qw( hello world Foo );

use Types::Standard -types;
use Type::Alias -declare => [qw( Foo )];

sub hello { "HELLO" }
sub world { "WORLD" }
type Foo => Str;

1;
