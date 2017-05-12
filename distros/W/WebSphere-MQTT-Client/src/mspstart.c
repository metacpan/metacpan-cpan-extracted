/****************************************************************************/
/*                                                                          */
/* Program name: MQIsdp protocol C Language implementation                  */
/*                                                                          */
/* Description: This source file contains the thread startup code for       */
/*              Windows and System V UNIX platforms.                        */
/*                                                                          */
/*  Statement:  Licensed Materials - Property of IBM                        */
/*                                                                          */
/*              MQSeries SupportPac IA93                                    */
/*              (C) Copyright IBM Corp. 2002                                */
/*                                                                          */
/****************************************************************************/
/* Version @(#) IA93/ship/mspstart.c, SupportPacs, S000 1.3 03/11/28 16:44:01  */
/*                                                                          */
/* Function:                                                                */
/*                                                                          */
/* MQIsdp_StartTasks() starts the threads as appropriate for the Windows    */
/* System V UNIX platforms. On these platforms it is appropriate to create  */
/* the threads dynamically at runtime. On other platforms a different       */
/* mechanism for starting the tasks may be required.                        */
/*                                                                          */
/****************************************************************************/
/*                                                                          */
/* Change history:                                                          */
/*                                                                          */
/* V1.0   19-02-2003  IRH  Initial release                                  */
/*                                                                          */
/*==========================================================================*/
/* Module Name: mspstart.c                                                  */
#include <mspsh.h>

#if defined(WIN32)
/* Prototypes for WIN32 send and receive tasks */
DWORD WINAPI mspWinStartSendTask( MQISDPTI *pTaskInfo );
DWORD WINAPI mspWinStartRcvTask( MQISDPTI *pTaskInfo );
static int   mspWinStartTasks( MQISDPTI *pApiTaskInfo, MQISDPTI *pSendTaskInfo,
                                MQISDPTI *pRcvTaskInfo, char *pClientId );
#elif defined(UNIX)
/* Define a union required for semaphore initialisation */
union {
    int              val;
    struct semid_ds *buf;
    unsigned short  *array;
}semctl_arg;

/* Prototypes for UNIX send and receive tasks */
void*      mspUnixStartSendTask( void *pTaskInfo );
void*      mspUnixStartRcvTask( void *pTaskInfo );
static int mspUnixStartTasks( MQISDPTI *pApiTaskInfo, MQISDPTI *pSendTaskInfo,
                              MQISDPTI *pRcvTaskInfo );
#endif

DllExport int MQIsdp_StartTasks( MQISDPTI *pApiTaskInfo, MQISDPTI *pSendTaskInfo,
                                 MQISDPTI *pRcvTaskInfo, char *pClientId ) {
    #if defined(WIN32)
      return mspWinStartTasks( pApiTaskInfo, pSendTaskInfo, pRcvTaskInfo, pClientId );
    #elif defined(UNIX)
      return mspUnixStartTasks( pApiTaskInfo, pSendTaskInfo, pRcvTaskInfo );
    #endif
}

