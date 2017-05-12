package WWW::Bookmark::TagStripper;
use HTML::Parser;

sub tag($$$)
{
    my $pkg = shift;
    my($tag, $num) = @_;
    $pkg->{INSIDE}->{$tag} += $num;
}

sub text($$)
{
    my $pkg = shift;
    return if $pkg->{INSIDE}->{script} || $pkg->{INSIDE}->{style};
    $pkg->{TITLE} = $_[0] if( !$pkg->{TITLE} && $pkg->{INSIDE}->{title} );
    $_[0] =~ s/\n+/ /og;
    $pkg->{TEXT} .= $_[0];
}

sub strip {
    my $pkg = shift;
    $pkg->{PARSER} =
      HTML::Parser->new(
			api_version => 3,
			handlers    => [
					start => [\&tag, "self, tagname, '+1'"],
					end   => [\&tag, "self, tagname, '-1'"],
					text  => [\&text, "self, dtext"],
					],
			marked_sections => 1,
			);
    $pkg->{PARSER}->parse(shift);
    $pkg->{TEXT} = $pkg->{PARSER}->{TEXT};
    $pkg->{TITLE} = $pkg->{PARSER}->{TITLE};
    1;
}

sub new() {
    bless { TEXT => '', TITLE => ''}, shift;
}


######################################################################


package WWW::Bookmark::Crawler;

use 5.006;
use strict;
use warnings;
use Carp;

our $VERSION = '0.01';

use OurNet::FuzzyIndex;
use HTML::LinkExtor;
use LWP::UserAgent;
use HTTP::Request::Common;
use Set::Scalar;

sub new($$) {
    my ($pkg, $arg) = @_;
    my $self = {
	SOURCE  =>
	    -f $arg->{SOURCE} ? 
		$arg->{SOURCE} :
		    ( ref($arg->{SOURCE}) eq "ARRAY" ? $arg->{SOURCE} : '' ),
	DBNAME  => $arg->{DBNAME},
	PEEK    => $arg->{PEEK},
	PROXY   => $arg->{PROXY},
	TIMEOUT => $arg->{TIMEOUT} || 10,
    };
    $self->{TOKENIZER} = ref($arg->{TOKENIZER}) ? $arg->{TOKENIZER} : \&tokenizer;

    if(ref($self->{SOURCE}) eq "ARRAY"){
	$self->{_LINKS} = $self->{SOURCE};
    }
    elsif($self->{SOURCE}){
	my $p = HTML::LinkExtor->new();
	$p->parse_file($self->{SOURCE});
	$self->{_LINKS} = [map{$_->[2]}grep{$_->[0] eq 'a' && $_->[1] eq 'href' }$p->links];
    }

    bless $self, $pkg;
}

