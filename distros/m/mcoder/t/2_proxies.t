package Other;

sub run { "running" }

sub talk { shift; join('-', 'talk', @_) }

sub new { bless {}, shift }



package One;

use mcoder proxy => [other => qw( talk run )];

sub other { shift->{other} }

sub new { bless {other => Other->new}, shift }



package testing;
use Test::More tests => 3;


my $o=One->new;

is($o->run, 'running', 'first proxy');

is($o->talk, 'talk', 'second proxy');

is($o->talk(qw(hello world)),
   'talk-hello-world', 'second proxy with args');

