###########################################
package Text::TermExtract;
###########################################

use strict;
use warnings;
use Lingua::StopWords;
use Text::Language::Guess;
use Log::Log4perl qw(:easy);

our $VERSION = "0.02";

###########################################
sub new {
###########################################
    my($class, %options) = @_;

    my $self = {
        languages => ['en'],
        %options,
    };

    bless $self, $class;
}

###########################################
sub exclude {
###########################################
    my($self, $aref) = @_;

    for (@$aref) {
        $self->{exclude}->{$_}++;
    }
}

###########################################
sub terms_extract {
###########################################
    my($self, $text, $opts) = @_;

    $opts = {} unless defined $opts;

    my $guesser = Text::Language::Guess->
            new(languages => $self->{languages});

    my $lang = 
        $guesser->language_guess_string($text);

    $lang = $self->{languages}->[0] unless $lang;
    DEBUG "Guessed language: $lang\n";

    my $stopwords =
      Lingua::StopWords::getStopWords($lang);

    my %words;

    while($text =~ /\b(\w+)\b/g) {
        my $word = lc($1);
        next if $stopwords->{$word};
        next if $word =~ /^\d+$/;
        next if length($word) <= 2;
        next if exists $self->{exclude}->{$word};
        $words{$word}++;
        $words{$word} += 3 if length $word > 6;
    }
    
    my @weighted_words = sort {
      $words{$b} <=> $words{$a} or
      $a cmp $b  # sort alphabetically on equal score
    } keys %words;

    if(get_logger()->is_debug()) {
        for my $word (@weighted_words) {
            DEBUG "$word scores $words{$word}";
        }
    }

    if(exists $opts->{max} and $opts->{max} < @weighted_words) {
        return @weighted_words[0..($opts->{max}-1)];
    } else {
        return @weighted_words;
    }
}

1;

__END__

=head1 NAME

Text::TermExtract - Extract terms from text

=head1 SYNOPSIS

    use Text::TermExtract;

    my $text = { Hey, hey, how's it going? Wanna go to Wendy's 
                 tonight? Wendy's has great sandwiches." };

    my $ext = Text::TermExtract->new();

    for my $word ( $ext->terms_extract( $text, { max => 3 }) ) {
        print "$word\n";
    }

    # "sandwiches"
    # "tonight"
    # "wendy"

=head1 DESCRIPTION

Text::TermExtract takes a simple approach at extracting the most interesting
terms from documents of arbitrary length.

There's more scientific methods to term extraction, like Yahoo's online 
term extraction API (but you can't have it locally) and the Lingua::YaTeA 
module on CPAN (which is so poorly documented that I couldn't figure out
how to use it). 

So I wrote Text::TermExtract, which first tries to
guess the language a text is written in, kicks out the language-
specific stopwords, weighs the rest with a hand-crafted formula and
returns a list of (hopefully) interesting words.

This is a very crude approach to term extraction, if you have a better
method and want to include it in Text::TermExtract, drop me an email,
I'm interested.

=head2 METHODS

=over 4

=item new()

Constructor.

=item terms_extract( $text, $opts )

Goes through the text stringin $text, extracts the keywords and returns
them as a list.

To limit the number of words returned, use the C<max> option:

    $extr->terms_extract( $text, { max => 10 } );

=item exclude( $array_ref )

Add a list of words to exclude. The words listed in the array passed
in as a reference will never be used as keywords.

    $extr->exclude( ['moe', 'joe'] );

=back

=head1 LEGALESE

Copyright 2008 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2008, Mike Schilli <cpan@perlmeister.com>
