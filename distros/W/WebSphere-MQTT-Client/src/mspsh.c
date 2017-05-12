/****************************************************************************/
/*                                                                          */
/* Program name: MQIsdp protocol C Language implementation                  */
/*                                                                          */
/* Description: This source file contains common functions that are         */
/* required by all aspects of the code.                                     */
/*                                                                          */
/*  Statement:  Licensed Materials - Property of IBM                        */
/*                                                                          */
/*              MQSeries SupportPac IA93                                    */
/*              (C) Copyright IBM Corp. 2002                                */
/*                                                                          */
/****************************************************************************/
/* Version @(#) IA93/ship/mspsh.c, SupportPacs, S000 1.2 03/08/26 16:38:29  */
/*                                                                          */
/* Function:                                                                */
/*                                                                          */
/* The functions in the source file provide memory management, and logging  */
/* of messages in both character and hex.                                   */
/*                                                                          */
/****************************************************************************/
/*                                                                          */
/* Change history:                                                          */
/*                                                                          */
/* V1.0   19-02-2003  IRH  Initial release                                  */
/*                                                                          */
/*==========================================================================*/
/* Module Name: mspsh.c                                                     */
#include <mspsh.h>

/* Declare an sccsid variable that has a scope of the entire mqisdp shared  */
/* library and is visible if the a utility such as UNIX strings is executed */
/* against the shared library.                                              */
static char *sccsid = "WMQtt C library SCCSID: @(#) IA93/ship/mspsh.c, SupportPacs, S000 1.2 03/08/26 16:38:29";

/* Memory allocation function used throughout the reference code base. */
DllExport void* mspMalloc( MSPCMN *cData, size_t size ) {
    void *m = malloc( size );

	/* Zero the memory */
	if (m != NULL) bzero(m, size);

    #if MSP_DEBUG_MEM > 0
    if ( m != NULL ) {
      if ( cData != NULL ) {
          cData->mc++;
          cData->memCount += size;
          if ( cData->memCount > cData->memMax ) {
              cData->memMax = cData->memCount;
          }
      }
      #if MSP_DEBUG_MEM == 2
      printf( "Malloced:%p\n", m );
      #endif
    }
    #endif
    
    return m;
}

/* Memory re-allocation function used throughout the reference code base. */
DllExport void* mspRealloc( MSPCMN *cData, void *memBlock, size_t size, long freeSize ) {
    void *m;
#if defined(MSP_NO_REALLOC) || (MSP_DEBUG_MEM > 0)
    m = mspMalloc( cData, size );
    if ( m != NULL ) {
        memcpy( m, memBlock, freeSize );
    }
    mspFree( cData, memBlock, freeSize );
#else
    m = realloc( memBlock, size );
#endif

#if MSP_DEBUG_MEM == 2
    printf( "Realloced:%p to:%p\n", memBlock, m );
#endif
    return m;
}

/* Memory free function used throughout the reference code base. */
DllExport void mspFree( MSPCMN *cData, void *memBlock, size_t freeSize ) {
    
    if ( memBlock != NULL ) {
#if MSP_DEBUG_MEM > 0
        if ( cData != NULL ) {
            cData->fc++;
            cData->memCount -= freeSize;
        }
  #if MSP_DEBUG_MEM == 2
        printf( "Freeing:%p\n", memBlock );
  #endif
#endif
        free( memBlock );
    } 
}

/* Memory logging function recording memory stats when debuging is enabled */
DllExport void mspLogMem( MSPCMN *cData, char *id, int correction ) {
    #if MSP_DEBUG_MEM > 0
    if ( cData != NULL ) {
        mspLog( LOGNORMAL, cData, "%s:Calls to malloc   : %ld\n", id, cData->mc );
        mspLog( LOGNORMAL, cData, "%s:Calls to free     : %ld\n", id, cData->fc );
        mspLog( LOGNORMAL, cData, "%s:Current allocation: %ld\n", id, cData->memCount );
        mspLog( LOGNORMAL, cData, "%s:Max allocation    : %ld\n", id, cData->memMax + correction );
    }
    #endif
}

