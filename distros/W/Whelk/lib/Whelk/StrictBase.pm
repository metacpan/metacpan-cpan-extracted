package Whelk::StrictBase;
$Whelk::StrictBase::VERSION = '0.03';
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

sub new
{
	my ($class, %params) = @_;

	foreach my $key (keys %params) {
		croak "attribute $key is not valid for class $class"
			unless $class_attributes{$class}{$key};
	}

	return $class->SUPER::new(%params);
}

1;

