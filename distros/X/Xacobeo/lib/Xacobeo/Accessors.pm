package Xacobeo::Accessors;

=head1 NAME

Xacobeo::Accessors - Generate accessors/setters easily.

=head1 SYNOPSIS

	# Create $self->document and $self->xpath
	use Xacobeo::Accessors qw{
		document
		xpath
	};
	
	$self->document($document);
	validate($self->xpath);

=head1 DESCRIPTION

This package provides a utility for creating methods that work as accessors and
setters. Usually L<Class::Accessor::Fast> would have been used but it conflicts
with GObject's system when extending a pure perl GObject.

=head1 IMPORTS

This package imports the methods listed in the import clause.

=cut

use strict;
use warnings;


sub import {
	my $class = shift;
	my @names = @_;

	my @caller = caller(1);
	my $package = $caller[3];
	$package =~ s/::[^:]+$//;
	
	foreach my $name (@names) {
		
		my $sub = sub {
			return @_ > 1 ? $_[0]{$name} = $_[1] : $_[0]{$name};
		};
		
		{
			no strict 'refs';
			*{"${package}::${name}"} = $sub;
		}
	}
}


# A true value
1;


=head1 AUTHORS

Emmanuel Rodriguez E<lt>potyl@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Emmanuel Rodriguez.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
