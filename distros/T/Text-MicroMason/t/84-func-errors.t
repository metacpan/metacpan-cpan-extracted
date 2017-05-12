#!/usr/bin/perl -w

use strict;
use Test::More tests => 16;

use_ok 'Text::MicroMason', qw( compile execute try_compile try_execute );

######################################################################

my $scr_syn = '<b><% if ( 1 ) %></b>';
is eval { compile($scr_syn) }, undef;
like $@, qr/MicroMason compilation failed/;
like $@, qr/syntax error/;
is try_compile($scr_syn), undef;
is try_execute($scr_syn), undef;

my $scr_die = '<b><% die "FooBar" %></b>';
ok compile($scr_die);
is eval { execute($scr_die) }, undef;
like $@, qr/MicroMason execution failed/;
like $@, qr/FooBar/;
isa_ok try_compile($scr_die), 'CODE';
is try_execute($scr_die), undef;

# try_execute can return the $@
ok my ($r, $ok) = try_execute($scr_die);
is $r, undef;
like $ok, qr/MicroMason execution failed/;
like $ok, qr/FooBar/;
