/* VMS::Queue - Get a list of Queues, or manage Queues
 *
 * Version: 0.01
 * Author:  Dan Sugalski <dan@sidhe.org>
 * Revised: 05-Dec-1997
 *
 *
 * Revision History:
 *
 * 0.01  05-Dec-1997 Dan Sugalski <dan@sidhe.org>
 *       Snagged this source from VMS::Process, and gutted appropriately.
 *
 */

#ifdef __cplusplus
extern "C" {
#endif
#include <starlet.h>
#include <descrip.h>
#include <prvdef.h>
#include <jpidef.h>
#include <uaidef.h>
#include <ssdef.h>
#include <stsdef.h>
#include <statedef.h>
#include <prcdef.h>
#include <pcbdef.h>
#include <pscandef.h>
#include <quidef.h>  
#include <jbcmsgdef.h>
#include <sjcdef.h>
  
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#ifdef __cplusplus
}
#endif

typedef union {
  struct {short   buflen,          /* Length of output buffer */
                  itmcode;         /* Item code */
          void    *buffer;         /* Buffer address */
          long    itemflags;       /* Item flags */
        } BufferItem;  /* Layout of buffer $PROCESS_SCAN item-list elements */
                
  struct {short   buflen,          /* Length of output buffer */
                  itmcode;         /* Item code */
          long    itemvalue;       /* Value for this item */ 
          long    itemflags;       /* flags for this item */
        } LiteralItem;  /* Layout of literal $PROCESS_SCAN item-list */
                        /* elements */
  struct {short   buflen,          /* Length of output buffer */
                  itmcode;         /* Item code */
          void    *buffer;         /* Buffer address */
          void    *retlen;         /* Return length address */
        } TradItem;  /* Layout of 'traditional' item-list elements */
} ITMLST;

typedef struct {int sts;     /* Returned status */
                int unused;  /* Unused by us */
              } iosb;

typedef struct {char  *ItemName;         /* Name of the item we're getting */
                unsigned short *ReturnLength; /* Pointer to the return */
                                              /* buffer length */
                void  *ReturnBuffer;     /* generic pointer to the returned */
                                         /* data */
                int   ReturnType;        /* The type of data in the return */
                                         /* buffer */
                int   ItemListEntry;     /* Index of the entry in the item */
                                         /* list we passed to GETJPI */
              } FetchedItem; /* Use this keep track of the items in the */
                             /* 'grab everything' system call */ 

#define bit_test(HVPointer, BitToCheck, HVEntryName, EncodedMask) \
{ \
    if ((EncodedMask) & (BitToCheck)) \
    hv_store((HVPointer), (HVEntryName), strlen((HVEntryName)), &PL_sv_yes, 0); \
    else \
    hv_store((HVPointer), (HVEntryName), strlen((HVEntryName)), &PL_sv_no, 0);}   

#define IS_STRING 1
#define IS_LONGWORD 2
#define IS_QUADWORD 3
#define IS_WORD 4
#define IS_BYTE 5
#define IS_VMSDATE 6
#define IS_BITMAP 7   /* Each bit in the return value indicates something */
#define IS_ENUM 8     /* Each returned value has a name, and we ought to */
                      /* return the name instead of the value */
#define IS_BOOL 9     /* This is a boolean item--its existence means true */

/* defines for input and/or output */
#define INPUT_INFO 1  /* The parameter's an input param for info reqests */
#define OUTPUT_INFO 2 /* The parameter's an output param for info requests */
#define INPUT_ACTION 4 /* The parameter's an input param for an action */
                       /* function */
#define OUTPUT_ACTION 8 /* The parameter's an output param for an action */
                        /* function */

/* defines to mark the system call parameters get passed to */
#define GETQUI_PARAM 1 /* The parameter goes to GETQUI */
#define SNDJBC_PARAM 2 /* The parameter goes to SNDJBC */

/* defines to mark the type of object (form, manager, queue, characteristic, */
/* or entry) the line's good for */
#define OBJECT_FORM (1<<0)
#define OBJECT_MANAGER (1<<1)
#define OBJECT_QUEUE (1<<2)
#define OBJECT_CHAR (1<<3)
#define OBJECT_ENTRY (1<<4)
#define OBJECT_FILE (1<<5)

/* Some defines to mark 'special' things about entries */
#define S_QUEUE_GENERIC  (1<<0)
#define S_QUEUE_BATCH    (1<<1)
#define S_QUEUE_PRINTER  (1<<2)
#define S_QUEUE_TERMINAL (1<<3)
#define S_QUEUE_SERVER   (1<<9)
#define S_QUEUE_ISAQUEUE (1<<10)       /* It's a queue of some sort */
#define S_QUEUE_OUTPUT   (S_QUEUE_PRINTER | S_QUEUE_TERMINAL)
#define S_QUEUE_ANY      (S_QUEUE_GENERIC | S_QUEUE_BATCH | S_QUEUE_PRINTER \
                          | S_QUEUE_TERMINAL | S_QUEUE_SERVER \
                          | S_QUEUE_ISAQUEUE)
#define S_ENTRY_BATCH    (1<<4)
#define S_ENTRY_PRINT    (1<<5)
#define S_ENTRY_DONE     (1<<6)
#define S_ENTRY_ANY      (S_ENTRY_BATCH | S_ENTRY_PRINT | S_ENTRY_DONE)
#define S_FORM_ANY       (1<<7)
#define S_FILE_ANY       (1<<8)
#define S_ANY             -1


/* Macro to create an entry in the array that associates string names with */
/* their QUI$_ values, along with lots of other info for it */
#define GETQUI_ENTRY(a, b, c, d, e, f) \
        {#a, QUI$_##a, 0, b, c, GETQUI_PARAM, \
           d, e, f}
#define SNDJBC_ENTRY(a, b, c, d, e, f) \
        {#a, 0, SJC$_##a, b, c, SNDJBC_PARAM, \
           d, e, f}
#define MIXED_ENTRY(a, b, c, d, e, f) \
        {#a, QUI$_##a, SJC$_##a, b, c, SNDJBC_PARAM | GETQUI_PARAM, \
           d, e, f}

/* Macro to expand out entries for generic_bitmap_encode */
#define BME_Q(a) { if (!strncmp(FlagName, #a, FlagLen)) { \
                       EncodedValue = EncodedValue | QUI$M_##a; \
                       break; \
                     } \
                 }
                     

   
/*#define QUI$M_ 0*/

struct MondoQueueInfoID {
  char *InfoName; /* Pointer to the item name */
  int  GetQUIValue;   /* Value to use for a GETQUI syscall */
  int  SndJBCValue;   /* Value to use for a SNDJBC syscall */
  int  BufferLen;     /* Length the return va buf needs to be. (no nul */
                      /* terminators, so must be careful with the return */
                      /* values. */
  int  ReturnType;    /* Type of data the item returns */
  int  SysCall;       /* What system call the item's to be used with */
  int  InOrOut;       /* Is it an input or an output parameter? */
  int  UseForObject;  /* Which object type this can be used for */
  int  SpecialFlags;  /* Subcategory for the item. (Used to restrict which */
                      /* items are being used for info calls, since bogus */
                      /* ones (like device name for batch queues) end up */
                      /* with invalid data) */
};

