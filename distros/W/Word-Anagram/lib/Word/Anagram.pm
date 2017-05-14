package Word::Anagram;

use 5.012000;
use strict;
use warnings;
use open IN => ":encoding(utf8)", OUT => ":utf8";

our $VERSION = '0.01';
my @anagram = ();

sub new {
	my $class = shift;
	my $self->{'word'} = shift || '';
	return bless $self, $class;
}

sub select_anagrams {
	my $self = shift;
	my @langs = @{ shift() };
	
	my @out = ();
	my %langs = ();
	@langs{0..$#langs} = @langs;
	
	for my $i (0..$#langs) {
		for my $j (0..$#langs) {
			next if $i == $j;
			my $is = $self->are_anagrams($langs{$i}, $langs{$j});
			if ($is) {
				push @out, $langs{$i};
				last;
			}
		}
	}
	return \@out;
}

sub are_anagrams {
	my $self = shift;
	my ($in1, $in2) = @_;
	
	return 0 if length($in1) != length($in2); 
	
	# compared as UTF-8 and case-insensitive
	$in1 = pack('U*', sort unpack('U*', uc $in1));
	$in2 = pack('U*', sort unpack('U*', uc $in2));
	
	return $in1 eq $in2 ? 1 : 0;
	
}

sub get_anagrams_of {
	my $self = shift;
	my $word = shift;
	@anagram = ();
	anagrams('',split('',$word));
	my %anagram;
	@anagram{@anagram} = @anagram;
	@anagram = sort keys %anagram;
	return \@anagram;
}

sub find_word_in {
	my $self = shift;
	my $word = shift;
	my @langs = @{ shift() };
	
	my @out = ();
	my %langs = ();
	@langs{0..$#langs} = @langs;
	
	for my $i (0..$#langs) {
		my $is = $self->are_anagrams($word, $langs{$i});
		push @out, $langs{$i} if $is;
	}
	return \@out;
	
}

# Private sub
sub anagrams {
	my ($p,@s) = @_;
	if (@s) {
		my $r = @s;
		while ($r--) {
			my $c = shift @s;
			anagrams($p.$c,@s);
			push @s,$c
		}
	} else {
		push @anagram, $p;
	}
}


1;

__END__

=pod

=head1 NAME

Word::Anagram - Perl extension for find anagrams of a word

=head1 SYNOPSIS

  use Word::Anagram;
  my $obj = Word::Anagram->new;

=head1 DESCRIPTION

A class to search anagrams of a word in different contexts.
E.g. find the anagrams of a word inside a list of words (dictionary).
Or find if two words are anagrams. Or, to filter all anagrams inside
a list of words that are anagrams of each other. 

Be aware that inside is used a recursive sub and this require a lot of
memory during the increase of the word's lenght, while are find all 
anagrams of a given word. 

All search are case-insensitive.
	
=head1 METHODS

=over

=item are_anagram()

	# check if two words, $word1 $word2, are anagram
	my $obj = Word::Anagram->new;
	my ($word1, $word2) = qw( donna danno );
	my $bool = $obj->are_anagrams($word1, $word2); # return true/false
	
=item select_anagrams()

	# select all words inside @words that are anagrams
	my $obj = Word::Anagram->new;
	my @words = qw(Donna  Danno Pluto Toplu Paperino Minni);
	my $anag = $obj->select_anagrams(\@words); # return an array ref
	
=item get_anagrams_of()

	# find all anagrams of $word
	my $obj = Word::Anagram->new;
	my $word = 'ABC';
	my $anag = $obj->get_anagrams_of($word); # return an array ref

=item find_word_in()

	# find all anagrams of $word inside @words
	my $obj = Word::Anagram->new;
	my $word = 'nonda';
	my @words = qw(donna  danno pluto toplu paperino minni des nodan );
	my $anag = $obj->find_word_in($word, \@words); # return an array ref

=back
	
=head1 AUTHOR

Leo Manfredi, <manfredi@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Leo Manfredi

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
