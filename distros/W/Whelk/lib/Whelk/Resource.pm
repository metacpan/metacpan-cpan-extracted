package Whelk::Resource;
$Whelk::Resource::VERSION = '1.04';
use Kelp::Base 'Whelk';
use Role::Tiny::With;

with 'Whelk::Role::Resource';

sub api { ... }

1;

__END__

=pod

=head1 NAME

Whelk::Resource - Base Kelp controller for Whelk

=head1 SYNOPSIS

	package My::Resource;

	use Kelp::Base 'Whelk::Resource';

	# required
	sub api
	{
		my ($self) = @_;

		# implement the api
		...;
	}

=head1 DESCRIPTION

This is the base controller for L<Whelk>. It extends Whelk and implements the
Resource role, since all controllers for Whelk are API resources by default. If
you want to create your own application which uses L<Kelp::Module::Whelk>, take
a look at L<Whelk::Role::Resource> instead.

