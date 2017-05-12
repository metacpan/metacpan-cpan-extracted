package XPanel;

use strict;
use warnings;
use vars qw($VERSION);

$VERSION = '0.0.1';


sub new {
	my $this = shift;
	my $class = ref($this) || $this;
	my $self = {};
	bless $self, $class;
	$self->_initialize();
	return $self;
}

sub _initialize {
	my $self = shift;
	$self->{'customer_id'} = 0;
	$self->{'login_name'} = '';
	$self->{'password'} = '';
	$self->{'status'} = 'notValidated';
	$self->{'password_hint'} = '';
	$self->{'call_in_pin'} = 0;
	$self->{'first_name'} = '';
	$self->{'middle_name'} = '';
	$self->{'last_name'} = '';
	$self->{'organization'} = '';
	$self->{'address1'} = '';
	$self->{'address2'} = '';
	$self->{'city'} = '';
	$self->{'state'} = '';
	$self->{'postal_code'} = '';
	$self->{'country'} = '';
	$self->{'work_phone'} = 0;
	$self->{'home_phone'} = '';
	$self->{'mobile_phone'} = '';
	$self->{'fax'} = '';
	$self->{'email'} = '';
	$self->{'account_type'} = 0;
	$self->{'gender'} = '';
	$self->{'birthday'} = '';
	$self->{'language'} = 'en-US';
	$self->{'subscribe'} = 0;
	$self->{'last_ip_address'} = '';
	$self->{'comments'} = '';
	$self->{'creation_date'} = '0000-00-00 00:00:00';
	$self->{'updated_date'} = '0000-00-00 00:00:00';
}

1;
__END__

=head1 NAME

XPanel - Perl extension to XPanel servers

=head1 SYNOPSIS

  use XPanel;

=head1 DESCRIPTION

This is a placeholder for now for XPanel:: modules.

I'm doing this as a XPanel L<http://www.xpanel.com> developer for future development of our public API.

=head1 USING THE XPanel:: namespace

If you'd like to use the XPanel namespace in your modules, please use XPanel::3rdparty  or XPanel::My as your 
base namespace to avoid confusion with modules released by XPanel, Inc.

Thank you very much for your consideration in this matter.

=head1 AUTHOR

Lilian Rudenco, E<lt>http://www.xpanel.com/E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Lilian Rudenco

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut