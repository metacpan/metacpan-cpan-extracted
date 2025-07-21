#!perl
use 5.006;
use strict;
use warnings;
use Test::More tests => 1;
use HTML::LinkExtor;
use IO::All;
use LWP::UserAgent;
use URI;
use URI::URL;
use WWW::YaCyBlacklist;

my $ycb = WWW::YaCyBlacklist->new( { 'use_regex' => 0 } );
$ycb->read_from_files( 'C:/Users/Work/Documents/ingram/Perl/dzil/WWW-YaCyBlacklist/yacy/default.black' );

# LWP
my $lwp = LWP::UserAgent->new( agent => 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:76.0) Gecko/20100101 Firefox/76.0' );
$lwp->ssl_opts(  # we don't verify hostnames of TLS URLs
    verify_mode   => 'SSL_VERIFY_PEER',
    SSL_verify_mode => 0x00,
    verify_hostname => 0, 
);

my %raw_urls;

my @urls = (
    'https://dev.ingram-braun.net/my/archive.pl/blacklist_test.htm',
);

my $count = 0;
foreach my $url (@urls) {
    
    $count++;
    
    # We need a request object for HTML::LinkExtor
    my $r = $lwp->request(HTTP::Request->new( GET => $url ));

    # LinkExtor
    my $p = HTML::LinkExtor->new(\&get_links);
    # extract links
    $p->parse( $r->content );

    # expand raw urls
    my @links = map {$_ = url($_, $r->base)->abs;} sort keys %raw_urls;
    # empty buffer
     %raw_urls = ();

    grep { my $u = new URI $_; $_ = $u->as_string }
    
    #join("\n", @links) > io('C:/Users/Work/Documents/ingram/Perl/dzil/WWW-YaCyBlacklist/xt/links.txt');
    join("\n", $ycb->find_matches( @links )) > io('C:/Users/Work/Documents/ingram/Perl/dzil/WWW-YaCyBlacklist/xt/matched.txt');

    is( scalar $ycb->find_matches( @links ), 72, "LinkExtor-$count" );
}

 # LinkExtor callback
sub get_links {
    my($tag, %attr) = @_;
    return if $tag ne 'a' && $tag ne 'area' && $tag ne 'frame' && $tag ne 'iframe' && $tag ne 'track' && $tag ne 'source';
    grep {$raw_urls{$_}++} values %attr;
}
