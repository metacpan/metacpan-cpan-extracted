/****************************************************************************/
/*                                                                          */
/* Program name: MQIsdp protocol C Language implementation                  */
/*                                                                          */
/* Description: This source file contains functions for building, parsing,  */
/* sending and receiving MQIsdp messgaes.                                   */
/*                                                                          */
/*  Statement:  Licensed Materials - Property of IBM                        */
/*                                                                          */
/*              MQSeries SupportPac IA93                                    */
/*              (C) Copyright IBM Corp. 2002                                */
/*                                                                          */
/****************************************************************************/
/* Version @(#) IA93/ship/mspscada.c, SupportPacs, S000 1.4 03/11/28 16:43:48  */
/*                                                                          */
/* Function:                                                                */
/*                                                                          */
/* The send functions in this source file talk through to the TCP/IP layer  */
/* and queues the data if required. Functions also exist to retry sending   */
/* data and that retry connecting in the event of a connection being broken.*/
/*                                                                          */
/****************************************************************************/
/*                                                                          */
/* Change history:                                                          */
/*                                                                          */
/* V1.0   19-02-2003  IRH  Initial release                                  */
/* V1.2   21-10-2003  IRH  Split a line of code in function                 */
/*                         mspStorePublication into two lines because it was*/
/*                         not understood by all compilers.                  */
/*                                                                          */
/*==========================================================================*/
/* Module Name: mspscada.c                                                  */
#include <mspdmn.h>
#include <mspscada.h>

/* mspBuildScadaConnectMsg */
/* Validate the data passed into the API and build a connect message */
/* Returns NULL on error and sets pHconn->apiReturnCode              */
void* mspBuildScadaConnectMsg( HCONNCB *pHconn, long bufLength,
                               void *ipcBuffer, long *msgLength ){
    long        fHLength = 0;   /* Fixed Header: Depends upon data length */
    long        wtLength = 0;   /* Will topic length   */
    long        wtLengthUt = 0; /* Will topic length untrimmed */
    long        wmLength = 0;   /* Will message length */
    long        rLength = 12;   /* remaining length. Var Header: 12 bytes long for a connect*/
    long        ciLength = 0;   /* Client ID length */
    char       *tmpPtr;
    CONN_PARMS *pMspCp;
    long        totalLength = 0;
    char       *connectMsg = NULL;
    char       *pWillMsg = NULL;
    char       *pWillTopic = NULL;
    size_t      cleanStartOffset = 0;
    u_short     keepAlive;

    pHconn->apiReturnCode = MQISDP_OK;
    pMspCp = (CONN_PARMS*)ipcBuffer;
    *msgLength = 0;

    /* Add 2 to the length of the clientId to allow for UTF encoding */
    ciLength = strlen( pMspCp->clientId );
    rLength += ciLength + 2;

    /* See if a will message is to be sent */
    if ( pMspCp->options & MQISDP_WILL ) {

        /* Step to the Will Topic Length */
        tmpPtr = (char*)pMspCp + sizeof(CONN_PARMS);

        /* If a topic > 0 length exists add it to the message, otherwise        */
        /* return an error. Add 2 to the topic length to allow for UTF encoding */
        memcpy( &wtLengthUt, tmpPtr, sizeof(long) );
        if ( wtLengthUt > 0 ) {
            pWillTopic = tmpPtr + sizeof(long);
            /* Trim any white space off the end of the topic and set the trimmed length accordingly */
            wtLength = mspCharTrim( ' ', wtLengthUt, pWillTopic );
            rLength += wtLength + 2;
        } else {
            pHconn->apiReturnCode = MQISDP_NO_WILL_TOPIC;
            return NULL;
        }

        /* Step over the Will Topic Length and Will Topic to the Will Message Length */
        tmpPtr += wtLengthUt + sizeof(long);
        
        /* If a will message > 0 length exists- compare long, so cast long* */
        /* Add 2 to the message length to allow for UTF encoding            */
        memcpy( &wmLength, tmpPtr, sizeof(long) );
        if ( wmLength > 0 ) {
            pWillMsg = tmpPtr + sizeof(long);
            /* Trim any white space off the end of the message and set the new length accordingly */
            wmLength = mspCharTrim( ' ', wmLength, pWillMsg );
            rLength += wmLength + 2;
        }
    }

    /* Calculate the fixed header size required to hold the remaining length */
    MSP_CALC_FHEADER_LENGTH( rLength, fHLength );

    totalLength = fHLength + rLength;

    if ( fHLength == -1 ) {
        /* Data is bigger than MQIsdp can handle */
        pHconn->apiReturnCode = MQISDP_DATA_TOO_BIG;
    }
    
    if ( pHconn->apiReturnCode == MQISDP_OK ) {
        /* Now build up the connect message */
        connectMsg = (char*)mspMalloc( &(pHconn->comParms), (size_t)totalLength );
        if ( connectMsg == NULL ) {
            pHconn->apiReturnCode = MQISDP_OUT_OF_MEMORY;
            return NULL;
        }
        tmpPtr = connectMsg;

        /* Insert the message type */
        *tmpPtr = 0x00 | MSP_CONNECT;
        tmpPtr++;

        /* Encode the message length */
        mspEncodeFHeaderLength( rLength, tmpPtr );
        tmpPtr =  connectMsg + fHLength;

        /* Variable header */
        /* Add the protocol name */
        mspUTFEncodeString( MSP_PROTOCOL_NAME_SZ, MSP_PROTOCOL_NAME, tmpPtr );
        tmpPtr += MSP_PROTOCOL_NAME_SZ + 2;

        /* Add the protocol version */
        *tmpPtr = MSP_PROTOCOL_VERSION_3;
        tmpPtr++;

        /* Set up the connect options */
        cleanStartOffset = tmpPtr - connectMsg;
        *tmpPtr = 0x00;
        if ( pMspCp->options & MQISDP_WILL ) {
            *tmpPtr |= MSPC_WILL;
        }
        if ( pMspCp->options & MQISDP_WILL_RETAIN ) {
            *tmpPtr |= MSPC_WILL_RETAIN;
        }
        if ( pMspCp->options & MQISDP_CLEAN_START ) {
            pHconn->ctrlFlags |= MSP_CLEAN_SESSION;
            *tmpPtr |= MSPC_CLEAN_START;
            /* If we are using clean start then the protocol library        */
            /* should not attempt to reconnect on behalf of the application */
            /* because the protocol library does not know what subscriptions*/
            /* to register on behalf of the application.                    */
            pHconn->reconnect.connRetries = -1;
        } else {
            /* Switch off the clean session control flag */
            pHconn->ctrlFlags &= MSP_CLEAN_SESSION_OFF;
        }
        /* QoS 0 is the default, so only handle QoS 1 and 2 */
        if ( pMspCp->options & MQISDP_QOS_2 ) {
            *tmpPtr |= MSPC_QOS_2;
        } else if ( pMspCp->options & MQISDP_QOS_1 ) {
            *tmpPtr |= MSPC_QOS_1;
        }
        tmpPtr ++;

        /* Now add the KeepAliveTimer */
        keepAlive = htons( (u_short)pMspCp->keepAliveTime );
        memcpy( tmpPtr, &keepAlive, sizeof(u_short) );
        tmpPtr += sizeof(u_short);

        /* Payload */
        /* First the ClientID */
        mspUTFEncodeString( (u_short)ciLength, pMspCp->clientId, tmpPtr );
        tmpPtr += ciLength + 2;

        /* Next the will topic and message, if required */
        if ( pMspCp->options & MQISDP_WILL ) {
            if ( wtLength > 0 ) {
                /* Add the will topic */
                mspUTFEncodeString( (u_short)wtLength, pWillTopic, tmpPtr );
                tmpPtr += wtLength + 2;
            }
            if ( wmLength > 0 ) {
                /* Add the will message */
                mspUTFEncodeString( (u_short)wmLength, pWillMsg, tmpPtr );
                tmpPtr += wmLength + 2;
            }
        }

        /* Take a copy of the MQIsdp connect message incase a reconnect is required */
        /* Turn clean start off for a reconnect message                             */
        pHconn->reconnect.connMsgSz = totalLength;
        pHconn->reconnect.connectMsg = (char*)mspMalloc( &(pHconn->comParms), totalLength );
        if ( pHconn->reconnect.connectMsg == NULL ) {
            mspFree( &(pHconn->comParms), connectMsg, totalLength );
            pHconn->apiReturnCode = MQISDP_OUT_OF_MEMORY;
            return NULL;
        }
        memcpy( pHconn->reconnect.connectMsg, connectMsg, totalLength );
        *(pHconn->reconnect.connectMsg + cleanStartOffset) &= MSPC_CLEAN_START_OFF;
    
        mspLog( LOGSCADA, &(pHconn->comParms), "CONNECT\n" );

        *msgLength = totalLength;
    }

    return connectMsg;
}