#ifdef UNIX
static int mspUnixStartTasks( MQISDPTI *pApiTaskInfo, MQISDPTI *pSendTaskInfo,
                               MQISDPTI *pRcvTaskInfo ) {
    #ifndef MSP_SINGLE_THREAD
    pthread_t      threadId;
    pthread_attr_t threadArgs;
    int      apifd[2];    /* API thread pipe     */
    int      sendfd[2];   /* SEND thread pipe    */
    int      rcvfd[2];    /* RECEIVE thread pipe */
    MTH      mutexid;
    MSH      semHandle;

    /* Create the server end of the mailboxes */
    if ( pipe( apifd ) < 0 ) {
        printf( "mspUnixStartTasks:API pipe error\n" );
    }
    if ( pipe( sendfd ) < 0 ) {
        printf( "mspUnixStartTasks:SEND pipe error\n" );
    }
    if ( pipe( rcvfd ) < 0 ) {
        printf( "mspUnixStartTasks:RCV pipe error\n" );
    }

    /* Create the mutex for coordinating the threads and initialise */
    mutexid = semget( IPC_PRIVATE, 1, 0666 );
    semctl_arg.val = 1;
    semctl( mutexid, 0, SETVAL, semctl_arg );
    
    /* Create the semaphore for coordinating blocking receives   */
    semHandle = (MSH)malloc( sizeof(MSH_S) );
    pthread_mutex_init( &semHandle->semLock, NULL );
    pthread_cond_init( &semHandle->msgSignal, NULL );
    semHandle->msgAvailable = 0x00;

    /* Create all the handles required by the api task */
    /* API task requires: apiMailBox   read            */
    /*                    sendMailbox  write           */
    /*                    sendMutex                    */
    /*                    receiveSemaphore             */
    pApiTaskInfo->apiMailbox  = apifd[0];
    pApiTaskInfo->sendMailbox = sendfd[1];
    pApiTaskInfo->sendMutex = mutexid; 
    pApiTaskInfo->receiveSemaphore = semHandle; 

    /* Create all the mailbox handles required by send task */
    /* Send task requires: apiMailBox      write            */
    /*                     sendMailbox     read             */
    /*                     receiveMailbox  write            */
    /*                     sendMutex                        */
    /*                     receiveSemaphore                 */
    pSendTaskInfo->sendMailbox      = sendfd[0];
    pSendTaskInfo->apiMailbox       = apifd[1];
    pSendTaskInfo->receiveMailbox   = rcvfd[1];
    pSendTaskInfo->sendMutex = mutexid; 
    pSendTaskInfo->receiveSemaphore = semHandle;

    /* Create all the handles required by the receive task */
    /* Receive task requires: sendMailBox      write       */
    /*                        receiveMailbox   read        */
    /*                        sendMutex                    */
    pRcvTaskInfo->receiveMailbox = rcvfd[0];
    /* Duplicate the file descriptor as we have already used it for the api task */
    pRcvTaskInfo->sendMailbox    = dup( sendfd[1] ); 
    pRcvTaskInfo->sendMutex = mutexid; 

    /* Fire up the receive task thread */
    pthread_attr_init( &threadArgs );
    pthread_attr_setdetachstate( &threadArgs, PTHREAD_CREATE_DETACHED );

    if( pthread_create( &threadId, &threadArgs, mspUnixStartRcvTask, (void*)pRcvTaskInfo ) != 0 ) {
        return 1;
    }
        
    /* Fire up the send task thread */
    pthread_attr_init( &threadArgs );
    pthread_attr_setdetachstate( &threadArgs, PTHREAD_CREATE_DETACHED );
    
    if ( pthread_create( &threadId, &threadArgs, mspUnixStartSendTask, (void*)pSendTaskInfo ) != 0 ) {
        return 1;
    }
    
    #endif
    return 0;
}

void* mspUnixStartSendTask( void *pTaskInfo ) {
    MQIsdp_SendTask( (MQISDPTI*)pTaskInfo );
    return NULL;
}

void* mspUnixStartRcvTask( void *pTaskInfo ) {
    MQIsdp_ReceiveTask( (MQISDPTI*)pTaskInfo );
    return NULL;
}

#endif

