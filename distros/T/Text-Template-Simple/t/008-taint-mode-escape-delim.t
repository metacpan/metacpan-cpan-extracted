#!perl -Tw
use constant TAINTMODE => 1;
#!/usr/bin/env perl -w
use strict;
use warnings;
use Test::More qw( no_plan );

BEGIN {
   use_ok('Text::Template::Simple');
}

ok(my $t = Text::Template::Simple->new,'object');

is( $t->compile(q/<%!f%>/), '<%f%>', 'Escaped delim 1' );
is( $t->compile(q/<%!f>/), '<%f>' ,  'Escaped delim 2' );