struct MondoQueueInfoID MondoQueueInfoList[] =
{
  GETQUI_ENTRY(ACCOUNT_NAME, 8, IS_STRING, OUTPUT_INFO,
              OBJECT_ENTRY, S_ANY),
  GETQUI_ENTRY(AFTER_TIME, 8, IS_VMSDATE, OUTPUT_INFO, OBJECT_ENTRY, S_ANY),
  GETQUI_ENTRY(ASSIGNED_QUEUE_NAME, 31, IS_STRING, OUTPUT_INFO,
               OBJECT_ENTRY | OBJECT_QUEUE, S_ANY),
  GETQUI_ENTRY(AUTOSTART_ON, 255, IS_STRING, OUTPUT_INFO, OBJECT_QUEUE,
               S_ANY),
  GETQUI_ENTRY(BASE_PRIORITY, 4, IS_LONGWORD, OUTPUT_INFO, OBJECT_QUEUE,
               S_ANY),
  GETQUI_ENTRY(CHARACTERISTIC_NAME, 31, IS_STRING, OUTPUT_INFO,
               OBJECT_CHAR, S_ANY),
  GETQUI_ENTRY(CHARACTERISTIC_NUMBER, 4, IS_LONGWORD, OUTPUT_INFO,
               OBJECT_CHAR, S_ANY),
/*  GETQUI_ENTRY(CHARACTERISTICS, 16, IS_BITMAP, OUTPUT_INFO,
               OBJECT_ENTRY | OBJECT_QUEUE, S_ANY),*/
  GETQUI_ENTRY(CHECKPOINT_DATA, 255, IS_STRING, OUTPUT_INFO,
               OBJECT_ENTRY, S_ENTRY_BATCH),
  GETQUI_ENTRY(CLI, 39, IS_STRING, OUTPUT_INFO, OBJECT_ENTRY,
               S_ENTRY_BATCH),
  GETQUI_ENTRY(COMPLETED_BLOCKS, 4, IS_LONGWORD, OUTPUT_INFO,
               OBJECT_ENTRY, S_QUEUE_OUTPUT),
  GETQUI_ENTRY(CONDITION_VECTOR, 4, IS_LONGWORD, OUTPUT_INFO,
               OBJECT_ENTRY, S_ANY),
  GETQUI_ENTRY(CPU_DEFAULT, 4, IS_LONGWORD, OUTPUT_INFO, OBJECT_QUEUE,
               S_QUEUE_BATCH),
  GETQUI_ENTRY(CPU_LIMIT, 4, IS_LONGWORD, OUTPUT_INFO,
               OBJECT_QUEUE | OBJECT_ENTRY,
               S_QUEUE_BATCH | S_ENTRY_BATCH),
  GETQUI_ENTRY(DEFAULT_FORM_NAME, 31, IS_STRING, OUTPUT_INFO,
               OBJECT_QUEUE, S_QUEUE_OUTPUT), 
  GETQUI_ENTRY(DEFAULT_FORM_STOCK, 31, IS_STRING, OUTPUT_INFO,
               OBJECT_QUEUE, S_QUEUE_OUTPUT), 
  GETQUI_ENTRY(DEVICE_NAME, 31, IS_STRING, OUTPUT_INFO, OBJECT_QUEUE,
               S_QUEUE_OUTPUT),
  GETQUI_ENTRY(ENTRY_NUMBER, 4, IS_LONGWORD, OUTPUT_INFO, OBJECT_ENTRY,
               S_ANY),
  GETQUI_ENTRY(EXECUTING_JOB_COUNT, 4, IS_LONGWORD, OUTPUT_INFO,
               OBJECT_QUEUE, S_ANY),
  GETQUI_ENTRY(FILE_COPIES, 4, IS_LONGWORD, OUTPUT_INFO, OBJECT_FILE,
               S_ANY),
  GETQUI_ENTRY(FILE_COPIES_DONE, 4, IS_LONGWORD, OUTPUT_INFO, OBJECT_FILE,
               S_ANY),
  GETQUI_ENTRY(FILE_COUNT, 4, IS_LONGWORD, OUTPUT_INFO, OBJECT_ENTRY,
               S_ANY),
  GETQUI_ENTRY(FILE_FLAGS, 4, IS_BITMAP, OUTPUT_INFO, OBJECT_FILE,
               S_ANY),
  GETQUI_ENTRY(FILE_IDENTIFICATION, 28, IS_STRING, OUTPUT_INFO, OBJECT_FILE,
               S_ANY),
  GETQUI_ENTRY(FILE_SETUP_MODULES, 255, IS_STRING, OUTPUT_INFO, OBJECT_FILE,
               S_ANY),
  GETQUI_ENTRY(FILE_SPECIFICATION, 255, IS_STRING, OUTPUT_INFO, OBJECT_FILE,
               S_ANY),
  GETQUI_ENTRY(FILE_STATUS, 4, IS_BITMAP, OUTPUT_INFO, OBJECT_FILE,
               S_ANY),
  GETQUI_ENTRY(FIRST_PAGE, 4, IS_LONGWORD, OUTPUT_INFO, OBJECT_FILE,
               S_ANY),
  GETQUI_ENTRY(FORM_DESCRIPTION, 255, IS_STRING, OUTPUT_INFO, OBJECT_FORM,
               S_ANY),
  GETQUI_ENTRY(FORM_FLAGS, 4, IS_BITMAP, OUTPUT_INFO, OBJECT_FORM, S_ANY),
  GETQUI_ENTRY(FORM_LENGTH, 4, IS_LONGWORD, OUTPUT_INFO, OBJECT_FORM,
               S_ANY),
  GETQUI_ENTRY(FORM_MARGIN_BOTTOM, 4, IS_LONGWORD, OUTPUT_INFO,
               OBJECT_FORM, S_ANY),
  GETQUI_ENTRY(FORM_MARGIN_LEFT, 4, IS_LONGWORD, OUTPUT_INFO,
               OBJECT_FORM, S_ANY),
  GETQUI_ENTRY(FORM_MARGIN_RIGHT, 4, IS_LONGWORD, OUTPUT_INFO,
               OBJECT_FORM, S_ANY),
  GETQUI_ENTRY(FORM_MARGIN_TOP, 4, IS_LONGWORD, OUTPUT_INFO,
               OBJECT_FORM, S_ANY),
  GETQUI_ENTRY(FORM_NAME, 31, IS_STRING, OUTPUT_INFO,
               OBJECT_FORM | OBJECT_ENTRY | OBJECT_QUEUE,
               S_QUEUE_OUTPUT | S_ENTRY_PRINT | S_FORM_ANY),
  GETQUI_ENTRY(FORM_NUMBER, 4, IS_LONGWORD, OUTPUT_INFO,
               OBJECT_FORM, S_ANY),
  GETQUI_ENTRY(FORM_SETUP_MODULES, 256, IS_STRING, OUTPUT_INFO,
               OBJECT_FORM, S_ANY),
  GETQUI_ENTRY(FORM_STOCK, 31, IS_STRING, OUTPUT_INFO,
               OBJECT_FORM | OBJECT_ENTRY | OBJECT_QUEUE,
               S_QUEUE_OUTPUT | S_ENTRY_PRINT | S_FORM_ANY),
  GETQUI_ENTRY(FORM_WIDTH, 4, IS_LONGWORD, OUTPUT_INFO,
               OBJECT_FORM, S_ANY),
  GETQUI_ENTRY(GENERIC_TARGET, 3968, IS_STRING, OUTPUT_INFO, OBJECT_QUEUE,
               S_QUEUE_GENERIC),
  GETQUI_ENTRY(HOLDING_JOB_COUNT, 4, IS_LONGWORD, OUTPUT_INFO,
               OBJECT_QUEUE, S_ANY),
  GETQUI_ENTRY(JOB_COMPLETION_QUEUE, 31, IS_STRING, OUTPUT_INFO,
               OBJECT_ENTRY, S_ENTRY_DONE),
  GETQUI_ENTRY(JOB_COMPLETION_TIME, 8, IS_VMSDATE, OUTPUT_INFO,
               OBJECT_ENTRY, S_ENTRY_DONE),
  GETQUI_ENTRY(JOB_COPIES, 4, IS_LONGWORD, OUTPUT_INFO, OBJECT_ENTRY,
               S_ENTRY_PRINT),
  GETQUI_ENTRY(JOB_COPIES_DONE, 4, IS_LONGWORD, OUTPUT_INFO, OBJECT_ENTRY,
               S_ENTRY_PRINT),
  GETQUI_ENTRY(JOB_FLAGS, 4, IS_BITMAP, OUTPUT_INFO, OBJECT_ENTRY, S_ANY),
  GETQUI_ENTRY(JOB_LIMIT, 4, IS_LONGWORD, OUTPUT_INFO, OBJECT_QUEUE, S_ANY),
  GETQUI_ENTRY(JOB_NAME, 39, IS_STRING, OUTPUT_INFO, OBJECT_ENTRY, S_ANY),
  GETQUI_ENTRY(JOB_PID, 4, IS_LONGWORD, OUTPUT_INFO, OBJECT_ENTRY,
               S_ENTRY_BATCH),
  GETQUI_ENTRY(JOB_RESET_MODULES, 256, IS_STRING, OUTPUT_INFO,
               OBJECT_QUEUE, S_QUEUE_OUTPUT),
  GETQUI_ENTRY(JOB_RETENTION_TIME, 8, IS_VMSDATE, OUTPUT_INFO,
               OBJECT_ENTRY, S_ANY),
  GETQUI_ENTRY(JOB_SIZE, 4, IS_LONGWORD, OUTPUT_INFO, OBJECT_ENTRY,
               S_ENTRY_PRINT),
  GETQUI_ENTRY(JOB_SIZE_MAXIMUM, 4, IS_LONGWORD, OUTPUT_INFO, OBJECT_QUEUE,
               S_QUEUE_OUTPUT),
  GETQUI_ENTRY(JOB_SIZE_MINIMUM, 4, IS_LONGWORD, OUTPUT_INFO, OBJECT_QUEUE,
               S_QUEUE_OUTPUT),
  GETQUI_ENTRY(JOB_STATUS, 4, IS_BITMAP, OUTPUT_INFO, OBJECT_ENTRY, S_ANY),
  GETQUI_ENTRY(LAST_PAGE, 4, IS_LONGWORD, OUTPUT_INFO, OBJECT_FILE,
               S_ANY),
  GETQUI_ENTRY(LIBRARY_SPECIFICATION, 39, IS_STRING, OUTPUT_INFO,
               OBJECT_QUEUE, S_QUEUE_OUTPUT),
  GETQUI_ENTRY(LOG_QUEUE, 31, IS_STRING, OUTPUT_INFO, OBJECT_ENTRY,
               S_ENTRY_BATCH),
  GETQUI_ENTRY(LOG_SPECIFICATION, 255, IS_STRING, OUTPUT_INFO,
               OBJECT_ENTRY, S_ENTRY_BATCH),
  GETQUI_ENTRY(MANAGER_NAME, 31, IS_STRING, OUTPUT_INFO, OBJECT_MANAGER,
               S_ANY),
  GETQUI_ENTRY(MANAGER_NODES, 256, IS_STRING, OUTPUT_INFO, OBJECT_MANAGER,
               S_ANY),
  GETQUI_ENTRY(MANAGER_STATUS, 4, IS_BITMAP, OUTPUT_INFO, OBJECT_MANAGER,
               S_ANY),
  GETQUI_ENTRY(NOTE, 255, IS_STRING, OUTPUT_INFO, OBJECT_ENTRY, S_ANY),
  GETQUI_ENTRY(OPERATOR_REQUEST, 255, IS_STRING, OUTPUT_INFO,
               OBJECT_ENTRY, S_ENTRY_PRINT),
  GETQUI_ENTRY(OWNER_UIC, 4, IS_LONGWORD, OUTPUT_INFO, OBJECT_QUEUE, S_ANY),
  GETQUI_ENTRY(PAGE_SETUP_MODULES, 256, IS_STRING, OUTPUT_INFO,
               OBJECT_FORM, S_ANY),
  GETQUI_ENTRY(PARAMETER_1, 255, IS_STRING, OUTPUT_INFO, OBJECT_ENTRY,
               S_ENTRY_BATCH),
  GETQUI_ENTRY(PARAMETER_2, 255, IS_STRING, OUTPUT_INFO, OBJECT_ENTRY,
               S_ENTRY_BATCH),
  GETQUI_ENTRY(PARAMETER_3, 255, IS_STRING, OUTPUT_INFO, OBJECT_ENTRY,
               S_ENTRY_BATCH),
  GETQUI_ENTRY(PARAMETER_4, 255, IS_STRING, OUTPUT_INFO, OBJECT_ENTRY,
               S_ENTRY_BATCH),
  GETQUI_ENTRY(PARAMETER_5, 255, IS_STRING, OUTPUT_INFO, OBJECT_ENTRY,
               S_ENTRY_BATCH),
  GETQUI_ENTRY(PARAMETER_6, 255, IS_STRING, OUTPUT_INFO, OBJECT_ENTRY,
               S_ENTRY_BATCH),
  GETQUI_ENTRY(PARAMETER_7, 255, IS_STRING, OUTPUT_INFO, OBJECT_ENTRY,
               S_ENTRY_BATCH),
  GETQUI_ENTRY(PARAMETER_8, 255, IS_STRING, OUTPUT_INFO, OBJECT_ENTRY,
               S_ENTRY_BATCH),
  GETQUI_ENTRY(PENDING_JOB_BLOCK_COUNT, 4, IS_LONGWORD, OUTPUT_INFO,
               OBJECT_QUEUE, S_QUEUE_OUTPUT),
  GETQUI_ENTRY(PENDING_JOB_COUNT, 4, IS_LONGWORD, OUTPUT_INFO,
               OBJECT_QUEUE, S_ANY),
  GETQUI_ENTRY(PENDING_JOB_REASON, 4, IS_BITMAP, OUTPUT_INFO,
               OBJECT_ENTRY, S_ANY),
  GETQUI_ENTRY(PRIORITY, 4, IS_LONGWORD, OUTPUT_INFO, OBJECT_ENTRY, S_ANY),
  GETQUI_ENTRY(PROCESSOR, 39, IS_STRING, OUTPUT_INFO, OBJECT_QUEUE |
               OBJECT_ENTRY, S_QUEUE_OUTPUT | S_ENTRY_PRINT),
  GETQUI_ENTRY(PROTECTION, 4, IS_BITMAP, OUTPUT_INFO, OBJECT_QUEUE, S_ANY),
  GETQUI_ENTRY(QUEUE_DESCRIPTION, 255, IS_STRING, OUTPUT_INFO,
               OBJECT_QUEUE, S_ANY),
  GETQUI_ENTRY(QUEUE_DIRECTORY, 255, IS_STRING, OUTPUT_INFO,
               OBJECT_MANAGER, S_ANY),
  GETQUI_ENTRY(QUEUE_FLAGS, 4, IS_BITMAP, OUTPUT_INFO, OBJECT_ENTRY |
               OBJECT_QUEUE, S_ANY),
  GETQUI_ENTRY(QUEUE_NAME, 31, IS_STRING, OUTPUT_INFO, OBJECT_QUEUE |
               OBJECT_ENTRY, S_ANY),
  GETQUI_ENTRY(QUEUE_STATUS, 4, IS_BITMAP, OUTPUT_INFO, OBJECT_ENTRY |
               OBJECT_QUEUE, S_ANY),
  GETQUI_ENTRY(REQUEUE_QUEUE_NAME, 31, IS_STRING, OUTPUT_INFO,
               OBJECT_ENTRY, S_ANY),
  GETQUI_ENTRY(RESTART_QUEUE_NAME, 31, IS_STRING, OUTPUT_INFO,
               OBJECT_ENTRY, S_ANY),
  GETQUI_ENTRY(RETAINED_JOB_COUNT, 4, IS_STRING, OUTPUT_INFO,
               OBJECT_QUEUE, S_ANY),
  GETQUI_ENTRY(SCSNODE_NAME, 6, IS_STRING, OUTPUT_INFO, OBJECT_MANAGER |
               OBJECT_QUEUE, S_ANY),
  GETQUI_ENTRY(SEARCH_JOB_NAME, 39, IS_STRING, INPUT_INFO, OBJECT_ENTRY,
               S_ANY),
  GETQUI_ENTRY(SEARCH_NAME, 31, IS_STRING, INPUT_INFO, OBJECT_QUEUE |
               OBJECT_MANAGER | OBJECT_FORM | OBJECT_CHAR, S_ANY),
  GETQUI_ENTRY(SEARCH_FLAGS, 4, IS_BITMAP, INPUT_INFO, 
               OBJECT_QUEUE | OBJECT_MANAGER | OBJECT_FORM | OBJECT_CHAR |
               OBJECT_ENTRY, S_ANY),
  GETQUI_ENTRY(SEARCH_NUMBER, 4, IS_LONGWORD, INPUT_INFO, OBJECT_CHAR |
               OBJECT_ENTRY | OBJECT_FORM, S_ANY),
  GETQUI_ENTRY(SEARCH_USERNAME, 12, IS_STRING, INPUT_INFO, OBJECT_ENTRY,
               S_ANY),
  GETQUI_ENTRY(SUBMISSION_TIME, 8, IS_VMSDATE, OUTPUT_INFO, OBJECT_ENTRY,
               S_ANY),
  GETQUI_ENTRY(TIMED_RELEASE_JOB_COUNT, 4, IS_LONGWORD, OUTPUT_INFO,
               OBJECT_QUEUE, S_ANY),
  GETQUI_ENTRY(UIC, 4, IS_LONGWORD, OUTPUT_INFO, OBJECT_ENTRY, S_ANY),
  GETQUI_ENTRY(USERNAME, 12, IS_STRING, OUTPUT_INFO, OBJECT_ENTRY, S_ANY),
  GETQUI_ENTRY(WSDEFAULT, 4, IS_LONGWORD, OUTPUT_INFO, OBJECT_ENTRY |
               OBJECT_QUEUE, S_ENTRY_BATCH | S_QUEUE_BATCH),
  GETQUI_ENTRY(WSEXTENT, 4, IS_LONGWORD, OUTPUT_INFO, OBJECT_ENTRY |
               OBJECT_QUEUE, S_ENTRY_BATCH | S_QUEUE_BATCH),
  GETQUI_ENTRY(WSQUOTA, 4, IS_LONGWORD, OUTPUT_INFO, OBJECT_ENTRY |
               OBJECT_QUEUE, S_ENTRY_BATCH | S_QUEUE_BATCH),
/* Stuff for SNDJBC */
  SNDJBC_ENTRY(ACCOUNT_NAME, 8, IS_STRING, INPUT_ACTION, OBJECT_ENTRY, S_ANY),
  SNDJBC_ENTRY(AFTER_TIME, 8, IS_VMSDATE, INPUT_ACTION, OBJECT_ENTRY, S_ANY),
  SNDJBC_ENTRY(NO_AFTER_TIME, 4, IS_BOOL, INPUT_ACTION, OBJECT_ENTRY, S_ANY),
  SNDJBC_ENTRY(AUTOSTART_ON, 16, IS_STRING, INPUT_ACTION, OBJECT_QUEUE, S_ANY),
  SNDJBC_ENTRY(BASE_PRIORITY, 4, IS_LONGWORD, INPUT_ACTION, OBJECT_QUEUE,
               S_ANY),
  SNDJBC_ENTRY(BATCH, 4, IS_BOOL, INPUT_ACTION, OBJECT_QUEUE, S_ANY),
  SNDJBC_ENTRY(NO_BATCH, 4, IS_BOOL, INPUT_ACTION, OBJECT_QUEUE, S_ANY),
  SNDJBC_ENTRY(CHARACTERISTIC_NAME, 255, IS_STRING, INPUT_ACTION,
               OBJECT_QUEUE | OBJECT_ENTRY | OBJECT_CHAR, S_ANY),
  SNDJBC_ENTRY(CHARACTERISTIC_NUMBER, 4, IS_LONGWORD, INPUT_ACTION,
               OBJECT_QUEUE | OBJECT_ENTRY | OBJECT_CHAR, S_ANY),
  SNDJBC_ENTRY(NO_CHARACTERISTICS, 4, IS_BOOL, INPUT_ACTION, OBJECT_QUEUE |
               OBJECT_ENTRY | OBJECT_CHAR, S_ANY),
  SNDJBC_ENTRY(CLI, 39, IS_STRING, INPUT_ACTION, OBJECT_ENTRY, S_ANY),
  SNDJBC_ENTRY(NO_CLI, 4, IS_BOOL, INPUT_ACTION, OBJECT_ENTRY, S_ANY),
  SNDJBC_ENTRY(CLOSE_QUEUE, 4, IS_BOOL, INPUT_ACTION, OBJECT_QUEUE, S_ANY),
  SNDJBC_ENTRY(CPU_DEFAULT, 4, IS_BOOL, INPUT_ACTION, OBJECT_QUEUE, S_ANY),
  SNDJBC_ENTRY(NO_CPU_DEFAULT, 4, IS_BOOL, INPUT_ACTION, OBJECT_QUEUE, S_ANY),
  SNDJBC_ENTRY(CPU_LIMIT, 4, IS_BOOL, INPUT_ACTION, OBJECT_QUEUE |
               OBJECT_ENTRY, S_ANY),
  SNDJBC_ENTRY(NO_CPU_LIMIT, 4, IS_BOOL, INPUT_ACTION, OBJECT_QUEUE |
               OBJECT_ENTRY, S_ANY),
  SNDJBC_ENTRY(CREATE_START, 4, IS_BOOL, INPUT_ACTION, OBJECT_QUEUE, S_ANY),
  SNDJBC_ENTRY(DEFAULT_FORM_NAME, 31, IS_STRING, INPUT_ACTION,
               OBJECT_QUEUE, S_ANY),
  SNDJBC_ENTRY(DEFAULT_FORM_NUMBER, 4, IS_LONGWORD, INPUT_ACTION,
               OBJECT_QUEUE, S_ANY),
  SNDJBC_ENTRY(DELETE_FILE, 4, IS_BOOL, INPUT_ACTION, OBJECT_FILE, S_ANY),
  SNDJBC_ENTRY(NO_DELETE_FILE, 4, IS_BOOL, INPUT_ACTION, OBJECT_FILE, S_ANY),
  SNDJBC_ENTRY(DESTINATION_QUEUE, 31, IS_STRING, INPUT_ACTION,
               OBJECT_ENTRY, S_ANY),
  SNDJBC_ENTRY(DEVICE_NAME, 31, IS_STRING, INPUT_ACTION, OBJECT_QUEUE, S_ANY),
  SNDJBC_ENTRY(DOUBLE_SPACE, 4, IS_BOOL, INPUT_ACTION, OBJECT_ENTRY |
               OBJECT_FILE, S_ANY),
  SNDJBC_ENTRY(NO_DOUBLE_SPACE, 4, IS_BOOL, INPUT_ACTION, OBJECT_ENTRY |
               OBJECT_FILE, S_ANY),
  SNDJBC_ENTRY(ENTRY_NUMBER, 4, IS_LONGWORD, INPUT_ACTION, OBJECT_ENTRY,
               S_ANY),
  SNDJBC_ENTRY(FILE_BURST, 4, IS_BOOL, INPUT_ACTION, OBJECT_ENTRY |
               OBJECT_QUEUE, S_ANY),
  SNDJBC_ENTRY(NO_FILE_BURST, 4, IS_BOOL, INPUT_ACTION, OBJECT_ENTRY |
               OBJECT_QUEUE, S_ANY),
  SNDJBC_ENTRY(FILE_BURST_ONE, 4, IS_BOOL, INPUT_ACTION, OBJECT_QUEUE, S_ANY),
  SNDJBC_ENTRY(FILE_COPIES, 4, IS_LONGWORD, INPUT_ACTION, OBJECT_FILE |
               OBJECT_ENTRY, S_ANY),
  SNDJBC_ENTRY(FILE_FLAG, 4, IS_BOOL, INPUT_ACTION, OBJECT_QUEUE |
               OBJECT_FILE | OBJECT_ENTRY, S_ANY),
  SNDJBC_ENTRY(NO_FILE_FLAG, 4, IS_BOOL, INPUT_ACTION, OBJECT_QUEUE |
               OBJECT_FILE | OBJECT_ENTRY, S_ANY),
  SNDJBC_ENTRY(FILE_FLAG_ONE, 4, IS_BOOL, INPUT_ACTION, OBJECT_QUEUE |
               OBJECT_ENTRY, S_ANY),
  SNDJBC_ENTRY(FILE_IDENTIFICATION, 28, IS_STRING, INPUT_ACTION,
               OBJECT_FILE, S_ANY),
  SNDJBC_ENTRY(FILE_SETUP_MODULES, 255, IS_STRING, INPUT_ACTION,
               OBJECT_FILE | OBJECT_ENTRY, S_ANY),
  SNDJBC_ENTRY(NO_FILE_SETUP_MODULES, 4, IS_BOOL, INPUT_ACTION,
               OBJECT_FILE | OBJECT_ENTRY, S_ANY),
  SNDJBC_ENTRY(FILE_SPECIFICATION, 255, IS_STRING, INPUT_ACTION,
               OBJECT_FILE, S_ANY),
  SNDJBC_ENTRY(FILE_TRAILER, 4, IS_BOOL, INPUT_ACTION, OBJECT_QUEUE |
               OBJECT_FILE | OBJECT_ENTRY, S_ANY),
  SNDJBC_ENTRY(NO_FILE_TRAILER, 4, IS_BOOL, INPUT_ACTION, OBJECT_QUEUE |
               OBJECT_FILE | OBJECT_ENTRY, S_ANY),
  SNDJBC_ENTRY(FILE_TRAILER_ONE, 4, IS_BOOL, INPUT_ACTION, OBJECT_QUEUE |
               OBJECT_ENTRY, S_ANY),
  SNDJBC_ENTRY(FIRST_PAGE, 4, IS_LONGWORD, INPUT_ACTION, OBJECT_ENTRY |
               OBJECT_FILE, S_ANY),
  SNDJBC_ENTRY(NO_FIRST_PAGE, 4, IS_BOOL, INPUT_ACTION, OBJECT_ENTRY |
               OBJECT_FILE, S_ANY),
  SNDJBC_ENTRY(FORM_DESCRIPTION, 255, IS_STRING, INPUT_ACTION, OBJECT_FORM,
               S_ANY),
  SNDJBC_ENTRY(FORM_LENGTH, 4, IS_LONGWORD, INPUT_ACTION, OBJECT_FORM, S_ANY),
  SNDJBC_ENTRY(FORM_MARGIN_BOTTOM, 4, IS_LONGWORD, INPUT_ACTION,
               OBJECT_FORM, S_ANY),
  SNDJBC_ENTRY(FORM_MARGIN_LEFT, 4, IS_LONGWORD, INPUT_ACTION,
               OBJECT_FORM, S_ANY),
  SNDJBC_ENTRY(FORM_MARGIN_RIGHT, 4, IS_LONGWORD, INPUT_ACTION,
               OBJECT_FORM, S_ANY),
  SNDJBC_ENTRY(FORM_MARGIN_TOP, 4, IS_LONGWORD, INPUT_ACTION,
               OBJECT_FORM, S_ANY),
  SNDJBC_ENTRY(FORM_NAME, 31, IS_STRING, INPUT_ACTION, OBJECT_FORM |
               OBJECT_ENTRY | OBJECT_QUEUE, S_ANY),
  SNDJBC_ENTRY(FORM_NUMBER, 4, IS_LONGWORD, INPUT_ACTION, OBJECT_FORM |
               OBJECT_ENTRY | OBJECT_QUEUE, S_ANY),
  SNDJBC_ENTRY(FORM_SETUP_MODULES, 255, IS_STRING, INPUT_ACTION,
               OBJECT_FORM, S_ANY),
  SNDJBC_ENTRY(NO_FORM_SETUP_MODULES, 4, IS_BOOL, INPUT_ACTION,
               OBJECT_FORM, S_ANY),
  SNDJBC_ENTRY(FORM_SHEET_FEED, 4, IS_BOOL, INPUT_ACTION, OBJECT_FORM, S_ANY),
  SNDJBC_ENTRY(NO_FORM_SHEET_FEED, 4, IS_BOOL, INPUT_ACTION, OBJECT_FORM,
               S_ANY),
  SNDJBC_ENTRY(FORM_STOCK, 31, IS_STRING, INPUT_ACTION, OBJECT_FORM, S_ANY),
  SNDJBC_ENTRY(FORM_TRUNCATE, 4, IS_BOOL, INPUT_ACTION, OBJECT_FORM, S_ANY),
  SNDJBC_ENTRY(NO_FORM_TRUNCATE, 4, IS_BOOL, INPUT_ACTION, OBJECT_FORM,
               S_ANY),
  SNDJBC_ENTRY(FORM_WIDTH, 4, IS_LONGWORD, INPUT_ACTION, OBJECT_FORM, S_ANY),
  SNDJBC_ENTRY(FORM_WRAP, 4, IS_BOOL, INPUT_ACTION, OBJECT_FORM, S_ANY),
  SNDJBC_ENTRY(NO_FORM_WRAP, 4, IS_BOOL, INPUT_ACTION, OBJECT_FORM, S_ANY),
  SNDJBC_ENTRY(GENERIC_QUEUE, 4, IS_BOOL, INPUT_ACTION, OBJECT_QUEUE, S_ANY),
  SNDJBC_ENTRY(NO_GENERIC_QUEUE, 4, IS_BOOL, INPUT_ACTION, OBJECT_QUEUE,
               S_ANY),
  SNDJBC_ENTRY(GENERIC_SELECTION, 4, IS_BOOL, INPUT_ACTION, OBJECT_QUEUE,
               S_ANY),
  SNDJBC_ENTRY(NO_GENERIC_SELECTION, 4, IS_BOOL, INPUT_ACTION,
               OBJECT_QUEUE, S_ANY),
  SNDJBC_ENTRY(HOLD, 4, IS_BOOL, INPUT_ACTION, OBJECT_ENTRY, S_ANY),
  SNDJBC_ENTRY(JOB_BURST, 4, IS_BOOL, INPUT_ACTION, OBJECT_QUEUE, S_ANY),
  SNDJBC_ENTRY(NO_JOB_BURST, 4, IS_BOOL, INPUT_ACTION, OBJECT_QUEUE,
               S_ANY),
  SNDJBC_ENTRY(JOB_COPIES, 4, IS_LONGWORD, INPUT_ACTION, OBJECT_ENTRY,
               S_ANY ),
  SNDJBC_ENTRY(JOB_DEFAULT_RETAIN, 4, IS_BOOL, INPUT_ACTION, OBJECT_ENTRY,
               S_ANY),
  SNDJBC_ENTRY(JOB_ERROR_RETAIN, 4, IS_BOOL, INPUT_ACTION, OBJECT_ENTRY,
               S_ANY),
  SNDJBC_ENTRY(JOB_FLAG, 4, IS_BOOL, INPUT_ACTION, OBJECT_QUEUE, S_ANY),
  SNDJBC_ENTRY(NO_JOB_FLAG, 4, IS_BOOL, INPUT_ACTION, OBJECT_QUEUE, S_ANY),
  SNDJBC_ENTRY(JOB_LIMIT, 4, IS_LONGWORD, INPUT_ACTION, OBJECT_QUEUE,
               S_ANY),
  SNDJBC_ENTRY(JOB_NAME, 39, IS_STRING, INPUT_ACTION, OBJECT_ENTRY, S_ANY),
  SNDJBC_ENTRY(JOB_RESET_MODULES, 255, IS_STRING, INPUT_ACTION,
               OBJECT_QUEUE, S_ANY),
  SNDJBC_ENTRY(NO_JOB_RESET_MODULES, 4, IS_BOOL, INPUT_ACTION,
               OBJECT_QUEUE, S_ANY),
  SNDJBC_ENTRY(JOB_RETAIN, 4, IS_BOOL, INPUT_ACTION, OBJECT_ENTRY, S_ANY),
  SNDJBC_ENTRY(JOB_RETAIN_TIME, 8, IS_VMSDATE, INPUT_ACTION, OBJECT_ENTRY,
               S_ANY),
  SNDJBC_ENTRY(JOB_SIZE_MAXIMUM, 4, IS_LONGWORD, INPUT_ACTION,
               OBJECT_QUEUE, S_ANY),
  SNDJBC_ENTRY(NO_JOB_SIZE_MAXIMUM, 4, IS_BOOL, INPUT_ACTION, OBJECT_QUEUE,
               S_ANY),
  SNDJBC_ENTRY(JOB_SIZE_MINIMUM, 4, IS_LONGWORD, INPUT_ACTION,
               OBJECT_QUEUE, S_ANY),
  SNDJBC_ENTRY(NO_JOB_SIZE_MINIMUM, 4, IS_BOOL, INPUT_ACTION, OBJECT_QUEUE,
               S_ANY),
  SNDJBC_ENTRY(JOB_SIZE_SCHEDULING, 4, IS_BOOL, INPUT_ACTION,
               OBJECT_QUEUE, S_ANY),
  SNDJBC_ENTRY(NO_JOB_SIZE_SCHEDULING, 4, IS_BOOL, INPUT_ACTION, OBJECT_QUEUE,
               S_ANY),
  SNDJBC_ENTRY(JOB_TRAILER, 4, IS_BOOL, INPUT_ACTION, OBJECT_QUEUE, S_ANY),
  SNDJBC_ENTRY(NO_JOB_TRAILER, 4, IS_BOOL, INPUT_ACTION, OBJECT_QUEUE,
               S_ANY),
  SNDJBC_ENTRY(LAST_PAGE, 4, IS_LONGWORD, INPUT_ACTION, OBJECT_ENTRY,
               S_ANY),
  SNDJBC_ENTRY(NO_LAST_PAGE, 4, IS_LONGWORD, INPUT_ACTION, OBJECT_ENTRY,
               S_ANY),
  SNDJBC_ENTRY(LIBRARY_SPECIFICATION, 39, IS_STRING, INPUT_ACTION,
               OBJECT_QUEUE, S_ANY),
  SNDJBC_ENTRY(NO_LIBRARY_SPECIFICATION, 4, IS_BOOL, INPUT_ACTION,
               OBJECT_QUEUE, S_ANY),
  SNDJBC_ENTRY(LOG_DELETE, 4, IS_BOOL, INPUT_ACTION, OBJECT_ENTRY, S_ANY),
  SNDJBC_ENTRY(NO_LOG_DELETE, 4, IS_BOOL, INPUT_ACTION, OBJECT_ENTRY, S_ANY),
  SNDJBC_ENTRY(LOG_QUEUE, 31, IS_STRING, INPUT_ACTION, OBJECT_ENTRY, S_ANY),
  SNDJBC_ENTRY(LOG_SPECIFICATION, 255, IS_STRING, INPUT_ACTION,
               OBJECT_ENTRY, S_ANY),
  SNDJBC_ENTRY(NO_LOG_SPECIFICATION, 4, IS_BOOL, INPUT_ACTION,
               OBJECT_ENTRY, S_ANY),
  SNDJBC_ENTRY(LOG_SPOOL, 4, IS_BOOL, INPUT_ACTION, OBJECT_ENTRY, S_ANY),
  SNDJBC_ENTRY(NO_LOG_SPOOL, 4, IS_BOOL, INPUT_ACTION, OBJECT_ENTRY, S_ANY),
  SNDJBC_ENTRY(LOWERCASE, 4, IS_BOOL, INPUT_ACTION, OBJECT_ENTRY, S_ANY),
  SNDJBC_ENTRY(NO_LOWERCASE, 4, IS_BOOL, INPUT_ACTION, OBJECT_ENTRY, S_ANY),
  SNDJBC_ENTRY(NEXT_JOB, 4, IS_BOOL, INPUT_ACTION, OBJECT_QUEUE, S_ANY),
  SNDJBC_ENTRY(NOTE, 255, IS_STRING, INPUT_ACTION, OBJECT_ENTRY, S_ANY),
  SNDJBC_ENTRY(NO_NOTE, 4, IS_BOOL, INPUT_ACTION, OBJECT_ENTRY, S_ANY),
  SNDJBC_ENTRY(NOTIFY, 255, IS_STRING, INPUT_ACTION, OBJECT_ENTRY, S_ANY),
  SNDJBC_ENTRY(NO_NOTIFY, 4, IS_BOOL, INPUT_ACTION, OBJECT_ENTRY, S_ANY),
  SNDJBC_ENTRY(OPEN_QUEUE, 4, IS_BOOL, INPUT_ACTION, OBJECT_QUEUE, S_ANY),
  SNDJBC_ENTRY(OPERATOR_REQUEST, 255, IS_STRING, INPUT_ACTION,
               OBJECT_ENTRY, S_ANY),
  SNDJBC_ENTRY(NO_OPERATOR_REQUEST, 4, IS_BOOL, INPUT_ACTION, OBJECT_ENTRY,
               S_ANY),
  SNDJBC_ENTRY(OWNER_UIC, 4, IS_LONGWORD, INPUT_ACTION, OBJECT_QUEUE,
               S_ANY),
  SNDJBC_ENTRY(PAGE_HEADER, 4, IS_BOOL, INPUT_ACTION, OBJECT_QUEUE, S_ANY),
  SNDJBC_ENTRY(NO_PAGE_HEADER, 4, IS_BOOL, INPUT_ACTION, OBJECT_QUEUE,
               S_ANY),
  SNDJBC_ENTRY(PAGE_SETUP_MODULES, 255, IS_STRING, INPUT_ACTION,
               OBJECT_FORM, S_ANY),
  SNDJBC_ENTRY(NO_PAGE_SETUP_MODULES, 4, IS_BOOL, INPUT_ACTION,
               OBJECT_FORM, S_ANY),
  SNDJBC_ENTRY(PAGINATE, 4, IS_BOOL, INPUT_ACTION, OBJECT_ENTRY |
               OBJECT_QUEUE, S_ANY),
  SNDJBC_ENTRY(NO_PAGINATE, 4, IS_BOOL, INPUT_ACTION, OBJECT_ENTRY |
               OBJECT_QUEUE, S_ANY),
  SNDJBC_ENTRY(PARAMETER_1, 255, IS_STRING, INPUT_ACTION, OBJECT_ENTRY, S_ANY),
  SNDJBC_ENTRY(PARAMETER_2, 255, IS_STRING, INPUT_ACTION, OBJECT_ENTRY, S_ANY),
  SNDJBC_ENTRY(PARAMETER_3, 255, IS_STRING, INPUT_ACTION, OBJECT_ENTRY, S_ANY),
  SNDJBC_ENTRY(PARAMETER_4, 255, IS_STRING, INPUT_ACTION, OBJECT_ENTRY, S_ANY),
  SNDJBC_ENTRY(PARAMETER_5, 255, IS_STRING, INPUT_ACTION, OBJECT_ENTRY, S_ANY),
  SNDJBC_ENTRY(PARAMETER_6, 255, IS_STRING, INPUT_ACTION, OBJECT_ENTRY, S_ANY),
  SNDJBC_ENTRY(PARAMETER_7, 255, IS_STRING, INPUT_ACTION, OBJECT_ENTRY, S_ANY),
  SNDJBC_ENTRY(PARAMETER_8, 255, IS_STRING, INPUT_ACTION, OBJECT_ENTRY, S_ANY),
  SNDJBC_ENTRY(NO_PARAMETERS, 4, IS_BOOL, INPUT_ACTION, OBJECT_ENTRY, S_ANY),
  SNDJBC_ENTRY(PASSALL, 4, IS_BOOL, INPUT_ACTION, OBJECT_ENTRY, S_ANY),
  SNDJBC_ENTRY(NO_PASSALL, 4, IS_BOOL, INPUT_ACTION, OBJECT_ENTRY, S_ANY),
  SNDJBC_ENTRY(PRINTER, 4, IS_BOOL, INPUT_ACTION, OBJECT_QUEUE, S_ANY),
  SNDJBC_ENTRY(PRIORITY, 4, IS_LONGWORD, INPUT_ACTION, OBJECT_ENTRY, S_ANY),
  SNDJBC_ENTRY(PROCESSOR, 255, IS_STRING, INPUT_ACTION, OBJECT_QUEUE, S_ANY),
  SNDJBC_ENTRY(NO_PROCESSOR, 4, IS_BOOL, INPUT_ACTION, OBJECT_QUEUE, S_ANY),
  SNDJBC_ENTRY(PROTECTION, 4, IS_BOOL, INPUT_ACTION, OBJECT_ENTRY, S_ANY),
  SNDJBC_ENTRY(QUEUE, 31, IS_STRING, INPUT_ACTION, OBJECT_QUEUE |
               OBJECT_ENTRY, S_ANY),
  SNDJBC_ENTRY(QUEUE_DESCRIPTION, 255, IS_STRING, INPUT_ACTION,
               OBJECT_QUEUE, S_ANY),
  SNDJBC_ENTRY(NO_QUEUE_DESCRIPTION, 4, IS_BOOL, INPUT_ACTION,
               OBJECT_QUEUE, S_ANY),
  SNDJBC_ENTRY(QUEUE_DIRECTORY, 255, IS_STRING, INPUT_ACTION,
               OBJECT_MANAGER, S_ANY),
  SNDJBC_ENTRY(QUEUE_MANAGER_NAME, 31, IS_STRING, INPUT_ACTION,
               OBJECT_QUEUE | OBJECT_MANAGER, S_ANY),
  SNDJBC_ENTRY(QUEUE_MANAGER_NODES, 255, IS_STRING, INPUT_ACTION,
               OBJECT_MANAGER, S_ANY),
  SNDJBC_ENTRY(RECORD_BLOCKING, 4, IS_BOOL, INPUT_ACTION, OBJECT_QUEUE,
               S_ANY),
  SNDJBC_ENTRY(NO_RECORD_BLOCKING, 4, IS_BOOL, INPUT_ACTION, OBJECT_QUEUE,
               S_ANY),
  SNDJBC_ENTRY(RELATIVE_PAGE, 4, IS_LONGWORD, INPUT_ACTION, OBJECT_QUEUE,
               S_ANY),
  SNDJBC_ENTRY(RESTART, 4, IS_BOOL, INPUT_ACTION, OBJECT_QUEUE, S_ANY),
  SNDJBC_ENTRY(NO_RESTART, 4, IS_BOOL, INPUT_ACTION, OBJECT_QUEUE, S_ANY),
  SNDJBC_ENTRY(RETAIN_ALL_JOBS, 4, IS_BOOL, INPUT_ACTION, OBJECT_QUEUE,
               S_ANY),
  SNDJBC_ENTRY(RETAIN_ERROR_JOBS, 4, IS_BOOL, INPUT_ACTION, OBJECT_QUEUE,
               S_ANY),
  SNDJBC_ENTRY(NO_RETAIN_JOBS, 4, IS_BOOL, INPUT_ACTION, OBJECT_QUEUE,
               S_ANY),
  SNDJBC_ENTRY(SCSNODE_NAME, 6, IS_STRING, INPUT_ACTION, OBJECT_QUEUE,
               S_ANY),
  SNDJBC_ENTRY(SEARCH_STRING, 63, IS_STRING, INPUT_ACTION, OBJECT_QUEUE,
               S_ANY),
  SNDJBC_ENTRY(SERVER, 4, IS_STRING, INPUT_ACTION, OBJECT_QUEUE, S_ANY),
  SNDJBC_ENTRY(SWAP, 4, IS_BOOL, INPUT_ACTION, OBJECT_QUEUE, S_ANY),
  SNDJBC_ENTRY(NO_SWAP, 4, IS_BOOL, INPUT_ACTION, OBJECT_QUEUE, S_ANY),
  SNDJBC_ENTRY(TERMINAL, 4, IS_BOOL, INPUT_ACTION, OBJECT_QUEUE, S_ANY),
  SNDJBC_ENTRY(NO_TERMINAL, 4, IS_BOOL, INPUT_ACTION, OBJECT_QUEUE, S_ANY),
  SNDJBC_ENTRY(TOP_OF_FILE, 4, IS_BOOL, INPUT_ACTION, OBJECT_QUEUE, S_ANY),
  SNDJBC_ENTRY(UIC, 4, IS_LONGWORD, INPUT_ACTION, OBJECT_ENTRY, S_ANY),
  SNDJBC_ENTRY(USERNAME, 12, IS_STRING, INPUT_ACTION, OBJECT_ENTRY, S_ANY),
  SNDJBC_ENTRY(WSDEFAULT, 4, IS_LONGWORD, INPUT_ACTION, OBJECT_QUEUE |
               OBJECT_ENTRY, S_ANY),
  SNDJBC_ENTRY(NO_WSDEFAULT, 4, IS_BOOL, INPUT_ACTION, OBJECT_QUEUE |
               OBJECT_ENTRY, S_ANY),
  SNDJBC_ENTRY(WSEXTENT, 4, IS_LONGWORD, INPUT_ACTION, OBJECT_QUEUE
               | OBJECT_ENTRY, S_ANY),
  SNDJBC_ENTRY(NO_WSEXTENT, 4, IS_BOOL, INPUT_ACTION, OBJECT_QUEUE
               | OBJECT_ENTRY, S_ANY),
  SNDJBC_ENTRY(WSQUOTA, 4, IS_LONGWORD, INPUT_ACTION, OBJECT_QUEUE |
               OBJECT_ENTRY, S_ANY),
  SNDJBC_ENTRY(NO_WSQUOTA, 4, IS_BOOL, INPUT_ACTION, OBJECT_QUEUE |
               OBJECT_ENTRY, S_ANY),
  {NULL, 0, 0, 0, 0, 0, 0, 0}
};

