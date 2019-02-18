package WWW::FetchStory::Fetcher::Owl;
$WWW::FetchStory::Fetcher::Owl::VERSION = '0.2004';
use strict;
use warnings;
=head1 NAME

WWW::FetchStory::Fetcher::Owl - fetching module for WWW::FetchStory

=head1 VERSION

version 0.2004

=head1 DESCRIPTION

This is the Owl story-fetching plugin for WWW::FetchStory.

=cut

our @ISA = qw(WWW::FetchStory::Fetcher);

=head2 info

Information about the fetcher.

$info = $self->info();

=cut

sub info {
    my $self = shift;
    
    my $info = "(http://owl.tauri.org/) A Harry Potter fiction archive.";

    return $info;
} # info

=head2 priority

The priority of this fetcher.  Fetchers with higher priority
get tried first.  This is useful where there may be a generic
fetcher for a particular site, and then a more specialized fetcher
for particular sections of a site.  For example, there may be a
generic Owl fetcher, and then refinements for particular
Owl community, such as the sshg_exchange community.
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

    return ($url =~ /owl\.tauri\.org/);
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
    my $story = '';
    my $title = '';
    if ($content =~ m#<title>OWL\s*::\s*([^<]+)</title>#)
    {
	$title = $1;
    }
    else
    {
	$title = $args{title};
    }

    if ($content =~ m#<div class=pagehead></div>(.*?)<div align=left><span class=credits>#s)
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
    $info{url} = $args{url};
    my $sid='';
    if ($args{url} =~ m#psid=(\d+)#)
    {
	$sid = $1;
    }
    else
    {
	return $self->SUPER::parse_toc(%args);
    }

    $info{title} = $self->parse_title(%args);
    $info{author} = $self->parse_author(%args);
    $info{summary} = $self->parse_summary(%args);
    $info{characters} = $self->parse_characters(%args);
    $info{universe} = 'Harry Potter';
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
	@chapters = ();
	# Owl does not have a sane chapter system
	my $fmt = 'http://owl.tauri.org/stories.php?sid=%d&action=print';
	while ($content =~ m#stories.php\?sid=(\d+)#sg)
	{
	    my $ch_sid = $1;
	    my $ch_url = sprintf($fmt, $ch_sid);
	    warn "chapter=$ch_url\n" if ($self->{verbose} > 1);
	    push @chapters, $ch_url;
	}
    }

    return \@chapters;
} # parse_chapter_urls

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
    my $title = $self->SUPER::parse_title(%args);
    if ($title =~ m#OWL\s*::\s*([^<]+)#)
    {
	$title = $1;
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
    if ($content =~ m#by <a href="users.php\?uid=\d+">([^<]+)</a>#s)
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
    if ($content =~ m#<span class=summary>([^<]+)</span>#s)
    {
	$summary = $1;
    }
    else
    {
	$summary = $self->SUPER::parse_summary(%args);
    }
    return $summary;
} # parse_summary

1; # End of WWW::FetchStory::Fetcher::Owl
__END__
