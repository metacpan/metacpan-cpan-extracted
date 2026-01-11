package WWW::Noss::FeedReader::Atom;
use 5.016;
use strict;
use warnings;
our $VERSION = '2.02';

use WWW::Noss::FeedReader::MediaRSS qw(parse_media_node);
use WWW::Noss::TextToHtml qw(text2html unescape_html strip_tags);
use WWW::Noss::Timestamp;

our $NS = 'http://www.w3.org/2005/Atom';

sub _name {

    my ($node) = @_;

    my ($email_node, $name_node);

    for my $n ($node->childNodes) {
        my $node_name = $n->nodeName;
        if ($node_name eq 'name') {
            $name_node = $n;
        } elsif ($node_name eq 'email') {
            $email_node = $n;
        }
    }

    my $name  = defined $name_node ? $name_node->textContent : '';
    my $email = defined $email_node ? $email_node->textContent : '';

    if ($name ne '' and $email ne '') {
        return sprintf "%s (%s)", $email, $name;
    } elsif ($email ne '') {
        return $email;
    } elsif ($name ne '') {
        return $name;
    } else {
        return undef;
    }

}

sub _link {

    my ($node) = @_;

    my $href = $node->getAttribute('href');

    return undef unless defined $href;

    my $rel = $node->getAttribute('rel') // 'alternate';

    return $rel eq 'alternate' ? $href : undef;

}

sub _time {

    my ($node) = @_;

    return WWW::Noss::Timestamp->rfc3339($node->textContent);

}

sub _title {

    my ($node) = @_;

    my ($title, $display);
    $title = $node->textContent;
    my $type = $node->getAttribute('type') // 'text';
    if ($type eq 'html') {
        $display = unescape_html(strip_tags($title));
    } else {
        $display = $title;
    }

    $display =~ s/\s+/ /g;
    $display =~ s/^\s+|\s+$//g;

    return wantarray ? ($title, $display) : $display;

}

sub _content {

    my ($node) = @_;

    my $type = $node->getAttribute('type') // 'text';
    my $src = $node->getAttribute('src');

    if ($type eq 'text') {
        return text2html($node->textContent);
    } elsif ($type eq 'html') {
        return $node->textContent;
    } elsif ($type eq 'xhtml') {
        return join '', map { $_->toString } $node->childNodes;
    } elsif (defined $src) {
        return undef;
    } elsif ($type =~ /[\+\/]xml$/) {
        return join '', map { $_->toString } $node->childNodes;
    } elsif ($type =~ /^text/) {
        return text2html($node->textContent);
    } else {
        return undef;
    }

}

sub _summary {

    my ($node) = @_;

    my $type = $node->getAttribute('type') // 'text';

    if ($type eq 'html') {
        return $node->textContent;
    } elsif ($type eq 'xhtml') {
        return join '', map { $_->toString } $node->childNodes;
    } elsif ($type eq 'text') {
        return text2html($node->textContent);
    } else {
        return undef;
    }

}

sub _read_entry {

    my ($node) = @_;

    my $entry = {
        nossid    => undef,
        status    => undef,
        feed      => undef,
        title     => undef,
        link      => undef,
        author    => undef,
        category  => undef,
        summary   => undef,
        published => undef,
        updated   => undef,
        uid       => undef,
    };

    my $summary;

    for my $n ($node->childNodes) {

        my $name = $n->nodeName;

        if ($name =~ /^media:/) {
            my $c = parse_media_node($n);
            for my $k (keys %$c) {
                if (ref $c->{ $k } eq 'ARRAY') {
                    push @{ $entry->{ $k } }, @{ $c->{ $k } };
                } else {
                    $entry->{ $k } //= $c->{ $k };
                }
            }
        } elsif ($name eq 'id') {
            $entry->{ uid } = $n->textContent;
        } elsif ($name eq 'title') {
            @{ $entry }{ qw(title displaytitle) } = _title($n);
        } elsif ($name eq 'updated') {
            $entry->{ updated } = _time($n);
        } elsif ($name eq 'author') {
            $entry->{ author } = _name($n);
        } elsif ($name eq 'content') {
            $entry->{ summary } = _content($n);
        } elsif ($name eq 'link') {
            $entry->{ link } = _link($n);
        } elsif ($name eq 'summary') {
            $summary = _summary($n);
        } elsif ($name eq 'category') {
            my $term = $n->getAttribute('term');
            next unless defined $term;
            push @{ $entry->{ category } }, $term;
        } elsif ($name eq 'published') {
            $entry->{ published } = _time($n);
        }

    }

    if (not defined $entry->{ summary } and defined $summary) {
        $entry->{ summary } = $summary;
    }

    $entry->{ title } //= $entry->{ link };

    return $entry;

}

sub read_feed {

    my ($class, $feed, $dom) = @_;

    my $channel = {
        nossname    => $feed->name,
        nosslink    => $feed->feed,
        title       => undef,
        link        => undef,
        description => undef,
        updated     => undef,
        author      => undef,
        category    => undef,
        generator   => undef,
        image       => undef,
        rights      => undef,
        skiphours   => undef,
        skipdays    => undef,
    };

    my $entries = [];

    my @entry_nodes;

    for my $n ($dom->documentElement->childNodes) {

        my $name = $n->nodeName;

        if ($name eq 'entry') {
            push @entry_nodes, $n;
        } elsif ($name eq 'title') {
            $channel->{ title } = _title($n);
        } elsif ($name eq 'link') {
            $channel->{ link } = _link($n);
        } elsif ($name eq 'updated') {
            $channel->{ updated } = _time($n);
        } elsif ($name eq 'author') {
            $channel->{ author } = _name($n);
        } elsif ($name eq 'category') {
            my $term = $n->getAttribute('term');
            next unless defined $term;
            push @{ $channel->{ category } }, $term;
        } elsif ($name eq 'generator') {
            $channel->{ generator } = $n->textContent;
        } elsif ($name eq 'logo') {
            $channel->{ image } = $n->textContent;
        } elsif ($name eq 'rights') {
            $channel->{ rights } = $n->textContent;
        } elsif ($name eq 'subtitle') {
            $channel->{ description } = $n->textContent;
        }

    }

    if (not defined $channel->{ title }) {
        die sprintf "%s is not a valid Atom feed\n", $feed->name;
    }

    for my $n (@entry_nodes) {
        my $e = _read_entry($n);
        next unless defined $e;
        $e->{ feed } = $channel->{ nossname };
        push @$entries, $e;
    }

    unless (@$entries) {
        die sprintf "%s contains no posts\n", $feed->name;
    }

    @$entries =
        map { $_->[1] }
        sort {
            my $at = $a->[1]{ published } // $a->[1]{ updated };
            my $bt = $b->[1]{ published } // $b->[1]{ updated };
            if (not defined $at and not defined $bt) {
                $a->[0] <=> $b->[0];
            } elsif (not defined $at) {
                -1;
            } elsif (not defined $bt) {
                1;
            } else {
                $at <=> $bt;
            }
        }
        map { [ $_, $entries->[$_]] }
        0 .. $#$entries;

    $channel->{ updated } //=
        $entries->[$#$entries]{ updated } //
        $entries->[$#$entries]{ published };

    # So the feed doesn't have an updated field (which is technically required),
    # and none of its posts have an updated or published field either. The
    # feed is probably beyond saving.
    if (not defined $channel->{ updated }) {
        die sprintf "%s is not a valid Atom feed\n", $feed->name;
    }

    return ($channel, $entries);

}

1;

# vim: expandtab shiftwidth=4
