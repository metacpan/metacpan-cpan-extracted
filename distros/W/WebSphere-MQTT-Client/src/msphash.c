/****************************************************************************/
/*                                                                          */
/* Program name: MQIsdp protocol C Language implementation                  */
/*                                                                          */
/* Description: This source file contains functions for managing hash       */
/* tables and linked lists.                                                 */
/*                                                                          */
/*  Statement:  Licensed Materials - Property of IBM                        */
/*                                                                          */
/*              MQSeries SupportPac IA93                                    */
/*              (C) Copyright IBM Corp. 2002                                */
/*                                                                          */
/****************************************************************************/
/* Version @(#) IA93/ship/msphash.c, SupportPacs, S000 1.3 03/11/28 16:43:45  */
/*                                                                          */
/* Function:                                                                */
/*                                                                          */
/* Both queues for sending and receiving data to/from the broker are        */
/* implemented as linked lists and are hashed.                              */
/*                                                                          */
/****************************************************************************/
/*                                                                          */
/* Change history:                                                          */
/*                                                                          */
/* V1.0   19-02-2003  IRH  Initial release                                  */
/*                                                                          */
/*==========================================================================*/
/* Module Name: msphash.c                                                   */
#include <mspdmn.h>

int mspCalcHashCode( MHASHT* pHash, short msgId );

/* Create a hash table with the specified number of keys */ 
MHASHT *mspInitHash( HCONNCB *pHconn, int nKeys ) {
    MHASHT *pHash = NULL;
    int       hashSz = 0;

    if ( nKeys > 0 ) {
        hashSz = sizeof(MHASHT) + ((nKeys - 1 )*sizeof(MHASHENTRY*));

        pHash = (MHASHT*)mspMalloc( &(pHconn->comParms), hashSz );
        if ( pHash != NULL ) {
            memset( pHash, 0, hashSz );
            pHash->nKeys = nKeys;
        }
    }

    return pHash;
}

/* Delete the identified hash table */
void mspTermHash( HCONNCB *pHconn, MHASHT *pHash ) {
    MHASHENTRY *pCurEntry, *pNextEntry;
    int         k;
    int         hashSz = 0;

    for ( k=0; k < pHash->nKeys; k++ ) {
        pCurEntry = pHash->pKeys[k];
        while ( pCurEntry != NULL ) {
            pNextEntry = pCurEntry->Next;
            mspFree( &(pHconn->comParms), pCurEntry, sizeof(MHASHENTRY) );
            pCurEntry = pNextEntry;
        }
    }

    hashSz = sizeof(MHASHT) + ((pHash->nKeys - 1 )*sizeof(MHASHENTRY*));
    mspFree( &(pHconn->comParms), pHash, hashSz );
}

/* Add an entry to a hash table, where msgId is the hash key */
int mspAddToHash( HCONNCB *pHconn, MHASHT* pHash, short msgId, void *dataPtr ) {
    int         hCode;
    MHASHENTRY *pCurEntry;

    /* Avoid duplicate entries */
    mspDelFromHash( pHconn, pHash, msgId );

    /* Calculate the hash code */
    hCode = mspCalcHashCode( pHash, msgId );

    pCurEntry = (MHASHENTRY*)mspMalloc( &(pHconn->comParms), sizeof(MHASHENTRY) );
    if ( pCurEntry == NULL ) {
        return 1;
    }

    /* Add the current entry to the beginning of the list                */
    /* Set next of the new entry to be current beginning of the list     */
    /* Set the prev of current beginning of the list to be the new entry */
    if ( pHash->pKeys[hCode] != NULL ) {
        pCurEntry->Next = pHash->pKeys[hCode];
        pHash->pKeys[hCode]->Prev = pCurEntry;
    } else {
        pCurEntry->Next = NULL;
    }

    /* Set the new entry to be the beginning of the list */
    pHash->pKeys[hCode] = pCurEntry;

    pCurEntry->msgId = msgId;
    pCurEntry->dataPtr = dataPtr;
    pCurEntry->Prev = NULL;

    return 0;
}

