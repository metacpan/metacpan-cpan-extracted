package Text::MultiPhone::no;

use 5.006;
use strict;
use warnings;

use POSIX qw(setlocale LC_CTYPE);

use base qw(Text::MultiPhone);

use constant VOWELS => [qw(a e i o u y æ ø å)];

our $VERSION = do { my @r = (q$Revision: 1.1.1.1 $ =~ /\d+/g); sprintf " %d." . "%02d" x $#r, @r };

sub pre_split {
    my ($self, $word) = @_;
    my $orgLocale = setlocale(LC_CTYPE);
    setlocale(LC_CTYPE, 'no_NO');
    use locale;

    $word = lc($word);
    $word =~ s/qu/q/g; # q is always alone
    # sj/kj lyder
    $word =~ s/skj/sj/g;
    $word =~ s/ski/sji/g;
    $word =~ s/ki/sji/g;
    $word =~ s/tj/sj/g;
    $word =~ s/kj/sj/g;
    $word =~ s/gj/sj/g;

    $word =~ s/aa/å/g;
    $word =~ s/ph/f/g;
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
	foreach my $part (@$word) {
	    next unless defined $part;
	    my $sequence = ${ $part }[0];
	    next unless $sequence;
	    my @splits;
	
	    if ($sequence =~ 'hv') {
		push @splits, 'w';
	    } elsif ($sequence =~ /v/) {
		# v sounds like w
		(my $subst = $sequence) =~ s/v/w/;
		push @splits, $subst;
	    } elsif ($sequence =~ /y/) {
		# y sounds like u,i
		(my $subst = $sequence) =~ s/y/i/;
		push @splits, $subst;
		($subst = $sequence)  =~ s/y/u/;
		push @splits, $subst;
	    } elsif ($sequence eq 'u') {
		# u sounds like u,i
		push @splits, 'u';
		push @splits, 'i';
	    } elsif ($sequence eq 'o') {
		# o sounds like u,o
		push @splits, 'u';
		push @splits, 'o';
	    } elsif ($sequence eq 'å') {
		# o sounds like u,o
		push @splits, 'o';
	    } elsif ($sequence eq 'æ' or $sequence eq 'ae') {
		# æ sounds like a,e
		push @splits, 'a';
		push @splits, 'e';
	    } elsif ($sequence eq 'ø' or $sequence eq 'oe') {
		# ö sounds like o,e
		push @splits, 'o';
		push @splits, 'e';
	    } elsif ($sequence eq 'øy' or $sequence eq 'øi' or $sequence eq 'oy') {
		push @splits, 'oi';
	    } elsif ($sequence eq 'ai') {
		push @splits, 'ei';
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
