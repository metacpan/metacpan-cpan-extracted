use warnings;
use strict;

use Test::More tests => 1 + 2*504;

BEGIN { $SIG{__WARN__} = sub { die "WARNING: $_[0]" }; }

BEGIN { use_ok "XML::Easy::Syntax", qw(
		$xml10_content_rx $xml10_element_rx
		$xml10_document_xdtd_rx $xml10_extparsedent_rx
); }

use Encode qw(decode);
use IO::File ();
use utf8 ();

sub upgraded($) {
	my($str) = @_;
	utf8::upgrade($str);
	return $str;
}

sub downgraded($) {
	my($str) = @_;
	utf8::downgrade($str, 1);
	return $str;
}

my %recogniser = (
	c => qr/\A$xml10_content_rx\z/o,
	e => qr/\A$xml10_element_rx\z/o,
	d => qr/\A$xml10_document_xdtd_rx\z/o,
	x => qr/\A$xml10_extparsedent_rx\z/o,
);

# This code checks whether the regexp iteration limit bug (#60034) is
# present.  The regexp match expression checks for getting the wrong
# result with a long input, and suffices to diagnose the bug.  However,
# running that test on a pre-5.10 perl causes the stack to grow large,
# and if there's a limited stack size then this may overflow it and
# cause perl to crash.  All pre-5.10 perls have the iteration limit
# bug, so there's no need to run the proper test on those verions.
# 5.10 fixed the stack issue, so it's safe to run the proper test there.
my $have_iterlimit_bug = "$]" < 5.010 || do {
	local $SIG{__WARN__} = sub { };
	("a"x40000) !~ /\A(?:X?[a-z])*\z/;
};

my $data_in = IO::File->new("t/read.data", "r") or die;
my $line = $data_in->getline;

while(1) {
	$line =~ /\A###([a-z])?(-?)\n\z/ or die;
	last unless defined $1;
	my($prod, $syntax_error) = ($1, $2);
	$line = $data_in->getline;
	last unless defined $line;
	my $input = "";
	while($line ne "#\n") {
		die if $line =~ /\A###/;
		$input .= $line;
		$line = $data_in->getline;
		die unless defined $line;
	}
	die if $input eq "";
	chomp($input);
	$input =~ tr/~/\r/;
	$input =~ s/\$\((.*?)\)/$1 x 40000/seg;
	$input =~ s/\$\{(.*?)\}/$1 x 32764/seg;
	$input = decode("UTF-8", $input);
	while(1) {
		$line = $data_in->getline;
		die unless defined $line;
		last if $line =~ /\A###/;
	}
	SKIP: {
		skip "perl bug affects long inputs", 2
			if $have_iterlimit_bug && length($input) >= 32766;
		is upgraded($input) =~ $recogniser{$prod}, !$syntax_error;
		is downgraded($input) =~ $recogniser{$prod}, !$syntax_error;
	}
}

1;