/* Some static info */
char *MonthNames[12] = {
  "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep",
  "Oct", "Nov", "Dec"} ;

int QueueItemCount = 0;
int EntryItemCount = 0;
int FormItemCount = 0;
int CharacteristicItemCount = 0;
int ManagerItemCount = 0;
int FileItemCount = 0;

/* Macro to fill in a 'traditional' item-list entry */
#define init_itemlist(ile, length, code, bufaddr, retlen_addr) \
{ \
    (ile)->TradItem.buflen = (length); \
    (ile)->TradItem.itmcode = (code); \
    (ile)->TradItem.buffer = (bufaddr); \
    (ile)->TradItem.retlen = (retlen_addr) ;}

/* Take a pointer to a bitmap hash (like decode_bitmap gives) and turn it */
/* into an integer */
int
generic_bitmap_encode(HV * FlagHV, int CodeType, int ItemCode)
{
  char *FlagName;
  I32 FlagLen;
  int EncodedValue = 0;

  /* Shut Dec C up */
  FlagName = NULL;

  /* Initialize our hash iterator */
  hv_iterinit(FlagHV);

  /* Rip through the hash */
  while (hv_iternextsv(FlagHV, &FlagName, &FlagLen)) {
    
    if (CodeType == GETQUI_PARAM) {
      switch (ItemCode) {
      case QUI$_SEARCH_FLAGS:
        BME_Q(SEARCH_ALL_JOBS);
        BME_Q(SEARCH_BATCH);
        BME_Q(SEARCH_EXECUTING_JOBS);
        BME_Q(SEARCH_FREEZE_CONTEXT);
        BME_Q(SEARCH_GENERIC);
        BME_Q(SEARCH_HOLDING_JOBS);
        BME_Q(SEARCH_PENDING_JOBS);
        BME_Q(SEARCH_PRINTER);
        BME_Q(SEARCH_RETAINED_JOBS);
        BME_Q(SEARCH_SERVER);
        BME_Q(SEARCH_SYMBIONT);
        BME_Q(SEARCH_TERMINAL);
        BME_Q(SEARCH_THIS_JOB);
        BME_Q(SEARCH_TIMED_RELEASE_JOBS);
        BME_Q(SEARCH_WILDCARD);
        break;
      default:
        croak("Invalid item specified");
      }
    } else {
      EncodedValue = 0;
    }
  }
  
  return EncodedValue;
  
}

