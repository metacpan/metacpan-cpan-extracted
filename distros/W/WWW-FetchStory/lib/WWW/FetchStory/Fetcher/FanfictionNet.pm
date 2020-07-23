package WWW::FetchStory::Fetcher::FanfictionNet;
$WWW::FetchStory::Fetcher::FanfictionNet::VERSION = '0.2201';
use strict;
use warnings;
=head1 NAME

WWW::FetchStory::Fetcher::FanfictionNet - fetching module for WWW::FetchStory

=head1 VERSION

version 0.2201

=head1 DESCRIPTION

This is the FanfictionNet story-fetching plugin for WWW::FetchStory.

=cut

our @ISA = qw(WWW::FetchStory::Fetcher);

=head2 info

Information about the fetcher.

$info = $self->info();

=cut

sub info {
    my $self = shift;
    
    my $info = "(http://www.fantiction.net/) Huge fan fiction archive.";

    return $info;
} # info

=head2 priority

The priority of this fetcher.  Fetchers with higher priority
get tried first.  This is useful where there may be a generic
fetcher for a particular site, and then a more specialized fetcher
for particular sections of a site.  For example, there may be a
generic FanfictionNet fetcher, and then refinements for particular
FanfictionNet community, such as the sshg_exchange community.
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

    return ($url =~ /fanfiction\.net/);
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
    my $author = '';

    if ($content =~ m#<div\s+id=content><center><b>([^<]+)</b>\s*by\s*<a href='/u/\d+/'>([^<]+)</a>#)
    {
	$title = $1;
	$author = $2;
    }
    $author =~ s/^\s*//;
    $author =~ s/\s*$//;
    warn "title=$title\n" if ($self->{verbose} > 1);
    warn "author=$author\n" if ($self->{verbose} > 1);

    my $universe = $self->parse_universe(content=>$content);
    warn "universe=$universe\n" if ($self->{verbose} > 1);

    my $chapter = $self->parse_ch_title(%args);
    warn "chapter=$chapter\n" if ($self->{verbose} > 1);

    my $story = '';
    if ($content =~ m# id='storycontent'\s*>(.*?)\s*<div align=center>#s)
    {
	$story = $1;
    }
    elsif ($content =~ m# id='storycontent'\s*>(.*?)\s*<center>.*?Ch \d+ of <a href='[^']+'>\d+</a>.*?<br>\s*<span class='xbut corner_round'>#s)
    {
	$story = $1;
    }
    elsif ($content =~ m#class='storycontent' id='storycontent'\s*>(.*?)\s*<center>\s*<br>\s*<span class='xbut corner_round'>#s)
    {
	$story = $1;
    }
    elsif ($content =~ m#class='storycontent puretext' id='storycontent'\s*>(.*?)\s*</div>\s*</div>\s*<div id='content' class='puretext'>#s)
    {
	$story = $1;
    }
    elsif ($content =~ m#id=storycontent class=storycontent>(.*?)\s*</div>\s*</div>\s*<div id=content>#s)
    {
	$story = $1;
    }
    elsif ($content =~ m#id=storycontent class=storycontent>(.*?)\s*</div>\s*<div id=content>#s)
    {
	$story = $1;
    }
    elsif ($content =~ m#<div id=storytext class=storytext>(.*?)</div>#s)
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
	$out .= "<p>by $author</p>\n" if $author;
	$out .= "<br/>\n<b>Universe:</b> $universe\n" if $universe;
	$out .= "<div>\n";
	$out .= "$story\n";
	$out .= "</div>\n";
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
    if ($args{url} =~ m#https?://www.fanfiction.net/s/(\d+)/#)
    {
	$sid = $1;
    }
    else
    {
	return $self->SUPER::parse_toc(%args);
    }
    $info{title} = $self->parse_title(%args);
    my $auth_url = '';
    if ($content =~ m#href='(/u/\d+/[-\w]+)'>([^<]+)</a>#s)
    {
	$auth_url = $1;
	$info{author} = $2;
        warn "author from URL=$info{author}\n" if ($self->{verbose} > 1);
    }
    else
    {
	$info{author} = $self->parse_author(%args);
    }
    # The summary is on the Author page!
    if ($auth_url && $sid)
    {
        my $auth_page = $self->get_page("http://www.fanfiction.net${auth_url}");
	if ($auth_page =~ m#<a href="/s/${sid}/\d+/[-\w]+">.*?<div\s*class='[-\w\s]+'>([^<]+)<div#s)
	{
	    $info{summary} = $1;
	}
	elsif ($auth_page =~ m#<a class=reviews href='/r/${sid}/'>reviews</a>\s*<div class='z-indent z-padtop'>([^<]+)<div#s)
	{
	    $info{summary} = $1;
	}
	else
	{
	    $info{summary} = $self->parse_summary(%args);
	}
    }
    else
    {
	$info{summary} = $self->parse_summary(%args);
    }

    # get the mobile version of the page in order to parse the other stuff
    my $mob_url = $args{url};
    $mob_url =~ s/www/m/;
    my $mob_page = $self->get_page($mob_url);
    $info{characters} = $self->parse_characters(%args,content=>$mob_page);
    $info{category} = $self->parse_category(%args,content=>$mob_page);
    $info{universe} = $self->parse_universe(%args,content=>$mob_page);

    # this needs the non-mobile version
    $info{chapters} = $self->parse_chapter_urls(%args,
	sid=>$sid, mob_url=>$mob_url);

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
	    $chapters[$i] =~ s/www/m/; # convert to mobile-site URL
	}
    }

    if (@chapters == 0 or @chapters == 1)
    {
	# fortunately fanfiction.net has a sane-ish chapter system
        if ($content =~ m#-\s+Chapters:\s+(\d+)\s+-\s+Words:\s+[\d,]#is)
        {
            my $num_chapters = $1;
            @chapters = ();
            my $fmt = $args{url};
            $fmt =~ s/www/m/;
            $fmt =~ s!/\d+/\d+/!/%d/\%d/!;
            for (my $i=1; $i <= $num_chapters; $i++)
            {
                my $ch_url = sprintf($fmt, $sid, $i);
                warn "chapter=$ch_url\n" if ($self->{verbose} > 1);
                push @chapters, $ch_url;
            }
        }
        else
        {
            @chapters = ($args{mob_url});
        }
    }

    return \@chapters;
} # parse_chapter_urls

=head2 parse_category

Get the categories.

=cut
sub parse_category {
    my $self = shift;
    my %args = @_;

    my $content = $args{content};

    my $category = '';
    my $characters = '';
    if ($content =~ m!Rated:\s*[+\w]+,\s*English,\s*([^,]+),\s*(.*?),\s*Words:!)
    {
	$category = $1;
	$characters = $2;
	$category =~ s!\s*\&\s!, !g;
	$characters =~ s!\.!!g;
    }
    elsif ($content =~ m!Rated:\s*[+\w]+,\s*English,\s*([^,]+),\s*([^,]+),\s*Words:[^<]+!)
    {
	$category = $1;
	$characters = $2;
	$category =~ s!\s*\&\s!, !g;
	$characters =~ s!\s*\&\s!, !g;
	$characters =~ s!\.!!g;
    }
    elsif ($content =~ m!Rated:\s*[+\w]+,\s*English,\s*([^,]+),\s*Words:[^<]+!)
    {
        # only one of category or characters
	$category = $1;
        if ($category =~ /\./)
        {
            # these are characters
            $category = '';
        }
        else
        {
            $category =~ s!\s*\&\s!, !g;
        }
    }
    elsif ($content =~ m!Rated:\s*[\w]+,\s*English,\s*([^,]+),\s*([^,]+),\s*(P:[^<]+)<!)
    {
	$category = $1;
	$characters = $2;
	$category =~ s!\s*\&\s!, !g;
	$characters =~ s!\s*\&\s!, !g;
	$characters =~ s!\.!!g;
    }
    else
    {
	$category = $self->SUPER::parse_category(%args);
    }
    return $category;
} # parse_category

=head2 parse_characters

Get the characters.

=cut
sub parse_characters {
    my $self = shift;
    my %args = @_;

    my $content = $args{content};

    my $category = '';
    my $characters = '';
    if ($content =~ m!Rated:\s*[+\w]+,\s*English,\s*([^,]+),\s*(.*?),\s*Words:!)
    {
	$category = $1;
	$characters = $2;
	$category =~ s!\s*\&\s!, !g;
	$characters =~ s!\.!!g;
    }
    elsif ($content =~ m!Rated:\s*[+\w]+,\s*English,\s*([^,]+),\s*([^,]+),\s*Words:[^<]+!)
    {
	$category = $1;
	$characters = $2;
	$category =~ s!\s*\&\s!, !g;
	$characters =~ s!\s*\&\s!, !g;
	$characters =~ s!\.!!g;
    }
    elsif ($content =~ m!Rated:\s*[+\w]+,\s*English,\s*([^,]+),\s*Words:[^<]+!)
    {
        # only one of category or characters
	$characters = $1;
        if ($characters =~ /\./)
        {
            # these are characters
            $characters =~ s!\s*\&\s!, !g;
            $characters =~ s!\.!!g;
        }
        else
        {
            $characters = '';
        }
    }
    elsif ($content =~ m!Rated:\s*[-\w]+,\s*English,\s*([^,]+),\s*([^,]+),\s*(P:[^<]+)<!)
    {
        $category = $1;
        $characters = $2;
        $category =~ s!\s*\&\s!, !g;
        $characters =~ s!\s*\&\s!, !g;
        $characters =~ s!\.!!g;
    }
    else
    {
        $characters = $self->SUPER::parse_characters(%args);
    }

    # Correct some character names
    $characters =~ s/Hermione G/Hermione Granger/;
    $characters =~ s/Severus S/Severus Snape/;
    $characters =~ s/Harry P/Harry Potter/;
    $characters =~ s/Draco M/Draco Malfoy/;
    $characters =~ s/Remus L/Remus Lupin/;
    $characters =~ s/Sirius B/Sirius Black/;
    $characters =~ s/Alastor M/Alastor Moody/;
    $characters =~ s/Ginny W/Ginny Weasley/;
    $characters =~ s/Fred W/Fred Weasley/;
    $characters =~ s/George W/George Weasley/;
    $characters =~ s/8th Doctor/Eighth Doctor/;
    $characters =~ s/9th Doctor/Ninth Doctor/;
    $characters =~ s/10th Doctor/Tenth Doctor/;
    $characters =~ s/11th Doctor/Eleventh Doctor/;
    $characters =~ s/Rose T/Rose Tyler/;
    $characters =~ s/Donna N/Donna Noble/;
    $characters =~ s/Jenny - Doctor's Daughter/Jenny/;
    $characters =~ s#River Song/Melody P III#River Song#;

    return $characters;
} # parse_characters

=head2 parse_universe

Get the universe.

=cut
sub parse_universe {
    my $self = shift;
    my %args = @_;

    my $content = $args{content};

    my $universe = '';
    if ($content =~ m!&#187; <a href="/(?:anime|book|cartoon|comic|game|misc|movie|play|tv)/[-\w]+/">([^<]+)</a>!)
    {
	$universe = $1;
    }
    else
    {
	$universe = $self->SUPER::parse_universe(%args);
    }
    return $universe;
} # parse_universe

=head2 parse_author

Get the author from the content

=cut
sub parse_author {
    my $self = shift;
    my %args = (
	content=>'',
	@_
    );

    my $author = $self->SUPER::parse_author(%args);
    # extract the actual author name
    if ($author =~ m#<a href='/u/\d+/[-\w]+'>([^<]+)</a>#s)
    {
        $author = $1;
    }

    return $author;
} # parse_author

=head2 parse_title

Get the title from the content

=cut
sub parse_title {
    my $self = shift;
    my %args = (
	content=>'',
	@_
    );

    my $content = $args{content};
    my $title = '';
    if ($content =~ m/&#187; <b>([^<]+)<\/b>/s)
    {
	$title = $1;
    }
    elsif ($content =~ m#<title>([^<]+)\s*Chapter[^<]+</title>#is)
    {
	$title = $1;
    }
    elsif ($content =~ m#<title>([^<]+), a [^<]+ fanfic [|] FanFiction</title>#is)
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
    if ($content =~ m#^Chapter\s*(\d+:[^<]+)<br#m)
    {
        $title = $1;
    }
    elsif ($content =~ m#<option[^>]+selected>([^<]+)</option>#s)
    {
	$title = $1;
    }
    elsif ($content =~ m#<SELECT title='chapter navigation'.*?<option[^>]+selected>([^<]+)<#s)
    {
	$title = $1;
    }
    elsif ($content =~ m#<title>([^<]+)</title>#is)
    {
	$title = $1;
    }
    else
    {
        $title = '';
    }
    $title =~ s/<u>//ig;
    $title =~ s/<\/u>//ig;
    $title =~ s/^Fanfic:\s*//;
    return $title;
} # parse_ch_title

1; # End of WWW::FetchStory::Fetcher::FanfictionNet
__END__
