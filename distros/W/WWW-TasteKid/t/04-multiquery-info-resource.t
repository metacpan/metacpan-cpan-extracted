#!perl -T
# /* vim:et: set ts=4 sw=4 sts=4 tw=78: */
#$Id: 04-multiquery-info-resource.t,v 1.3 2009/04/17 05:10:00 dinosau2 Exp $

use strict;
use warnings;

#use Test::More tests => 32;
#use Test::More tests => 29;
use Test::More tests => 1;
use WWW::TasteKid;


# disabling tests for now
ok 'Maximum request rate exceeded. Please try again later, or contact us if you have any questions. Thank you.';
exit;


my $tskd = WWW::TasteKid->new;

## start for dev, test locally
#use LWP::Simple;
#use File::Basename qw/dirname/;
#use Cwd 'abs_path';
#$tskd->set_xml_result(
#    get('file:///'.dirname(abs_path(__FILE__)).'/data/bach_beethoven_mozart.xml')
#);
# end for dev, test locally

{
  $tskd->query({ name => 'bach' });
  $tskd->query({ name => 'beethoven' });
  $tskd->query({ name => 'mozart' });
  $tskd->ask;
  
  my $res = $tskd->info_resource;
  
  is $res->[0]->name, 'Johann Sebastian Bach';
  is $res->[1]->name, 'Ludwig Van Beethoven';
  is $res->[2]->name, 'Wolfgang Amadeus Mozart';
  
  # we didn't specify a type, so the obvious one is returned
  is $res->[0]->type, 'music';
  is $res->[1]->type, 'music';
  is $res->[2]->type, 'music';
}

{
  $tskd->query({ type => 'music', name => 'bach' });
  $tskd->query({ type => 'music', name => 'beethoven' });
  $tskd->query({ type => 'music', name => 'mozart' });
  $tskd->ask;
  my $res = $tskd->info_resource;
 
  # retured in order recieved
  my @expected = ('Johann Sebastian Bach',
                  'Ludwig Van Beethoven',
                  'Wolfgang Amadeus Mozart');
  
  my @result = ();
  foreach my $r (@{$res}){
      push @result, $r->name;
  }
  
  is scalar @expected, scalar @result;
  is_deeply \@expected, \@result;
}


$tskd->query({ type => 'music', name => 'bach' });
$tskd->query({ type => 'music', name => 'beethoven' });
$tskd->query({ type => 'music', name => 'mozart' });
$tskd->ask({ verbose => 1 });

## start for dev, test locally
#use LWP::Simple;
#use File::Basename qw/dirname/;
#use Cwd 'abs_path';
#$tskd->set_xml_result(
#    get('file:///'.dirname(abs_path(__FILE__)).'/data/bach_beethoven_mozart_verbose.xml')
#);
## end for dev, test locally

my $res = $tskd->info_resource;

# return hash ref, specify by element
is $res->[0]->name, 'Johann Sebastian Bach';
is $res->[0]->type, 'music';

ok $res->[0]->wteaser =~ m{johann sebastian bach}ims; # 'x' causes it to not match!

ok $res->[0]->wurl =~ m{http://en.wikipedia.org/wiki}xms;
ok $res->[0]->wurl =~ m{bach}ixms;

ok $res->[0]->ytitle =~ m{bach}ixms;

ok $res->[0]->yurl =~ m{http://www.youtube.com}xms;
ok $res->[0]->yurl =~ m{f=videos&c=TasteKid&app=youtube_gdata}xms;

# add for 
is $res->[1]->name, 'Ludwig Van Beethoven';
is $res->[1]->type, 'music';
ok $res->[1]->wteaser =~ m{ludwig van beethoven}msi;

ok $res->[1]->wurl =~ m{http://en.wikipedia.org/wiki}xms;
ok $res->[1]->wurl =~ m{beethoven}ixms;

#ok $res->[1]->ytitle =~ m{beethoven}ixms;
#ok $res->[1]->yurl =~ m{http://www.youtube.com}xms;
#ok $res->[1]->yurl =~ m{f=videos&c=TasteKid&app=youtube_gdata}xms;

is $res->[2]->name, 'Wolfgang Amadeus Mozart';
is $res->[2]->type, 'music';

ok substr($res->[2]->wteaser, 0, 30 ) =~ m{mozart}ixms;

ok $res->[2]->wurl =~ m{http://en.wikipedia.org/wiki}xms;
ok $res->[2]->wurl =~  m{mozart}ixms;

ok $res->[2]->ytitle =~ m{mozart}xmsi;

ok $res->[2]->yurl =~ m{http://www.youtube.com}xms;
ok $res->[2]->yurl =~ m{f=videos&c=TasteKid&app=youtube_gdata}xms;

