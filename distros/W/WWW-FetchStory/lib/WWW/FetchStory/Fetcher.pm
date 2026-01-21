package WWW::FetchStory::Fetcher;
$WWW::FetchStory::Fetcher::VERSION = '0.2602';
use strict;
use warnings;
=head1 NAME

WWW::FetchStory::Fetcher - fetching module for WWW::FetchStory

=head1 VERSION

version 0.2602

=head1 DESCRIPTION

This is the base class for story-fetching plugins for WWW::FetchStory.

=cut

require File::Temp;
use Date::Format;
use Encode::ZapCP1252;
use HTML::Entities;
use HTML::Strip;
use XML::LibXML;
use HTML::Tidy::libXML;
use EBook::EPUB;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use YAML::Any;
use WWW::Mechanize::Sleepy;
use Encode qw( encode );
use HTTP::Cookies;
use HTTP::Cookies::Wget;
use HTTP::Cookies::Mozilla;

=head1 METHODS

=head2 new

$obj->WWW::FetchStory::Fetcher->new();

=cut

sub new {
    my $class = shift;
    my %parameters = @_;
    my $self = bless ({%parameters}, ref ($class) || $class);

    return ($self);
} # new

=head2 init

Initialize the object.

$obj->init(%args)

=cut

sub init {
    my $self = shift;
    my %parameters = @_;

    foreach my $key (keys %parameters)
    {
	$self->{$key} = $parameters{$key};
    }

    if ($self->{use_wget})
    {
	$self->{wget_cmd} = 'wget';
	if ($self->{wget_cookies} and -f $self->{wget_cookies})
	{
	    $self->{wget_cmd} .= " --load-cookies " . $self->{wget_cookies};
	}
	if ($self->{debug})
	{
	    $self->{wget_cmd} .= " --debug";
	}
	if ($self->{wget_options})
	{
	    $self->{wget_cmd} .= ' ' . $self->{wget_options};
	}
    }
    else
    {
	$self->{user_agent} = WWW::Mechanize::Sleepy->new(
	    keep_alive => 1,
	    env_proxy => 1,
            sleep => '1..10',
            agent => ref $self,
	);
	$self->{user_agent}->show_progress($self->{verbose} > 0);
	if ($self->{firefox_cookies} and -f $self->{firefox_cookies})
	{
	    my $cookies = HTTP::Cookies::Mozilla->new(
		'file' => $self->{firefox_cookies},
		hide_cookie2 => 1,
		ignore_discard => 1,
	    );
	    print "\n--------------\n", $cookies->as_string, "\n------------\n" if ($self->{debug} && $self->{debug} > 2);
	    $self->{user_agent}->cookie_jar( $cookies );
	}
	elsif ($self->{wget_cookies} and -f $self->{wget_cookies})
	{
	    my $cookies = HTTP::Cookies::Wget->new(
		'file' => $self->{wget_cookies},
		hide_cookie2 => 1,
		ignore_discard => 1,
	    );
	    print "\n--------------\n", $cookies->as_string, "\n------------\n" if ($self->{debug} && $self->{debug} > 2);
	    $self->{user_agent}->cookie_jar( $cookies );
	}
	if ($self->{debug} && $self->{debug} > 1)
	{
	    $self->{user_agent}->add_handler("request_send",  sub { shift->dump; return });
	    $self->{user_agent}->add_handler("response_done", sub { shift->dump; return });
	}
    }

    $self->{stripper} = HTML::Strip->new();
    $self->{stripper}->add_striptag("head");

    return ($self);
} # init

=head2 name

The name of the fetcher; this is basically the last component
of the module name.  This works as either a class function or a method.

$name = $self->name();

$name = WWW::FetchStory::Fetcher::name($class);

=cut

sub name {
    my $class = shift;
    
    my $fullname = (ref ($class) ? ref ($class) : $class);

    my @bits = split('::', $fullname);
    return pop @bits;
} # name

=head2 info

Information about the fetcher.
By default this just returns the formatted name.

$info = $self->info();

=cut

sub info {
    my $self = shift;
    
    my $name = $self->name();

    # split the name into words
    my $info = $name;
    $info =~ s/([A-Z])/ $1/g;
    $info =~ s/^\s+//;

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
    return 0;
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

    return 0;
} # allow

=head2 fetch

Fetch the story, with the given options.

    %story_info = $obj->fetch(
	urls=>\@urls,
	basename=>$basename,
	toc=>0,
	yaml=>0);

=over

=item basename

Optional basename used to construct the filenames.
If this is not given, the basename is derived from the title of the story.

=item epub

Create an EPUB file, deleting the HTML files which have been downloaded.

=item toc

Build a table-of-contents file if this is true.

=item yaml

Build a YAML file with meta-data about this story if this is true.

=item meta_only

Don't download the story, just parse the meta-data from the web page.
This is useful if you've had to download the story separately due
to security restrictions.

=item use_file I<filename>

Use the given file to parse the meta-data from rather than from
the web page. (This is usually a pre-downloaded EPUB file)
Implies meta_only.

=item urls

The URLs of the story.
The first page is scraped for meta-information about the story,
including the title and author.  Site-specific Fetcher plugins can find additional
information, including the URLs of all the chapters in a multi-chapter story.

=back

=cut

