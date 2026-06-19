#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Edje.h>

typedef Edje_Message_Float_Set EdjeMessageFloatSet;

MODULE = pEFL::Edje::Message::FloatSet		PACKAGE = pEFL::Edje::Message::FloatSet

EdjeMessageFloatSet *
_new(class,count, val_arr)
	char *class
	int count
	AV *val_arr
PREINIT:
	EdjeMessageFloatSet *message;
	double *val;
	int index;
CODE:
	Newx(message,1,EdjeMessageFloatSet);
	Renewc(message,count+2,double,EdjeMessageFloatSet);
	if (message == NULL) 
		croak("Failed to allocate memory in _new function\n");
	message->count = count+1;
	for (index = 0; index <= count; index++) {
		message->val[index] = SvNV( *av_fetch(val_arr,index,0) );
	}
	RETVAL = message;
OUTPUT:
	RETVAL

void
DESTROY(message) 
    EdjeMessageFloatSet *message
CODE:
	//printf("Freeing Message_Float_Set\n");
	Safefree(message);


MODULE = pEFL::Edje::Message::FloatSet		PACKAGE = EdjeMessageFloatSetPtr

int
count(message)
    EdjeMessageFloatSet *message
CODE:
    RETVAL = message->count;
OUTPUT:
    RETVAL
    
void
val(message)
    EdjeMessageFloatSet *message
PREINIT:
	int count;
	double *vals;
	int index;
PPCODE:
    count = message->count;
    vals = message->val;
    
    EXTEND(SP,count);
    for (index = 0; index <count; index++) {
    	PUSHs( sv_2mortal( newSVnv( vals[index] ) ));
	}
	
=pod

=head1 DEVELOPER MEMO: MEMORY MANAGEMENT & OWNERSHIP FOR MESSAGES

=head2 PACKAGE: pEFL::Edje::Message::FloatSet

=over 4

=item * B<Context:> For messages actively created in Perl (e.g., via C<< ->new() >>).

=item * B<Ownership:> Perl owns this data structure. 

=item * B<Lifecycle:> After sending via C<edje_object_message_send()>, Edje performs a deep copy. The original Perl-created structure is no longer needed by the C layer. 

=item * B<Action:> Perl B<MUST> free the memory in C<DESTROY> using C<Safefree> to prevent memory leaks.

=back

=head2 PACKAGE: EdjeMessageFloatSetPtr

=over 4

=item * B<Context:> Base class for all EdjeMessageFloatSet methods. Used directly in the C-handler (C<call_perl_edje_message_handler>) to pass read-only pointers from C to Perl.

=item * B<CRITICAL: NO DESTROY HERE!>

=over 4

=item 1. Object from C

If the object originates in C, the C-handler blesses it directly into THIS package. The memory belongs to Edje and is automatically freed after the callback. Adding a C<DESTROY> here will corrupt Edje's internal memory.

=item 2. Object from Perl

When Perl creates the message, C<pEFL::Edje::Message::FloatSet> inherits from this package to share the C<str()> method. Since Perl is the owner in that case, its own C<DESTROY> block safely handles the cleanup.

=back

=back

=cut
