/*
// On windows, functions have a different address when they are used
// internally from a DLL, to externally.  This causes problems when attempting
// to call tpadvertise from within a DLL that also contains the function that
// the service should map to.  When you run buildserver, you must specify all
// functions that could possibly be mapped to a service.  The address of the
// function is stored in a dispatch table contained in the generated BS-xxx.c
// file.  If the function is in a DLL, then the address stored in the dispatch
// table is the external address.  When you then try to call tpadvertise from
// the DLL and use the internal address, tpadvertise fails because it compares
// the function address passed to tpadvertise, with function addresses stored
// in the dispatch table.  This causes a problem with the framework because
// the _DISPATCH_ function is contained in the libtuxfmwk.dll file on WIN32
// and the TuxedoServer failed to advertise the registered servlets to this
// function.
//
// The work around is to define TMMAINEXIT when building a tuxedo server on
// WIN32.  That will make the BS-xxx.c file include mainexit.h.  This is our
// version of mainexit.h.  Because this file is included in BS-xxx.c, we can
// access any of the structures declared in BS-xxx.c, including the dispatch
// table.  So here, we just store the address of the dispatch table in a
// variable within the Tuxedo perl module dll!  Then when we get around to
// advertising registered TuxedoServlets, we look up the dispatch table for
// the external address of the PERL function, and use that in tpadvertise.
// Works a treat!
*/
void settmsvrargs( struct tmsvrargs_t * tmsvrargs );
settmsvrargs( _tmgetsvrargs() );
