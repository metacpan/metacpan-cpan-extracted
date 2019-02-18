package WWW::FetchStory::Fetcher::TwistingHellmouth;
$WWW::FetchStory::Fetcher::TwistingHellmouth::VERSION = '0.2004';
use strict;
use warnings;
=head1 NAME

WWW::FetchStory::Fetcher::TwistingHellmouth - fetching module for WWW::FetchStory

=head1 VERSION

version 0.2004

=head1 DESCRIPTION

This is the TwistingHellmouth story-fetching plugin for WWW::FetchStory.

=cut

our @ISA = qw(WWW::FetchStory::Fetcher);

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
    $info{title} = $self->parse_title(%args);
    $info{author} = $self->parse_author(%args);
    $info{summary} = $self->parse_summary(%args);
    $info{characters} = $self->parse_characters(%args);
    $info{universe} = 'Buffy';

    if ($content =~ m{<td>(No|Yes)\s*</td>\s*</tr>}s)
    {
	$info{complete} = $1;
    }
    $info{chapters} = $self->parse_chapter_urls(%args);

    return %info;
} # parse_toc

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
    my @chapters = ();
    if (defined $args{urls})
    {
	@chapters = @{$args{urls}};
    }
    if (@chapters == 1)
    {
	if ($args{url} =~ m{http://www.tthfanfic.org/Story-(\d+)})
	{
	    my $sid = $1;
	    @chapters =
	    ("http://www.tthfanfic.org/wholestory.php?no=${sid}&format=print");
	}
    }

    return \@chapters;
} # parse_chapter_urls

1; # End of WWW::FetchStory::Fetcher::TwistingHellmouth
__END__