/* Read an entry from a hash table, as identified by hash key msgId */
void* mspReadFromHash( MHASHT* pHash, short msgId ) {
  MHASHENTRY* pCurEntry;
  int hCode;

  hCode = mspCalcHashCode( pHash, msgId );

  for( pCurEntry = pHash->pKeys[hCode]; pCurEntry != NULL; pCurEntry = pCurEntry->Next )
  {
    if( pCurEntry->msgId == msgId ) {
        return( pCurEntry->dataPtr );
    }
  }

  return(NULL);
}

#if 0
/* This is a useful debug function if the contents of a hash table need to be dumped */
int mspDumpHash( MHASHT* pHash ) {
  MHASHENTRY* pCurEntry;
  int hCode;


  for ( hCode = 0; hCode < pHash->nKeys; hCode++ ) {
      for( pCurEntry = pHash->pKeys[hCode]; pCurEntry != NULL; pCurEntry = pCurEntry->Next )
      {
          printf( "MSGID  :%d\n", pCurEntry->msgId );
          printf( "DATAPTR:%p\n", pCurEntry->dataPtr );
      }
  }

  return 0;
}
#endif

/* Get a complete entry from a hash table, as identified by hash key msgId */
MHASHENTRY* mspGetHashEntry( MHASHT* pHash, short msgId ) {
  MHASHENTRY* pCurEntry;
  int hCode;

  hCode = mspCalcHashCode( pHash, msgId );

  for( pCurEntry = pHash->pKeys[hCode]; pCurEntry != NULL; pCurEntry = pCurEntry->Next )
  {
    if( pCurEntry->msgId == msgId ) {
        return( pCurEntry );
    }
  }

  return(NULL);
}

/* Delete an entry from a hash table, as identified by hash key msgId */
void mspDelFromHash( HCONNCB *pHconn, MHASHT* pHash, short msgId ) {
  MHASHENTRY *pCurEntry, *next, *prev;
  int hCode;

  hCode = mspCalcHashCode( pHash, msgId );

  for( pCurEntry = pHash->pKeys[hCode]; pCurEntry != NULL; pCurEntry = pCurEntry->Next )
  {
    if( pCurEntry->msgId == msgId ) {

        prev = pCurEntry->Prev;
        next = pCurEntry->Next;

        if ( prev != NULL ) {
            prev->Next = next;
        } else {
            /* Deleting the first in the chain */
            pHash->pKeys[hCode] = next;
        }

        if ( next != NULL ) {
            next->Prev = prev;
        }

        mspFree( &(pHconn->comParms), pCurEntry, sizeof(MHASHENTRY) );
        return;
    }
  }
}

/* Calculate the hash value from the key */
int mspCalcHashCode( MHASHT* pHash, short msgId ) {
  int hc, j;
  char* pcMsgId;

  pcMsgId = (char*)&msgId;

  /* For each byte of memory in data to be hashed */
  for( hc=0, j=0; j < sizeof(short); pcMsgId++, j++ )
  {
    /* The hash code is the current value of the hash code multiplied */
    /* by 131 plus the current value of the byte we are looking at    */
    hc = 131*hc + *pcMsgId;
  }

  /* hc is between 0 and the number of hashkeys - 1 */
  hc = abs(hc)%pHash->nKeys;
  return( hc );
}

/* Functions for Adding and Deleting an 'in progress message' to/from the InProgressQ linked list */
IPQ* mspAddIPMToList( HCONNCB *pHconn, long dataLen, void *msgData, short msgId ){
  IPQ *ipqEntry = NULL;

  ipqEntry = (IPQ*)mspMalloc( &(pHconn->comParms), sizeof(IPQ) );
  if ( ipqEntry != NULL ) {
      ipqEntry->msgData = msgData;
      ipqEntry->msgLength = dataLen;
      ipqEntry->msgId = msgId;
      ipqEntry->flags = 0;
      ipqEntry->msgStatus = MQISDP_IN_PROGRESS;
      ipqEntry->Next = NULL;
      
      switch ( (*(char*)msgData) & MSP_FH_GET_QOS ) {
      case 0:
          ipqEntry->flags |= MSP_IPQ_QOS_0 ;
          break;
      case 1:
          ipqEntry->flags |= MSP_IPQ_QOS_1 ;
          break;
      case 2:
          ipqEntry->flags |= MSP_IPQ_QOS_2 ;
          break;
      }

      /* Add entries to the end of the list so that they are in the order sent */
      /* incase any retries are required.                                      */
      if ( pHconn->outQ.inProgressQ == NULL ) {
          pHconn->outQ.inProgressQ = ipqEntry;
          ipqEntry->Prev = NULL;
      } else {
          ipqEntry->Prev = pHconn->outQ.pLastEntry;
          pHconn->outQ.pLastEntry->Next = ipqEntry;
      }
      pHconn->outQ.pLastEntry = ipqEntry;

      pHconn->outQ.ipEntries++;
      pHconn->outQ.numBytesQueued += sizeof(IPQ) + ipqEntry->msgLength;
  }

  return ipqEntry;
}

