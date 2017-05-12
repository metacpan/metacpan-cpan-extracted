/****************************************************************************/
/*                                                                          */
/* Program name: MQIsdp protocol C Language implementation                  */
/*                                                                          */
/* Description: This source file contains the API to the MQIsdp protocol.   */
/* All functions in this file pass the received data across to the send     */
/* thread for processing.                                                   */
/*                                                                          */
/*  Statement:  Licensed Materials - Property of IBM                        */
/*                                                                          */
/*              MQSeries SupportPac IA93                                    */
/*              (C) Copyright IBM Corp. 2002, 2003                          */
/*                                                                          */
/****************************************************************************/
/* Version @(#) IA93/ship/mspclnt.c, SupportPacs, S000 1.3 03/08/26 16:38:15  */
/*                                                                          */
/* Function:                                                                */
/*                                                                          */
/* Contains the API that is exposed to client applications.                 */
/*                                                                          */
/****************************************************************************/
/*                                                                          */
/* Change history:                                                          */
/*                                                                          */
/* V1.0   19-02-2003  IRH  Initial release                                  */
/*                                                                          */
/*==========================================================================*/
/* Module Name: mspclnt.c                                                   */
#ifdef MSP_SINGLE_THREAD
#include <mspdmn.h>
#endif
#include <mspclnt.h>

static int mspCopyDataToBuffer( MSPCCB *pConnHandle, char **ppCpToBuffer, long *cpToSz,
                                char *pCpFromBuffer, int cpFromSz );
static int mspIPCExchange( MSPCCB *pConnHandle, char *pEc, MQISDPMH hMsgWrite, char *pData,
                               long dataLength, long *pBytesRead, char* pEcRead, MQISDPMH *pHmsgRead );

/* Global variable controlling the shutdown of all threads behind the API, defined in mspdmn.c */
extern int mspEnding;
                        
/* MQIsdp_connect */
/* Initialise the connection handle and connect to the send thread      */
/* phConn must be MQISDP_INV_CONN_HANDLE prior to issuing the connect   */
/* return MQISDP_OK on success, or an error code                        */
DllExport int MQIsdp_connect( MQISDPCH *phConn, CONN_PARMS *pMspCp, MQISDPTI *pTaskInfo ) {
    int      rc = MQISDP_FAILED;
    long     bytesRead = 0;
    char     eyeCatcher[MSP_EC_LENGTH];
    MSPCCB  *pConnHandle;

    if ( *phConn != MQISDP_INV_CONN_HANDLE ) {
        return MQISDP_ALREADY_CONNECTED;
    }

    *phConn = MQISDP_INV_CONN_HANDLE;

    pConnHandle = (MSPCCB*)mspMalloc( NULL, sizeof(MSPCCB) );

    if ( pConnHandle == NULL ) {
        return MQISDP_OUT_OF_MEMORY;
    }

    pConnHandle->comParms.memLimit = 0;
    pConnHandle->comParms.mspLogOptions = pTaskInfo->logLevel;
    #if MSP_DEBUG_MEM > 0
    pConnHandle->comParms.memMax = 0;
    pConnHandle->comParms.memCount = 0;
    pConnHandle->comParms.mc = 0;
    pConnHandle->comParms.fc = 0;
    #endif
    
    /* Validate the client identifier */
    if ( strlen(pMspCp->clientId) > MQISDP_CLIENT_ID_LENGTH ) {
        mspFree( NULL, pConnHandle, sizeof(MSPCCB) );
        return MQISDP_CLIENT_ID_ERROR;
    }
        
    pConnHandle->ipcCb.apiMailbox = pTaskInfo->apiMailbox;
    pConnHandle->ipcCb.sendMailbox = pTaskInfo->sendMailbox;
    pConnHandle->ipcCb.receiveMailbox = MSP_NULL_MAILBOX; /* Don't need to know the receive threads mail box */
    pConnHandle->ipcCb.sendMutex = pTaskInfo->sendMutex;
    pConnHandle->ipcCb.receiveSemaphore = pTaskInfo->receiveSemaphore;

    /* Set the IPC buffer size to the maximum of the CONN_PARMS length or */
    /* the default IPC buffer size                                        */
    if ( pMspCp->strucLength > MSP_DEFAULT_IPC_BUFFER_SZ ) {
        pConnHandle->ipcCb.ipcBufferSz = pMspCp->strucLength;
    } else {
        pConnHandle->ipcCb.ipcBufferSz = MSP_DEFAULT_IPC_BUFFER_SZ;
    }
    pConnHandle->ipcCb.pIpcBuffer = (char*)mspMalloc( &(pConnHandle->comParms),
                                                      pConnHandle->ipcCb.ipcBufferSz );
    pConnHandle->ipcCb.options = 0x00 | MSP_IPC_BLOCK;
    pConnHandle->ipcCb.readTimeout = MSP_IPC_WAIT_FOREVER;

    /* Initialise the IPC for this task - the API */
    mspInitialiseIPC( pConnHandle->ipcCb.apiMailbox, &(pConnHandle->ipcCb) );

    #ifdef MSP_SINGLE_THREAD
        pConnHandle->pSendHconn = mspInitialise( NULL );
        /* When running single threaded we set up a pseudo mailbox for */
        /* communication, with the buffer being part of the client     */
        /* connection handle.                                          */
        pConnHandle->ipcCb.pPseudoMailbox = pConnHandle->mspIpcBuffer;
        pConnHandle->pSendHconn->ipcCb.pPseudoMailbox = pConnHandle->mspIpcBuffer;
    #endif
    
    rc = mspIPCExchange( pConnHandle, CONN_S, 0, (char*)pMspCp, pMspCp->strucLength,
                             &bytesRead, eyeCatcher, NULL );
    
    if ( rc == MQISDP_OK ) {
        *phConn = (MQISDPCH)pConnHandle;
    } else {
        *phConn = MQISDP_INV_CONN_HANDLE;
        mspFree( NULL, pConnHandle, sizeof(MSPCCB) );
    }

    return rc;
}