/* mspBuildScadaDisconnectMsg */
/* Validate the data passed into the API and build a disconnect message */
/* Returns NULL on error and sets pHconn->apiReturnCode                 */
void* mspBuildScadaDisconnectMsg( HCONNCB *pHconn, long bufLength,
                                  void *ipcBuffer, long *msgLength ){
    long  totalLength = 2;
    char *discMsg = NULL;

    pHconn->apiReturnCode = MQISDP_OK;
    *msgLength = 0;

    /* Now build up the disconnect message */
    discMsg = (char*)mspMalloc( &(pHconn->comParms), (size_t)totalLength );

    if ( discMsg != NULL) {
        /* Insert the message type */
        *discMsg = 0x00 | (char)MSP_DISCONNECT;
        *(discMsg+1) = 0x00;

        mspLog( LOGSCADA, &(pHconn->comParms), "DISCONNECT\n" );

        *msgLength = totalLength;
    } else {
        pHconn->apiReturnCode = MQISDP_OUT_OF_MEMORY;
    }

    return discMsg;
}

/* mspBuildScadaSubscribeMsg */
/* Validate the data passed into the API and build a subscribe message */
/* Returns NULL on error and sets pHconn->apiReturnCode                */
void* mspBuildScadaSubscribeMsg( HCONNCB *pHconn, long bufLength,
                                 void *ipcBuffer, long *msgLength ){
    long        fHLength = 0;  /* Fixed Header: Depends upon data length */
    long        rLength  = 2;  /* remaining length. Var Header: 2 bytes long for a subscribe*/
    long        tLength;       /* Topic length */
    long        tLengthUt;     /* Topic length untrimmed */
    SUB_PARMS  *pMspSp;
    char       *endPtr;
    char       *tmpPtr;
    char       *topicPtr;
    char       *subMsg = NULL;
    long        totalLength = 0;
    long        topicQoS;
    u_short     msgId;

    pHconn->apiReturnCode = MQISDP_OK;
    pMspSp = (SUB_PARMS*)ipcBuffer;
    endPtr = (char*)pMspSp + pMspSp->strucLength;
    *msgLength = 0;

    tmpPtr = (char*)pMspSp + sizeof(SUB_PARMS);

    while ( tmpPtr < endPtr ) {
        /* Get the topic length and check we are in bounds */
        if ( tmpPtr <= (endPtr - sizeof(long)) ) {
            memcpy( &tLengthUt, tmpPtr, sizeof(long) );
            tLength = mspCharTrim( ' ', tLengthUt, tmpPtr + sizeof(long) );
            /* Add the topic length + 2 for UTF encoding + 1 for the QoS */
            rLength += tLength + 3;
        } else {
            pHconn->apiReturnCode = MQISDP_INVALID_STRUC_LENGTH;
            break;
        }
    
        /* Step over the topic name length, topic name and QoS - check we are in bounds */
        tmpPtr += sizeof(long) + tLengthUt + sizeof(long);
        if ( tmpPtr > endPtr ) {
            pHconn->apiReturnCode = MQISDP_INVALID_STRUC_LENGTH;
            break;
        }
    }

    /* Calculate the fixed header size required to hold the remaining length */
    MSP_CALC_FHEADER_LENGTH( rLength, fHLength );

    totalLength = fHLength + rLength;

    /* Check we have enough room to hold this data */
    if ( pHconn->outQ.numBytesQueued + totalLength + sizeof(IPQ) > MSP_DEFAULT_MAX_OUTQ_SZ ) {
        pHconn->apiReturnCode = MQISDP_Q_FULL;
    }
    
    if ( fHLength == -1 ) {
        /* Data is bigger than MQIsdp can handle */
        pHconn->apiReturnCode = MQISDP_DATA_TOO_BIG;
    }
    
    if ( pHconn->apiReturnCode == MQISDP_OK ) {

        /* Now build up the subscribe message */
        subMsg = (char*)mspMalloc( &(pHconn->comParms), (size_t)totalLength );
        if ( subMsg == NULL ) {
            pHconn->apiReturnCode = MQISDP_OUT_OF_MEMORY;
            return NULL;
        }
        tmpPtr = subMsg;
    
        /* Insert the message type and QoS (always QoS 1) */
        *tmpPtr = 0x00 | (char)MSP_SUBSCRIBE | (char)MSPF_QOS_1 ;
        tmpPtr++;

        /* Encode the message length */
        mspEncodeFHeaderLength( rLength, tmpPtr );
        tmpPtr =  subMsg + fHLength;
    
        /* Variable header */
        /* Now add the message ID in network byte order (big-endian) */
        msgId = htons( pHconn->nextMsgId );
        memcpy( tmpPtr, &msgId, sizeof(u_short) );
        tmpPtr += sizeof(u_short);

        /* Payload */
        /* Add topics and QoS */
        /* topicPtr points at the SUB_PARMS structure */
        /* tmpPtr points at the MQIsdp message        */
        topicPtr = (char*)pMspSp + sizeof(SUB_PARMS);

        while ( topicPtr < endPtr ) {
            /* Get the topic length supplied in SUB_PARMS */
            memcpy( &tLengthUt, topicPtr, sizeof(long) );

            /* Get the length once spaces have been trimmed */
            tLength = mspCharTrim( ' ', tLengthUt, topicPtr + sizeof(long) );
            topicPtr += sizeof(long);
            mspUTFEncodeString( (u_short)tLength, topicPtr, tmpPtr );

            /* Move the pointer in the MQIsdp message and the SUB_PARMS structure */
            tmpPtr += tLength + 2;
            topicPtr += tLengthUt;

            /* Add the QoS to the message */
            memcpy( &topicQoS, topicPtr, sizeof(long) );
            if ( topicQoS & MQISDP_QOS_2 ) {
                *tmpPtr = MSPS_QOS_2;
            } else if ( topicQoS & MQISDP_QOS_1 ) {
                *tmpPtr = MSPS_QOS_1;
            } else {
                *tmpPtr = MSPS_QOS_0;
            }

            mspLog( LOGSCADA, &(pHconn->comParms), "SUBSCRIBE,topic:<%.*s>,QoS:%d\n",
                    tLength, topicPtr - tLengthUt, *tmpPtr );

            tmpPtr++;
            topicPtr += sizeof(long);
        }

        *msgLength = totalLength;
    }

    return subMsg;
}

