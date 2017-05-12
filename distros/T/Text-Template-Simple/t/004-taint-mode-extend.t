#!perl -Tw
use constant TAINTMODE => 1;
#!/usr/bin/env perl -w
# Extending Text::Template::Simple with functions and globals
# SEE ALSO: t/lib/My.pm
use strict;
use warnings;
use lib qw(t/lib lib);
use Test::More qw( no_plan );
use Data::Dumper;
use Carp qw();
use My;
use MyUtil;

BEGIN {
   use_ok('Text::Template::Simple');
}

ok($My::VERSION, 'My::VERSION defined');

my $info = "Extending Text::Template::Simple with My v$My::VERSION\n";

_p $info;

ok( my $t = Text::Template::Simple->new, 'Object created');

my $tmpl = <<'THE_TEMPLATE';
<% my $url = shift %>
Function call  : <%=      hello  "Burak"          %>
Global variable: X is <%= $GLOBAL{X}              %>
THE_TEMPLATE

ok( my $out = $t->compile( $tmpl, [ 'http://search.cpan.org/' ] ), 'Compiled');

ok( $out, 'Got output' );

my $d = Data::Dumper->new(
           [ \%Text::Template::Simple::Dummy:: ],
           [ '*SYMBOL'                         ]
        );

_p $out, "\nDumping template namespace symbol table ...\n", $d->Dump;
