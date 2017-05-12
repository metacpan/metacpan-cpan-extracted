# *****************************************************************************
# *                                                                           *
# * WebService::Upcoming::Object::Event                                       *
# *                                                                           *
# *****************************************************************************


# Package *********************************************************************
package WebService::Upcoming::Object::Event;


# Uses ************************************************************************
use strict;
use WebService::Upcoming::Object;


# Exports *********************************************************************
our @ISA = ('WebService::Upcoming::Object');
our $VERSION = '0.05';


# Code ************************************************************************
sub new   { return WebService::Upcoming::Object::new(shift,@_); }
sub _name { return 'event'; }
sub _list { shift;
            return ('id','name','description','start_date','end_date',
                    'start_time','end_time','personal','selfpromotion',
                    'metro_id','venue_id','user_id','category_id',
                    'date_posted','tags') if ($_[0] eq '1.0');
            return (); }
sub _info { return (
             { 'upco' => 'event.getInfo','http' => 'GET'  },
             { 'upco' => 'event.add',    'http' => 'POST' },
             { 'upco' => 'event.search', 'http' => 'GET'  } ); }
1;
__END__

=head1 NAME

WebService::Upcoming::Object::Event - Event response object to the Upcoming API

=head1 AUTHOR

Copyright (C) 2005, Greg Knauss, E<lt>greg@eod.comE<gt>

=head1 SEE ALSO

L<WebService::Upcoming>

=cut
