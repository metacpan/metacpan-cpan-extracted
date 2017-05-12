package Text::Xatena::Inline;

use strict;
use warnings;
use Text::Xatena::Inline::Base -Base;
use URI::Escape;
use HTML::Entities;

sub footnotes {
    my ($self) = @_;
    $self->{footnotes} || [];
}

match qr{\[\]([\s\S]*?)\[\]}i => sub {
    my ($self, $unlink) = @_;
    $unlink;
};

match qr{(\(\(\(.*?\)\)\))}i => sub {
    my ($self, $unlink) = @_;
    $unlink;
};

match qr{\)(\(\(.*?\)\))\(}i => sub {
    my ($self, $unlink) = @_;
    $unlink;
};

match qr{\(\((.+?)\)\)}i => sub {
    my ($self, $note) = @_;
    push @{ $self->{footnotes} ||= [] }, {};

    my $number   = @{ $self->{footnotes} };
    my $title    = $note;
    $title =~ s/<[^>]+>//g;

    my $footnote = $self->{footnotes}->[-1];
    $footnote->{number} = $number;
    $footnote->{note}   = $note;
    $footnote->{title}  = $title;
    return sprintf('<a href="#fn%d" title="%s">*%d</a>',
        $number,
        $title,
        $number
    );
};

match qr{(<a[^>]+>[\s\S]*?</a>)}i => sub {
    my ($self, $anchor) = @_;
    $anchor;
};

match qr{<!--.*-->} => sub {
    my ($self) = @_;
    '<!-- -->';
};

match qr{(<[^>]+>)}i => sub {
    my ($self, $tag) = @_;
    $tag;
};

match qr<\[((?:https?|ftp)://[^\s:]+(?::\d+)?[^\s:]+)(:(?:title(?:=([^[]+))?|barcode))?\]>i => sub {
    my ($self, $uri, $opt, $title) = @_;

    if ($opt) {
        if ($opt =~ /^:barcode$/) {
            return sprintf('<img src="http://chart.apis.google.com/chart?chs=150x150&cht=qr&chl=%s" title="%s"/>',
                uri_escape($uri),
                $uri,
            );
        }
        if ($opt =~ /^:title/) {
            if (!$title && $self->{aggressive}) {
                $title = $self->cache->get($uri);
                if (not defined $title) {
                    eval {
                        $title = $self->title_of($uri);
                        $self->cache->set($uri, $title, "30 days");
                    };
                    if ($@) {
                        warn $@;
                    }
                }
            }
            return sprintf('<a href="%s">%s</a>',
                $uri,
                encode_entities(decode_entities($title || ''))
            );
        }
    } else {
        return sprintf('<a href="%s">%s</a>',
            $uri,
            $uri
        );
    }

};

match qr<\[?((?:https?|ftp):(?!([^\s<>\]]+?):(?:barcode|title))([^\s<>\]]+))\]?>i => sub {
    my ($self, $uri) = @_;
    sprintf('<a href="%s">%s</a>',
        $uri,
        $uri
    );
};

match qr<\[?mailto:([^\s\@:?]+\@[^\s\@:?]+(\?[^\s]+)?)\]?>i => sub {
    my ($self, $uri) = @_;
    sprintf('<a href="mailto:%s">%s</a>',
        $uri,
        $uri
    );
};

match qr<\[tex:([^\]]+)\]>i => sub {
    my ($self, $tex) = @_;

    return sprintf('<img src="http://chart.apis.google.com/chart?cht=tx&chl=%s" alt="%s"/>',
        uri_escape($tex),
        encode_entities($tex)
    );
};

1;
__END__



