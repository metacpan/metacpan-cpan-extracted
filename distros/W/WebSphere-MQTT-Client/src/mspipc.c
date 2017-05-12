/****************************************************************************/
/*                                                                          */
/* Program name: MQIsdp protocol C Language implementation                  */
/*                                                                          */
/* Description: This source file contains functions for handing all Inter   */
/* Process Communication between the various threads.                       */
/*                                                                          */
/*  Statement:  Licensed Materials - Property of IBM                        */
/*                                                                          */
/*              MQSeries SupportPac IA93                                    */
/*              (C) Copyright IBM Corp. 2002                                */
/*                                                                          */
/****************************************************************************/
/* Version @(#) IA93/ship/mspipc.c, SupportPacs, S000 1.3 03/08/26 16:38:24  */
/*                                                                          */
/* Function:                                                                */
/*                                                                          */
/* Functions such as mspInitialiseIPC, mspWriteIPC and mspReadIPC are used  */
/* for transferring data between threads. mspLockMutex and mspReleaseMutex  */
/* control when data may be sent to a particular thread (a lock must be     */
/* obtained before data can be written to a thread). mspWaitForSemaphore    */
/* and mspSignalSemaphore are used when an application does a blocking wait */
/* for messages to arrive.                                                  */
/*                                                                          */
/****************************************************************************/
/*                                                                          */
/* Change history:                                                          */
/*                                                                          */
/* V1.0   19-02-2003  IRH  Initial release                                  */
/* V1.1   18-08-2003  IRH  mspReadIPC - pointer returned from mspRealloc was*/
/*                         not correctly assigned to *ppBuffer variable.    */   
/*                                                                          */
/*==========================================================================*/
/* Module Name: mspipc.c                                                    */
#include <mspsh.h>

/* Initialise the IPC read timeout, if appropriate                              */
/* A timeout value of -1 will cause the mailbox to block until data is received */
DllExport int mspSetIPCTimeout( MBH mbHandle, long mSecs ) {
    #ifndef MSP_SINGLE_THREAD
    
    #if defined(WIN32)
    
      if ( mSecs == -1 ) {
          SetMailslotInfo( mbHandle, MSP_IPC_WAIT_FOREVER );
      } else {
          SetMailslotInfo( mbHandle, mSecs );
      }

    #endif
    
    #endif
    
    return 0;
}

/* Initialise the IPC, as appropriate                                           */
/* A timeout value of -1 will cause the mailbox to block until data is received */
DllExport int mspInitialiseIPC( MBH mbHandle, IPCCB *pIpcCb ) {
    #ifndef MSP_SINGLE_THREAD
    
    #if defined(WIN32)
      SetMailslotInfo( mbHandle, pIpcCb->readTimeout );
    #elif defined(UNIX)
      /* On UNIX we want to ignore the SIGPIPE signal */
      signal( SIGPIPE, SIG_IGN );

    #endif
    
    #endif
    
    return 0;
}

/* mspWriteIPC: Used by the tasks/threads to exchange data.     */
/* Returns 1 on error, otherwise 0                              */
DllExport int mspWriteIPC( MBH mbHandle, IPCCB *pIpcCb, char *ec, int retCode,
                           MQISDPMH hMsg, long numBytes, char *pBuffer ) {
    int     rc = 0;
    CB_HEAD ipcHeader; 
    #ifndef MSP_SINGLE_THREAD
    long    bytesWritten = 0;
    #endif /* MSP_SINGLE_THREAD */
    
    /* Setup the IPC header */
    memcpy( ipcHeader.eyeCatcher, ec, MSP_EC_LENGTH );
    ipcHeader.returnCode = retCode;
    ipcHeader.hMsg = hMsg;
    ipcHeader.dataLength = numBytes;
    ipcHeader.pData = pBuffer;

    #ifndef MSP_SINGLE_THREAD
   
    #if defined(WIN32)
    
       if ( WriteFile( mbHandle, &ipcHeader, sizeof(CB_HEAD), &bytesWritten, NULL ) == 0 ) {
           printf( "IPC: WriteFile error:%ld\n", GetLastError() );
           rc = 1;
       }
    #elif defined(UNIX)
    
       if ( write( mbHandle, &ipcHeader, sizeof(CB_HEAD) ) < 0 ) {
           printf( "IPC: write error:%ld\n", errno );
           rc = 1;
       }

    #endif

    #else
    memcpy( pIpcCb->pPseudoMailbox, &ipcHeader, sizeof(CB_HEAD) );
    #endif

    return rc;
}

