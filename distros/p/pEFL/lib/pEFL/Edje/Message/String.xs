#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Edje.h>

typedef Edje_Message_String EdjeMessageString;

MODULE = pEFL::Edje::Message::String		PACKAGE = pEFL::Edje::Message::String

EdjeMessageString *
new(class,str)
	char *class
	SV *str
PREINIT:
	EdjeMessageString *message;
	char *string;
	STRLEN len;
CODE:
	if (items != 2) {
		Perl_croak(aTHX_ "Usage pEFL::Edje::Message::String->new($string)\n");
	}
	New(0,message,1,EdjeMessageString);
	string = SvPV(str,len);
	message->str = savepvn(string,len);
	RETVAL = message;
OUTPUT:
	RETVAL

void
DESTROY(message) 
    EdjeMessageString *message
CODE:
	/* FIX: Zuerst den mit savepvn erzeugten String-Inhalt löschen */
	if (message->str) {
		Safefree(message->str);
	}
	/* Danach erst die Struktur selbst löschen */
	Safefree(message);

	
MODULE = pEFL::Edje::Message::String		PACKAGE = EdjeMessageStringPtr

char*
str(message)
    EdjeMessageString *message
CODE:
    RETVAL = message->str;
OUTPUT:
    RETVAL

=pod

=head1 DEVELOPER MEMO: MEMORY MANAGEMENT & OWNERSHIP FOR MESSAGES

=head2 PACKAGE: pEFL::Edje::Message::String

=over 4

=item * B<Context:> For messages actively created in Perl (e.g., via C<< ->new() >>).

=item * B<Ownership:> Perl owns this data structure. 

=item * B<Lifecycle:> After sending via C<edje_object_message_send()>, Edje performs a deep copy. The original Perl-created structure is no longer needed by the C layer. 

=item * B<Action:> Perl B<MUST> free the memory in C<DESTROY> using C<Safefree> to prevent memory leaks.

=back

=head2 PACKAGE: EdjeMessageStringPtr

=over 4

=item * B<Context:> Base class for all EdjeMessageString methods. Used directly in the C-handler (C<call_perl_edje_message_handler>) to pass read-only pointers from C to Perl.

=item * B<CRITICAL: NO DESTROY HERE!>

=over 4

=item 1. Object from C

If the object originates in C, the C-handler blesses it directly into THIS package. The memory belongs to Edje and is automatically freed after the callback. Adding a C<DESTROY> here will corrupt Edje's internal memory.

=item 2. Object from Perl

When Perl creates the message, C<pEFL::Edje::Message::String> inherits from this package to share the C<str()> method. Since Perl is the owner in that case, its own C<DESTROY> block safely handles the cleanup.

=back

=back

=cut
