/****************************************************************************/
/*                                                                          */
/* Program name: MQIsdp protocol C Language implementation                  */
/*                                                                          */
/* Description: This header file must be included by client applications. It*/
/* contains the function prototypes for the API and macros for return codes.*/
/*                                                                          */
/*  Statement:  Licensed Materials - Property of IBM                        */
/*                                                                          */
/*              MQSeries SupportPac IA93                                    */
/*              (C) Copyright IBM Corp. 2002                                */
/*                                                                          */
/****************************************************************************/
/* Version @(#) IA93/ship/MQIsdp.h, SupportPacs, S000 1.5 03/12/05 14:11:53  */
/*                                                                          */
/* Function:                                                                */
/*                                                                          */
/* Contains the function prototypes for the API, all structures that the    */
/* API requires and all return codes that may be returned.                  */
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
/* Module Name: MQIsdp.h                                                    */
#ifndef MQISDP_H_INCLUDED
  #define MQISDP_H_INCLUDED

#if defined(__cplusplus)
   extern "C" {
#endif

#ifdef WIN32
  #define DllImport __declspec(dllimport)
  #define DllExport __declspec(dllexport) 
#else
  #define DllImport extern
  #define DllExport
#endif

/* Pull in pthread.h for the multithreaded builds on UNIX */
#if defined(UNIX) && !defined(MSP_SINGLE_THREAD)
  #include <pthread.h>
#endif  

/***********************/
/* Constant values     */
/***********************/

/* Define logging levels - log written to stdout                   */
#define LOGNONE   0x00000000  /* No log output is produced         */
#define LOGNORMAL 0x00000001  /* Log significant events            */
#define LOGERROR  0x00000002  /* Log error conditions only         */
#define LOGIPC    0x00000004  /* Log inter thread communication    */
#define LOGTCPIP  0x00000008  /* Log TCP/IP i/o events             */
#define LOGSCADA  0x00000010  /* Log WMQTT i/o events              */
#define LOGDEBUG  0x00000020  /* Produce detailed debugging output */

/* Return codes for the client API */
#define MQISDP_OK                     0
#define MQISDP_PROTOCOL_VERSION_ERROR 1001
#define MQISDP_HOSTNAME_NOT_FOUND     1002
#define MQISDP_Q_FULL                 1003
#define MQISDP_FAILED                 1004
#define MQISDP_PUBS_AVAILABLE         1005
#define MQISDP_NO_PUBS_AVAILABLE      1006
#define MQISDP_PERSISTENCE_FAILED     1007
#define MQISDP_CONN_HANDLE_ERROR      1008
#define MQISDP_NO_WILL_TOPIC          1010
#define MQISDP_INVALID_STRUC_LENGTH   1011
#define MQISDP_DATA_LENGTH_ERROR      1012
#define MQISDP_DATA_TOO_BIG           1013
#define MQISDP_ALREADY_CONNECTED      1014
#define MQISDP_CONNECTION_BROKEN      1017
#define MQISDP_DATA_TRUNCATED         1018
#define MQISDP_CLIENT_ID_ERROR        1019
#define MQISDP_BROKER_UNAVAILABLE     1020
#define MQISDP_SOCKET_CLOSED          1021
#define MQISDP_OUT_OF_MEMORY          1022

/* Message status */
#define MQISDP_DELIVERED          1
#define MQISDP_RETRYING           2
#define MQISDP_IN_PROGRESS        3
#define MQISDP_MSG_HANDLE_ERROR   4

/* Connection states */
#define MQISDP_CONNECTING         6
#define MQISDP_CONNECTED          7
#define MQISDP_DISCONNECTED       8

/* Flags */
#define MQISDP_NONE               0x0000
#define MQISDP_WILL               0x0001
#define MQISDP_RETAIN             0x0002
#define MQISDP_QOS_0              0x0004
#define MQISDP_QOS_1              0x0008
#define MQISDP_QOS_2              0x0010
#define MQISDP_CLEAN_START        0x0020
#define MQISDP_WILL_RETAIN        0x0040
#define MQISDP_DUPLICATE          0x0080

/* Disconnect options */
#define MQISDP_IMMEDIATE          0x00000001
#define MQISDP_QUIESCE            0x00000002

/* lengths */
#define MQISDP_CLIENT_ID_LENGTH    23L
#define MQISDP_MAX_MSGS            65535L
#define MQISDP_INET_ADDR_LENGTH    16L
#define MQISDP_INFO_STRING_LENGTH  32L
#define MQISDP_RC_STRING_LENGTH    32L

/* Invalid handle */
#define MQISDP_INV_MSG_HANDLE      (-1L)
#define MQISDP_INV_CONN_HANDLE     NULL

/* ---- Flags used by the persistence interface */
/* Define flags to indicate if a publication has been released or not  */
/* The last bytes of a the buffer passed into the persistence contains */
/* the bit.                                                            */
#define MQISDP_RELEASED     0x01    /* OR flag  */

/* ---- End persistence interface flags         */

/* type definitions */
typedef void* MQISDPCH;          /* Connection Handle */                    
typedef unsigned long MQISDPMH;  /* Message handle    */
#if defined(WIN32)
typedef HANDLE MBH;     /* Mailbox handle    */
typedef HANDLE MTH;     /* Mutex handle      */
typedef HANDLE MSH;     /* Semaphore handle  */
#elif defined(UNIX) && !defined(MSP_SINGLE_THREAD)
typedef int MBH;     /* Mailbox handle    */
typedef int MTH;     /* Mutex handle      */
typedef struct s_pmsh {
    pthread_mutex_t  semLock;
    pthread_cond_t   msgSignal;
    char             msgAvailable;
}MSH_S;
typedef MSH_S* MSH;  /* Semaphore handle  */
#else
/* These are default values */
typedef int MBH;     /* Mailbox handle    */
typedef int MTH;     /* Mutex handle      */
typedef int MSH;     /* Semaphore handle  */
#endif

/***********************/
/* Structures          */
/***********************/

/* Task info required for starting the send and receive tasks */
typedef struct struct_mti {
    MBH  apiMailbox;
    MBH  sendMailbox;
    MBH  receiveMailbox;
    MTH  sendMutex;
    MSH  receiveSemaphore;
    long logLevel;
} MQISDPTI;

/* Persistence structure which holds function entry points and user data */
typedef struct struct_PSISTMSG {
    unsigned long key;
    int           length;
    char         *pWmqttMsg;
} MQISDP_PMSG;

typedef struct struct_PSIST {
    void  *pUserData;
    int  (*open)( void *pUserData, char *pClientId, char *pBroker, int port );
    int  (*close)( void *pUserData );
    int  (*reset)( void *pUserData );
    int  (*getAllReceivedMessages)( void *pUserData, int *numMsgs, MQISDP_PMSG** );
    int  (*getAllSentMessages)( void *pUserData, int *numMsgs, MQISDP_PMSG** );
    int  (*addSentMessage)( void *pUserData, unsigned long key, int msgLength, char *pWmqttMsg );
    int  (*updSentMessage)( void *pUserData, unsigned long key, int msgLength, char *pWmqttMsg );
    int  (*delSentMessage)( void *pUserData, unsigned long key );
    int  (*addReceivedMessage)( void *pUserData, unsigned long key, int msgLength, char *pWmqttMsg );
    int  (*updReceivedMessage)( void *pUserData, unsigned long key );
    int  (*delReceivedMessage)( void *pUserData, unsigned long key );
} MQISDP_PERSIST;

/* Connect parameters - fixed length portion*/
typedef struct struct_CP {
    long            strucLength;    /* Fixed length plus variable portion length */
    char            clientId[MQISDP_CLIENT_ID_LENGTH + 1];
    long            retryCount;
    long            retryInterval;  /* seconds */
    unsigned short  options;        /* WILL flag, WILL retain, WILL QoS and Clean Start */
    unsigned short  keepAliveTime;  /* seconds */
    MQISDP_PERSIST *pPersistFuncs;
    char           *brokerHostname;
    long            brokerPort;
} CONN_PARMS;
/*  Connect parameters              - variable length portion
    long         willTopicLength;
    char         willTopic[n];      - Must be 4 byte aligned and padded with space
    long         willMessageLength;
    char         willMessage[n];    - Must be 4 byte aligned and padded with space
*/

/* Publish parameters - fixed length portion */
typedef struct struct_PP {
    long  strucLength;
    long  options;
    long  topicLength;
    char *topic;
    long  dataLength;
    char *data;
} PUB_PARMS;

/* Subscribe parameters - fixed length portion */
typedef struct struct_SP {
    long strucLength;    /* Fixed length plus variable portion length */
} SUB_PARMS;
/* Subscribe parameters - variable length portion 
    long topicLength;
    char topic[n];      - Must be 4 byte aligned and padded with space
    long options;       - currently only the QoS
    
    NOTE: topicLength, topic and options must be adjacent, and may repeat as a triplet
*/

/* Unsubscribe parameters */
typedef struct struct_UP {
    long strucLength;    /* Fixed length plus variable portion length */
} UNSUB_PARMS;
/* Unsubscribe parameters - variable length portion 
    long topicLength;
    char topic[n];        - Must be 4 byte aligned and padded with space
    
    NOTE: topicLength and topic must be adjacent, and may repeat as a pair
*/

/* ReceivePublication parameters */
typedef struct struct_RP {
    long strucLength;
    long options;         /* Retain and QoS flags                      */
} RCVPUB_PARMS;


/***********************/
/* Function prototypes */
/***********************/

/* MQIsdp_connect                        */
/* Inputs : CONN_PARMS                   */
/* Returns: MQISDPCH (connection handle) */
/*          int return code              */
DllExport int MQIsdp_connect( MQISDPCH   *pHconn,
                              CONN_PARMS *pConnParms,
                              MQISDPTI   *pTaskInfo );

/* MQIsdp_disconnect                     */
/* Inputs : MQISDPCH (connection handle) */
/* Returns: int return code              */
DllExport int MQIsdp_disconnect( MQISDPCH *pHconn );

/* MQIsdp_publish                        */
/* Inputs : MQISDPCH (connection handle) */
/*          PUB_PARMS                    */
/*          dataLength                   */
/*          data to publish              */
/* Returns: int return code              */
/*          MQISDPMH (message handle)    */
DllExport int MQIsdp_publish( MQISDPCH   hConn,
                              MQISDPMH  *pHmsg,
                              PUB_PARMS *pPubParms );

/* MQIsdp_subscribe                      */
/* Inputs : MQISDPCH (connection handle) */
/*          SUB_PARMS                    */
/* Returns: int return code              */
/*          MQISDPMH (message handle)    */
DllExport int MQIsdp_subscribe( MQISDPCH   hConn,
                                MQISDPMH  *pHmsg,
                                SUB_PARMS *pSubParms );

/* MQIsdp_unsubscribe                    */
/* Inputs : MQISDPCH (connection handle) */
/*          UNSUB_PARMS                  */
/* Returns: int return code              */
/*          MQISDPMH (message handle)    */
DllExport int MQIsdp_unsubscribe( MQISDPCH     hConn,
                                  MQISDPMH    *pHmsg,
                                  UNSUB_PARMS *pUnsubParms );

/* MQIsdp_status                         */
/* Inputs : MQISDPCH (connection handle) */
/*          errorStringLength            */
/*          errorString buffer           */
/* Returns: int status code              */
/*          errorCode                    */
/*          text in errorString          */
DllExport int MQIsdp_status( MQISDPCH  hConn,
                             long      errorStringLength,
                             long     *errorCode,
                             char     *errorString );
                             /* errorString and errorCode may be NULL if error information is not wanted */

/* MQIsdp_receivePub                     */
/* Inputs : MQISDPCH (connection handle) */
/*          msTimeout                    */
/*          msgBufferLength              */
/* Returns: int return code              */
/*          RCVPUB_PARMS                 */
/*          topicLength - actual length  */
/*          dataLength - actual length   */
/*          data in msgBuffer            */
/*                                       */
/* NOTE: The topic will be returned as the first 'topicLength' bytes of msgBuffer */
DllExport int MQIsdp_receivePub( MQISDPCH      hConn,
                                 long          msTimeout,
                                 long         *options,  /* Retain, duplicate and QoS flags */
                                 long         *topicLength,
                                 long         *dataLength,
                                 long          msgBufferLength,
                                 char         *msgBuffer ); 

/* MQIsdp_getMsgStatus                   */
/* Inputs : MQISDPCH (connection handle) */
/*          MQISDPMH (message handle)    */
/* Returns: int status code              */
DllExport int MQIsdp_getMsgStatus( MQISDPCH hConn,
                                   MQISDPMH hMsg );

/* MQIsdp_terminate                      */
/* Inputs : none                         */
/* Returns: int status code              */
DllExport int MQIsdp_terminate( void );


/* MQIsdp_SendTask                                     */
/* Inputs : MQISDPTI struct defining task/thread parms */
/* Returns: int task/thread completion code            */
DllExport int MQIsdp_SendTask( MQISDPTI *pTaskInfo );

/* MQIsdp_ReceiveTask                                  */
/* Inputs : MQISDPTI struct defining task/thread parms */
/* Returns: int task/thread completion code            */
DllExport int MQIsdp_ReceiveTask( MQISDPTI *pTaskInfo );

/* MQIsdp_StartTasks                                   */
/* Inputs : Malloc'ed storage for each MQISDPTI struct */
/*          A valid client id                          */
/* Returns: 0 if tasks successfully started            */
/*          MQISDPTI structures are correctly populated*/
DllExport int MQIsdp_StartTasks( MQISDPTI *pApiTaskInfo,
                                 MQISDPTI *pSendTaskInfo,
                                 MQISDPTI *pRcvTaskInfo,
                                 char *pClientId );

/* MQIsdp_version                           */
/* Version information is printed to stdout */
/* Inputs : none                            */
/* Returns: none                            */
DllExport void MQIsdp_version( void );

#if defined(__cplusplus)
} /* extern "C" { */
#endif

#endif
