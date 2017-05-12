/*---------------------------------------------------------------------
 $Header: /Perl/OlleDB/connect.h 2     08-01-05 21:26 Sommar $

  Implements the connection routines on Win32::SqlServer.

  Copyright (c) 2004-2008   Erland Sommarskog

  $History: connect.h $
 * 
 * *****************  Version 2  *****************
 * User: Sommar       Date: 08-01-05   Time: 21:26
 * Updated in $/Perl/OlleDB
 * Moving the creation of the session pointer broke AutoConnect. The code
 * for AutoConnect is now in the connect module and be called from
 * executebatch or definetablecolumn.
 *
 * *****************  Version 1  *****************
 * User: Sommar       Date: 07-12-24   Time: 21:39
 * Created in $/Perl/OlleDB
  ---------------------------------------------------------------------*/


// Connect, called from $X->Connect() and $X->executebatch for autoconnect.
extern BOOL do_connect (SV    * olle_ptr,
                        BOOL    isautoconnect);

// This is $X->setloginproperty.
extern void setloginproperty(SV   * olle_ptr,
                             char * prop_name,
                             SV   * prop_value);

// Sets up the datasrc and session pointers and implements Auto-Connect.
extern BOOL setup_session(SV * olle_ptr);

// $X->disconncet
extern void disconnect(SV * olle_ptr);
