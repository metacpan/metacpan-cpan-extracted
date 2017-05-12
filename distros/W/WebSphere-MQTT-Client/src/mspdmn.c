/****************************************************************************/
/*                                                                          */
/* Program name: MQIsdp protocol C Language implementation                  */
/*                                                                          */
/* Description: This source file contains the send and receive functions to */
/* run in the send and receive threads.                                     */
/*                                                                          */
/*  Statement:  Licensed Materials - Property of IBM                        */
/*                                                                          */
/*              MQSeries SupportPac IA93                                    */
/*              (C) Copyright IBM Corp. 2002                                */
/*                                                                          */
/****************************************************************************/
/* Version @(#) IA93/ship/mspdmn.c, SupportPacs, S000 1.2 03/08/26 16:38:18  */
/*                                                                          */
/* Function:                                                                */
/*                                                                          */
/* The send thread is where the bulk of the processing occurs. The receive  */
/* thread simply reads messages from the socket and passes them across to   */
/* the send thread for further processing.                                  */
/*                                                                          */
/****************************************************************************/
/*                                                                          */
/* Change history:                                                          */
/*                                                                          */
/* V1.0   19-02-2003  IRH  Initial release                                  */
/*                                                                          */
/*==========================================================================*/
/* Module Name: mspdmn.c                                                    */
#include <mspdmn.h>

/* Global variable controlling the shutdown of all threads behind the API */                             
int mspEnding = 0;
                        
int mspWriteDataToSendTask( RCVHCONN rcvHconn, long dataLength, char *pData );

/* This is the entry point that the client application must start as a thread / task */
/* before calling the API. It starts up mspHandleClientConnection, which contains    */
/* the main processing logic.                                                        */
DllExport int MQIsdp_SendTask( MQISDPTI *pTaskInfo ) {
    HCONNCB    *pHconn;

    pHconn = mspInitialise( pTaskInfo );
    
    mspHandleClientConnection( pHconn );

    mspTCPTerm();
    
    return 0;
}

/* This is the entry point that the client application must start as a thread / task */
/* before calling the API. It reads data from the socket and passes it back to the   */
/* send task.                                                                        */
/* The receive task can be doing one of two things: */
/* Initially it reads its mailbox, waiting to be sent a socket descriptor */
/* Once it has a socket descriptor it then waits on that socket for data  */
/* If the socket becomnes invalid, then it goes back to its mail box to   */
/* wait for a new socket descriptor                                       */
DllExport int MQIsdp_ReceiveTask( MQISDPTI *pTaskInfo ) {
    RCVHCONN rcvHconn;
    long     bytesRead = 0;
    char     ec[MSP_EC_LENGTH];
    int      rc;
    
    /* Initialise all variables */
    rcvHconn.comParms.memLimit = 0;
    rcvHconn.comParms.mspLogOptions = pTaskInfo->logLevel;
    #if MSP_DEBUG_MEM > 0
    rcvHconn.comParms.memMax = 0;
    rcvHconn.comParms.mc = 0;
    rcvHconn.comParms.fc = 0;
    rcvHconn.comParms.memCount = 0;
    #endif

    rcvHconn.sockfd = MSP_INVALID_SOCKET;

    rcvHconn.ipcCb.sendMailbox = pTaskInfo->sendMailbox;
    rcvHconn.ipcCb.receiveMailbox = pTaskInfo->receiveMailbox;
    rcvHconn.ipcCb.apiMailbox = MSP_NULL_MAILBOX;
    rcvHconn.ipcCb.sendMutex = pTaskInfo->sendMutex;
    rcvHconn.ipcCb.receiveSemaphore = (MSH)MSP_NULL_SEMAPHORE;
    rcvHconn.ipcCb.readTimeout = 5000;   /* 5 seconds */
    rcvHconn.ipcCb.options = 0;
    rcvHconn.ipcCb.ipcBufferSz = MSP_DEFAULT_IPC_BUFFER_SZ;
    rcvHconn.ipcCb.pIpcBuffer = mspMalloc( &(rcvHconn.comParms), rcvHconn.ipcCb.ipcBufferSz );
    mspInitialiseIPC( rcvHconn.ipcCb.receiveMailbox, &(rcvHconn.ipcCb) );

    /* Start the main processing loop */
    while ( mspEnding == 0 ) {
        if ( rcvHconn.sockfd != MSP_INVALID_SOCKET ) {
            mspGetDataFromNetwork( &(rcvHconn.sockfd), &(rcvHconn.comParms),
                                   &(rcvHconn.lastError), &bytesRead,
                                   &(rcvHconn.ipcCb.ipcBufferSz),
                                   &(rcvHconn.ipcCb.pIpcBuffer), 5000 );

            if ( bytesRead > 0 ) {
                mspWriteDataToSendTask( rcvHconn, bytesRead, rcvHconn.ipcCb.pIpcBuffer );
            }
        } else {
            /* Block on the mailbox waiting to receive a socket handle */
            if ( mspReadIPC( rcvHconn.ipcCb.receiveMailbox, &(rcvHconn.ipcCb),
                             &(rcvHconn.comParms), &bytesRead, &(rcvHconn.ipcCb.ipcBufferSz),
                             (void**)&(rcvHconn.ipcCb.pIpcBuffer), ec, &rc, NULL ) == 0 ) {
                if ( memcmp( ec, RCON_S, MSP_EC_LENGTH ) == 0 ) {
                    /* The socket descriptor was inserted in the rc field */
                    rcvHconn.sockfd = rc;
                }
            }
        }

    }

    mspFree( &(rcvHconn.comParms), rcvHconn.ipcCb.pIpcBuffer, rcvHconn.ipcCb.ipcBufferSz );

    /* Log the memory allocation. No correction is required because */
    /* all malloc's were recorded.                                  */
    mspLogMem( &rcvHconn.comParms, "RCV ", 0 );

    return 0;
}

/* Pass data received by the receive task to the send task for queuing */
int mspWriteDataToSendTask( RCVHCONN rcvHconn, long dataLength, char *pData ) {
    long bytesRead = 0;
    char ec[MSP_EC_LENGTH];
    int  retCode = 0;
    int  rc = 1;

    /* Obtain the mutex so that we can write to the send task */
    if ( mspLockMutex( rcvHconn.ipcCb.sendMutex ) == 0 ) {
        
        if ( mspWriteIPC( rcvHconn.ipcCb.sendMailbox, &(rcvHconn.ipcCb),
                          RTSK_S, 0, 0, dataLength, pData ) == 0 ) {

            rc = 1;
            /* If a TCP/IP error occurs then there is a small chance that we may */
            /* receive a new socket handle instead of the response we expect.    */
            while ( rc == 1 ) {
                /* Now wait for a response */
                rc = mspReadIPC( rcvHconn.ipcCb.receiveMailbox, &(rcvHconn.ipcCb),
                                 &(rcvHconn.comParms), &bytesRead, &(rcvHconn.ipcCb.ipcBufferSz),
                                 (void**)&(rcvHconn.ipcCb.pIpcBuffer), ec, &retCode, NULL );

                if ( memcmp( ec, RTSK_R, MSP_EC_LENGTH ) == 0 ) {
                    rc = 0;
                } else if ( memcmp( ec, RCON_S, MSP_EC_LENGTH ) == 0 ) {
                    /* The socket descriptor was inserted in the retCode field */
                    rcvHconn.sockfd = retCode;
                } 
            }
        }

        mspReleaseMutex( rcvHconn.ipcCb.sendMutex );
    }

    return rc; 
}

