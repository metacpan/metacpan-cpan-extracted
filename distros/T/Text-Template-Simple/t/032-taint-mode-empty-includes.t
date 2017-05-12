#!perl -Tw
use constant TAINTMODE => 1;
#!/usr/bin/env perl -w
use strict;
use warnings;
use Test::More qw( no_plan );
use Text::Template::Simple;
use Text::Template::Simple::Constants qw( EMPTY_STRING );

ok( my $t = Text::Template::Simple->new(), 'Got the object' );

my $template = <<'EMPTY';
<%+ t/data/empty.tts -%>
<%* t/data/empty.tts -%>
EMPTY

my $rv = eval { $t->compile( $template ); };

is( $@,  EMPTY_STRING, 'Empty includes (static+dynamic) did not die' );
is( $rv, EMPTY_STRING, 'Empty includes (static+dynamic) returned empty string' );
