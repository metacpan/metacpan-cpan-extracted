#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <windows.h>

unsigned short XSRegisterHotkey( unsigned int modifier, unsigned int vkey, char* name ) {
	
	unsigned short atom = GlobalAddAtom( name );

	if ( RegisterHotKey( NULL, atom, modifier, vkey) ) {
		return atom;
	} else {
		return 0;
	}
}

MSG msg;
unsigned int XSGetMessage() {
	
	if ( GetMessage( &msg, NULL, 0, 0 ) != 0 ) {
		return msg.wParam;
	} else {
		return 0;
	}
}

bool XSUnregisterHotkey( unsigned short atom ) {
	bool ret = UnregisterHotKey( NULL, atom );
	unsigned short atom_ret = GlobalDeleteAtom( atom );
	return ret;	
}


MODULE = Win32::GlobalHotkey	PACKAGE = Win32::GlobalHotkey	

PROTOTYPES: DISABLE


unsigned short
XSRegisterHotkey (modifier, vkey, name)
	unsigned int	modifier
	unsigned int	vkey
	char *	name

unsigned int
XSGetMessage ()

bool
XSUnregisterHotkey (atom)
	unsigned short	atom

