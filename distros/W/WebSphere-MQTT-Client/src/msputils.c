/****************************************************************************/
/*                                                                          */
/* Program name: MQIsdp protocol C Language implementation                  */
/*                                                                          */
/* Description: This source file contains the functions that are used by the*/
/*              send thread to process data to be sent and as well as data  */
/*              received.                                                   */
/*                                                                          */
/*  Statement:  Licensed Materials - Property of IBM                        */
/*                                                                          */
/*              MQSeries SupportPac IA93                                    */
/*              (C) Copyright IBM Corp. 2002                                */
/*                                                                          */
/****************************************************************************/
/* Version @(#) IA93/ship/msputils.c, SupportPacs, S000 1.4 03/08/26 16:38:36  */
/*                                                                          */
/* Function:                                                                */
/*                                                                          */
/* mspHandleClientConnection is the main function which controls both       */
/* sending and receiving of data, keeping the MQIsdp connection alive and   */
/* retrying any failed transmissions.                                       */
/*                                                                          */
/****************************************************************************/
/*                                                                          */
/* Change history:                                                          */
/*                                                                          */
/* V1.0   19-02-2003  IRH  Initial release                                  */
/*        06-06-2003  IRH  mspSendRcvPubResponse did not report any errors  */
/*                         if the connectin to the broker was broken.       */
/*                                                                          */
/*==========================================================================*/
/* Module Name: msputils.c                                                  */
#include <mspdmn.h>

/* Global flag that controls the shutting down of the send and receive threads */
/* Defined in mspdmn.c                                                         */
extern int mspEnding;

int mspInitialiseHconn( HCONNCB *pHconn, long ipcBytesRead, void *ipcrBuffer );
int mspSendGetStatusResponse( HCONNCB *pHconn, MQISDPMH hMsg );
int mspSendConnStatusResponse( HCONNCB *pHconn, long bytesRead, char *pReadBuffer );
int mspSendRcvPubResponse( HCONNCB *pHconn, long bytesRead, char *pReadBuffer );
int mspDeletePublication( HCONNCB *pHconn, char *ec, MQISDPMH hMsg );
int mspReceiveIPCMessage( HCONNCB *pHconn, char *ec, MQISDPMH hMsg, long bytesRead );
int mspResetHconn( HCONNCB * pHconn );

/*******************************************************/
/* Initialise any resources after the daemon starts up */
/*******************************************************/
HCONNCB *mspInitialise( MQISDPTI *pTaskInfo ) {
    HCONNCB *pHconn = NULL;

    /* Malloc a connection handle ready to give to the next client connection */
    pHconn = (HCONNCB*)mspMalloc( NULL, sizeof(HCONNCB) );
    if ( pHconn == NULL ) {
        return NULL;
    }

    /* Initialise the TCP/IP stack */    
    mspTCPInit();
    
    /* Initialise common parms */
    pHconn->comParms.memLimit = 0;
    if ( pTaskInfo ) {
    	pHconn->comParms.mspLogOptions = pTaskInfo->logLevel;
    } else {
    	pHconn->comParms.mspLogOptions = LOGNONE; /* -1 to enable all debugging */
    }
    #if MSP_DEBUG_MEM > 0
    pHconn->comParms.memMax = 0;
    pHconn->comParms.memCount = 0;
    pHconn->comParms.mc = 0;
    pHconn->comParms.fc = 0;
    #endif

    /* Initialise IPC parameters */
    if ( pTaskInfo != NULL ) {
        pHconn->ipcCb.apiMailbox = pTaskInfo->apiMailbox;
        pHconn->ipcCb.sendMailbox = pTaskInfo->sendMailbox;
        pHconn->ipcCb.receiveMailbox = pTaskInfo->receiveMailbox;
        pHconn->ipcCb.sendMutex = MSP_NULL_MUTEX;
        pHconn->ipcCb.receiveSemaphore = pTaskInfo->receiveSemaphore;
    }
    pHconn->ipcCb.readTimeout = 2000;
    pHconn->ipcCb.options = 0;
    pHconn->ipcCb.ipcBufferSz = MSP_DEFAULT_IPC_BUFFER_SZ;
    pHconn->ipcCb.pIpcBuffer = mspMalloc( &(pHconn->comParms), MSP_DEFAULT_IPC_BUFFER_SZ );
    mspInitialiseIPC( pHconn->ipcCb.sendMailbox, &(pHconn->ipcCb) );

    /* Initialise the input queue */
    pHconn->inQ.rcvdPubsQ = NULL;
    pHconn->inQ.rpHash = mspInitHash( pHconn, MSP_DEFAULT_NUM_HASH_KEYS );
    pHconn->inQ.numBytesQueued = 0;

    /* Initialise the output queue */
    pHconn->outQ.inProgressQ = NULL;
    pHconn->outQ.ipHash = mspInitHash( pHconn, MSP_DEFAULT_NUM_HASH_KEYS );
    pHconn->outQ.numBytesQueued = 0;

    /* Initialise the reconnect information */
    pHconn->reconnect.connectMsg = NULL;

    pHconn->apiReturnCode = MQISDP_OK;
    pHconn->connState = MQISDP_DISCONNECTED;
    pHconn->retryCount = 0;
    pHconn->timeForNextPoll = 0;
    pHconn->timeForNextRetry = 0;
    pHconn->ctrlFlags = 0;

    /* Initialise the persistence interface */
    pHconn->persistFuncs = NULL;

    /* Initialise the TCP/IP parms */
    pHconn->tcpParms.lastError = 0;
    pHconn->tcpParms.msperrno = 0;
    pHconn->tcpParms.sockfd = MSP_INVALID_SOCKET;

    /* Call mspResetHconn to initialise the rest of the Hconn */
    mspResetHconn( pHconn );

    #ifdef MSP_SINGLE_THREAD
    pHconn->tcpParms.sockWaitTime = 0;
    #endif
    
    return pHconn;
}

