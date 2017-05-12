#!perl

use 5.008;

use strict;
use warnings;

use Test::More tests => 4;

use App::Rgit::Config;
use App::Rgit::Utils qw/:levels/;

local $SIG{__WARN__} = sub { diag 'warning:',   @_ };
local $SIG{__DIE__}  = sub { diag 'exception:', @_ };

my %levels = (
 info => INFO,
 warn => WARN,
 err  => ERR,
 crit => CRIT,
);
my @levels = sort { $levels{$b} <=> $levels{$a} } keys %levels;

my $olderr;
open $olderr, '>&', \*STDERR or die "Can't dup STDERR: $!";

for my $l (0 .. $#levels) {
 my $arc = App::Rgit::Config->new(
  root  => 't',
  git   => 't/bin/git',
  debug => $levels{$levels[$l]},
 );
 my $buf = '';
 close STDERR;
 open STDERR, '>', \$buf or die "open(STDERR, '>', \\\$buf): $!";
 $arc->$_($_) for qw/info warn err crit/;
 is $buf, join('', @levels[$l .. $#levels]), "level $l ok";
}

close STDERR;
open STDERR, '>&', $olderr or die "Can't dup \$olderr: $!";
