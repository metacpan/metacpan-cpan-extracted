/****************************************************************************/
/*                                                                          */
/* Program name: MQIsdp protocol C Language implementation                  */
/*                                                                          */
/* Description: This source file contains the TCP/IP interface code. All    */
/*              platform differences with regard to TCP/IP imlementations   */
/*              are handled in here.                                        */
/*                                                                          */
/*  Statement:  Licensed Materials - Property of IBM                        */
/*                                                                          */
/*              MQSeries SupportPac IA93                                    */
/*              (C) Copyright IBM Corp. 2002                                */
/*                                                                          */
/****************************************************************************/
/* Version @(#) IA93/ship/msptcp.c, SupportPacs, S000 1.3 03/11/28 16:44:03  */
/*                                                                          */
/* Function:                                                                */
/*                                                                          */
/* The main functions that are exposed to callers are mspTCPReadMsg,        */
/* mspTCPWrite, mspTCPInitialise and mspTCPDisconnect.                      */
/* All low level socket functions are wrapped e.g. socket() is wrapped by   */
/* msp_socket() to assist with masking platform differences.                */
/*                                                                          */
/****************************************************************************/
/*                                                                          */
/* Change history:                                                          */
/*                                                                          */
/* V1.0   19-02-2003  IRH  Initial release                                  */
/*                                                                          */
/*==========================================================================*/
/* Module Name: msptcp.c                                                    */
#include <mspdmn.h>
#include <mspscada.h>

#ifndef WIN32
#ifdef MSP_SINGLE_THREAD
#include <signal.h>
static void connect_alarm(int s) { return; }
#endif
#endif

/* Prototypes for wrapper functions of the standard socket functions */
static int msp_socket( int af, int type, int protocol, int *pError );
static int msp_inet_addr( const char *sp, struct in_addr *inadrp );
static int msp_connect(int s, struct sockaddr *destaddr, int addrlen );
static int msp_close( int s );
static int msp_send( int s, void *pBuf, int len, int flags, int *pError );
static int msp_recv( int s, void *pBuf, int len, int flags, int *pError );
static int mspTcpGetLastError( void );

/* Do DNS resolution                                              */
/* Returns the dotted ip address (a.b.c.d) as a string on success */
/* Returns NULL error if the hostname cannot be resolved          */
/* pHconn->tcpParms.lastError contains the error code which is    */
/* returned if the application uses MQIsdp_status() to query the  */
/* connection state.                                              */
char* mspTCPGetHostByName( HCONNCB *pHconn, char *pHostName ) {
    struct hostent *pHostEntry;
    struct in_addr sinAddr;

    pHostEntry = gethostbyname( pHostName );

    if ( pHostEntry != NULL ) {
        memcpy( &sinAddr, pHostEntry->h_addr_list[0], pHostEntry->h_length );
        return inet_ntoa( sinAddr );
    } else {
        if ( pHconn->tcpParms.lastError == 0L ) {
            pHconn->tcpParms.lastError = MSP_TCP_HOST_ERROR | MQISDP_HOSTNAME_NOT_FOUND;
        }
        return NULL;
    }
}