/* This function contains the main loop for the send thread */
/* The function spends most of its time waiting for IPC input, which may come from */
/* the API, or from the receive thread.                                            */
/* The function manages retrying failed sends, handles TCP/IP connection breakages */
/* and queues received data ready for the application to collect                   */
int mspHandleClientConnection( HCONNCB *pHconn) {
   long        bytesRead = 0;
   #ifdef MSP_SINGLE_THREAD
   long        netBytesRead = 0;
   #endif
   char        ec[MSP_EC_LENGTH];
   int         retCode;
   MQISDPMH    hMsg;
   IPQ        *curIpqEntry, *nextIpqEntry;
   
   #ifndef MSP_SINGLE_THREAD
   do {
   #else
       pHconn->tcpParms.sockWaitTime = 0;
   #endif
       /* Handle IPC input from client or receive task                             */
       /* #########################################################################*/
       if ( mspReadIPC( pHconn->ipcCb.sendMailbox, &(pHconn->ipcCb), &(pHconn->comParms),
                        &bytesRead, &(pHconn->ipcCb.ipcBufferSz),
                        (void**)&(pHconn->ipcCb.pIpcBuffer), ec, &retCode, &hMsg ) == 0 ) {
           
           /* Have a look at what type of request the client has sent in */
           mspReceiveIPCMessage( pHconn, ec, hMsg, bytesRead );

           /* Indicate that data was received */
           bytesRead = 1;
       }
       /* #########################################################################*/
       /* End of handling IPC input from client application                        */
       
       /* If an application is connected then execute the code to service   */
       /* TCP/IP and retry messages, otherwise just service the IPC mailbox */
       if ( pHconn->ctrlFlags & MSP_CLIENT_APP_CONNECTED ) {
           /* Handle TCP/IP input from the SCADA broker                                */
           /* #########################################################################*/
           /* Loop getting all available messages from the network */
           #ifdef MSP_SINGLE_THREAD
           netBytesRead = 1;
           while ( netBytesRead > 0 ) {

               if ( mspGetDataFromNetwork( &(pHconn->tcpParms.sockfd), &(pHconn->comParms),
                                           &(pHconn->tcpParms.lastError), &netBytesRead,
                                           &(pHconn->ipcCb.ipcBufferSz),
                                           &(pHconn->ipcCb.pIpcBuffer), 
                                           pHconn->tcpParms.sockWaitTime ) == 2 ) {
                   /* A recv error occurred */
                   pHconn->connState = MQISDP_DISCONNECTED;
                   netBytesRead = 0;
               }

               if ( netBytesRead > 0 ) {
                   mspReceiveScadaMessage( pHconn, netBytesRead, pHconn->ipcCb.pIpcBuffer );
                   /* If we are single threaded then we can stop waiting     */
                   /* only when a publication has been successfully received */
                   if ( pHconn->inQ.rtpEntries > 0 ) {
                       pHconn->tcpParms.sockWaitTime = 0;
                   }
               } else 
           #endif
               /* Do we need to poll the MQIsdp server?                                */
               if ( (pHconn->connState == MQISDP_CONNECTED) &&
                    (time( NULL ) >= pHconn->timeForNextPoll) ) {

                   /* Poll the server */
                   if ( mspSendPingRequest( pHconn ) == 1 ) {
                       /* Set the time for the next poll if the TCP/IP send failed */
                       /* to stop the broker becoming swamped with ping messages   */
                       pHconn->timeForNextPoll = time(NULL) + pHconn->keepAliveTime;
                   }
               }
           #ifdef MSP_SINGLE_THREAD
           }   /* while (netBytesRead > 0) */
           #endif
           /* #########################################################################*/
           /* End of handling TCP/IP input from the SCADA server                       */

           /* If the TCP/IP connection has broken then try to reconnect it.            */
           /* #########################################################################*/
           /* If we are in a state of not connected and                     */
           /* pHconn->timeForNextConnect is zero then we are on our first   */
           /* retry. Otherwise if current time > pHconn->timeForNextConnect */
           /* then we need to try another connect.                          */
           if ( (pHconn->connState != MQISDP_CONNECTED) &&
                ( (pHconn->reconnect.timeForNextConnect == 0) ||
                  (time(NULL) >= pHconn->reconnect.timeForNextConnect) ) ) {

               /* If connRetries < 0 then we are running under clean start     */
               /* so the application needs to explicitly reconnect and         */
               /* resubscribe                                                  */
               /* Check we can do the next retry: connRetries + 1 < retryCount */
               if ( ((pHconn->reconnect.connRetries + 1) <= pHconn->retryCount) &&
                    (pHconn->reconnect.connRetries >= 0) ) {

                   pHconn->reconnect.connRetries++;
                   mspMQIsdpReconnect( pHconn );

               } else {
                   /* The end of the road.... */
                   /* Attempts to establish a connection have expired. Tell the */
                   /* client application that it needs to reconnect.            */
                   pHconn->connState = MQISDP_CONNECTION_BROKEN;
               }
               pHconn->reconnect.timeForNextConnect = time(NULL) + pHconn->retryInterval;
           }
           /* #########################################################################*/
           /* End of TCP/IP reconnect processing.                                      */
  
           /* Check to see what data needs retrying                                    */
           /* #########################################################################*/
           if ( time(NULL) > pHconn->timeForNextRetry ) {
               curIpqEntry = pHconn->outQ.inProgressQ;
               while ( curIpqEntry != NULL ) {
                   nextIpqEntry = curIpqEntry->Next;
                   if ( curIpqEntry->msgStatus == MQISDP_RETRYING ) {
                       mspSendScadaMessage( pHconn, curIpqEntry->msgLength, curIpqEntry->msgData,
                                            curIpqEntry->msgId, 1, 0 );
                   } else {
                       /* If the msgStatus is not retrying then the entry is marked as being       */
                       /* available for retry if it is still on the InProgressQ next time around.  */
                       /* It is not retried now because it might have only just been sent.         */
                       curIpqEntry->msgStatus = MQISDP_RETRYING;
                   }

                   curIpqEntry = nextIpqEntry;
               }

               pHconn->timeForNextRetry = time(NULL) + pHconn->retryInterval;
           }
           /* #########################################################################*/
           /* End of checking to see what data needs retrying                          */

       } /* if (pHconn->ctrlFlags & MSP_CLIENT_APP_CONNECTED) */

   #ifndef MSP_SINGLE_THREAD
   } while ( mspEnding == 0 );
   #else
   /* If there is an application waiting to receive data then send a response */
   if ( strncmp( ec, RCV_S, MSP_EC_LENGTH ) == 0 ) {
       mspSendRcvPubResponse( pHconn, bytesRead, pHconn->ipcCb.pIpcBuffer );
   }

   /* If a client has disconnected then clean up */
   if ( !(pHconn->ctrlFlags & MSP_CLIENT_APP_CONNECTED) ) {
   #endif

   /* Remove the received publications hash table */
   mspTermHash( pHconn, pHconn->inQ.rpHash );

   /* Remove the In Progress Messages hash table */
   mspTermHash( pHconn, pHconn->outQ.ipHash );
      
   mspFree( &pHconn->comParms, pHconn->ipcCb.pIpcBuffer, pHconn->ipcCb.ipcBufferSz );

   /* Log the memory allocation. Add a correction of the size of the connection */
   /* handle because that was on the heap, but not counted because the          */
   /* structure was malloc'ed before stats were recorded.                       */
   mspLogMem( &(pHconn->comParms), "SEND", sizeof(HCONNCB) );

   mspFree( NULL, pHconn, sizeof(HCONNCB) );

   #ifdef MSP_SINGLE_THREAD
   } /* if ( !(ctrlFlags & MSP_CLIENT_APP_CONNECTED) ) { */
   #endif
   
   return 0;
}

