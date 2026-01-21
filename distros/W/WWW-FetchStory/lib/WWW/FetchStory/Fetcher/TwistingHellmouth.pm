package WWW::FetchStory::Fetcher::TwistingHellmouth;
$WWW::FetchStory::Fetcher::TwistingHellmouth::VERSION = '0.2602';
=head1 NAME

WWW::FetchStory::Fetcher::TwistingHellmouth - fetching module for WWW::FetchStory

=head1 VERSION

version 0.2602

=head1 DESCRIPTION

This is the TwistingHellmouth story-fetching plugin for WWW::FetchStory.

=cut

use parent qw(WWW::FetchStory::Fetcher);

use common::sense;
use YAML::Any qw(Dump);

=head1 METHODS

=head2 info

Information about the fetcher.

$info = $self->info();

=cut

sub info {
    my $self = shift;
    
    my $info = "(http://www.tthfanfic.org) Twisting The Hellmouth; Buffy The Vampire Slayer crossovers.";

    return $info;
} # info

=head2 priority

The priority of this fetcher.  Fetchers with higher priority
get tried first.  This is useful where there may be a generic
fetcher for a particular site, and then a more specialized fetcher
for particular sections of a site.  For example, there may be a
generic TwistingHellmouth fetcher, and then refinements for particular
TwistingHellmouth community, such as the sshg_exchange community.
This works as either a class function or a method.

This must be overridden by the specific fetcher class.

$priority = $self->priority();

$priority = WWW::FetchStory::Fetcher::priority($class);

=cut

sub priority {
    my $class = shift;

    return 1;
} # priority

=head2 allow

If this fetcher can be used for the given URL, then this returns
true.
This must be overridden by the specific fetcher class.

    if ($obj->allow($url))
    {
	....
    }

=cut

sub allow {
    my $self = shift;
    my $url = shift;

    return ($url =~ /tthfanfic\.org/);
} # allow

=head1 Private Methods

=head2 parse_toc

Parse the table-of-contents file.

    %info = $self->parse_toc(content=>$content,
			 url=>$url,
			 urls=>\@urls);

This should return a hash containing:

=over

=item chapters

An array of URLs for the chapters of the story.  In the case where the
story only takes one page, that will be the chapter.
In the case where multiple URLs have been passed in, it will be those URLs.

=item title

The title of the story.

=back

It may also return additional information, such as Summary.

=cut

sub parse_toc {
    my $self = shift;
    my %args = (
	url=>'',
	content=>'',
	@_
    );

    my $content = $args{content};
    my %info = ();
    $info{url} = $args{url};

    my $sid='';
    if ($args{url} =~ m!Story-(\d+)!)
    {
        $sid = $1;
    }
    else
    {
	print STDERR "did not find SID for $args{url}";
	return $self->SUPER::parse_toc(%args);
    }

    $info{title} = $self->parse_title(%args);
    $info{author} = $self->parse_author(%args);
    $info{summary} = $self->parse_summary(%args);
    $info{characters} = $self->parse_characters(%args);
    $info{universe} = 'Buffy';
    my $epub_url = $self->parse_epub_url(%args, sid=>$sid);
    if ($epub_url)
    {
        $info{epub_url} = $epub_url;
    }
    if ($args{epub}) # need to parse the wordcount
    {
        $info{wordcount} = $self->parse_wordcount(%args);
    }

    if ($content =~ m{<td>(No|Yes)\s*</td>\s*</tr>}s)
    {
	$info{complete} = $1;
    }
    $info{chapters} = $self->parse_chapter_urls(%args, sid=>$sid);

    return %info;
} # parse_toc

=head2 parse_author

Get the author.

=cut
sub parse_author {
    my $self = shift;
    my %args = @_;

    my $content = $args{content};

    my $author = '';
    # <a href="/AuthorStories-5487/janusi.htm">janusi</a>
    if ($content =~ m!/AuthorStories-\d+/[a-zA-Z0-9_]+\.htm["']>([^<]+)</a>!)
    {
	$author = $1;
    }
    else
    {
	$author = $self->SUPER::parse_author(%args);
    }
    $author =~ s/_/ /g;
    return $author;
} # parse_author

=head2 parse_wordcount

Get the wordcount.

=cut
sub parse_wordcount {
    my $self = shift;
    my %args = @_;

    my $content = $args{content};

    my $words = '';
    # <td><a href='/Story-22230-4/janusi+Iron+Buffy.htm' >4</a></td><td>56,481</td>
    if ($content =~ m!</a></td><td>([0-9][0-9,]+)</td>!)
    {
	$words = $1;
        $words =~ s/,//;
    }
    return $words;
} # parse_wordcount

=head2 parse_chapter_urls

Figure out the URLs for the chapters of this story.

=cut
sub parse_chapter_urls {
    my $self = shift;
    my %args = (
	url=>'',
	content=>'',
	@_
    );
    my $content = $args{content};
    my $sid = $args{sid};

    my @chapters = ();
    if (defined $args{urls})
    {
	@chapters = @{$args{urls}};
    }
    if (@chapters <= 1)
    {
        @chapters =
        ("http://www.tthfanfic.org/wholestory.php?no=${sid}&format=offlinehtml");
    }

    return \@chapters;
} # parse_chapter_urls

=head2 parse_epub_url

Figure out the URL for the EPUB version of this story.

=cut
sub parse_epub_url {
    my $self = shift;
    my %args = (
	url=>'',
	content=>'',
	@_
    );
    my $content = $args{content};
    my $sid = $args{sid};
    my $epub_url = "http://www.tthfanfic.org/wholestory.php?no=${sid}&format=epub";

} # parse_epub_url

1; # End of WWW::FetchStory::Fetcher::TwistingHellmouth
__END__
