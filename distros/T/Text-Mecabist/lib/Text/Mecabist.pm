package Text::Mecabist;
use 5.010001;
use strict;
use warnings;
our $VERSION = "0.02";

use Moo;
use Encode;
use Text::MeCab;
use Text::Mecabist::Document;
use Text::Mecabist::Node;

has mecab => (is => 'rw');

my $encoding;
sub encoding {
    $encoding ||= Encode::find_encoding(Text::MeCab::ENCODING);
}

sub BUILD {
    my ($self, $args) = @_; 
    my $mecab = delete $args->{mecab} || Text::MeCab->new($args);
    $self->mecab($mecab);
}

sub parse {
    my ($self, $text, $cb) = @_;
    my $doc = Text::Mecabist::Document->new;
    
    $text = $self->encoding->encode($text // "");
    
    for my $part (split /(\s+)/, $text) {
        if ($part =~ /^\s+$/) {
            my $node = Text::Mecabist::Node->new({
                text => $part,
            });
            
            $doc->add($node);
            next;
        }
        
        foreach (
            my $node = $self->mecab->parse($part);
            $node;
            $node = $node->next()
        ) {
            my $node = Text::Mecabist::Node->new($node, $self);
            $doc->add($node);
        }
    }

    if ($cb) {
        $doc->each($cb);
    }
    
    $doc;
}

1;
__END__

=encoding utf-8

=head1 NAME

Text::Mecabist - Text::MeCab companion for Acmeist

=head1 SYNOPSIS

    use utf8;
    use Text::Mecabist;

    my $parser = Text::Mecabist->new();

    print $parser->parse('庭に鶏', sub {
        my $node = shift;
        $node->text($node->reading .'!') if $node->readable;
    });

    # ニワ!ニ!ニワトリ!

=head1 DESCRIPTION

Text::Mecabist is a sub project from my Japanese transforming Acme toys. 

Although it is overhead exists than using L<Text::MeCab> directly,
but helpful especially around to encode/decode with mecab encoding.

=head1 METHODS

=head2 Text::Mecabist->new()

    my $parser = Text::Mecabist->new();

Craete parser object. Arguments can take are optional and same as L<Text::MeCab>->new().

    my $parser = Text::Mecabist->new({
        node_format => '%m,%H',
        unk_format  => '%m,%H',
        bos_format  => '%m,%H',
        eos_format  => '%m,%H',
        userdic     => 'user.dic',
    });

=head2 Text::Mecabist->encoding()

    print Text::Mecabist->encoding->name; # => "utf8" or something

This class method returns L<Encode>::Encoding object.

=head2 $parser->parse($text [, $cb ])

Parses text by mecab, returns Text::Mecabist::Document object
that contains HUGE list of Text::Mecabist::Node objects.

$parser encodes $text by mecab encoding automatically.

Optional $cb is called for all of those nodes.

    $doc = $parser->parse('...', sub {
        my $node = shift; # => is a Text::Mecabist::Node
    });

=head2 Text::Mecabist::Document

=head3 $doc->stringify()

Shortcut to $doc->join('text'). Document object is L<overload>ing as a string.

    print $doc; # boon

=head3 $doc->nodes()

Accessor. Arrayref of Text::Mecabist::Node-s.

=head3 $doc->join($field)

    $doc = $parser->parse('庭の鶏')
    $text = $doc->join('reading'); # => "ニワノニワトリ"

Return combined text by specific field. Same as

    my $res = "";
    for my $node (@{ $doc->nodes }) {
        $res .= $node->$field;
    }

=head2 Text::Mecabist::Node

=head3 from Text::MeCab::Node

    $node->id;
    $node->length;
    $node->rlength;
    $node->rcattr;
    $node->lcattr;
    $node->stat;
    $node->isbest;
    $node->alpha;
    $node->beta;
    $node->prob;
    $node->wcost;
    $node->cost;
    $node->surface; # decoded
    $node->feature; # decoded
    $node->format;  # decoded

=head3 divided feature

    $node->pos;  # 品詞
    $node->pos1; # 品詞細分類1
    $node->pos2; # 品詞細分類2
    $node->pos3; # 品詞細分類3
    $node->inflection_type; # 活用型
    $node->inflection_form; # 活用形
    $node->lemma;   # 原形
    $node->reading; # 読み
    $node->pronunciation; # 発音
    $node->extra1;
    $node->extra2;
    $node->extra3;
    $node->extra4;
    $node->extra5;
    $node->extra; # all of extra, with comma

=head3 traversal nodes 

    $node->has_next; # 1 or 0
    $node->next; # next Text::MeCab::Node or undef
    $node->has_prev; # 1 or 0
    $node->prev; # prev Text::MeCab::Node or undef

=head3 helper

    $node->readable; # 1 or 0
    $node->is('名詞'); # 1 or 0
    $node->text; # copy of $node->surface but RW.
    $node->skip(0); # skip in join() if set 1
    $node->last(0); # last in join() if set 1

=head1 AUTHOR

Naoki Tomita E<lt>tomita@cpan.orgE<gt>

=head1 LICENSE

Copyright (C) Naoki Tomita.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=for stopwords mecab ing acmeist

=cut
