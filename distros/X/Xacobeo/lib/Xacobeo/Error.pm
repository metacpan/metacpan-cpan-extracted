package Xacobeo::Error;

=encoding utf8

=head1 NAME

Xacobeo::Error - A simple wrapper over an error.

=head1 SYNOPSIS

	use Xacobeo::Error;
	
	# As a one time use
	my $error = Xacobeo::Error->new(xpath => "Failed to parse Xpath expression");
	die $error;

=head1 DESCRIPTION

This package provides a very simple, perhpaps too simple, error wrapper. This
errors are meant to be used as exceptions.

=head1 METHODS

The package defines the following methods:

=cut

use 5.006;
use strict;
use warnings;

use Glib;


# Register a new error type
BEGIN {
	my $enum = __PACKAGE__ . 'Code';
	Glib::Type->register_enum($enum, 'xpath');
	Glib::Error::register(    ##no critic (ProhibitCallsToUnexportedSubs)
		__PACKAGE__, $enum    # it is supposed to be called that way
	);
}


# A true value
1;


=head1 AUTHORS

Emmanuel Rodriguez E<lt>potyl@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008,2009 by Emmanuel Rodriguez.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