/* mspBuildScadaUnsubscribeMsg */
/* Validate the data passed into the API and build a unsubscribe message */
/* Returns NULL on error and sets pHconn->apiReturnCode                  */
void* mspBuildScadaUnsubscribeMsg( HCONNCB *pHconn, long bufLength,
                                   void *ipcBuffer, long *msgLength ){
    long         fHLength = 0;  /* Fixed Header: Depends upon data length */
    long         rLength  = 2;  /* remaining length. Var Header: 2 bytes long for a subscribe*/
    long         tLength;       /* Topic length */
    long         tLengthUt;     /* Topic length untrimmed */
    UNSUB_PARMS *pMspUp;
    char        *endPtr;
    char        *tmpPtr;
    char        *topicPtr;
    char        *unsubMsg = NULL;
    long         totalLength = 0;
    u_short      msgId;

    pHconn->apiReturnCode = MQISDP_OK;
    pMspUp = (UNSUB_PARMS*)ipcBuffer;
    endPtr = (char*)pMspUp + pMspUp->strucLength;
    *msgLength = 0;

    tmpPtr = (char*)pMspUp + sizeof(UNSUB_PARMS);

    while ( tmpPtr < endPtr ) {
        /* Get the topic length and check we are in bounds */
        if ( tmpPtr <= (endPtr - sizeof(long)) ) {
            memcpy( &tLengthUt, tmpPtr, sizeof(long) );
            tLength = mspCharTrim( ' ', tLengthUt, tmpPtr + sizeof(long) );

            /* Add the topic length + 2 for UTF encoding */
            rLength += tLength + 2;
        } else {
            pHconn->apiReturnCode = MQISDP_INVALID_STRUC_LENGTH;
            break;
        }
    
        /* Step over the topic name length and topic name - check we are in bounds */
        tmpPtr += sizeof(long) + tLengthUt;
        if ( tmpPtr > endPtr ) {
            pHconn->apiReturnCode = MQISDP_INVALID_STRUC_LENGTH;
            break;
        }
    }

    /* Calculate the fixed header size required to hold the remaining length */
    MSP_CALC_FHEADER_LENGTH( rLength, fHLength );

    totalLength = fHLength + rLength;

    /* Check we have enough room to hold this data */
    if ( pHconn->outQ.numBytesQueued + totalLength + sizeof(IPQ) > MSP_DEFAULT_MAX_OUTQ_SZ ) {
        pHconn->apiReturnCode = MQISDP_Q_FULL;
    }

    if ( fHLength == -1 ) {
        /* Data is bigger than MQIsdp can handle */
        pHconn->apiReturnCode = MQISDP_DATA_TOO_BIG;
    }
    
    if ( pHconn->apiReturnCode == MQISDP_OK ) {

        /* Now build up the unsubscribe message */
        unsubMsg = (char*)mspMalloc( &(pHconn->comParms), (size_t)totalLength );
        if ( unsubMsg == NULL ) {
            pHconn->apiReturnCode = MQISDP_OUT_OF_MEMORY;
            return NULL;
        }
        tmpPtr = unsubMsg;
    
        /* Insert the message type and QoS (always QoS 1) */
        *tmpPtr = 0x00 | (char)MSP_UNSUBSCRIBE | (char)MSPF_QOS_1 ;
        tmpPtr++;

        /* Encode the message length */
        mspEncodeFHeaderLength( rLength, tmpPtr );
        tmpPtr =  unsubMsg + fHLength;
    
        /* Variable header */
        /* Now add the message ID in network byte order (big-endian) */
        msgId = htons( pHconn->nextMsgId );
        memcpy( tmpPtr, &msgId, sizeof(u_short) );
        tmpPtr += sizeof(u_short);

        /* Payload */
        /* Add topics                                   */
        /* topicPtr points at the UNSUB_PARMS structure */
        /* tmpPtr points at the MQIsdp message          */
        topicPtr = (char*)pMspUp + sizeof(UNSUB_PARMS);

        while ( topicPtr < endPtr ) {
            /* Get the topic length supplied in SUB_PARMS */
            memcpy( &tLengthUt, topicPtr, sizeof(long) );
            /* Get the length once spaces have been trimmed */
            tLength = mspCharTrim( ' ', tLengthUt, topicPtr + sizeof(long) );
            topicPtr += sizeof(long);

            mspUTFEncodeString( (u_short)tLength, topicPtr, tmpPtr );
            /* Move the pointer in the MQIsdp message and the SUB_PARMS structure */
            tmpPtr += tLength + 2;
            topicPtr += tLengthUt;

            mspLog( LOGSCADA, &(pHconn->comParms), "UNSUBSCRIBE,topic:<%.*s>\n",
                    tLength, topicPtr-tLengthUt );
        }

        *msgLength = totalLength;
    }

    return unsubMsg;
}

