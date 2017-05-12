#!perl -Tw
use constant TAINTMODE => 1;
#!/usr/bin/env perl -w
use strict;
use warnings;
use lib qw(t/lib lib);
use Test::More qw( no_plan );
use Text::Template::Simple;
use Cwd;
use MyUtil;

ok( my $t   = Text::Template::Simple->new(),      'Got the object' );
ok( my $out = $t->compile( 't/data/static.tts' ), 'Compile'        );

_p "OUTPUT: $out\n";

my $confirm = confirm();

is( $out, $confirm, 'Valid output from static inclusion' );

sub confirm {
    return <<'CONFIRMED';
RAW 1: raw content <%= $$ %>
RAW 2: raw content <%= $$ %>
RAW 3: raw content <%= $$ %>
CONFIRMED
}