/* The send thread uses this function to process the IPC data received. */
/* Data may come from the API (in mspclnt.c), or from the receive task  */
/* (in mspdmn.c).                                                       */
int mspReceiveIPCMessage( HCONNCB *pHconn, char *ec, MQISDPMH hMsg,
                          long bytesRead ) {
    long        mspsBufSize;
    void       *mspsMsg = NULL;
    int         rc = 0;
    
    switch ( ec[0] ) {
    case 'A':    /* Receive publication acknowledgement from the API */
        mspDeletePublication( pHconn, ec, hMsg );
        if ( pHconn->inQ.rtpEntries > 0 ) {
            /* If there are publications available to receive */
            /* then signal the receive semaphore.             */
            mspSignalSemaphore( pHconn->ipcCb.receiveSemaphore );
        }
        break;
    case 'C':    /* Connect message from the API */
        if ( pHconn->ctrlFlags & MSP_CLIENT_APP_CONNECTED ) {
            pHconn->apiReturnCode = MQISDP_ALREADY_CONNECTED;
        } else {
            pHconn->ctrlFlags |= MSP_CLIENT_APP_CONNECTED;
            pHconn->apiReturnCode = MQISDP_OK;
            
            mspsMsg = mspBuildScadaConnectMsg( pHconn, bytesRead,
                                               pHconn->ipcCb.pIpcBuffer, &mspsBufSize );

            if ( mspsMsg != NULL ) {
                if ( mspInitialiseHconn( pHconn, bytesRead, pHconn->ipcCb.pIpcBuffer ) == 0 ) {
                    mspTCPInitialise( pHconn );
                    mspSendScadaMessage( pHconn, mspsBufSize, mspsMsg, 0, 0, 0 );
                    MSP_SET_NEXT_MSGID( pHconn->nextMsgId );
                }
            } else {
                /* The connect has failed */
                pHconn->ctrlFlags &= MSP_CLIENT_APP_DISCONNECTED;
            }

            mspWriteIPC( pHconn->ipcCb.apiMailbox, &(pHconn->ipcCb), ec,
                         pHconn->apiReturnCode, 0, 0, NULL );
        }
        break;
    case 'D':     /* Disconnect message from the API */
        mspsMsg = mspBuildScadaDisconnectMsg( pHconn, bytesRead,
                                              pHconn->ipcCb.pIpcBuffer, &mspsBufSize );
        if ( mspsMsg != NULL ) {
            mspSendScadaMessage( pHconn, mspsBufSize, mspsMsg, 0, 0, 0 );
        }
        pHconn->ctrlFlags &= MSP_CLIENT_APP_DISCONNECTED;
        mspResetHconn( pHconn );
        mspWriteIPC( pHconn->ipcCb.apiMailbox, &(pHconn->ipcCb), ec, MQISDP_OK, 0, 0, NULL );
        break;
    case 'E': /* Receive publication decline from the API - The application buffer was not large */
              /* enough to receive the data. Signal the next waiter that a message is still available */
        if ( pHconn->inQ.rtpEntries > 0 ) {
            /* If there are publications available to receive */
            /* then signal the receive semaphore.             */
            mspSignalSemaphore( pHconn->ipcCb.receiveSemaphore );
        }
        mspWriteIPC( pHconn->ipcCb.apiMailbox, &(pHconn->ipcCb), RCV_B, MQISDP_OK, 0, 0, NULL );
        break;
    case 'P':      /* Publish message from the API     */
    case 'S':      /* Subscribe message from the API   */
    case 'U':      /* Unsubscribe message from the API */
        if ( pHconn->connState == MQISDP_CONNECTION_BROKEN ) {
            mspWriteIPC( pHconn->ipcCb.apiMailbox, &(pHconn->ipcCb), ec,
                         MQISDP_CONNECTION_BROKEN, 0, 0, NULL );
        } else {
            pHconn->apiReturnCode = MQISDP_OK;
            switch( ec[0] ) {
            case 'P':
                mspsMsg = mspBuildScadaPublishMsg( pHconn, bytesRead,
                                                   pHconn->ipcCb.pIpcBuffer, &mspsBufSize );
                break;
            case 'S':
                mspsMsg = mspBuildScadaSubscribeMsg( pHconn, bytesRead,
                                                     pHconn->ipcCb.pIpcBuffer, &mspsBufSize );
                break;
            case 'U':
                mspsMsg = mspBuildScadaUnsubscribeMsg( pHconn, bytesRead,
                                                       pHconn->ipcCb.pIpcBuffer, &mspsBufSize );
            }

            if ( mspsMsg != NULL ) {
                rc = mspSendScadaMessage( pHconn, mspsBufSize, mspsMsg, pHconn->nextMsgId, 0, 0 );
                /* 0 or 1 are ok as return codes, anything higher is an error */
                if ( rc > 1 ) {
                    pHconn->apiReturnCode = rc;
                }
            }

            mspWriteIPC( pHconn->ipcCb.apiMailbox, &(pHconn->ipcCb), ec,
                         pHconn->apiReturnCode, pHconn->nextMsgId, 0, NULL );
            
            MSP_SET_NEXT_MSGID( pHconn->nextMsgId );
        }
        break;
    case 'M':    /* Get message status from the API */
        mspSendGetStatusResponse( pHconn, hMsg );
        break;
    case 'R':    /* Receive a publication message from the API */
        #ifdef MSP_SINGLE_THREAD
        /* The requested time to wait is in the IPC buffer              */
        /* Wait for at most 50% of the keepalive time.                  */
        /* Keepalive time is in seconds - convert to milliseconds       */
        /* (*1000) and divide by 2, or just multiply by 500             */
        /* If there is already a publication available, then don't wait */
        if ( pHconn->inQ.rtpEntries > 0 ) {
            pHconn->tcpParms.sockWaitTime = 0;
        } else {
            int waitTime;
            memcpy( &waitTime, pHconn->ipcCb.pIpcBuffer, sizeof(int) );
            pHconn->tcpParms.sockWaitTime = MIN( (int)(pHconn->keepAliveTime*500), waitTime );
        }
        #else
        mspSendRcvPubResponse( pHconn, bytesRead, pHconn->ipcCb.pIpcBuffer );
        #endif
        break;
    case 'T':    /* Get the connection status message from the API */
        mspSendConnStatusResponse( pHconn, bytesRead, pHconn->ipcCb.pIpcBuffer );
        break;
    #ifndef MSP_SINGLE_THREAD
    case 'K':    /* Receive data from the receive task and send an IPC response */
        /* For a single task solution the TCP/IP socket is polled for input */
        /* further down this function                                       */
        mspReceiveScadaMessage( pHconn, bytesRead, pHconn->ipcCb.pIpcBuffer );
        mspWriteIPC( pHconn->ipcCb.receiveMailbox, &(pHconn->ipcCb), RTSK_R, MQISDP_OK, 0, 0, NULL );
        break;
    #endif
    default:
        mspLog( LOGERROR, &(pHconn->comParms), "Unrecognised IPC eye catcher:%.2s\n", ec ); 
        break;
    }

    return 0;
}
/* mspGetDataFromNetwork: Returns 0 if data was received   */
/* Returns 2 on error, 1 if no data available, otherwise 0 */
int mspGetDataFromNetwork( int *pSockfd, MSPCMN *pComParms, int *pLastError, 
                           long *pBytesRead, long *rBufSize, char **rBuffer,
                           long msTimeout ) {
    int rc = 1;

    *pBytesRead = 0;

    /* Poll the socket to check for input data */
    if ( msp_select( *pSockfd, msTimeout ) > 0 ) {
        if ( mspTCPReadMsg( *pSockfd, pComParms, pLastError, pBytesRead,
                            rBufSize, rBuffer) < 0 ) {
            mspTCPDisconnect( pSockfd );
            rc = 2;
        } else {
            rc = 0;
        }
    }

    return rc;
}

