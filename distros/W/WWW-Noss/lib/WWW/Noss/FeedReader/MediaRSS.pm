package WWW::Noss::FeedReader::MediaRSS;
use 5.016;
use strict;
use warnings;
our $VERSION = '2.01';

use Exporter qw(import);
our @EXPORT_OK = qw(parse_media_node);

use List::Util qw(uniq);

use WWW::Noss::TextToHtml qw(text2html strip_tags unescape_html);

sub _parse_media_title {

    my ($node) = @_;

    my $type = $node->getAttribute('type') // 'plain';

    my ($title, $display);
    $title = $node->textContent;
    if ($type eq 'html') {
        $display = unescape_html(strip_tags($title));
    } else {
        $display = $title;
    }

    $display =~ s/\s+/ /g;
    $display =~ s/^\s+|\s+$//g;

    return wantarray ? ($title, $display) : $display;

}

sub _parse_media_description {

    my ($node) = @_;

    my $type = $node->getAttribute('type') // 'plain';

    if ($type eq 'html') {
        return $node->textContent;
    } else {
        return text2html($node->textContent);
    }

}

sub _parse_media_content {

    my ($node) = @_;

    my $data = {};
    my $url = $node->getAttribute('url');
    $data->{ link } = $url if defined $url;

    for my $n ($node->childNodes) {
        next if $n->nodeName !~ /^media:/;
        my $c = parse_media_node($n);
        for my $k (keys %$c) {
            $data->{ $k } //= $c->{ $k };
        }
    }

    return $data;

}

sub parse_media_node {

    my ($node) = @_;

    my $data = {};

    my $name = $node->nodeName;
    $name =~ s/^media:// or die "invalid MRSS node";

    if ($name eq 'content') {
        my $c = _parse_media_content($node);
        for my $k (keys %$c) {
            $data->{ $k } //= $c->{ $k };
        }
    } elsif ($name eq 'group') {
        for my $n ($node->childNodes) {
            next if $n->nodeName !~ /^media:/;
            my $c = parse_media_node($n);
            for my $k (keys %$c) {
                $data->{ $k } //= $c->{ $k };
            }
        }
    } elsif ($name eq 'title') {
        if (not defined $data->{ title }) {
            @{ $data }{ qw(title displaytitle) } = _parse_media_title($node);
        }
    } elsif ($name eq 'description') {
        $data->{ summary } //= _parse_media_description($node);
    } elsif ($name eq 'keywords') {
        push @{ $data->{ category } }, split /\s*,\s*/, $node->textContent;
    } elsif ($name eq 'player') {
        my $url = $name->getAttribute('url');
        if (defined $url) {
            $data->{ link } //= $url;
        }
    }

    if (defined $data->{ category }) {
        $data->{ category } = [ uniq sort @{ $data->{ category } } ];
    }

    return $data;

}

1;

# vim: expandtab shiftwidth=4