/* Create a socket and connect to the IP address and port specified */
/* Returns 0 on success, 1 on error                                 */
/* pHconn->tcpParms.lastError contains the specific error code,     */
/* which is interpreted by the MQIsdp_status() API call.            */
int mspTCPConnect( HCONNCB *pHconn, u_short port, char *ipAddr ) {
    int    connrc;
    int    rc = 0;
    struct sockaddr_in servAddr;

    pHconn->tcpParms.sockfd = msp_socket( AF_INET, SOCK_STREAM, 0, &connrc );
        
    if ( pHconn->tcpParms.sockfd != MSP_INVALID_SOCKET ) {

        servAddr.sin_family = AF_INET;
        servAddr.sin_port = htons(port);

        msp_inet_addr( ipAddr, &(servAddr.sin_addr) );
        
        if ( msp_connect( pHconn->tcpParms.sockfd, (struct sockaddr*)&servAddr, sizeof(servAddr) ) < 0 ) {
            connrc = mspTcpGetLastError();
            /* Close the socket */
            mspTCPDisconnect( &(pHconn->tcpParms.sockfd) );
            
            mspLog( LOGTCPIP, &(pHconn->comParms), "mspTCPConnect:connect error:%ld - %s(%d)\n",
                    connrc, ipAddr, port );
            /* Only set a last error if it is zero otherwise don't overwrite anything */
            if ( pHconn->tcpParms.lastError == 0L ) {
                pHconn->tcpParms.lastError = connrc | MSP_TCP_CONN_ERROR;
            }
            rc = 1;
        }
    } else {
        /* Only set a last error if it is zero otherwise don't overwrite anything */
        if ( pHconn->tcpParms.lastError == 0L ) {
            pHconn->tcpParms.lastError = connrc | MSP_TCP_SOCK_ERROR;
            mspLog( LOGERROR, &(pHconn->comParms), "mspTCPConnect:socket error:%ld\n", connrc );
        }
        rc = 1;
    }

    if ( rc == 0 ) {
        pHconn->tcpParms.lastError = 0L;
        mspLog( LOGNORMAL, &(pHconn->comParms), "mspTCPConnect:connect success - %s(%d)\n", ipAddr, port );
    }

    return rc;
}

/* This function loops through all the servers provided on the connect call         */
/* and connects to each in the order supplied until a successful connection is made */
/* or the list of servers is exhausted.                                             */
/* If a successful connection is made then all other potential servers are removed  */
/* from the list. If mspTCPInitialise is called when reconnecting then there will   */
/* only be one server in the list (as all others have been removed), so that is the */
/* one it will use.                                                                 */
/* Returns 0 on success, otherwise 1                                                */
int mspTCPInitialise( HCONNCB *pHconn ) {
    int     rc = 1;

    rc = mspTCPConnect( pHconn, pHconn->tcpParms.brokerPort, pHconn->tcpParms.brokerAddress );

    if ( rc == 0 ) {
        /* Send a message to the receive task to tell it what the socket descriptor is */
        mspInitReceiveTask( pHconn );
    }

    return rc;
}

/* Close the TCP/IP socket */
/* Returns 0               */
int mspTCPDisconnect( int *pSockfd ) {

    if ( *pSockfd != MSP_INVALID_SOCKET ) {
        msp_close( *pSockfd );
        *pSockfd = MSP_INVALID_SOCKET;
    }
    
    return 0;
}

/* Write data to the socket          */
/* Returns 0 on success, -1 on error */
int mspTCPWrite( HCONNCB *pHconn, size_t msgLen, char *msgData ) {

    size_t  nleft;
    int     nwritten = 0;
    char   *ptr;
    int     mspErrno = 0;

    ptr = msgData;
    nleft = msgLen;
    while ( nleft > 0 ) {
        if ( (nwritten = msp_send( pHconn->tcpParms.sockfd, ptr, nleft, 0, &mspErrno )) <= 0 ) {
            if ( mspErrno == EINTR ) {
                nwritten = 0;
            } else {
                pHconn->tcpParms.lastError = mspTcpGetLastError() | MSP_TCP_SEND_ERROR;
                mspLog( LOGERROR, &(pHconn->comParms), "TCP/IP send error %ld\n",
                        (pHconn->tcpParms.lastError & MSP_GET_LAST_ERROR) );
                return -1;
            }
        }
        nleft -= nwritten;
        ptr += nwritten;
    }

    mspLog( LOGTCPIP, &(pHconn->comParms), "TCP/IP output sent: %ld bytes\n", nwritten );
    mspLogHex( LOGTCPIP, &(pHconn->comParms), nwritten, msgData );
    
    return 0;
}

