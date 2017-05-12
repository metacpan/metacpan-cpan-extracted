package WWW::FetchStory::Fetcher::TardisBigBang3;
$WWW::FetchStory::Fetcher::TardisBigBang3::VERSION = '0.1902';
use strict;
use warnings;
=head1 NAME

WWW::FetchStory::Fetcher::TardisBigBang3 - fetching module for WWW::FetchStory

=head1 VERSION

version 0.1902

=head1 DESCRIPTION

This is the TardisBigBang3 story-fetching plugin for WWW::FetchStory.

=cut

our @ISA = qw(WWW::FetchStory::Fetcher);

=head2 info

Information about the fetcher.

$info = $self->info();

=cut

sub info {
    my $self = shift;
    
    my $info = "(http://www.tardisbigbang.com/Round3/) Round 3 of the TARDIS BigBang challenge.";

    return $info;
} # info

=head2 priority

The priority of this fetcher.  Fetchers with higher priority
get tried first.  This is useful where there may be a generic
fetcher for a particular site, and then a more specialized fetcher
for particular sections of a site.

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

    return ($url =~ /www\.tardisbigbang\.com\/Round3/);
} # allow

=head1 Private Methods

=head2 extract_story

Extract the story-content from the fetched content.

    my ($story, $title) = $self->extract_story(content=>$content,
	title=>$title);

=cut

sub extract_story {
    my $self = shift;
    my %args = (
	content=>'',
	title=>'',
	@_
    );

    my $content = $args{content};
    my $title = $args{title};
    my $story = '';
    if ($content =~ m#<div class="main">(.*?)</div>\s*<p class="bottomcomment">#s)
    {
	$story = $1;
    }
    elsif ($content =~ m#<body[^>]*>(.*)</body>#is)
    {
	$story = $1;
    }

    if ($story)
    {
	$story = $self->tidy_chars($story);
    }
    else
    {
	$story = $content;
    }

    return ($story, $title);
} # extract_story

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

    my %info = ();
    my $content = $args{content};

    my @chapters = ();

    $info{url} = $args{url};
    my $sid='';
    if ($args{url} =~ m#storyID=(S\d+)#)
    {
	$sid = $1;
    }
    else
    {
	return $self->SUPER::parse_toc(%args);
    }
    $info{author} = $self->parse_author(%args);
    $info{title} = $self->parse_title(%args);
    $info{summary} = $self->parse_summary(%args);
    if ($content =~ m#<span class="storyinfo">([\w\s]+) \| ([\w-]+) \| (.*?) \| ([\d,]+) words</span>#)
    {
	$info{universe} = $1;
	$info{rating} = $2;
	$info{summary2} = $3;
	$info{size} = $4;

	$info{size} =~ s/,//g;
	$info{size} .= 'w';
	$info{universe} =~ s/New Who/Doctor Who/;
    }
    else
    {
	$info{universe} = 'Doctor Who';
    }
    $info{chapters} = $self->parse_chapter_urls(%args, sid=>$sid);

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
    }
    if (@chapters == 1)
    {
	if ($content =~ m#part=2#)
	{
	    my $fmt = $args{url};
	    $fmt =~ s/part=\d+/part=\%d/;
	    while ($content =~ m#storyID=${sid}\&part=(\d+)">Part#sg)
	    {
		my $ch_num = $1;
		my $ch_url = sprintf($fmt, $ch_num);
		warn "chapter=$ch_url\n" if ($self->{verbose} > 1);
		push @chapters, $ch_url;
	    }
	}
    }

    return \@chapters;
} # parse_chapter_urls

=head2 parse_author

Get the author from the content

=cut
sub parse_author {
    my $self = shift;
    my %args = (
	url=>'',
	content=>'',
	@_
    );

    my $content = $args{content};
    my $author = '';
    if ($content =~ m#<p id="authorinfo">by <strong>([^<]+)</strong>#)
    {
	$author = $1;
    }
    else
    {
	$author = $self->SUPER::parse_author(%args);
    }
    return $author;
} # parse_author

=head2 parse_summary

Get the summary from the content

=cut
sub parse_summary {
    my $self = shift;
    my %args = (
	url=>'',
	content=>'',
	@_
    );

    my $content = $args{content};
    my $summary = '';
    if ($content =~ m#<p class="summary">(.*?)</p>#)
    {
	$summary = $1;
    }
    else
    {
	$summary = $self->SUPER::parse_summary(%args);
    }
    return $summary;
} # parse_summary

1; # End of WWW::FetchStory::Fetcher::TardisBigBang3
__END__