/* Initialise the connection handle when a new connection is created */
int mspInitialiseHconn( HCONNCB *pHconn, long ipcBytesRead, void *ipcrBuffer ) {
    CONN_PARMS  *pMspCp;      /* User input connection parameters */
    int          rc = 0;      /* The function return code         */    
    int          i = 0;       /* Loop counter used when loading messages from the persistence */
    char        *pResAddr;    /* DNS resolved IP address                           */
    int          numMsgs;     /* Number of messages retrieved from the persistence */
    MQISDP_PMSG *pPersistMsgs;/* Pointer to messages returned from the persistence */        
    u_short      wmqttMsgId;  /* WMQTT message identifier                          */
    RPQ         *pRcvdEntry;  /* Received queue entry                              */

    pMspCp = (CONN_PARMS*)ipcrBuffer;
    
    /* Set up parameters for keeping the connection alive */
    pHconn->keepAliveTime = pMspCp->keepAliveTime;
    pHconn->timeForNextPoll = time(NULL) + pHconn->keepAliveTime;
    pHconn->retryCount = pMspCp->retryCount;
    pHconn->retryInterval = pMspCp->retryInterval;
    pHconn->timeForNextRetry = time(NULL) + pHconn->retryInterval;

    /* Set a time limit for the connect to complete */
    pHconn->reconnect.timeForNextConnect = time(NULL) + pHconn->retryInterval;

    /* Set the persistence interface as requested by the connecting application */
    pHconn->persistFuncs = pMspCp->pPersistFuncs;
    
    /* We haven't completed the MQIsdp connect yet */
    pHconn->connState = MQISDP_CONNECTING;
    
    pResAddr = mspTCPGetHostByName( pHconn, pMspCp->brokerHostname );
    if ( pResAddr != NULL ) {
        mspLog( LOGTCPIP, &(pHconn->comParms), "DNS resolved %s -> %s\n", pMspCp->brokerHostname, pResAddr );
        memcpy( pHconn->tcpParms.brokerAddress, pResAddr, MQISDP_INET_ADDR_LENGTH );
        pHconn->tcpParms.brokerPort = (u_short)pMspCp->brokerPort;

        /* Now initialise the persistence */
        if ( pHconn->persistFuncs != NULL ) {
            rc = pHconn->persistFuncs->open( pHconn->persistFuncs->pUserData, pMspCp->clientId,
                                             pHconn->tcpParms.brokerAddress,
                                             pHconn->tcpParms.brokerPort );
            if ( rc == 0 ) {
                if ( pHconn->ctrlFlags & MSP_CLEAN_SESSION ) {
                    /* Using clean session, so reset the state of the persistence */
                    rc = pHconn->persistFuncs->reset( pHconn->persistFuncs->pUserData );
                } else {
                    /* Not using clean session, so load in the previous state from the persistence */
                    if ( rc == 0 ) {
                        rc = pHconn->persistFuncs->getAllSentMessages( pHconn->persistFuncs->pUserData,
                                                                       &numMsgs, &pPersistMsgs );
                        if ( (rc == 0) && (numMsgs > 0) ) {
                            /* There is no TCP/IP connection at this stage, so mspSendScadaMessage   */
                            /* will simply queue the data up in memory, initialising the memory      */
                            /* state back to what it was prior to the application last disconnecting */
                            /* The initFlag is set to stop the data being written back to the        */
                            /* persistence.                                                          */
                            for ( i=0; i < numMsgs; i++ ) {
                                if ( pPersistMsgs[i].key > pHconn->nextMsgId ) {
                                    /* Conversion from u_long to u_short is ok as a key greater */
                                    /* than can be accomodated by u_short is never used.        */
                                    pHconn->nextMsgId = (u_short)pPersistMsgs[i].key;
                                }
                                mspSendScadaMessage( pHconn,
                                                     pPersistMsgs[i].length,
                                                     pPersistMsgs[i].pWmqttMsg,
                                                     (short)pPersistMsgs[i].key, 0, 1 );
                            }
                        }
                    }
                    if ( rc == 0 ) {
                        rc = pHconn->persistFuncs->getAllReceivedMessages( pHconn->persistFuncs->pUserData,
                                                                           &numMsgs, &pPersistMsgs );
                        if ( (rc == 0) && (numMsgs > 0) ) {
                            /* The messages were stored in the MQIsdp wire format, so the */
                            /* mspStorePublication function can be used to reload memory  */
                            /* as though the messages had just been received from TCP/IP. */
                            for ( i=0; i < numMsgs; i++ ) {
                                if ( pPersistMsgs[i].key > pHconn->nextRcvId ) {
                                    pHconn->nextRcvId = pPersistMsgs[i].key;
                                }
                                pRcvdEntry =  mspStorePublication( pHconn,
                                                                   pPersistMsgs[i].length,
                                                                   pPersistMsgs[i].pWmqttMsg,
                                                                   &wmqttMsgId );
                                if ( pRcvdEntry != NULL ) {
                                    pRcvdEntry->rcvId = pPersistMsgs[i].key;
                                } else {
                                    rc = 1;
                                }
                               
                            }
                        }
                    }
                }
            }
            if ( rc != 0 ) {
                pHconn->apiReturnCode = MQISDP_PERSISTENCE_FAILED;
            }
        }

    } else {
        pHconn->apiReturnCode = MQISDP_HOSTNAME_NOT_FOUND;
        rc = 1;
    }
    
    return rc;
}

