#!perl -T
# /* vim:et: set ts=4 sw=4 sts=4 tw=78: */
#$Id: 05-results-resource.t,v 1.4 2009/09/23 06:12:10 dinosau2 Exp $

use strict;
use warnings;

#use Test::More qw/no_plan/;
#use Test::More tests => 22;
use Test::More tests => 1;
use Data::Dumper qw/Dumper/;
use Encode qw/decode encode/;
use WWW::TasteKid;
use URI;


# disabling tests for now
ok 'Maximum request rate exceeded. Please try again later, or contact us if you have any questions. Thank you.';
exit;



my $tskd = WWW::TasteKid->new;
$tskd->query({ type => 'music', name => 'bach' });
# show in example
#my $debug_query = $tskd->query_inspection; # inspect what in the query
#warn $debug_query;
$tskd->ask({ verbose => 1 });
my $res = $tskd->results_resource;

# order may change but these 4 should remain 'suggested' from bach,... (I hope)
#use utf8;
my @expected_in_res = (
   'George Frideric Handel',
   'Johannes Brahms',
   'Gustav Mahler',
   'Igor Stravinsky', # consistenly in results
   #'Joseph Haydn',
   #'Johannes Brahms',
   #"Anton\x{ed}n Leopold Dvo\x{159}\x{e1}k"
   #'Antonín Leopold Dvořák'
);

my @received = ();
my $seen = 0;
foreach my $r (@{$res}){
    #warn $r->name;
    if ( scalar grep { $r->name eq encode('utf8',$_) } @expected_in_res ) {
        push @received, $r;
        $seen++;
    }
}
#pop @received;
is $seen, scalar @expected_in_res;
is scalar @received, 4;
pop @received; # an array of result objects


# now check verbose data
my $tskdr1 = WWW::TasteKidResult->new;
$tskdr1->name('George Frideric Handel');
$tskdr1->type('music');
$tskdr1->wteaser(q{George Frideric Handel});
$tskdr1->wurl('http://en.wikipedia.org/wiki/George_Frideric_Handel');
#$tskdr1->ytitle(q{George Frideric Handel - Messiah "Hallelujah!"});
$tskdr1->ytitle(q{George Frideric Handel - });
$tskdr1->yurl(q{http://www.youtube.com/v/3uOabPZScQs&f=videos&c=TasteKid&app=youtube_gdata});
 
my $tskdr2 = WWW::TasteKidResult->new;
$tskdr2->name('Johannes Brahms');
$tskdr2->type('music');
$tskdr2->wteaser(q{Johannes Brahms});
$tskdr2->wurl('http://en.wikipedia.org/wiki/Johannes_Brahms');
$tskdr2->ytitle(q{Johannes Brahms-});
$tskdr2->yurl(q{http://www.youtube.com/v/TJcoaIeH3GI&f=videos&c=TasteKid&app=youtube_gdata});

#my $tskdr3 = WWW::TasteKidResult->new;
#$tskdr3->name('Joseph Haydn');
#$tskdr3->type('music');
#$tskdr3->wteaser(q{(Franz) Joseph Haydn});
#$tskdr3->wurl('http://en.wikipedia.org/wiki/Joseph_Haydn');
#$tskdr3->ytitle(q{Joseph Haydn - Piano Sonata in Eb});
#$tskdr3->yurl(q{http://www.youtube.com/v/Vkse1g9ibnM&f=videos&c=TasteKid&app=youtube_gdata});

my @r_obj = ($tskdr1,$tskdr2);  

for my $i (0..1){

    next unless isa_ok($received[$i], 'WWW::TasteKidResult');
    is $received[$i]->name, $r_obj[$i]->name;

    is $received[$i]->type, $r_obj[$i]->type;

    my $exp =  $r_obj[$i]->wteaser;
    ok substr($received[$i]->wteaser, 0, 35) =~ /$exp/i;

    #is $received[$i]->wurl,   $r_obj[$i]->wurl;
    my $url_got = URI->new($received[$i]->wurl);
    my $url_exp = URI->new($r_obj[$i]->wurl);
    is $url_got->host, $url_exp->host;

    # at least first name in url
    my $u = $url_got->as_string;
    my ($f) = split /\s+/, $r_obj[$i]->name, 3;
    ok $f.'_' =~ /$u/;

    $exp =  $r_obj[$i]->ytitle;
    ok $received[$i]->ytitle =~ /$exp/;

    #is $received[$i]->yurl,   $r_obj[$i]->yurl;
    my $u_got = URI->new($received[$i]->yurl);
    my $u_exp = URI->new($r_obj[$i]->yurl);
    is $u_got->host, $u_exp->host, 

    my $s = $u_exp->as_string;
    ok $s =~ /TasteKid/;
    ok $s =~ /youtube_gdata/;
}


## start for dev, test locally
#use LWP::Simple;
#$tskd->set_xml_result(
#    get('file:///'.dirname(abs_path(__FILE__)).'/data/bach_verbose.xml')
#);
## end for dev, test locally