int mspDeleteIPMFromList( HCONNCB *pHconn, IPQ* delEntry ){
    IPQ *prev, *next;

    if ( delEntry != NULL ) {
        prev = delEntry->Prev;
        next = delEntry->Next;

        if ( prev != NULL ) {
            prev->Next = next;
        } else {
            /* Deleting the first in the chain */
            pHconn->outQ.inProgressQ = next;
        }

        if ( next != NULL ) {
            next->Prev = prev;
        } else {
            /* Deleting the last entry, so move the last entry */
            /* pointer to the previous entry                   */
            pHconn->outQ.pLastEntry = prev;
        }

        pHconn->outQ.ipEntries--;
        pHconn->outQ.numBytesQueued -= (delEntry->msgLength + sizeof(IPQ));
        if ( pHconn->outQ.ipEntries == 0 ) {
            pHconn->outQ.pLastEntry = NULL;
        }

        if ( delEntry->msgData != NULL ) {
            mspFree( &(pHconn->comParms), delEntry->msgData, delEntry->msgLength );
        }
        mspFree( &(pHconn->comParms), delEntry, sizeof(IPQ) );
    }

    return 0;
}

/* Functions for Adding and Deleting a publication to/from the RcvdPubsQ linked list */
int mspAddRPMToList( HCONNCB *pHconn, RPQ *newEntry ){
  int  rc = 0;

  if ( newEntry != NULL ) {
      newEntry->Next = NULL;

      /* Add entries to the end of the list so that they are in the order received */
      if ( pHconn->inQ.rcvdPubsQ == NULL ) {
          pHconn->inQ.rcvdPubsQ = newEntry;
          newEntry->Prev = NULL;
      } else {
          newEntry->Prev = pHconn->inQ.pLastEntry;
          pHconn->inQ.pLastEntry->Next = newEntry;
      }
      pHconn->inQ.pLastEntry = newEntry;
      
      if ( newEntry->readyToPublish == MQISDP_RELEASED ) {
          if ( pHconn->inQ.rtpEntries == 0 ) {
              /* If the publications available to receive changes */
              /* from 0 to 1 signal the receive semaphore.        */
              mspSignalSemaphore( pHconn->ipcCb.receiveSemaphore );
          }
          pHconn->inQ.rtpEntries++;
      }
      pHconn->inQ.numBytesQueued += sizeof(RPQ) + newEntry->bufferLength;
  }
  
  return rc;
}

int mspDeleteRPMFromList( HCONNCB *pHconn, RPQ* delEntry ){
    RPQ *prev, *next;

    if ( delEntry != NULL ) {
        prev = delEntry->Prev;
        next = delEntry->Next;

        if ( prev != NULL ) {
            prev->Next = next;
        } else {
            /* Deleting the first in the chain */
            pHconn->inQ.rcvdPubsQ = next;
        }

        if ( next != NULL ) {
            next->Prev = prev;
        } else {
            /* Deleting the last entry, so move the last entry */
            /* pointer to the previous entry                   */
            pHconn->inQ.pLastEntry = prev;
        }

        if ( delEntry->readyToPublish == MQISDP_RELEASED ) {
            pHconn->inQ.rtpEntries--;
        }
        
        pHconn->inQ.numBytesQueued -= (delEntry->bufferLength + sizeof(RPQ));

        if ( delEntry->buffer != NULL ) {
            mspFree( &(pHconn->comParms), delEntry->buffer, delEntry->bufferLength );
        }
        mspFree( &(pHconn->comParms), delEntry, sizeof(RPQ) );
    }
    
    return 0;
}


