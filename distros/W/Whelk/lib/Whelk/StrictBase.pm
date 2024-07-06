package Whelk::StrictBase;
$Whelk::StrictBase::VERSION = '0.04';
use strict;
use warnings;

use parent 'Kelp::Base';
use Kelp::Util;
use Carp;

my %class_attributes;

sub attr
{
	my ($class, $name, $default) = @_;

	my $ret = Kelp::Base::attr($class, $name, $default);

	$name =~ s/^-//;
	$class_attributes{$class}{$name} = 1;

	return $ret;
}

sub import
{
	my $class = shift;
	my $caller = caller;

	# Do not import into inherited classes
	return if $class ne __PACKAGE__;

	my $base = shift || $class;

	{
		no strict 'refs';
		no warnings 'redefine';

		Kelp::Util::load_package($base);
		push @{"${caller}::ISA"}, $base;
		%{$class_attributes{$caller}} = %{$class_attributes{$base} // {}};

		*{"${caller}::attr"} = sub { attr($caller, @_) };

		namespace::autoclean->import(
			-cleanee => $caller
		);
	}

	strict->import;
	warnings->import;
	feature->import(':5.10');
}

my $find_closest = sub {
	my ($class, $key) = @_;

	my @all = keys %{$class_attributes{$class}};
	@all = sort @all, $key;

	# in case $key ended up as index 0 or last
	unshift @all, undef;
	push @all, undef;

	shift @all while $all[1] ne $key;
	my @options = grep { defined } @all[0, 2];

	return undef if @options == 0;
	return $options[0] if @options == 1;

	# decide which option to present by checking the longest substring, but
	# only if at least two letters match.
	for my $len (reverse 2 .. length $key) {
		my $substr = lc substr $key, 0, $len;
		foreach my $other (@options) {
			return $other
				if $substr eq lc substr $other, 0, $len;
		}
	}

	return undef;
};

sub new
{
	my ($class, %params) = @_;

	foreach my $key (keys %params) {
		if (!$class_attributes{$class}{$key}) {
			my $closest = $find_closest->($class, $key);
			my $closest_sentence = defined $closest ? ". Did you mean $closest?" : '';

			croak "attribute $key is not valid for class $class" . $closest_sentence;
		}
	}

	return $class->SUPER::new(%params);
}

1;

