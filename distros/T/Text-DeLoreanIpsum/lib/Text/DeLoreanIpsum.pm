package Text::DeLoreanIpsum;

use 5.018002;
use strict;
use warnings;
use List::MoreUtils qw(uniq);
use Text::DeLoreanIpsumData qw/ getData /;

use vars qw($VERSION);

our $VERSION = '0.03';

my $deLoreanIpsum;

sub new {
  my $class = shift;
  $deLoreanIpsum ||= bless {}, $class;
  return $deLoreanIpsum;
}

sub generate_characterlist {
    my $self = shift;
    my $all = shift;
    my $getData = getData();

    return $all
        ? [ map { keys %$_ } @$getData ]
        : [ uniq sort map { keys %$_ } @$getData ];
}

sub characterlist {
    my $self = shift;
    my $all = shift;

    $self->{ characterlist } ||= $self->generate_characterlist($all);
}

sub charactercount {
    my $self = shift;
    return scalar(@{$self->{ characterlist }});
}

sub get_character {
    my $self = shift;
    return $self->characterlist->[ int( rand( $self->charactercount ) ) ];
}

sub characters {
    my $self = shift;
    my $all = shift || 0;

    my @characters;
    return join(' / ', @{$self->characterlist($all)});
}

sub generate_wordlist {
    my $self = shift;
    my $character = shift;
    my $getData = getData();

    my @words;
    foreach my $line (@$getData) {
        next unless $line->{$character};
        push @words, map { s/\W//; lc($_) } map { split /\s/, $_ } values %$line;
    }
    return \@words;
}

sub wordlist {
    my $self = shift;
    my $character = shift;
    $self->{ wordlist }->{ $character } ||= $self->generate_wordlist( $character );
}

sub wordcount {
    my $self = shift;
    my $character = shift;
    return scalar(@{$self->{ wordlist }->{ $character }});
}

sub get_word {
    my $self = shift;
    my $character = shift;
    return $self->wordlist($character)->[ int( rand( $self->wordcount($character) ) ) ];
}

sub words {
    my $self = shift;
    my $num  = shift || 1;
    my $character = shift || $self->get_character();

    return join ' ', map { $self->get_word($character) }
                       (0..$num-1);
}

sub get_sentence {
    my $self = shift;
    my $character = shift || $self->get_character();

    my $words = $self->words( 4 + int( rand( 6 ) ), $character);

    return sprintf '%s: %s', $character, ucfirst( $words );
}

sub sentences {
    my $self = shift;
    my $num = shift || 1;
    my $character = shift;

    my @sentences = map { $self->get_sentence($character) }
                      0..$num-1;

    return join( '. ', @sentences ) . '.';
}

sub get_paragraph {
    my $self = shift;
    my $character = shift;
    return $self->sentences(3 + int( rand( 4 ) ), $character );
}

sub paragraphs {
    my $self = shift;
    my $num = shift || 1;
    my $character = shift;
    my @paragraphs;
    push @paragraphs, $self->get_paragraph($character) for (1..$num);
    return join "\n\n", @paragraphs;
}

1;
__END__

=head1 NAME

Text::DeLoreanIpsum - Generate random Back to the Future looking text

=head1 SYNOPSIS

    use Text::DeLoreanIpsum;

    my $text = Text::DeLoreanIpsum->new();

    # Generate a string of list of BTTF characters
    $characters = $text->characters();
  
    # Generate a string of text with 5 words
    $words = $text->words(5);
  
    # Generate a string of text with 2 sentences
    $sentences = $text->sentences(2);
  
    # Generate 3 paragraphs
    $paragraphs = $text->paragraphs(3);

=head1 DESCRIPTION

Often when developing a website or other application, it's important to have placeholders for content. This module generates prescribed amounts of fake Back to the Future text

=head1 CONSTRUCTOR

=over 4

=item C<new()>

The default constructor, C<new()> takes no arguments and returns a Text::DeLoreanIpsum object.

=back

=head1 METHODS

=over 4

=item C<words( INTEGER )>

Returns INTEGER words from fake BTTF text.

=item C<sentences( INTEGER )>

Returns INTEGER sentences from fake BTTF text.

=item C<paragraphs( INTEGER )>

Returns INTEGER paragraphs from fake BTTF text.

=back

=head1 AUTHOR

Mariano Spadaccini (MARIANOS)

=head1 SEE ALSO

    L<Text::Lorem> and L<http://deloreanipsum.com/>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016, 2023 by Mariano Spadaccini
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
