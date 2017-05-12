/****************************************************************************/
/*                                                                          */
/* Program name: MQIsdp protocol C Language implementation                  */
/*                                                                          */
/* Description: This header file contains structures for various objects    */
/* such as input and output queues, IPC control blocks, hash tables and more*/
/* tables and linked lists.                                                 */
/*                                                                          */
/*  Statement:  Licensed Materials - Property of IBM                        */
/*                                                                          */
/*              MQSeries SupportPac IA93                                    */
/*              (C) Copyright IBM Corp. 2002                                */
/*                                                                          */
/****************************************************************************/
/* Version @(#) IA93/ship/mspdmn.h, SupportPacs, S000 1.3 03/11/28 16:43:38  */
/*                                                                          */
/* Function:                                                                */
/*                                                                          */
/* Header file defining various types of object as described above,         */
/* function prototypes and some useful macros.                              */
/*                                                                          */
/****************************************************************************/
/*                                                                          */
/* Change history:                                                          */
/*                                                                          */
/* V1.0   19-02-2003  IRH  Initial release                                  */
/*                                                                          */
/*==========================================================================*/
/* Module Name: mspdmn.h                                                    */
#include <mspsh.h>

/* TCP/IP parameters */
typedef struct struct_Tcp {
    int     sockfd;
    int     lastError;
	int     msperrno;
    char    brokerAddress[MQISDP_INET_ADDR_LENGTH];
    u_short brokerPort;
    #ifdef MSP_SINGLE_THREAD
    int     sockWaitTime; /* In the single threaded version blocking */
    #endif                /* receives are done on the socket         */
} TCP_PARMS;

/* Message in progress queue - for messages being sent */
/* The flags could be a char, but the structure would not be 4 byte aligned... */
typedef struct struct_IPQ {
    void  *msgData;
    long   msgLength;
    long   flags;    /* QoS of message and retry */
    short  msgId;
    short  msgStatus;
    struct struct_IPQ *Next;
    struct struct_IPQ *Prev;
} IPQ;

/* Received publications queue - for publications being received */
typedef struct struct_RPQ {
    long   options;       /* Retain, duplicate, qos - MQISDP_* options in MQIsdp.h */
    long   topicLength;
    long   bufferLength;
    char  *buffer;
    u_long rcvId;         /* This uniquely identifies the publication and is the persistence msgId*/
    /*short  msgId;*/
    char   readyToPublish; 
    struct struct_RPQ *Next;
    struct struct_RPQ *Prev;
} RPQ;

/* Structures for the internal hashtable used with the rcvdInProgressQ */
/* A hash table entry */
typedef struct struct_MHASHENTRY {
    long  msgId;
    void *dataPtr;
    struct struct_MHASHENTRY *Next;
    struct struct_MHASHENTRY *Prev;
} MHASHENTRY;

/* A hash table with 1 key */
typedef struct struct_MHASHT {
    int            nKeys;
    MHASHENTRY *pKeys[1];
} MHASHT;

/* This is all the data required for receiving publications from the network.*/
/* rcvdPubsQ  - a linked list of data in the order it arrives from the       */
/*              network.                                                     */
/* ripHash    - a hash table which allows fast access by Msg Id to the       */
/*              rcvdPubsQ.                                                   */
/* pLastEntry - allows data to be easily added to the end of the queue       */
/* rtpEntries - The number of queue entries available to be received by the  */
/*              the application. i.e. All QoS 0 and QoS 1 publications plus  */
/*              QoS 2 pubs for which a PUBREL message has been received.     */
/* numBytesQueued - The total number of bytes in the rcvdPubsQ linked list.  */
/*                  This includes all bytes in all RPQ structures.           */
typedef struct struct_inq {
    RPQ    *rcvdPubsQ;
    MHASHT *rpHash;
    RPQ    *pLastEntry;
    long    rtpEntries; /* Entries ready to publish to client application */
    long    numBytesQueued;
} INPUTQ;

/* This is all the data required for sending publications to the network     */
/* inProgressQ - a linked list of data as it arrives from the client         */
/* ipHash      - a hash table which allows fast access by Msg Id to the      */
/*               inProgressQ.                                                */
/* pLastEntry - allows data to be easily added to the end of the queue       */
/* ipEntries  - The number of messages in progress, for which ACKs have not  */
/*              been received.                                               */
/* numBytesQueued - The total number of bytes in the inProgressQ linked list.*/
/*                  This includes all bytes in all IPQ structures.           */
typedef struct struct_outq {
    IPQ    *inProgressQ;
    MHASHT *ipHash;
    IPQ    *pLastEntry;
    long    ipEntries;
    long    numBytesQueued;
} OUTPUTQ;

