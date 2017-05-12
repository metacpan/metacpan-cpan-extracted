# This code is a part of tux_perl, and is released under the GPL.
# Copyright 2002 by Yale Huang<mailto:yale@sdf-eu.org>.
# See README and COPYING for more information, or see
#   http://tux-perl.sourceforge.net/.
#
# $Id: Constants.pm,v 1.3 2002/11/11 11:16:08 yaleh Exp $

package Tux::Constants;

use strict;

use vars qw( $VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS );
require Exporter;
@ISA = qw(Exporter);


my @action =qw(TUX_ACTION_STARTUP
	       TUX_ACTION_SHUTDOWN
	       TUX_ACTION_STARTTHREAD
	       TUX_ACTION_STOPTHREAD
	       TUX_ACTION_EVENTLOOP
	       TUX_ACTION_GET_OBJECT
	       TUX_ACTION_SEND_OBJECT
	       TUX_ACTION_READ_OBJECT
	       TUX_ACTION_FINISH_REQ
	       TUX_ACTION_FINISH_CLOSE_REQ
	       TUX_ACTION_REGISTER_MODULE
	       TUX_ACTION_UNREGISTER_MODULE
	       TUX_ACTION_CURRENT_DATE
	       TUX_ACTION_REGISTER_MIMETYPE
	       TUX_ACTION_READ_HEADERS
	       TUX_ACTION_POSTPONE_REQ
	       TUX_ACTION_CONTINUE_REQ
	       TUX_ACTION_REDIRECT_REQ
	       TUX_ACTION_READ_POST_DATA
	       TUX_ACTION_SEND_BUFFER
	       TUX_ACTION_WATCH_PROXY_SOCKET
	       TUX_ACTION_WAIT_PROXY_SOCKET
	      );

my @event =qw(TUX_EVENT_FINISH_REQ
	      TUX_EVENT_FINISH_CLOSE_REQ
	     );

my @method = qw(METHOD_NONE METHOD_GET METHOD_HEAD METHOD_POST METHOD_PUT);

@EXPORT = qw();
@EXPORT_OK = (@action,@event,@method);
%EXPORT_TAGS = ( all => [@action,@event,@method],
		 action => [@action],
		 event => [@event],
		 mehtod => [@method]
	       );
Exporter::export_ok_tags('all','action','event','method');

sub TUX_ACTION_STARTUP { 1 }
sub TUX_ACTION_SHUTDOWN { 2 }
sub TUX_ACTION_STARTTHREAD { 3 }
sub TUX_ACTION_STOPTHREAD { 4 }
sub TUX_ACTION_EVENTLOOP { 5 }
sub TUX_ACTION_GET_OBJECT { 6 }
sub TUX_ACTION_SEND_OBJECT { 7 }
sub TUX_ACTION_READ_OBJECT { 8 }
sub TUX_ACTION_FINISH_REQ { 9 }
sub TUX_ACTION_FINISH_CLOSE_REQ { 10 }
sub TUX_ACTION_REGISTER_MODULE { 11 }
sub TUX_ACTION_UNREGISTER_MODULE { 12 }
sub TUX_ACTION_CURRENT_DATE { 13 }
sub TUX_ACTION_REGISTER_MIMETYPE { 14 }
sub TUX_ACTION_READ_HEADERS { 15 }
sub TUX_ACTION_POSTPONE_REQ { 16 }
sub TUX_ACTION_CONTINUE_REQ { 17 }
sub TUX_ACTION_REDIRECT_REQ { 18 }
sub TUX_ACTION_READ_POST_DATA { 19 }
sub TUX_ACTION_SEND_BUFFER { 20 }
sub TUX_ACTION_WATCH_PROXY_SOCKET { 21 }
sub TUX_ACTION_WAIT_PROXY_SOCKET { 22 }

sub TUX_EVENT_FINISH_REQ { -1 }
sub TUX_EVENT_FINISH_CLOSE_REQ { -2 }

sub METHOD_NONE{0}
sub METHOD_GET{1}
sub METHOD_HEAD{2}
sub METHOD_POST{3}
sub METHOD_PUT{4}

1;
__END__

=head1 NAME

Tux::Constants - Constant definitions for tux_perl

=head1 SYNOPSIS

  use Tux;
  use Tux::Constants qw/:event/;

  $r->event(TUX_EVENT_FINISH_REQ);

  use Tux::Constants qw/:method/;

  if($r->method==METHOD_POST){
    ...
  }

  use Tux::Constants qw/:action/;

  $r->tux(TUX_ACTION_SEND_BUFFER);

=head1 ABSTRACT

Tux::Constants defines constants for tux_perl, including events,
methods and actions.

=head1 DESCRIPTION

=head2 EVENT

Please refer to tux man page for the description of events.

=head2 ACTION

Two actions are predefined to speed up the module: B<TUX_EVENT_FINISH_REQ>
and B<TUX_EVENT_FINISH_CLOSE_REQ>. Setting the event value to these two
values, tux_perl will do action B<TUX_ACTION_FINISH_REQ> or
B<TUX_ACTION_FINISH_CLOSE_REQ> when this request is processed next time
without enter the perl handler.

=head2 METHOD

The http_method method of Tux object will return one of the following
values:  B<METHOD_NONE>, B<METHOD_GET>, B<METHOD_HEAD>, B<METHOD_POST>, or
B<METHOD_PUT>.

=head2 EXPORT

None by default.

=over 4

=item action

=over 4

 TUX_ACTION_STARTUP
 TUX_ACTION_SHUTDOWN
 TUX_ACTION_STARTTHREAD
 TUX_ACTION_STOPTHREAD
 TUX_ACTION_EVENTLOOP
 TUX_ACTION_GET_OBJECT
 TUX_ACTION_SEND_OBJECT
 TUX_ACTION_READ_OBJECT
 TUX_ACTION_FINISH_REQ
 TUX_ACTION_FINISH_CLOSE_REQ
 TUX_ACTION_REGISTER_MODULE
 TUX_ACTION_UNREGISTER_MODULE
 TUX_ACTION_CURRENT_DATE
 TUX_ACTION_REGISTER_MIMETYPE
 TUX_ACTION_READ_HEADERS
 TUX_ACTION_POSTPONE_REQ
 TUX_ACTION_CONTINUE_REQ
 TUX_ACTION_REDIRECT_REQ
 TUX_ACTION_READ_POST_DATA
 TUX_ACTION_SEND_BUFFER
 TUX_ACTION_WATCH_PROXY_SOCKET
 TUX_ACTION_WAIT_PROXY_SOCKET

=back

=item event

=over 4

 TUX_EVENT_FINISH_REQ
 TUX_EVENT_FINISH_CLOSE_REQ

=back

=item method

=over 4

 METHOD_NONE
 METHOD_GET
 METHOD_HEAD
 METHOD_POST
 METHOD_PUT

=back

=back

=head1 SEE ALSO

Tux, tux

More information about tux_perl can be found at

  http://tux-perl.sourceforge.net
  http://sourceforge.net/projects/tux-perl

=head1 AUTHOR

Yale Huang, E<lt>yale@sdf-eu.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002 by Yale Huang

This library is released under the GPL; you can redistribute it and/or modify
it under the term of GPL.

=cut
