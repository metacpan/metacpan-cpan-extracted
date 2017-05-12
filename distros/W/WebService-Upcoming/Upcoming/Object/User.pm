# *****************************************************************************
# *                                                                           *
# * WebService::Upcoming::Object::User                                        *
# *                                                                           *
# *****************************************************************************


# Package *********************************************************************
package WebService::Upcoming::Object::User;


# Uses ************************************************************************
use strict;
use WebService::Upcoming::Object;


# Exports *********************************************************************
our @ISA = ('WebService::Upcoming::Object');
our $VERSION = '0.05';


# Code ************************************************************************
sub new   { return WebService::Upcoming::Object::new(@_); }
sub _name { return 'watchlist'; }
sub _list { shift;
            return ('id','name','username','zip','photourl','url' )
             if ($_[0] eq '1.0');
            return (); }
sub _info { return (
             { 'upco' => 'user.getInfo','http' => 'GET' } ); }
1;
__END__

=head1 NAME

WebService::Upcoming::Object::User - User response object to the Upcoming API

=head1 AUTHOR

Copyright (C) 2005, Greg Knauss, E<lt>greg@eod.comE<gt>

=head1 SEE ALSO

L<WebService::Upcoming>

=cut