/* Take a pointer to an itemlist, a hashref, and some flags, and build up */
/* an itemlist from what's in the hashref. Buffer space for the items is */
/* allocated, as are the length shorts and stuff. If the hash entries have */
/* values, those values are copied into the buffers, too. Returns the */
/* number of items stuck in the itemlist */
int build_itemlist(ITMLST *ItemList, HV *HashRef, int SysCallType,
                            int ObjectType)
{
  /* standard, dopey index variable */
  int i = 0, ItemListIndex = 0;
  char *TempCharPointer;
  unsigned int TempStrLen;
  
  int TempNameLen;
  short ItemCode;
  SV *TempSV;
  unsigned short *TempLen;
  unsigned short work_length;
  char *TempBuffer;
  long TempLong;
  struct dsc$descriptor_s TimeStringDesc;
  int Status;

  for(i = 0; MondoQueueInfoList[i].InfoName; i++) {
    if ((ObjectType & MondoQueueInfoList[i].UseForObject) &&
        (SysCallType & MondoQueueInfoList[i].SysCall)) {
      TempNameLen = strlen(MondoQueueInfoList[i].InfoName);
      if (hv_exists(HashRef, MondoQueueInfoList[i].InfoName, TempNameLen)) {
        ItemCode = (SysCallType == GETQUI_PARAM ?
                    MondoQueueInfoList[i].GetQUIValue :
                    MondoQueueInfoList[i].SndJBCValue);
        /* Figure out some stuff. Avoids duplication, and makes the macro */
        /* expansion of init_itemlist a little easier */
        switch(MondoQueueInfoList[i].ReturnType) {
          /* Quadwords are treated as strings for right now */
        case IS_QUADWORD:
        case IS_STRING:
          TempSV = *hv_fetch(HashRef,
                             MondoQueueInfoList[i].InfoName,
                             TempNameLen, FALSE);
          TempCharPointer = SvPV(TempSV, TempStrLen);

          /* Allocate us some buffer space */
          New(NULL, TempBuffer, MondoQueueInfoList[i].BufferLen, char);
          Newz(NULL, TempLen, 1, unsigned short);

          /* By default, our length is the length of the buffer we allocate */
          *TempLen =  MondoQueueInfoList[i].BufferLen;
          work_length = MondoQueueInfoList[i].BufferLen;
          
          /* Set the string buffer to spaces */
          memset(TempBuffer, ' ', MondoQueueInfoList[i].BufferLen);
          
          /* If there was something in the SV, and we want to tell VMS, */
          /* then copy it over */
          if (TempStrLen > 0 && ((MondoQueueInfoList[i].InOrOut &
                                 INPUT_INFO) ||
                                (MondoQueueInfoList[i].InOrOut &
                                 INPUT_ACTION))) {
            /* Note the length of the data we actually copied over */
            work_length = TempStrLen <
              MondoQueueInfoList[i].BufferLen ? TempStrLen :
                MondoQueueInfoList[i].BufferLen;
            *TempLen = work_length;
            /* Copy it. (Duh...) */
            Copy(TempCharPointer, TempBuffer, work_length, char);
          }

          init_itemlist(&ItemList[ItemListIndex],
                        work_length,
                        ItemCode,
                        TempBuffer,
                        TempLen);
          break;
        case IS_VMSDATE:
          TempSV = *hv_fetch(HashRef,
                             MondoQueueInfoList[i].InfoName,
                             TempNameLen, FALSE);
          TempCharPointer = SvPV(TempSV, TempStrLen);
          
          /* Allocate us some buffer space */
          New(NULL, TempBuffer, MondoQueueInfoList[i].BufferLen, char);
          Newz(NULL, TempLen, 1, unsigned short);

          /* Fill in the time string descriptor */
          TimeStringDesc.dsc$a_pointer = TempCharPointer;
          TimeStringDesc.dsc$w_length = TempStrLen;
          TimeStringDesc.dsc$b_dtype = DSC$K_DTYPE_T;
          TimeStringDesc.dsc$b_class = DSC$K_CLASS_S;

          /* Convert from an ascii rep to a VMS quadword date structure */
          Status = sys$bintim(&TimeStringDesc, TempBuffer);
          if (Status != SS$_NORMAL) {
            croak("Error converting time!");
          }
          
          init_itemlist(&ItemList[ItemListIndex],
                        MondoQueueInfoList[i].BufferLen,
                        ItemCode,
                        TempBuffer,
                        TempLen);
          break;

        case IS_BOOL:
          init_itemlist(&ItemList[ItemListIndex], 0,
                        ItemCode, NULL, NULL);
          break;
        case IS_LONGWORD:
          TempSV = *hv_fetch(HashRef,
                             MondoQueueInfoList[i].InfoName,
                             TempNameLen, FALSE);
          TempLong = SvIVX(TempSV);

          /* Allocate us some buffer space */
          New(NULL, TempBuffer, MondoQueueInfoList[i].BufferLen, char);
          Newz(NULL, TempLen, 1, unsigned short);

          *TempLen = 4;

          /* Set the value */
          *TempBuffer = TempLong;
          
          init_itemlist(&ItemList[ItemListIndex],
                        MondoQueueInfoList[i].BufferLen,
                        ItemCode,
                        TempBuffer,
                        TempLen);
          break;

        case IS_BITMAP:
          TempSV = *hv_fetch(HashRef,
                             MondoQueueInfoList[i].InfoName,
                             TempNameLen, FALSE);

          /* Is the SV an integer? If so, then we'll use that value. */
          /* Otherwise we'll assume that it's a hashref of the sort that */
          /* generic_bitmap_decode gives */
          if (SvIOK(TempSV)) {
            TempLong = SvIVX(TempSV);
          } else {
            TempLong = generic_bitmap_encode((HV *)SvRV(TempSV),
                                             SysCallType, ItemCode);
          }

          /* Allocate us some buffer space */
          Newz(NULL, TempBuffer, MondoQueueInfoList[i].BufferLen, char);
          Newz(NULL, TempLen, 1, unsigned short);
          *TempLen = 4;
          

          /* Set the value */
          Copy(&TempLong, TempBuffer, 4, char);
          
          init_itemlist(&ItemList[ItemListIndex],
                        MondoQueueInfoList[i].BufferLen,
                        ItemCode,
                        TempBuffer,
                        TempLen);
          break;

        default:
          croak("Unknown item type found!");
          break;
        }
        ItemListIndex++;
      }
    }
  }
  return(ItemListIndex);
}

/* scan an itemlist for the SEARCH_FLAGS entry.  If found, force the
   SEARCH_WILDCARD flag so we get a context from $GETQUI.  If not found,
   add it.
 */
int force_wildcard(ITMLST *ItemList, int count)
{
  int i;
  for (i=0;
       i<count &&
       ItemList[i].BufferItem.itmcode != QUI$_SEARCH_FLAGS;
       i++)
  {
    continue;
  }
  if (i < count)
  {
    *(long *)ItemList[i].BufferItem.buffer |= QUI$M_SEARCH_WILDCARD;
  } else {
    unsigned short *TempLen;
    long *TempBuffer;

    New(NULL, TempBuffer, 4, long);
    Newz(NULL, TempLen, 1, unsigned short);
    *TempLen = 4;
    *TempBuffer = QUI$M_SEARCH_WILDCARD;

    init_itemlist(&ItemList[count],
                  4,
                  QUI$_SEARCH_FLAGS,
                  TempBuffer,
                  TempLen);
    count++;
  }
  return count;
}

/* Takes an item list pointer and a count of items, and frees the buffer */
/* memory and length buffer memory */
void tear_down_itemlist(ITMLST *ItemList, int NumItems)
{
  int i;

  for(i=0; i < NumItems; i++) {
    if(ItemList[i].TradItem.buffer != NULL)
      Safefree(ItemList[i].TradItem.buffer);
    if(ItemList[i].TradItem.retlen != NULL)
      Safefree(ItemList[i].TradItem.retlen);
  }
}
         
void tote_up_items()
{
  /* Temp varaibles for all our statics, so we can be a little thread safer */
  int i, QueueItemTemp, EntryItemTemp, FormItemTemp, CharItemTemp,
  ManagerItemTemp, FileItemTemp;
  
  QueueItemTemp = 0;
  EntryItemTemp = 0;
  FormItemTemp = 0;
  CharItemTemp = 0;
  ManagerItemTemp = 0;
  FileItemTemp = 0;
  
  for(i = 0; MondoQueueInfoList[i].InfoName; i++) {
    if (MondoQueueInfoList[i].UseForObject & OBJECT_QUEUE)
      QueueItemTemp++;
    if (MondoQueueInfoList[i].UseForObject & OBJECT_ENTRY)
      EntryItemTemp++;
    if (MondoQueueInfoList[i].UseForObject & OBJECT_FORM)
      FormItemTemp++;
    if (MondoQueueInfoList[i].UseForObject & OBJECT_CHAR)
      CharItemTemp++;
    if (MondoQueueInfoList[i].UseForObject & OBJECT_MANAGER)
      ManagerItemTemp++;
    if (MondoQueueInfoList[i].UseForObject & OBJECT_FILE)
      FileItemTemp++;
  }

  QueueItemCount = QueueItemTemp;
  EntryItemCount = EntryItemTemp;
  FormItemCount = FormItemTemp;
  CharacteristicItemCount = CharItemTemp;
  ManagerItemCount = ManagerItemTemp;
  FileItemCount = FileItemTemp;
}

char *
decode_jbc(int JBC_To_Decode) {
  switch(JBC_To_Decode) {
  case JBC$_NORMAL:
    return("Normal");
  case JBC$_INVFUNCOD:
    return("Invalid function code");
  case JBC$_INVITMCOD:
    return("Invalid item list code");
  case JBC$_INVPARLEN:
    return("Invalid parameter length");
  case JBC$_INVQUENAM:
    return("Invalid Queue Name");
  case JBC$_JOBQUEDIS:
    return("Queue manager not started");
  case JBC$_MISREQPAR:
    return("Missing a required parameter");
  case JBC$_NOJOBCTX:
    return("No job context");
  case JBC$_NOMORECHAR:
    return("No more characteristics");
  case JBC$_NOMOREENT:
    return("No more entries");
  case JBC$_NOMOREFILE:
    return("No more files");
  case JBC$_NOMOREFORM:
    return("No more forms");
  case JBC$_NOMOREJOB:
    return("No more jobs");
  case JBC$_NOMOREQMGR:
    return("No more queue managers");
  case JBC$_NOMOREQUE:
    return("No more queues");
  case JBC$_NOQUECTX:
    return("No queue context");
  case JBC$_NOSUCHCHAR:
    return("No such characteristic");
  case JBC$_NOSUCHENT:
    return("No such entry");
  case JBC$_NOSUCHFILE:
    return("No such file");
  case JBC$_NOSUCHFORM:
    return("No such form");
  case JBC$_NOSUCHJOB:
    return("No such job");
  case JBC$_NOSUCHQMGR:
    return("No such queue manager");
  case JBC$_NOSUCHQUE:
    return("No such queue");
  case JBC$_AUTONOTSTART:
    return("Autostart queue, but no nodes with autostart started");
  case JBC$_BUFTOOSMALL:
    return("Buffer too small");
  case JBC$_DELACCESS:
    return("Can't delete file");
  case JBC$_DUPCHARNAME:
    return("Duplicate characteristic name");
  case JBC$_DUPCHARNUM:
    return("Duplicate characteritic number");
  case JBC$_DUPFORM:
    return("Duplicate form number");
  case JBC$_DUPFORMNAME:
    return("Duplicate form name");
  case JBC$_EMPTYJOB:
    return("No files specified for job");
  case JBC$_EXECUTING:
    return("Job is currently executing");
  case JBC$_INCDSTQUE:
    return("Destination queue type inconsistent with requested operation");
  default:
    return("Dunno");
  }
}
  
