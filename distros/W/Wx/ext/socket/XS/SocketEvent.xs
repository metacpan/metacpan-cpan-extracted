#############################################################################
## Name:        ext/socket/XS/SocketEvent.xs
## Purpose:     XS for Wx::SocketEvent
## Author:      Graciliano M. P.
## Created:     05/03/2003
## RCS-ID:      $Id: SocketEvent.xs 2057 2007-06-18 23:03:00Z mbarbon $
## Copyright:   (c) 2003 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

MODULE=Wx PACKAGE=Wx::SocketEvent

wxSocketEvent*
wxSocketEvent::new(id = 0)
    int id
  CODE:
    RETVAL = new wxSocketEvent( id ) ;
  OUTPUT: RETVAL

wxSocketBase*
wxSocketEvent::GetSocket()

long
wxSocketEvent::GetSocketEvent()