/* A funtion to return the status of a message to the API */
int mspSendGetStatusResponse( HCONNCB *pHconn, MQISDPMH hMsg ) {
    int         rc = MQISDP_IN_PROGRESS;   
    MHASHENTRY *pHashEntry;

    if ( (hMsg > 0) && (hMsg <= MQISDP_MAX_MSGS) ) {
        pHashEntry = mspGetHashEntry( pHconn->outQ.ipHash, (short)hMsg );
        /* Get the hash table entry for this message id.                        */
        /* If the Hash entry is NULL then the message was delivered.            */
        /* If it is not NULL then the message is any data waiting to be sent */
        if ( pHashEntry == NULL ) {
            rc = MQISDP_DELIVERED;
        } else {
            rc = ((IPQ*)pHashEntry->dataPtr)->msgStatus;
        }
    } else {
        rc = MQISDP_MSG_HANDLE_ERROR;
    }

    mspWriteIPC( pHconn->ipcCb.apiMailbox, &(pHconn->ipcCb), MSG_R, rc, hMsg, 0, NULL );

    return 0;
}

/* Send the connection status back to the API */
/* Buffer written to IPC holds:               */
/* errorCode (long)                           */
/* error string length (long)                 */
/* error string  MQISDP_ERROR_STRING_LENGTH   */
int mspSendConnStatusResponse( HCONNCB *pHconn, long bytesRead, char *pReadBuffer ) {
    char    *pData;
    char    *pErrStr = NULL;
    long     dataLength;
    long     lastError;

    pData = pHconn->ipcCb.pIpcBuffer;
    dataLength = sizeof(long);

    /* Copy an error code */
    if ( pHconn->tcpParms.sockfd == MSP_INVALID_SOCKET ) {
        lastError = pHconn->tcpParms.lastError & MSP_GET_LAST_ERROR;
        memcpy( pData, &lastError, sizeof(long) );
    } else {
        memset( pData, 0, sizeof(long) );
    }
    pData += sizeof(long);
    
    /* Insert a NULL after the error code field to initialise the error string field */
    pErrStr = pData;
    *pErrStr = '\0';

    /* Copy any relevant info string data */
    switch ( pHconn->tcpParms.lastError & MSP_GET_ERROR_TYPE ) {
    case 0:
        sprintf( pData, MSP_TCP_CONN_SUC_STR, pHconn->tcpParms.brokerAddress,
                 (long)pHconn->tcpParms.brokerPort );
    break;
    case MSP_CONN_ERROR:
        switch ( pHconn->tcpParms.lastError & MSP_GET_LAST_ERROR ) {
        case MQISDP_SOCKET_CLOSED:
            strcpy( pData, MSP_SOCK_CLOSED_ERR_STR );
        break;
        case MQISDP_PROTOCOL_VERSION_ERROR:
            strcpy( pData, MSP_MQISDP_VERS_ERR_STR );
        break;
        case MQISDP_CLIENT_ID_ERROR:
            strcpy( pData, MSP_MQISDP_CLID_ERR_STR );
        break;
        case MQISDP_BROKER_UNAVAILABLE:
            strcpy( pData, MSP_MQISDP_CREF_ERR_STR );
        break;
        case MQISDP_HOSTNAME_NOT_FOUND:
            strcpy( pData, MSP_MQISDP_HOST_ERR_STR );
        break;
        default:
        break;
        }
    break;  
    case MSP_TCP_SEND_ERROR:
      sprintf( pData, MSP_TCP_SEND_ERR_STR, (long)(pHconn->tcpParms.lastError & MSP_GET_LAST_ERROR) );
    break;
    case MSP_TCP_RECV_ERROR:
        sprintf( pData, MSP_TCP_RECV_ERR_STR, (long)(pHconn->tcpParms.lastError & MSP_GET_LAST_ERROR) );
    break;
    case MSP_TCP_CONN_ERROR:
        sprintf( pData, MSP_TCP_CONN_ERR_STR, (long)(pHconn->tcpParms.lastError & MSP_GET_LAST_ERROR) );
    break;
    case MSP_TCP_SOCK_ERROR:
        sprintf( pData, MSP_TCP_SOCK_ERR_STR, (long)(pHconn->tcpParms.lastError & MSP_GET_LAST_ERROR) );
    break;
    case MSP_TCP_HOST_ERROR:
        strcpy( pData, MSP_MQISDP_HOST_ERR_STR );
    break;
    default:
    break;
    }

    /* Add the length of the string pErrStr. If no error data was available         */
    /* then pErrStr will be pointing at its initial value of \0 - a 0 length string */
    dataLength += strlen( pErrStr ) + 1;

    mspWriteIPC( pHconn->ipcCb.apiMailbox, &(pHconn->ipcCb), STAT_R,
                 pHconn->connState, 0, dataLength, pHconn->ipcCb.pIpcBuffer );

    return 0;
}