/* mspBuildScadaPublishMsg */
/* Validate the data passed into the API and build a publish message */
/* Returns NULL on error and sets pHconn->apiReturnCode              */
void* mspBuildScadaPublishMsg( HCONNCB *pHconn, long bufLength,
                               void *ipcBuffer, long *msgLength ){
    long         fHLength = 0;  /* Fixed Header: Depends upon data length */
    long         rLength  = 0;  /* remaining length. */
    long         dLength;       /* data length */
    PUB_PARMS   *pMspPp;
    char        *tmpPtr;
    char        *pubMsg = NULL;
    long         totalLength = 0;

    pHconn->apiReturnCode = MQISDP_OK;
    pMspPp = (PUB_PARMS*)ipcBuffer;
    
    *msgLength = 0;

    /* Variable header */
    /* This has a UTF encoded topic name and a msgId if the QoS is 1 or 2 */
    
    /* Get the topic length */
    dLength = mspCharTrim( ' ', pMspPp->topicLength, pMspPp->topic );
    rLength += dLength + 2; /* Add topic length plus 2 (For the UTF encoding) to the message length */
    if ( (pMspPp->options & MQISDP_QOS_1) || (pMspPp->options & MQISDP_QOS_2) ) {
        rLength += 2;  /* Also allow for a 16 bit msg ID for QoS > 0 messages */
    }

    /* Payload */
    if ( pHconn->apiReturnCode == MQISDP_OK ) {
        rLength += pMspPp->dataLength;
    }

    /* Calculate the fixed header size required to hold the remaining length */
    MSP_CALC_FHEADER_LENGTH( rLength, fHLength );

    totalLength = fHLength + rLength;

    /* Check we have enough room to hold this data */
    if ( pHconn->outQ.numBytesQueued + totalLength + sizeof(IPQ) > MSP_DEFAULT_MAX_OUTQ_SZ ) {
        pHconn->apiReturnCode = MQISDP_Q_FULL;
    }

    if ( fHLength == -1 ) {
        /* Data is bigger than MQIsdp can handle */
        pHconn->apiReturnCode = MQISDP_DATA_TOO_BIG;
    }

    if ( pHconn->apiReturnCode == MQISDP_OK ) {

        /* Now build up the publish message */
        pubMsg = (char*)mspMalloc( &(pHconn->comParms), (size_t)totalLength );
        if ( pubMsg == NULL ) {
            pHconn->apiReturnCode = MQISDP_OUT_OF_MEMORY;
            return NULL;
        }
        tmpPtr = pubMsg;
    
        /* Insert the message type, QoS and retain */
        *tmpPtr = 0x00 | (char)MSP_PUBLISH;
        if ( pMspPp->options & MQISDP_QOS_2 ) {
            *tmpPtr |= (char)MSPF_QOS_2;
        } else if ( pMspPp->options & MQISDP_QOS_1 ) {
            *tmpPtr |= (char)MSPF_QOS_1;
        }
        
        if ( pMspPp->options & MQISDP_RETAIN ) {
            *tmpPtr |= (char)MSPF_RETAIN;
        }

        tmpPtr++;

        /* Encode the message length */
        mspEncodeFHeaderLength( rLength, tmpPtr );
        tmpPtr = pubMsg + fHLength;

        /* Variable header */
        /* Add the topic name - dataPtr is still pointing at the topic */
        mspUTFEncodeString( (u_short)dLength, pMspPp->topic, tmpPtr );
        tmpPtr += dLength + 2;

        /* If the QoS is not 0 then add a msg id */
        if ( (*pubMsg & MSP_FH_GET_QOS) != 0x00 ) {
            u_short msgId = htons( pHconn->nextMsgId );
            memcpy( tmpPtr, &msgId, sizeof(u_short) );
            mspLog( LOGSCADA, &(pHconn->comParms), "PUBLISH sent,topic:<%.*s>,QoS:%d,msgid:%d\n",
                    dLength, pMspPp->topic, (*pubMsg & MSP_FH_GET_QOS)>>1 , pHconn->nextMsgId );
            tmpPtr += sizeof(u_short);
        } else {
            mspLog( LOGSCADA, &(pHconn->comParms), "PUBLISH sent,topic:<%.*s>,QoS:%d\n",
                    dLength, pMspPp->topic, (*pubMsg & MSP_FH_GET_QOS)>>1 );
        }

        /* Payload */
        memcpy( tmpPtr, pMspPp->data, pMspPp->dataLength );

        *msgLength = totalLength;
    }

    return pubMsg;
}

