# *****************************************************************************
# *                                                                           *
# * WebService::Upcoming::Object::Category                                    *
# *                                                                           *
# *****************************************************************************


# Package *********************************************************************
package WebService::Upcoming::Object::Category;


# Uses ************************************************************************
use strict;
use WebService::Upcoming::Object;


# Exports *********************************************************************
our @ISA = ('WebService::Upcoming::Object');
our $VERSION = '0.05';


# Code ************************************************************************
sub new   { return WebService::Upcoming::Object::new(shift,@_); }
sub _name { return 'category'; }
sub _list { shift;
            return ('id','name','description') if ($_[0] eq '1.0');
            return (); }
sub _info { return (
             { 'upco' => 'category.getList','http' => 'GET' } ); }
1;
__END__

=head1 NAME

WebService::Upcoming::Object::Category - Category response object to the Upcoming API

=head1 AUTHOR

Copyright (C) 2005, Greg Knauss, E<lt>greg@eod.comE<gt>

=head1 SEE ALSO

L<WebService::Upcoming>

=cut
