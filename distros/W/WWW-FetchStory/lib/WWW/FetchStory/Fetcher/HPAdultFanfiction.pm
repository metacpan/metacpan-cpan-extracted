package WWW::FetchStory::Fetcher::HPAdultFanfiction;
$WWW::FetchStory::Fetcher::HPAdultFanfiction::VERSION = '0.1902';
use strict;
use warnings;
=head1 NAME

WWW::FetchStory::Fetcher::HPAdultFanfiction - fetching module for WWW::FetchStory

=head1 VERSION

version 0.1902

=head1 DESCRIPTION

This is the HPAdultFanfiction story-fetching plugin for WWW::FetchStory.

=cut

our @ISA = qw(WWW::FetchStory::Fetcher);

=head1 METHODS

=head2 new

$obj->WWW::FetchStory::Fetcher->new();

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    # disable the User-Agent for HPAdultFanfiction
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
    
    my $info = "(http://hp.adultfanfiction.net) An adult Harry Potter fiction archive.";

    return $info;
} # info

=head2 priority

The priority of this fetcher.  Fetchers with higher priority
get tried first.  This is useful where there may be a generic
fetcher for a particular site, and then a more specialized fetcher
for particular sections of a site.  For example, there may be a
generic HPAdultFanfiction fetcher, and then refinements for particular
HPAdultFanfiction community, such as the sshg_exchange community.
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

    return ($url =~ /hp\.adultfanfiction\.net/);
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

    my $chapter = $self->parse_ch_title(%args);
    warn "chapter=$chapter\n" if ($self->{verbose} > 1);

    my $author = $self->parse_author(%args);
    warn "author=$author\n" if ($self->{verbose} > 1);

    my $story = '';
    if ($content =~ m!<td colspan="3" bgcolor="F4EBCC">\s*<font color="#003333">Disclaimer:[^<]+</font>\s*</td>\s*</tr>\s*<tr>\s*<td colspan="3">\s*<p>&nbsp;</p>\s*</td>\s*</tr>\s*<tr>\s*<td colspan="3" bgcolor="F4EBCC">\s*(.*?)<tr class='catdis'>!s)
    {
	$story = $1;
    }

    if ($story)
    {
	$story = $self->tidy_chars($story);
    }
    else
    {
	die "Failed to extract story for $title";
    }

    my $story_title = "$title: $chapter";
    $story_title = $title if ($title eq $chapter);
    $story_title = $title if ($chapter eq '');

    my $out = '';
    if ($story)
    {
	$out .= "<h1>$story_title</h1>\n";
	$out .= "<p>by $author</p>\n";
	$out .= "$story";
    }
    return ($out, $story_title);
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
    if ($args{url} =~ m#no=(\d+)#)
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
    $info{category} = $self->parse_category(%args);
    $info{universe} = 'Harry Potter';
    $info{rating} = 'Adult';

    # the summary is on the Author page!
    my $auth_id = '';
    if ($content =~ m/Author:\s*<a href='authors\.php\?no=(\d+)'>/s)
    {
	$auth_id = $1;
    }
    if ($auth_id and $sid)
    {
	my $auth_page = $self->get_page("http://hp.adultfanfiction.net/authors.php?no=${auth_id}");
	if ($auth_page =~ m#<a href='story\.php\?no=${sid}'>[^<]+</a><br>\s*([^<]+)<br>#s)
	{
	    $info{summary} = $1;
	}
    }
    if (!$info{summary})
    {
	$info{summary} = $self->SUPER::parse_summary(%args);
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
	@chapters = ();
	my $fmt = 'http://hp.adultfanfiction.net/story.php?no=%d&chapter=%d';
	my $max_chapter = 0;
	while ($content =~ m#<option value='story\.php\?no=${sid}&chapter=(\d+)'#gs)
	{
	    my $a_ch = $1;
	    if ($a_ch > $max_chapter)
	    {
		$max_chapter = $a_ch;
	    }
	}
	for (my $ch = 1; $ch <= $max_chapter; $ch++)
	{
	    my $ch_url = sprintf($fmt, $sid, $ch);
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
    my $title = '';
    if ($content =~ m#<title>\s*Story:\s*([^<]+)\s*</title>#is)
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
    if ($content =~ m/Author:\s*<a href='authors\.php\?no=\d+'>\s*([^<]+)\s*<\/a>/s)
    {
	$author = $1;
    }
    else
    {
	$author = $self->SUPER::parse_author(%args);
    }
    return $author;
} # parse_author

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
    if ($content =~ m#<a href="main\.php\?list=\d+">\s*(\w+)/(\w+)</a>#)
    {
	$characters = $1 . ', ' . $2;
	$characters =~ s/Arthur/Arthur Weasley/;
	$characters =~ s/Bill/Bill Weasley/;
	$characters =~ s/Charlie/Charlie Weasley/;
	$characters =~ s/Draco/Draco Malfoy/;
	$characters =~ s/Dudley/Dudley Dursley/;
	$characters =~ s/Fred/Fred Weasley/;
	$characters =~ s/George/George Weasley/;
	$characters =~ s/Ginny/Ginny Weasley/;
	$characters =~ s/Harry/Harry Potter/;
	$characters =~ s/Hermione/Hermione Granger/;
	$characters =~ s/James/James Potter/;
	$characters =~ s/Lavender/Lavender Brown/;
	$characters =~ s/Lavendar/Lavender Brown/;
	$characters =~ s/Lily/Lily Evans/;
	$characters =~ s/Lucius/Lucius Malfoy/;
	$characters =~ s/Luna/Luna Lovegood/;
	$characters =~ s/McGonagall/Minerva McGonagall/;
	$characters =~ s/Molly/Molly Weasley/;
	$characters =~ s/Narcissa/Narcissa Malfoy/;
	$characters =~ s/Neville/Neville Longbottom/;
	$characters =~ s/Remus/Remus Lupin/;
	$characters =~ s/Ron/Ron Weasley/;
	$characters =~ s/Snape/Severus Snape/;
    }
    else
    {
	$characters = $self->SUPER::parse_characters(%args);
    }
    return $characters;
} # parse_characters

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
    if ($content =~ m#^Chapter\s*(\d+:[^<]+)<br#m)
    {
	$title = $1;
    }
    elsif ($content =~ m#<option[^>]+selected>([^<]+)</option>#s)
    {
	$title = $1;
    }
    else
    {
	$title = $self->parse_title(%args);
    }
    return $title;
} # parse_ch_title

1; # End of WWW::FetchStory::Fetcher::HPAdultFanfiction
__END__
