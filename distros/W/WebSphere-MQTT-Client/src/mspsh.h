/****************************************************************************/
/*                                                                          */
/* Program name: MQIsdp protocol C Language implementation                  */
/*                                                                          */
/* Description: This header file contains prototypes for common functions   */
/* that are required by all aspects of the code. It also contains platform  */
/* specific includes and macro definitions.                                 */
/*                                                                          */
/*  Statement:  Licensed Materials - Property of IBM                        */
/*                                                                          */
/*              MQSeries SupportPac IA93                                    */
/*              (C) Copyright IBM Corp. 2002                                */
/*                                                                          */
/****************************************************************************/
/* Version @(#) IA93/ship/mspsh.h, SupportPacs, S000 1.4 03/11/28 16:43:57  */
/*                                                                          */
/* Function:                                                                */
/*                                                                          */
/* For each platform this header file should pull in the correct header     */
/* files. It should also contain appropriate NULL values for the semaphore, */
/* mutex and IPC handles.                                                   */
/*                                                                          */
/****************************************************************************/
/*                                                                          */
/* Change history:                                                          */
/*                                                                          */
/* V1.0   19-02-2003  IRH  Initial release                                  */
/*        21-10-2003  IRH  Removed dependency on pthread.h for the the      */
/*                         single threaded build.                           */
/*                                                                          */
/*==========================================================================*/
/* Module Name: mspsh.h                                                     */
#ifndef MSPSH_H_INCLUDED
  #define MSPSH_H_INCLUDED 1
/*********************************************************************/
/* Header file defining the Control block structures flowed via IPC. */
/*********************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>

/*  These #define's can be added as appropriate for each platform          */
/*  See porting documentation for more information                         */
/*  #define MSP_FUSION_SOCKETS 1    Use the Fusion TCP/IP socket interface */
/*  #define MSP_KN_SOCKETS 1        Use the KwikNet TCP/IP socket interface*/
/*  #define MSP_NO_LOCALTIME 1      No localtime() function                */
/*  #define MSP_NO_REALLOC 1        No realloc() function                  */
/*  #define MSP_NO_ISPRINT 1        No isprint() function                  */
/*  #define MSP_NO_TIME 1           No time() function                     */
/*  #define MSP_NO_USHORT 1         No typedef of u_short as unsigned short*/
/*  #define MSP_NO_UINT 1           No typedef of u_int as unsigned int    */


/* Define an invalid TCP/IP socket */
#define MSP_INVALID_SOCKET   -1

/* Windows WIN32 specifics */
#ifdef WIN32
  #define MSP_BSD_SOCKETS 1   /* Use the standard TCP/IP socket interface */
  #include <time.h>
  #include <io.h>
  #include <winsock2.h>
  #include <windows.h>

  #define MSP_NULL_MAILBOX     INVALID_HANDLE_VALUE  /* NULL mailbox            */
  #define MSP_NULL_MUTEX       INVALID_HANDLE_VALUE  /* NULL mutex semaphore    */
  #define MSP_NULL_SEMAPHORE   INVALID_HANDLE_VALUE  /* NULL resource semaphore */
  #define MSP_IPC_WAIT_FOREVER MAILSLOT_WAIT_FOREVER /* IPC infinite wait       */

  /* Redefine an invalid TCP/IP socket */
  #undef MSP_INVALID_SOCKET
  #define MSP_INVALID_SOCKET   INVALID_SOCKET
#endif