/* Structure for holding reconnect parameters.                     */
/* In order to be able to reconnect a failed connection we need to */
/* remember the initial connect message.                           */
typedef struct struct_rcnt {
    long        connRetries;
    time_t      timeForNextConnect;
    long        connMsgSz;
    char       *connectMsg;
} RECONN;

/* Connection handle control block */
/* This structure is used by the send task/thread.                             */
/* The HCONNCB structure ensures that all long values are 4-byte aligned       */
/* to avoid sparse gaps appearing in the structure when the compiler aligns it */
typedef struct struct_hConnCB {
  IPCCB     ipcCb;                /* IPC info for each client                        */
  long      connState;            /* Connection state of MQIsdp protocol             */
  long      ctrlFlags;
  time_t    timeForNextPoll;      /* Time the MQIsdp server next needs to be polled  */
  time_t    timeForNextRetry;     /* Time the send task next needs to retry messages */
  short     keepAliveTime;        /* Maximum interval to poll the MQIsdp server      */
  u_short   nextMsgId;            /* The WMQTT message id used for sending and persisting data */
  u_long    nextRcvId;            /* The id allocated on receive for persisteing data */
  long      apiReturnCode;
  long      retryCount;
  long      retryInterval;
  TCP_PARMS tcpParms;
  OUTPUTQ   outQ;
  INPUTQ    inQ;
  RECONN    reconnect;
  MSPCMN    comParms;
  MQISDP_PERSIST* persistFuncs;     /* Pointer to a structure of functions implementing persistence */
} HCONNCB;

/* The structure below is used by the receive thread to hold all data it requires */
/* when executing                                                                 */
typedef struct struct_rcvTask {
  IPCCB  ipcCb;    /* IPC control block */
  MSPCMN comParms; /* Common parms      */
  int    sockfd;   /* Socket descriptor */
  int    lastError;
} RCVHCONN;

/* Define error conditions that can be reported back to the application */
/* The error code occupies the top 8 bits of a 4 byte int               */
#define MSP_CONN_ERROR       0x01000000  /* OR mask  */
#define MSP_TCP_SEND_ERROR   0x02000000  /* OR mask  */
#define MSP_TCP_RECV_ERROR   0x04000000  /* OR mask  */
#define MSP_TCP_CONN_ERROR   0x08000000  /* OR mask  */
#define MSP_TCP_SOCK_ERROR   0x10000000  /* OR mask  */
#define MSP_TCP_HOST_ERROR   0x20000000  /* OR mask  */
#define MSP_GET_LAST_ERROR   0x00FFFFFF  /* AND mask - get the last error value */
#define MSP_GET_ERROR_TYPE   0xFF000000  /* AND mask - get the type of error    */

/* Define some error strings to accompany the error codes */
/* Total string length including any inserts should not be longer than */
/* MQISDP_INFO_STRING_LENGTH - currently 32                            */
#define MSP_TCP_CONN_ERR_STR    "TCPIP connect error:%ld"
#define MSP_TCP_SOCK_ERR_STR    "TCPIP socket error:%ld"
#define MSP_TCP_CONN_SUC_STR    "connected:%s(%ld)"
#define MSP_TCP_SEND_ERR_STR    "TCPIP send error:%ld"
#define MSP_TCP_RECV_ERR_STR    "TCPIP recv error:%ld"
#define MSP_SOCK_CLOSED_ERR_STR "recv error:remote socket closed"
#define MSP_MQISDP_VERS_ERR_STR "Connection refused:Version"
#define MSP_MQISDP_CLID_ERR_STR "Connection refused:ClientId"
#define MSP_MQISDP_CREF_ERR_STR "Connection refused:Broker down"
#define MSP_MQISDP_HOST_ERR_STR "DNS error:Host name not found"

/* Bitmask for getting the MQIsdp QoS from the MQIsdp fixed header */ 
#define MSP_FH_GET_QOS 0x06

/* Bitmasks for flags used in the InProgressQ */
#define MSP_IPQ_QOS_0  0x00000002
#define MSP_IPQ_QOS_1  0x00000004
#define MSP_IPQ_QOS_2  0x00000008

/* Bitmask for use by the mspHandleClientConnection function */
#define MSP_CLIENT_APP_CONNECTED    0x00000001
#define MSP_CLIENT_APP_DISCONNECTED 0xFFFFFFFE
#define MSP_CLEAN_SESSION           0x00000002
#define MSP_CLEAN_SESSION_OFF       0xFFFFFFFD