/* Buffer written to IPC holds:             */
/* msgId (short)                            */
/* options (long)                           */
/* topic length (long)                      */
/* buffer length (long)                     */
/* data buffer                              */
/* This function does not delete a publication when it is sent to the client  */
/* The publication is only deleted upon receipt of a positive acknowledgement */
/* from the client library.                                                   */
int mspSendRcvPubResponse( HCONNCB *pHconn, long bytesRead, char *pReadBuffer ) {
    long     respDataLength = 0;
    char    *pData = NULL;
    RPQ     *pRcvdPub;
    int      rc;


    /* Find the next available publication, if any */
    pRcvdPub = pHconn->inQ.rcvdPubsQ;
    while ( (pRcvdPub != NULL) && (pRcvdPub->readyToPublish == 0) ) {
        pRcvdPub = pRcvdPub->Next;
    }

    if ( pRcvdPub != NULL ) {
        respDataLength = (4*sizeof(long)) + sizeof(char*);
    }

    if ( respDataLength > pHconn->ipcCb.ipcBufferSz ) {
        pHconn->ipcCb.pIpcBuffer = mspRealloc( &(pHconn->comParms), pHconn->ipcCb.pIpcBuffer,
                                               respDataLength, pHconn->ipcCb.ipcBufferSz );
        pHconn->ipcCb.ipcBufferSz = respDataLength;
    }

    if ( pHconn->ipcCb.pIpcBuffer == NULL ) {
        pHconn->ipcCb.ipcBufferSz = 0;
        rc = MQISDP_OUT_OF_MEMORY;
    } else if ( pRcvdPub == NULL ) {
        /* When there are no more publications to receive then  */
        /* we need to return one of two possible return codes   */
        /* MQISDP_NO_PUBS_AVAILABLE or MQISDP_CONNECTION_BROKEN */
        if ( pHconn->connState == MQISDP_CONNECTION_BROKEN ) {
            rc = pHconn->connState;
        } else {
            rc = MQISDP_NO_PUBS_AVAILABLE;
        }
        #ifdef MSP_SINGLE_THREAD
        /* Return how long we actually waited for */
        respDataLength = sizeof(long);
        pData = (char*)(&pHconn->tcpParms.sockWaitTime);
        #endif
    } else {
        pData = pHconn->ipcCb.pIpcBuffer;

        /* Copy in the message id */
        memcpy( pData, &pRcvdPub->rcvId, sizeof(u_long) );
        pData += sizeof(u_long);

        /* copy the options */
        memcpy( pData, &pRcvdPub->options, sizeof(long) );
        pData += sizeof(long);

        /* copy the topic length */
        memcpy( pData, &pRcvdPub->topicLength, sizeof(long) );
        pData += sizeof(long);

        /* copy the buffer length */
        memcpy( pData, &pRcvdPub->bufferLength, sizeof(long) );
        pData += sizeof(long);

        /* Copy the buffer pointer */
        memcpy( pData, &(pRcvdPub->buffer), sizeof(char*) );

        /* Indicate if there are more publications or not (pHconn->inQ.rtpEntries) */
        rc = (pHconn->inQ.rtpEntries > 1)?MQISDP_PUBS_AVAILABLE:MQISDP_OK;

        /* respData Length was set above */
        pData = pHconn->ipcCb.pIpcBuffer;
    }

    mspWriteIPC( pHconn->ipcCb.apiMailbox, &(pHconn->ipcCb), RCV_R, rc, 0, respDataLength, pData );
    
    return 0;
}

