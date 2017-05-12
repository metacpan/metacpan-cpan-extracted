use strict;
use warnings;

package Text::WordCounter;

use namespace::autoclean;
use Moose;

use Lingua::ZH::MMSEG;
use Unicode::UCD qw(charinfo);
use URI::Find;
use Lingua::Stem;

has stemming => (is => 'rw', isa => 'Int', default => 0);
has stopwords => (is => 'ro', isa => 'HashRef', default => sub { {} });

sub is_stop_word { 
    my( $self, $word, $script ) = @_;
    return 0 if( $script eq 'Han' );
    return 1 if exists $self->stopwords->{lc $word};
    return length($word) <= 3;
}

sub normalize {
    my ($self, $word) = @_;

    if ($self->stemming) {
        my $stemmed = Lingua::Stem::stem($word)->[0];
        if ($stemmed ne '') {
            return $stemmed;
        }
    }
    return lc $word
}

my %char_cache = ();
sub split_scripts {
    my ( $self, $text ) = @_;
    my @parts;
    while ( $text =~ /(\X)/g ) {
        my $part = $1;
        my $pos = pos( $text );
        my $ord = ord $part;

        unless ($char_cache{$ord}) {
            if (scalar(keys(%char_cache)) > 5000) {
                # XXX: Some LRU cache would be more appropriate, but this cleaning
                # will probably happen very rarely or never, so there's (hopefully) no
                # need to bother about it too much
                undef %char_cache;
            }

            $char_cache{$ord} = charinfo($ord);
        }
        my $charinfo = $char_cache{$ord};

        if( ! defined $charinfo ){
            warn "$1 does not look like good UTF8 - no charinfo";
            next;
        }
        my $script = $charinfo->{script};
        if( ! defined $script ){
            warn "$1 does not look like good UTF8 - no script";
            next;
        }
        next if $script eq 'Common';
        $text=~ /((\p{$script}|[-0-9:])*)/g;
        $part .= $1;
        push @parts, { text => $part, script => $script };
    }
    # warn join ' | ', map { $_->{text} } @parts;
    return @parts;
}

sub word_count {
    my ( $self, $text, $features ) = @_;
    $features ||= {};
    for my $part ( $self->split_scripts( $text ) ){
        my @words = ( $part->{text} );
        if( $part->{script} eq 'Han' ){
            @words = mmseg( $part->{text} );
        }
        for my $word ( @words ){
            next if $self->is_stop_word( $word, $part->{script} );
            $features->{ $self->normalize( $word ) }++;
        }
    }
    return $features;
}


__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: counting words in multilingual texts

=head1 SYNOPSIS

my $counter = Text::WordCounter->new();

my $word_count = $counter->word_count( $text )

=head1 DESCRIPTION

It is quite heuristic, for example '-' and digits inside word characters
are treated as a word character, see the tests to find out how all the special
cases are resolved,

The features parameter should be a hashref and is an accumulator for found
features.

=head1 ATTRIBUTES

=head2 stemming

If set stemming via Lingua::Stem is performed on the words.
We never managed to make it sanely in multilingual texts.

=head2 stopwords

A hashref with words to discard.

=head1 INSTANCE METHODS

=head2 C<is_stop_word>

=head2 C<normalize>

Lowercases words and stemms them if the C<stemming> attribute is true.

=head2 C<split_scripts>

=head2 C<word_count>

Returns a hashref with word counts.

=head1 LIMITATIONS

From languages that don't use spaces only Chinese is currently supported 
(using Lingua::ZH::MMSEG).

=head1 SEE ALSO


__END__


