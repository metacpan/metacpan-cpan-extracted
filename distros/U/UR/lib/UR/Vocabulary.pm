
package UR::Vocabulary;

use strict;
use warnings;
use Lingua::EN::Inflect ("PL_V","PL");

require UR;
our $VERSION = "0.47"; # UR $VERSION;

UR::Object::Type->define(
    class_name => 'UR::Vocabulary',
    is => ['UR::Singleton'],
    doc => 'A word in the vocabulary of a given namespace.',
);

sub get_words_with_special_case {
    shift->_singleton_class_name->_words_with_special_case;
}

sub _words_with_special_case {
    return ('UR');
}

sub convert_to_title_case {
    my $conversion_hashref = shift->_words_with_special_case_hashref;    
    my @results;
    for my $word_in(@_) {
        my $word = lc($word_in);
        if (my $uc = $conversion_hashref->{$word}) {
            push @results, $uc;
        }
        else {
            push @results, ucfirst($word);
        }
    }
    return $results[0] if @results == 1 and !wantarray;
    return @results;
}

sub convert_to_special_case {
    my $conversion_hashref = shift->_words_with_special_case_hashref;    
    my @results;
    for my $word_in(@_) {
        my $word = lc($word_in);
        if (my $sc = $conversion_hashref->{$word}) {
            push @results, $sc;
        }
        else {
            push @results, $word_in;
        }
    }
    return $results[0] if @results == 1 and !wantarray;
    return @results;
}


sub _words_with_special_case_hashref {
    my $self = shift->_singleton_object;
    my $hashref = $self->{_words_with_special_case_hashref};
    return $hashref if $hashref;
    $hashref = { map { lc($_) => $_ } $self->get_words_with_special_case };
    $self->{_words_with_special_case_hashref} = $hashref;
    return $hashref;
}

sub singular_to_plural {
    my $self = shift;
    return map { PL($_) } @_;
}

our %exceptions =
(
    statuses => 'status',
    is => 'is',
    has => 'has',
    cds => 'cds',
);

sub plural_to_singular {
    my $self = shift;
    my ($lc,$override);
    return map { 
        $lc = lc($_); 
        $override = $exceptions{$lc}; 
        ( $override ? $override : PL_V($_) )
    } @_;
}





1;
