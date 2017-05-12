package Xacobeo::Plugin;

=head1 NAME

Xacobeo::Plugin - Parent class for all plugins.

=head1 SYNOPSIS

	use strict;
	use warnings;
	
	use base 'Xacobeo::Plugin';
	
	sub init {
		my ($self, $xacobeo) = @_;
		
		my ($window) = $xacobeo->get_windows();
		$window->statusbar->display("Plugin Loaded!");
	}
	
	# Finish the plugin with loaded
	__PACKAGE__->load();

=head1 DESCRIPTION

Parent class for all plugins. It provides a common framework for all plugins.

=head1 METHODS

The package defines the following methods:

=cut

use strict;
use warnings;

use Data::Dumper;


sub new {
	my $class = shift;;
	my $self = bless {}, ref($class) || $class;
	return $self;
}


sub init {
	my $self = shift;
	die "Plugin ", ref $self, " is missing the init method";
}


sub load {
	my ($package) = caller;
	return $package->new();
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
