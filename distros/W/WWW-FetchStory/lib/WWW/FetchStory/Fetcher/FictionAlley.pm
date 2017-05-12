package WWW::FetchStory::Fetcher::FictionAlley;
$WWW::FetchStory::Fetcher::FictionAlley::VERSION = '0.1902';
use strict;
use warnings;
=head1 NAME

WWW::FetchStory::Fetcher::FictionAlley - fetching module for WWW::FetchStory

=head1 VERSION

version 0.1902

=head1 DESCRIPTION

This is the FictionAlley story-fetching plugin for WWW::FetchStory.

=cut

our @ISA = qw(WWW::FetchStory::Fetcher);

=head1 METHODS

=head2 new

$obj->WWW::FetchStory::Fetcher->new();

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    # disable the User-Agent for FictionAlley
    # because it blocks wget
    $self->{wget} .= " --user-agent=''";

    return ($self);
} # new

=head2 info

Information about the fetcher.

$info = $self->info();

=cut

sub info {
    my $self = shift;
    
    my $info = "(http://www.fictionalley.org/) A Harry Potter fiction archive.";

    return $info;
} # info

=head2 priority

The priority of this fetcher.  Fetchers with higher priority
get tried first.  This is useful where there may be a generic
fetcher for a particular site, and then a more specialized fetcher
for particular sections of a site.  For example, there may be a
generic FictionAlley fetcher, and then refinements for particular
FictionAlley community, such as the sshg_exchange community.
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

    return ($url =~ /(fictionalley|schnoogle\.com|astronomytower\.org|riddikulus\.org|thedarkarts\.org)/);
} # allow

=head1 Private Methods

=head2 extract_story

Extract the story-content from the fetched content.

    ($story, $title) = $self->extract_story(content=>$content,
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

    my $story = '';
    my $story_title = '';
    if ($content =~ m#<title>Astronomy Tower -\s+(.*?)</title>#)
    {
	$story_title = $1;
    }
    elsif ($content =~ m#<title>\w+ -\s+(.*?)</title>#)
    {
	$story_title = $1;
    }
    elsif ($content =~ m#<title>(.*?)</title>#)
    {
	$story_title = $1;
    }
    if ($content =~ m#<!-- headerstart -->(.*?)<!-- footerstart -->#s)
    {
	$story = $1;
    }
    if ($story)
    {
	$story = $self->tidy_chars($story);
    }
    else
    {
	return $content;
    }
    warn "title=$story_title\n" if ($self->{verbose} > 1);

    my $out = <<EOT;
<h1>$story_title</h1>
$story
EOT
    return $out;
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
    $info{title} = $self->parse_title(%args);
    $info{author} = $self->parse_author(%args);
    $info{summary} = $self->parse_summary(%args);
    $info{characters} = $self->parse_characters(%args);
    $info{universe} = 'Harry Potter';
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
	@chapters = ();
	while ($content =~ m#<a href\s*=\s*"(http://www.fictionalley.org/authors/\w+/\w+\.html)"\s*class\s*=\s*"chapterlink">#g)
	{
	    my $ch_url = $1;
	    warn "chapter=$ch_url\n" if ($self->{verbose} > 1);
	    push @chapters, $ch_url;
	}
    }

    return \@chapters;
} # parse_chapter_urls

=head2 parse_ch_title

Get the chapter title from the content

=cut
sub parse_ch_title {
    my $self = shift;
    my %args = (
	content=>'',
	@_
    );

    my $content = $args{content};
    my $title = '';
    if ($content =~ /\((Chapter \d+)\)/si)
    {
	$title = $1;
    }
    else
    {
	$title = $self->parse_title(%args);
    }
    $title =~ s/<u>//ig;
    $title =~ s/<\/u>//ig;
    return $title;
} # parse_ch_title

=head2 parse_title

Get the title from the content

=cut
sub parse_title {
    my $self = shift;
    my %args = (
	url=>'',
	content=>'',
	@_
    );

    my $content = $args{content};
    my $title = '';
    if ($content =~ m/<h1\s*class\s*=\s*"title"[^>]*>([^<]+)\s+by\s+<a/s)
    {
	$title = $1;
	$title =~ s/&#039;/'/g;
    }
    else
    {
	$title = $self->SUPER::parse_title(%args);
    }
    return $title;
} # parse_title

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
    if ($content =~ m!"http://www.fictionalley.org/authors/\w+/">([^<]+)</a>!s)
    {
	$author = $1;
    }
    elsif ($content =~ m/<h1\s*class\s*=\s*"title"[^>]*>[^<]+\s*by\s*<a href="[^"]+">([^<]+)<\/a>/s)
    {
	$author = $1;
    }
    else
    {
	$author = $self->SUPER::parse_author(%args);
    }
    $author =~ s/\./ /g;
    $author =~ s/\s\s+/ /g;
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
    if ($content =~ m{<div class="summary" align = "center">Rating: \w+<br />\s*<i>([^<]+)</i></div>}s)
    {
	$summary = $1;
    }
    elsif ($content =~ /<div class="summary"[^>]*>[\w\s]*<br \/>\s*<i>\s*(.*?)<\/i>\s*<\/div>/s)
    {
	$summary = $1;
    }
    else
    {
	$summary = $self->SUPER::parse_summary(%args);
    }
    return $summary;
} # parse_summary

1; # End of WWW::FetchStory::Fetcher::FictionAlley
__END__