SV *
generic_bitmap_decode(char *InfoName, int BitmapValue)
{
  HV *AllPurposeHV;
  if (!strcmp(InfoName, "FORM_FLAGS")) {
    AllPurposeHV = (HV*)sv_2mortal((SV*)newHV());
    bit_test(AllPurposeHV, QUI$M_FORM_SHEET_FEED, "FORM_SHEET_FEED",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_FORM_TRUNCATE, "FORM_TRUNCATE",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_FORM_WRAP, "FORM_WRAP", BitmapValue);
  } else {
  if (!strcmp(InfoName, "FILE_FLAGS")) {
    AllPurposeHV = (HV*)sv_2mortal((SV*)newHV());
    bit_test(AllPurposeHV, QUI$M_FILE_BURST, "FILE_BURST",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_FILE_DELETE, "FILE_DELETE",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_FILE_DOUBLE_SPACE, "FILE_SOUBLE_SPACE",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_FILE_FLAG, "FILE_FLAG",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_FILE_TRAILER, "FILE_TRAILER",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_FILE_PAGE_HEADER, "FILE_PAGE_HEADER",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_FILE_PAGINATE, "FILE_PAGINATE",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_FILE_PASSALL, "FILE_PASSALL",
             BitmapValue);
  } else {
  if (!strcmp(InfoName, "FILE_STATUS")) {
    AllPurposeHV = (HV*)sv_2mortal((SV*)newHV());
    bit_test(AllPurposeHV, QUI$M_FILE_CHECKPOINTED, "FILE_CHECKPOINTED",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_FILE_EXECUTING, "FILE_EXECUTING",
             BitmapValue);
  } else {
  if (!strcmp(InfoName, "JOB_FLAGS")) {
    AllPurposeHV = (HV*)sv_2mortal((SV*)newHV());
    bit_test(AllPurposeHV, QUI$M_JOB_CPU_LIMIT, "JOB_CPU_LIMIT", BitmapValue);
    bit_test(AllPurposeHV, QUI$M_JOB_ERROR_RETENTION,
             "JOB_ERROR_RETENTION", BitmapValue);
    bit_test(AllPurposeHV, QUI$M_JOB_FILE_BURST, "JOB_FILE_BURST",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_JOB_FILE_BURST_ONE, "JOB_FILE_BURST_ONE",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_JOB_FILE_FLAG, "JOB_FILE_FLAG",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_JOB_FILE_FLAG_ONE, "JOB_FILE_FLAG_ONE",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_JOB_FILE_PAGINATE, "JOB_FILE_PAGINATE",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_JOB_FILE_TRAILER, "JOB_FILE_TRAILER",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_JOB_FILE_TRAILER_ONE,
             "JOB_FILE_TRAILER_ONE", BitmapValue);
    bit_test(AllPurposeHV, QUI$M_JOB_LOG_DELETE, "JOB_LOG_DELETE",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_JOB_LOG_NULL, "JOB_LOG_NULL", BitmapValue);
    bit_test(AllPurposeHV, QUI$M_JOB_LOG_SPOOL, "JOB_LOG_SPOOL", BitmapValue);
    bit_test(AllPurposeHV, QUI$M_JOB_LOWERCASE, "JOB_LOWERCASE", BitmapValue);
    bit_test(AllPurposeHV, QUI$M_JOB_NOTIFY, "JOB_NOTIFY", BitmapValue);
    bit_test(AllPurposeHV, QUI$M_JOB_RESTART, "JOB_RESTART", BitmapValue);
    bit_test(AllPurposeHV, QUI$M_JOB_RETENTION, "JOB_RETENTION", BitmapValue);
    bit_test(AllPurposeHV, QUI$M_JOB_WSDEFAULT, "JOB_WSDEFAULT", BitmapValue);
    bit_test(AllPurposeHV, QUI$M_JOB_WSEXTENT, "JOB_WSEXTENT", BitmapValue);
    bit_test(AllPurposeHV, QUI$M_JOB_WSQUOTA, "JOB_WSQUOTA", BitmapValue);
  } else {
  if (!strcmp(InfoName, "JOB_STATUS")) {
    AllPurposeHV = (HV*)sv_2mortal((SV*)newHV());
    bit_test(AllPurposeHV, QUI$M_JOB_ABORTING, "JOB_ABORTING", BitmapValue);
    bit_test(AllPurposeHV, QUI$M_JOB_EXECUTING, "JOB_EXECUTING", BitmapValue);
    bit_test(AllPurposeHV, QUI$M_JOB_HOLDING, "JOB_HOLDING", BitmapValue);
    bit_test(AllPurposeHV, QUI$M_JOB_INACCESSIBLE, "JOB_INACCESSIBLE",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_JOB_PENDING, "JOB_PENDING", BitmapValue);
    bit_test(AllPurposeHV, QUI$M_JOB_REFUSED, "JOB_REFUSED", BitmapValue);
    bit_test(AllPurposeHV, QUI$M_JOB_RETAINED, "JOB_RETAINED", BitmapValue);
    bit_test(AllPurposeHV, QUI$M_JOB_STALLED, "JOB_STALLED", BitmapValue);
    bit_test(AllPurposeHV, QUI$M_JOB_STARTING, "JOB_STARTING", BitmapValue);
    bit_test(AllPurposeHV, QUI$M_JOB_SUSPENDED, "JOB_SUSPENDED", BitmapValue);
    bit_test(AllPurposeHV, QUI$M_JOB_TIMED_RELEASE, "JOB_TIMED_RELEASE",
             BitmapValue);
  } else {
  if (!strcmp(InfoName, "MANAGER_FLAGS")) {
    AllPurposeHV = (HV*)sv_2mortal((SV*)newHV());
    bit_test(AllPurposeHV, QUI$M_MANAGER_FAILOVER, "MANAGER_FAILOVER",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_MANAGER_RUNNING, "MANAGER_RUNNING",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_MANAGER_START_PENDING,
             "MANAGER_START_PENDING", BitmapValue);
    bit_test(AllPurposeHV, QUI$M_MANAGER_STARTING, "MANAGER_STARTING",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_MANAGER_STOPPING, "MANAGER_STOPPING",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_MANAGER_STOPPED, "MANAGER_STOPPED",
             BitmapValue);
  } else {
  if (!strcmp(InfoName, "PENDING_JOB_REASON")) {
    AllPurposeHV = (HV*)sv_2mortal((SV*)newHV());
    bit_test(AllPurposeHV, QUI$M_PEND_CHAR_MISMATCH, "PEND_CHAR_MISMATCH",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_PEND_JOB_SIZE_MAX, "PEND_JOB_SIZE_MAX",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_PEND_LOWERCASE_MISMATCH,
             "PEND_LOWERCASE_MISMATCH", BitmapValue);
    bit_test(AllPurposeHV, QUI$M_PEND_NO_ACCESS, "PEND_NO_ACCESS",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_PEND_QUEUE_BUSY, "PEND_QUEUE_BUSY",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_PEND_QUEUE_STATE, "PEND_QUEUE_STATE",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_PEND_STOCK_MISMATCH,
             "PEND_STOCK_MISMATCH", BitmapValue);
  } else {
  if (!strcmp(InfoName, "QUEUE_FLAGS")) {
    AllPurposeHV = (HV*)sv_2mortal((SV*)newHV());
    bit_test(AllPurposeHV, QUI$M_QUEUE_ACL_SPECIFIED,
             "QUEUE_ACL_SPECIFIED", BitmapValue);
    bit_test(AllPurposeHV, QUI$M_QUEUE_AUTOSTART, "QUEUE_AUTOSTART",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_QUEUE_BATCH, "QUEUE_BATCH", BitmapValue);
    bit_test(AllPurposeHV, QUI$M_QUEUE_CPU_DEFAULT, "QUEUE_CPU_DEFAULT",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_QUEUE_CPU_LIMIT, "QUEUE_CPU_LIMIT",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_QUEUE_FILE_BURST, "QUEUE_FILE_BURST",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_QUEUE_FILE_BURST_ONE,
             "QUEUE_FILE_BURST_ONE", BitmapValue);
    bit_test(AllPurposeHV, QUI$M_QUEUE_FILE_FLAG, "QUEUE_FILE_FLAG",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_QUEUE_FILE_FLAG_ONE,
             "QUEUE_FILE_FLAG_ONE", BitmapValue);
    bit_test(AllPurposeHV, QUI$M_QUEUE_FILE_PAGINATE,
             "QUEUE_FILE_PAGINATE", BitmapValue);
    bit_test(AllPurposeHV, QUI$M_QUEUE_FILE_TRAILER, "QUEUE_FILE_TRAILER",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_QUEUE_FILE_TRAILER_ONE,
             "QUEUE_FILE_TRAILER_ONE", BitmapValue);
    bit_test(AllPurposeHV, QUI$M_QUEUE_GENERIC, "QUEUE_GENERIC",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_QUEUE_GENERIC_SELECTION,
             "QUEUE_GENERIC_SELECTION", BitmapValue);
    bit_test(AllPurposeHV, QUI$M_QUEUE_JOB_BURST, "QUEUE_JOB_BURST",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_QUEUE_JOB_FLAG, "QUEUE_JOB_FLAG",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_QUEUE_JOB_SIZE_SCHED,
             "QUEUE_JOB_SIZE_SCHED", BitmapValue);
    bit_test(AllPurposeHV, QUI$M_QUEUE_JOB_TRAILER, "QUEUE_JOB_TRAILER",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_QUEUE_PRINTER, "QUEUE_PRINTER",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_QUEUE_RECORD_BLOCKING,
             "QUEUE_RECORD_BLOCKING", BitmapValue);
    bit_test(AllPurposeHV, QUI$M_QUEUE_RETAIN_ALL, "QUEUE_RETAIN_ALL",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_QUEUE_RETAIN_ERROR, "QUEUE_RETAIN_ERROR",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_QUEUE_SWAP, "QUEUE_SWAP", BitmapValue);
    bit_test(AllPurposeHV, QUI$M_QUEUE_TERMINAL, "QUEUE_TERMINAL",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_QUEUE_WSDEFAULT, "QUEUE_WSDEFAULT",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_QUEUE_WSEXTENT, "QUEUE_WSEXTENT",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_QUEUE_WSQUOTA, "QUEUE_WSQUOTA",
             BitmapValue);
  } else {
  if (!strcmp(InfoName, "QUEUE_STATUS")) {
    AllPurposeHV = (HV*)sv_2mortal((SV*)newHV());
    bit_test(AllPurposeHV, QUI$M_QUEUE_ALIGNING, "QUEUE_ALIGNING",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_QUEUE_AUTOSTART_INACTIVE,
             "QUEUE_AUTOSTART_INACTIVE", BitmapValue);
    bit_test(AllPurposeHV, QUI$M_QUEUE_AVAILABLE, "QUEUE_AVAILABLE",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_QUEUE_BUSY, "QUEUE_BUSY", BitmapValue);
    bit_test(AllPurposeHV, QUI$M_QUEUE_CLOSED, "QUEUE_CLOSED",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_QUEUE_DISABLED, "QUEUE_DISABLED",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_QUEUE_IDLE, "QUEUE_IDLE", BitmapValue);
    bit_test(AllPurposeHV, QUI$M_QUEUE_LOWERCASE, "QUEUE_LOWERCASE",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_QUEUE_PAUSED, "QUEUE_PAUSED",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_QUEUE_PAUSING, "QUEUE_PAUSING",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_QUEUE_REMOTE, "QUEUE_REMOTE",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_QUEUE_RESETTING, "QUEUE_RESETTING",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_QUEUE_RESUMING, "QUEUE_RESUMING",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_QUEUE_SERVER, "QUEUE_SERVER",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_QUEUE_STALLED, "QUEUE_STALLED",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_QUEUE_STARTING, "QUEUE_STARTING",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_QUEUE_STOP_PENDING, "QUEUE_STOP_PENDING",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_QUEUE_STOPPED, "QUEUE_STOPPED",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_QUEUE_STOPPING, "QUEUE_STOPPING",
             BitmapValue);
    bit_test(AllPurposeHV, QUI$M_QUEUE_UNAVAILABLE, "QUEUE_UNAVAILABLE",
             BitmapValue);
  }}}}}}}}}
  if (AllPurposeHV) {
    return(newRV_noinc((SV *)AllPurposeHV));
  } else {
    return(&PL_sv_undef);
  }
}

/* This routine runs through the MondoQueueInfoList array and pulls out all */
/* the things that match the object type passed */
SV *
generic_valid_properties(HV *HashToFill, int ObjectType)
{
  int i;
  SV *Input_InfoSV, *Output_InfoSV, *Input_ActionSV, *Output_ActionSV;
  HV *ResultHV;
  
  /* Create the SVs for input, output and in/out returns */
  Input_InfoSV = sv_2mortal(newSVpv("INPUT_INFO", 0));
  Output_InfoSV = sv_2mortal(newSVpv("OUTPUT_INFO", 0));
  Input_ActionSV = sv_2mortal(newSVpv("INPUT_ACTION", 0));
  Output_ActionSV = sv_2mortal(newSVpv("OUTPUT_ACTION", 0));
  
  for(i=0; MondoQueueInfoList[i].InfoName; i++) {
    if (MondoQueueInfoList[i].UseForObject & ObjectType) {
      
      /* Allocate a new AV to hold our results */
      ResultHV = newHV();
      
      /* Run through the options */
      if (MondoQueueInfoList[i].InOrOut & INPUT_INFO)
        hv_store_ent(HashToFill, Input_InfoSV, &PL_sv_yes, 0);
      else
        hv_store_ent(HashToFill, Input_InfoSV, &PL_sv_no, 0);

      if (MondoQueueInfoList[i].InOrOut & OUTPUT_INFO)
        hv_store_ent(HashToFill, Output_InfoSV, &PL_sv_yes, 0);
      else
        hv_store_ent(HashToFill, Output_InfoSV, &PL_sv_no, 0);

      if (MondoQueueInfoList[i].InOrOut & INPUT_ACTION)
        hv_store_ent(HashToFill, Input_ActionSV, &PL_sv_yes, 0);
      else
        hv_store_ent(HashToFill, Input_ActionSV, &PL_sv_no, 0);

      if (MondoQueueInfoList[i].InOrOut & OUTPUT_ACTION)
        hv_store_ent(HashToFill, Output_ActionSV, &PL_sv_yes, 0);
      else
        hv_store_ent(HashToFill, Output_ActionSV, &PL_sv_no, 0);
      
      hv_store(HashToFill, MondoQueueInfoList[i].InfoName,
               strlen(MondoQueueInfoList[i].InfoName),
               (SV *)newRV_noinc((SV *)ResultHV), 0);
    }
  }

  return (SV *)HashToFill;
}