sub tokenizer($) {
    caller eq __PACKAGE__ or croak(q/It's private!/);
    my(@t);
    for my $tok (grep {$_} split /\s+/o, $_[0]){
        my %words = OurNet::FuzzyIndex::parse($tok, 0);
        foreach my $m (keys %words){
            push @t, map{"$m$_"} grep { $_ !~ /^[\s\t\d]+$/ } keys %{$words{$m}};
            push @t, $m;
        }
        push @t, $_[0] unless @t;
    }
    return @t;
}

sub crawl($) {
    my $pkg = shift;
    my $ua = LWP::UserAgent->new;
    $ua->agent  ("WWW::Bookmark::Crawler $VERSION");
    $ua->proxy  ($pkg->{HTTP_PROXY});
    $ua->timeout($pkg->{TIMEOUT});
    local $| = 1;
    open (DB, ">".$pkg->{DBNAME}) or croak("cannot write to index file");
    local $SIG{INT} = sub { close DB; exit };

    for my $L (@{$pkg->{_LINKS}}){
	my $request = GET ($L);
	my $response = $ua->request($request);
	$response->is_success or next;

	my $stripper = WWW::Bookmark::TagStripper->new();
	$stripper->strip($response->content);

	if($pkg->{PEEK}){
	    print "{\n  $L\n";
	    print "  ".$stripper->{TITLE}."\n}\n";
	}

	print DB
	    $L, "\x02", $stripper->{TITLE}, "\x02",
	    join(qq/\x01/, $pkg->{TOKENIZER}->($stripper->{TEXT}) ), "\n";
    }
    close DB;
}

sub _loadDB($) {
    my $pkg = shift;
    my $L;
    my ($url, $title, $keywords);
    my $cnt = 0;
    $pkg->{_dbloaded} = 1;
    open (DB, $pkg->{DBNAME}) or croak("index file error");
    while($L = <DB>){
	next unless $L =~ /\x02/o;
	chomp $L;
	($url, $title, $keywords) = split /\x02/, $L;
	$pkg->{_URLS}->[$cnt] = $url;
	$pkg->{_TITLES}->[$cnt] = $title;
	foreach my $k (keys %{ { map {$_,1} split /\x01/, $keywords } }){
	    push @{$pkg->{_KEYWORDS}->{$k}}, $cnt;
	}
	$cnt++;
    }
    close DB;
}

sub query($) {
    my $pkg = shift;
    my $query = shift || croak("Query?");

    $pkg->_loadDB unless $pkg->{_dbloaded};

    my @queries = keys %{{
	map {$_,1}
	sort { @{$pkg->{_KEYWORDS}->{$a}} <=> @{$pkg->{_KEYWORDS}->{$b}} }
	$pkg->{TOKENIZER}->($query)
	}};

    my $seta = Set::Scalar->new(@{$pkg->{_KEYWORDS}->{$queries[0]}});

    for my $i (1..$#queries){
	my $setb = Set::Scalar->new(@{$pkg->{_KEYWORDS}->{$queries[$i]}});
	$seta->intersection($setb);
    }

    map {{
	URL => $pkg->{_URLS}->[$_], TITLE => $pkg->{_TITLES}->[$_]
    }} $seta->elements;
}

sub peek()     { $_[0]->{PEEK} = 1 }

sub nopeek()   { $_[0]->{PEEK} = 0 }

sub proxy($)   { $_[0]->{PROXY} = $_[1] }

sub timeout($) { $_[0]->{TIMEOUT} = $_[1] || 10 }

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

WWW::Bookmark::Crawler - Personal bookmark search engine

=head1 SYNOPSIS

  use WWW::Bookmark::Crawler;
  $crawler = WWW::Bookmark::Crawler->new({
                                           SOURCE => 'bookmarks.html',
                                           DBNAME => 'mybookmark.db',
                                           PEEK   => 1,
                                           TOKENIZER => \&my_tokenizer,
                                         });
  $crawler->peek();
  $crawler->crawl();

  $crawler->nopeek();

  $crawler->query('Ars longa');


=head1 DESCRIPTION

B<WWW::Bookmark::Crawler> is a WWW spider and a search engine for personal bookmark. It first extracts links in either a browser-generated bookmark or a plain html file, then retrieves each page's content online and builds the index file. User can use this module to build a personal bookmark search engine.

=head1 METHODS

=head2 new

Parameters:

=over 6

=item * SOURCE

User may feed it with either the name of bookmark file or reference to an array of urls.

=item * DBNAME

The name of the index file.

=item * PROXY

This is passed on to LWP agent.

=item * TIMEOUT

Ditto. Default is 10 seconds.

=item * PEEK

Set it to non-undef if user wants to see the debugging log dumping to STDOUT. Default is undef.

=item * TOKENIZER

User may write an ad hoc tokenizer replacing the given one. B<WWW::Bookmark::Crawler> uses L<OurNet::FuzzyIndex> to play the role.

=back

=head2 crawl

Starts fetching and building index file.

=head2 query

Returns an array of hashes of URLs and Titles related to the given terms. The default tokenizer treats space as B<intersection>. This method builds an in-memory inverted file from index file when it appears the first time in a script.

No advanced IR skills are used.

=head2 peek

Turns on the debugging output. Same effective as PEEK given to B<new>.

=head2 nopeek

Turns off the debugging information.

=head2 proxy

Sets the proxy server. Same effective as PROXY given to B<new>.

=head2 timeout

Sets the TIMEOUT value. Same effective as PROXY given to B<new>.

=head1 AUTHOR

xern <xern@cpan.org>

=head1 LICENSE

Released under The Artistic License.

=cut
