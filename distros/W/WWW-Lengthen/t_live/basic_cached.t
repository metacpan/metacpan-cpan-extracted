use strict;
use warnings;
use Test::More;

BEGIN{
  eval "use Cache::Memcached; 1"
  or plan skip_all => "requires Cache::Memcached";
};

use WWW::Lengthen::Cached;
use t_live::urllist;

my %tests = t_live::urllist->basic_tests;

my $l = WWW::Lengthen::Cached->new;
$l->setup_cached( Cache::Memcached->new );
foreach my $name ( sort keys %tests ) {
  my ($long, $short) = @{ $tests{$name} || []};
  unless ($long && $short) {
    warn "$name is disabled";
    next;
  }
  my $got = $l->try( $short ) || '';
  ok $got eq $long, "$name: $got";
  sleep 1;
}

foreach my $name ( sort keys %tests ) {
  my ($long, $short) = @{ $tests{$name} || []};
  unless ($long && $short) {
    warn "$name is disabled";
    next;
  }
  my $got = $l->try( $short ) || '';
  ok $got eq $long, "$name: $got";
  sleep 1;
}

done_testing;