/* This routine gets passed a pre-cleared array that's big enough for all */
/* the pieces we'll fill in, and that has the input parameter stuck in */
/* entry 0. We allocate the memory and fill in the rest of the array, and */
/* pass back a hash that has all the return results in it. */
SV *
generic_getqui_call(ITMLST *ListOItems, int ObjectType, int InfoCount,
                    short QUIFunction, int SpecialFlags,
                    int PrefilledSlots, unsigned int OtherOKIOSBStatus,
                    unsigned int *ReturnedStatus, int ContextStream)
{
  FetchedItem *OurDataList;
  unsigned short *ReturnLengths;
  int i, LocalIndex;
  iosb GenericIOSB;
  int status;
  HV *AllPurposeHV;
  SV *ReturnedSV;
  unsigned short ReturnedTime[7];
  char AsciiTime[100];
  char QuadWordString[65];
  long *TempLongPointer;
  __int64 *TempQuadPointer;
  char *TempStringBuffer;
  
  LocalIndex = 0;
  
  /* Allocate the local tracking array */
  OurDataList = malloc(sizeof(FetchedItem) * InfoCount);
  memset(OurDataList, 0, sizeof(FetchedItem) * InfoCount);
  
  /* We also need room for the buffer lengths */
  ReturnLengths = malloc(sizeof(short) * InfoCount);
  memset(ReturnLengths, 0, sizeof(short) * InfoCount);
  
  
  /* Fill in the item list and the tracking list */
  for (i = 0; MondoQueueInfoList[i].InfoName; i++) {
    if ((MondoQueueInfoList[i].UseForObject & ObjectType) &&
        (MondoQueueInfoList[i].SpecialFlags & SpecialFlags) &&
        (MondoQueueInfoList[i].InOrOut & OUTPUT_INFO)) {
      
      /* Allocate the return data buffer and zero it. Can be oddly
         sized, so we use the system malloc instead of New */
      OurDataList[LocalIndex].ReturnBuffer =
        malloc(MondoQueueInfoList[i].BufferLen);
      memset(OurDataList[LocalIndex].ReturnBuffer, 0,
             MondoQueueInfoList[i].BufferLen); 
      
      /* Note some important stuff (like what we're doing) in our local */
      /* tracking array */
      OurDataList[LocalIndex].ItemName =
        MondoQueueInfoList[i].InfoName;
      OurDataList[LocalIndex].ReturnLength =
        &ReturnLengths[LocalIndex];
      OurDataList[LocalIndex].ReturnType =
        MondoQueueInfoList[i].ReturnType;
      OurDataList[LocalIndex].ItemListEntry = i;
      
      /* Fill in the item list */
      init_itemlist(&ListOItems[LocalIndex + PrefilledSlots], MondoQueueInfoList[i].BufferLen,
                    MondoQueueInfoList[i].GetQUIValue,
                    OurDataList[LocalIndex].ReturnBuffer,
                    &ReturnLengths[LocalIndex]);

      /* Increment the local index */
      LocalIndex++;
    }
  }
  
  /* Make the GETQUIW call */
  status = sys$getquiw(NULL, QUIFunction, &ContextStream, ListOItems,
                       &GenericIOSB, NULL, NULL);

  /* Set the return status */
  *ReturnedStatus = GenericIOSB.sts;

  /* Did it go OK? */
  if ((status == SS$_NORMAL) && (GenericIOSB.sts == JBC$_NORMAL)) {
    unsigned int *timeptr;
    /* Looks like it */
    AllPurposeHV = (HV*)sv_2mortal((SV*)newHV());
    for (i = 0; i < LocalIndex; i++) {
      switch(OurDataList[i].ReturnType) {
      case IS_STRING:
        /* copy the return string into a temporary buffer with C's string */
        /* handling routines. For some reason $GETQUI returns values with */
        /* embedded nulls and bogus lengths, which is really */
        /* strange. Anyway, this is a cheap way to see how long the */
        /* string is without doing a strlen(), which might fall off the */
        /* end of the world */
        TempStringBuffer = malloc(*(OurDataList[i].ReturnLength) + 1);
        memset(TempStringBuffer, 0, *(OurDataList[i].ReturnLength) + 1);
        strncpy(TempStringBuffer, OurDataList[i].ReturnBuffer,
                *(OurDataList[i].ReturnLength));
        if (strlen(TempStringBuffer) < *OurDataList[i].ReturnLength)
          *OurDataList[i].ReturnLength = strlen(TempStringBuffer);
        free(TempStringBuffer);
        /* Check to make sure we got something back, otherwise set the */
        /* value to undef */
        if (*OurDataList[i].ReturnLength) {
          hv_store(AllPurposeHV, OurDataList[i].ItemName,
                   strlen(OurDataList[i].ItemName),
                   newSVpv(OurDataList[i].ReturnBuffer,
                           *(OurDataList[i].ReturnLength)), 0);
        } else {
          hv_store(AllPurposeHV, OurDataList[i].ItemName,
                   strlen(OurDataList[i].ItemName),
                   &PL_sv_undef, 0);
        }
        break;
      case IS_VMSDATE:
	timeptr = (unsigned int *)OurDataList[i].ReturnBuffer;
 	if ((timeptr[0] == 0) && (timeptr[1] == 0)) {
	  hv_store(AllPurposeHV, OurDataList[i].ItemName,
		   strlen(OurDataList[i].ItemName),
		   &PL_sv_undef, 0);
 	} else {
	  sys$numtim(ReturnedTime, OurDataList[i].ReturnBuffer);
	  sprintf(AsciiTime, "%02hi-%s-%hi %02hi:%02hi:%02hi.%hi",
		  ReturnedTime[2], MonthNames[ReturnedTime[1] - 1],
		  ReturnedTime[0], ReturnedTime[3], ReturnedTime[4],
		  ReturnedTime[5], ReturnedTime[6]);
	  hv_store(AllPurposeHV, OurDataList[i].ItemName,
		   strlen(OurDataList[i].ItemName),
		   newSVpv(AsciiTime, 0), 0);
 	}
        break;
        /* No enums for now, so they become longs */
      case IS_ENUM:
/*        TempLongPointer = OurDataList[i].ReturnBuffer;
        hv_store(AllPurposeHV, OurDataList[i].ItemName,
                 strlen(OurDataList[i].ItemName),
                 enum_name(MondoQueueInfoList[i].GetQUIValue,
                           *TempLongPointer), 0);
        break;
        */
      case IS_BITMAP:
      case IS_LONGWORD:
        TempLongPointer = OurDataList[i].ReturnBuffer;
        hv_store(AllPurposeHV, OurDataList[i].ItemName,
                 strlen(OurDataList[i].ItemName),
                 newSViv(*TempLongPointer),
                 0);
        break;
      case IS_QUADWORD:
        TempQuadPointer = OurDataList[i].ReturnBuffer;
        sprintf(QuadWordString, "%llu", *TempQuadPointer);
        hv_store(AllPurposeHV, OurDataList[i].ItemName,
                 strlen(OurDataList[i].ItemName),
                 newSVpv(QuadWordString, 0), 0);
        break;
        
      }
    }
    /* Set the returned status and return the HV we built */
    ReturnedSV = newRV_noinc((SV *) AllPurposeHV);
  } else {
    /* Well, things weren't fine and dandy. Were they almost fine and */
    /* dandy? (Which is to say, did we return a normal status and an IOSB */
    /* status that matches our 'other ok' status?) */
    if ((status == SS$_NORMAL) && (GenericIOSB.sts == OtherOKIOSBStatus)) {
      ReturnedSV = &PL_sv_undef;
    } else {
      /* I think we failed */
      SETERRNO(EVMSERR, status);
      ReturnedSV = &PL_sv_undef;
    }
  }
  
  /* Free up our allocated memory */
  for(i = 0; i < InfoCount; i++) {
    free(OurDataList[i].ReturnBuffer);
  }
  free(OurDataList);
  free(ReturnLengths);

  return(ReturnedSV);
}

/* Look up a name in the list and return its index, or -1 if it fails */
int
name_to_index(char *SearchName)
{
  int i;
  for(i = 0; MondoQueueInfoList[i].InfoName; i++) {
    if (!strcmp(SearchName, MondoQueueInfoList[i].InfoName))
      return i;
  }
  /* Got here, so we didn't find it. */
  return -1;
}


MODULE = VMS::Queue		PACKAGE = VMS::Queue		
PROTOTYPES: ENABLE

void
queue_list(...)
   PPCODE:
{
  /* variables */
  ITMLST QueueScanItemList[99]; /* Yes, this should be a pointer and the */
                                /* memory should be dynamically */
                                /* allocated. When I try, wacky things */
                                /* happen, so we fall back to this hack */
  int status;
  unsigned int QueueContext = -1;
  char WildcardSearchName[] = "*";
  short WildcardSearchNameReturnLength; /* Shouldn't ever need this, but */
                                        /* just in case... */
  char QueueNameBuffer[255];
  short QueueNameBufferReturnLength;
  iosb QueueIOSB;
  int QUIIndex, ItemsAdded, GottaFree;
  
  /* First, zero out as much of the array as we're using */
  Zero(&QueueScanItemList, items == 0 ? 3: 99, ITMLST);

  /* First check to see if things are wildly wrong (i.e. wrong number of */
  /* items) */
  if (items > 1) {
    croak("Max one hash ref!");
  }

  /* The first item's always the queue name, as that's what we're looking */
  /* for */
  init_itemlist(&QueueScanItemList[0], 255, QUI$_QUEUE_NAME,
                QueueNameBuffer, &QueueNameBufferReturnLength);
  
  /* Did they pass us anything? */
  if (items == 0) {

    /* Fill in the item list. Right now we just return all the queues we */
    /* can get our hands on */
    init_itemlist(&QueueScanItemList[1], 1, QUI$_SEARCH_NAME,
                  WildcardSearchName, &WildcardSearchNameReturnLength);
    GottaFree = FALSE;
  } else {
    /* Call build_itemlist here... */
    ItemsAdded = build_itemlist(QueueScanItemList + 1, (HV *)SvRV(ST(0)),
                                GETQUI_PARAM, OBJECT_QUEUE);
    GottaFree = TRUE;
  }

  /* Call $GETQUI in wildcard mode */
  status = sys$getquiw(0, QUI$_DISPLAY_QUEUE, &QueueContext,
                       QueueScanItemList, &QueueIOSB, NULL, 0);

  /* Did it fail somehow? */
  if (status != SS$_NORMAL) {
    XPUSHs(&PL_sv_undef);
    /* Cancel our context, just in case */
    sys$getquiw(0, QUI$_CANCEL_OPERATION, &QueueContext, NULL, NULL, NULL, 0);
  
    SETERRNO(EVMSERR, status);
  } else {
    /* We just loop as long as things are OK */
    while ((status == SS$_NORMAL) && (QueueIOSB.sts == JBC$_NORMAL)) {
      /* Stick the returned value on the return stack */
      XPUSHs(sv_2mortal(newSVpv(QueueNameBuffer,
                                QueueNameBufferReturnLength)));
      
      /* Call again */
      status = sys$getquiw(0, QUI$_DISPLAY_QUEUE, &QueueContext,
                           QueueScanItemList, &QueueIOSB, NULL, 0);
    }
  }
   
  /* We're done. Do we need to free things up? */
  if (GottaFree) {
    tear_down_itemlist(&QueueScanItemList[1], ItemsAdded);
  }

  /* Cancel our context, just in case */
  sys$getquiw(0, QUI$_CANCEL_OPERATION, &QueueContext, NULL, NULL, NULL, 0);
}

void
entry_list(...)
   PPCODE:
{
  /* This routine is fairly annoying, as we have to iterate through each */
  /* queue, then for each job in that queue. It'd be much nicer if we could */
  /* just go through all the entries or jobs by themselves, but we */
  /* can't. :( */

  /* variables for the main queue scan */
  ITMLST QueueScanItemList[99]; /* Yes, this should be a pointer and the */
                                /* memory should be dynamically */
                                /* allocated. When I try, wacky things */
                                /* happen, so we fall back to this hack */
  int QueueStatus;
  int QueueContext = -1;
  char WildcardSearchName[] = "*";
  short WildcardSearchNameReturnLength; /* Shouldn't ever need this, but */
                                        /* just in case... */
  char QueueNameBuffer[255];
  short QueueNameBufferReturnLength;
  iosb QueueIOSB;
  int GottaFreeQueue, QueueItemsAdded;
  
  /* variables for the entries*/
  ITMLST EntryScanItemList[99]; /* Yes, this should be a pointer and the */
                                /* memory should be dynamically */
                                /* allocated. When I try, wacky things */
                                /* happen, so we fall back to this hack */
  int EntryStatus;
  int WildcardSearchFlags = QUI$M_SEARCH_ALL_JOBS;
  int WildcardQueueSearchFlags = QUI$M_SEARCH_WILDCARD;
  short WildcardSearchFlagsReturnLength; /* Shouldn't ever need this, but */
                                        /* just in case... */
  long EntryNumber;
  short EntryNumberReturnLength;
  char WildcardUserName[] = "*";
  short WildcardUserNameReturnLength;
  iosb EntryIOSB;
  int GottaFreeEntry, EntryItemsAdded;
  int entry_count = 0;
  

  /* First, zero out as much of the arrays as we're using */
  Zero(&QueueScanItemList, items < 2 ? 3: 99, ITMLST);
  Zero(&EntryScanItemList, items < 1 ? 3: 99, ITMLST);  
  
  /* Did they pass us anything? and was it real? */
  if ((items > 0) && (ST(0) != &PL_sv_undef)) {
    /* Call build_itemlist here... */
    EntryItemsAdded = build_itemlist(&EntryScanItemList[1], (HV *)SvRV(ST(0)),
                                GETQUI_PARAM, OBJECT_ENTRY);
    GottaFreeEntry = TRUE;
  } else {
    /* Fill in the item list. Right now we just return all the entries we */
    /* can get our hands on */
    init_itemlist(&EntryScanItemList[1], sizeof(WildcardSearchFlags),
                  QUI$_SEARCH_FLAGS, &WildcardSearchFlags,
                  &WildcardSearchFlagsReturnLength);
    GottaFreeEntry = FALSE;
  }
  /* We always want the entry number */
  init_itemlist(&EntryScanItemList[0], sizeof(EntryNumber),
                QUI$_ENTRY_NUMBER, &EntryNumber,
                &EntryNumberReturnLength);

  /* Did they pass us a queue? And was it meaningful? */
  if ((items > 1) && (ST(1) != &PL_sv_undef)) {
    /* Call build_itemlist here... */
    QueueItemsAdded = build_itemlist(QueueScanItemList, (HV *)SvRV(ST(1)),
                                GETQUI_PARAM, OBJECT_QUEUE);
    GottaFreeQueue = TRUE;
    QueueItemsAdded = force_wildcard(QueueScanItemList, QueueItemsAdded);
  } else {
    /* Fill in the 'loop through the queues' item list */
    init_itemlist(&QueueScanItemList[0], 1, QUI$_SEARCH_NAME,
                  WildcardSearchName, &WildcardSearchNameReturnLength);
    QueueItemsAdded = 1;
    GottaFreeQueue = FALSE;
  }
  /* We always want the name */
  init_itemlist(&QueueScanItemList[QueueItemsAdded], 255, QUI$_QUEUE_NAME,
                QueueNameBuffer, &QueueNameBufferReturnLength);
  
  
  /* Call $GETQUI in wildcard mode for the queues */
  QueueStatus = sys$getquiw(0, QUI$_DISPLAY_QUEUE, &QueueContext,
                            QueueScanItemList, &QueueIOSB, NULL, 0);
    
  /* We just loop as long as things are OK */
  while ((QueueStatus == SS$_NORMAL) && (QueueIOSB.sts == JBC$_NORMAL)) {
    /* If we're in here, then we must have a queue. Try processing the */
    /* jobs for the queue */
    EntryStatus = sys$getquiw(0, QUI$_DISPLAY_JOB, &QueueContext,
                              EntryScanItemList, &EntryIOSB, NULL, 0);
    
    /* We just loop as long as things are OK */
    while ((EntryStatus == SS$_NORMAL) && (EntryIOSB.sts == JBC$_NORMAL)) {
      /* Stick the returned value on the return stack */
      XPUSHs(sv_2mortal(newSViv(EntryNumber)));

      /* Debugging */
      entry_count++;
      
      /* Call again */
      EntryStatus = sys$getquiw(0, QUI$_DISPLAY_JOB, &QueueContext,
                           EntryScanItemList, &EntryIOSB, NULL, 0);
    }
    
    /* Call again */
    QueueStatus = sys$getquiw(0, QUI$_DISPLAY_QUEUE, &QueueContext,
                         QueueScanItemList, &QueueIOSB, NULL, 0);
  }

  /* Now go give things back */
  if (GottaFreeQueue) {
    tear_down_itemlist(QueueScanItemList, QueueItemsAdded);
  }
  if (GottaFreeEntry) {
    tear_down_itemlist(&EntryScanItemList[1], EntryItemsAdded);
  }

  /* Cancel our context, just in case */
  sys$getquiw(0, QUI$_CANCEL_OPERATION, &QueueContext, NULL, NULL, NULL, 0);
}

void
file_list(EntryNumber)
     int EntryNumber
   PPCODE:
{
  /* This routine rips through all the files for a particular entry and */
  /* returns a list of hasrefs with all the file info in 'em. It's pretty */
  /* simple, though a touch annoying. We establish an entry context, then */
  /* repeatedly call generic_getqui_call in wildcard mode until we run out */
  /* of files. */

  /* variables for the entry itemlist */
  ITMLST EntryItemList[4];
  int EntryStatus;
  unsigned int EntryContext = -1;
  HV *FileHV;
  
  /* variables for the files */
  ITMLST FileScanItemList[99]; /* Yes, this should be a pointer and the */
                               /* memory should be dynamically */
                               /* allocated. When I try, wacky things */
                               /* happen, so we fall back to this hack */
  unsigned int FileStatus;
  short EntryNumberReturnLength;
  iosb EntryIOSB;
  int EntryFlags = QUI$M_SEARCH_WILDCARD;
  unsigned short EntryFlagsReturnLength;

  char QueueName[255];
  char UserName[255];
  unsigned short QueueNameReturnLength;  
  unsigned short UserNameReturnLength;  
    
  
  if (FileItemCount == 0) {
    tote_up_items();
  }
  

  /* First, zero out as much of the arrays as we're using */
  Zero(&EntryItemList, 5, ITMLST);
  Zero(&FileScanItemList, FileItemCount + 2, ITMLST);  
  
  /* Fill in the entry item list, which we use to establish our context */
  init_itemlist(&EntryItemList[0], sizeof(EntryNumber), QUI$_SEARCH_NUMBER,
                &EntryNumber, &EntryNumberReturnLength);
  init_itemlist(&EntryItemList[1], sizeof(EntryFlags), QUI$_SEARCH_FLAGS,
                &EntryFlags, &EntryFlagsReturnLength);
  init_itemlist(&EntryItemList[2], 255, QUI$_QUEUE_NAME,
                QueueName, &QueueNameReturnLength);
  init_itemlist(&EntryItemList[3], 255, QUI$_USERNAME,
                UserName, &UserNameReturnLength);
  
  /* Call $GETQUI in wildcard mode for the entry */
  EntryStatus = sys$getquiw(NULL, QUI$_DISPLAY_ENTRY, &EntryContext,
                            EntryItemList, &EntryIOSB, NULL, NULL);

  /* If things were OK, then  */
  if ((EntryStatus == SS$_NORMAL) && (EntryIOSB.sts == JBC$_NORMAL)) {
    /* If we're here, then we must have established context for the */
    /* entry. Whip through */
    FileHV = (HV *)generic_getqui_call(&FileScanItemList[0], OBJECT_FILE,
                                       FileItemCount, QUI$_DISPLAY_FILE, S_ANY,
                                       0, JBC$_NOMOREFILE, &FileStatus,
                                       EntryContext);
    
    while (FileStatus == JBC$_NORMAL) {
      /* Stick the returned value on the return stack */
      XPUSHs((SV *)FileHV);
      
      /* Call again */
      FileHV = (HV *)generic_getqui_call(&FileScanItemList[0], OBJECT_FILE,
                                         FileItemCount, QUI$_DISPLAY_FILE,
                                         S_ANY, 0, JBC$_NOMOREFILE,
                                         &FileStatus, EntryContext);
    }
    /* Cancel the wildcard op, since we're done. Otherwise we leak */
    /* contexts */
    sys$getquiw(NULL, QUI$_CANCEL_OPERATION, &EntryContext, NULL,
		NULL, NULL, NULL);
  } else {
    /* Got an error, so croak appropriately */
    croak(decode_jbc(EntryIOSB.sts));
    XSRETURN_EMPTY;
  }
}

