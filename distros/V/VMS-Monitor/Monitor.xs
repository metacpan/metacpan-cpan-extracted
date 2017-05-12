/* MONITOR.XS - yank the monitor info out of the system via the */
/* undocumented exe$GETSPI call (that lives in SYS$SHARE:SYISHR.EXE) and */
/* make it available to running perl programs, lucky them.

   Some gotchas so far:

   1) For some reason I don't understand, the scs_info array is returned
   offset by 4 bytes, which is to say, rather than returning the data
   starting at the beginning of the buffer we pass, it returns it starting
   in by 4 bytes. Go figure.

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
#include <prcdef.h>
#include <pcbdef.h>
#include <pscandef.h>
#include <lib$routines.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#pragma nomember_alignment
struct scs_info {
  int scs_nodename[2];
  int scs_dgsent;
  int scs_dgrcvd;
  int scs_dgdiscard;
  int scs_msgsent;
  int scs_msgrcvd;
  int scs_snddats;
  int scs_kbytsent;
  int scs_reqdats;
  int scs_kbytreqd;
  int scs_kbytmapd;
  int scs_qcr_cnt;
  int scs_qbdt_cnt;
} ;

struct disk_info {
  char disk_alloclass;
  int disk_devname[1];
  short int disk_unitnum;
  char disk_flags;
  int disk_nodename[2];
  int disk_volname[3];
  int disk_optcnt;
  int disk_qcount;
};

struct proc_info {
  int proc_ipid;
  int proc_uic;
  short int proc_state;
  char proc_pri;
  int proc_lname[4];
  int proc_gpgcnt;
  int proc_ppgcnt;
  int proc_sts;
  int proc_diocnt;
  int proc_pageflts;
  int proc_cputim;
  int proc_biocnt;
  int proc_epid;
  int proc_efwm;
  int proc_rbstran;
};

struct mode_info {
  char cpu_id;
  int interrupt_time;
  int mpsync_time;
  int kernel_time;
  int exec_time;
  int super_time;
  int user_time;
  int compatibility_time;
  int idle_time;
};
#pragma member_alignment

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

/* Prototype for exe$getspi. Takes an event flag pointer, a CSID pointer
   (unused), a pointer to a string descriptor with the nodename (unused), a
   pointer to an itemlist, a pointer to an IOSB structure, a pointer to an
   AST completion routine, and a pointer to an AST routine parameter.

   This info snagged from the SYSGETSPI.MAR module off the VMS listing CD.
*/
short exe$getspi(int, void *, void *, void *, void *, void *, long *);

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

#define HV_KEY(a) #a, strlen(a)

#define bit_test(HVPointer, BitToCheck, HVEntryName, EncodedMask) \
{ \
    if ((EncodedMask) & (BitToCheck)) \
    hv_store((HVPointer), (HVEntryName), strlen((HVEntryName)), &PL_sv_yes, 0); \
    else \
    hv_store((HVPointer), (HVEntryName), strlen((HVEntryName)), &PL_sv_no, 0);}   

#define IS_STRING 1
#define IS_LONGWORD 2
#define IS_QUADWORD 3
#define IS_WORD, 4
#define IS_BYTE 5
#define IS_VMSDATE 6
#define IS_BITMAP 7   /* Each bit in the return value indicates something */
#define IS_ENUM 8     /* Each returned value has a name, and we ought to */
                      /* return the name instead of the value */
#define IS_BOOL 9     /* This is a boolean item--its existence means true */
#define IS_SCS 10     /* SCS class, i.e. cluster info. */
#define IS_PROCESS 11 /* Process class--returns lots of info */
#define IS_DISK 12    /* Disk class--returns lots of info too */
#define IS_MODE 13    /* CPU modes class */

#define NUM_SCS 96    /* Max # of SCS entries we can get, which is the max */
                      /* # of machines in a cluster. We probably ought to */
                      /* dynamically calculate this so as not to waste */
                      /* memory, but it's really not that much */
#define NUM_DISKS 5000 /* Once again, ought to be dynamic. But memory's */
                       /* cheap, right? :-) */
#define NUM_PROCESS 1000 /* This is probably too low, but we'll have to */
                         /* cope. Should go dynamic some day */
#define NUM_CPUS 256   /* I suppose we could have more, but that seems */
                       /* unlikely. */

#define IS_SINGLE 1

/* Yeah, this is fairly pointless, but it's there in case I get clever some */
/* time later */
#define MONDEF(a, b, c, d, e) {#a, b, c, d, e}