/* Read data from the socket, increasing the size of the supplied receive buffer if required. */
/* Multiple messages may be waiting to be read from the socket, so a bulk read of all data    */
/* available isn't done. This function initially reads two bytes (Fixed header and first      */
/* length byte), then reads 1 byte at a time up to the end of the remaining length field.     */
/* the remaining length has been calculated the remaining part of the message can be read in  */
/* a single read operation.                                                                   */
/* Returns 0 on success, -1 on error                                                          */
int mspTCPReadMsg( int sockfd, MSPCMN *pComParms, int *pLastError,
                   long *msgLen, long *bufLen, char **buffer ) {

    int         nread = -1;
    long        rlLength = 2;  /* Read the first 2 bytes of data */         
    int         nleft;
    char       *ptr;
    int         rc = 0;
    int         mspErrno = 0;

    ptr = *buffer;
    *msgLen = 0;

    /* Keep reading until we either read without being interrupted or there is an error */
    /* rlLength indicates how much data to receive */
    /* This first loop reads the MQIsdp fixed header and remaining length bytes */
    while ( rlLength > 0 ) {
        if ( (nread = msp_recv( sockfd, ptr, rlLength, 0, &mspErrno )) == 0 ) {
            /* If the socket is readable, but 0 bytes are read then this */
            /* indicates that the remote end has closed the socket       */
            *msgLen = 0;
            if ( pLastError != NULL ) {
                *pLastError = MQISDP_SOCKET_CLOSED | MSP_CONN_ERROR ;
            }
            rlLength = 0;
            rc = -1;
            break;
        } else if ( (nread < 0) && (mspErrno != EINTR) ) {
            /* Something else has gone wrong.... */
            *msgLen = 0;
            if ( pLastError != NULL ) {
                *pLastError = mspErrno | MSP_TCP_RECV_ERROR;
            }
            mspLog( LOGERROR, pComParms, "TCP/IP recv error %ld\n", mspErrno );
            rlLength = 0;
            rc = -1;
            break;
        } else {
            /* Record how much data we have read */
            *msgLen += nread;
            rlLength = 1;

            /* The first byte is the MQIsdp fixed header */
            if ( *msgLen > 1 ) {
                /* Move to the last byte read and check the highest order bit    */
                /* If it is off then we have read all the remaining length bytes */
                ptr += nread - 1;
                if ( !(*ptr & 128) ) {
                    rlLength = 0;
                }
            }
            ptr++;
        }
    }

    /* Now decode the remaining length bytes               */
    /* The number of bytes used will be stored in rlLength */
    /* The decoded length will be stored in nleft          */
    if ( (*msgLen == 0) || (mspDecodeFHeaderLength( *msgLen-1, &rlLength, &nleft, *buffer+1 ) < 0) ) {
        /* We are unable to decode the data length */
        *msgLen = 0;
        return -1;
    }

    /* Work out the message length we have received              */
    /* Fixed header (1) + # of remaining length bytes (rlLength) */
    /* + the data length following (nleft)                       */
    *msgLen = nleft + rlLength + 1;

    /* Take a look at the fixed header. If it is a message of type publish then   */
    /* allocate an additional byte that indicates if it has been released or not. */
    /* This additional byte is used by the persistence.                           */
    if ( ((*buffer)[0] & MSP_GET_MSG_TYPE) == MSP_PUBLISH ) {
        (*msgLen)++;
    }

    if ( *msgLen > *bufLen ) {
        *buffer = (char*)mspRealloc( pComParms, *buffer, *msgLen, *bufLen );
        *bufLen = *msgLen;
        if ( *buffer == NULL ) {
            *bufLen = 0;
            *msgLen = 0;
            return -1;
        }
    }

    ptr = *buffer + rlLength + 1;
    while ( nleft > 0 ) {
        if ( (nread = msp_recv( sockfd, ptr, nleft, 0, &mspErrno )) <= 0 ) {
            /* If we have been interrupted spin around and retry the recv */
            if ( mspErrno != EINTR ) {
                /* Something else has gone wrong.... */
                if ( pLastError != NULL ) {
                    *pLastError = mspErrno | MSP_TCP_RECV_ERROR;
                }
                mspLog( LOGERROR, pComParms, "TCP/IP recv error %ld\n", mspErrno );
                *bufLen = 0;
                *msgLen = 0;
                rc = -1;
                break;
            }
        } else {
            ptr += nread;
            nleft -= nread;
        }
    }

    mspLog( LOGTCPIP, pComParms, "TCP/IP input received: %ld bytes\n", *msgLen );
    mspLogHex( LOGTCPIP, pComParms, *msgLen, *buffer );

    return rc;
}

