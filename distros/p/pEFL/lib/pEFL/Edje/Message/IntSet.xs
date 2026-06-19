#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Edje.h>

typedef Edje_Message_Int_Set EdjeMessageIntSet;

MODULE = pEFL::Edje::Message::IntSet		PACKAGE = pEFL::Edje::Message::IntSet

EdjeMessageIntSet *
_new(class,count, val_arr)
	char *class
	int count
	AV *val_arr
PREINIT:
	EdjeMessageIntSet *message;
	int *val;
	int index;
CODE:
	Newx(message,1,EdjeMessageIntSet);
	Renewc(message,count+2,int,EdjeMessageIntSet);
	if (message == NULL) 
		croak("Failed to allocate memory in _new function\n");
	message->count = count+1;
	for (index = 0; index <= count; index++) {
		message->val[index] = SvIV( *av_fetch(val_arr,index,0) );
		//printf("VALUE %d\n",message->val[index]);
	}
	RETVAL = message;
OUTPUT:
	RETVAL

void
DESTROY(message) 
    EdjeMessageIntSet *message
CODE:
	//printf("Freeing Message_Int_Set\n");
	Safefree(message);

MODULE = pEFL::Edje::Message::IntSet		PACKAGE = EdjeMessageIntSetPtr

int
count(message)
    EdjeMessageIntSet *message
CODE:
    RETVAL = message->count;
OUTPUT:
    RETVAL
    
void
val(message)
    EdjeMessageIntSet *message
PREINIT:
	int count;
	int *vals;
	int index;
PPCODE:
    count = message->count;
    vals = message->val;
    
    EXTEND(SP,count);
    for (index = 0; index <count; index++) {
    	PUSHs( sv_2mortal( newSViv( vals[index] ) ));
	}

=pod

=head1 DEVELOPER MEMO: MEMORY MANAGEMENT & OWNERSHIP FOR MESSAGES

=head2 PACKAGE: pEFL::Edje::Message::IntSet

=over 4

=item * B<Context:> For messages actively created in Perl (e.g., via C<< ->new() >>).

=item * B<Ownership:> Perl owns this data structure. 

=item * B<Lifecycle:> After sending via C<edje_object_message_send()>, Edje performs a deep copy. The original Perl-created structure is no longer needed by the C layer. 

=item * B<Action:> Perl B<MUST> free the memory in C<DESTROY> using C<Safefree> to prevent memory leaks.

=back

=head2 PACKAGE: EdjeMessageIntSetPtr

=over 4

=item * B<Context:> Base class for all EdjeMessageIntSet methods. Used directly in the C-handler (C<call_perl_edje_message_handler>) to pass read-only pointers from C to Perl.

=item * B<CRITICAL: NO DESTROY HERE!>

=over 4

=item 1. Object from C

If the object originates in C, the C-handler blesses it directly into THIS package. The memory belongs to Edje and is automatically freed after the callback. Adding a C<DESTROY> here will corrupt Edje's internal memory.

=item 2. Object from Perl

When Perl creates the message, C<pEFL::Edje::Message::IntSet> inherits from this package to share the C<str()> method. Since Perl is the owner in that case, its own C<DESTROY> block safely handles the cleanup.

=back

=back

=cut