/* mspRecieveScadaMessage */
/* Receives a  MQIsdp message buffer and handles it as appropriate for the message type */
/* Returns NULL on error and sets pHconn->apiReturnCode                                 */
/* A note on identifiers:                                                               */
/* When sending data this implementation ensures that the wmqtt message id is           */
/* incremented each time, so that a wmqtt message id can uniquely identify a message    */
/* that was previously sent to the broker.                                              */
/* When receiving data the wmqtt message id is not unique enough because if data is     */
/* queued up for receiving then when a wmqtt connection is established there is no      */
/* guarantee that wmqtt msg ids received on the new connection will not clash with wmqtt*/
/* message ids received on previous connections. COnsequently we generate a our own     */
/* internal message id whenever a publication is received.                              */
int mspReceiveScadaMessage( HCONNCB *pHconn, long bytesRead, char *pReadBuffer ) {
    long    rlBytes = 0; /* How many bytes does the remaining length take up? */
    int     rLength = 0; /* What is the remaining length? */
    int     l = 0;
    int     rc = 0;
    RPQ    *pRpqEntry;
    IPQ    *pIpqEntry;
    u_short wmqttMsgId;

    switch ( pReadBuffer[0] & MSP_GET_MSG_TYPE ) {
    case MSP_PUBLISH:
        /* Should the publication be released to the application yet?               */
        /* The last byte of the buffer is reserved for this flag. It is part of the */
        /* buffer so that the persistence will store it with the message.           */
        if ( pReadBuffer[0] & MSPF_QOS_2 ) {
            pReadBuffer[bytesRead-1] = 0x00;  /* Not yet released to the application */
        } else {
            pReadBuffer[bytesRead-1] = MQISDP_RELEASED;
        }

        pRpqEntry = mspStorePublication( pHconn, bytesRead, pReadBuffer, &wmqttMsgId );
        if ( pRpqEntry == NULL ) {
            mspLog( LOGSCADA, &(pHconn->comParms), "PUBLISH received, unable to store\n" );
        } else {
            /* Add the message to the persistence store (QoS > 0 pubs only) if there is one */
            if ( !(pRpqEntry->options & MQISDP_QOS_0) && (pHconn->persistFuncs != NULL) ) {
                /* Increment the received message id */
                MSP_SET_NEXT_RCVID( pHconn->nextRcvId );
                pRpqEntry->rcvId = pHconn->nextRcvId;

                /* Use the rcvId when persisting the data - this is separate from the */
                /* protocol id, which isn't sufficiently unique.                      */
                rc = pHconn->persistFuncs->addReceivedMessage( pHconn->persistFuncs->pUserData,
                                                               pRpqEntry->rcvId, bytesRead, pReadBuffer );
            }
            if ( rc != 0 ) {
                /* The persistence failed, so undo the mspStorePublication */
                mspDelFromHash( pHconn, pHconn->inQ.rpHash, wmqttMsgId );
                mspDeleteRPMFromList( pHconn, pRpqEntry );
            } else {
                mspLog( LOGSCADA, &(pHconn->comParms), "PUBLISH received,topic:<%.*s>,QoS:%d,msgid:%d\n",
                        pRpqEntry->topicLength, pRpqEntry->buffer, (pRpqEntry->options)/8,
                        wmqttMsgId );

                /* Send the response using the message id of the received message */
                mspSendPublishResponse( pHconn, pRpqEntry, wmqttMsgId );
            }
        }
        break;
    case MSP_PUBREC:
        if ( mspDecodeFHeaderLength( bytesRead - 1, &rlBytes, &rLength, pReadBuffer + 1 ) != -1
          && rlBytes + rLength <= bytesRead - 1 ) {
            memcpy( &wmqttMsgId, pReadBuffer + 1 + rlBytes, sizeof(u_short) );
            /* Swap the bytes from network to host order */
            wmqttMsgId = ntohs( wmqttMsgId );

            mspLog( LOGSCADA, &(pHconn->comParms), "PUBREC received\n" );

            /* Now send a PUBREL to get the sent publication released.                      */
            /* The PUBLISH message will be deleted from the IPQ by mspSendScadaMessage when */
            /* the PUBREL has been successfully sent.                                       */
            /* The persistence of the PUBREL is handled by mspSendScadaMessage.             */
            /* Send the response using the message id of the received message               */
            mspSendPubReceivedResponse( pHconn, wmqttMsgId );
        }
        break;
    case MSP_PUBREL:
        if ( mspDecodeFHeaderLength( bytesRead - 1, &rlBytes, &rLength, pReadBuffer + 1 ) != -1
          && rlBytes + rLength <= bytesRead - 1 ) {
            memcpy( &wmqttMsgId, pReadBuffer + 1 + rlBytes, sizeof(u_short) );
            /* Swap the bytes from network to host order */
            wmqttMsgId = ntohs( wmqttMsgId );
            pRpqEntry = (RPQ*)mspReadFromHash( pHconn->inQ.rpHash, wmqttMsgId );
            /* If pPubData is NULL then this must be a duplicate PUBREL message. In this */
            /* case just send the PUBCOMP as the message has already been released.      */
            if ( pRpqEntry != NULL ) {

                if ( pHconn->persistFuncs != NULL ) {
                    /* Use the rcvId when persisting the data - this is separate from the protocol id,*/
                    /* which isn't sufficiently unique.                                               */
                    rc = pHconn->persistFuncs->updReceivedMessage( pHconn->persistFuncs->pUserData, pRpqEntry->rcvId );
                }

                if ( rc == 0 ) {
                    /* Mark the publication as having been released */
                    pRpqEntry->readyToPublish = MQISDP_RELEASED;
                    if ( pHconn->inQ.rtpEntries == 0 ) {
                        /* If the number of publications available to receive     */
                        /* changes from 0 to 1 then signal the receive semaphore. */
                        mspSignalSemaphore( pHconn->ipcCb.receiveSemaphore );
                    }
                    pHconn->inQ.rtpEntries++;

                    /* Free the data in the hash */
                    mspDelFromHash( pHconn, pHconn->inQ.rpHash, wmqttMsgId );
                    mspLog( LOGSCADA, &(pHconn->comParms), "PUBREL received,msgId:%ld. Releasing publication.\n", wmqttMsgId );
                }
            } else {
                mspLog( LOGSCADA, &(pHconn->comParms), "PUBREL received,msgId:%ld. Already released.\n", wmqttMsgId );
                /* Leave rc == 0 so that the PUBCOMP still gets sent */
            }

            /* If the persistence update was a success then send the PUBCOMP */
            if ( rc == 0 ) {
                /* Now send a PUBCOMP to complete the QoS 2 flow */
                /* Send the response using the message id of the received message */
                mspSendPubReleaseResponse( pHconn, wmqttMsgId );
            }
        }
        break;
    case MSP_PUBACK:
        if ( l == 0 ) {
            mspLog( LOGSCADA, &(pHconn->comParms), "PUBACK received\n" );
            l=1;
        }
    case MSP_PUBCOMP:
        if ( l == 0 ) {
            mspLog( LOGSCADA, &(pHconn->comParms), "PUBCOMP received\n" );
            l=1;
        }
    case MSP_SUBACK:
        if ( l == 0 ) {
            mspLog( LOGSCADA, &(pHconn->comParms), "SUBACK received\n" );
            l=1;
        }
    case MSP_UNSUBACK:
        if ( l == 0 ) {
            mspLog( LOGSCADA, &(pHconn->comParms), "UNSUBACK received\n" );
            l=1;
        }
        if ( mspDecodeFHeaderLength( bytesRead - 1, &rlBytes, &rLength, pReadBuffer + 1 ) != -1
          && rlBytes + rLength <= bytesRead - 1 ) {
            memcpy( &wmqttMsgId, pReadBuffer + 1 + rlBytes, sizeof(u_short) );
            /* Swap the bytes from network to host order */
            wmqttMsgId = ntohs( wmqttMsgId );
            pIpqEntry = mspReadFromHash( pHconn->outQ.ipHash, wmqttMsgId );
            /* We have received the ACK for the particular message id, so the message */
            /* can be removed from the In Progress Queue and from the hash table      */
            mspDelFromHash( pHconn, pHconn->outQ.ipHash, wmqttMsgId );
            mspDeleteIPMFromList( pHconn, pIpqEntry );

            /* Delete the message from the persistence store, if there is one            */
            /* This doesn't check the return code, because there is not a lot that can   */
            /* be done if the persistence fails to delete a sent message.                */
            /* At worst at application restart QoS 1 messages would be duplicated. QoS 2 */
            /* will not because it will just be the PUBREL message that will be retried. */
            if ( pHconn->persistFuncs != NULL ) {
                pHconn->persistFuncs->delSentMessage( pHconn->persistFuncs->pUserData, wmqttMsgId );
            }
        }
        break;
    case MSP_PINGREQ:
        mspLog( LOGSCADA, &(pHconn->comParms), "PINGREQ received\n" );
        mspSendPingResponse( pHconn );
        break;
    case MSP_PINGRESP:
        /* When we receive a ping response do nothing                                 */
        mspLog( LOGSCADA, &(pHconn->comParms), "PINGRESP received\n" );
        break;
    case MSP_CONNACK:
        /* Check the response code in the CONNACK */
        if ( pReadBuffer[3] == MSP_CONN_ACCEPTED ) {
            pHconn->connState = MQISDP_CONNECTED;
            pHconn->reconnect.timeForNextConnect = 0;
            if ( pHconn->reconnect.connRetries > 0 ) {
                /* If connRetries < 0 then we are running under clean  */
                /* start, so the protocol library should not reconnect */
                /* on behalf of the application                        */
                pHconn->reconnect.connRetries = 0;
            }
        } else {
            pHconn->connState = MQISDP_DISCONNECTED;
            mspTCPDisconnect( &(pHconn->tcpParms.sockfd) );
            /* Stop any retry being attempted */
            pHconn->reconnect.connRetries = pHconn->retryCount + 1;
        
            switch ( pReadBuffer[4] ) {
            case MSP_CONN_REFUSED_VERSION:
                pHconn->tcpParms.lastError = MQISDP_PROTOCOL_VERSION_ERROR | MSP_CONN_ERROR;
                break;
            case MSP_CONN_REFUSED_ID:
                pHconn->tcpParms.lastError = MQISDP_CLIENT_ID_ERROR | MSP_CONN_ERROR;
                break;
            case MSP_CONN_REFUSED_BROKER:
                pHconn->tcpParms.lastError = MQISDP_BROKER_UNAVAILABLE | MSP_CONN_ERROR;
                break;
            }
        }
        mspLog( LOGSCADA, &(pHconn->comParms), "CONNACK\n" );
        break;
    default:
        mspLog( LOGERROR, &(pHconn->comParms), "Unrecognised MQIsdp fixed header:\n" );
        mspLogHex( LOGERROR, &(pHconn->comParms), 1, pReadBuffer );
    }

    return 0;
}

/* Encode the message length according to the SCADA algorithm */
int mspEncodeFHeaderLength( int l, char *ptr ) {
    char d;
    
    do
    {
        d = l % 128;
        l = l / 128;
        /* if there are more digits to encode, set the top bit of this digit */
        if ( l > 0 ) {
            d = d | 0x80;
        }
        *ptr = d;
        ptr++;
    } while ( l > 0 );

    return 0;
}

/* Decode the message length according to the SCADA algorithm             */
/* numBytes is the length of the buffer                                   */
/* rlLength is the count of the bytes used to encode the remaining length */
/* l        is the length decoded                                         */
/* ptr      is the buffer containing the encoded length                   */
/* Returns 0 on success, otherwise -1                                     */
int mspDecodeFHeaderLength( long numBytes, long *rlLength, int *l, char *ptr ) {
    char d;
    int  multiplier = 1;

    *l = 0;
    *rlLength = 0;

    do {
        (*rlLength)++;  /* Increment the byte count for the remaining length */
        d = *ptr;       /* point at the next byte */
        *l += (d & 127) * multiplier; 
        multiplier *= 128;
        ptr++;
    } while ( ((d & 128) != 0) && (*rlLength <= numBytes) );

    /* The length is encoded in more bytes than we have been given */
    if ( (d & 128) != 0 ) {
        *rlLength = 0;
        *l = 0;
        return -1;
    }

    return 0;
}