/* mspReadIPC: Used by the daemon and client tasks to read data */
/* from the partner task (client or daemon respectively).       */
/* Returns 1 on error, otherwise 0                              */
/* NOTE: nBytesRead may be 0 even if data is read, because this */
/* only counts data received in addition to the CB_HEAD header. */
/* The function return code should be used to determine if data */
/* was received or not.                                         */
DllExport int mspReadIPC( MBH mbHandle, IPCCB *pIpcCb, MSPCMN *comParms, long *nBytesRead,
                          long *bufSize, void **ppBuffer, char *ec ,int *retCode,
                          MQISDPMH *phMsg ) {
    int     rc = 0;
    CB_HEAD ipcHeader;
    long    bytesRead = 0;

    #ifndef MSP_SINGLE_THREAD
    
      #if defined(WIN32)
      if ( ReadFile( mbHandle, &ipcHeader, sizeof(CB_HEAD), &bytesRead, NULL ) == 0 ) {
          if ( GetLastError() != ERROR_SEM_TIMEOUT) {
              printf( "IPC: ReadFile error:%ld\n", GetLastError() );
          }
          bytesRead = 0;
          rc = 1;
      }

      #elif defined(UNIX)
      int selRc;

      /* Wait for any IPC input down the pipe */
      selRc = msp_select( mbHandle, pIpcCb->readTimeout );
      if( selRc > 0 ) {
          /* Bytes available */
          bytesRead = read( mbHandle, &ipcHeader, sizeof(CB_HEAD) );
          if ( bytesRead < 0 ) {
              printf( "IPC: read error:%ld\n", errno );
              bytesRead = 0;
              rc = 1;
          }
      } else {
          /* No data available - msp_select timeout (0) or an error (<0) */
          if ( selRc < 0 ) {
              printf( "IPC: read select error:%ld\n", errno );
          }
          bytesRead = 0;
          rc = 1;
      }

      #endif
      
    #else /* MSP_SINGLE_THREAD */
      memcpy( &ipcHeader, pIpcCb->pPseudoMailbox, sizeof(CB_HEAD) );
      bytesRead = sizeof(CB_HEAD);
    #endif /* MSP_SINGLE_THREAD */

    if ( bytesRead > 0 ) {
        /* Copy the relevant information out of the IPC header */
        *nBytesRead = ipcHeader.dataLength;
        memcpy( ec, ipcHeader.eyeCatcher, MSP_EC_LENGTH );
        *retCode = ipcHeader.returnCode;
        if ( phMsg != NULL ) {
            *phMsg = ipcHeader.hMsg;
        }

        /* Now copy the received data into the receive buffer, extending the buffer if required */
        if ( ipcHeader.dataLength > 0 ) {
            if ( ipcHeader.dataLength <= *bufSize ) {
                memcpy( *ppBuffer, ipcHeader.pData, ipcHeader.dataLength );
            } else {
                *ppBuffer = mspRealloc( comParms, *ppBuffer, ipcHeader.dataLength, *bufSize );
                *bufSize = ipcHeader.dataLength;
                memcpy( *ppBuffer, ipcHeader.pData, ipcHeader.dataLength );
            }
        }
    } else {
        *nBytesRead = 0;
        memset( ec, ' ', MSP_EC_LENGTH );
        *retCode = MQISDP_FAILED;
    }

    return rc;
}

/* Waits for a mutex to become signalled */
/* Returns 0 if this task owns the mutex */
/* Returns 1 otherwise                   */
DllExport int mspLockMutex( MTH mutexHandle ) {
    int rc = 0;
    
    #ifndef MSP_SINGLE_THREAD

    #if defined(WIN32)
      /* Wait forever */
      rc = WaitForSingleObject( mutexHandle, INFINITE );
      if ( rc == WAIT_TIMEOUT ) {
          rc = 1;
      }

    #elif defined(UNIX)
      struct sembuf sb;

      sb.sem_num = 0;
      sb.sem_op = -1;
      /* If the process fails we want the kernel to undo the semaphore */
      sb.sem_flg = SEM_UNDO;

      if ( semop( mutexHandle, &sb, 1 ) < 0 ) {
          rc = 1;
      }

    #endif
    
    #else    /* MSP_SINGLE_THREAD */
      rc = 0;
    #endif   /* MSP_SINGLE_THREAD */
    
    return rc;
}

