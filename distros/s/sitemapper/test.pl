# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $ntests = 1;

sub ok( $ ) {
    my $status = shift;
    print "not " unless $status;
    print "ok $ntests\n";
    $ntests++;
}

BEGIN { 
    $| = 1; 
    print "1..2\n"; 
}

END {
    ok( $loaded );
}

$loaded = 1;
use strict;
use WWW::Sitemap;
use LWP::UserAgent;
use LWP::AuthenAgent;

my $ok_count = 1;

$| = 1;

my $default_url = 'http://www.itn.co.uk/';
print STDERR "Type the URL to generate a sitemap for: [$default_url] "; 
my $url = <>;
chomp( $url );
$url ||= $default_url;
print STDERR "URL: $url\n";
my $ua = new LWP::UserAgent;
if ( defined( $ENV{ http_proxy } ) )
{
    $ua->env_proxy();
}
else
{
    print STDERR "Do you need to use a proxy [y|N]? ";
    if ( <> =~ /^[y|Y]/ )
    {
        print STDERR "What is the URL of your proxy? ";
        my $proxy = <>;
        $ua->proxy( [ 'http' ], $proxy );
    }
    else
    {
        $ua->no_proxy();
    }
}

my $email = 'test@my.com';

my $default_depth = 2;
print STDERR "What depth of traversal do you want? [$default_depth] ";
my $depth = <>;
chomp( $depth );
$depth ||= $default_depth;
print STDERR "DEPTH: $depth\n";

my $sitemap = new WWW::Sitemap
    EMAIL               => $email,
    USERAGENT           => $ua,
    ROOT                => $url,
    DEPTH               => $depth,
    SUMMARY_LENGTH      => 200,
    VERBOSE             => 1,
;

$sitemap->generate();

ok( defined( $sitemap ) );

print "ROOT ", $sitemap->root(), "\n";
for my $url ( $sitemap->urls )
{
    printf STDERR <<URL,
$url:
    TITLE:      %s
    SUMMARY:    %s
    LINKS:      %s

URL
    $sitemap->title( $url ),
    $sitemap->summary( $url ),
    join( ' ', $sitemap->links( $url ) ),
}

$sitemap->traverse(
    sub {
        my ( $sitemap, $url, $depth, $flag ) = @_;
        if ( $flag == 0 )
        {
            print STDERR "Entering list of daughter URLs of $url (depth = $depth)\n";
        }
        elsif( $flag == 1 )
        {
            print STDERR "Processing $url (depth = $depth)\n";
        }
        elsif( $flag == 2 )
        {
            print STDERR "Leaving list of daughter URLs of $url (depth = $depth)\n";
        }
    }
);
