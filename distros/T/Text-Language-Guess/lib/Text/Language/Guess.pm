###########################################
# Text::Language::Guess 
# 2005, Mike Schilli <cpan@perlmeister.com>
###########################################

###########################################
package Text::Language::Guess;
###########################################

use strict;
use warnings;
use vars qw(%STOPMAPS $VERSION);

use Log::Log4perl qw(:easy);
use Text::ExtractWords;
use Lingua::StopWords;
use File::Spec;
use File::Basename;

%STOPMAPS = ();
$VERSION  = "0.02";

###########################################
sub new {
###########################################
    my($class, @options) = @_;

    my $self = {
        languages => languages(),
        @options,
    };

    bless $self, $class;

        # To avoid re-initializing the stopmap (which is fairly expensive)
        # on every new(), hold all stopmaps for pre-computed language
        # combinations in a class variable.
    if(exists $STOPMAPS{"@{$self->{languages}}"}) {
        $self->{stopmap} = $STOPMAPS{"@{$self->{languages}}"};
    } else {
        $self->{stopmap} = $self->stopwords();
        $STOPMAPS{"@{$self->{languages}}"} = $self->{stopmap};
    }

    return $self;
}

###########################################
sub scores {
###########################################
    my($self, $file) = @_;

    return $self->scores_string(slurp($file));
}

###########################################
sub scores_string {
###########################################
    my($self, $data) = @_;

    my @words = ();
    my %scores = ();

    LOGDIE "Cannot score empty/undefined document" if
        !defined $data or !length $data;

    words_list(\@words, $data, {});
    
    for my $word (@words) {
        my $langs = $self->{stopmap}->{$word};
    
        if(! defined $langs) {
            DEBUG "$word doesn't match any language";
            next;
        }
    
        for my $lang (@$langs) {
            DEBUG "Scoring for $lang";
            $scores{$lang}++;
        }
    }

    return \%scores;
}
    
###########################################
sub language_guess {
###########################################
    my($self, $file) = @_;
    
    return $self->language_guess_string(slurp($file));
}

###########################################
sub language_guess_string {
###########################################
    my($self, $data) = @_;

    my $scores = $self->scores_string($data);

    my $best_lang;
    my $max_score;
    
    for my $lang (keys %$scores) {
        if(!defined $max_score or
            $max_score < $scores->{$lang}) {
            $best_lang = $lang;
            $max_score = $scores->{$lang};
        }
    }
    
    return $best_lang;
}

###########################################
sub stopwords {
###########################################
    my($self) = @_;

    # Fetch all stopword lists from all supported languages

    my $stopmap = {};

    for my $lang (@{$self->{languages}}) {
        
        DEBUG "Loading language $lang";

        my $stopwords = Lingua::StopWords::getStopWords($lang);

        for my $stopword (keys %$stopwords) {
            DEBUG "Pushing $stopword => $lang";
            push @{$stopmap->{$stopword}}, $lang;
        }
    }

    return $stopmap;
}
    
###########################################
sub languages {
###########################################

    # Check which languages are supported by Lingua::StopWords

    for my $dir (@INC) {
        if(-f File::Spec->catfile($dir, "Lingua/StopWords.pm")) {
            return [map { s/\.pm$//; lc basename($_); } 
                        <$dir/Lingua/StopWords/*.pm>];
        }
    }
}

###########################################
sub slurp {
###########################################
    my($file) = @_;

    LOGDIE "$file not a file" unless -f $file;

    local $/ = undef;

    my $data;

    open FILE, "<$file" or LOGDIE "Cannot open $file ($!)";
    $data = <FILE>;
    close FILE;
    return $data;
}

1;

__END__

=head1 NAME

Text::Language::Guess - Trained module to guess a document's language

=head1 SYNOPSIS

    use Text::Language::Guess;

    my $guesser = Text::Language::Guess->new();
    my $lang = $guesser->language_guess("bill.txt");

        # prints 'en'
    print "Best fit: $lang\n";

=head1 DESCRIPTION

Text::Language::Guess guesses a document's language. Its implementation
is simple: Using C<Text::ExtractWords> and C<Lingua::StopWords> from 
CPAN, it determines how many of the known stopwords the document 
contains for each language supported by C<Lingua::StopWords>.

Each word in the document recognized as stopword
of a particular language scores one point for this language.

The C<language_guess()> function takes a document as a parameter
and returns the abbreviation of the language that it is most likely
written in.

Supported Languages:

=over 4

=item *

English (en)

=item *

French (fr)

=item *

Spanish (es)

=item *

Portugese (pt)

=item *

Italian (it)

=item *

German (de)

=item *

Dutch (nl)

=item *

Swedish (sv)

=item *

Norwegian (no)

=item *

Danish (da) 

=back

=head2 Methods

=over 4

=item C<new()>

Initializes the guesser with all stopwords available for
all supported languges.
If C<new> has been called before, subsequent
calls will return the same precomputed stoplist map,
avoiding collecting all stopwords again (as long as the
number of languages stays the same, see next
paragraph).

You can limit the number of searched languages by specifying
the C<language> parameter and passing it an array ref of wanted
languages:

        # Only guess between English and German
    $guesser = Text::Language::Guess->new(languages => ['en', 'de']);

=item C<language_guess($textfile)>

Reads in a text file, extracts all words, scores them 
using the stopword maps and returns a single two-letter
string indicating the language the document is most likely
written in.

=item C<language_guess_string($string)>

Just like C<language_guess>, but takes a string instead of a file name.

=item C<scores($textfile)>

Like C<language_guess($textfile)>, just returning
a ref to a hash mapping language strings (e.g. 'en')
to a score number. The entry with the highest score
is the most likely one.

=item C<scores_string($string)>

Like C<scores>, but takes a string instead of a file name.

=back

=head1 EXAMPLES

    use Text::Language::Guess;

        # Guess language in a string instead of a file
    my $guesser = Text::Language::Guess->new();
    my $lang = $guesser->language_guess_string("Make love not war");
        # 'en'


        # Limit number of languages to choose from
    my $guesser = Text::Language::Guess->new(languages => ['da', 'nl']);
    my $lang = $guesser->language_guess_string(
                   "Which is closer to English, danish or dutch?");
        # 'nl'


        # Show different scores
    my $guesser = Text::Language::Guess->new();
    my $scores = $guesser->scores_string(
        "This text is English, but other languages are scoring as well");
    use Data::Dumper;
    print Dumper($scores);

        # $VAR1 = {
        #   'pt' => 1,
        #   'en' => 6,
        #   'fr' => 1,
        #   'nl' => 1
        # };

=head1 LEGALESE

Copyright 2005 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2005, Mike Schilli <cpan@perlmeister.com>
