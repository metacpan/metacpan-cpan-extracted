package WWW::FetchStory::Fetcher::Teaspoon;
$WWW::FetchStory::Fetcher::Teaspoon::VERSION = '0.2002';
use strict;
use warnings;
=head1 NAME

WWW::FetchStory::Fetcher::Teaspoon - fetching module for WWW::FetchStory

=head1 VERSION

version 0.2002

=head1 DESCRIPTION

This is the Teaspoon story-fetching plugin for WWW::FetchStory.

=cut

our @ISA = qw(WWW::FetchStory::Fetcher);

=head2 info

Information about the fetcher.

$info = $self->info();

=cut

sub info {
    my $self = shift;
    
    my $info = "(http://www.whofic.com) A Teaspoon And An Open Mind; a Doctor Who fiction archive.";

    return $info;
} # info

=head2 priority

The priority of this fetcher.  Fetchers with higher priority
get tried first.  This is useful where there may be a generic
fetcher for a particular site, and then a more specialized fetcher
for particular sections of a site.  For example, there may be a
generic Teaspoon fetcher, and then refinements for particular
Teaspoon community, such as the sshg_exchange community.
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

    return ($url =~ /whofic\.com/);
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
    if ($content =~ m#<u><a name="top"></a>(.*?) by ([\w\s]*)</u>#s)
    {
	$title = $1;
	$user= $2;
    }
    warn "user=$user, title=$title\n" if ($self->{verbose} > 1);

    my $story = '';
    if ($content =~ m#(<strong>Summary:.*)<u>Disclaimer:</u>#s)
    {
	$story = $1;
    }
    elsif ($content =~ m#<body[^>]*>(.*)</body>#s)
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

    my $out = '';
    $out .= "<h1>$title</h1>\n";
    $out .= "<p>by $user</p>\n";
    $out .= "<p>Title: $title</p>\n";
    $out .= "<p>$story\n";
    return ($out, $title);
} # extract_story

=head2 make_css

Create site-specific CSS styling.

    $css = $self->make_css();

=cut

sub make_css {
    my $self = shift;

    my $out = '';
    $out .= <<EOT;
<style type="text/css">
.title {
    font-weight: bold;
}
#notes {
border: solid black 1px;
padding: 4px;
}
</style>
EOT
    return $out;
} # make_css

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

    my $fmt = 'http://www.whofic.com/viewstory.php?action=printable&sid=%s&textsize=0&chapter=%d';

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
    if ($content =~ m#<b>([^<]+)</b> by <a href="viewuser.php\?uid=\d+">([^<]+)</a>#s)
    {
	$info{title} = $1;
	$info{author} = $2;
    }
    else
    {
	$info{title} = $self->parse_title(%args);
	$info{author} = $self->parse_author(%args);
    }
    # In order to get the summary and characters,
    # look at the "print" version of chapter 1
    my $ch1_url = sprintf($fmt, $sid, 1);
    my $chapter1 = $self->get_page($ch1_url);
    $info{summary} = $self->parse_summary(%args,content=>$chapter1);

    # the "Categories" here is which Era it is, and we can get that from the Characters
    # So let's look at the "Genres" instead.
    if ($chapter1 =~ m#<strong>Genres:</strong>\s*([^<]+)<br>#s)
    {
	$info{category} = $1;
    }

    my $characters = $self->parse_characters(%args,content=>$chapter1);
    # Rename the characters to match a different convention
    # and filter out things like 'Other Characters'
    # Do it in a hash because some characters get repeated in Multi-Era stories.
    my @chars = split(/,\s*/, $characters);
    my %char_hash = ();
    foreach my $ch (@chars)
    {
	if ($ch =~ /The Doctor \((\d+\w+)\)/)
	{
	    my $numero = $1;
	    if ($numero eq '1st')
	    {
		$char_hash{'First Doctor'} = 1;
	    }
	    elsif ($numero eq '2nd')
	    {
		$char_hash{'Second Doctor'} = 1;
	    }
	    elsif ($numero eq '3rd')
	    {
		$char_hash{'Third Doctor'} = 1;
	    }
	    elsif ($numero eq '4th')
	    {
		$char_hash{'Fourth Doctor'} = 1;
	    }
	    elsif ($numero eq '5th')
	    {
		$char_hash{'Fifth Doctor'} = 1;
	    }
	    elsif ($numero eq '6th')
	    {
		$char_hash{'Sixth Doctor'} = 1;
	    }
	    elsif ($numero eq '7th')
	    {
		$char_hash{'Seventh Doctor'} = 1;
	    }
	    elsif ($numero eq '8th')
	    {
		$char_hash{'Eighth Doctor'} = 1;
	    }
	    elsif ($numero eq '9th')
	    {
		$char_hash{'Ninth Doctor'} = 1;
	    }
	    elsif ($numero eq '10th')
	    {
		$char_hash{'Tenth Doctor'} = 1;
	    }
	    elsif ($numero eq '11th')
	    {
		$char_hash{'Eleventh Doctor'} = 1;
	    }
	}
	elsif ($ch =~ /The (Master|Doctor)\s*\((.*)\)/i)
	{
	    my $who = $1;
	    my $when = $2;
	    if ($when =~ /(:?other|unspecified|author.created)/i)
	    {
		$char_hash{$who} = 1;
	    }
	    else
	    {
		$char_hash{"$when $who"} = 1;
	    }
	}
	elsif ($ch =~ /Romana.*author created/i)
	{
	    $char_hash{'Romana'} = 1;
	}
	elsif ($ch =~ /(?:Other Character|Original Companion|Unspecified Companion|None)/i)
	{
	    # skip
	}
	elsif ($ch =~ /^The\s(.*)/)
	{
	    $char_hash{$1} = 1;
	}
	else
	{
	    $char_hash{$ch} = 1;
	}
    }
    if (%char_hash)
    {
	$info{characters} = join(', ', sort keys %char_hash);
    }
    $info{universe} = 'Doctor Who';
    $info{chapters} = $self->parse_chapter_urls(%args,
	sid=>$sid, fmt=>$fmt);

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
    my $fmt = $args{fmt};
    my @chapters = ();
    if (defined $args{urls})
    {
	@chapters = @{$args{urls}};
    }
    if (@chapters == 1)
    {
	# fortunately Teaspoon has a sane chapter system
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

1; # End of WWW::FetchStory::Fetcher::Teaspoon
__END__
