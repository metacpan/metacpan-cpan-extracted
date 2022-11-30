package Value::Diff;
$Value::Diff::VERSION = '0.002';
use v5.10;
use strict;
use warnings;

use Exporter qw(import);

our @EXPORT = qw(diff);

my $no_diff = \'no_diff';

sub _has_diff
{
	return !!1 unless defined $_[0];
	return $_[0] ne $no_diff;
}

sub _diff_hash
{
	my ($left, $right) = @_;

	my %out;
	for my $key (keys %{$left}) {
		my $value = $left->{$key};
		$out{$key} = $value
			unless exists $right->{$key};

		my $diff = _diff($value, $right->{$key});
		$out{$key} = $diff
			if _has_diff($diff);
	}

	return %out ? \%out : $no_diff;
}

sub _diff_array
{
	my ($left, $right) = @_;

	my @out;
	my @other = @{$right};

	OUTER:
	for my $value (@{$left}) {
		for my $key (0 .. $#other) {
			my $other_value = $other[$key];
			if (!_has_diff(_diff($value, $other_value))) {
				splice @other, $key, 1;
				next OUTER;
			}
		}

		# TODO: take the smallest diff instead of full $left?
		push @out, $value;
	}

	return @out ? \@out : $no_diff;
}

sub _diff_scalar
{
	my ($left, $right) = @_;

	my $diff = _diff($$left, $$right);
	return _has_diff($diff) ? \$diff : $no_diff;
}

sub _diff_other
{
	my ($left, $right) = @_;

	return $left
		if defined $left ne defined $right
		|| (defined $left && $left ne $right);

	return $no_diff;
}

sub _diff
{
	my ($left, $right) = @_;

	my $ref_left = ref $left;
	my $ref_right = ref $right;
	return $left if $ref_left ne $ref_right;
	return _diff_array($left, $right) if $ref_left eq 'ARRAY';
	return _diff_hash($left, $right) if $ref_left eq 'HASH';
	return _diff_scalar($left, $right) if $ref_left eq 'SCALAR' || $ref_left eq 'REF';
	return _diff_other($left, $right);
}

sub _empty_of_type
{
	my ($left) = @_;

	my $type = ref $left;
	return [] if $type eq 'ARRAY';
	return {} if $type eq 'HASH';
	return \undef if $type eq 'SCALAR';
	return undef;
}

sub diff
{
	my ($left, $right, $out) = @_;

	my $diff = _diff($left, $right);

	if (_has_diff($diff)) {
		$$out = $diff if ref $out;
		return !!1;
	}
	else {
		$$out = _empty_of_type($left) if ref $out;
		return !!0;
	}
}

1;

# ABSTRACT: find the difference between two Perl values