/* MQIsdp_disconnect */
/* Disconnect from the send thread and free up the connection handle */
DllExport int MQIsdp_disconnect( MQISDPCH *phConn ) {
    int      rc = MQISDP_FAILED;
    long     bytesRead = 0;
    char     eyeCatcher[MSP_EC_LENGTH];
    MSPCCB  *pConnHandle;

    if ( *phConn == MQISDP_INV_CONN_HANDLE ) {
        return MQISDP_CONN_HANDLE_ERROR;
    }

    pConnHandle = (MSPCCB*)*phConn;
        
    rc = mspIPCExchange( (MSPCCB*)*phConn, DISC_S, 0, NULL, 0, &bytesRead, eyeCatcher, NULL );

    if (rc != MQISDP_FAILED ) {
        mspFree( &pConnHandle->comParms, pConnHandle->ipcCb.pIpcBuffer,
                 pConnHandle->ipcCb.ipcBufferSz );

        /* Log the memory allocation. Add a correction of the size of the connection */
        /* handle because that was on the heap, but not counted because the          */
        /* structure was malloc'ed before stats were recorded.                       */
        mspLogMem( &pConnHandle->comParms, "API ", sizeof(MSPCCB) );
    
        mspFree( NULL, pConnHandle, sizeof(MSPCCB) );
        *phConn = MQISDP_INV_CONN_HANDLE;
    }

    return rc;
}

/* MQIsdp_subscribe */
/* Pass the subscribe message to the send thread */
DllExport int MQIsdp_subscribe( MQISDPCH   hConn,
                                MQISDPMH  *pHmsg,
                                SUB_PARMS *pMspSp ) {
    int      rc = MQISDP_FAILED;
    long     bytesRead = 0;
    char     eyeCatcher[MSP_EC_LENGTH];

    *pHmsg = MQISDP_INV_MSG_HANDLE;
    
    if ( hConn == MQISDP_INV_CONN_HANDLE ) {
        return MQISDP_CONN_HANDLE_ERROR;
    }

    rc = mspIPCExchange( (MSPCCB*)hConn, SUB_S, 0, (char*)pMspSp, pMspSp->strucLength,
                             &bytesRead, eyeCatcher, pHmsg );
    return rc;
}

/* MQIsdp_unsubscribe */
/* Pass the unsubscribe message to the send thread */
DllExport int MQIsdp_unsubscribe( MQISDPCH   hConn,
                                  MQISDPMH  *pHmsg,
                                  UNSUB_PARMS *pMspUp ) {

    int      rc = MQISDP_FAILED;
    long     bytesRead = 0;
    char     eyeCatcher[MSP_EC_LENGTH];

    *pHmsg = MQISDP_INV_MSG_HANDLE;
    
    if ( hConn == MQISDP_INV_CONN_HANDLE ) {
        return MQISDP_CONN_HANDLE_ERROR;
    }

    rc = mspIPCExchange( (MSPCCB*)hConn, UNS_S, 0, (char*)pMspUp, pMspUp->strucLength,
                             &bytesRead, eyeCatcher, pHmsg );
    return rc;
}