/* Initialise the TCP/IP stack                               */
/* This function is called once when the send task starts up */
int mspTCPInit( void ) {
    #ifdef WIN32
        WORD    winsockVer = 0x0202;
        WSADATA wsd;
    
        WSAStartup( winsockVer, &wsd );
    #endif

    return 0;
}

/* Terminate the TCP/IP stack                                 */
/* This function is called once when the send task shuts down */
int mspTCPTerm( void ) {
    #ifdef WIN32
        WSACleanup();
    #endif

    return 0;
}

/*##############################################################################*/
/* Below are wrapper functions for the standard TCP/IP socket functions.        */
/* Specifics of different TCP/IP stacks aree handled in these wrapper functions */
/*##############################################################################*/
/* mspSelect                                                                   */
/* Inputs:                                                                     */
/*  sockfd  - Socket descriptor                                                */
/*  mSecs   - millisecond timeout                                              */
/* If sockfd is an invalid socket msp_select will sleep for mSecs milliseconds */
/* If mSecs is -1 then msp_select will block infinitely on sockfd, unless      */
/* sockfd is invalid. In this case it will return immediately.                 */
int msp_select( int sockfd, long mSecs ) {
    #ifndef MSP_FUSION_SOCKETS
      fd_set          rset;
      int             maxfdp1 = 0;
      struct timeval  timeout;
      struct timeval *pTimeout = &timeout;
    
       if ( mSecs < 0 ) {
           pTimeout = NULL;
       } else {
           timeout.tv_sec = (int)mSecs / 1000;      /* seconds      */
           timeout.tv_usec = (mSecs % 1000) * 1000; /* microseconds */
       }

      if ( sockfd != MSP_INVALID_SOCKET ) {
          /* Initialise the descriptor set */
          FD_ZERO( &rset );
          /* Add the current socket descriptor */
          FD_SET( (u_int)sockfd, &rset );
          maxfdp1 = sockfd + 1;
      }

      #ifdef MSP_KN_SOCKETS
        return kn_select( maxfdp1, &rset, NULL, NULL, pTimeout );
      #else  /* MSP_KN_SOCKETS */
          #if defined(WIN32)
          /* If there are no descriptors to wait on select will fail on Windows */
          if ( maxfdp1 == 0 ) {
              Sleep( mSecs );
              /* Return 0 because we have timed out rather than receiving data */
              return 0;
          } 
          #endif /* WIN32 */
          return select( maxfdp1, &rset, NULL, NULL, pTimeout );
      #endif /* MSP_KN_SOCKETS */
    #else /* MSP_FUSION_SOCKETS */
      struct sel sel_arr[1];
      int        err;

      if ( sockfd == MSP_INVALID_SOCKET ) {
          if( mSecs > 0 ) {
              DELAY( mSecs );
          }
          return 0;
      } else {
          sel_arr[0].se_fd = sockfd;
          sel_arr[0].se_inflags = READ_NOTIFY;
          return nselect( sel_arr,  1, &mSecs, usel_nilpfi, (u32)0, &err );
      }
    #endif  /* MSP_FUSION_SOCKETS */
    /* return 0; - unreachable statement */
}

