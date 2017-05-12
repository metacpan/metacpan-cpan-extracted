# *****************************************************************************
# *                                                                           *
# * WebService::Upcoming::Object::Venue                                       *
# *                                                                           *
# *****************************************************************************


# Package *********************************************************************
package WebService::Upcoming::Object::Venue;


# Uses ************************************************************************
use strict;
use WebService::Upcoming::Object;


# Exports *********************************************************************
our @ISA = ('WebService::Upcoming::Object');
our $VERSION = '0.05';


# Code ************************************************************************
sub new   { return WebService::Upcoming::Object::new(shift,@_); }
sub _name { return 'venue'; }
sub _list { shift;
            return ('id','name','address','city','zip','phone','url',
                    'description') if ($_[0] eq '1.0');
            return (); };
sub _info { return (
             { 'upco' => 'venue.add',    'http' => 'POST' },
             { 'upco' => 'venue.getInfo','http' => 'GET'  },
             { 'upco' => 'venue.getList','http' => 'GET'  },
             { 'upco' => 'venue.search', 'http' => 'GET'  } ); }
1;
__END__

=head1 NAME

WebService::Upcoming::Object::Venue - Venue response object to the Upcoming API

=head1 AUTHOR

Copyright (C) 2005, Greg Knauss, E<lt>greg@eod.comE<gt>

=head1 SEE ALSO

L<WebService::Upcoming>

=cut
