package Whelk::StrictBase;
$Whelk::StrictBase::VERSION = '1.02';
use strict;
use warnings;

use parent 'Kelp::Base';
use Kelp::Util;
use Carp;
use List::Util ();
use Text::Levenshtein ();

my %class_attributes;

sub attr
{
	my ($class, $name, $default) = @_;

	# names starting with a question mark will be used to suggest proper key to
	# the user
	my $for_user = $name =~ s/^\?//;

	my $ret = Kelp::Base::attr($class, $name, $default);

	$name =~ s/^-//;
	$class_attributes{$class}{$name} = $for_user;

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

	my @options = grep { $class_attributes{$class}{$_} } keys %{$class_attributes{$class}};
	my @distances = Text::Levenshtein::distance($key, @options);
	my $min = List::Util::min(@distances);
	return () unless defined $min && $min < 4;

	return map { $options[$_] } grep { $distances[$_] == $min } keys @options;
};

sub new
{
	my ($class, %params) = @_;

	foreach my $key (keys %params) {
		if (!defined $class_attributes{$class}{$key}) {
			my @closest = $find_closest->($class, $key);
			my $hint = join ' or ', map { "'$_'" } @closest;

			croak "attribute '$key' is not valid for class $class" . ($hint ? ". Did you mean $hint?" : '');
		}
	}

	return $class->SUPER::new(%params);
}

1;

