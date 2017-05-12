#!perl -Tw
use constant TAINTMODE => 1;
#!/usr/bin/env perl -w
# Using Safe templates (tricky)
# SEE ALSO: t/lib/My.pm
use strict;
use warnings;
use lib qw(t/lib lib);
use Test::More qw( no_plan );
use MyUtil;

BEGIN {
   use_ok('Text::Template::Simple');
}

ok( my $t = Text::Template::Simple->new( safe => 1 ), 'Object created');

my $tmpl = q(<% my $name = shift %>Hello <%= $name %>, you are safe!);

ok( my $out = $t->compile( $tmpl, [ 'Burak' ] ), 'compile()');

ok( $out                               , 'Got compiled output' );
is( $out, q{Hello Burak, you are safe!}, 'Output is correct'   );

_p $out, "\n";