void
form_list(...)
   PPCODE:
{
  /* variables */
  ITMLST FormScanItemList[99]; /* Yes, this should be a pointer and the */
                                /* memory should be dynamically */
                                /* allocated. When I try, wacky things */
                                /* happen, so we fall back to this hack */
  int status;
  unsigned int FormContext = -1;
  char WildcardSearchName[] = "*";
  short WildcardSearchNameReturnLength; /* Shouldn't ever need this, but */
                                        /* just in case... */
  int FormNumberBuffer;
  short FormNumberBufferReturnLength;
  iosb FormIOSB;
  int ItemsAdded, GottaFree;
  
  /* First, zero out as much of the array as we're using */
  Zero(&FormScanItemList, items == 0 ? 3: 99, ITMLST);
  
  /* Did they pass us anything? */
  if (items == 0) {

    /* Fill in the item list. Right now we just return all the forms we */
    /* can get our hands on */
    init_itemlist(&FormScanItemList[1], 1, QUI$_SEARCH_NAME,
                  WildcardSearchName, &WildcardSearchNameReturnLength);
    GottaFree = FALSE;
  } else {
    /* Call build_itemlist here... */
    ItemsAdded = build_itemlist(FormScanItemList + 1, (HV *)SvRV(ST(0)),
                                GETQUI_PARAM, OBJECT_FORM);
    GottaFree = TRUE;
  }
  /* Always want this */
  init_itemlist(&FormScanItemList[0], sizeof(FormNumberBuffer),
                QUI$_FORM_NUMBER, &FormNumberBuffer,
                &FormNumberBufferReturnLength);
  
  /* Call $GETQUI in wildcard mode */
  status = sys$getquiw(0, QUI$_DISPLAY_FORM, &FormContext,
                       FormScanItemList, &FormIOSB, NULL, 0);
  /* We just loop as long as things are OK */
  while ((status == SS$_NORMAL) && (FormIOSB.sts == JBC$_NORMAL)) {
    /* Stick the returned value on the return stack */
    XPUSHs(sv_2mortal(newSViv(FormNumberBuffer)));
    
    /* Call again */
    status = sys$getquiw(0, QUI$_DISPLAY_FORM, &FormContext,
                         FormScanItemList, &FormIOSB, NULL, 0);
  }

  /* Cancel the wildcard op, since we're done. Otherwise we leak */
  /* contexts */
  sys$getquiw(NULL, QUI$_CANCEL_OPERATION, &FormContext, NULL,
	      NULL, NULL, NULL);

  if (GottaFree) {
    tear_down_itemlist(&FormScanItemList[1], ItemsAdded);
  }
}

void
characteristic_list(...)
   PPCODE:
{
  /* variables */
  ITMLST CharacteristicScanItemList[99]; /* Yes, this should be a pointer and the */
                                /* memory should be dynamically */
                                /* allocated. When I try, wacky things */
                                /* happen, so we fall back to this hack */
  int status;
  unsigned int CharacteristicContext = -1;
  char WildcardSearchName[] = "*";
  short WildcardSearchNameReturnLength; /* Shouldn't ever need this, but */
                                        /* just in case... */
  int CharacteristicNumberBuffer;
  short CharacteristicNumberBufferReturnLength;
  iosb CharacteristicIOSB;
  int GottaFree, ItemsAdded;
  
  /* First, zero out as much of the array as we're using */
  Zero(&CharacteristicScanItemList, items == 0 ? 3: 99, ITMLST);
  
  /* Did they pass us anything? */
  if (items == 0) {

    /* Fill in the item list. Right now we just return all the */
    /* characteristics we can get our hands on */
    init_itemlist(&CharacteristicScanItemList[1], 1, QUI$_SEARCH_NAME,
                  WildcardSearchName, &WildcardSearchNameReturnLength);
    GottaFree = FALSE;
  } else {
    /* Call build_itemlist here... */
    ItemsAdded = build_itemlist(CharacteristicScanItemList + 1,
                                (HV *)SvRV(ST(0)), GETQUI_PARAM,
                                OBJECT_CHAR);
    GottaFree = TRUE;
  }
  /* Always need this */
  init_itemlist(&CharacteristicScanItemList[0], 255,
                QUI$_CHARACTERISTIC_NUMBER, &CharacteristicNumberBuffer,
                &CharacteristicNumberBufferReturnLength);
  
  /* Call $GETQUI in wildcard mode */
  status = sys$getquiw(0, QUI$_DISPLAY_CHARACTERISTIC,
                       &CharacteristicContext, CharacteristicScanItemList,
                       &CharacteristicIOSB, NULL, 0);
  /* We just loop as long as things are OK */
  while ((status == SS$_NORMAL) && (CharacteristicIOSB.sts == JBC$_NORMAL)) {
    /* Stick the returned value on the return stack */
    XPUSHs(sv_2mortal(newSViv(CharacteristicNumberBuffer)));
    
    /* Call again */
    status = sys$getquiw(0, QUI$_DISPLAY_CHARACTERISTIC,
                         &CharacteristicContext,
                         CharacteristicScanItemList, &CharacteristicIOSB,
                         NULL, 0);
  }

  /* Cancel the wildcard op, since we're done. Otherwise we leak */
  /* contexts */
  sys$getquiw(NULL, QUI$_CANCEL_OPERATION, &CharacteristicContext, NULL,
	      NULL, NULL, NULL);

  if (GottaFree) {
    tear_down_itemlist(&CharacteristicScanItemList[1], ItemsAdded);
  }
}


void
manager_list(...)
   PPCODE:
{
  /* variables */
  ITMLST ManagerScanItemList[99]; /* Yes, this should be a pointer and the */
                                /* memory should be dynamically */
                                /* allocated. When I try, wacky things */
                                /* happen, so we fall back to this hack */
  int status;
  unsigned int ManagerContext = -1;
  char WildcardSearchName[] = "*";
  short WildcardSearchNameReturnLength; /* Shouldn't ever need this, but */
                                        /* just in case... */
  char ManagerNameBuffer[255];
  short ManagerNameBufferReturnLength;
  iosb ManagerIOSB;
  int ItemsAdded, GottaFree;
  
  /* First, zero out as much of the array as we're using */
  Zero(&ManagerScanItemList, items == 0 ? 3: 99, ITMLST);
  
  /* Did they pass us anything? */
  if (items == 0) {

    /* Fill in the item list. Right now we just return all the managers we */
    /* can get our hands on */
    init_itemlist(&ManagerScanItemList[1], 1, QUI$_SEARCH_NAME,
                  WildcardSearchName, &WildcardSearchNameReturnLength);
    GottaFree = FALSE;
  } else {
    /* Call build_itemlist here... */
    ItemsAdded = build_itemlist(ManagerScanItemList + 1, (HV *)SvRV(ST(0)),
                                GETQUI_PARAM, OBJECT_MANAGER);
    GottaFree = TRUE;
  }
  /* Always need the name */
  init_itemlist(&ManagerScanItemList[0], 255, QUI$_MANAGER_NAME,
                ManagerNameBuffer, &ManagerNameBufferReturnLength);
  
  /* Call $GETQUI in wildcard mode */
  status = sys$getquiw(0, QUI$_DISPLAY_MANAGER, &ManagerContext,
                       ManagerScanItemList, &ManagerIOSB, NULL, 0);
  /* We just loop as long as things are OK */
  while ((status == SS$_NORMAL) && (ManagerIOSB.sts == JBC$_NORMAL)) {
    /* Stick the returned value on the return stack */
    XPUSHs(sv_2mortal(newSVpv(ManagerNameBuffer,
                              ManagerNameBufferReturnLength)));
    
    /* Call again */
    status = sys$getquiw(0, QUI$_DISPLAY_MANAGER, &ManagerContext,
                         ManagerScanItemList, &ManagerIOSB, NULL, 0);
  }

  /* Cancel the wildcard op, since we're done. Otherwise we leak */
  /* contexts */
  sys$getquiw(NULL, QUI$_CANCEL_OPERATION, &ManagerContext, NULL,
	      NULL, NULL, NULL);
  
  if (GottaFree) {
    tear_down_itemlist(ManagerScanItemList + 1, ItemsAdded);
  }
}


void
queue_info(QueueName)
     char *QueueName
   CODE:
{
  
  ITMLST *ListOItems;
  unsigned short ReturnBufferLength = 0;
  unsigned int QueueFlags;
  unsigned short ReturnFlagsLength;
  unsigned int Status;
  iosb QueueIOSB;
  unsigned int SubType;
  unsigned int ReturnedJBCStatus;
  
  /* If we've not gotten the count of items, go get it now */
  if (QueueItemCount == 0) {
    tote_up_items();
  }
     
  /* We need room for our item list */
  ListOItems = malloc(sizeof(ITMLST) * (QueueItemCount + 1));
  memset(ListOItems, 0, sizeof(ITMLST) * (QueueItemCount + 1));

  /* First, do a quick call to get the queue flags. We need 'em so we can */
  /* figure out what special flag we need to pass to the generic fetcher */
  init_itemlist(&ListOItems[0], strlen(QueueName), QUI$_SEARCH_NAME, QueueName,
                &ReturnBufferLength); 
  init_itemlist(&ListOItems[1], sizeof(QueueFlags), QUI$_QUEUE_FLAGS,
                &QueueFlags, &ReturnFlagsLength);

  Status = sys$getquiw(NULL, QUI$_DISPLAY_QUEUE, NULL, ListOItems,
                       &QueueIOSB, NULL, NULL);
  if (Status == SS$_NORMAL) {
    /* First, figure out the flag */
    SubType = S_QUEUE_ISAQUEUE;
    if (QueueFlags & QUI$M_QUEUE_BATCH)
      SubType |= S_QUEUE_BATCH;
    if (QueueFlags & QUI$M_QUEUE_GENERIC)
      SubType |= S_QUEUE_GENERIC;
    if (QueueFlags & QUI$M_QUEUE_PRINTER)
      SubType |= S_QUEUE_PRINTER;
    if (QueueFlags & QUI$M_QUEUE_TERMINAL)
      SubType |= S_QUEUE_TERMINAL;
    if (QueueFlags & QUI$M_QUEUE_GENERIC_SELECTION)
      SubType |= S_QUEUE_SERVER;
    
    /* Make the call to the generic fetcher and make it the return */
    /* value. We don't need to go messing with the item list, since what we */
    /* used for the last call is OK to pass along to this one. */
    ST(0) = generic_getqui_call(ListOItems, OBJECT_QUEUE, QueueItemCount,
                                QUI$_DISPLAY_QUEUE, SubType, 1,
                                JBC$_NOMOREQUE, &ReturnedJBCStatus,
                                0);
  } else {
    ST(0) = &PL_sv_undef;
    SETERRNO(EVMSERR, Status);
  }
      
  /* Give back the allocated item list memory */
  free(ListOItems);
}

void
entry_info(EntryNumber)
     int EntryNumber
   CODE:
{
  
  ITMLST *ListOItems;
  unsigned short ReturnBufferLength = 0;
  unsigned int QueueFlags;
  unsigned short QueueFlagsLength;
  unsigned int EntryFlags;
  unsigned short EntryFlagsLength;
  unsigned int Status;
  iosb EntryIOSB;
  unsigned int ReturnedJBCStatus;
  unsigned int SubType;
  
  /* If we've not gotten the count of items, go get it now */
  if (EntryItemCount == 0) {
    tote_up_items();
  }

  /* We need room for our item list */
  ListOItems = malloc(sizeof(ITMLST) * (EntryItemCount + 1));
  memset(ListOItems, 0, sizeof(ITMLST) * (EntryItemCount + 1));

  /* First, do a quick call to get the queue flags. We need 'em so we can */
  /* figure out what special flag we need to pass to the generic fetcher */
  init_itemlist(&ListOItems[0], sizeof(EntryNumber), QUI$_SEARCH_NUMBER,
                &EntryNumber, &ReturnBufferLength); 
  init_itemlist(&ListOItems[1], sizeof(QueueFlags), QUI$_QUEUE_FLAGS,
                &QueueFlags, &QueueFlagsLength);
  init_itemlist(&ListOItems[2], sizeof(EntryFlags), QUI$_JOB_STATUS,
                &EntryFlags, &EntryFlagsLength);
  
  
  Status = sys$getquiw(NULL, QUI$_DISPLAY_ENTRY, NULL, ListOItems,
                       &EntryIOSB, NULL, NULL);
  if (Status == SS$_NORMAL) {
    /* The flags tell us what queue type we're on, so we can figure out what */
    /* type of entry we are */
    SubType = 0;
    if (QueueFlags & QUI$M_QUEUE_BATCH)
      SubType |= S_ENTRY_BATCH;
    if ((QueueFlags & QUI$M_QUEUE_GENERIC) && !(QueueFlags &
                                                QUI$M_QUEUE_BATCH))
      SubType |= S_ENTRY_PRINT;
    if (QueueFlags & QUI$M_QUEUE_PRINTER)
      SubType |= S_ENTRY_PRINT;
    if (QueueFlags & QUI$M_QUEUE_TERMINAL)
      SubType |= S_ENTRY_PRINT;
    if ((EntryFlags & QUI$M_JOB_RETAINED) ||
	(EntryFlags & QUI$M_JOB_REFUSED) ||
	(EntryFlags & QUI$M_JOB_PENDING) ||
	(EntryFlags & QUI$M_JOB_SUSPENDED))
      SubType |= S_ENTRY_DONE;
    if (!SubType) SubType |= S_ENTRY_PRINT;

    /* Make the call to the generic fetcher and make it the return */
    /* value. We don't need to go messing with the item list, since what we */
    /* used for the last call is OK to pass along to this one. */
    ST(0) = generic_getqui_call(ListOItems, OBJECT_ENTRY, EntryItemCount,
                                QUI$_DISPLAY_ENTRY, SubType, 1,
                                JBC$_NOMOREENT, &ReturnedJBCStatus, 0);
  } else {
    ST(0) = &PL_sv_undef;
    SETERRNO(EVMSERR, Status);
  }
      
  /* Give back the allocated item list memory */
  free(ListOItems);
}

void
form_info(FormNumber)
     int FormNumber
   CODE:
{
  
  ITMLST *ListOItems;
  unsigned short ReturnBufferLength = 0;
  unsigned int SubType;
  unsigned int ReturnedJBCStatus;
  
  /* If we've not gotten the count of items, go get it now */
  if (FormItemCount == 0) {
    tote_up_items();
  }

  /* We need room for our item list */
  ListOItems = malloc(sizeof(ITMLST) * (FormItemCount + 1));
  memset(ListOItems, 0, sizeof(ITMLST) * (FormItemCount + 1));

  /* First, do a quick call to get the queue flags. We need 'em so we can */
  /* figure out what special flag we need to pass to the generic fetcher */
  init_itemlist(&ListOItems[0], sizeof(FormNumber), QUI$_SEARCH_NUMBER,
                &FormNumber, &ReturnBufferLength); 

  /* No special bits for forms, so get everything */
  SubType = S_ANY;

  /* Make the call to the generic fetcher and make it the return */
  /* value. We don't need to go messing with the item list, since what we */
  /* used for the last call is OK to pass along to this one. */
  ST(0) = generic_getqui_call(ListOItems, OBJECT_FORM, FormItemCount,
                              QUI$_DISPLAY_FORM, SubType, 1,
                              JBC$_NOMOREFORM, &ReturnedJBCStatus, 0);
      
  /* Give back the allocated item list memory */
  free(ListOItems);
}

