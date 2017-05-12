/*
 *
 * ICC.xs
 *
 * The XS interface to the ICC services 
 *
 * Modification History
 *
 * 07/26/99	DRS	Created, more or less
 */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <iccdef.h>
#include <libdef.h>
#include <builtins.h>
#include <ssdef.h>
#include <descrip.h>
#include <starlet.h>
#include <lib$routines.h>
#include <iosbdef.h>

/* The biggest message we're willing to receive */
#define MAX_MESSAGE_SIZE 1000

#define DEBUG_TRACE	(1<<0)
#define DEBUG_STATUS	(1<<1)
#define DEBUG_CHATTY	(1<<2)

static long max_entries = 25;	/* Maximum number of entries we'll	*/
				/* handle at one time */
static long queue_head[2];	/* Queue header */
static long queue_count;	/* Number of entries in the queue */
static long accepting_connections = 0;	/* True if we're accepting	*/
					/* connections, otherwise false */
static long ServiceInUse = 0;	/* Have we actually started? */

static long DebugLevel = 0;     /* Because things inevitably go wrong, */
				/* and it's nice to be able to follow */
				/* along at home */

struct queue_entry {
	char private_to_queue[8];
	unsigned int conn_handle;
};

/* An AST routine to accept incoming connections and put them on a */
/* queue */
void connect_call(unsigned int event_type, unsigned int conn_handle,
		  unsigned int data, char *data_bfr, unsigned int P5,
		  unsigned int P6, char *P7)
{
  struct queue_entry *queue_entry;
  int status;
  
  if (DebugLevel & DEBUG_TRACE) {
    puts("Entering connect_call");
  }

  /* Are we accepting any new connections? */
  if ((queue_count > max_entries) || !accepting_connections) {
    /* Nope. Tell 'em to go away */
    sys$icc_reject(conn_handle);
  } else {
    /* Yep. Increment the connect count and aquire the		*/
    /* connection */
    status = sys$icc_accept(conn_handle, NULL, 0, 0, 0);

    if (DebugLevel & DEBUG_STATUS) {
      printf("sys$icc_accept returned %i\n", status);
    }

    if (status == SS$_NORMAL) {
      /* Take the accepted connection, make a note of it, build a */
      /* queue entry, and put it on the queue */

      /* Gotta be atomic, otherwise it's not threadsafe. (Or AST safe, */
      /* for that matter) */
      queue_entry = malloc(sizeof(queue_entry));
      queue_entry->conn_handle = conn_handle;
      lib$insqti(queue_entry, queue_head);
      __ATOMIC_INCREMENT_LONG(&queue_count);
      if (DebugLevel & DEBUG_CHATTY) {
	printf("Accepted connection handle %i\n", conn_handle);
      }
    }
  }

  if (DebugLevel & DEBUG_TRACE) {
    puts("Leaving connect_call");
  }
  return;
}

char * ss_translate(int status)
{
  
  switch(status) {
  case SS$_NORMAL: return "SS$_NORMAL";
  case SS$_ACCVIO: return "SS$_ACCVIO";
  case SS$_BADPARAM: return "SS$_BADPARAM";
  case SS$_DUPLNAM: return "SS$_DUPLNAM";
  case SS$_EXQUOTA: return "SS$_EXQUOTA";
  case SS$_INSFARG: return "SS$_INSFARG";
  case SS$_INSFMEM: return "SS$_INSFMEM";
  case SS$_IVMODE: return "SS$_IVMODE";
  case SS$_NOLINKS: return "SS$_NOLINKS";
  case SS$_NONETMBX: return "SS$_NONETMBX";
  case SS$_NOPRIV: return "SS$_NOPRIV";
  case SS$_SSFAIL: return "SS$_SSFAIL";
  case SS$_TOO_MANY_ARGS: return "SS$_TOO_MANY_ARGS";
  case SS$_NOLOGTAB: return "SS$_NOLOGTAB";
  case SS$_NOSUCHOBJ: return "SS$_NOSUCHOBJ";
  default: return "dunno";
  }
}

MODULE = VMS::ICC		PACKAGE = VMS::ICC		

BOOT:
queue_count = 0;
Zero(queue_head, 2, long);


int
debug(debug_level)
    int debug_level;
   CODE:
     RETVAL = DebugLevel;
     DebugLevel = debug_level;
   OUTPUT:
     RETVAL


