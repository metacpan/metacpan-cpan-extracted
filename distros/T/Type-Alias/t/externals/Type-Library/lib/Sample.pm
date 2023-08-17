package Sample;
use strict;
use warnings;

our @EXPORT_OK = qw( hello world Foo Bar );

use Type::Library -base, -declare => qw( Bar );
use Type::Alias -declare => [qw( Foo )];
use Types::Standard -types;

sub hello { "HELLO" }
sub world { "WORLD" }
type Foo => Str;

1;
