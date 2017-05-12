package Text::Info::BASE;
use Moose;
use namespace::autoclean;

with 'Text::Info::Utils';

use Module::Load;
use Unicode::Normalize;

has 'text' => (
    isa      => 'Str',
    is       => 'rw',
    default  => '',
);

has 'tld' => (
    isa     => 'Maybe[Str]',
    is      => 'rw',
    default => '',
);

has 'language' => (
    isa     => 'Str',
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;

        my @lang = $self->CLD->identify( $self->text, tld => $self->tld );
        my $lang = $lang[1];

        if ( $lang eq 'nb' || $lang eq 'nn' ) {
            $lang = 'no';
        }

        return $lang;
    },
);

around 'BUILDARGS' => sub {
    my $orig = shift;
    my $self = shift;

    if ( @_ == 1 && !ref $_[0] ) {
        return $self->$orig( text => $_[0] );
    }
    else {
        return $self->$orig( @_ );
    }
};

has 'sentences' => ( isa => 'ArrayRef[Text::Info::Sentence]', is => 'ro', lazy_build => 1 );

sub _build_sentences {
    my $self = shift;

    my $marker     = '</marker/>';
    my $text       = $self->text;
    my $separators = '.?!:;';

    # Mark separators with a marker.
    $text =~ s/([\Q$separators\E]+\s*)/$1$marker/sg;

    # Markers immediately prefixed by a lowercase + uppercased characters, and again followed
    # by a marker, a space and "normal" stuff should be removed.
    # Expample: If you want cake, open door A. </marker/>If you want a car, open door C.</marker/>
    # die $text;
    # $text =~ s/([[:lower:]]\s+[[:upper:]]\.\s+)<\/marker\/>([[:upper:]].*?)\Q$marker\E/$1$2/sg;

    # Abbreviations.
    foreach ( qw( Prof Ph Dr Mr Mrs Ms Hr St ) ) {
        $text =~ s/($_\.\s+)\Q$marker\E/$1/sg;
    }

    # U.N., U.S.A.
    $text =~ s/([[:upper:]]{1}\.)\Q$marker\E/$1/sg;

    # Clockwork.
    $text =~ s/(kl\.\s+)\Q$marker\E(\d+.)(\d+.)\Q$marker\E(\d+)/$1$2$3$4/sg;
    $text =~ s/(kl\.\s+)\Q$marker\E(\d+.)\Q$marker\E(\d+)/$1$2$3/sg;
    $text =~ s/(\d+.)\Q$marker\E(\d+)/$1$2/sg;
    $text =~ s/(\d+.)\Q$marker\E(\d+.)\Q$marker\E(\d+)/$1$2$3/sg;
    $text =~ s/(\d+\s+[ap]\.)\Q$marker\E(m\.\s*)\Q$marker\E/$1$2/sg;
    $text =~ s/(\d+\s+[ap]m\.\s+)\Q$marker\E/$1/sg;

    # Remove marker if it looks like we're dealing with a date abbrev., like "Nov. 29" etc.
    my @months = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );

    foreach my $month ( @months ) {
        $text =~ s/($month\.\s+)\Q$marker\E(\d+)/$1$2/sg;
    }

    # Markers immediately followed by a (possible space and) lowercased character should be removed.
    # This is useful for TLDs/domain names like "cnn.com".
    $text =~ s/\Q$marker\E\s*([[:lower:]])/$1/sg;

    # Markers immediately prefixed by a space + single uppercased characters should be removed.
    # This is fine for f.ex. names like "Tore O. Aursand".
    $text =~ s/(\s+[[:upper:]]\.\s+)\Q$marker\E/$1/sg;

    # Build sentences.
    my @sentences = ();

    foreach my $sentence ( split(/\Q$marker\E/, $text) ) {
        1 while ( $sentence =~ s/[\Q$separators\E\s]$// );

        $sentence =  $self->squish( $sentence );
        $sentence =~ s/^\-+\s*//sg;

        if ( length $sentence ) {
            push( @sentences, Text::Info::Sentence->new(text => $sentence, tld => $self->tld) );
        }
    }

    # Return
    return \@sentences;
}

has 'sentence_count' => ( isa => 'Int', is => 'ro', lazy_build => 1 );

sub _build_sentence_count {
    my $self = shift;

    return scalar( @{$self->sentences} );
}

has 'avg_sentence_length' => ( isa => 'Num', is => 'ro', lazy_build => 1 );

sub _build_avg_sentence_length {
    my $self = shift;

    my $total_length = 0;

    foreach my $sentence ( @{$self->sentences} ) {
        $total_length += length( $sentence->text );
    }

    return $total_length / $self->sentence_count;
}

has 'words' => ( isa => 'ArrayRef[Str]', is => 'ro', lazy_build => 1 );

sub _build_words {
    my $self = shift;

    return $self->text2words( $self->text );
}

=item word_count

=cut

has 'word_count' => ( isa => 'Int', is => 'ro', lazy_build => 1 );

sub _build_word_count {
    my $self = shift;

    return scalar( @{$self->words} );
}

=item avg_word_length()

Returns the average length of the words in the text.

=cut

has 'avg_word_length' => ( isa => 'Num', is => 'ro', lazy_build => 1 );

sub _build_avg_word_length {
    my $self = shift;

    my $total_length = 0;

    foreach my $word ( @{$self->words} ) {
        $total_length += length( $word );
    }

    return $total_length / $self->word_count;
}

=item syllable_count

=cut

has 'syllable_count' => ( isa => 'Int', is => 'ro', lazy_build => 1 );

sub _build_syllable_count {
    my $self = shift;

    my $class_name = 'Lingua::' . uc( $self->language ) . '::Syllable';
    autoload $class_name;

    my $count = 0;

    foreach my $word ( @{$self->words} ) {
        $count += syllable( Unicode::Normalize::NFD($word) );
    }

    return $count;
}

=item ngrams( $size )

=cut

sub ngrams {
    my $self = shift;
    my $size = shift || 2;

    my @ngrams = ();
    my @words  = @{ $self->words };

    for ( my $word_idx = 0; $word_idx < @words; $word_idx++ ) {
        my @w = @words[ $word_idx .. $word_idx + ($size - 1) ];
        if ( defined $w[-1] ) {
            push( @ngrams, join(' ', @w) );
        }
    }

    return \@ngrams;
}

=item unigrams

=cut

has 'unigrams' => ( isa => 'ArrayRef[Str]', is => 'ro', lazy_build => 1 );

sub _build_unigrams {
    my $self = shift;

    return $self->ngrams( 1 );
}

=item bigrams

=cut

has 'bigrams' => ( isa => 'ArrayRef[Str]', is => 'ro', lazy_build => 1 );

sub _build_bigrams {
    my $self = shift;

    return $self->ngrams( 2 );
}

=item trigrams

=cut

has 'trigrams' => ( isa => 'ArrayRef[Str]', is => 'ro', lazy_build => 1 );

sub _build_trigrams {
    my $self = shift;

    return $self->ngrams( 3 );
}

=item quadgrams

=cut

has 'quadgrams' => ( isa => 'ArrayRef[Str]', is => 'ro', lazy_build => 1 );

sub _build_quadgrams {
    my $self = shift;

    return $self->ngrams( 4 );
}

__PACKAGE__->meta->make_immutable;

1;