#ifdef WIN32
static int mspWinStartTasks( MQISDPTI *pApiTaskInfo, MQISDPTI *pSendTaskInfo,
                              MQISDPTI *pRcvTaskInfo, char *pClientId ) {
    #ifndef MSP_SINGLE_THREAD
    HANDLE    hThread;
    DWORD     threadId;
    char     *mailboxNameStem    = "\\\\.\\mailslot\\MQISDP_";
    int       mailboxNameLen;
    char     *apiMailboxName     = NULL;
    char     *sendMailboxName    = NULL;
    char     *receiveMailboxName = NULL;
    char     *sendMutexName      = NULL;
    char     *receiveSemName     = NULL;

    /* Use the clientId to make the various object names unique */
    mailboxNameLen = strlen( mailboxNameStem ) + strlen( pClientId ) + 5;
    
    apiMailboxName = (char*)malloc(mailboxNameLen);
    sendMailboxName = (char*)malloc(mailboxNameLen);
    receiveMailboxName = (char*)malloc(mailboxNameLen);
    sendMutexName = (char*)malloc( strlen(pClientId) + 12 );
    receiveSemName = (char*)malloc( strlen(pClientId) + 12 );

    /* Set up the API mailbox name */
    sprintf( apiMailboxName, "%sAPI_%s", mailboxNameStem, pClientId );

    /* Set up the SEND mailbox name */
    sprintf( sendMailboxName, "%sSND_%s", mailboxNameStem, pClientId );

    /* Set up the RCV mailbox name */
    sprintf( receiveMailboxName, "%sRCV_%s", mailboxNameStem, pClientId );

    /* Set up the send mutex name */
    sprintf( sendMutexName, "MQISDP_SND_%s", pClientId );

    /* Set up the receive semaphore name */
    sprintf( receiveSemName, "MQISDP_RCV_%s", pClientId );
    
    /* Create the server end of the mailboxes */
    pApiTaskInfo->apiMailbox     = CreateMailslot( apiMailboxName    , 40, 0, NULL );
    pSendTaskInfo->sendMailbox   = CreateMailslot( sendMailboxName   , 40, 0, NULL );
    pRcvTaskInfo->receiveMailbox = CreateMailslot( receiveMailboxName, 40, 0, NULL );

    /* Create the mutex for coordinating the threads */
    pSendTaskInfo->sendMutex = CreateMutex( NULL, FALSE, sendMutexName ); 
    
    /* Create the semaphore for coordinating blocking receives */
    pSendTaskInfo->receiveSemaphore = CreateSemaphore( NULL, 0, 1, receiveSemName );

    /* Create all the handles required by the api task */
    /* API task requires: apiMailBox                   */
    /*                    sendMailbox                  */
    /*                    sendMutex                    */
    /*                    receiveSemaphore             */
    pApiTaskInfo->sendMailbox     = CreateFile( sendMailboxName,
                                                GENERIC_WRITE,
                                                FILE_SHARE_READ | FILE_SHARE_WRITE,
                                                NULL,
                                                OPEN_EXISTING,
                                                FILE_ATTRIBUTE_NORMAL,
                                                NULL );

    pApiTaskInfo->sendMutex = OpenMutex( MUTEX_ALL_ACCESS | SYNCHRONIZE, FALSE, sendMutexName );
    pApiTaskInfo->receiveSemaphore = OpenSemaphore( SEMAPHORE_ALL_ACCESS, FALSE, receiveSemName ); 

    /* Create all the mailbox handles required by send task */
    /* Send task requires: apiMailBox                       */
    /*                     sendMailbox                      */
    /*                     receiveMailbox                   */
    /*                     sendMutex                        */
    /*                     receiveSemaphore                 */
    pSendTaskInfo->apiMailbox     = CreateFile( apiMailboxName,
                                                GENERIC_WRITE,
                                                FILE_SHARE_READ | FILE_SHARE_WRITE,
                                                NULL,
                                                OPEN_EXISTING,
                                                FILE_ATTRIBUTE_NORMAL,
                                                NULL );

    pSendTaskInfo->receiveMailbox     = CreateFile( receiveMailboxName,
                                                    GENERIC_WRITE,
                                                    FILE_SHARE_READ | FILE_SHARE_WRITE,
                                                    NULL,
                                                    OPEN_EXISTING,
                                                    FILE_ATTRIBUTE_NORMAL,
                                                    NULL );

    /* Create all the handles required by the receive task */
    /* Receive task requires: sendMailBox                  */
    /*                        receiveMailbox               */
    /*                        sendMutex                    */
    pRcvTaskInfo->sendMailbox     = CreateFile( sendMailboxName,
                                                GENERIC_WRITE,
                                                FILE_SHARE_READ | FILE_SHARE_WRITE,
                                                NULL,
                                                OPEN_EXISTING,
                                                FILE_ATTRIBUTE_NORMAL,
                                                NULL );

    pRcvTaskInfo->sendMutex = OpenMutex( MUTEX_ALL_ACCESS | SYNCHRONIZE, FALSE, sendMutexName );

    /* Fire up the receive task thread */
    hThread = CreateThread( NULL, 0, mspWinStartRcvTask, pRcvTaskInfo, 0, &threadId );
    
    if ( hThread == NULL ) {
        return 1;
    }
    
    /* Fire up the send task thread */
    hThread = CreateThread( NULL, 0, mspWinStartSendTask, pSendTaskInfo, 0, &threadId );

    if ( hThread == NULL ) {
        return 1;
    }

    #endif
    return 0;
}

DWORD WINAPI mspWinStartSendTask( MQISDPTI *pTaskInfo ) {

    MQIsdp_SendTask( pTaskInfo );

    return 0;
}
DWORD WINAPI mspWinStartRcvTask( MQISDPTI *pTaskInfo ) {

    MQIsdp_ReceiveTask( pTaskInfo );

    return 0;
}
#endif