sub fetch {
    my $self = shift;
    my %args = (
	urls=>undef,
	basename=>'',
	@_
    );

    $self->{verbose} = $args{verbose};

    my $first_url = $args{urls}[0];
    my $toc_content = $self->get_toc(%args, first_url=>$first_url);
    my %story_info = $self->parse_toc(%args, content=>$toc_content,
	url=>$first_url);

    my $basename = ($args{basename}
		    ? $args{basename}
		    : $self->get_story_basename($story_info{title}));
    $story_info{basename} = $basename;
    my @storyfiles = ();

    $args{meta_only} = 1 if $args{use_file};
    if ($args{meta_only})
    {
        $self->derive_values(info=>\%story_info);
        warn Dump(\%story_info) if ($self->{verbose} > 1);
    }
    else
    {
        if ($args{epub} and exists $story_info{epub_url} and $story_info{epub_url})
        {
            my %epub_info = $self->get_epub(base=>$basename,
                url=>$story_info{epub_url},
                meta=>\%story_info);
            $story_info{storyfiles} = [$epub_info{filename}];

            $self->derive_values(info=>\%story_info);
            warn Dump(\%story_info) if ($self->{verbose} > 1);
        }
        else
        {
            my @ch_urls = @{$story_info{chapters}};
            my $one_chapter = (@ch_urls == 1);
            my $first_chapter_is_toc =
            $story_info{toc_first} || $self->{first_is_toc};
            delete $story_info{toc_first};
            my @ch_titles = ();
            my @ch_wc = ();
            my $count = (($one_chapter or $first_chapter_is_toc) ? 0 : 1);
            foreach (my $i = 0; $i < @ch_urls; $i++)
            {
                my $ch_title = sprintf("%s (%d)", $story_info{title}, $i+1);
                my %ch_info = $self->get_chapter(base=>$basename,
                    count=>$count,
                    url=>$ch_urls[$i],
                    title=>$ch_title);
                push @storyfiles, $ch_info{filename};
                push @ch_titles, $ch_info{title};
                push @ch_wc, $ch_info{wordcount};
                $story_info{wordcount} += $ch_info{wordcount};
                $count++;
                sleep 1; # try not to overload the archive
            }
            $self->derive_values(info=>\%story_info);

            warn Dump(\%story_info) if ($self->{verbose} > 1);

            $story_info{storyfiles} = \@storyfiles;
            $story_info{chapter_titles} = \@ch_titles;
            $story_info{chapter_wc} = \@ch_wc;
            if ($args{toc} and !$args{epub}) # build a table-of-contents
            {
                my $toc = $self->build_toc(info=>\%story_info);
                unshift @{$story_info{storyfiles}}, $toc;
                unshift @{$story_info{chapter_titles}}, "Table of Contents";
            }
            if ($args{epub})
            {
                my $epub_file = $self->build_epub(info=>\%story_info);
                # if we have built an EPUB file, then the storyfiles
                # are now just one EPUB file.
                $story_info{storyfiles} = [$epub_file];
            }
        }
    }
    if ($args{yaml})
    {
	my $filename = sprintf("%s.yml", $story_info{basename});
	my $ofh;
	open($ofh, ">",  $filename) || die "Can't write to $filename";
	print $ofh Dump(\%story_info);
	close($ofh);
    }

    return %story_info;
} # fetch

=head1 Private Methods

=head2 get_story_basename

Figure out the file basename for a story by using its title.

    $basename = $self->get_story_basename($title);