/* A UTF encoded string is preceeded by a big-endian 16 bit length, */
/* so the outBuf must be 16 bits bigger than the data being encoded */
int mspUTFEncodeString( u_short bufLen, char *buf, char *outBuf ) {
    u_short netShort;

    /* Use the socket function htons to get the length in big-endian order */
    netShort = htons( bufLen );

    memcpy( outBuf, &netShort, sizeof(u_short) );
    memcpy( outBuf + 2, buf, (size_t)bufLen );

    return 0;
}

/* A UTF encoded string is preceeded by a big-endian 16 bit length,                     */
/* To decode the string:                                                                */
/*     1. Convert the first 16 bytes into an unsigned short in the platform endian      */
/*     2. Move the UTF string pointer forward 16 bits to point to a conventional string */
int mspUTFDecodeString( u_short *bufLen, char *bufToDecode, char **ppBuffer ) {

    /* Use the socket function ntohs to get the length in platform endian order */
    memcpy( bufLen, bufToDecode, sizeof(u_short) );
    /* Swap the bytes, if appriopriate for the platform */
    *bufLen = ntohs( *bufLen );

    *ppBuffer = bufToDecode + 2;

    return 0;
}

/* mspSendScadaMessage                                                      */
/* pHconn    - Connection handle for the current application                */
/* msgLen    - Length of the message to send                                */
/* msgData   - The data to send in MQIsdp wire format                       */
/* retryFlag - (0/1) Is this message being retried?                         */
/* initFlag  - (0/1) Is the state being initialised from persistence? If so */
/*             then the state must not be written back to the persistence   */
/*             we are initialising from !.                                  */
/* Returns as follows:                                                      */
/* 0 - Successful send                                                      */
/* 1 - Unsuccessful send, data queued (if appropriate )                     */
/* MQISDP_PERSISTENCE_FAILED - Unable to queue the data - persistence error */
/* MQISDP_OUT_OF_MEMORY      - Unable to queue the data - out of memory     */
int mspSendScadaMessage( HCONNCB *pHconn, long msgLen, char *msgData,
                         short msgId, int retryFlag, int initFlag ) {
    long  storeMsg = 0;
    int   tcpRc = 1;
    int   rc = 0;
    IPQ  *ipqEntry = NULL;
    IPQ  *pTmpIpqEntry = NULL;
    
    /* Store messages with QoS greater than 0 */
    switch ( *msgData & MSP_FH_GET_QOS ) {
    case MSPF_QOS_2:
    case MSPF_QOS_1:
        storeMsg = 1;
        break;
    default:
        break;
    }
    
    /* The message needs to be put on the InProgressQ if:      */
    /* 1. It has a QoS > 0 or                                  */
    /* 2. It is a PUBREL message (This implementation assigns  */
    /*    PUBREL message a QoS > 0).                           */
    /*                                                         */
    /* PUBLISH (QoS > 0) and PUBREL messages are driven by the */
    /* client end of the MQIsdp connection. PUBLISH must be    */
    /* retried in the event of a TCP/IP error and PUBREL must  */
    /* be retried until a PUBCOMP is received.                 */
    if ( storeMsg == 1 ) {

        /* If we are not retrying then queue up the data, otherwise it is already   */
        /* queued.                                                                  */
        if ( retryFlag == 0 ) {

            if ( pHconn->outQ.numBytesQueued + msgLen + sizeof(IPQ) > MSP_DEFAULT_MAX_OUTQ_SZ ) {
                rc = MQISDP_OUT_OF_MEMORY;
            } else {
                ipqEntry = mspAddIPMToList( pHconn, msgLen, msgData, msgId );
                if ( ipqEntry == NULL ) {
                    rc = MQISDP_OUT_OF_MEMORY;
                } else {
                    /* Add the message into the persistence. If this fails, then */
                    /* undo previous in memory queue and abort the send.         */
                    if ( initFlag == 0 ) {
                        if ( pHconn->persistFuncs != NULL ) {
                            if ( (*msgData & MSP_GET_MSG_TYPE) == MSP_PUBREL ) {
                                rc = pHconn->persistFuncs->updSentMessage( pHconn->persistFuncs->pUserData,
                                                                       msgId, msgLen, msgData );
                            } else {
                                rc = pHconn->persistFuncs->addSentMessage( pHconn->persistFuncs->pUserData,
                                                                       msgId, msgLen, msgData );
                            }
                        }
                    } else {
                        ipqEntry->msgStatus = MQISDP_RETRYING;
                    }
                    
                    /* If the persistence failed then undo the previous update */
                    if ( rc != 0 ) {
                        rc = MQISDP_PERSISTENCE_FAILED;
                        /* Set the msgData field to be NULL to stop mspDeleteIPMFromList    */
                        /* freeing the message buffer that this function is trying to send. */
                        /* It will be freed further down...                                 */
                        ipqEntry->msgData = NULL;
                        mspDeleteIPMFromList( pHconn, ipqEntry );
                        ipqEntry = NULL;
                    } else {
                        /* Delete a previous entry if it exists */
                        /* This is only ever the case for QoS 2 publications we send */
                        /* We don't want to delete the PUBLISH message until we know the PUBREL has been queued */
                        pTmpIpqEntry = mspReadFromHash( pHconn->outQ.ipHash, msgId );
                        if ( pTmpIpqEntry != NULL ) {
                            mspDeleteIPMFromList( pHconn, pTmpIpqEntry );
                        }
                        mspAddToHash( pHconn, pHconn->outQ.ipHash, msgId, ipqEntry );
                    }
                }
            }
        } else {
            /* Retry, so flip on the DUP flag. */
            *msgData |= MSPF_DUPLICATE;
        }
    }

    /* Write the data to TCP/IP */
    if ( rc == 0 ) {
        if ( pHconn->tcpParms.sockfd != MSP_INVALID_SOCKET ) {
            tcpRc = mspTCPWrite( pHconn, msgLen, msgData );
            if ( tcpRc == -1 ) {
                rc = 1;
                pHconn->connState = MQISDP_DISCONNECTED;
                mspTCPDisconnect( &(pHconn->tcpParms.sockfd) );
            } else {
                /* A successful write, so update the time for the next poll */
                pHconn->timeForNextPoll = time(NULL) + pHconn->keepAliveTime;
            }
        } else {
            rc = 1;
        }
    }
    
    /* If it the message QoS is 0 or the persistence failed then free up */
    /* storage used by the message. Don't free data if retrying. Only    */
    /* QoS 1 & 2 data is retried and it will be freed when an ACK is     */
    /* received from the broker.                                         */
    if ( ((storeMsg != 1) || (ipqEntry == NULL)) && !retryFlag ) {
        mspFree( &(pHconn->comParms), msgData, msgLen );
    }
    
    return rc;
}

