package WWW::Shopify::Liquid::Dialect;

use strict;
use warnings;
use Module::Find;

sub new { return bless { }, $_[0]; }

sub use_modules {
	my ($self, $package) = @_;
	return useall($package || ref($self) || $self);
}

sub apply {
	my ($self, $liquid, $package) = @_;
	
	my @modules = $self->use_modules($package);
	
	$liquid->register_operator($_) for (grep { $_ =~ m/\bOperator\b/ } @modules);
	$liquid->register_filter($_) for (grep { $_ =~ m/\bFilter\b/ } @modules);
	$liquid->register_tag($_) for (grep { $_ =~ m/\bTag\b/ } @modules);
}

1;