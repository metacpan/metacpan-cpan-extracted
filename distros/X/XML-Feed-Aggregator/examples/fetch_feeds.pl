use 5.012;
use utf8;
use strict;
use warnings;
use HTTP::Date;
use HTML::Zoom;
use XML::Feed::Aggregator;

binmode(STDOUT, ":utf8");

my $agg = XML::Feed::Aggregator->new({sources => [
    "http://blogs.perl.org/atom.xml",
    "http://planet.perl.org/rss20.xml",
    "http://ironman.enlightenedperl.org/atom.xml",
    "http://blog.basho.com/feed/index.xml",
#    "http://news.ycombinator.com/rss"
    ]
});

$agg->fetch->aggregate->grep_entries(sub {
        return 0 if $_->title =~ /perl\s?6/i;
        return 0 if $_->title =~ /mojolicious/i;
        return 0 if $_->title =~ /strawberry/i;
        return 0 unless length( $_->content || $_->summary ) > 0;
        return 0 unless defined $_->title ? 1 : 0;
        return 0 unless defined ($_->issued || $_->modified) ? 1 : 0;
        return 1;
    });

$agg->sort_by_date_ascending;

my $title = "My Feeds - generated ".time2str();

my $template = <<HEADER;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
<style type="text/css">

body{
    font-family: Trebuchet MS, Lucida Sans Unicode, Arial, sans-serif;  /* Font to use */
    margin:4px;
}

</style>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/> 
   <title>$title</title>
</head>

<body>
<h1>$title</h1>
<div id="entry">
<div id="entry_title">
</div>
<div>
<div id="entry_body">
<hr id="end"/>
</div>
</div>
</body>
</html>
HEADER

my $zoom = HTML::Zoom->from_html($template);

my @entries = $agg->map_entries(sub {
        my $pub = $_->issued || $_->modified;

        my $title = $_->title;
        utf8::decode($title);

        my $entry_title = HTML::Zoom->from_html('<h3>'.$pub->ymd('-') . ' ' . $pub->hms(':')
            .' ' . $_->title . ' <a href="'.$_->link.'">LINKY?!</a> '
            . ' By ' . ($_->author || '?' ). '</h3>');
       
        my $body = length($_->content->body || '') 
            >= length($_->summary->body || '') 
                ? $_->content->body : $_->summary->body;

        utf8::decode($body);

        my $entry_body = HTML::Zoom->from_html($body);

        return sub {
           $_->select('#entry_title')->replace_content($entry_title)
            ->select('#entry_body')->replace_content($entry_body);
        }
    } 
);

print $zoom->select('#entry')->repeat_content(\@entries,
    { repeat_between => '#end' })->to_html;