/* Generic System V UNIX specifics */
#ifdef UNIX
  #define MSP_BSD_SOCKETS 1   /* Use the standard TCP/IP socket interface */
  #define _ANSI_C_SOURCE
  #include <sys/time.h>
  #include <sys/types.h>
  #include <sys/socket.h>
  #include <netinet/in.h>
  #include <arpa/inet.h>
  #include <netdb.h>
  #include <sys/ipc.h>
  #include <sys/sem.h>
  #include <stdarg.h>
  #include <signal.h>
  #include <time.h>
  #include <string.h>
  #include <ctype.h>
  #include <unistd.h>
  #ifndef MSP_SINGLE_THREAD
      #define POSIXTHREADS
      #include <pthread.h>
  #endif
  
  #define MSP_NULL_MAILBOX     -1   /* NULL pipe handle      */
  #define MSP_NULL_MUTEX       -1   /* NULL semaphore handle */
  #define MSP_NULL_SEMAPHORE   NULL /* NULL MSH_S structure  */
  #define MSP_IPC_WAIT_FOREVER -1   /* IPC infinite wait     */
#endif

/* Linux specifics */
#ifdef LINUX
  #define MSP_NO_USHORT 1        /* no typedef for C type u_short */
  #define MSP_NO_UINT   1        /* no typedef for C type u_int   */
  #define MSP_NO_ULONG  1        /* no typedef for C type u_long  */
#endif

/* AIX specifics */
#ifdef AIX
  #include <sys/socketvar.h>
#endif

/* SOLARIS specifics */
#ifdef SOLARIS
  #ifndef INADDR_NONE
    #define INADDR_NONE -1
  #endif
#endif

#ifdef MSP_NO_USHORT
  typedef unsigned short u_short;
#endif

#ifdef MSP_NO_UINT
  typedef unsigned int u_int;
#endif

#ifdef MSP_NO_ULONG
  typedef unsigned long u_long;
#endif

#ifdef MSP_NO_TIME
  time_t time( time_t *t );
#endif

#ifdef MSP_KN_SOCKETS
  /* If a KwikNet TCP/IP stack is being used then include the appropriate header file */
  #include <KN_SOCK.H>
#endif

#ifdef MSP_FUSION_SOCKETS
  #define INADDR_NONE 0xFFFFFFFF
#endif

#define MQISDP_LINE_LENGTH        70

#include <MQIsdp.h>

/* Define some parameters for controlling memory usage */
#define MSP_DEFAULT_MAX_OUTQ_SZ   32768 /* Amount of queued for sending - 32K   */
#define MSP_DEFAULT_MAX_INQ_SZ    32768 /* Amount of queued for receiving - 32K */
#define MSP_DEFAULT_IPC_BUFFER_SZ 128   /* IPC buffer length - 128 bytes        */    
#define MSP_DEFAULT_NUM_HASH_KEYS 16    /* Size of hash table for storing messages */

/* Define some IPC attributes */
#define MSP_EC_LENGTH             2          /* Eyecatcher length */
#define MSP_IPC_BLOCK             0x00000001 /* An IPC option to indicate blocking / non-blocking reads */

/* Eye catchers used by the IPC layer. The first letter of the eyecatcher must be unique */
/* for each operation e.g C - connect, D - disconnect etc                                */

/* Connect */
#define CONN_S "CS"
#define CONN_R "CR"
/* Disconnect */
#define DISC_S "DS"
#define DISC_R "DR"
/* Publish */
#define PUB_S  "PS"
#define PUB_R  "PR"
/* Subscribe */
#define SUB_S  "SS"
#define SUB_R  "SR"
/* Unsubscribe */
#define UNS_S  "US"
#define UNS_R  "UR"
/* Status */
#define STAT_S "TS"
#define STAT_R "TR"
/* ReceivePublication */
#define RCV_S  "RS"
#define RCV_R  "RR"
#define RCV_A  "AS"  /* Acknowledge receive */
#define RCV_D  "ES"  /* Decline receive     */
#define RCV_B  "AR"  /* Acknowledge / Decline receive response */
/* GetMsgStatus */
#define MSG_S  "MS"
#define MSG_R  "MR"
/* Initialise receive task */
#define RCON_S  "IS"
/* Receive data from the receive task */
#define RTSK_S  "KS"
#define RTSK_R  "KR"
                                                                
