package WWW::FetchStory::Fetcher::LiveJournal;
$WWW::FetchStory::Fetcher::LiveJournal::VERSION = '0.2002';
use strict;
use warnings;
use HTML::Entities;
=head1 NAME

WWW::FetchStory::Fetcher::LiveJournal - fetching module for WWW::FetchStory

=head1 VERSION

version 0.2002

=head1 DESCRIPTION

This is the LiveJournal story-fetching plugin for WWW::FetchStory.

=cut

our @ISA = qw(WWW::FetchStory::Fetcher);

=head1 METHODS

=head2 info

Information about the fetcher.

$info = $self->info();

=cut

sub info {
    my $self = shift;
    
    my $info = "(http://www.livejournal.com/) Journalling site where some people post their fiction.";

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

    return ($url =~ /\.livejournal\.com/);
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

    my $ljuser= '';
    my $title = $args{title};
    my $url = '';
    if ($content =~ m#<title>([\w]+):\s*([^<]+)</title>#s)
    {
	$ljuser= $1;
	$title = $2;
    }
    elsif ($content =~ m#<h1 class="b-singlepost-title">\s*([^<]+)\s*</h1>#s)
    {
	$title = $1;
    }
    elsif ($content =~ m#<title>([^<]+)</title>#s)
    {
	$title = $1;
    }
    elsif ($content =~ m#<h2 class="asset-name page-header2"><a href="([^"]+)">([^>]+)</a></h2>#)
    {
	$url = $1;
	$title = $2;
    }
    elsif ($content =~ m#<div class="subject">([^<]+)</div>#)
    {
	$title = $1;
    }
    if ($content =~ m#([-\w]+)</b></a></span>\) wrote in <span class='ljuser'#s)
    {
	$ljuser = $1;
    }

    if (!$url)
    {
        if ($content =~ m#(http://[-\w]+.livejournal.com/\d+\.html)\?format=light\&mode=reply#s)
        {
	    $url = $1;
        }
	elsif ($content =~ m#<a[^>]*href=["']([^?\s]+)\?mode=reply["']\s*>Post a new comment#s)
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
    if (!$ljuser && $url && ($url =~ m#http://([-\w]+)\.livejournal\.com#s))
    {
	$ljuser = $1;
    }

    my $story = '';
    if ($content =~ m#<article class="\s*b-singlepost-body[^>]*>(.*?)</article>#s)
    {
	$story = $1;
    }
    elsif ($content =~ m#<article class="\s*b-singlepost-body[^>]*>(.*?)<div class="\s*b-singlepost-tags ljtags\s*"#s)
    {
	$story = $1;
    }
    elsif ($content =~ m#<div class="b-singlepost-body">(.*?)<div id="comments"#s)
    {
	$story = $1;
    }
    elsif ($content =~ m#</table><p>(.*)<br[^>]*/><hr[^>]*/><div id='Comments'>#s)
    {
	$story = $1;
    }
    elsif ($content =~ m#<div class="b-singlepost-body">(.*?)<div class="b-singlepost-tags ljtags">#s)
    {
	$story = $1;
    }
    elsif ($content =~ m#<div class="b-singlepost-body">(.*?)</div>#s)
    {
	$story = $1;
    }
    elsif ($content =~ m#<div class="entrytext">(.*?)<div class="meta">#s)
    {
	$story = $1;
    }
    elsif ($content =~ m#<div style='[^']+'>(.*)</div>\s*<br[^>]*/><hr[^>]*/><div id='Comments'>#s)
    {
	$story = $1;
    }
    elsif ($content =~ m#</table></div>(.*)<br[^>]*/><hr[^>]*/><div id='Comments'>#s)
    {
	$story = $1;
    }
    elsif ($content =~ m#<div class="asset-body">\s*<div class="user-icon"[^>]+>\s*<img[^>]+>\s*<br\s*/>\s*</div>(.*)</div>\s*<div class="lj-currents">#s)
    {
	$story = $1;
    }
    elsif ($content =~ m#<td valign='top'>(<strong>.*)<strong>Current Mood:</strong>#s)
    {
	$story = $1;
    }
    elsif ($content =~ m#<div\s*class="entryHeader">([^<]*)</div>.*?<td\s*class="entry">\s*(<div>.*?</div>)#s)
    {
	$title = $1;
	$story = $2;
    }
    elsif ($content =~ m#<div\s*class="asset-content">\s*(.*?)\s*<div class="lj-currents">#s)
    {
	$story = $1;
    }
    elsif ($content =~ m#<div\s*class="asset-content">\s*(.*?)\s*<div class="quickreply" id="ljqrtentrycomment"#s)
    {
	$story = $1;
    }
    elsif ($content =~ m#<div\s*class="entryText">\s*(.*?)\s*</div>\s*<div class="entryMetadata">#s)
    {
	$story = $1;
    }
    elsif ($content =~ m#<div\s*class="entryText">\s*(.*?)\s*</div>\s*<div class="entryFooter">#s)
    {
	$story = $1;
    }
    elsif ($content =~ m#<b>Entry tags:</b>.*?</table>(.*?)<div class="ljad ljadleaderboard"#s)
    {
	$story = $1;
    }
    elsif ($content =~ m#<b>Entry tags:</b>.*?</table>(.*?)<iframe src='http://ads.sixapart.com/#s)
    {
	$story = $1;
    }
    elsif ($content =~ m#alt="Next Entry".*?</table>\s*</div>(.*?)<iframe src='http://ads.sixapart.com/#s)
    {
	$story = $1;
    }
    elsif ($content =~ m#alt="Next Entry".*?</table>\s*</div>(.*?)<div id='Comments'>#s)
    {
	$story = $1;
    }
    elsif ($content =~ m#<div class="entry_text">(.*?)<div class="clear">#s)
    {
	$story = $1;
    }
    elsif ($content =~ m#(<b>Tags</b>.*?)\s*<div class="quickreply" id="ljqrttopcomment"#s)
    {
	$story = $1;
    }
    warn "ljuser=$ljuser, title=$title\n" if ($self->{verbose} > 1);
    warn "url=$url\n" if ($self->{verbose} > 1);
    if ($story)
    {
	# remove LJ-specific cruft
	$story =~ s#<a name="cutid."></a>##sg;
        $story =~ s#<a name='cutid.-end'></a>##sg;
        $story =~ s#<center><div class="lj-like">.*</center>##sg;
        $story =~ s#<a href="http://[A-Za-z_-]+\.livejournal\.com/profile"[^>]*>\s*<img\s*class="i-ljuser-userhead"[^>]*/>\s*</a>##sg;

	$story = $self->tidy_chars($story);
    }
    else
    {
	print STDERR "story not found\n";
        print STDERR "\n==============\n${content}\n===========\n" if ($self->{debug});
	return $self->tidy_chars($content);
    }

    my $out = <<EOT;
<h1>$title</h1>
EOT
    if ($url)
    {
        $out .= <<EOT;
<p>(from <a href='$url'>$url</a>)</p>
EOT
    }
        $out .= <<EOT;
<p>$story
EOT
    return ($out, $title);
} # extract_story

=head2 get_toc

Get a table-of-contents page.

=cut
sub get_toc {
    my $self = shift;
    my $url = shift;

    return $self->get_page("${url}?format=light");
} # get_toc

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
    if ($content =~ m#<b>Author: </b> <span\s+class="ljuser\s+i-ljuser\s+"\s+lj:user="([-_\w]+)"#)
    {
        $author = $1;
    }
    elsif ($content =~ m#<b>Creator:\s*</b>\s*<span\s+class="ljuser\s+i-ljuser\s+"\s+lj:user="([-_\w]+)"#)
    {
        $author = $1;
    }
    elsif ($content =~ m#<span class='ljuser ljuser-name_\w+' lj:user='\w+' style='white-space: nowrap;'><a href='http://\w+\.livejournal\.com/profile'><img src='http://l-stat\.livejournal\.com/img/userinfo\.gif' alt='\[info\]' width='17' height='17' style='vertical-align: bottom; border: 0; padding-right: 1px;' /></a><a href='http://\w+\.livejournal\.com/'><b>(.*?)</b></a></span>#)
    {
	$author = $1;
    }
    elsif ($content =~ m#<a href='http://[-\w]+\.livejournal\.com/'><b>(.*?)</b></a>#)
    {
	$author = $1;
    }
    else
    {
        $author = $self->SUPER::parse_author(%args);
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
    if ($content =~ /<(?:b|strong)>Title:?\s*<\/(?:b|strong)>:?\s*"?(.*?)"?\s*<(?:br|p|\/p|div|\/div)/si)
    {
	$title = $1;
    }
    elsif ($content =~ /\bTitle:\s*"?(.*?)"?\s*<br/s)
    {
	$title = $1;
    }
    elsif ($content =~ m#<title>[\w]+:\s*([^<]+)</title>#s)
    {
	$title = $1;
    }
    elsif ($content =~ m#<h1 class="b-singlepost-title">\s*([^<]+)\s*</h1>#s)
    {
	$title = $1;
    }
    elsif ($content =~ m#<title>([^<]+)</title>#s)
    {
	$title = $1;
    }
    elsif ($content =~ m#<h2 class="asset-name page-header2"><a href="([^"]+)">([^>]+)</a></h2>#)
    {
	$title = $2;
    }
    elsif ($content =~ m#<div class="subject">([^<]+)</div>#)
    {
	$title = $1;
    }
    elsif ($content =~ m#<h1>([^<]+)</h1>#is)
    {
	$title = $1;
    }
    elsif ($content =~ m#<h2>([^<]+)</h2>#is)
    {
	$title = $1;
    }
    $title = decode_entities($title); # get rid of HTML entities in the title
    $title =~ s/<u>//ig;
    $title =~ s/<\/u>//ig;
    return $title;
} # parse_title

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
    if ($args{url} =~ m{http://([-\w]+)\.livejournal\.com})
    {
	$user = $1;
    }
    if ($user eq 'community')
    {
	$is_community = 1;
	$user = '';
	if ($args{url} =~ m{http://community\.livejournal\.com/([-\w]+)})
	{
	    $user = $1;
	}
    }

    my %info = ();
    $info{url} = $args{url};
    $info{toc_first} = 1;

    my $title = $self->parse_title(%args);
    $title =~ s/${user}:\s*//;
    $title =~ s/Fic:\s*//;
    $info{title} = $title;

    my $summary = $self->parse_summary(%args);
    $summary =~ s/"/'/g;
    $info{summary} = $summary;

    my $author = $self->parse_author(%args);
    if (!$author) 
    {
	$author = $user;
    }
    $info{author} = $author;

    my $characters = $self->parse_characters(%args);
    $info{characters} = $characters;

    $info{universe} = $self->parse_universe(%args);
    $info{chapters} = $self->parse_chapter_urls(%args, user=>$user,
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

    # avoid adding duplicate URLs by remembering what we've parsed
    my %remember_ch_urls = ();
    $remember_ch_urls{$args{url}} = 1;

    if (defined $args{urls})
    {
	@chapters = @{$args{urls}};
	for (my $i = 0; $i < @chapters; $i++)
	{
	    $chapters[$i] = sprintf('%s?format=light', $chapters[$i]);
	}
    }
    if (@chapters <= 1 and $user)
    {
	warn "parse_chapter_urls: user=$user\n" if ($self->{verbose} > 1);
	if ($args{is_community})
	{
	    while ($content =~ m/href="(http:\/\/community\.livejournal\.com\/${user}\/\d+.html)/sg)
	    {
		my $ch_url = $1;
		if (!$remember_ch_urls{$ch_url})
		{
		    warn "chapter=$ch_url\n" if ($self->{verbose} > 1);
		    push @chapters, "${ch_url}?format=light";
                    $remember_ch_urls{$ch_url} = 1;
		}
	    }
	}
	else
	{
	    while ($content =~ m/<a\s+href="(http:\/\/${user}\.livejournal\.com\/\d+.html)"\s*([^>]*)>/sg)
	    {
		my $ch_url = $1;
                my $rest = $2;
                if ($rest =~ /prevnext-link/)
                {
                    # it's a prev-next link, ignore it
                }
                else
                {
                    warn "chapter='$ch_url'\n" if ($self->{verbose} > 1);
                    if (!$remember_ch_urls{$ch_url})
                    {
                        push @chapters, "${ch_url}?format=light";
                        $remember_ch_urls{$ch_url} = 1;
                    }
                }
	    }
	}
    }

    return \@chapters;
} # parse_chapter_urls

1; # End of WWW::FetchStory::Fetcher::LiveJournal
__END__