SV *
new_service(service_name = &PL_sv_undef, logical_name = &PL_sv_undef, logical_table = &PL_sv_undef)
     SV *service_name
     SV *logical_name
     SV *logical_table

   PPCODE:
{

  struct dsc$descriptor LogicalTable;
  struct dsc$descriptor LogicalName;
  struct dsc$descriptor ServiceName;

  $DESCRIPTOR(DefaultLogTable, "ICC$REGISTRY_TABLE");

  struct dsc$descriptor *LogicalTablePtr, *LogicalNamePtr, *ServiceNamePtr;

  unsigned int AssocHandle, status;

  if (DebugLevel & DEBUG_TRACE) {
    puts("Entering new_service");
  }

  /* Three parameters. service_name can be undef, in which case we'll   
     use the default service name. If logical_table is undef, then we'll   
     use the default ICC logical table */

  /* First, is the service already set up? die if it is */
  if (ServiceInUse) {
    croak("Service already registered");
    XSRETURN_UNDEF;
  }


  /* If the name's undef, use the default name, otherwise fill in the */
  /* blanks appropriately */
  if (!SvOK(service_name)) {
    ServiceNamePtr = NULL;
  } else {
    ServiceName.dsc$b_dtype = DSC$K_DTYPE_T;
    ServiceName.dsc$b_class = DSC$K_CLASS_S;
    ServiceName.dsc$a_pointer = SvPV(service_name, PL_na);
    ServiceName.dsc$w_length = SvCUR(service_name);
    ServiceNamePtr = &ServiceName;
  }
    
  /* If the name's undef, use the default name, otherwise fill in the */
  /* blanks appropriately */
  if (!SvOK(logical_name)) {
    LogicalNamePtr = NULL;
  } else {
    LogicalName.dsc$b_dtype = DSC$K_DTYPE_T;
    LogicalName.dsc$b_class = DSC$K_CLASS_S;
    LogicalName.dsc$a_pointer = SvPV(logical_name, PL_na);
    LogicalName.dsc$w_length = SvCUR(logical_name);
    LogicalNamePtr = &LogicalName;
  }
    
  /* If the name's undef, use the default name, otherwise fill in the */
  /* blanks appropriately */
  if (!SvOK(logical_table)) {
    if (SvOK(logical_name)) {
      LogicalTablePtr = (struct dsc$descriptor *)&DefaultLogTable;
    } else {
      LogicalTablePtr = NULL;
    }
  } else {
    LogicalTable.dsc$b_dtype = DSC$K_DTYPE_T;
    LogicalTable.dsc$b_class = DSC$K_CLASS_S;
    LogicalTable.dsc$a_pointer = SvPV(logical_table, PL_na);
    LogicalTable.dsc$w_length = SvCUR(logical_table);
    LogicalTablePtr = &LogicalTable;
  }
    

  status = sys$icc_open_assoc(&AssocHandle, ServiceNamePtr, LogicalNamePtr,
			      LogicalTablePtr, connect_call, NULL, NULL,
			      0, 0);

  if (DebugLevel & DEBUG_STATUS) {
    printf("sys$icc_open_assoc returned %i\n", status);
  }
  /* Did it work? */
  if ($VMS_STATUS_SUCCESS(status)) {
    accepting_connections = 1;
    ServiceInUse = 1;
    XPUSHs(sv_2mortal(newSViv(AssocHandle)));
    if (DebugLevel & DEBUG_TRACE) {
      puts("Leaving new_service");
    }
    XSRETURN(1);
  } else {
    printf("Error %i/%s\n", status, ss_translate(status));
    SETERRNO(EVMSERR, status);
    if (DebugLevel & DEBUG_TRACE) {
      puts("Leaving new_service");
    }
    XSRETURN_UNDEF;
  }
  if (DebugLevel & DEBUG_TRACE) {
    puts("Leaving new_service");
  }
}

SV *
accept_connection(service_handle = &PL_sv_undef)
     SV *service_handle
   PPCODE:
{
/* Accept an outstanding connection. (Well, one that we've already */
/* officially accepted, just not acknowledged) The parameter's */
/* currently ignored as we only allow one connection listener at the */
/* moment, but that could change in the future */

  SV *return_sv;
  struct queue_entry *queue_entry;

  if (DebugLevel & DEBUG_TRACE) {
    puts("Entering accept_connection");
  }

  /* try and take an entry off the queue and see what happens */
  lib$remqhi(queue_head, &queue_entry);
  /* If we got back the address of the queue_head, then there wasn't */
  /* anything to be had and we can exit with an undef */
  /* Yeah, I know casting these both to longs is skanky. But it shuts */
  /* the compiler up */
  if ((long)queue_entry == (long)queue_head) {
    if (DebugLevel & DEBUG_TRACE) {
      puts("Leaving accept_connection emptyhanded");
    }
    XSRETURN_UNDEF;
  }

  /* Decrement the queue count */
  __ATOMIC_DECREMENT_LONG(&queue_count);

  /* Hey, look--we got something. Pass it back. This counts on the */
  /* fact that a pointer will fit into the IV slot of an SV. This is */
  /* probably a bad, bad thing I'm doing here... */
  return_sv = sv_2mortal(newSViv(queue_entry->conn_handle));
  XPUSHs(return_sv);

  if (DebugLevel & DEBUG_CHATTY) {
    printf("Fetched connect handle %i (%i)\n",
	   queue_entry->conn_handle, SvIV(return_sv));
  }

  /* Free up the queue entry */
  Safefree(queue_entry);

  if (DebugLevel & DEBUG_TRACE) {
    puts("Leaving accept_connection");
  }
  XSRETURN(1);
}