/* mspStorePublication                                                    */
/* A received message is stored in a RIPQ structure. These structures     */
/* are then chained together to form a queue, with the newest message     */
/* received being added to the end of the queue. For Qos 2 messages  the  */
/* pointer to the RIPQ structure is added to a hash table with the        */
/* message id being the hash key. This allows entries to be quickly found */
/* when PUBREL messages are received.                                     */
RPQ* mspStorePublication( HCONNCB *pHconn, long bytesRead, char *pReadBuffer, u_short *wmqttMsgId ) {
    RPQ        *pRpqEntry = NULL;
    long        rlBytes;  /* How many bytes does the Remaining length occupy */
    int         rLength;  /* The actual remaining length */
    char       *tmpPtr;
    char       *topicPtr = NULL;
    u_short     topicLength = 0;               /* @ V1.2 */

    pRpqEntry = (RPQ*)mspMalloc( &(pHconn->comParms), sizeof(RPQ) );
    if ( pRpqEntry == NULL ) {
        return NULL;
    }

    if ( mspDecodeFHeaderLength( bytesRead - 1, &rlBytes, &rLength, pReadBuffer + 1 ) != -1
      && rlBytes + rLength <= bytesRead - 1 /* Sanity check */ ) {
    
       pRpqEntry->options = 0;
       *wmqttMsgId = 0;
       pRpqEntry->topicLength = 0;
        
       /* Get the options from the fixed header - byte 1 */
       if ( pReadBuffer[0] & MSPF_RETAIN ) {
           pRpqEntry->options |= MQISDP_RETAIN;
       }

       if ( pReadBuffer[0] & MSPF_DUPLICATE ) {
           pRpqEntry->options |= MQISDP_DUPLICATE;
       }

       /* Store some options to do with the message */
       if ( pReadBuffer[0] & MSPF_QOS_2 ) {
           pRpqEntry->options |= MQISDP_QOS_2;
       } else if ( pReadBuffer[0] & MSPF_QOS_1 ) {
           pRpqEntry->options |= MQISDP_QOS_1;
       } else {
           pRpqEntry->options |= MQISDP_QOS_0;
       }
       /* The flag indicating whether the publication should be released to the application  */
       /* is the last byte in the buffer. The QoS is not used to determine this because this */
       /* function may be rebuilding QoS 2 publications from the persistence which have      */
       /* already been released.                                                             */
       pRpqEntry->readyToPublish = pReadBuffer[bytesRead-1];

       /* Decode the variable header - step over fixed header and remaining length bytes */
       tmpPtr = pReadBuffer + rlBytes + 1;

       mspUTFDecodeString( &topicLength, tmpPtr, &topicPtr );     /* @ V1.2 */
       pRpqEntry->topicLength = topicLength;                      /* @ V1.2 */
       tmpPtr += pRpqEntry->topicLength + 2;

       if ( (pReadBuffer[0] & MSPF_QOS_2) || (pReadBuffer[0] & MSPF_QOS_1) ) {
           /* Sanity check */
           if (tmpPtr + sizeof(u_short) > pReadBuffer + bytesRead) {
               mspFree( &(pHconn->comParms), pRpqEntry, sizeof(RPQ) );
               return NULL;
           }
           /* Get the message id */
           memcpy( wmqttMsgId, tmpPtr, sizeof(u_short) );
           (*wmqttMsgId) = ntohs( *wmqttMsgId );
           /* The buffer length to hold the topic and data is:  */
           /* remaining length - 2 (for the msg Id) - 2 (for the UTF encoding of the topic) */
           pRpqEntry->bufferLength = rLength - 4;
           tmpPtr += 2;
       } else {
           /* The buffer length to hold the topic and data is:  */
           /* remaining length - 2 (for the UTF encoding of the topic) */
           pRpqEntry->bufferLength = rLength - 2;
       }

       /* Sanity check the two upcoming memcpy's */
       if (topicPtr + pRpqEntry->topicLength > pReadBuffer + bytesRead
       ||  pRpqEntry->bufferLength - pRpqEntry->topicLength < 0
       ||  tmpPtr + (pRpqEntry->bufferLength - pRpqEntry->topicLength) > pReadBuffer + bytesRead) {
           mspFree( &(pHconn->comParms), pRpqEntry, sizeof(RPQ) );
           return NULL;
       }
       
       /* We have no more room to store publications, so free any storage */
       /* we have allocated and return NULL.                              */
       if ( pRpqEntry->bufferLength + sizeof(RPQ) > MSP_DEFAULT_MAX_INQ_SZ ) {
           mspFree( &(pHconn->comParms), pRpqEntry, sizeof(RPQ) );
           return NULL;
       }

       pRpqEntry->buffer = (char*)mspMalloc( &(pHconn->comParms), pRpqEntry->bufferLength );
       if ( pRpqEntry->buffer != NULL ) {
           /* Copy the topic first */
           memcpy( pRpqEntry->buffer, topicPtr, pRpqEntry->topicLength );

           /* Copy the data next */
           memcpy( pRpqEntry->buffer + pRpqEntry->topicLength, tmpPtr,
                   pRpqEntry->bufferLength - pRpqEntry->topicLength );

           /* Add QoS 2 messages to the hash table so that they can be easily looked  */
           /* up later when a PUBREL message is received. If a duplicate is sent then */
           /* check if we have already received it.                                   */
           /* QoS2 pubs that are readyToPublish have been fully acknowledged, so don't*/
           /* add then to the hash table for later look up.                           */
           if ( (pReadBuffer[0] & MSPF_QOS_2) && (pRpqEntry->readyToPublish == 0) ) {
               switch ( pReadBuffer[0] & MSPF_DUPLICATE ) {
               case MSPF_DUPLICATE: /* DUP flag is set.... */
                   if ( mspGetHashEntry( pHconn->inQ.rpHash, *wmqttMsgId ) != NULL ) {
                       /* ....but we have already received it */
                       mspFree( &(pHconn->comParms), pRpqEntry->buffer, pRpqEntry->bufferLength );
                       mspFree( &(pHconn->comParms), pRpqEntry, sizeof(RPQ) );
                       pRpqEntry = NULL;
                       break;
                   }
                   /* ....else we haven't received it, so drop through to default processing */
               default: /* DUP flag not set */
                   mspAddRPMToList( pHconn, pRpqEntry );
                   if ( mspAddToHash( pHconn, pHconn->inQ.rpHash, *wmqttMsgId, pRpqEntry ) != 0 ) {
                       /* Failed to store the publication */
                       mspDeleteRPMFromList( pHconn, pRpqEntry);
                       mspFree( &(pHconn->comParms), pRpqEntry->buffer, pRpqEntry->bufferLength );
                       mspFree( &(pHconn->comParms), pRpqEntry, sizeof(RPQ) );
                       pRpqEntry = NULL;
                   }
                   break;
               }
           } else {
               /* Add the message to the receive queue for the client */
               mspAddRPMToList( pHconn, pRpqEntry );
           }

           if ( pRpqEntry != NULL ) {
               mspLog( LOGSCADA, &(pHconn->comParms), "Storing publication,msgId:%ld. Releasing:%s\n",
                       *wmqttMsgId, (pRpqEntry->readyToPublish==MQISDP_RELEASED)?"TRUE":"FALSE" );
           }
       } else {
           /* Failed to store the publication */
           mspFree( &(pHconn->comParms), pRpqEntry, sizeof(RPQ) );
           pRpqEntry = NULL;
       }
    } else {
        /* Failed to store the publication */
        mspFree( &(pHconn->comParms), pRpqEntry, sizeof(RPQ) );        
        pRpqEntry = NULL;
    }

    return pRpqEntry;
}