/* When the API successfully passes a message back to the client application, this */
/* function removes the publication from the queue of data to be received.         */
int mspDeletePublication( HCONNCB *pHconn, char *ec, MQISDPMH hMsg ) {
    RPQ     *pRcvdPub;
    long     rc = MQISDP_OK;

    /* Find the next available publication, if any */
    pRcvdPub = pHconn->inQ.rcvdPubsQ;
    while ( (pRcvdPub != NULL) && (pRcvdPub->rcvId != hMsg) ) {
        pRcvdPub = pRcvdPub->Next;
    }

    if ( pRcvdPub != NULL ) {
        /* If the application received a QoS 1 or 2 publication and persistence is being used */
        /* then delete the message from the persistence.                                      */
        if ( !(pRcvdPub->options & MQISDP_QOS_0) && (pHconn->persistFuncs != NULL) ) {
            /* Delete the received publication from the persistence store (QoS > 0 only) */
            pHconn->persistFuncs->delReceivedMessage( pHconn->persistFuncs->pUserData, pRcvdPub->rcvId );
        }

        /* And from the in memory queue */
        mspDeleteRPMFromList( pHconn, pRcvdPub );
    } else {
        mspLog( LOGERROR, &(pHconn->comParms), "mspDeletePublication:Cannot find publication, msgId:%ld\n", (u_short)hMsg );
        rc = MQISDP_FAILED;
    }

    mspWriteIPC( pHconn->ipcCb.apiMailbox, &(pHconn->ipcCb), RCV_B, rc, hMsg, 0, NULL );

    return 0;
}