/* Generic function for dumping data in hex */
/* As it stands this function won't work with multibyte character */
/* sets, as it's formatting assumes 1 byte per character.         */
DllExport void mspLogHex( int logLevel, MSPCMN *cData, int bufSize, char *buffer ) {
    unsigned char *ptr;
    char line1[ MQISDP_LINE_LENGTH + 1 ];
    char line2[ MQISDP_LINE_LENGTH + 1 ];
    char line3[ MQISDP_LINE_LENGTH + 1 ];
    int bytesRemaining;
    int i;
    char hexstring[ 2 + 1 ];

    /* Should we log this message? mspLogOptions is defined at the top of this file */
    if ( logLevel & cData->mspLogOptions ) {
        ptr = (unsigned char *) buffer;
        bytesRemaining = bufSize;

        if (bufSize > 0 ) {
            mspLog( logLevel, cData, "Logging %ld bytes:\n", bufSize );
        }
    
        while ( bytesRemaining > 0 ) {
        
            i = 0;

            while ( ( bytesRemaining > 0 ) && ( i < MQISDP_LINE_LENGTH ) ) {

#ifdef MSP_NO_ISPRINT
		line1[ i ] = *ptr;
#else
                if ( isprint( *ptr ) )
                    line1[ i ] = *ptr;
                else
                    line1[ i ] = '.';
#endif

                sprintf( hexstring, "%02x", *ptr );
                line2[ i ] = hexstring[ 0 ];
                line3[ i ] = hexstring[ 1 ];

                i++;
                ptr++;
                bytesRemaining--;
            }

            line1[ i ] = '\0';
            line2[ i ] = '\0';
            line3[ i ] = '\0';

            mspLog( logLevel, cData, "%s\n", line1 );
            mspLog( logLevel, cData, "%s\n", line2 );
            mspLog( logLevel, cData, "%s\n", line3 );
        }
    }
}

/* Generic log function, which currently writes log messges to stdout */
/* Can be customised to write data to appropriate location            */
DllExport void mspLog( int logLevel, MSPCMN *cData, char *fmt, ... ) {
    char       buf[MSP_LOG_LINE_SZ];
    char      *writePtr;
    va_list    arg_ptr;
    #ifndef MSP_NO_LOCALTIME
    time_t     timer;
    struct tm *pCurTime;
    #endif

    /* Should we log this message? mspLogOptions is defined at the top of this file */
    if ( logLevel & cData->mspLogOptions ) {
        va_start( arg_ptr, fmt );

        writePtr = buf;
        #ifndef MSP_NO_LOCALTIME
        time( &timer );
	    pCurTime = localtime( &timer );
        sprintf( writePtr, "%02d/%02d/%04d %02d:%02d:%02d ", pCurTime->tm_mday, pCurTime->tm_mon + 1,
                 pCurTime->tm_year + 1900, pCurTime->tm_hour, pCurTime->tm_min,
                 pCurTime->tm_sec );
        writePtr += 20;
        #endif

        if ( !(logLevel & LOGNORMAL) ) {
            if ( logLevel & LOGERROR ) {
                sprintf( writePtr, "ERROR :" );
            } else if ( logLevel & LOGSCADA ) {
                sprintf( writePtr, "MQISDP:" );
            } else if ( logLevel & LOGIPC ) {
                sprintf( writePtr, "IPC   :" );
            } else if ( logLevel & LOGTCPIP ) {
                sprintf( writePtr, "TCPIP :" );
            }
            writePtr += 7;
        }

        vsprintf ( writePtr, fmt, arg_ptr );
        va_end( arg_ptr );

        printf( buf );
    }

}

/* This function retruns the length of a buffer after repeats of the character, as */
/* identified by the first parameter, are trimmed off the end of the buffer.       */
/* Mainly used for trimming whitespace of the end of data                          */
DllExport long mspCharTrim( char c, long len, char *buffer ) {

    while ( buffer[len - 1] == c ) {
        len--;
    }

    return len;
}