/* mspReleaseMutex: Release the mutex identified by MTH */
DllExport int mspReleaseMutex( MTH mutexHandle ) {
    int rc = 1;

    #ifndef MSP_SINGLE_THREAD
    
    #if defined(WIN32)
    
      if ( ReleaseMutex( mutexHandle ) > 0 ) { 
          /* Success */
          rc = 0;
      }

    #elif defined(UNIX)
      struct sembuf sb;

      sb.sem_num = 0;
      sb.sem_op = 1;
      sb.sem_flg = SEM_UNDO;

      if ( semop( mutexHandle, &sb, 1 ) < 0 ) {
          rc = 1;
      } else {
          rc = 0;
      }

    #endif
    
    #else   /* MSP_SINGLE_THREAD */
      rc = 0;
    #endif  /* MSP_SINGLE_THREAD */
    
    return rc;
}

/* Waits for a semaphore to become signalled                   */
/* Returns 0 if this task waits successfully for the semaphore */
/* Returns 1 otherwise e.g. timeout                            */
DllExport int mspWaitForSemaphore( MSH semHandle, long msTimeout ) {
    int rc = 1;

    #ifndef MSP_SINGLE_THREAD
    
    #if defined(WIN32)
      if ( msTimeout == -1 ) {
          /* Wait forever */
          rc = WaitForSingleObject( semHandle, INFINITE );
      } else {
          rc = WaitForSingleObject( semHandle, msTimeout );
      }
      if ( rc == WAIT_TIMEOUT ) {
          rc = 1;
      } else {
          rc = 0;
      }
    #elif defined(UNIX)
      struct timespec to;

      /* Lock the pthread mutex                           */
      /* Check if a message is already available          */
      /* If there is no message then wait to be signalled */
      /*    either wait forever, or on a timer            */
      /* The message flag is checked first, as a message may have arrived */
      /* whilst we were not listening for condition variable events.      */
      pthread_mutex_lock( &semHandle->semLock );
      if ( semHandle->msgAvailable == 0x00 ) {
          /* No message available, so wait */
          if ( msTimeout == -1 ) {
              /* Wait forever */
              rc = pthread_cond_wait( &semHandle->msgSignal, &semHandle->semLock );
          } else {

              to.tv_sec = time(NULL) + (int)(msTimeout / 1000);
              to.tv_nsec = 0;
              /* to.tv_nsec = (int)(msTimeout % 1000); */
              rc = pthread_cond_timedwait( &semHandle->msgSignal, &semHandle->semLock, &to );
          }

          if ( rc == ETIMEDOUT ) {
              rc = 1;
          } else {
              rc = 0;
          }
      } else {
          /* A message is available */
          rc = 0;
      }
      /* Reset the message available flag */
      semHandle->msgAvailable = 0x00;
      pthread_mutex_unlock( &semHandle->semLock );

    #endif
    
    #else   /* MSP_SINGLE_THREAD */
      rc = 0;
    #endif  /* MSP_SINGLE_THREAD */
    
    return rc;
}

/* mspSignalSemaphore: Release the semaphore to indicate that data is available */
/* to be received.                                                              */
DllExport int mspSignalSemaphore( MSH semHandle ) {
    int rc = 1;

    #ifndef MSP_SINGLE_THREAD
    
    #if defined(WIN32)
      if ( ReleaseSemaphore( semHandle, 1, NULL ) > 0 ) { 
          /* Success */
          rc = 0;
      }

    #elif defined(UNIX)
      
      /* Lock the pthread mutex                           */
      /* Set the message available flag                   */
      /* Signal any waiters                               */
      /* A message flag is used as well as signalling because a signal is only */
      /* caught if there is a thread waiting. The msgAvailable flag holds the  */
      /* correct state regardless of whether there is a thread waiting.        */
      pthread_mutex_lock( &semHandle->semLock );
      
      /* Set the message available flag and signal any waiters */
      semHandle->msgAvailable = 0x01;
      pthread_cond_signal( &semHandle->msgSignal );
      
      pthread_mutex_unlock( &semHandle->semLock );
      rc = 0;

    #endif
    
    #else   /* MSP_SINGLE_THREAD */
      rc = 0;
    #endif  /* MSP_SINGLE_THREAD */
    
    return rc;
}
            

