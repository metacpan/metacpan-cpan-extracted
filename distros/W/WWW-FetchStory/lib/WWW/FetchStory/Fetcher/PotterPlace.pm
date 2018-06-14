package WWW::FetchStory::Fetcher::PotterPlace;
$WWW::FetchStory::Fetcher::PotterPlace::VERSION = '0.2002';
use strict;
use warnings;
=head1 NAME

WWW::FetchStory::Fetcher::PotterPlace - fetching module for WWW::FetchStory

=head1 VERSION

version 0.2002

=head1 DESCRIPTION

This is the PotterPlace story-fetching plugin for WWW::FetchStory.

=cut

our @ISA = qw(WWW::FetchStory::Fetcher);

=head2 info

Information about the fetcher.

$info = $self->info();

=cut

sub info {
    my $self = shift;
    
    my $info = "(http://www.potterplacearchives.com) A Harry Potter fiction archive.";

    return $info;
} # info

=head2 priority

The priority of this fetcher.  Fetchers with higher priority
get tried first.  This is useful where there may be a generic
fetcher for a particular site, and then a more specialized fetcher
for particular sections of a site.  For example, there may be a
generic PotterPlace fetcher, and then refinements for particular
PotterPlace community, such as the sshg_exchange community.
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

    return ($url =~ /potterplacearchives\.com/);
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

    my %info = ();
    my $content = $args{content};

    $info{url} = $args{url};
    my $sid='';
    if ($args{url} =~ m#sid=(\d+)#)
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
	# fortunately Potter Place has a sane chapter system
	my $fmt = 'http://www.potterplacearchives.com/viewstory.php?action=printable&textsize=0&sid=%d&chapter=%d';
	if ($content =~ m#<span class="label">Chapters:\s*</span>\s*(\d+)#s)
	{
	    @chapters = ();
	    my $num_ch = $1;
	    for (my $i=1; $i <= $num_ch; $i++)
	    {
		my $ch_url = sprintf($fmt, $sid, $i);
		warn "chapter=$ch_url\n" if ($self->{verbose} > 1);
		push @chapters, $ch_url;
	    }
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
    if ($content =~ m#<div id="pagetitle"><a href="viewstory.php\?sid=\d+">([^<]+)</a>#s)
    {
	$title = $1;
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
    if ($content =~ m#\s*by\s*<a href="viewuser.php\?uid=\d+">([^<]+)</a></div>#s)
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
    if ($content =~ m#<span class="label">Summary:\s*</span>\s*(.*?)\s*<br#s)
    {
	$summary = $1;
    }
    else
    {
	$summary = $self->SUPER::parse_summary(%args);
    }
    return $summary;
} # parse_summary

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
    if ($content =~ m#<span class="label">Characters:\s*</span>(.*?)<br#s)
    {
	my $chars_str = $1;
	my @chars = ();
	while ($chars_str =~ m#charid=\d*'>([^<]+)</a>#sg)
	{
	    my $character = $1;
	    push @chars, $character;
	}
	$characters = join(', ', @chars);
    }
    else
    {
	$characters = $self->SUPER::parse_characters(%args);
    }
    return $characters;
} # parse_characters

1; # End of WWW::FetchStory::Fetcher::PotterPlace
__END__
