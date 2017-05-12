#!perl -T
# /* vim:et: set ts=4 sw=4 sts=4 tw=78: */
#$Id: 06-complex-queries.t,v 1.2 2009/04/16 08:08:48 dinosau2 Exp $

use strict;
use warnings;

#use Test::More qw/no_plan/;
#use Test::More tests => 23;
use Test::More tests => 1;
use Data::Dumper qw/Dumper/;
use WWW::TasteKid;

# disabling tests for now
ok 'Maximum request rate exceeded. Please try again later, or contact us if you have any questions. Thank you.';
exit;




my $tskd = WWW::TasteKid->new;

$tskd->query({ type => 'music', name => 'bach' });
$tskd->query({ type => 'movie', name => 'amadeus' });
$tskd->query({ type => 'book',  name => 'star trek' });
$tskd->ask({ filter => 'music', verbose => 1 });
#warn $tskd->get_encoded_query; # inspect what in the query

## start for dev, test locally
#use LWP::Simple;
#use File::Basename qw/dirname/;
#use Cwd 'abs_path';
#$tskd->set_xml_result(
#    get('file:///'.dirname(abs_path(__FILE__)).'/data/bach_beethoven_mozart.xml')
#);
## end for dev, test locally

my $info = $tskd->info_resource;

my @res = ();
foreach my $tkr (@{$info}) {
    push @res, ($tkr->name, $tkr->type);
}

my $r = [
          'Johann Sebastian Bach',
          'music',
          'Amadeus',
          'movie',
          'Star Trek',
          'book'
        ];
is_deeply \@res, $r;


my $res = $tskd->results_resource;

my $t = 0;
my $tr = scalar @{$res};
foreach my $tkr (@{$res}) {
    # good, they all eq music,...
    # we filtered for music results only
    is $tkr->type, 'music';
    $t++;
}

ok $tr > 10, 'there should be more than 10 results';
is $t, $tr;

