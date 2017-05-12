package Text::Mecabist::Node;
use strict;
use warnings;
use Moo;

with 'Text::Mecabist::Iter';
with 'Text::Mecabist::Helper';

# mecab vars
has [qw/ id length rlength rcattr lcattr stat isbest alpha beta prob wcost cost /] => (
    is => 'ro'
);

# mecab var decoded
has [qw/ surface feature format /] => (
    is => 'ro',
    default => "",
);

# 品詞,品詞細分類1,品詞細分類2,品詞細分類3,活用型,活用形,原形,読み,発音 (,その他)
has [qw/ pos pos1 pos2 pos3 inflection_type inflection_form lemma reading pronunciation extra /] => (
    is => 'ro'
);

# extra (up to 5 items)
has [qw/ extra1 extra2 extra3 extra4 extra5 /] => (
    is => 'ro'
);

# copied from surface
has text => (
    is => 'rw',
    default => "",
);

sub BUILDARGS {
    my $class = shift;

    my $type = ref $_[0];
    if ($type ne 'Text::MeCab::Node') {
        return $type eq 'HASH' ? shift : { @_ };
    }
    
    my ($node, $parser) = @_;
    my %args = (
        id      => $node->id,
        length  => $node->length,
        rlength => $node->rlength,
        rcattr  => $node->rcattr,
        lcattr  => $node->lcattr,
        stat    => $node->stat,
        isbest  => $node->isbest,
        alpha   => $node->alpha,
        beta    => $node->beta,
        prob    => $node->prob,
        wcost   => $node->wcost,
        cost    => $node->cost,
        
        feature => $parser->encoding->decode($node->feature),
        format  => $parser->encoding->decode($node->format($parser->mecab)),
    );

    @args{qw/ pos pos1 pos2 pos3 inflection_type inflection_form lemma reading pronunciation extra /}
        = split(/,/, $args{feature}, 10);
    
    if ($args{extra}) {
        @args{qw/ extra1 extra2 extra3 extra4 extra5 /}
            = split(',', $args{extra});
    }

    if (defined $node->surface) {
        $args{surface} = $parser->encoding->decode($node->surface);
    }
    
    $args{text} = $args{surface} // "";

    return \%args;
}

1;
