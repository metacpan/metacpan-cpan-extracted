package Text::MultiPhone::de;

use 5.006;
use strict;
use warnings;

use POSIX qw(setlocale LC_COLLATE LC_CTYPE);

use base qw(Text::MultiPhone);

use constant VOWELS => [qw(a e i o u y ä ü ö)];

our $VERSION = do { my @r = (q$Revision: 1.1.1.1 $ =~ /\d+/g); sprintf " %d." . "%02d" x $#r, @r };


sub pre_split {
    my ($self, $word) = @_;
    my $orgLocale = setlocale(LC_CTYPE);
    setlocale(LC_CTYPE, 'de_DE');
    use locale;

    $word = lc($word);
    $word =~ s/ß/s/;
    $word =~ s/qu/q/g; # q is always alone
    $word =~ s/sch/ch/g; # ch == sch
    $word =~ s/sc[^h]/ch/g; # usual typo for sch
    $word =~ s/sh/ch/g; # usual typo for sch
    $word =~ s/ck/k/g;
    $word =~ s/ie/i/g;
    $word =~ s/ph/f/g;
    $word =~ s/pf/f/g;
    $word =~ s/(\w)\1/$1/g; # removing double characters
    $word =~ s/(\w{2})\1/$1/g; # removing double pairs as stst in "selbstständig"

    no locale;
    setlocale(LC_CTYPE, $orgLocale);
    return $word
}

sub process_bits {
    my ($self, @words) = @_;

    my @results;
    foreach my $word (@words) {
	next unless defined $word;
	my $partNo = 0;
	foreach my $part (@$word) {
	    next unless defined $part;
	    $partNo++;
	    my $sequence = ${ $part }[0];
	    next unless $sequence;
	    my @splits;
	
	    if ($sequence =~ /v/) {
		# v sounds like v or f
		(my $subst = $sequence) =~ s/v/f/;
		push @splits, $subst;
		($subst = $sequence) =~ s/v/w/;
		push @splits, $subst;
	    } elsif ($sequence =~ /y/) {
		# y sounds like ü (= u,i), i, j
		(my $subst = $sequence) =~ s/y/i/;
		push @splits, $subst;
		($subst = $sequence)  =~ s/y/j/;
		push @splits, $subst;
		($subst = $sequence)  =~ s/y/u/;
		push @splits, $subst;
	    } elsif ($sequence eq 'ü' or $sequence eq 'ue') {
		# ü sounds like u,i
		push @splits, 'u';
		push @splits, 'i';
	    } elsif ($sequence eq 'ä' or $sequence eq 'ae') {
		# ä sounds like a,e
		push @splits, 'a';
		push @splits, 'e';
	    } elsif ($sequence eq 'ö' or $sequence eq 'oe') {
		# ö sounds like o,e
		push @splits, 'o';
		push @splits, 'e';
	    } elsif ($sequence eq 'ai') {
		push @splits, 'ei';
	    } elsif ($sequence eq 'oi') {
		push @splits, 'eu';
	    } elsif ($sequence eq 'c') {
		push @splits, 'z';
	    } elsif ($partNo > 1 and $sequence =~ /^h/) {
		# ignore silent h after vowel (lengthening the vowel
		(my $subst = $sequence) =~ s/^h//;
		push @splits, $sequence;
	    } else {
		push @splits, $sequence;
	    }

	    @$part = @splits;
	}
    }
    return @words;
}

sub post_join {
    my ($self, @words) = @_;
    # nothing to do here
    return @words;
}

1;