/* Initialise the receive task by sending it the socket to listen on */
/* Write the socket to the receive mail box                          */
int mspInitReceiveTask( HCONNCB *pHconn ) {

    #ifndef MSP_SINGLE_THREAD
    /* The socket descriptor is inserted in the rc field of the IPC header    */
    /* By sending the socket descriptor in the IPC header the send task does  */
    /* have to worry about allocating an additional buffer and waiting for a  */
    /* response indicating that the buffer has been read.                     */
    mspWriteIPC( pHconn->ipcCb.receiveMailbox, &(pHconn->ipcCb), RCON_S,
                 pHconn->tcpParms.sockfd, 0, 0, NULL );
    #endif
    return 0;
}

/* This function resets the connection handle after a disconnect */
/* ready to receive the next connect                             */
/* This entails freeing up connection specific storage and       */
/* reseting some values                                          */
int mspResetHconn( HCONNCB *pHconn ) {
    IPQ  *curIpqEntry;
    RPQ  *curRpqEntry;
    
    /* Disconnect from TCP/IP */
    mspTCPDisconnect( &(pHconn->tcpParms.sockfd) );
    
    /* Scrub the memory state, but don't scrub the state in the persistence store unless */
    /* clean session is being used with the MQIsdp protocol.                              */
    if ( pHconn->persistFuncs != NULL ) {
        if ( pHconn->ctrlFlags & MSP_CLEAN_SESSION ) {
            pHconn->persistFuncs->reset( pHconn->persistFuncs->pUserData );
        }
        pHconn->persistFuncs->close( pHconn->persistFuncs->pUserData );
    }


    /* Delete any messages on the output (in progress) queue */
    mspLog( LOGNORMAL, &(pHconn->comParms), "Number of bytes queued for sending:%ld\n", pHconn->outQ.numBytesQueued );
    curIpqEntry = pHconn->outQ.inProgressQ;
    if ( curIpqEntry != NULL ) {
        while( curIpqEntry->Next != NULL ) {
            curIpqEntry = curIpqEntry->Next;
            mspDelFromHash( pHconn, pHconn->outQ.ipHash, curIpqEntry->Prev->msgId );
            mspDeleteIPMFromList( pHconn, curIpqEntry->Prev );
        }
        mspDelFromHash( pHconn, pHconn->outQ.ipHash, curIpqEntry->msgId );
        mspDeleteIPMFromList( pHconn, curIpqEntry );
        mspLog( LOGNORMAL, &(pHconn->comParms), "Number of bytes queued for sending:%ld\n", pHconn->outQ.numBytesQueued );
    }
    pHconn->outQ.inProgressQ = NULL;
    pHconn->outQ.ipEntries = 0;
    pHconn->outQ.numBytesQueued = 0;
    pHconn->outQ.pLastEntry = NULL;

    /* Delete any messages on the input (received publications) queue */
    mspLog( LOGNORMAL, &(pHconn->comParms), "Number of bytes queued for receiving:%ld\n", pHconn->inQ.numBytesQueued );
    curRpqEntry = pHconn->inQ.rcvdPubsQ;
    if ( curRpqEntry != NULL ) {
        while( curRpqEntry->Next != NULL ) {
            curRpqEntry = curRpqEntry->Next;
            mspDeleteRPMFromList( pHconn, curRpqEntry->Prev );
        }
        mspDeleteRPMFromList( pHconn, curRpqEntry );
        mspLog( LOGNORMAL, &(pHconn->comParms), "Number of bytes queued for receiving:%ld\n", pHconn->inQ.numBytesQueued );
    }
    pHconn->inQ.rcvdPubsQ = NULL;
    pHconn->inQ.rtpEntries = 0;
    pHconn->inQ.numBytesQueued = 0;
    pHconn->inQ.pLastEntry = NULL;

    /* Remove the saved connect message for the previous connection */
    if ( pHconn->reconnect.connectMsg != NULL ) {
        mspFree( &(pHconn->comParms), pHconn->reconnect.connectMsg, pHconn->reconnect.connMsgSz );
        pHconn->reconnect.connectMsg = NULL;
    }
    pHconn->reconnect.connMsgSz = 0;
    pHconn->reconnect.connRetries = 0;
    pHconn->reconnect.timeForNextConnect = 0;

    /* Delete all TCP/IP connection information */
    pHconn->tcpParms.lastError = 0;
    pHconn->tcpParms.msperrno = 0;
    pHconn->tcpParms.sockfd = MSP_INVALID_SOCKET;

    pHconn->nextMsgId = 0;
    pHconn->nextRcvId = 0;
    
    return 0;
}



