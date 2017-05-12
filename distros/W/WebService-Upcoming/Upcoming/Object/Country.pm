# *****************************************************************************
# *                                                                           *
# * WebService::Upcoming::Object::Country                                     *
# *                                                                           *
# *****************************************************************************


# Package *********************************************************************
package WebService::Upcoming::Object::Country;


# Uses ************************************************************************
use strict;
use WebService::Upcoming::Object;


# Exports *********************************************************************
our @ISA = ('WebService::Upcoming::Object');
our $VERSION = '0.05';


# Code ************************************************************************
sub new   { return WebService::Upcoming::Object::new(shift,@_); }
sub _name { return 'country'; }
sub _list { shift;
            return ('id','name','code') if ($_[0] eq '1.0');
            return (); }
sub _info { return (
             { 'upco' => 'event.getCountryList','http' => 'GET' } ); }
1;
__END__

=head1 NAME

WebService::Upcoming::Object::Country - Country response object to the Upcoming API

=head1 AUTHOR

Copyright (C) 2005, Greg Knauss, E<lt>greg@eod.comE<gt>

=head1 SEE ALSO

L<WebService::Upcoming>

=cut