SV *
read_data(connection_handle)
     SV *connection_handle
   PPCODE:
{
  SV *received_data;
  int status;
  ios_icc ICC_Info;

  if (DebugLevel & DEBUG_TRACE) {
    puts("Entering read_data");
  }

  /* Create us a new SV with MAX_MESSAGE_SIZE bytes allocated. Mark it */
  /* as mortal, too */
  received_data = NEWSV(912, MAX_MESSAGE_SIZE);
  sv_2mortal(received_data);

  if (DebugLevel & DEBUG_CHATTY) {
    printf("Listening on handle %i\n", SvIV(connection_handle));
  }

  /* Go look for some data */
  status = sys$icc_receivew(SvIV(connection_handle), &ICC_Info, NULL, 0,
			    SvPVX(received_data), MAX_MESSAGE_SIZE);

  if (DebugLevel & DEBUG_STATUS) {
    printf("sys$icc_receivew returned %i\n", status);
  }
  /* Did it go OK? */
  if (SS$_NORMAL == status) {
    /* Set the scalar length */
    SvCUR(received_data) = ICC_Info.ios_icc$l_rcv_len;
    SvPOK_on(received_data);
    XPUSHs(received_data);
    if (DebugLevel & DEBUG_TRACE) {
      puts("Leaving read_data");
    }
    XSRETURN(1);
  } else {
    /* Guess something went wrong. Return the status */
    SETERRNO(EVMSERR, status);
    if (DebugLevel & DEBUG_TRACE) {
      puts("Leaving read_data");
    }
    XSRETURN_UNDEF;
  }
  if (DebugLevel & DEBUG_TRACE) {
    puts("Leaving read_data");
  }
}

SV *
write_data(connection_handle, data, async = &PL_sv_undef)
     SV *connection_handle
     SV *data
     SV *async
   CODE:
{
  ios_icc ICC_Info;
  int status;

  if (DebugLevel & DEBUG_TRACE) {
    puts("Entering write_data");
  }
  /* Just return with ACCVIO they gave us no data. That's what'd */
  /* happen, after all, if we tried passing a null buffer around */
  if (!SvCUR(data)) {
    SETERRNO(EVMSERR, SS$_ACCVIO);
    if (DebugLevel & DEBUG_TRACE) {
      puts("Leaving write_data");
    }
    XSRETURN_UNDEF;
  }

  if (DebugLevel & DEBUG_CHATTY) {
    printf("Sending %i bytes to handle %i\n", SvCUR(data),
	   SvIV(connection_handle));
  }

  if (SvTRUE(async)) {
    status = sys$icc_transmit(SvIV(connection_handle), &ICC_Info, NULL, NULL,
			      SvPVX(data), SvCUR(data));
    if (DebugLevel & DEBUG_STATUS) {
      printf("sys$icc_transmit returned %i\n", status);
    }
  } else {
    status = sys$icc_transmitw(SvIV(connection_handle), &ICC_Info, NULL, NULL,
			       SvPVX(data), SvCUR(data));
    if (DebugLevel & DEBUG_STATUS) {
      printf("sys$icc_transmitw returned %i\n", status);
    }
  }
  if (SS$_NORMAL == status) {
    if (DebugLevel & DEBUG_TRACE) {
      puts("Leaving write_data");
    }
    XSRETURN_YES;
  } else {
    SETERRNO(EVMSERR, status);
    if (DebugLevel & DEBUG_TRACE) {
      puts("Leaving write_data");
    }
    XSRETURN_UNDEF;
  }
  if (DebugLevel & DEBUG_TRACE) {
    puts("Leaving write_data");
  }
}

SV *
close_connection(connection_handle)
     SV *connection_handle
   CODE:
{
  int status;
  iosb iosb;

  if (DebugLevel & DEBUG_TRACE) {
    puts("Entering close_connection");
  }
  status = sys$icc_disconnectw(SvIV(connection_handle), &iosb,0,0,0,0);
  if (DebugLevel & DEBUG_STATUS) {
    printf("sys$icc_disconnectw returned %i\n", status);
  }
  if (SS$_NORMAL == status) {
    if (DebugLevel & DEBUG_TRACE) {
      puts("Leaving close_connection");
    }
    XSRETURN_YES;
  } else {
    SETERRNO(EVMSERR, status);
    if (DebugLevel & DEBUG_TRACE) {
      puts("Leaving close_connection");
    }
    XSRETURN_UNDEF;
  }
}