/* Macro to fill in a $PROCESS_SCAN literal item list entry */
#define init_bufitemlist(ile, length, code, bufaddr, flags) \
{ \
    (ile)->BufferItem.buflen = (length); \
    (ile)->BufferItem.itmcode = (code); \
    (ile)->BufferItem.buffer = (bufaddr); \
    (ile)->BufferItem.itemflags = (flags) ;}

/* Macro to fill in a process_scan literal item list entry */
#define init_lititemlist(ile, code, itemval, flags) \
{ \
    (ile)->LiteralItem.buflen = 0; \
    (ile)->LiteralItem.itmcode = (code); \
    (ile)->LiteralItem.itemvalue = (itemval); \
    (ile)->LiteralItem.itemflags = (flags) ;}

/* Macro to fill in a 'traditional' item-list entry */
#define init_itemlist(ile, length, code, bufaddr, retlen_addr) \
{ \
    (ile)->TradItem.buflen = (length); \
    (ile)->TradItem.itmcode = (code); \
    (ile)->TradItem.buffer = (bufaddr); \
    (ile)->TradItem.retlen = (retlen_addr) ;}

struct MonInfo {
  char *InfoName;  /* Pointer to the name of the monitor info */
  int GetSPIValue; /* Value to use for the GETSPI call */
  int ReturnType;  /* Type of info it returns */
  int BufferLen;   /* Length of the buffer this item takes */
  int ItemType;    /* Is the return value a singular thing, or a list? */
};

