package Text::MultiPhone;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.01';

use constant VOWELS => [qw(a e i o u)];

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

sub multiphone {
    my ($self, $word) = @_;
    $word = $self->pre_split($word);
    my @words = $self->do_split($word);
    @words = $self->process_bits(@words);
    @words = $self->do_join(@words);
    @words = $self->post_join(@words);
    return @words;
}

sub _warn {
    my ($self, @warn) = @_;
    warn (@warn);
}

sub pre_split {
    $_[0]->_warn((caller(0))[3] . " not defined in $_[0]\n");
}

# a word consist of 2 levels of arrays
# 1. level splits vowels and consonants
# 2. level splits several meanings of this vowel or consonant
# i.e. Alphabet will be [[a],[lf],[a], [b], [t] ]
sub do_split {
    my ($self, @words) = @_;
    my @results;
    my $vowels = join "", @{ $self->VOWELS() };
    foreach my $word (@words) {
	my @splitted;
	while ($word =~ m/([$vowels]*)([^$vowels]*)/g) {
	    push @splitted, [$1], [$2];
	}
	push @results, \@splitted;
    }
    return @results;
}

sub process_bits {
    $_[0]->_warn((caller(0))[3] . " not defined in $_[0]\n");
}

sub do_join {
    my ($self, @words) = @_;
    my @results = ("");
    foreach my $word (@words) {
	next unless defined $word;
	foreach my $part (@$word) {
	    next unless defined $part;
	    my @newResults;
	    foreach my $splitPart (@$part) {
		next unless defined $splitPart;
		foreach my $result (@results) {
		    push @newResults, $result . $splitPart;
		}
	    }
	    @results = @newResults;
	}
    }
    return @results;
}

sub post_join {
    $_[0]->_warn((caller(0))[3] . " not defined in $_[0]\n");
}
    

1;
__END__

=head1 NAME

Text::MultiPhone - Package to retrieve the phonetics of a word

=head1 SYNOPSIS

  use Text::MultiPhone::de;

  my $dePhone = new Text::MulitPhone::de();

  my @results = $dePhone->mulitphone("Alphabet");

=head1 DESCRIPTION

This is yet another solution to the problem of phonetic
similarities. In contrast to L<Soundex> or L<Metaphone>, vowels
matter, and it is thus more useful for other (germanic?) languages.

In languages, there are often cases where an automated phonetic
analyzer cannot detect the correct pronounciation. I.e. can the german
v be pronounced as english v (as in I<Verb>) or as english f (as in
I<verstehen>), without obvious reason. In those cases, this analyzer
returns both solutions.

This package has been written originally to support the
german-norwegian dictionary L<www.heiznelnisse.info>. It has
been used in a combination with the stem module L<Lingua::Stem::Snowball>.


=head2 EXPORT

None.


=head1 SEE ALSO

L<Soundex>, L<Text::Metaphone>, L<Text::DoublePhone>, L<Lingua::Stem::Snowball>


=head1 AUTHOR

Heiko Klein, E<lt>hklein@suse.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Heiko Klein

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
