package Text::Mecabist::Helper;
use strict;
use warnings;
use utf8;
use Moo::Role;

sub readable {
    my $node = shift;

    return 0 if not defined $node->stat;
    return 0 if $node->stat == Text::MeCab::MECAB_BOS_NODE;
    return 0 if $node->stat == Text::MeCab::MECAB_EOS_NODE;
    
    return 1;
}

sub is {
    my ($node, $type) = @_;
    for ($node->pos, $node->pos1, $node->inflection_type, $node->inflection_form) {
        return 1 if $_ && $_ eq $type;
    }
    
    return 0;
}

1;