/* MQIsdp_publish */
/* Pass the publish message to the send thread */
DllExport int MQIsdp_publish( MQISDPCH   hConn,
                              MQISDPMH  *pHmsg,
                              PUB_PARMS *pMspPp ){
    int      rc = MQISDP_FAILED;
    long     bytesRead = 0;
    char     eyeCatcher[MSP_EC_LENGTH];

    *pHmsg = MQISDP_INV_MSG_HANDLE;
    
    if ( hConn == MQISDP_INV_CONN_HANDLE ) {
        return MQISDP_CONN_HANDLE_ERROR;
    }
    if ( pMspPp->dataLength <= 0 ) {
        return MQISDP_DATA_LENGTH_ERROR;
    }
        
    rc = mspIPCExchange( (MSPCCB*)hConn, PUB_S, 0, (char*)pMspPp, pMspPp->strucLength,
                             &bytesRead, eyeCatcher, pHmsg );
    return rc;
}

/* MQIsdp_getMsgStatus */
/* Find out if a particular message has been delivered successfully or not */
DllExport int MQIsdp_getMsgStatus( MQISDPCH hConn, MQISDPMH hMsg ) {
    int      rc = MQISDP_FAILED;
    long     bytesRead = 0;
    char     eyeCatcher[MSP_EC_LENGTH];

    if ( hConn == MQISDP_INV_CONN_HANDLE ) {
        return MQISDP_CONN_HANDLE_ERROR;
    }

    rc = mspIPCExchange( (MSPCCB*)hConn, MSG_S, hMsg, NULL, 0, &bytesRead, eyeCatcher, NULL );
    
    return rc;
}

/* MQIsdp_status */
/* Find out the current state of the MQIsdp connection */
/* Valid states are:                                   */
/*    MQISDP_CONNECTING                                */
/*    MQISDP_CONNECTED                                 */
/*    MQISDP_CONNECTION_BROKEN                         */
/* MQISDP_CONNECTION_BROKEN indicates that all retry attempts by the client have failed.    */
/* The application should disconnect after checking the state of all messages and take some */
/* other action.                                                                            */
DllExport int MQIsdp_status( MQISDPCH hConn, long errStrLen, long *errCode, char *errStr ) {
    int      rc = MQISDP_FAILED;
    long     bytesRead = 0;
    char    *pData;
    char     eyeCatcher[MSP_EC_LENGTH];
    MSPCCB  *pConnHandle;

    if ( errStr != NULL ) {
        errStr[0] = '\0';
    }
    if ( errCode != NULL ) {
        *errCode = 0;
    }
    
    if ( hConn == MQISDP_INV_CONN_HANDLE ) {
        return MQISDP_CONN_HANDLE_ERROR;
    }

    rc = mspIPCExchange( (MSPCCB*)hConn, STAT_S, 0, NULL, 0, &bytesRead, eyeCatcher, NULL );
    
    if ( (rc != MQISDP_FAILED) && (bytesRead > 0 ) ) {
        pConnHandle = (MSPCCB*)hConn;
        /* First retrieve the error code */
        pData = (char*)pConnHandle->ipcCb.pIpcBuffer;
        if ( errCode != NULL ) {
            memcpy( errCode, pData, sizeof(long) );
        }
        pData += sizeof(long);

        /* Next see if there is an error string */
        if ( bytesRead > sizeof(long) ) {
            strncpy( errStr, pData, errStrLen );
            errStr[errStrLen-1] = '\0';
        } else {
            errStr[0] = '\0';
        }
    }

    return rc;
}

