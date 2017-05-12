package WWW::FetchStory::Fetcher::Gutenberg;
$WWW::FetchStory::Fetcher::Gutenberg::VERSION = '0.1902';
use strict;
use warnings;
=head1 NAME

WWW::FetchStory::Fetcher::Gutenberg - fetching module for WWW::FetchStory

=head1 VERSION

version 0.1902

=head1 DESCRIPTION

This is the Gutenberg story-fetching plugin for WWW::FetchStory.

=cut

our @ISA = qw(WWW::FetchStory::Fetcher);

=head1 METHODS

=head2 info

Information about the fetcher.

$info = $self->info();

=cut

sub info {
    my $self = shift;
    
    my $info = "(http://www.gutenberg.org) Project Gutenberg; public-domain works";

    return $info;
} # info

=head2 priority

The priority of this fetcher.  Fetchers with higher priority
get tried first.  This is useful where there may be a generic
fetcher for a particular site, and then a more specialized fetcher
for particular sections of a site.  For example, there may be a
generic Gutenberg fetcher, and then refinements for particular
Gutenberg community, such as the sshg_exchange community.
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

    return ($url =~ /gutenberg\.org/);
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
    $info{category} = $self->parse_category(%args);
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
	if ($args{url} =~ m{http://www.gutenberg.org/ebooks/(\d+)})
	{
	    my $sid = $1;
	    @chapters = ("http://www.gutenberg.org/files/${sid}/${sid}-h/${sid}-h.htm");
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
    my $title = '';
    if ($content =~ m#<th>Title</th>\s*<td>\s*([^<]+)\s*</td>#s)
    {
	$title = $1;
    }
    elsif ($content =~ m#<h1 class="icon_title">\s*(.*?)\s*by\s[^<]+\s*</h1>#s)
    {
	$title = $1;
    }
    else
    {
	$title = $self->SUPER::parse_title(%args);
    }
    $title =~ s/\s+$//;
    return $title;
} # parse_title

=head2 parse_ch_title

Get the chapter title from the content

=cut
sub parse_ch_title {
    my $self = shift;
    my %args = (
	url=>'',
	content=>'',
	@_
    );

    my $content = $args{content};
    my $title = '';
    if ($content =~ m#Title: (.*)$#m)
    {
	$title = $1;
    }
    else
    {
	$title = $self->SUPER::parse_title(%args);
    }
    $title =~ s/\s+$//;
    return $title;
} # parse_ch_title

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
    if ($content =~ m#<h1 class="icon_title">\s*[^<]+\s*by\s+([^<]+)\s*</h1>#s)
    {
	$author = $1;
    }
    else
    {
	$author = $self->SUPER::parse_author(%args);
    }
    $author =~ s/\s+$//;
    return $author;
} # parse_author

=head2 parse_category

Get the category from the content

=cut
sub parse_category {
    my $self = shift;
    my %args = (
	url=>'',
	content=>'',
	@_
    );

    my $content = $args{content};
    my $category = '';
    my %cats = ();
    while ($content =~ m#<th>Subject</th>\s*<td[^>]*>\s*<a [^>]+>\s+([^<]+)\s+</a>\s*</td>#sg)
    {
	my $subjects = $1;
	if ($subjects !~ /Fictitious character/)
	{
	    my @subs = split(/ -- /, $subjects);
	    if (@subs)
	    {
		foreach my $sub (@subs)
		{
		    # some subjects need even more parsing
		    if ($sub =~ m#(.*?) \((.*)\)#)
		    {
			my $sub1 = $1;
			my $sub2 = $2;
			$cats{$sub2} = 1;
			$sub = $sub1;
		    }
		    if ($sub =~ m#(.*?), (.*)#)
		    {
			$sub = "$2 $1";
		    }
		    $cats{$sub} = 1;
		}
	    }
	    else
	    {
		$cats{$subjects} = 1;
	    }
	}
    }
    if (%cats)
    {
	$category = join(', ', sort keys %cats);
    }
    return $category;
} # parse_category

=head2 parse_characters

Get the characters from the content

=cut
sub parse_characters {
    my $self = shift;
    my %args = (
	url=>'',
	content=>'',
	@_
    );

    my $content = $args{content};
    my $characters = '';
    my %chars = ();
    while ($content =~ m#<th>Subject</th>\s*<td[^>]*>\s*<a [^>]+>\s+([^<]+)\s+</a>\s*</td>#sg)
    {
	my $subjects = $1;
	if ($subjects =~ /Fictitious character/)
	{
	    my @subs = split(/ -- /, $subjects);
	    if (@subs)
	    {
		foreach my $sub (@subs)
		{
		    # only look at the characters
		    if ($sub =~ m#(.*?) \(Fictitious character\)#)
		    {
			my $sub1 = $1;
			if ($sub1 =~ m#(.*?), (.*)#)
			{
			    $sub1 = "$2 $1";
			}
			$chars{$sub1} = 1;
		    }
		}
	    }
	}
    }
    if (%chars)
    {
	$characters = join(', ', sort keys %chars);
    }
    return $characters;
} # parse_characters

1; # End of WWW::FetchStory::Fetcher::Gutenberg
__END__