SV *
delete_service(service_handle=&PL_sv_undef)
     SV *service_handle
   CODE:
{
  struct queue_entry *queue_entry;
  iosb iosb;

  if (DebugLevel & 255) {
    puts("Entering delete_service");
  }
  /* Close the association */
  sys$icc_close_assoc(SvIV(service_handle));

  /* Note that we're not accepting any more */
  accepting_connections = 0;

  /* Run through the connections we've got and disconnect them */
  lib$remqhi(queue_head, &queue_entry);
  while (queue_head != (long *)queue_entry) {
    sys$icc_disconnectw(queue_entry->conn_handle, &iosb);
    Safefree(queue_entry);
  }

  /* Note that the queue is empty */
  queue_count = 0;

  /* Mark the service as not in use */
  ServiceInUse = 0;

  if (DebugLevel & 255) {
    puts("Leaving delete_service");
  }
  /* return OK */
  XSRETURN_YES;
}

SV *
open_connection(assoc_name, node = &PL_sv_undef)
     SV *assoc_name
     SV *node
   PPCODE:
{
  struct dsc$descriptor_s AssocName, NodeName;
  struct dsc$descriptor_s *AssocNamePtr, *NodeNamePtr;
  int status;
  SV *return_sv;
  
  unsigned int ConnHandle;

  ios_icc IOS_ICC;

  if (DebugLevel & DEBUG_TRACE) {
    puts("Entering open_connection");
  }

  /* 'Kay, validate our stuff */
  if (!SvOK(assoc_name)) {
    if (DebugLevel & DEBUG_TRACE) {
      puts("Leaving open_connection");
    }
    croak("association name may not be undef");
  }
    
  /* If the name's undef, use the default name, otherwise fill in the */
  /* blanks appropriately */
  if (!SvOK(assoc_name)) {
    AssocNamePtr = NULL;
    if (DebugLevel & DEBUG_CHATTY) {
      printf("Assoc name: NULL\n");
    }
  } else {
    AssocName.dsc$b_dtype = DSC$K_DTYPE_T;
    AssocName.dsc$b_class = DSC$K_CLASS_S;
    AssocName.dsc$a_pointer = SvPV(assoc_name, PL_na);
    AssocName.dsc$w_length = SvCUR(assoc_name);
    AssocNamePtr = &AssocName;
    if (DebugLevel & DEBUG_CHATTY) {
      printf("Assoc name: %s\n", SvPV(assoc_name, PL_na));
    }
  }
    
  /* If the name's undef, use the default name, otherwise fill in the */
  /* blanks appropriately */
  if (!SvOK(node)) {
    NodeNamePtr = NULL;
    if (DebugLevel & DEBUG_CHATTY) {
      printf("Node name: NULL\n");
    }
  } else {
    NodeName.dsc$b_dtype = DSC$K_DTYPE_T;
    NodeName.dsc$b_class = DSC$K_CLASS_S;
    NodeName.dsc$a_pointer = SvPV(node, PL_na);
    NodeName.dsc$w_length = SvCUR(node);
    NodeNamePtr = &NodeName;
    if (DebugLevel & DEBUG_CHATTY) {
      printf("Node name: %s\n", SvPV(node, PL_na));
    }
  }

  status = sys$icc_connectw(&IOS_ICC, NULL, NULL,
			    ICC$C_DFLT_ASSOC_HANDLE, &ConnHandle,
			    AssocNamePtr, NodeNamePtr, 0, NULL, 0,
			    NULL, NULL, NULL, 0);
  if (DebugLevel & DEBUG_STATUS) {
    printf("sys$icc_connect returned %i\n", status);
  }
  if (SS$_NORMAL == status) {
    /* Hey, look--we got something. Pass it back. This counts on the */
    /* fact that a pointer will fit into the IV slot of an SV. This is */
    /* probably a bad, bad thing I'm doing here... */
    return_sv = sv_2mortal(newSViv(ConnHandle));
    XPUSHs(return_sv);
    if (DebugLevel & DEBUG_CHATTY) {
      printf("Connection opened was %i (%i)\n", ConnHandle,
	     SvIV(return_sv));
    }
    if (DebugLevel & DEBUG_TRACE) {
      puts("Leaving open_connection");
    }
    XSRETURN(1);
  } else {
    printf("Error %s\n", ss_translate(status));
    SETERRNO(EVMSERR, status);
    if (DebugLevel & DEBUG_TRACE) {
      puts("Leaving open_connection");
    }
    XSRETURN_UNDEF;
  }
  if (DebugLevel & DEBUG_TRACE) {
    puts("Leaving open_connection");
  }
}

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    