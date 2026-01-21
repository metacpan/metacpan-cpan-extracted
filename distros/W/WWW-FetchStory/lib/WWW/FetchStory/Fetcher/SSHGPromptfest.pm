package WWW::FetchStory::Fetcher::SSHGPromptfest;
$WWW::FetchStory::Fetcher::SSHGPromptfest::VERSION = '0.2602';
use strict;
use warnings;
=head1 NAME

WWW::FetchStory::Fetcher::SSHGPromptfest - fetching module for WWW::FetchStory

=head1 VERSION

version 0.2602

=head1 DESCRIPTION

This is the SSHGPromptfest story-fetching plugin for WWW::FetchStory.

=cut

use parent qw(WWW::FetchStory::Fetcher::LiveJournal);

=head1 METHODS

=head2 info

Information about the fetcher.

$info = $self->info();

=cut

sub info {
    my $self = shift;
    
    my $info = "(http://sshg_promptfest.livejournal.com/) Severus Snape/Hermione Granger fiction exchange comm.";

    return $info;
} # info

=head2 priority

The priority of this fetcher.  Fetchers with higher priority
get tried first.  This is useful where there may be a generic
fetcher for a particular site, and then a more specialized fetcher
for particular sections of a site.  For example, there may be a
generic LiveJournal fetcher, and then refinements for particular
LiveJournal community, such as the sshg_exchange community.
This works as either a class function or a method.

This must be overridden by the specific fetcher class.

$priority = $self->priority();

$priority = WWW::FetchStory::Fetcher::priority($class);

=cut

sub priority {
    my $class = shift;

    return 2;
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

    return ($url =~ /sshg[-_]promptfest\.livejournal\.com/);
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
    $info{toc_first} = 1;

    my $title = $self->parse_title(%args);
    $title =~ s/sshg_promptfest\s*//;
    $info{title} = $title;

    my $summary = $self->parse_summary(%args);
    $summary =~ s/"/'/g;
    $info{summary} = $summary;

    my $author = $self->parse_author(%args);
    $info{author} = $author;

    $info{characters} = "Hermione Granger, Severus Snape";
    $info{universe} = 'Harry Potter';
    $info{recipient} = $self->parse_recipient(%args);
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
    my $sid = $args{sid};
    my @chapters = ();
    if (defined $args{urls})
    {
	@chapters = @{$args{urls}};
	for (my $i = 0; $i < @chapters; $i++)
	{
	    $chapters[$i] = sprintf('%s?format=light', $chapters[$i]);
	}
    }
    if (@chapters == 1)
    {
	while ($content =~ m/href=["'](http:\/\/sshg[-_]pf[-_](?:mod|fanwork)\.livejournal\.com\/\d+.html)/sg)
	{
	    my $ch_url = $1;
	    warn "chapter=$ch_url\n" if ($self->{verbose} > 1);
	    push @chapters, "${ch_url}?format=light";
	}
    }

    return \@chapters;
} # parse_chapter_urls

1; # End of WWW::FetchStory::Fetcher::SSHGPromptfest
__END__