static int msp_socket( int af, int type, int protocol, int *pError ) {
#ifdef MSP_FUSION_SOCKETS
    return socket( AF_INET, SOCK_STREAM, 0, pError );
#else
    int sockRc;
    #ifdef MSP_KN_SOCKETS
        sockRc = kn_socket( AF_INET, SOCK_STREAM, 0 );
    #else
        sockRc = socket( AF_INET, SOCK_STREAM, 0 );
    #endif
    *pError = mspTcpGetLastError();
    return sockRc;
#endif
}

static int msp_inet_addr( const char *sp, struct in_addr *inadrp ) {
    #ifdef MSP_KN_SOCKETS
        return kn_inet_addr( sp, inadrp);
    #else
        /* AIX and SOLARIS only support inet_addr */
        /* On LINUX inet_addr or inet_aton works  */
        #if defined( WIN32 ) || defined(UNIX) || defined( MSP_FUSION_SOCKETS )
            long    inetAddr; 
            inetAddr = inet_addr( sp );
            if ( inetAddr != INADDR_NONE ) {
                memcpy( inadrp, &inetAddr, sizeof(inadrp) );
                return 0;
            }
            return 1;
        #else
            return inet_aton( sp, inadrp );
        #endif
    #endif
}

static int msp_connect(int s, struct sockaddr *destaddr, int addrlen ) {
    #ifdef MSP_KN_SOCKETS
        return kn_connect( s, destaddr, addrlen );
    #else
        #ifdef WIN32
          if ( connect( s, destaddr, addrlen ) == SOCKET_ERROR )
               return -1;
          else
              return 0;
        #elif defined(MSP_SINGLE_THREAD) && defined(SIGALRM)
          /* This is a frig to prevent blocking in connect() for several
             minutes if the remote host is not reachable */
          int rc;
          struct sigaction act, oact;
          memset(&act, 0, sizeof(act));
          act.sa_handler = connect_alarm;
          /* Note: don't set sa_flags = SA_RESTART */
          sigaction(SIGALRM, &act, &oact);
          alarm(15);
          rc = connect( s, destaddr, addrlen );
          alarm(0);
          sigaction(SIGALRM, &oact, NULL);
          if (rc < 0 && errno == EINTR) errno = ETIMEDOUT;
          return rc;
        #else
          return connect( s, destaddr, addrlen );
        #endif
    #endif
}

static int mspTcpGetLastError( void ) {
    #ifdef MSP_KN_SOCKETS
        return kn_errno();
    #else
      #ifdef WIN32
        return WSAGetLastError();
      #else
        return errno;
      #endif
    #endif  
}

static int msp_close( int s ) {
    #ifdef MSP_KN_SOCKETS
      return kn_close( s )
    #else
      #ifdef WIN32
        return closesocket( s );
      #else
        return close( s );
      #endif
    #endif    
}

static int msp_send( int s, void *pBuf, int len, int flags, int *pError ) {
#ifdef MSP_FUSION_SOCKETS
    return send( s, pBuf, len, flags, pError );
#else                                       
    int sockRc;
    #ifdef MSP_KN_SOCKETS
      sockRc = kn_send( s, pBuf, len, flags );
    #else
      sockRc = send( s, pBuf, len, flags );
    #endif
    *pError = mspTcpGetLastError();
    return sockRc;
#endif
}

static int msp_recv( int s, void *pBuf, int len, int flags, int *pError ) {
#ifdef MSP_FUSION_SOCKETS
    return recv( s, pBuf, len, flags, pError );
#else
    int sockRc;
    #ifdef MSP_KN_SOCKETS
      sockRc = kn_recv( s, pBuf, len, flags );
    #else
      sockRc = recv( s, pBuf, len, flags );
    #endif
    *pError = mspTcpGetLastError();
    return sockRc;
#endif
}
