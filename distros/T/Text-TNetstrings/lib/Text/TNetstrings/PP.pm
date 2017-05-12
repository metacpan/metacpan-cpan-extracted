package Text::TNetstrings::PP;
use strict;
use warnings;
use Carp qw(croak);
use Scalar::Util qw(blessed);
use base qw(Exporter);

=head1 NAME

Text::TNetstrings::PP - Pure-Perl data serialization using typed netstrings.

=head1 VERSION

Version 1.2.0

=cut

use version 0.77; our $VERSION = version->declare("v1.2.0");

=head1 SYNOPSIS

A pure-Perl implementation of the tagged netstring specification. The
interface is the same as documented in L<Text::TNetstrings>.

=head1 EXPORT

=over

=item C<encode_tnetstrings($data)>

=item C<decode_tnetstrings($data)>

=item C<:all>

The C<:all> tag exports all the above subroutines.

=back

=cut

our @EXPORT_OK = qw(encode_tnetstrings decode_tnetstrings);
our %EXPORT_TAGS = (
	"all" => \@EXPORT_OK,
);

sub encode_tnetstrings {
	my $data = shift;
	my ($encoded, $type);

	if(ref($data) eq "ARRAY") {
		$encoded = join('', map {encode_tnetstrings($_)} @$data);
		$type = ']';
	} elsif(ref($data) eq "HASH") {
		while(my ($key, $value) = each(%$data)) {
			# Keys must be strings
			$encoded .= encode_tnetstrings("" . $key);
			$encoded .= encode_tnetstrings($value);
		}
		$type = '}';
	} elsif(blessed($data) && $data->isa('boolean')) {
		$encoded = $data ? 'true' : 'false';
		$type = '!';
	} elsif(!defined($data)) {
		$encoded = '';
		$type = '~';
	} elsif($data =~ /^([-+])?[0-9]*\.[0-9]+$/) {
		$encoded = $data;
		$type = '^';
	} elsif($data =~ /^([-+])?[1-9][0-9]*$/) {
		$encoded = $data;
		$type = '#';
	} else {
		$encoded = $data;
		$type = ',';
	}
	# Since there is no boolean type, it's impossible to distinguish
	# between true/false and integers, strings, etc.  Boolean values
	# will simply be represented as whatever the underlying type is
	# (integer, string, undefined).
	return join('', length($encoded), ':', $encoded, $type);
}

sub decode_tnetstrings {
	my $encoded = shift;
	return unless $encoded;
	my ($decoded, $length, $data, $type, $rest);

	my $length_end = index($encoded, ":");
	$length = substr($encoded, 0, $length_end);

	my $offset = $length_end + 1;
	$data = substr($encoded, $offset, $length);
	$offset += $length;
	$type = substr($encoded, $offset, 1);

	for($type) {
		"," eq $_ and do {
			$decoded = $data;
			last;
		};
		"#" eq $_ and do {
			$decoded = int($data);
			last;
		};
		"^" eq $_ and do {
			$decoded = $data;
			last;
		};
		"!" eq $_ and do {
			$decoded = $data eq 'true';
			last;
		};
		"~" eq $_ and do {
			$decoded = undef;
			last;
		};
		"}" eq $_ and do {
			$decoded = {};
			my $ss = $data;
			do {
				my ($x, $y);
				($x, $ss) = decode_tnetstrings($ss);
				($y, $ss) = decode_tnetstrings($ss) or croak("unbalanced hash");
				$decoded->{$x} = $y;
			} while(defined($ss) && $ss ne '');
			last;
		};
		"]" eq $_ and do {
			$decoded = [];
			my $ss = $data;
			do {
				my $x;
				($x, $ss) = decode_tnetstrings($ss);
				push(@$decoded, $x);
			} while(defined($ss) && $ss ne '');
			last;
		};
		croak("type $type not supported");
	}

	if(wantarray()) {
		$rest = substr($encoded, $offset + 1) if length($encoded) > $offset;
		return ($decoded, $rest);
	}
	return $decoded;
}

=head1 AUTHOR

Sebastian Nowicki

=cut

1;