/* MQIsdp_receivePub */
/* The code needs to send a confirmation message to the daemon to indicate that the client */
/* application successfully received the publication. This is so that if the receiving     */
/* application specifies a buffer that is too small then the message is not deleted from   */
/* the daemon queue.                                                                       */
DllExport int MQIsdp_receivePub( MQISDPCH hConn, long msTimeout, long *options, long *topicLength,
                                 long *dataLength, long msgBufferLength, char *msgBuffer ) {
    char    *pData;
    int      rc = MQISDP_FAILED;
    long     bytesRead = 0;
    u_long   msgId;
    char    *pDataBuffer;
    char     eyeCatcher[MSP_EC_LENGTH];
    int      returnCode;
    MSPCCB  *pConnHandle;
    #ifdef MSP_SINGLE_THREAD
      long waitedTime;
    #endif

    if ( hConn == MQISDP_INV_CONN_HANDLE ) {
        return MQISDP_CONN_HANDLE_ERROR;
    }

    pConnHandle = (MSPCCB*)hConn;
        
    *options = 0;
    *topicLength = 0;
    *dataLength = 0;
    
    /* mspWaitForSemaphore waits for the receive semaphore to become signalled */
    /* indicating that publications are available. This function only has any  */
    /* effect if the code is built without MSP_SINGLE_THREAD defined           */
    mspWaitForSemaphore( pConnHandle->ipcCb.receiveSemaphore, msTimeout );
    
    /* Regardless of the result of wait for semaphore we want to ask the send thread */
    /* for publications, even if there are none, because it may send as back a return*/
    /* code indicating that there is a problem e.g. CONNECTION_BROKEN                */
    if ( mspLockMutex( pConnHandle->ipcCb.sendMutex ) == 0 ) {
        #ifdef MSP_SINGLE_THREAD
        /* If we are single threaded, then we cannot do a simple blocking wait   */
        /* on the TCP/IP socket, as there are other things we have to do such as */
        /* retry messages, send and receive ACKS. The mspHandleClientConnection  */
        /* function will wait as long as it can before retries are required.     */
        /* Consequently multiple calls to mspHandleClientConnection are required */
        /* for the wait time to be fully satisfied.                              */
        do {
        memcpy( pConnHandle->ipcCb.pIpcBuffer, &msTimeout, sizeof(long) );
        #endif
        rc = mspWriteIPC( pConnHandle->ipcCb.sendMailbox, &(pConnHandle->ipcCb),
                          RCV_S, 0, 0, sizeof(long), pConnHandle->ipcCb.pIpcBuffer );

        #ifdef MSP_SINGLE_THREAD
            mspHandleClientConnection( pConnHandle->pSendHconn );
        #endif

        /* This is a blocking read */
        rc = mspReadIPC( pConnHandle->ipcCb.apiMailbox, &(pConnHandle->ipcCb),
                         &(pConnHandle->comParms), &bytesRead,
                         &(pConnHandle->ipcCb.ipcBufferSz), (void**)&(pConnHandle->ipcCb.pIpcBuffer),
                         eyeCatcher, &returnCode, NULL );

        #ifdef MSP_SINGLE_THREAD
        if ( returnCode == MQISDP_NO_PUBS_AVAILABLE ) {
            memcpy( &waitedTime, pConnHandle->ipcCb.pIpcBuffer, sizeof(long) );
            msTimeout -= waitedTime;
        }
        } while ( (returnCode == MQISDP_NO_PUBS_AVAILABLE) && (msTimeout > 0) );
        #endif

        /* Return the required info to the API */
        rc = returnCode;
        if ( (rc == MQISDP_PUBS_AVAILABLE) || (rc == MQISDP_OK) ) {
            pData = pConnHandle->ipcCb.pIpcBuffer;

            /* Get the message id */
            memcpy( &msgId, pData, sizeof(u_long) );
            pData += sizeof(u_long);

            /* Next the options */
            if ( options != NULL ) {
                memcpy( options, pData, sizeof(long) );
            }
            pData += sizeof(long);

            /* Next the topic length */
            if ( topicLength != NULL ) {
                memcpy( topicLength, pData, sizeof(long) );
            }
            pData += sizeof(long);

            /* Next the buffer length */
            if ( dataLength != NULL ) {
                memcpy( dataLength, pData, sizeof(long) );
            }
            pData += sizeof(long);

            /* Now copy the data into the application buffer */
            if ( (msgBufferLength != 0) && (msgBuffer != NULL) ) {
                memcpy( &pDataBuffer, pData, sizeof(char*) );
                memcpy( msgBuffer, pDataBuffer, *dataLength );
            }

            /* Check if the application supplied receive buffer is big enough */
            if ( (*dataLength > msgBufferLength) || (msgBuffer == NULL) ) {
                /* App buffer is too small */
                rc = MQISDP_DATA_TRUNCATED;
                /* Decline to receive the message */
                mspWriteIPC( pConnHandle->ipcCb.sendMailbox, &(pConnHandle->ipcCb),
                             RCV_D, 0, 0, 0, NULL );
            } else {
                /* Everything OK */
                /* Now build the response to the send thread to */
                /* indicate that the data should be deleted.    */
                mspWriteIPC( pConnHandle->ipcCb.sendMailbox, &(pConnHandle->ipcCb),
                             RCV_A, 0, msgId, 0, NULL );
            }

            #ifdef MSP_SINGLE_THREAD
               mspHandleClientConnection( pConnHandle->pSendHconn );
            #endif

            /* We have to wait for an acknowledgement to this write       */
            /* otherwise we very easily get into the situation where this */
            /* API writes and returns, then the next API call writes      */
            /* resulting in 2 messages on the IPC input queue.            */
            /* This is a blocking read */
            mspReadIPC( pConnHandle->ipcCb.apiMailbox, &(pConnHandle->ipcCb),
                        &(pConnHandle->comParms), &bytesRead,
                        &(pConnHandle->ipcCb.ipcBufferSz), (void**)&(pConnHandle->ipcCb.pIpcBuffer),
                        eyeCatcher, &returnCode, NULL );

        }

        mspReleaseMutex( pConnHandle->ipcCb.sendMutex );
    }
            
    return rc;
}

