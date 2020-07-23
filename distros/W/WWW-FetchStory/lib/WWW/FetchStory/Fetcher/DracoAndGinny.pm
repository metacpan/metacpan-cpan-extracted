package WWW::FetchStory::Fetcher::DracoAndGinny;
$WWW::FetchStory::Fetcher::DracoAndGinny::VERSION = '0.2201';
use strict;
use warnings;
=head1 NAME

WWW::FetchStory::Fetcher::DracoAndGinny - fetching module for WWW::FetchStory

=head1 VERSION

version 0.2201

=head1 DESCRIPTION

This is the DracoAndGinny story-fetching plugin for WWW::FetchStory.

=cut

our @ISA = qw(WWW::FetchStory::Fetcher);

=head2 info

Information about the fetcher.

$info = $self->info();

=cut

sub info {
    my $self = shift;
    
    my $info = "(http://www.dracoandginny.com) A Draco Malfoy/Ginny Weasley HP fiction archive.";

    return $info;
} # info

=head2 priority

The priority of this fetcher.  Fetchers with higher priority
get tried first.  This is useful where there may be a generic
fetcher for a particular site, and then a more specialized fetcher
for particular sections of a site.  For example, there may be a
generic DracoAndGinny fetcher, and then refinements for particular
DracoAndGinny community, such as the sshg_exchange community.
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

    return ($url =~ /dracoandginny\.com/);
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

    my @chapters = ();

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
    $info{summary} = $self->parse_summary(%args,sid=>$sid);
    $info{characters} = "Draco Malfoy, Ginny Weasley";
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
	my $fmt = 'http://www.dracoandginny.com/viewstory.php?action=printable&sid=%s&textsize=0&chapter=%d';

	# fortunately DracoAndGinny has a sane chapter system
	if ($content =~ m#chapter=all#s)
	{
	    @chapters = ();
	    while ($content =~ m#<a href="viewstory.php\?sid=${sid}&amp;chapter=(\d+)">#sg)
	    {
		my $ch_num = $1;
		my $ch_url = sprintf($fmt, $sid, $ch_num);
		warn "chapter=$ch_url\n" if ($self->{verbose} > 1);
		push @chapters, $ch_url;
	    }
	}
	else
	{
	    @chapters = (sprintf($fmt, $sid, 1));
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
    if ($content =~ m#<a href="viewstory.php\?sid=\d+">([^<]+)</a>#s)
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
    if ($content =~ m#<a href="viewuser.php\?uid=\d+">([^<]+)</a>#s)
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
	sid=>'',
	@_
    );

    my $content = $args{content};
    my $sid = $args{sid};
    my $summary = '';
    if ($content =~ m#<blockquote>([^<]+)</blockquote>#s)
    {
	$summary = $1;
    }
    else
    {
	# In order to get the summary, # look at the "print" version of chapter 1
	my $fmt = 'http://www.dracoandginny.com/viewstory.php?action=printable&sid=%s&textsize=0&chapter=%d';

	my $ch1_url = sprintf($fmt, $sid, 1);
	my $chapter1 = $self->get_page($ch1_url);
	$summary = $self->SUPER::parse_summary(%args,content=>$chapter1);
    }
    return $summary;
} # parse_summary

1; # End of WWW::FetchStory::Fetcher::DracoAndGinny
__END__