struct MonInfo MonitorInfoList[] = {
    MONDEF(MODES, 4096, IS_MODE, sizeof(struct mode_info) * NUM_CPUS, IS_SINGLE),
    MONDEF(INTERRUPT, 4097, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(KERNEL, 4098, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(EXEC, 4099, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(SUPER, 4100, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(USER, 4101, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(COMPAT, 4102, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(INTERRUPT_BUSY, 4103, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(KERNEL_BUSY, 4104, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(IDLE, 4105, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(CPUBUSY, 4106, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(COLPG, 4107, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(MWAIT, 4108, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(CEF, 4109, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(PFW, 4110, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(LEF, 4111, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(LEFO, 4112, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(HIB, 4113, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(HIBO, 4114, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(SUSP, 4115, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(SUSPO, 4116, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(FPG, 4117, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(COM, 4118, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(COMO, 4119, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(CUR, 4120, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(OTHSTAT, 4121, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(PROCS, 4122, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(PROC, 4123, IS_PROCESS, sizeof(struct proc_info) * NUM_PROCESS, IS_SINGLE),
    MONDEF(FRLIST, 4124, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(MODLIST, 4125, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(FAULTS, 4126, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(PREADS, 4127, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(PWRITES, 4128, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(PWRITIO, 4129, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(PREADIO, 4130, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(GVALFLTS, 4131, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(WRTINPROG, 4132, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(FREFLTS, 4133, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(MFYFLTS, 4134, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(DZROFLTS, 4135, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(SYSFAULTS, 4136, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(LRPCNT, 4137, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(LRPINUSE, 4138, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(IRPCNT, 4139, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(IRPINUSE, 4140, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(SRPCNT, 4141, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(SRPINUSE, 4142, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(HOLECNT, 4143, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(BIGHOLE, 4144, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(SMALLHOLE, 4145, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(HOLESUM, 4146, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(DYNINUSE, 4147, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(SMALLCNT, 4148, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(ISWPCNT, 4149, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(DIRIO, 4150, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(BUFIO, 4151, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(MBREADS, 4152, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(MBWRITES, 4153, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(LOGNAM, 4154, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(FCPCALLS, 4155, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(FCPREAD, 4156, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(FCPWRITE, 4157, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(FCPCACHE, 4158, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(FCPCPU, 4159, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(FCPHIT, 4160, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(FCPSPLIT, 4161, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(FCPFAULT, 4162, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(ENQNEW, 4163, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(ENQCVT, 4164, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(DEQ, 4165, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(BLKAST, 4166, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(ENQWAIT, 4167, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(ENQNOTQD, 4168, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(DLCKSRCH, 4169, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(DLCKFND, 4170, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(NUMLOCKS, 4171, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(NUMRES, 4172, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(ARRLOCPK, 4173, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(DEPLOCPK, 4174, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(ARRTRAPK, 4175, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(TRCNGLOS, 4176, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(RCVBUFFL, 4177, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(FID_TRIES, 4196, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(FILHDR_TRIES, 4197, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(DIRFCB_TRIES, 4198, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(DIRDATA_TRIES, 4199, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(EXT_TRIES, 4200, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(QUO_TRIES, 4201, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(STORAGMAP_TRIES, 4202, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(DISKS, 4203, IS_DISK, sizeof(struct disk_info) * NUM_DISKS, IS_SINGLE),
    MONDEF(TOTAL_LOCKS, 4204, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(ENQNEWLOC, 4205, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(ENQNEWIN, 4206, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(ENQNEWOUT, 4207, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(ENQCVTLOC, 4208, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(ENQCVTIN, 4209, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(ENQCVTOUT, 4210, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(DEQLOC, 4211, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(DEQIN, 4212, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(DEQOUT, 4213, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(BLKLOC, 4214, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(BLKIN, 4215, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(BLKOUT, 4216, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(DIRIN, 4217, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(DIROUT, 4218, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(DLCKMSGS, 4219, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(SCS, 4220, IS_SCS, sizeof(struct scs_info) * NUM_SCS, IS_SINGLE),
    MONDEF(SYSTIME, 4221, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(MSCP_REQUEST, 4222, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(MSCP_READ, 4223, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(MSCP_WRITE, 4224, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(MSCP_FRAGMENT, 4225, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(MSCP_SPLIT, 4226, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(MSCP_BUFWAIT, 4227, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(MSCP_SIZE1, 4228, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(MSCP_SIZE2, 4229, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(MSCP_SIZE3, 4230, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(MSCP_SIZE4, 4231, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(MSCP_SIZE5, 4232, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(MSCP_SIZE6, 4233, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(MSCP_SIZE7, 4234, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(MSCP_ALL, 4235, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(DDTM_STARTS, 4236, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(DDTM_PREPARES, 4237, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(DDTM_ONE_PHASE, 4238, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(DDTM_COMMITS, 4239, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(DDTM_ABORTS, 4240, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(DDTM_ENDS, 4241, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(DDTM_BRANCHS, 4242, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(DDTM_ADDS, 4243, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(DDTM_BUCKETS1, 4244, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(DDTM_BUCKETS2, 4245, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(DDTM_BUCKETS3, 4246, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(DDTM_BUCKETS4, 4247, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(DDTM_BUCKETS5, 4248, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(DDTM_BUCKETS6, 4249, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(DDTM_ALL, 4250, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(VECTORP, 4251, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(VBYTE_READ, 4252, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(VBYTE_WRITE, 4253, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(VVBS_TRAN, 4254, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(VRBS_TRAN, 4255, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(VDIO_SEL, 4256, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(VDIOMAP_ALLOC, 4257, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(VRBS_AVAIL, 4258, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(VSEL_FAIL, 4259, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(VVBSM_HIT, 4260, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(VVBSM_CACHE, 4261, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(VFLUIDBAL, 4262, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(VRECOPY, 4263, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(VCPUTICKS, 4264, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(ACCESS, 8432, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(ALLOC, 8433, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(FCPCREATE, 8434, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(VOLWAIT, 8435, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(FCPTURN, 8436, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(FCPERASE, 8437, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(OPENS, 8438, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(FIDHIT, 8439, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(FIDMISS, 8440, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(FILHDR_HIT, 8441, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(DIRFCB_HIT, 8442, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(DIRFCB_MISS, 8443, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(DIRDATA_HIT, 8444, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(EXTHIT, 8445, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(EXTMISS, 8446, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(QUOHIT, 8447, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(QUOMISS, 8448, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(STORAGMAP_HIT, 8449, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(VOLLCK, 8450, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(SYNCHLCK, 8451, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(SYNCHWAIT, 8452, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(ACCLCK, 8453, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(XQPCACHEWAIT, 8454, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(FIDHITPCNT, 12651, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(FILHDR_HITPCNT, 12652, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(DIRFCB_HITPCNT, 12653, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(DIRDATA_HITPCNT, 12654, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(EXTHITPCNT, 12655, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(QUOHITPCNT, 12656, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(STORAGMAP_HITPCNT, 12657, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(OPCNT, 12658, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(IOQUELEN, 12659, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(IOAQUELEN, 12660, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(DISKRESPTIM, 12661, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(JNLIOCNT, 12662, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(JDNQLEN, 12663, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(JDWQLEN, 12664, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(JDFQLEN, 12665, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(JDEXCNT, 12666, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(JNLWRTSS, 12667, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(JNLBUFWR, 12668, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(DGSENT, 12669, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(DGRCVD, 12670, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(DGDISCARD, 12671, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(MSGSENT, 12672, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(MSGRCVD, 12673, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(SNDATS, 12674, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(KBYTSENT, 12675, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(REQDATS, 12676, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(KBYTREQD, 12677, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(KBYTMAPD, 12678, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(QCR_CNT, 12679, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(QBDT_CNT, 12680, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(DIRLOOK, 12681, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(DIRINS, 12682, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(DIRDEL, 12683, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(PACKETS, 12684, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(KBYTES, 12685, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(PACKETSIZE, 12686, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(MPACKETS, 12687, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(MKBYTES, 12688, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(MPACKETSIZE, 12689, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(SINGLECOLL, 12690, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(MULTICOLL, 12691, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(INITDEFER, 12692, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(INTERNALBUFERR, 12693, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(LOCBUFERR, 12694, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(BUFFUNAVAIL, 12695, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(FILLER, 12696, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(RMS_STATS, 16893, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(SEQGETS, 16894, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(KEYGETS, 16895, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(RFAGETS, 16896, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(GETBYTES, 16897, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(SEQPUTS, 16898, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(KEYPUTS, 16899, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(PUTBYTES, 16900, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(UPDATES, 16901, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(UPDATEBYTES, 16902, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(DELETES, 16903, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(TRUNCATES, 16904, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(TRUNCBLKS, 16905, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(SEQFINDS, 16906, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(KEYFINDS, 16907, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(RFAFINDS, 16908, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(READS, 16909, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(READBYTES, 16910, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(CONNECTS, 16911, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(DISCONNECTS, 16912, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(EXTENDS, 16913, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(EXTBLOCKS, 16914, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(FLUSHES, 16915, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(REWINDS, 16916, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(WRITES, 16917, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(WRITEBYTES, 16918, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(FLCKENQS, 16919, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(FLCKDEQS, 16920, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(FLCKCNVS, 16921, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(LBLCKENQS, 16922, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(LBLCKDEQS, 16923, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(LBLCKCNVS, 16924, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(GBLCKENQS, 16925, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(GBLCKDEQS, 16926, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(GBLCKCNVS, 16927, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(GSLCKENQS, 16928, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(GSLCKDEQS, 16929, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(GSLCKCNVS, 16930, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(RLCKENQS, 16931, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(RLCKDEQS, 16932, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(RLCKCNVS, 16933, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(APPLCKENQS, 16934, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(APPLCKDEQS, 16935, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(APPLCKCNVS, 16936, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(FLBLKASTS, 16937, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(LBLBLKASTS, 16938, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(GBLBLKASTS, 16939, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(APPBLKASTS, 16940, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(LCACHEHITS, 16941, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(LCACHETRIES, 16942, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(GCACHEHITS, 16943, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(GCACHETRIES, 16944, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(GBRDIRIOS, 16945, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(GBWDIRIOS, 16946, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(LBRDIRIOS, 16947, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(LBWDIRIOS, 16948, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(BKTSPLT, 16949, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(MBKTSPLT, 16950, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(RMSOPENS, 16951, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(CLOSES, 16952, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(GSBLKASTS, 16953, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(FLWAITS, 16954, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(LBWAITS, 16955, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(GBWAITS, 16956, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(GSWAITS, 16957, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(RLWAITS, 16958, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(APWAITS, 16959, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(TOTWAITS, 16960, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(OUTBUFQUO, 16961, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(RMSDEV1, 16962, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(RMSDEV2, 16963, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(RMSDEV3, 16964, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(RMSDEV4, 16965, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(RMSDEV5, 16966, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(RMSDEV6, 16967, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(RMSDEV7, 16968, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(RMSDEV8, 16969, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(RMSDEV9, 16970, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(RMSDEV10, 16971, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(RMSDEV11, 16972, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(RMSDEV12, 16973, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(RMSDEV13, 16974, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(RMSDEV14, 16975, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(RMSDEV15, 16976, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(XQPQIOS, 16977, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(LCACHEHITPCNT, 16978, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(GCACHEHITPCNT, 16979, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(TOTALGET, 16980, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(TOTALPUT, 16981, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(TOTALFIND, 16982, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(BYTESGET, 16983, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(BYTESPUT, 16984, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(BYTESUPDATE, 16985, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(BYTESREAD, 16986, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(BYTESWRITE, 16987, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(BLOCKSTRUNCATE, 16988, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(BLOCKSEXTEND, 16989, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(ACTIVE_STREAMS, 16990, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(TOTAL_ENQS, 16991, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(TOTAL_DEQS, 16992, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(TOTAL_CNVS, 16993, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(TOTAL_BLKAST, 16994, IS_LONGWORD, 4, IS_SINGLE),
    MONDEF(RMS_ORG, 16995, IS_LONGWORD, 4, IS_SINGLE),
    {0,0,0,0,0}
};

static int MonitorCount = 0;
static int MonitorMallocSize = 0;

void tote_up_info_count()
{
  for(MonitorCount = 0; MonitorInfoList[MonitorCount].InfoName;
      MonitorCount++) {
    /* While we're here, we might as well get a generous estimate of how */
    /* much space we'll need for all the buffers */
    MonitorMallocSize += MonitorInfoList[MonitorCount].BufferLen;
    /* Add in a couple extra, just to be safe */
    MonitorMallocSize += 8;
  }
}    

char *MonthNames[12] = {
  "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep",
  "Oct", "Nov", "Dec"} ;

     
MODULE = VMS::Monitor		PACKAGE = VMS::Monitor		

PROTOTYPES: DISABLE

void
monitor_info_names()
   PPCODE:
   {
     int i;
     for (i=0; MonitorInfoList[i].InfoName; i++) {
       XPUSHs(sv_2mortal(newSVpv(MonitorInfoList[i].InfoName, 0)));
     }
   }

SV *
one_monitor_piece(infoname)
     SV *infoname
   CODE:
{
  int i;
  char *ReturnStringBuffer;            /* Return buffer pointer for strings */
  char ReturnByteBuffer;               /* Return buffer for bytes */
  unsigned short ReturnWordBuffer;     /* Return buffer for words */
  unsigned long ReturnLongWordBuffer;  /* Return buffer for longwords */
  struct scs_info *ReturnSCSInfo;      /* Pointer to an scs_info struct */
  struct disk_info *ReturnDiskInfo;    /* Pointer to a disk_info struct */
  struct proc_info *ReturnProcInfo;    /* Pointer to a proc_info struct */
  struct mode_info *ReturnModeInfo;    /* Pointer to a mode_info struct */
  unsigned short BufferLength;
#ifndef __VAX
  unsigned __int64 ReturnQuadWordBuffer;
#endif
  int status;
  unsigned short ReturnedTime[7];
  char AsciiTime[100];
  char QuadWordString[65];
  iosb IOSB;
  int EventFlag;
  
  for (i = 0; MonitorInfoList[i].InfoName; i++) {
    if (strEQ(MonitorInfoList[i].InfoName, SvPV_nolen(infoname))) {
      break;
    }
  }

  /* Did we find a match? If not, complain and exit */
  if (MonitorInfoList[i].InfoName == NULL) {
    warn("Invalid monitor info item");
    ST(0) = &PL_sv_undef;
  } else {
    /* allocate our item list */
    ITMLST OneItem[2];

    /* Clear the buffer */
    Zero(&OneItem[0], 2, ITMLST);

    /* Fill in the itemlist depending on the return type */
    switch(MonitorInfoList[i].ReturnType) {
    case IS_STRING:
    case IS_VMSDATE:
    case IS_DISK:
    case IS_PROCESS:
    case IS_SCS:
    case IS_MODE:
      /* Allocate the return data buffer and zero it. Can be oddly sized, so */
      /* we use the system malloc instead of New */
      ReturnStringBuffer = malloc(MonitorInfoList[i].BufferLen + 8);
      if (!ReturnStringBuffer) {
        printf("Hey! Something went horribly wrong!\n");
        croak("Malloc failed!");
      }
      memset(ReturnStringBuffer, 0, MonitorInfoList[i].BufferLen);

      /* Fill in the item list */
      init_itemlist(&OneItem[0], MonitorInfoList[i].BufferLen,
                    MonitorInfoList[i].GetSPIValue, ReturnStringBuffer,
                    &BufferLength);
      
      /* Done */
      break;
#ifndef __VAX
    case IS_QUADWORD:
      /* Fill in the item list */
      init_itemlist(&OneItem[0], MonitorInfoList[i].BufferLen,
                    MonitorInfoList[i].GetSPIValue, &ReturnQuadWordBuffer,
                    &BufferLength);
      break;
#endif
    case IS_ENUM:
    case IS_BITMAP:
    case IS_LONGWORD:
      /* Fill in the item list */
      init_itemlist(&OneItem[0], MonitorInfoList[i].BufferLen,
                    MonitorInfoList[i].GetSPIValue, &ReturnLongWordBuffer,
                    &BufferLength);
      break;
    default:
      warn("Unknown item return type");
      XSRETURN_UNDEF;
    }
    
    /* There's no wait form of this, so we need an event flag */
    status = lib$get_ef(&EventFlag);
    if (status != SS$_NORMAL) {
      SETERRNO(EVMSERR, status);
      XSRETURN_UNDEF;
    }
    status = sys$clref(EventFlag);
    if (!(status & 1)) {
      SETERRNO(EVMSERR, status);
      XSRETURN_UNDEF;
    }

    /* Make the call */
    status = exe$getspi(EventFlag, NULL, NULL, OneItem, &IOSB, NULL, NULL);

    /* Did we fail? */
    if (status != SS$_NORMAL) {
      /* Free the event flag then */
      lib$free_ef(&EventFlag);
      SETERRNO(EVMSERR, status);
      XSRETURN_UNDEF;
    }

    /* Wait for it to finish. */
    status = sys$synch(EventFlag, &IOSB);
      
    /* Free the event flag now, just in case */
    lib$free_ef(&EventFlag);

    /* Ok? */
    if (status == SS$_NORMAL) {
      /* Guess so. Grab the data and return it */
      switch(MonitorInfoList[i].ReturnType) {
      case IS_STRING:
        ST(0) = sv_2mortal(newSVpv(ReturnStringBuffer, 0));
        /* Give back the buffer */
        free(ReturnStringBuffer);
        break;
#ifndef __VAX
      case IS_QUADWORD:
        sprintf(QuadWordString, "%llu", ReturnQuadWordBuffer);
        ST(0) = sv_2mortal(newSVpv(QuadWordString, 0));
        break;
#endif
      case IS_VMSDATE:
        sys$numtim(ReturnedTime, ReturnStringBuffer);
        sprintf(AsciiTime, "%02hi-%s-%hi %02hi:%02hi:%02hi.%hi",
                ReturnedTime[2], MonthNames[ReturnedTime[1] - 1],
                ReturnedTime[0], ReturnedTime[3], ReturnedTime[4],
                ReturnedTime[5], ReturnedTime[6]);
        ST(0) = sv_2mortal(newSVpv(AsciiTime, 0));
        free(ReturnStringBuffer);
        break;
      case IS_ENUM:
      case IS_BITMAP:
      case IS_LONGWORD:
        ST(0) =  sv_2mortal(newSViv(ReturnLongWordBuffer));
        break;
      case IS_SCS:
        {
          int i = 0;
          AV *TempAV;
          HV *TempHV;
          char TempNodeName[12];
          TempAV = newAV();
          sv_2mortal((SV *)TempAV);
          /* Swap to a pointer variable of the type we like */
          ReturnSCSInfo = (void *)ReturnStringBuffer;
          /* Add four bytes because GETSPI doesn't return starting at the */
          /* beginning of the buffer. Dunno why. */
          ReturnSCSInfo = (void *)((char *)ReturnSCSInfo + 4);
          
          for (i=0; (i<NUM_SCS) && ReturnSCSInfo[i].scs_nodename[1]; i++) {
            /* Get a new hash */
            TempHV = newHV();
            /* Push a reference to it on our array */
            av_push(TempAV, newRV_noinc((SV *)TempHV));
            /* Fill it in */
            Copy(ReturnSCSInfo[i].scs_nodename, &TempNodeName[0], 8,
                 char);
            hv_store(TempHV, "NODENAME", 8,
                     newSVpv(&TempNodeName[1], TempNodeName[0]), 0);
            hv_store(TempHV, "DGRCVD", 6,
                     newSViv(ReturnSCSInfo[i].scs_dgrcvd), 0);
            hv_store(TempHV, "DGDISCARD", 9,
                     newSViv(ReturnSCSInfo[i].scs_dgdiscard), 0);
            hv_store(TempHV, "MSGSENT", 7,
                     newSViv(ReturnSCSInfo[i].scs_msgsent), 0);
            hv_store(TempHV, "MSGRCVD", 7,
                     newSViv(ReturnSCSInfo[i].scs_msgrcvd), 0);
            hv_store(TempHV, "SNDDATS", 7,
                     newSViv(ReturnSCSInfo[i].scs_snddats), 0);
            hv_store(TempHV, "KBYTSENT", 8,
                     newSViv(ReturnSCSInfo[i].scs_kbytsent), 0);
            hv_store(TempHV, "REQDATS", 7,
                     newSViv(ReturnSCSInfo[i].scs_reqdats), 0);
            hv_store(TempHV, "KBYTREQD", 8,
                     newSViv(ReturnSCSInfo[i].scs_kbytreqd), 0);
            hv_store(TempHV, "KBYTMAPD", 8,
                     newSViv(ReturnSCSInfo[i].scs_kbytmapd), 0);
            hv_store(TempHV, "QCR_CNT", 7,
                     newSViv(ReturnSCSInfo[i].scs_qcr_cnt), 0);
            hv_store(TempHV, "QBDT_CNT", 8,
                     newSViv(ReturnSCSInfo[i].scs_qbdt_cnt), 0);
            
          }
          /* Return a reference to our array */
          ST(0) = newRV_noinc((SV *)TempAV);
        }

        /* Give back the buffer */
        free(ReturnStringBuffer);
        break;
      case IS_MODE:
        {
          int i = 0;
          AV *TempAV;
          HV *TempHV;
          char TempNodeName[12];
          TempAV = newAV();
          sv_2mortal((SV *)TempAV);
          /* Swap to a pointer variable of the type we like */
          ReturnModeInfo = (void *)ReturnStringBuffer;
          /* Add four bytes because GETSPI doesn't return starting at the */
          /* beginning of the buffer. Dunno why. */
          ReturnModeInfo = (void *)((char *)ReturnModeInfo + 4);
          
          /* Loop as long as we're under our max CPU count and we haven't */
          /* run out of CPUs to check. We'd normally bail if our CPU_ID is */
          /* zero, except for CPU 0 (which we're pretty much guaranteed to */
          /* have). We'd be better off checking the actual number of CPUs, */
          /* but maybe next week. */
          for (i=0; (i< NUM_CPUS) && (i == 0 || ReturnModeInfo[i].cpu_id != 0);
               i++) {
            /* Get a new hash */
            TempHV = newHV();
            /* Push a reference to it on our array */
            av_push(TempAV, newRV_noinc((SV *)TempHV));
            /* Fill it in */
            hv_store(TempHV, "CPU_ID", 6,
                     newSViv(ReturnModeInfo[i].cpu_id), 0);
            hv_store(TempHV, "INTERRUPT", 9,
                     newSViv(ReturnModeInfo[i].interrupt_time), 0);
            hv_store(TempHV, "MPSYNC", 6,
                     newSViv(ReturnModeInfo[i].mpsync_time), 0);
            hv_store(TempHV, "KERNEL", 6,
                     newSViv(ReturnModeInfo[i].kernel_time), 0);
            hv_store(TempHV, "EXEC", 4,
                     newSViv(ReturnModeInfo[i].exec_time), 0);
            hv_store(TempHV, "SUPER", 5,
                     newSViv(ReturnModeInfo[i].super_time), 0);
            hv_store(TempHV, "USER", 4,
                     newSViv(ReturnModeInfo[i].user_time), 0);
            hv_store(TempHV, "COMPATIBILITY", 13,
                     newSViv(ReturnModeInfo[i].compatibility_time), 0);
            hv_store(TempHV, "IDLE", 4,
                     newSViv(ReturnModeInfo[i].idle_time), 0);
          }
          /* Return a reference to our array */
          ST(0) = newRV_noinc((SV *)TempAV);
        }

        /* Give back the buffer */
        free(ReturnStringBuffer);
        break;
      case IS_DISK:
        {
          int i = 0;
          AV *TempAV;
          HV *TempHV;
          char TempName[12];
          TempAV = newAV();
          sv_2mortal((SV *)TempAV);
          /* Swap to a pointer variable of the type we like */
          ReturnDiskInfo = (void *)ReturnStringBuffer;
          /* Add four bytes because GETSPI doesn't return starting at the */
          /* beginning of the buffer. Dunno why. */
          ReturnDiskInfo = (void *)((char *)ReturnDiskInfo + 4);
          
          for (i=0; (i<NUM_DISKS) && ReturnDiskInfo[i].disk_volname[0]; i++) {
            /* Get a new hash */
            TempHV = newHV();
            /* Push a reference to it on our array */
            av_push(TempAV, newRV_noinc((SV *)TempHV));
            /* Fill it in */
            memcpy(TempName, ReturnDiskInfo[i].disk_nodename, 8);
            hv_store(TempHV, "NODENAME", 8,
                     newSVpv(&TempName[1], TempName[0]), 0);
            
            /* This isn't a counted string, and has trailing blanks. Dunno */
            /* why it's different than the rest, but it is... */
            memcpy(TempName, ReturnDiskInfo[i].disk_volname, 12);
            hv_store(TempHV, "VOLNAME", 7,
                     newSVpv(&TempName[0], 12), 0);

            memcpy(TempName, ReturnDiskInfo[i].disk_devname, 4);
            hv_store(TempHV, "DEVNAME", 7,
                     newSVpv(&TempName[1], TempName[0]), 0);

            hv_store(TempHV, "ALLOCLASS", 8,
                     newSViv(ReturnDiskInfo[i].disk_alloclass), 0);
            hv_store(TempHV, "FLAGS", 5,
                     newSViv(ReturnDiskInfo[i].disk_flags), 0);
            hv_store(TempHV, "OPTCNT", 6,
                     newSViv(ReturnDiskInfo[i].disk_optcnt), 0);
            hv_store(TempHV, "QCOUNT", 6,
                     newSViv(ReturnDiskInfo[i].disk_qcount), 0);
            hv_store(TempHV, "UNITNUM", 7,
                     newSViv(ReturnDiskInfo[i].disk_unitnum), 0);
            
          }
          /* Return a reference to our array */
          ST(0) = newRV_noinc((SV *)TempAV);
        }

        /* Give back the buffer */
        free(ReturnStringBuffer);
        break;
      case IS_PROCESS:
        {
          int i = 0;
          AV *TempAV;
          HV *TempHV;
          char TempName[20];
          TempAV = newAV();
          sv_2mortal((SV *)TempAV);
          /* Swap to a pointer variable of the type we like */
          ReturnProcInfo = (void *)ReturnStringBuffer;
          /* Add four bytes because GETSPI doesn't return starting at the */
          /* beginning of the buffer. Dunno why. */
          ReturnProcInfo = (void *)((char *)ReturnProcInfo + 4);
          
          for (i=0; (i<NUM_PROCESS) && ReturnProcInfo[i].proc_ipid; i++) {
            /* Get a new hash */
            TempHV = newHV();
            /* Push a reference to it on our array */
            av_push(TempAV, newRV_noinc((SV *)TempHV));
            /* Fill it in */
            hv_store(TempHV, "IPID", 4,
                     newSViv(ReturnProcInfo[i].proc_ipid), 0);
            hv_store(TempHV, "UIC", 3,
                     newSViv(ReturnProcInfo[i].proc_uic), 0);
            hv_store(TempHV, "STATE", 5,
                     newSViv(ReturnProcInfo[i].proc_state), 0);
            hv_store(TempHV, "PRI", 3,
                     newSViv(ReturnProcInfo[i].proc_pri), 0);

            memcpy(TempName, ReturnProcInfo[i].proc_lname, 16);
            hv_store(TempHV, "NAME", 4,
                     newSVpv(&TempName[1], TempName[0]), 0);

            hv_store(TempHV, "GPGCNT", 6,
                     newSViv(ReturnProcInfo[i].proc_gpgcnt), 0);
            hv_store(TempHV, "PPGCNT", 6,
                     newSViv(ReturnProcInfo[i].proc_ppgcnt), 0);
            hv_store(TempHV, "STS", 3,
                     newSViv(ReturnProcInfo[i].proc_sts), 0);
            hv_store(TempHV, "DIOCNT", 6,
                     newSViv(ReturnProcInfo[i].proc_diocnt), 0);
            hv_store(TempHV, "PAGEFLTS", 8,
                     newSViv(ReturnProcInfo[i].proc_pageflts), 0);
            hv_store(TempHV, "CPUTIM", 6,
                     newSViv(ReturnProcInfo[i].proc_cputim), 0);
            hv_store(TempHV, "BIOCNT", 6,
                     newSViv(ReturnProcInfo[i].proc_biocnt), 0);
            hv_store(TempHV, "EPID", 4,
                     newSViv(ReturnProcInfo[i].proc_epid), 0);
            hv_store(TempHV, "EFWM", 4,
                     newSViv(ReturnProcInfo[i].proc_efwm), 0);
            hv_store(TempHV, "RBSTRAN", 9,
                     newSViv(ReturnProcInfo[i].proc_rbstran), 0);
            
            
          }
          /* Return a reference to our array */
          ST(0) = newRV_noinc((SV *)TempAV);
        }

        /* Give back the buffer */
        free(ReturnStringBuffer);
        break;
      default:
        ST(0) = &PL_sv_undef;
        break;
      }
    } else {
      SETERRNO(EVMSERR, status);
      ST(0) = &PL_sv_undef;
      /* free up the buffer if we were looking for a string */
      if (MonitorInfoList[i].ReturnType == IS_STRING)
        free(ReturnStringBuffer);
    }
  }
}