/* MQIsdp_terminate */
/* Shutdown the threads running behind the API */
/* Be aware that all tasks that read this global variable will be shutdown */
DllExport int MQIsdp_terminate( void ) {
    mspEnding = 1;
    return 0;
}

/* MQIsdp_version */
/* This function displays the version of the client and the version of the */
/* WMQTT protocol supported by this client.                                */
/* The versioning information is printed to stdout.                        */
DllExport void MQIsdp_version( void ) {
    printf( "WMQTT client version  : 1.2\n" );
    printf( "WMQTT protocol version: 3.0\n\n" );
    printf( "Licensed Materials - Property of IBM\n" );
    printf( "(C) Copyright IBM Corp. 2002, 2003\n" );
}

/* This function copies data into a new buffer, enlarging the buffer if required */
/* Returns 0 on success, 1 on failure                                            */
static int mspCopyDataToBuffer( MSPCCB *pConnHandle, char **ppCpToBuffer, long *cpToSz,
                                char *pCpFromBuffer, int cpFromSz ) {
    
    if ( cpFromSz > *cpToSz ) {
        *ppCpToBuffer = mspRealloc( &pConnHandle->comParms, *ppCpToBuffer, cpFromSz, *cpToSz );
        if ( ppCpToBuffer != NULL ) {
            *cpToSz = cpFromSz;
        } else {
            *cpToSz = 0;
            return 1;
        }
    }

    memcpy( *ppCpToBuffer, pCpFromBuffer, cpFromSz );
 
    return 0;
}

/* All communications from the client application to the send thread need to send some data */
/* to the IPC and then wait for a response. mspIPCExchange is a function used by most       */
/* of the API to do the send and receive. The only exception is MQIsdp_receivePub which     */
/* has to do some extra work under the mutex lock.                                          */
static int mspIPCExchange( MSPCCB *pConnHandle, char *pEc, MQISDPMH hMsgWrite, char *pData,
                               long dataLength, long *pBytesRead, char* pEcRead, MQISDPMH *pHmsgRead ) {
    int returnCode = MQISDP_FAILED;

    if ( mspLockMutex( pConnHandle->ipcCb.sendMutex ) == 0 ) {
    
        if ( pData != NULL ) {
            /* Copy the data to write into the IPC buffer */
            mspCopyDataToBuffer( pConnHandle, &pConnHandle->ipcCb.pIpcBuffer,
                                 &pConnHandle->ipcCb.ipcBufferSz, pData, dataLength );
        }
        
        mspWriteIPC( pConnHandle->ipcCb.sendMailbox, &(pConnHandle->ipcCb),
                     pEc, 0, hMsgWrite, dataLength, (void*)pConnHandle->ipcCb.pIpcBuffer );
    
        #ifdef MSP_SINGLE_THREAD
            mspHandleClientConnection( pConnHandle->pSendHconn );
        #endif
    
        /* This is a blocking read */
        mspReadIPC( pConnHandle->ipcCb.apiMailbox, &(pConnHandle->ipcCb),
                    &(pConnHandle->comParms), pBytesRead,
                    &(pConnHandle->ipcCb.ipcBufferSz), (void**)&(pConnHandle->ipcCb.pIpcBuffer),
                    pEcRead, &returnCode, pHmsgRead );

        mspReleaseMutex( pConnHandle->ipcCb.sendMutex );
    }

    return returnCode;
}
