package Text::TFIDF::Ngram;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Compute the TF-IDF measure for ngram phrases

our $VERSION = '0.0502';

use Moo;
use strictures 2;
use namespace::clean;

use Carp;
use Lingua::EN::Ngram;
use Lingua::StopWords qw( getStopWords );
use List::Util qw( sum0 );


has files => (
    is  => 'ro',
    isa => sub { croak 'Invalid files list' unless ref $_[0] eq 'ARRAY' },
);


has size => (
    is      => 'ro',
    isa     => sub { croak 'Invalid integer' unless $_[0] && $_[0] =~ /^\d+$/ && $_[0] > 0 },
    default => sub { 1 },
);


has stopwords => (
    is      => 'ro',
    isa     => sub { croak 'Invalid Boolean' unless defined $_[0] },
    default => sub { 1 },
);


has punctuation => (
    is      => 'ro',
    default => sub { qr/[-!"#$%&()*+,.\/\\:;<=>?@\[\]^_`{|}~]/ },
);


has lowercase => (
    is      => 'ro',
    default => sub { 0 },
);


has counts => (
    is       => 'ro',
    init_arg => undef,
);


has file_tfidf => (
    is       => 'ro',
    init_arg => undef,
);


sub BUILD {
    my ( $self, $args ) = @_;

    return unless $args->{files};

    $args->{size} ||= 1;

    for my $file ( @{ $args->{files} } ) {
        $self->_process_ngrams( $file, $args->{size} );
    }
}

sub _process_ngrams {
    my ( $self, $file, $size ) = @_;

    my $ngram  = Lingua::EN::Ngram->new( file => $file );
    my $phrase = $ngram->ngram($size);

    if ( $self->lowercase ) {
        $phrase = { map { lc $_ => $phrase->{$_} } keys %$phrase };
    }

    my $stop = getStopWords('en');

    my $counts;

    for my $p ( keys %$phrase ) {
        next if $self->stopwords
            && grep { $stop->{$_} } split /\s+/, $p;  # Exclude stopwords

        my $pat = $self->punctuation;
        $p =~ s/$pat//g if $pat; # Remove unwanted punctuation

        # Skip if we don't have an ngram of the requested size anymore
        my @p = grep { $_ } split /\s+/, $p;
        next unless @p == $size;

        # Skip an ngram with a lone single quote (allowed by the default punctuation)
        next if grep { $_ eq "'" } @p;

        $p = lc $p if $self->lowercase;

        $counts->{$p} = $phrase->{$p};
    }

    $self->{counts}{$file} = $counts;
}


sub tf {
    my ( $self, $file, $word ) = @_;
    return 0 unless exists $self->{counts}{$file} && exists $self->{counts}{$file}{$word};
    return $self->{counts}{$file}{$word} / sum0( values %{ $self->{counts}{$file} } );
}


sub idf {
    my ( $self, $word ) = @_;

    my $count = 0;

    for my $file ( keys %{ $self->{counts} } ) {
        $count++ if exists $self->{counts}{$file}{$word};
    }

    unless ( $count ) {
        carp "'$word' is not present in any document";
        return undef;
    }

    return - log( $count / scalar( keys %{ $self->{counts} } ) ) / log(10) + 0;
}


sub tfidf {
    my ( $self, $file, $word ) = @_;
    my $idf = $self->idf($word);
    return undef unless $idf;
    return $self->tf( $file, $word ) * $idf;
}


sub tfidf_by_file {
    my ($self) = @_;

    my %seen;

    for my $file ( keys %{ $self->{counts} } ) {
        for my $word ( keys %{ $self->{counts}{$file} } ) {
            my $tfidf = $self->tfidf( $file, $word );

            next if $seen{$word}++ || !defined $tfidf;

            $self->{file_tfidf}{$file}{$word} = $tfidf;
        }
    }

    return $self->{file_tfidf};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::TFIDF::Ngram - Compute the TF-IDF measure for ngram phrases

=head1 VERSION

version 0.0502

=head1 SYNOPSIS

  use Text::TFIDF::Ngram;
  my $obj = Text::TFIDF::Ngram->new(
    files => [qw( foo.txt bar.txt )],
    size  => 3,
  );
  my $w = $obj->tf( 'foo.txt', 'foo bar baz' );
  my $x = $obj->idf('foo bar baz');
  my $y = $obj->tfidf( 'foo.txt', 'foo bar baz' );
  printf "TF: %.3f, IDF: %.3f, TFIDF: %.3f\n", $w, $x, $y;
  my $z = $obj->tfidf_by_file;
  print Dumper $z;

=head1 DESCRIPTION

This module computes the TF-IDF ("term frequency-inverse document frequency")
measure for a corpus of text documents.

For a working example program, please see the F<eg/analyze> file in this
distribution.

=head1 ATTRIBUTES

=head2 files

ArrayRef of filenames to use in the ngram processing.

=head2 size

Integer ngram phrase size.  Default is 1.

=head2 stopwords

Boolean indicating that phrases with stopwords will be ignored.  Default is 1.

=head2 punctuation

Regular expression to be used to parse-out unwanted punctuation.  Giving the
constructor a value of C<''> or C<0> will override this and not exclude any
characters from the results.

Default: qr/[-!"#$%&()*+,.\/\\:;<=>?@\[\]^_`{|}~]/

Note that the default does not exclude the single quote.

=head2 lowercase

Boolean to render the ngrams in lowercase.  Default is 0.

=head2 counts

HashRef of the ngram counts of each processed file.  This is a computed
attribute - providing it in the constructor will be ignored.

=head2 file_tfidf

HashRef of the TF-IDF values in each processed file.  This is a computed
attribute - providing it in the constructor will be ignored.

=head1 METHODS

=head2 new

  $obj = Text::TFIDF::Ngram->new(
    files       => \@files,
    size        => $size,
    stopwords   => $stopwords,
    punctuation => $punctuation,
    lowercase   => $lowercase,
  );

Create a new C<Text::TFIDF::Ngram> object.  If the B<files> argument is passed
in, the ngrams of each file are stored in the B<counts>.

=for Pod::Coverage BUILD

=head2 tf

  $tf = $obj->tf( $file, $phrase );

Returns the frequency of the given B<phrase> in the document B<file>.  This is
not the "raw count" of the phrase, but rather the percentage of times it is
seen.

=head2 idf

  $idf = $obj->idf($phrase);

Returns the inverse document frequency of a B<phrase>.

=head2 tfidf

  $tfidf = $obj->tfidf( $file, $phrase );

Computes the TF-IDF weight for the given B<file> and B<phrase>.  If the phrase
is not in the corpus, a warning is issued and undef is returned.

=head2 tfidf_by_file()

  $tfidf = $obj->tfidf_by_file;

Construct a HashRef of all files with all phrases and their B<tfidf> values.

=head1 SEE ALSO

The F<eg/analyze> file in this distribution

L<https://en.wikipedia.org/wiki/Tf%E2%80%93idf>

L<Lingua::EN::Ngram>

L<Lingua::StopWords>

L<List::Util>

L<Moo>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