=cut
sub get_story_basename {
    my $self = shift;
    my $title = shift;

    # make a word with only letters and numbers
    # and remove HTML entities and UTF-8
    # and with everything lowercase
    # and the spaces replaced with underscores
    my $base = $title;
    $base =~ s/^The\s+//; # get rid of leading "The "
    $base =~ s/^A\s+//; # get rid of leading "A "
    $base =~ s/^An\s+//; # get rid of leading "An "
    $base =~ s/-/ /g; # replace dashes with spaces
    $base = decode_entities($base); # replace entities with UTF-8
    $base =~ s/[^[:ascii:]]//g; # remove UTF-8
    $base =~ s/[^\w\s]//g; # remove non-word characters
    $base = lc($base);

    my @words = split(' ', $base);
    my $max_words = 3;
    my @first_words = ();
    # if there are three words or less, use all of them
    if (@words <= $max_words)
    {
	@first_words = @words;
    }
    else
    {
	$max_words++ if (@words > 3); # four
	$max_words++ if (@words > 5); # five if a lot
	for (my $i = 0; $i < @words and @first_words < $max_words; $i++)
	{
	    # skip little words
	    if ($words[$i] =~ /^(the|a|an|and)$/)
	    {
	    }
	    elsif (@words > 4 and $words[$i] =~ /^(of|to|in|or|on|by|i|is|isnt|its)$/)
	    {
		# if there are a lot of words, skip these little words too
	    }
	    else
	    {
		push @first_words, $words[$i];
	    }
	}
    }

    return join('_', @first_words);

} # get_story_basename

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

    my $story = '';
    my $title = '';
    if ($args{content} =~ m#<title>([^<]+)</title>#is)
    {
	$title = $1;
    }
    else
    {
	$title = $args{title};
    }

    # some badly formed pages have multiple BODY tags
    if ($args{content} =~ m#<body[^>]*>.*?<body[^>]*>(.*?)</body>#is)
    {
	$story = $1;
    }
    elsif ($args{content} =~ m#<body[^>]*>(.*)</body>#is)
    {
	$story = $1;
    }
    elsif ($args{content} =~ m#</head>(.*)#is)
    {
	$story = $1;
    }

    if ($story)
    {
	$story = $self->tidy_chars($story);
    }
    else
    {
	$story = $args{content};
    }

    return ($story, $title);

} # extract_story

=head2 make_css

Create site-specific CSS styling.

    $css = $self->make_css();

=cut

sub make_css {
    my $self = shift;

    return '';
} # make_css

=head2 tidy

Make a tidy, compliant XHTML page from the given story-content.

    $content = $self->tidy(story=>$story,
			   title=>$title);

=cut

sub tidy {
    my $self = shift;
    my %args = (
	story=>'',
	title=>'',
	@_
    );

    my $story = $args{story};
    $story = $self->tidy_chars($story);
    my $title = $args{title};
    my $css = $self->make_css(%args);

    my $html = '';
    $html .= "<html>\n";
    $html .= "<head>\n";
    $html .= "<title>$title</title>\n";
    $html .= $css if $css;
    $html .= "</head>\n";
    $html .= "<body>\n";
    $html .= "$story\n";
    $html .= "</body>\n";
    $html .= "</html>\n";

    my $tidy = HTML::Tidy::libXML->new();
    $html = encode("UTF-8", $html);
    my $xhtml = $tidy->clean($html, 'UTF-8', 1);

    # fixing some errors
    $xhtml =~ s!xmlns="http://www.w3.org/1999/xhtml" xmlns="http://www.w3.org/1999/xhtml"!xmlns="http://www.w3.org/1999/xhtml"!;
    $xhtml =~ s!<i/>!!g;
    $xhtml =~ s!<b/>!!g;

    return $xhtml;
} # tidy

=head2 get_toc

Get a table-of-contents page.

=cut
sub get_toc {
    my $self = shift;
    my %args = @_;
    my $url = $args{first_url};

    return $self->get_page($url);
} # get_toc

=head2 get_page

Get the contents of a URL.

=cut

sub get_page {
    my $self = shift;
    my $url = shift;

    warn "getting $url\n" if $self->{verbose};
    my $content = '';

    # The "url" might be a file instead
    if ($url !~ /http/ and -f $url)
    {
	my $ifh;
	open($ifh, $url) or die "FAILED to read ${url}: $!";
	while(<$ifh>)
	{
	    $content .= $_;
	}
	close($ifh);
    }
    elsif ($self->{use_wget})
    {
	my $cmd = sprintf("%s -O %s '%s'", $self->{wget_cmd}, '-', $url);
	warn "$cmd\n" if ($self->{verbose} > 1);
	my $ifh;
	open($ifh, "${cmd}|") or die "FAILED $cmd: $!";
	while(<$ifh>)
	{
	    $content .= $_;
	}
	close($ifh);
    }
    else
    {
	my $can_accept = HTTP::Message::decodable;
	my $res = $self->{user_agent}->get($url,
	    'Accept-Encoding' => $can_accept,
	    'Keep-Alive' => "300",
	    'Connection' => 'keep-alive',
	);

	# Check the outcome of the response
	if ($res->is_success) {
	    print $res->status_line, "\n" if $self->{debug};
	}
	else {
	    die "FAILED fetching $url ", $res->status_line;
	}
	$content = $res->decoded_content || $res->content;
    }

    if (!$content and $self->{verbose})
    {
        warn "No content from $url";
        if ($self->{debug})
        {
            # there's a problem, we want to debug it
            exit;
        }
    }

    return $content;
} # get_page

=head2 parse_toc

Parse the table-of-contents file.

This must be overridden by the specific fetcher class.

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
    $info{url} = $args{url};
    $info{title} = $self->parse_title(%args);
    $info{author} = $self->parse_author(%args);
    $info{summary} = $self->parse_summary(%args);
    $info{characters} = $self->parse_characters(%args);
    $info{universe} = $self->parse_universe(%args);
    $info{category} = $self->parse_category(%args);
    $info{rating} = $self->parse_rating(%args);
    $info{chapters} = $self->parse_chapter_urls(%args);
    $info{epub_url} = $self->parse_epub_url(%args);

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

    my @chapters = ();
    if (defined $args{urls})
    {
	@chapters = @{$args{urls}};
    }
    else
    {
	@chapters = ($args{url});
    }

    return \@chapters;
} # parse_chapter_urls

=head2 parse_epub_url

Figure out the URL for the EPUB version of this story, if there is one.

=cut
sub parse_epub_url {
    my $self = shift;
    my %args = (
	url=>'',
	content=>'',
	@_
    );

    return undef;
} # parse_epub_url

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
    if ($content =~ /<(?:b|strong)>Title:?\s*<\/(?:b|strong)>:?\s*"?(.*?)"?\s*<(?:br|p|\/p|div|\/div)/si)
    {
	$title = $1;
    }
    elsif ($content =~ /\bTitle:\s*"?(.*?)"?\s*<br/s)
    {
	$title = $1;
    }
    elsif ($content =~ m#<h1>([^<]+)</h1>#is)
    {
	$title = $1;
    }
    elsif ($content =~ m#<p class=MsoTitle>([^<]+)</p>#is)
    {
	$title = $1;
    }
    elsif ($content =~ m#<h2>([^<]+)</h2>#is)
    {
	$title = $1;
    }
    elsif ($content =~ m#<h3>([^<]+)</h3>#is)
    {
	$title = $1;
    }
    elsif ($content =~ m#<h4>([^<]+)</h4>#is)
    {
	$title = $1;
    }
    elsif ($content =~ m#<title>([^<]+)</title>#is)
    {
	$title = $1;
    }
    $title =~ s/<u>//ig;
    $title =~ s/<\/u>//ig;
    return $title;
} # parse_title

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
    if ($content =~ /Chapter \d+[:.]?\s*([^<]+)/si)
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

=head2 parse_author

Get the author from the content

=cut
sub parse_author {
    my $self = shift;
    my %args = (
	content=>'',
	@_
    );

    my $content = $args{content};
    my $author = '';
    if ($content =~ /<(?:b|strong)>Author:?\s*<\/(?:b|strong)>:?\s*"?(.*?)"?\s*<(?:br|p|\/p|div|\/div)/si)
    {
	$author = $1;
    }
    elsif ($content =~ /\bAuthor:\s*"?(.*?)"?\s*<br/si)
    {
	$author = $1;
    }
    elsif ($content =~ /<meta name="author" content="(.*?)"/si)
    {
	$author = $1;
    }
    elsif ($content =~ /<p>by (.*?)<br/si)
    {
	$author = $1;
    }
    return $author;
} # parse_author

=head2 parse_summary

Get the summary from the content

=cut
sub parse_summary {
    my $self = shift;
    my %args = (
	content=>'',
	@_
    );

    my $content = $args{content};
    my $summary = '';
    if ($content =~ /<(?:b|strong)>Summary:?\s*<\/(?:b|strong)>:?\s*"?(.*?)"?\s*<(?:br|p|\/p|div|\/div)/si)
    {
	$summary = $1;
    }
    elsif ($content =~ m#<i>Summary:</i>\s*([^<]+)\s*<br>#s)
    {
	$summary = $1;
    }
    elsif ($content =~ m#>Summary:\s*</span>\s*([^<]+)\s*<br#s)
    {
	$summary = $1;
    }
    elsif ($content =~ /<i>Summary:<\/i>\s*(.*?)\s*$/m)
    {
	$summary = $1;
    }
    elsif ($content =~ m#<tr><(?:th|td)>Summary</(?:th|td)><td>(.*?)</td></tr>#s)
    {
	$summary = $1;
	$summary =~ s/<br>/ /g;
    }
    elsif ($content =~ /\bSummary:\s*"?(.*?)"?\s*<(?:br|p|\/p|div|\/div)/si)
    {
	$summary = $1;
    }
    elsif ($content =~ m#(?:Prompt|Summary):</b>([^<]+)#is)
    {
	$summary = $1;
    }
    elsif ($content =~ m#(?:Prompt|Summary):</strong>([^<]+)#is)
    {
	$summary = $1;
    }
    elsif ($content =~ m#(?:Prompt|Summary):</u>([^<]+)#is)
    {
	$summary = $1;
    }
    return $summary;
} # parse_summary

=head2 parse_characters

Get the characters from the content

=cut
sub parse_characters {
    my $self = shift;
    my %args = (
	content=>'',
	@_
    );

    my $content = $args{content};
    my $characters = '';
    if ($content =~ />Characters:?\s*<\/(?:b|strong)>:?\s*"?(.*?)"?\s*<(?:br|p|\/p|div|\/div)/si)
    {
	$characters = $1;
    }
    elsif ($content =~ /\bCharacters:\s*"?(.*?)"?\s*<br/si)
    {
	$characters = $1;
    }
    elsif ($content =~ m#<i>Characters:</i>\s*([^<]+)\s*<br>#s)
    {
	$characters = $1;
    }
    elsif ($content =~ m#(?:Pairings?|Characters):</(?:b|strong|u)>\s*([^<]+)#is)
    {
	$characters = $1;
    }
    elsif ($content =~ m#<tr><(?:th|td)>(?:Pairings?|Characters)</(?:th|td)><td>(.*?)</td></tr>#s)
    {
	$characters = $1;
	$characters =~ s/<br>/, /g;
    }
    return $characters;
} # parse_characters

=head2 parse_universe

Get the universe/fandom from the content

=cut
sub parse_universe {
    my $self = shift;
    my %args = (
	content=>'',
	@_
    );

    my $content = $args{content};
    my $universe = '';
    if ($content =~ m#(?:Universe|Fandom):</(?:b|strong|u)>([^<]+)#is)
    {
	$universe = $1;
    }
    return $universe;
} # parse_universe

=head2 parse_recipient

Get the recipient from the content

=cut
sub parse_recipient {
    my $self = shift;
    my %args = (
	content=>'',
	@_
    );

    my $content = $args{content};
    my $recipient = '';
    if ($content =~ m#(?:Recipient|Prompter): (\w+)#is)
    {
	$recipient = $1;
    }
    elsif ($content =~ m#Recipient:</(?:b|strong|u)>([^<]+)#is)
    {
	$recipient = $1;
    }
    return $recipient;
} # parse_recipient

=head2 parse_category

Get the categories from the content

=cut
sub parse_category {
    my $self = shift;
    my %args = (
	content=>'',
	@_
    );

    my $content = $args{content};
    my $category = '';
    if ($content =~ m#(?:Category|Tags):</(?:b|strong|u)>([^<]+)#is)
    {
	$category = $1;
    }
    elsif ($content =~ m#<tr><(?:th|td)>Categories</(?:th|td)><td>(.*?)</td></tr>#s)
    {
	$category = $1;
	$category =~ s/<br>/, /g;
    }
    return $category;
} # parse_category

=head2 parse_rating

Get the rating from the content

=cut
sub parse_rating {
    my $self = shift;
    my %args = (
	content=>'',
	@_
    );

    my $content = $args{content};
    my $rating = '';
    if ($content =~ m!^Rating:\s(.*?)$!m)
    {
	$rating = $1;
    }
    elsif ($content =~ m#Rating:</(?:b|strong|u)>\s*([^<]+)#is)
    {
	$rating = $1;
    }
    return $rating;
} # parse_rating

=head2 derive_values

Calculate additional Meta values, such as current date.

=cut
sub derive_values {
    my $self = shift;
    my %args = @_;

    my $today = time2str('%Y-%m-%d', time);
    $args{info}->{fetch_date} = $today;

    my $words = $args{info}->{wordcount};
    if ($words)
    {
        my $len = '';
        if ($words == 100)
        {
            $len = 'Drabble';
        } elsif ($words == 200)
        {
            $len = 'Double Drabble';
        } elsif ($words >= 75000)
        {
            $len = 'Long Novel';
        } elsif ($words >= 50000)
        {
            $len = 'Novel';
        } elsif ($words >= 25000)
        {
            $len = 'Novella';
        } elsif ($words >= 7500)
        {
            $len = 'Novelette';
        } elsif ($words >= 2000)
        {
            $len = 'Short Story';
        } elsif ($words > 500)
        {
            $len = 'Short Short';
        } elsif ($words <= 500)
        {
            $len = 'Flash';
        }
        $args{info}->{story_length} = $len if $len;
    }
    for my $field (qw{characters universe category})
    {
	if (exists $args{info}->{$field}
		and defined $args{info}->{$field}
		and $args{info}->{$field} =~ /,/s)
	{
	    my @chars = split(/,\s*/s, $args{info}->{$field});
	    $args{info}->{$field} = \@chars;
	}
    }
} # derive_values

=head2 get_chapter

Get an individual chapter of the story, tidy it,
and save it to a file.

    $filename = $obj->get_chapter(base=>$basename,
				    count=>$count,
				    url=>$url,
				    title=>$title);

=cut

sub get_chapter {
    my $self = shift;
    my %args = (
	base=>'',
	count=>0,
	url=>'',
	title=>'',
	@_
    );

    my $content = $self->get_page($args{url});

    my ($story, $title) = $self->extract_story(%args, content=>$content);

    my $chapter_title = $self->parse_ch_title(content=>$content);
    $chapter_title = $title if !$chapter_title;

    my $html = $self->tidy(story=>$story, title=>$chapter_title);

    my %wc = $self->wordcount(content=>$html);

    #
    # Write the file
    #
    my $filename = ($args{count}
	? sprintf("%s%02d.html", $args{base}, $args{count})
	: sprintf("%s.html", $args{base}));
    my $ofh;
    open($ofh, ">",  $filename) || die "Can't write to $filename";
    print $ofh $html;
    close($ofh);

    return (
	filename=>$filename,
	title=>$chapter_title,
	wordcount=>$wc{words},
	charcount=>$wc{chars},
	);
} # get_chapter

=head2 get_epub

Get the EPUB version of the story, tidy it,
and save it to a file.

    $filename = $obj->get_epub(base=>$basename,
				    url=>$url);

=cut

sub get_epub {
    my $self = shift;
    my %args = (
	base=>'',
	url=>'',
	meta=>undef,
	@_
    );

    my %meta = %{$args{meta}};
    my $content = $self->get_page($args{url});
    my %epub_info = ();

    #
    # Write the file
    #
    my $filename = $args{base} . '.epub';
    my $ofh;
    open($ofh, ">",  $filename) || die "Can't write to $filename";
    print $ofh $content;
    close($ofh);

    $epub_info{filename} = $filename;

    #
    # Update the file metadata
    #
    my $zip = Archive::Zip->new();
    my $status = $zip->read( $filename );
    if ($status != AZ_OK)
    {
	return %epub_info;
    }
    my @members = $zip->membersMatching('.*\.opf');
    if (@members && $members[0])
    {
	my %values = ();
	my $opf = $zip->contents($members[0]);
	my $dom = XML::LibXML->load_xml(string => $opf,
	    load_ext_dtd => 0,
	    no_network => 1);
	my @metanodes = $dom->getElementsByLocalName('metadata');
	foreach my $metanode (@metanodes)
	{
	    if ($metanode->hasChildNodes)
	    {
		my @children = $metanode->childNodes();
		foreach my $node (@children)
		{
		    $self->epub_parse_one_node(%args,
			node=>$node,
			values=>\%values);
		}
	    }
	}
        print STDERR "get_epub: about to replace description\n" if $self->{debug};
        $self->epub_replace_description(description=>$meta{summary}, xml=>$dom);

	# remove meta info we don't want to be added to this
	delete $meta{description};
	delete $meta{summary};
	delete $meta{title};
	delete $meta{chapters};
	delete $meta{epub_url};
	delete $meta{basename};
	delete $meta{toc_first};
        warn "EPUB meta: ", Dump(\%meta) if ($self->{verbose} > 1);
	$self->epub_add_meta(meta=>\%meta, xml=>$dom);

	my $str = $dom->toString;
	$zip->contents($members[0], $str);
	$zip->overwrite();
    }

    return %epub_info;
} # get_epub

=head2 epub_replace_description

Replace or add the description to an EPUB file.

=cut
sub epub_replace_description {
    my $self = shift;
    my %args = @_;

    my $dom = $args{xml};
    my $desc = $args{description};
    # need to clean up the description removing things not okay to put in a meta tag
    $desc =~ s!<[^>]+>!!g;
    $desc =~ s!</[^>]+>!!g;
    $desc =~ s!"!''!g;
    print STDERR "epub_replace_description: description=$desc\n" if $self->{debug};
    my @metanodes = $dom->getElementsByLocalName('metadata');
    return unless @metanodes;
    my $metanode = $metanodes[0];
    my @dnodes = $metanode->getElementsByLocalName('description');
    if ($dnodes[0])
    {
        $metanode->removeChild($dnodes[0]);
    }
    $metanode->appendTextChild('dc:description', $desc);
} # epub_replace_description

=head2 epub_add_meta

Add the given meta-data to an EPUB file.

=cut
sub epub_add_meta {
    my $self = shift;
    my %args = @_;

    my $dom = $args{xml};
    my @metanodes = $dom->getElementsByLocalName('metadata');
    return unless @metanodes;
    my $metanode = $metanodes[0];

    my %meta = %{$args{meta}};
    foreach my $key (sort keys %meta)
    {
	my $chunk=<<EOT;
<meta name="$key" content="$meta{$key}"/>
EOT
	$metanode->appendWellBalancedChunk( $chunk );
    }

} # epub_add_meta

=head2 epub_parse_one_node

Parse a node of meta-information from an EPUB file.

=cut
sub epub_parse_one_node {
    my $self = shift;
    my %params = @_;

    my $node = $params{node};
    my $oldvals = $params{values};

    my %newvals = ();
    my $name = $node->localname;
    return undef unless $name;

    my $value = $node->textContent;
    $value =~ s/^\s+//s;
    $value =~ s/\s+$//s;
    $value =~ s/\s\s+/ /gs;
    if ($name eq 'meta' and $node->hasAttributes)
    {
	my $metaname = '';
	my $metacontent = '';
	my @atts = $node->attributes();
	foreach my $att (@atts)
	{
	    my $n = $att->localname;
	    my $v = $att->textContent;
	    $v =~ s/^\s+//s;
	    $v =~ s/\s+$//s;
	    if ($n eq 'name')
	    {
		$metaname = $v;
	    }
	    else
	    {
		$metacontent = $v;
	    }
	}
	$newvals{$metaname} = $metacontent;
    }
    elsif ($node->hasAttributes)
    {
	$newvals{$name}->{text} = $value unless !$value;
	my @atts = $node->attributes();
	foreach my $att (@atts)
	{
	    my $n = $att->localname;
	    my $v = $att->textContent;
	    $v =~ s/^\s+//s;
	    $v =~ s/\s+$//s;
	    $newvals{$name}->{$n} = $v;
	}
    }
    else
    {
	$newvals{$name} = $value;
    }

    # Don't want to overwrite existing values
    foreach my $newname (sort keys %newvals)
    {
	my $newval = $newvals{$newname};
	if (!ref $newval)
	{
	    if (!exists $oldvals->{$newname})
	    {
		$oldvals->{$newname} = $newval;
	    }
	    elsif (!ref $oldvals->{$newname}) 
	    {
		my $v = $oldvals->{$newname};
		$oldvals->{$newname} = [$v, $newval];
	    }
	    elsif (ref $oldvals->{$newname} eq 'ARRAY')
	    {
		push @{$oldvals->{$newname}}, $newval;
	    }
	    else
	    {
		$oldvals->{$newname}->{$newval} = $newval;
	    }
	}
	else
	{
	    if (!exists $oldvals->{$newname})
	    {
		$oldvals->{$newname} = $newval;
	    }
	    elsif (ref $oldvals->{$newname} eq 'ARRAY')
	    {
		push @{$oldvals->{$newname}}, $newval;
	    }
	    else
	    {
		my $v = $oldvals->{$newname};
		$oldvals->{$newname} = [$v, $newval];
	    }
	}
    }
} # epub_parse_one_node

=head2 wordcount

Figure out the word-count.

=cut
sub wordcount {
    my $self = shift;
    my %args = (
	@_
    );

    #
    # Count the words
    #
    my $stripped = $self->{stripper}->parse($args{content});
    $self->{stripper}->eof;
    $stripped =~ s/[\n\r]/ /sg; # remove line splits
    $stripped =~ s/^\s+//;
    $stripped =~ s/\s+$//;
    $stripped =~ s/\s+/ /g; # remove excess whitespace
    my @words = split(' ', $stripped);
    my $wordcount = @words;
    my $chars = length($stripped);
    if ($self->{debug})
    {
        my $orig_length = length($args{content});
        print "orig_length=$orig_length, words=$wordcount, chars=$chars\n";
        if ($wordcount < 200) # too short!
        {
            print "====== stripped ======\n$stripped\n======\n";
        }
    }
    return (
	words=>$wordcount,
	chars=>$chars,
    );
} # wordcount

=head2 build_toc

Build a local table-of-contents file from the meta-info about the story.

    $self->build_toc(info=>\%info);

=cut
sub build_toc {
    my $self = shift;
    my %args = (
	@_
    );
    my $info = $args{info};

    my $filename = sprintf("%s00.html", $info->{basename});

    my $html;
    my $characters = (ref $info->{characters}
                      ? join( ', ', @{$info->{characters}} )
                      : $info->{characters});
    my $universe = (ref $info->{universe}
                      ? join( ', ', @{$info->{universe}} )
                      : $info->{universe});
    $html = <<EOT;
<html>
<head><title>$info->{title}</title></head>
<body>
<h1>$info->{title}</h1>
<p>by $info->{author}</p>
<p>Fetched from <a href="$info->{url}">$info->{url}</a></p>
<p><b>Summary:</b>
$info->{summary}
</p>
<p><b>Words:</b> $info->{wordcount}<br/>
<b>Universe:</b> $universe</p>
<b>Characters:</b> $characters</p>
<ol>
EOT

    my @storyfiles = @{$info->{storyfiles}};
    my @ch_titles = @{$info->{chapter_titles}};
    my @ch_wc = @{$info->{chapter_wc}};
    for (my $i=0; $i < @storyfiles; $i++)
    {
	$html .= sprintf("<li><a href=\"%s\">%s</a> (%d)</li>",
			   $storyfiles[$i],
			   $ch_titles[$i],
			   $ch_wc[$i]);
    }
    $html .= "\n</ol>\n</body></html>\n";
    my $ofh;
    open($ofh, ">",  $filename) || die "Can't write to $filename";
    print $ofh $html;
    close($ofh);

    return $filename;
} # build_toc

=head2 build_epub

Create an EPUB file from the story files and meta information.

    $self->build_epub()

=cut
sub build_epub {
    my $self = shift;
    my %args = (
	@_
    );
    my $info = $args{info};

    my $epub = EBook::EPUB->new;
    $epub->add_title($info->{title});
    $epub->add_author($info->{author});
    $epub->add_description($info->{summary});
    $epub->add_language('en');
    $epub->add_source($info->{url}, 'URL');
    $epub->add_date($info->{fetch_date}, 'fetched');

    # Add Subjects and additional Meta
    # Also build up the title-page
    my $info_str =<<EOT;
<h1>$info->{title}</h1>
<p>by $info->{author}</p>
<p><b>Fetched from:</b> $info->{url}</p>
<p><b>Summary:</b> $info->{summary}</p>
<p>
EOT
    my %know = %{$info};
    delete $know{title};
    delete $know{author};
    delete $know{summary};
    delete $know{url};
    delete $know{fetch_date};
    delete $know{basename};
    delete $know{chapter_titles};
    delete $know{chapter_wc};
    delete $know{chapters};
    delete $know{storyfiles};
    foreach my $key (sort keys %know)
    {
	if (!$know{$key})
	{
	    next;
	}
	if (!ref $know{$key})
	{
	    $info_str .= sprintf("<b>%s:</b> %s<br/>\n", $key, $know{$key});
	    if ($know{$key} =~ /,\s*/)
	    {
		my @array = split(/,\s*/, $know{$key});
		foreach my $v (@array)
		{
		    if ($key =~ /^(?:category|story_length)$/)
		    {
			$epub->add_subject($v);
		    }
		    else
		    {
			$epub->add_meta_item($key, $v);
		    }
		}
	    }
	    else
	    {
		if ($key =~ /^(?:category|story_length)$/)
		{
		    $epub->add_subject($know{$key});
		}
		else
		{
		    $epub->add_meta_item($key, $know{$key});
		}
	    }
	}
	else
	{
	    $info_str .= sprintf("<b>%s:</b> %s<br/>\n", $key, join(', ', @{$know{$key}}));
	    foreach my $cat (@{$know{$key}})
	    {
		if ($key =~ /^(?:category|story_length)$/)
		{
		    $epub->add_subject($cat);
		}
		else
		{
		    $epub->add_meta_item($key, $cat);
		}
	    }
	}
    }

    $info_str .= "</p>\n";

    my $titlepage = $self->tidy(story=>$info_str, title=>$info->{title});
    my $play_order = 1;
    my $id;
    $id = $epub->add_xhtml("title.html", $titlepage);

    # Add top-level nav-point
    my $navpoint = $epub->add_navpoint(
            label       => "ToC",
            id          => $id,
            content     => "title.html",
            play_order  => $play_order # should always start with 1
    );

    my @storyfiles = @{$info->{storyfiles}};
    my @ch_titles = @{$info->{chapter_titles}};
    for (my $i=0; $i < @storyfiles; $i++)
    {
	$play_order++;
	$id = $epub->copy_xhtml($storyfiles[$i], $storyfiles[$i]);
	my $navpoint = $epub->add_navpoint(
            label       => $ch_titles[$i],
            id          => $id,
            content     => $storyfiles[$i],
            play_order  => $play_order,
	);
    }

    my $epub_file = $info->{basename} . '.epub';
    $epub->pack_zip($epub_file);

    # now unlink the storyfiles
    for (my $i=0; $i < @storyfiles; $i++)
    {
	unlink $storyfiles[$i];
    }

    return $epub_file;
} # build_epub

=head2 tidy_chars

Remove nasty encodings.
    
    $content = $self->tidy_chars($content);

=cut
sub tidy_chars {
    my $self = shift;
    my $string = shift;

    # numeric entities
    $string =~ s/&#13;//sg;
    $string =~ s/&#39;/'/sg;
    $string =~ s/&#34;/"/sg;
    $string =~ s/&#45;/-/sg;
    $string =~ s/&#160;/ /sg;

    #-------------------------------------------------------
    # from Catalyst::Plugin::Params::Demoronize
    zap_cp1252($string);

    my %replace_map = (
	'\302' => '',
	'\240' => ' ',
	);

    foreach my $replace (keys(%{replace_map})) {
	my $rr = $replace_map{$replace};
	$string =~ s/$replace/$rr/g;
    }

    #-------------------------------------------------------
    # from demoronizser
    # http://www.fourmilab.ch/webtools/demoroniser/
    #-------------------------------------------------------

    #   Supply missing semicolon at end of numeric entity if
    #   Billy's bozos left it out.

    $string =~ s/(&#[0-2]\d\d)\s/$1; /g;

    #   Fix dimbulb obscure numeric rendering of &lt; &gt; &amp;

    $string =~ s/\&\#038;/&amp;/g;
    $string =~ s/\&\#39;/&lsquo;/g;
    $string =~ s/\&\#060;/&lt;/g;
    $string =~ s/\&\#062;/&gt;/g;

    #	Translate Unicode numeric punctuation characters
    #	into ISO equivalents

    $string =~ s/&#8208;/-/sg;    	# 0x2010 Hyphen
    $string =~ s/&#8209;/-/sg;    	# 0x2011 Non-breaking hyphen
    $string =~ s/&#8211;/-/sg;   	# 0x2013 En dash
    $string =~ s/&#8212;/--/sg;   	# 0x2014 Em dash
    $string =~ s/&#8213;/--/sg;   	# 0x2015 Horizontal bar/quotation dash
    $string =~ s/&#8214;/||/sg;   	# 0x2016 Double vertical line
    $string =~ s-&#8215;-_-sg; # 0x2017 Double low line
    $string =~ s/&#8216;/`/sg;    	# 0x2018 Left single quotation mark
    $string =~ s/&#8217;/'/sg;    	# 0x2019 Right single quotation mark
    $string =~ s/&#8218;/,/sg;    	# 0x201A Single low-9 quotation mark
    $string =~ s/&#8219;/`/sg;    	# 0x201B Single high-reversed-9 quotation mark
    $string =~ s/&#8220;/"/sg;    	# 0x201C Left double quotation mark
    $string =~ s/&#8221;/"/sg;    	# 0x201D Right double quotation mark
    $string =~ s/&#8222;/,,/sg;    	# 0x201E Double low-9 quotation mark
    $string =~ s/&#8223;/"/sg;    	# 0x201F Double high-reversed-9 quotation mark
    $string =~ s/&#8226;/*/sg;  	# 0x2022 Bullet
    $string =~ s/&#8227;/*/sg;  	# 0x2023 Triangular bullet
    $string =~ s/&#8228;/./sg;  	# 0x2024 One dot leader
    $string =~ s/&#8229;/../sg;  	# 0x2026 Two dot leader
    $string =~ s/&#8230;/.../sg;  	# 0x2026 Horizontal ellipsis
    $string =~ s/&#8231;/&#183;/sg;  	# 0x2027 Hyphenation point
    #-------------------------------------------------------

    # and somehow some of the entities go funny
    $string =~ s/\&\#133;/.../g;
    $string =~ s/\&nbsp;/ /g;
    $string =~ s/\&lsquo;/'/g;
    $string =~ s/\&rsquo;/'/g;
    $string =~ s/\&ldquo;/"/g;
    $string =~ s/\&rdquo;/"/g;
    $string =~ s/\&quot;/"/g;
    $string =~ s/\&ndash;/-/g;
    $string =~ s/\&hellip;/.../g;

    # replace double-breaks with <p>
    $string =~ s#<br\s*\/?>\s*<br\s*\/?>#\n<p>#sg;

    # remove other cruft
    $string =~ s#<wbr>##sg;
    $string =~ s#</wbr>##sg;
    $string =~ s#<wbr/>##sg;
    $string =~ s#<nobr>##sg;

    # Clean unwanted MS-Word HTML
    $string =~ s#<!--\[if gte mso \d*\]>.*?<!\[endif\]-->##sg;
    $string =~ s#<!--\[if !mso\]>.*?<!\[endif\]-->##sg;
    $string =~ s!<[/]?(font|span|xml|del|ins|[ovwxp]:\w+|st\d:\w+)[^>]*?>!!igs;
    $string =~ s!<([^>]*)(?:lang|style|size|face|[ovwxp]:\w+)=(?:'[^']*'|""[^""]*""|[^\s>]+)([^>]*)>!<$1$2>!isg;
    $string =~ s/\s*class="Banner[0-9]+"//g;
    $string =~ s/\s*class="Textbody"//g;
    $string =~ s/\s*class="MsoNormal"//g;
    $string =~ s/\s*class="MsoBodyText"//g;

    return $string;
} # tidy_chars

1; # End of WWW::FetchStory::Fetcher
__END__