/* mspSendPublishResponse */
/* Send a MQIsdp publish response message as appropriate for the QoS */
/* Returns 0 on success, 1 otherwise                                 */
int mspSendPublishResponse( HCONNCB *pHconn, RPQ* pRpqEntry, u_short wmqttMsgId ) {
    char   *pScadaMsg;
    u_short netMsgId;
    int     rc = 1;

    if ( pRpqEntry->options & MQISDP_QOS_2 ) {
        /* Send a PUBREC */
        pScadaMsg = mspMalloc( &(pHconn->comParms), 4 );
        if ( pScadaMsg != NULL ) {
            pScadaMsg[0] = 0x00 | MSP_PUBREC;  /* No other options  */
            pScadaMsg[1] = 0x02;               /* 2 bytes to follow */
            netMsgId = htons( wmqttMsgId );
            memcpy( pScadaMsg+2, &netMsgId, sizeof(u_short) );

            mspLog( LOGSCADA, &(pHconn->comParms), "PUBREC sent\n" );

            if ( mspSendScadaMessage( pHconn , 4, pScadaMsg, wmqttMsgId, 0, 0 ) <= 1 ) {
                rc = 0;
            }
        }
    } else if ( pRpqEntry->options & MQISDP_QOS_1 ) {
        /* Send a PUBACK */
        pScadaMsg = mspMalloc( &(pHconn->comParms), 4 );
        if ( pScadaMsg != NULL ) {
            pScadaMsg[0] = 0x00 | MSP_PUBACK;  /* No other options  */
            pScadaMsg[1] = 0x02;               /* 2 bytes to follow */
            netMsgId = htons( wmqttMsgId );
            memcpy( pScadaMsg+2, &netMsgId, sizeof(u_short) );

            mspLog( LOGSCADA, &(pHconn->comParms), "PUBACK sent\n" );
          
            if ( mspSendScadaMessage( pHconn , 4, pScadaMsg, wmqttMsgId, 0, 0 ) <= 1 ) {
                rc = 0;
            }
        }
    } else {
        /* Nothing to do for QoS 0 */
        rc = 0;
    }

    return rc;
}

/* mspSendPingResponse */
/* Send a MQIsdp PINGRESP message after receiving a PINGREQ */
/* Returns 0 on success, 1 otherwise                        */
int mspSendPingResponse( HCONNCB *pHconn ) {
    char *pScadaMsg;
    int   rc = 1;

    /* Send a PINGRESP */
    pScadaMsg = mspMalloc( &(pHconn->comParms), 2 );
    if ( pScadaMsg != NULL ) {
        pScadaMsg[0] = 0x00 | (char)MSP_PINGRESP;  /* No other options  */
        pScadaMsg[1] = 0x00;                 /* 0 bytes to follow */

        mspLog( LOGSCADA, &(pHconn->comParms), "PINGRESP sent\n" );
    
        if ( mspSendScadaMessage( pHconn , 2, pScadaMsg, 0, 0, 0 ) <= 1 ) {
            rc = 0;
        }
    }

    return rc;
}

/* mspSendPingRequest */
/* Send a MQIsdp PINGREQ message to keepalive the MQIsdp connection */
/* Returns 0 on success, 1 otherwise                                */
int mspSendPingRequest( HCONNCB *pHconn ) {
    char *pScadaMsg;
    int   rc = 1;

    /* Send a PINGREQ */
    pScadaMsg = mspMalloc( &(pHconn->comParms), 2 );
    if ( pScadaMsg != NULL ) {
        pScadaMsg[0] = 0x00 | (char)MSP_PINGREQ;  /* No other options  */
        pScadaMsg[1] = 0x00;                /* 0 bytes to follow */

        mspLog( LOGSCADA, &(pHconn->comParms), "PINGREQ sent\n" );
    
        if ( mspSendScadaMessage( pHconn , 2, pScadaMsg, 0, 0, 0 ) <= 1 ) {
            rc = 0;
        }
    }

    return rc;
}

/* mspSendPubReceivedResponse */
/* Send a MQIsdp publish release message for QoS 2 publications     */
/* Returns 0 on success, 1 otherwise                                */
int mspSendPubReceivedResponse( HCONNCB *pHconn, u_short msgId ) {
    char *pScadaMsg;
    int   rc = 1;

    /* Send a PUBREL */
    pScadaMsg = mspMalloc( &(pHconn->comParms), 4 );
    if ( pScadaMsg != NULL ) {
        pScadaMsg[0] = 0x00 | MSP_PUBREL;  /* No other options  */
        /* Ensure PUBREL gets retried. QoS 1 has for PUBREL no meaning in the protocol */
        /* spec. The QoS is used by this implementation to identify messages to retry  */
        pScadaMsg[0] |= (char)MSPF_QOS_1;
        pScadaMsg[1] = 0x02;               /* 2 bytes to follow */
        *(u_short*)(pScadaMsg+2) = htons( msgId );

        if ( mspSendScadaMessage( pHconn , 4, pScadaMsg, msgId, 0, 0 ) <= 1 ) {
            mspLog( LOGSCADA, &(pHconn->comParms), "PUBREL sent, msgid:%d\n", msgId );
            rc = 0;
        }
    }

    return rc;
}

/* mspSendPubReleaseResponse */
/* Send a MQIsdp publish complete message for QoS 2 publications    */
/* Returns 0 on success, 1 otherwise                                */
int mspSendPubReleaseResponse( HCONNCB *pHconn, u_short msgId ) {
    char *pScadaMsg;
    int   rc = 1;

    /* Send a PUBCOMP */
    pScadaMsg = mspMalloc( &(pHconn->comParms), 4 );
    if ( pScadaMsg != NULL ) {
        pScadaMsg[0] = 0x00 | MSP_PUBCOMP; /* No other options  */
        pScadaMsg[1] = 0x02;               /* 2 bytes to follow */
        *(u_short*)(pScadaMsg+2) = htons( msgId );

        mspLog( LOGSCADA, &(pHconn->comParms), "PUBCOMP sent, msgid:%d\n", msgId );
    
        if ( mspSendScadaMessage( pHconn , 4, pScadaMsg, msgId, 0, 0 ) <= 1 ) {
            rc = 0;
        }
    }

    return rc;
}

/* Attempts to reconnect a broken TCP/IP connection. The original SCADA */
/* connect message is sent to establish the MQIsdp connection.          */
/* Returns 0 on success, 1 otherwise                                    */
int mspMQIsdpReconnect( HCONNCB *pHconn ) {
     int rc = 1;
     char *connMsg;

     if ( pHconn->tcpParms.sockfd != MSP_INVALID_SOCKET ) {
         /* Disconnect TCP/IP before trying the reconnect. This ensures that a WMQtt connect */
         /* message is sent on a different TCP/IP connection each time to avoid confusion    */
         mspTCPDisconnect( &(pHconn->tcpParms.sockfd) );
     }

     /* mspTCPInitialise will also reconnect TCP/IP */
     rc = mspTCPInitialise( pHconn );

     if ( rc == 0 ) {
         pHconn->connState = MQISDP_CONNECTING;
         /* Take a copy of the message to send */
         connMsg = (char*)mspMalloc( &(pHconn->comParms), pHconn->reconnect.connMsgSz );
         if ( connMsg != NULL ) {
             memcpy( connMsg, pHconn->reconnect.connectMsg, pHconn->reconnect.connMsgSz );

             mspSendScadaMessage( pHconn, pHconn->reconnect.connMsgSz, connMsg, 0, 0, 0 );
         }
     }

     return rc;
}