/* IPC Control block                                             */
/* These are structured as follows:                              */
/*                                                               */
/* Every control block begins with a header CB_HEAD              */
/* This header is then followed by the API specific structure,   */
/* which depends on the eye catcher:                             */
/*    CONS - CONN_PARMS                                          */
/*    CONR -   - - -                                             */
/*    DISS -   - - -                                             */
/*    DISR -   - - -                                             */
/*    PUBS - PUB_PARMS, dataLength, data                         */
/*    PUBR -   - - -                                             */
/*    SUBS - SUB_PARMS                                           */
/*    SUBR -   - - -                                             */
/*    UNSS - UNSUB_PARMS                                         */
/*    UNSR -   - - -                                             */
/*    STAS - errorStringLength                                   */
/*    STAR - errorCode, errorString                              */
/*    RCVS - msgBufferLength                                     */
/*    RCVR - options, topicLength, dataLength, dataBuffer        */
/*    MSGS - MQISDPMH                                            */
/*    MSGR -   - - -                                             */
typedef struct struct_CB {
    char     eyeCatcher[MSP_EC_LENGTH];
    short    returnCode;  
    MQISDPMH hMsg;
    int      dataLength;
    char    *pData;
} CB_HEAD;

typedef struct struct_ipc {
    MBH   apiMailbox;
    MBH   sendMailbox;
    MBH   receiveMailbox;
    MTH   sendMutex;
    MSH   receiveSemaphore;
    long  options;
    int   readTimeout;
    long  ipcBufferSz;
    char *pIpcBuffer;
    #ifdef MSP_SINGLE_THREAD
    char *pPseudoMailbox;
    #endif
} IPCCB;

/* This flag determines what memory debugging is enabled        */
/* Set to 1 for a summary of memory allocation / deallocation   */
/* Set to 2 for explicit tracing of allocations / deallocations */
#define MSP_DEBUG_MEM 0

/* Data that is common to the client and daemon code */
typedef struct struct_scmd {
  unsigned int memLimit;
  unsigned int mspLogOptions;
  #if MSP_DEBUG_MEM > 0
  unsigned int mc;          /* Number of calls to malloc */
  unsigned int fc;          /* Number of calls to free   */
  unsigned int memCount;    /* Current number of bytes allocated */
  unsigned int memMax;      /* Maximum number of bytes allocated */
  #endif
} MSPCMN;

/* Define a MIN MACRO */
#ifndef MIN
    #define MIN( A, B ) (A > B) ? B : A
#endif    

#define MSP_LOG_LINE_SZ 128

/* mspsh.c */
DllExport void* mspMalloc( MSPCMN *cData, size_t size );
DllExport void* mspRealloc( MSPCMN *cData, void *memBlock, size_t size, long freeSize );
DllExport void mspFree( MSPCMN *cData, void *memBlock, size_t freeSize );
DllExport void mspLogMem( MSPCMN *cData, char *id, int correction  );
DllExport void mspLogHex( int logLevel, MSPCMN *cData, int bufSize, char *buffer );
DllExport void mspLog( int logLevel, MSPCMN *cData, char *fmt, ... );
DllExport long mspCharTrim( char c, long len, char *buffer );

/* mspipc.c */
DllExport int mspSetIPCTimeout( MBH mbHandle, long mSecs );
DllExport int mspInitialiseIPC( MBH mbHandle, IPCCB *pIpcCb );
DllExport int mspWriteIPC( MBH mbHandle, IPCCB *pIpcCb, char *ec, int rc, MQISDPMH hMsg,
                           long numBytes, char *pBuffer );
DllExport int mspReadIPC( MBH mbHandle, IPCCB *pIpcCb, MSPCMN *comParms, long *nBytesRead,
                          long *bufSize, void **ppBuffer, char *ec ,int *rc, MQISDPMH *hMsg );
DllExport int mspLockMutex( MTH mutexHandle );
DllExport int mspReleaseMutex( MTH mutexHandle );
DllExport int mspWaitForSemaphore( MSH semHandle, long msTimeout );
DllExport int mspSignalSemaphore( MSH semHandle );
#endif
