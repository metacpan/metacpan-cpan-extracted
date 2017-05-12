#!/usr/bin/perl
# /* vim:et: set ts=4 sw=4 sts=4 tw=78: */
#$Id$

###NOTE: I'm more interested in the music suggestions aspect of these 
### results, however, one could persue the movie and book results as well
### although honestly, untested

### obviously, you would run a script like this from the command line 
### and redirect to a file somewhere, to access via a web browser,
### just one idea,...

### TODO: much better than the above would be to login to 
### your youtube account and create a playlist of the above,
### then you can check out some new tunes while you work, without
### spending too much time on it :)

### or, if you prefer local viewing,  in the viewer/player of your
### choice (mplayer perhaps). one could create flv's/mp3's from 
### the swf's.  See: FLV::FromSwf and FLV::ToMP3 available on The CPAN

use strict;
use warnings;
#use criticism 'brutal';

use WWW::TasteKid;

my $tskd = WWW::TasteKid->new;

# let's get some 'goth/vampire-ish' music,.. different sources in,
# only music out,...
$tskd->query({ type => 'movie', name => 'underworld' });
$tskd->query({ type => 'movie', name => 'twlight' });
$tskd->query({ type => 'book',  name => 'bram stokers dracula' });
$tskd->query({ type => 'book',  name => 'interview with the vampire' });
$tskd->query({ type => 'movie', name => 'resident evil' });
$tskd->query({ type => 'music', name => 'type o negative' });
$tskd->ask({ filter => 'music', verbose => 1 });
#warn $tskd->get_encoded_query; # inspect whats in the query
# make sure it's what we put in,...
#warn $tskd->query_inspection;


# get our results
my $info = $tskd->info_resource;
my $results = $tskd->results_resource;

my $tm = scalar localtime;
my $q = $tskd->get_encoded_query;
print qq{<html><title>TasteKid Suggestions</title><body>};
print qq{<meta content='text/html; charset=UTF-8'>};

print qq{<p>$tm</p><br/>};
print qq{<i>seeds used:</i><br/>};

foreach my $tkr (@{$info}) {
    my ($n,$t) = ($tkr->name, $tkr->type);
    print qq{<b>Name:</b>$n&nbsp;&nbsp<b>Type:</b>$t<br/>\n};
}
print qq{<br/>};
print qq{<br/>};
print qq{Results:<br/>};

foreach my $tkr (@{$results}) {
    my ($u, $t) = ($tkr->yurl,$tkr->ytitle);
    my $a = $tkr->name;
    print qq{<b>Artist:</b> $a &nbsp;&nbsp;};
    print qq{<a href="$u" target="_blank">$t</a><br/>\n};
} 
print qq{</body></html>};

##### more query ideas.
#### 'oh yeah', some 80's music,...
#$tskd->query({ type => 'music', name => 'men at work' });
#$tskd->query({ type => 'music', name => 'flock of seagulls' });
#$tskd->query({ type => 'music', name => 'Huey Lewis And The News' });
#$tskd->ask({ filter => 'music', verbose => 1 });
#my $info = $tskd->results_resource;
#my @res = ();
#foreach my $tkr (@{$info}) {
#    print $tkr->name, $tkr->type;
#}
#
# of course, the possiblities are endless,...

