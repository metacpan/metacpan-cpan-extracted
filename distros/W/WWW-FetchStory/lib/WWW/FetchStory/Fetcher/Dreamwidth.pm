package WWW::FetchStory::Fetcher::Dreamwidth;
$WWW::FetchStory::Fetcher::Dreamwidth::VERSION = '0.2501';
use strict;
use warnings;
=head1 NAME

WWW::FetchStory::Fetcher::Dreamwidth - fetching module for WWW::FetchStory

=head1 VERSION

version 0.2501

=head1 DESCRIPTION

This is the Dreamwidth story-fetching plugin for WWW::FetchStory.

=cut

use parent qw(WWW::FetchStory::Fetcher);

=head1 METHODS

=head2 info

Information about the fetcher.

$info = $self->info();

=cut

sub info {
    my $self = shift;
    
    my $info = "(http://www.dreamwidth.org) Journalling site where some post their fiction.";

    return $info;
} # info

=head2 priority

The priority of this fetcher.  Fetchers with higher priority
get tried first.  This is useful where there may be a generic
fetcher for a particular site, and then a more specialized fetcher
for particular sections of a site.  For example, there may be a
generic Dreamwidth fetcher, and then refinements for particular
Dreamwidth community, such as the sshg_exchange community.
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

    return ($url =~ /\.dreamwidth\.org/);
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

    my $user= '';
    my $title = '';
    my $url = '';
    if ($content =~ m#<title>([\w]+):\s*([^<]+)</title>#s)
    {
	$user= $1;
	$title = $2;
    }
    elsif ($content =~ m#<title>([^<]+)</title>#s)
    {
	$title = $1;
    }
    if ($content =~ m#([-\w]+)</b></a></span>\) wrote in <span class='ljuser'#s)
    {
	$user = $1;
    }

    my $year = '';
    my $month = '';
    my $day = '';
    if ($content =~ m#wrote,<br /><font[^>]+>\@\s*<a href="[^"]+">(\d+)</a>-<a href="[^"]+">(\d+)</a>-<a href="[^"]+">(\d+)</a>#s)
    {
	$year = $1;
	$month = $2;
	$day = $3;
	warn "year=$year,month=$month,day=$day\n" if ($self->{verbose} > 1);
    }

    if (!$url)
    {
	if ($content =~ m#<a[^>]*href=["']([^?\s]+)\?mode=reply["']\s*>Post a new comment#s)
	{
	    $url = $1;
	}
	elsif ($content =~ m#<a[^>]*href=["']([^?\s]+)\?mode=reply#s)
	{
	    $url = $1;
	}
	elsif ($content =~ m#<a[^>]*href="([^?\s]+)"\s*>Link</a>#s)
	{
	    $url = $1;
	}
    }
    if (!$user && $url && ($url =~ m#http://([-\w]+)\.dreamwidth\.org#s))
    {
	$user = $1;
    }

    my $story = '';
    if ($content =~ m#<div id='entrysubj'>(.*?)<div id='Comments'>#s)
    {
	$story = $1;
    }
    elsif ($content =~ m#<div id='entrysubj'>(.*?)<div role="navigation">#s)
    {
	$story = $1;
    }
    elsif ($content =~ m#<div class="entry"[^>]*>(.*?)<div class="tag">#s)
    {
	$story = $1;
    }
    warn "user=$user, title=$title\n" if ($self->{verbose} > 1);
    warn "url=$url\n" if ($self->{verbose} > 1);
    if ($story)
    {
	$story = $self->tidy_chars($story);
	# remove cutid1
	$story =~ s#<a name="cutid."></a>##sg;
    }
    else
    {
	print STDERR "story not found\n";
	return $self->tidy_chars($content);
    }

    my $out = <<EOT;
<h1>$title</h1>
<p>by $user</p>
<p>$year-$month-$day (from <a href='$url'>here</a>)</p>
<p>$story
EOT
    return ($out, $title);
} # extract_story

=head2 get_toc

Get a table-of-contents page.

=cut
sub get_toc {
    my $self = shift;
    my %args = @_;
    my $url = $args{first_url};

    return $self->get_page("${url}?format=light");
} # get_toc

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
    my $user = '';
    my $is_community = 0;
    if ($args{url} =~ m{http://([-\w]+)\.dreamwidth\.org})
    {
	$user = $1;
    }
    if ($user eq 'community')
    {
	$is_community = 1;
	$user = '';
	if ($args{url} =~ m{http://community\.dreamwidth\.org/([-\w]+)})
	{
	    $user = $1;
	}
    }

    my %info = ();
    $info{url} = $args{url};

    $info{toc_first} = 1;

    my $title = $self->parse_title(%args);
    $title =~ s/${user}:\s*//;
    $info{title} = $title;

    my $summary = $self->parse_summary(%args);
    $summary =~ s/"/'/g;
    $info{summary} = $summary;

    $info{universe} = $self->parse_universe(%args);

    my $author = $self->parse_author(%args);
    if (!$author) 
    {
	$author = $user;
    }
    $info{author} = $author;

    my $characters = $self->parse_characters(%args);
    $info{characters} = $characters;

    $info{chapters} = $self->parse_chapter_urls(%args,
	user=>$user,
	is_community=>$is_community);

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
    my $user = $args{user};
    my @chapters = ();
    if (defined $args{urls})
    {
	@chapters = @{$args{urls}};
	for (my $i = 0; $i < @chapters; $i++)
	{
	    $chapters[$i] = sprintf('%s?format=light', $chapters[$i]);
	}
    }
    if (@chapters == 1 and $user)
    {
	warn "user=$user\n" if ($self->{verbose} > 1);
	if ($args{is_community})
	{
	    while ($content =~
		m/href="(http:\/\/community\.dreamwidth\.org\/${user}\/\d+.html)(#cutid\d)?">/sg)
	    {
		my $ch_url = $1;
		if ($ch_url ne $args{url})
		{
		    warn "chapter=$ch_url\n" if ($self->{verbose} > 1);
		    push @chapters, "${ch_url}?format=light";
		}
	    }
	}
	else
	{
	    while ($content =~
		m/href="(http:\/\/${user}\.dreamwidth\.org\/\d+.html)(#cutid\d)?">/sg)
	    {
		my $ch_url = $1;
		if ($ch_url ne $args{url})
		{
		    warn "chapter=$ch_url\n" if ($self->{verbose} > 1);
		    push @chapters, "${ch_url}?format=light";
		}
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
    my $author = $self->SUPER::parse_author(%args);

    if ($author =~ m#<span lj:user='\w+' style='white-space: nowrap;' class='ljuser'><a href='http://www\.dreamwidth\.org/profile\?user=\w+'><img src='http://www\.dreamwidth\.org/img/silk/identity/user\.png' alt='\[profile\] ' width='17' height='17' style='vertical-align: text-bottom; border: 0; padding-right: 1px;' /></a><a href='http://www\.dreamwidth\.org/profile\?user=\w+'><b>(.*?)</b></a></span>#)
    {
	$author = $1;
    }
    elsif ($author =~ m#<a href='http://[-\w]+\.dreamwidth\.org/'><b>(.*?)</b></a>#)
    {
	$author = $1;
    }
    return $author;
} # parse_author

1; # End of WWW::FetchStory::Fetcher::Dreamwidth
__END__