/* Bitmasks to control which interfaces we wait for */
#define MSP_WAIT_TCPIP          0x00000001
#define MSP_WAIT_IPC            0x00000002

/* A macro to return the next message id */
#define MSP_SET_NEXT_MSGID( Mid ) \
    Mid = (Mid==MQISDP_MAX_MSGS) ? 1 : Mid+1;
    
/* A macro to return the next receive message id to uniquely queue the message */
/* Set to max 32 bit value                                                     */
#define MSP_SET_NEXT_RCVID( Mid ) \
    Mid = (Mid==0xFFFFFFFF) ? 1 : Mid+1;

/* Some MQISDP attributes */
#define MSP_MAX_FHEADER_LENGTH 5   /* 1 byte plus 4 remaining length bytes */

/* msputils.c */
HCONNCB *mspInitialise( MQISDPTI *pTaskInfo );
int mspHandleClientConnection( HCONNCB *pHconn);
int mspGetDataFromNetwork( int *pSockfd, MSPCMN *pComParms, int *pLastError,
                                     long *pBytesRead, long *rBufSize, char **rBuffer,
                                     long msTimeout );
int mspInitReceiveTask( HCONNCB *pHconn );

/* mspscada.c */
int mspSendScadaMessage( HCONNCB *pHconn, long msgLen, char *msgData,
                                   short msgId, int retryFlag, int initFlag );
int mspSendPingRequest( HCONNCB *pHconn );
int mspReceiveScadaMessage( HCONNCB *pHconn, long bytesRead, char *pReadBuffer );
RPQ* mspStorePublication( HCONNCB *pHconn, long bytesRead, char *pReadBuffer, u_short *wmqttMsgId );
int mspEncodeFHeaderLength( int l, char *ptr );
int mspDecodeFHeaderLength( long numBytes, long *rlLength, int *l, char *ptr );
int mspMQIsdpReconnect( HCONNCB *pHconn );
int mspRetryScadaMessage( HCONNCB *pHconn, IPQ *curIpqEntry );
void* mspBuildScadaConnectMsg( HCONNCB *pHconn, long bufLength,
                                         void *ipcBuffer, long *msgLength );
void* mspBuildScadaDisconnectMsg( HCONNCB *pHconn, long bufLength,
                                            void *ipcBuffer, long *msgLength );
void* mspBuildScadaSubscribeMsg( HCONNCB *pHconn, long bufLength,
                                           void *ipcBuffer, long *msgLength );
void* mspBuildScadaUnsubscribeMsg( HCONNCB *pHconn, long bufLength,
                                             void *ipcBuffer, long *msgLength );
void* mspBuildScadaPublishMsg( HCONNCB *pHconn, long bufLength,
                                         void *ipcBuffer, long *msgLength );

/* msptcp.c */
char* mspTCPGetHostByName( HCONNCB *pHconn, char *pHostName );
int mspTCPConnect( HCONNCB *pHconn, u_short port, char *ipAddr );
int mspTCPInitialise( HCONNCB *pHconn );
int mspTCPInit( void );
int mspTCPTerm( void );
int mspTCPDisconnect( int *pSockfd );
int mspTCPWrite( HCONNCB *pHconn, size_t msgLen, char *msgData );
int mspTCPReadMsg( int sockfd, MSPCMN *pComParms, int *pLastError,
                             long *msgLen, long *bufLen, char **buffer );
int msp_select( int sockfd, long mSecs );


/* msphash.c */
MHASHT *mspInitHash( HCONNCB *pHconn, int nKeys );
void mspTermHash( HCONNCB *pHconn, MHASHT *pHash );
int mspAddToHash( HCONNCB *pHconn, MHASHT* pHash, short msgId, void *dataPtr );
void* mspReadFromHash( MHASHT* pHash, short msgId );
MHASHENTRY* mspGetHashEntry( MHASHT* pHash, short msgId );
void mspDelFromHash( HCONNCB *pHconn, MHASHT* pHash, short msgId );
IPQ* mspAddIPMToList( HCONNCB *pHconn, long dataLen, void *msgData, short msgId );
int mspDeleteIPMFromList( HCONNCB *pHconn, IPQ* delEntry );
int mspAddRPMToList( HCONNCB *pHconn, RPQ *newEntry );
int mspDeleteRPMFromList( HCONNCB *pHconn, RPQ* delEntry );
int mspDumpHash( MHASHT* pHash );