void
manager_info(ManagerName)
     char *ManagerName
   CODE:
{
  
  ITMLST *ListOItems;
  unsigned short ReturnBufferLength = 0;
  unsigned int SubType;
  unsigned int ReturnedJBCStatus;
  
  /* If we've not gotten the count of items, go get it now */
  if (ManagerItemCount == 0) {
    tote_up_items();
  }
     
  /* We need room for our item list */
  ListOItems = malloc(sizeof(ITMLST) * (ManagerItemCount + 1));
  memset(ListOItems, 0, sizeof(ITMLST) * (ManagerItemCount + 1));

  /* First, do a quick call to get the queue flags. We need 'em so we can */
  /* figure out what special flag we need to pass to the generic fetcher */
  init_itemlist(&ListOItems[0], strlen(ManagerName), QUI$_SEARCH_NAME,
                ManagerName, &ReturnBufferLength);

  /* No subtype--we just go for it */
  SubType = S_ANY;

  /* Make the call to the generic fetcher and make it the return */
  /* value. We don't need to go messing with the item list, since what we */
  /* used for the last call is OK to pass along to this one. */
  ST(0) = generic_getqui_call(ListOItems, OBJECT_MANAGER, ManagerItemCount,
                              QUI$_DISPLAY_MANAGER, SubType, 1,
                              JBC$_NOMOREQMGR, &ReturnedJBCStatus, 0);
      
  /* Give back the allocated item list memory */
  free(ListOItems);
}

SV *
queue_properties()
   ALIAS:
     entry_properties = 1
     file_properties = 2
     form_properties = 3
     characteristic_properties = 4
     manager_properties = 5
   CODE:
{
  int object_type;
  HV *GenericPropHV;
  GenericPropHV = newHV();
  switch(ix) {
  case 0:
    object_type = OBJECT_QUEUE;
    break;
  case 1:
    object_type = OBJECT_ENTRY;
    break;
  case 2:
    object_type = OBJECT_FILE;
    break;
  case 3:
    object_type = OBJECT_FORM;
    break;
  case 4:
    object_type = OBJECT_CHAR;
    break;
  case 5:
    object_type = OBJECT_MANAGER;
    break;
  }
  ST(0) = newRV_noinc(generic_valid_properties(GenericPropHV, object_type));
}

SV *
queue_bitmap_decode(InfoName, BitmapValue)
     char *InfoName
     int BitmapValue
   ALIAS:
     entry_bitmap_decode = 1
     file_bitmap_decode = 2
     form_bitmap_decode = 3
     characteristic_bitmap_decode = 4
     manager_bitmap_decode = 5
   CODE:
{
  ST(0) = generic_bitmap_decode(InfoName, BitmapValue);
}

SV *
delete_entry(EntryNumber)
     int EntryNumber
   ALIAS:
     hold_entry = 1
     release_entry = 2
   CODE:
{
  ITMLST NukeItemList[2];
  int Status;
  short ReturnLength;
  iosb KillIOSB;
  int SndJbcCode;

  /* Clear the item list */
  memset(NukeItemList, 0, sizeof(ITMLST) * 2);

  switch(ix) {
  case 0:
    SndJbcCode = SJC$_DELETE_JOB;
    init_itemlist(&NukeItemList[0], sizeof(EntryNumber), SJC$_ENTRY_NUMBER,
                  &EntryNumber, &ReturnLength);
    break;
  case 1:
    SndJbcCode = SJC$_ALTER_JOB;
    init_itemlist(&NukeItemList[0], sizeof(EntryNumber), SJC$_ENTRY_NUMBER,
                  &EntryNumber, &ReturnLength);
    init_itemlist(&NukeItemList[1], 0, SJC$_HOLD, NULL, NULL);
    break;
  case 2:
    SndJbcCode = SJC$_ALTER_JOB;
    init_itemlist(&NukeItemList[0], sizeof(EntryNumber), SJC$_ENTRY_NUMBER,
                  &EntryNumber, &ReturnLength);
    init_itemlist(&NukeItemList[1], 0, SJC$_NO_HOLD, NULL, NULL);
    break;
  }    
  
  /* make the call */
  Status = sys$sndjbcw(0, SndJbcCode, 0, NukeItemList, &KillIOSB,
                       NULL, NULL);

  /* If there's an abnormal return, then note it */
  if (Status != SS$_NORMAL) {
    SETERRNO(EVMSERR, Status);
    ST(0) = &PL_sv_undef;
  } else {
    /* We returned SS$_NORMAL. Was there another problem? */
    if (KillIOSB.sts != JBC$_NORMAL) {
      croak(decode_jbc(KillIOSB.sts));
    } else {
      /* Guess everything's OK. Exit normally */
      ST(0) = &PL_sv_yes;
    }
  }
}
  
SV *
delete_form(FormName)
     char *FormName
   CODE:
{
  ITMLST NukeItemList[2];
  int Status;
  short ReturnLength;
  iosb KillIOSB;
  
  /* Clear the item list */
  memset(NukeItemList, 0, sizeof(ITMLST) * 2);

  /* Fill the list in */
  init_itemlist(&NukeItemList[0], strlen(FormName), SJC$_FORM_NAME,
                FormName, &ReturnLength);

  /* make the call */
  Status = sys$sndjbcw(0, SJC$_DELETE_FORM, 0, NukeItemList, &KillIOSB,
                       NULL, NULL);

  /* If there's an abnormal return, then note it */
  if (Status != SS$_NORMAL) {
    SETERRNO(EVMSERR, Status);
    ST(0) = &PL_sv_undef;
  } else {
    /* We returned SS$_NORMAL. Was there another problem? */
    if (KillIOSB.sts != JBC$_NORMAL) {
      croak(decode_jbc(KillIOSB.sts));
    } else {
      /* Guess everything's OK. Exit normally */
      ST(0) = &PL_sv_yes;
    }
  }
}

  
SV *
delete_characteristic(CharacteristicName)
     char *CharacteristicName
   CODE:
{
  ITMLST NukeItemList[2];
  int Status;
  short ReturnLength;
  iosb KillIOSB;
  
  /* Clear the item list */
  memset(NukeItemList, 0, sizeof(ITMLST) * 2);

  /* Fill the list in */
  init_itemlist(&NukeItemList[0], strlen(CharacteristicName),
                SJC$_CHARACTERISTIC_NAME, CharacteristicName,
                &ReturnLength);

  /* make the call */
  Status = sys$sndjbcw(0, SJC$_DELETE_CHARACTERISTIC, 0, NukeItemList,
                       &KillIOSB, NULL, NULL);

  /* If there's an abnormal return, then note it */
  if (Status != SS$_NORMAL) {
    SETERRNO(EVMSERR, Status);
    ST(0) = &PL_sv_undef;
  } else {
    /* We returned SS$_NORMAL. Was there another problem? */
    if (KillIOSB.sts != JBC$_NORMAL) {
      croak(decode_jbc(KillIOSB.sts));
    } else {
      /* Guess everything's OK. Exit normally */
      ST(0) = &PL_sv_yes;
    }
  }
}

  
SV *
delete_queue(QueueName)
     char *QueueName
   ALIAS:
     stop_queue = 1
     pause_queue = 2
     start_queue = 3
     reset_queue = 4
   CODE:
{
  ITMLST NukeItemList[2];
  int Status;
  short ReturnLength;
  iosb KillIOSB;
  int SndJbcCode;

  switch(ix) {
  case 0:
    SndJbcCode = SJC$_DELETE_QUEUE;
    break;
  case 1:
    SndJbcCode = SJC$_STOP_QUEUE;
    break;
  case 2:
    SndJbcCode = SJC$_PAUSE_QUEUE;
    break;
  case 3:
    SndJbcCode = SJC$_START_QUEUE;
    break;
  case 4:
    SndJbcCode = SJC$_RESET_QUEUE;
    break;
  }
  
  /* Clear the item list */
  memset(NukeItemList, 0, sizeof(ITMLST) * 2);

  /* Fill the list in */
  init_itemlist(&NukeItemList[0], strlen(QueueName), SJC$_QUEUE,
                QueueName, &ReturnLength);

  /* make the call */
  Status = sys$sndjbcw(0, SndJbcCode, 0, NukeItemList, &KillIOSB,
                       NULL, NULL);

  /* If there's an abnormal return, then note it */
  if (Status != SS$_NORMAL) {
    SETERRNO(EVMSERR, Status);
    ST(0) = &PL_sv_undef;
  } else {
    /* We returned SS$_NORMAL. Was there another problem? */
    if (KillIOSB.sts != JBC$_NORMAL) {
      croak(decode_jbc(KillIOSB.sts));
    } else {
      /* Guess everything's OK. Exit normally */
      ST(0) = &PL_sv_yes;
    }
  }
}
  
SV *
start_manager(ManagerName)
     char *ManagerName
   ALIAS:
     stop_manager = 1
     delete_manager = 2
   CODE:
{
  ITMLST NukeItemList[2];
  int Status;
  short ReturnLength;
  iosb KillIOSB;
  int SndJbcCode;
  
  /* Clear the item list */
  memset(NukeItemList, 0, sizeof(ITMLST) * 2);

  /* Fill the list in */
  init_itemlist(&NukeItemList[0], strlen(ManagerName),
                SJC$_QUEUE_MANAGER_NAME, ManagerName, &ReturnLength);

  switch(ix) {
  case 0:
    SndJbcCode = SJC$_START_QUEUE_MANAGER;
    break;
  case 1:
    SndJbcCode = SJC$_STOP_QUEUE_MANAGER;
    break;
  case 2:
    SndJbcCode = SJC$_DELETE_QUEUE_MANAGER;
    break;
  }
    
  /* make the call */
  Status = sys$sndjbcw(0, SndJbcCode, 0, NukeItemList,
                       &KillIOSB, NULL, NULL);

  /* If there's an abnormal return, then note it */
  if (Status != SS$_NORMAL) {
    SETERRNO(EVMSERR, Status);
    ST(0) = &PL_sv_undef;
  } else {
    /* We returned SS$_NORMAL. Was there another problem? */
    if (KillIOSB.sts != JBC$_NORMAL) {
      croak(decode_jbc(KillIOSB.sts));
    } else {
      /* Guess everything's OK. Exit normally */
      ST(0) = &PL_sv_yes;
    }
  }
}

void
submit(...)
   PPCODE:
{
  ITMLST EntryItemList[99]; /* For the whole entry */
  ITMLST FileItemList[99]; /* For each file in the list */
  int Status, ItemCount, FileNum;
  iosb EntryIOSB, FileIOSB;
  unsigned int EntryNumber;
  unsigned short EntryNumberLength;
  char CroakString[1024];
  SV *TempSV;
  
  /* very simple error check */
  if (items < 2) {
    croak("Invalid number of arguments passed");
  }

  for(ItemCount = 0; ItemCount < items; ItemCount++) {
    if (!SvROK(ST(ItemCount))) {
      sprintf(CroakString, "Item %i isn't a reference", ItemCount + 1);
      croak(CroakString);
    }

    TempSV = SvRV(ST(ItemCount));
    if (SvTYPE(TempSV) != SVt_PVHV) {
      sprintf(CroakString, "Item %i isn't a hashref", ItemCount + 1);
      croak(CroakString);
    }
  }
  
  /* First, build the item list for the create job call */
  if (0 == (ItemCount = build_itemlist(EntryItemList,
                                       (HV *)SvRV(ST(0)), 
                                       SNDJBC_PARAM, OBJECT_ENTRY))) {
    croak("Bad code in entry item list");
  }
  /* Tack on the entry number, so we can return it when we're done */
  init_itemlist(&EntryItemList[ItemCount], 4, SJC$_ENTRY_NUMBER_OUTPUT,
                &EntryNumber, &EntryNumberLength);

  /* Zero out the next item (the end of list marker) */
  Zero(&EntryItemList[ItemCount+1], 1, ITMLST);
  
  /* Okay, open the entry */
  Status = sys$sndjbcw(NULL, SJC$_CREATE_JOB, NULL, EntryItemList,
                       &EntryIOSB, NULL, NULL);

  /* Clean out the item list & give tme memory back to the system */
  tear_down_itemlist(EntryItemList, ItemCount);

  /* Did it fail somehow? */
  if (Status != SS$_NORMAL) {
    SETERRNO(EVMSERR, Status);
    XSRETURN_UNDEF;
  } else {
    if (EntryIOSB.sts != JBC$_NORMAL) {
      SETERRNO(EVMSERR, Status);
      sprintf(CroakString, "Error %i (%s) creating job", EntryIOSB.sts,
              decode_jbc(FileIOSB.sts));
      croak(CroakString);
    }
  }

  /* 'Kay, opened the entry just fine. Run through all the files in the */
  /* entry */ 
  for(FileNum = 1; FileNum < items; FileNum++) {
    if (0 == (ItemCount = build_itemlist(FileItemList,
                                         (HV *)SvRV(ST(FileNum)),
                                         SNDJBC_PARAM,
                                         OBJECT_FILE))) {
      croak("Bad code in file item list");
    }

    /* Zero out the next item (the end of list marker) */
    Zero(&FileItemList[ItemCount], 1, ITMLST);
    
    /* Okay, add the file */
    Status = sys$sndjbcw(NULL, SJC$_ADD_FILE, NULL, FileItemList,
                         &FileIOSB, NULL, NULL);

    /* Give back the memory */
    tear_down_itemlist(FileItemList, ItemCount);
    
    /* Did it fail somehow? */
    if (Status != SS$_NORMAL) {
      SETERRNO(EVMSERR, Status);
      XSRETURN_UNDEF;
    } else {
      if (FileIOSB.sts != JBC$_NORMAL) {
        SETERRNO(EVMSERR, Status);
        sprintf(CroakString, "Error %i (%s) adding file", FileIOSB.sts,
                decode_jbc(FileIOSB.sts));
        croak(CroakString);
      }
    }
  }

  /* Well, all the files must've entered OK. Close the job, which submits */
  Status = sys$sndjbcw(NULL, SJC$_CLOSE_JOB, NULL, NULL, &EntryIOSB, NULL,
                       NULL);
  /* Did it fail somehow? Shouldn't, but you never know */
  if (Status != SS$_NORMAL) {
    SETERRNO(EVMSERR, Status);
    XSRETURN_UNDEF;
  } else {
    if (EntryIOSB.sts != JBC$_NORMAL) {
      SETERRNO(EVMSERR, Status);
      sprintf(CroakString, "Error %i (%s) closing job", EntryIOSB.sts,
              decode_jbc(FileIOSB.sts));
      croak(CroakString);
    }
  }
  
  /* Right then. Return the entry number and be done with it */
  XPUSHs(sv_2mortal(newSViv(EntryNumber)));
  XSRETURN(1);
}

void
create_queue(...)
   ALIAS:
     modify_queue = 1
     modify_entry = 2
     create_form = 3
     create_characteristic = 4
   PPCODE:
{
  ITMLST ItemList[99]; 
  int Status, ItemCount;
  iosb IOSB;
  char CroakString[1024];
  long SNDJBCCode[] = {SJC$_CREATE_QUEUE, SJC$_ALTER_QUEUE, SJC$_ALTER_JOB,
                         SJC$_DEFINE_FORM,
                         SJC$_DEFINE_CHARACTERISTIC};
  long ObjectType[] = {OBJECT_QUEUE, OBJECT_QUEUE, OBJECT_ENTRY,
                         OBJECT_FORM, OBJECT_CHAR};
  char *CroakMessages[] = { "Error %i (%s) creating queue",
                             "Error %i (%s) modifying queue",
                             "Error %i (%s) modifying entry",
                             "Error %i (%s) creating form",
                             "Error %i (%s) creating characteristic"};
  SV *TempSV;
  
  /* very simple error check */
  if (items != 1) {
    croak("Invalid number of arguments passed");
  }

  /* Check to make sure it's a reference */
  if (!SvROK(ST(0))) {
    croak("Passed parameter isn't a hashref");
  }

  TempSV = SvRV(ST(0));
  if (SvTYPE(TempSV) != SVt_PVHV) {
    croak("Passed parameter isn't a hashref");
  }

  /* First, build the item list for the call */
  if (0 == (ItemCount = build_itemlist(ItemList,
                                       (HV *)SvRV(ST(0)), 
                                       SNDJBC_PARAM, ObjectType[ix]))) {
    croak("Bad code in  item list");
  }

  /* Zero out the next item (the end of list marker) */
  Zero(&ItemList[ItemCount], 1, ITMLST);
  
  /* Make the call */
  Status = sys$sndjbcw(NULL, SNDJBCCode[ix], NULL, ItemList,
                       &IOSB, NULL, NULL);

  /* Clean out the item list & give tme memory back to the system */
  tear_down_itemlist(ItemList, ItemCount);

  /* Did it fail somehow? */
  if (Status != SS$_NORMAL) {
    SETERRNO(EVMSERR, Status);
    XSRETURN_UNDEF;
  } else {
    if (IOSB.sts != JBC$_NORMAL) {
      SETERRNO(EVMSERR, Status);
      sprintf(CroakString, CroakMessages[ix], IOSB.sts, decode_jbc(IOSB.sts));
      croak(CroakString);
    }
  }
  
  /* Things went OK--say so */
  XSRETURN_YES;
}

