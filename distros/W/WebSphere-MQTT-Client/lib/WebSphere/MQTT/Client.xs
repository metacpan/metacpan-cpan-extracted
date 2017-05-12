/*

	WebSphere MQ Telemetry Transport
	Perl Interface to IA93

	Nicholas Humfrey
	University of Southampton
	njh@ecs.soton.ac.uk
	
*/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* WMQTT include */
#include "MQIsdp.h"
#include "ppersist.h"



/* Get the connection handle from hashref */
MQISDPCH
get_handle_from_hv( HV* hash ) {
	SV** svp = NULL;
	IV pointer;
	
	svp = hv_fetch( hash, "handle", 6, 0 );
	if (svp == NULL || !SvOK(*svp)) {
		warn("Connection handle is missing from hash");
		return NULL;
	}
	
	if (!sv_derived_from(*svp, "MQISDPCH")) {
		//warn("Connection handle isn't isn't of type MQISDPCH");
		return NULL;
	}

	// Re-reference and extract the pointer
	pointer = SvIV((SV*)SvRV(*svp));
	return INT2PTR(MQISDPCH,pointer);
}


/* Get debug settings from hashref */
int
get_debug_from_hv( HV* hash ) {
	SV** svp = NULL;
	
	svp = hv_fetch( hash, "debug", 5, 0 );
	if (svp == NULL) {
		warn("Debug setting is missing from hash");
		return 0;
	}
	
	return SvTRUE( *svp );
}


/* Get task info from hashref */
MQISDPTI*
get_task_info_from_hv( HV* hash, char* name ) {
	SV** svp = NULL;
	IV pointer;
	
	svp = hv_fetch( hash, name, strlen(name), 0 );
	if (svp == NULL || !SvOK(*svp)) return NULL;
	if (!sv_derived_from(*svp, "MQISDPTIPtr")) return NULL;

	// Re-reference and extract the pointer
	pointer = SvIV((SV*)SvRV(*svp));
	return INT2PTR(MQISDPTI*,pointer);
}


/* Undefine the value of a key */
void
hv_key_undef( HV* hash, char* key ) {
	SV** svp = NULL;

	svp = hv_fetch( hash, key, strlen(key), 0 );
	if (svp) {
		sv_setsv(*svp, &PL_sv_undef);
	} /* else {
		warn("hv_key_undef: Didn't find key in hash");
	} */
}


/* Make an array from pubOptions */
AV*
options_to_av( long pubOptions ) {
	SV* sv = NULL;
	AV* av = newAV();
	
	if (pubOptions & MQISDP_WILL) {
		sv = newSVpv( "WILL", 0 );
		av_push( av, sv );
	}
	
	if (pubOptions & MQISDP_RETAIN) {
		sv = newSVpv( "RETAIN", 0 );
		av_push( av, sv );
	}
	
	if (pubOptions & MQISDP_QOS_0) {
		sv = newSVpv( "QOS_0", 0 );
		av_push( av, sv );
	}
	
	if (pubOptions & MQISDP_QOS_1) {
		sv = newSVpv( "QOS_1", 0 );
		av_push( av, sv );
	}
	
	if (pubOptions & MQISDP_QOS_2) {
		sv = newSVpv( "QOS_2", 0 );
		av_push( av, sv );
	}
	
	if (pubOptions & MQISDP_CLEAN_START) {
		sv = newSVpv( "CLEAN_START", 0 );
		av_push( av, sv );
	}
	
	if (pubOptions & MQISDP_WILL_RETAIN) {
		sv = newSVpv( "WILL_RETAIN", 0 );
		av_push( av, sv );
	}
	
	if (pubOptions & MQISDP_DUPLICATE) {
		sv = newSVpv( "DUPLICATE", 0 );
		av_push( av, sv );
	}

	return av;
}



#define STATUS_CASE_RET( x ) \
  case x:           \
    return #x;    \
    break;


const char*
get_status_string( int statusCode ) {

 	switch(statusCode) {
		case MQISDP_OK:						return "OK";
		case MQISDP_PROTOCOL_VERSION_ERROR:	return "PROTOCOL_VERSION_ERROR";
		case MQISDP_HOSTNAME_NOT_FOUND:		return "HOSTNAME_NOT_FOUND";
		case MQISDP_Q_FULL:					return "Q_FULL";
		case MQISDP_FAILED:					return "FAILED";
		case MQISDP_PUBS_AVAILABLE:			return "PUBS_AVAILABLE";
		case MQISDP_NO_PUBS_AVAILABLE:		return "NO_PUBS_AVAILABLE";
		case MQISDP_PERSISTENCE_FAILED:		return "PERSISTENCE_FAILED";
		case MQISDP_CONN_HANDLE_ERROR:		return "CONN_HANDLE_ERROR";
		case MQISDP_NO_WILL_TOPIC:			return "NO_WILL_TOPIC";
		case MQISDP_INVALID_STRUC_LENGTH:	return "INVALID_STRUC_LENGTH";
		case MQISDP_DATA_LENGTH_ERROR:		return "DATA_LENGTH_ERROR";
		case MQISDP_DATA_TOO_BIG:			return "DATA_TOO_BIG";
		case MQISDP_ALREADY_CONNECTED:		return "ALREADY_CONNECTED";
		case MQISDP_CONNECTION_BROKEN:		return "CONNECTION_BROKEN";
		case MQISDP_DATA_TRUNCATED:			return "DATA_TRUNCATED";
		case MQISDP_CLIENT_ID_ERROR:		return "CLIENT_ID_ERROR";
		case MQISDP_BROKER_UNAVAILABLE:		return "BROKER_UNAVAILABLE";
		case MQISDP_SOCKET_CLOSED:			return "SOCKET_CLOSED";
		case MQISDP_OUT_OF_MEMORY:			return "OUT_OF_MEMORY";
 		
		case MQISDP_DELIVERED:				return "DELIVERED";
		case MQISDP_RETRYING:				return "RETRYING";
		case MQISDP_IN_PROGRESS:			return "IN_PROGRESS";
		case MQISDP_MSG_HANDLE_ERROR:		return "MSG_HANDLE_ERROR";
		
		case MQISDP_CONNECTING:				return "CONNECTING";
		case MQISDP_CONNECTED:				return "CONNECTED";
		case MQISDP_DISCONNECTED:			return "DISCONNECTED";
	}
	
	return "UNKNOWN";
}


MODULE = WebSphere::MQTT::Client	PACKAGE = WebSphere::MQTT::Client


##
## Prints library version to STDOUT
##
void
xs_version()
  CODE:
   MQIsdp_version();


##
## Alocate memory for TaskInfo
##
int
xs_start_tasks( self )
	HV* self
  PREINIT:
  	MQISDPTI* pSendTaskInfo = NULL;
  	MQISDPTI* pRcvTaskInfo = NULL;
  	MQISDPTI* pApiTaskInfo = NULL;
  	char *clientid = NULL;
  	SV** svp = NULL;
 	SV* sv = NULL;

  CODE:
  	/* Get the client ID */
  	svp = hv_fetch( self, "clientid", 8, 0 );
  	if (svp != NULL) {
  		clientid = SvPV_nolen( *svp );
  		if (strlen(clientid) < 1 || strlen(clientid) > 23) {
  			croak("clientid is not valid");
  		}
  	} else {
  		croak("clientid is not defined");
   	}
  	
  	
	/* Allocate the WMQTT thread parameter structures */
	pSendTaskInfo = (MQISDPTI*)malloc( sizeof(MQISDPTI) );
	pRcvTaskInfo = (MQISDPTI*)malloc( sizeof(MQISDPTI) );
	pApiTaskInfo = (MQISDPTI*)malloc( sizeof(MQISDPTI) );
	
	/* Zero the memory */
	bzero( pSendTaskInfo, sizeof(MQISDPTI) );
	bzero( pRcvTaskInfo, sizeof(MQISDPTI) );
	bzero( pApiTaskInfo, sizeof(MQISDPTI) );
	
	/* Turn thread tracing off */
	pSendTaskInfo->logLevel = LOGNONE;
	pRcvTaskInfo->logLevel = LOGNONE;
	pApiTaskInfo->logLevel = LOGNONE;


	/* Start the threads (if enabled) */
	if ( MQIsdp_StartTasks( pApiTaskInfo, pSendTaskInfo,
                            pRcvTaskInfo, clientid ) != 0 ) {
        croak("Failed to start MQIsdp protocol threads");
        XSRETURN_UNDEF;
    }
    
    /* Store thread parameter pointers */
	sv=sv_setref_pv(newSV(0), "MQISDPTIPtr", (void *)pSendTaskInfo);
	if (hv_store(self, "send_task_info", 14, sv, 0) == NULL) {
		croak("send_task_info not stored");
	}
	
	sv=sv_setref_pv(newSV(0), "MQISDPTIPtr", (void *)pRcvTaskInfo);
	if (hv_store(self, "recv_task_info", 14, sv, 0) == NULL) {
		croak("recv_task_info not stored");
	}
	
	sv=sv_setref_pv(newSV(0), "MQISDPTIPtr", (void *)pApiTaskInfo);
	if (hv_store(self, "api_task_info", 13, sv, 0) == NULL) {
		croak("api_task_info not stored");
	}

    
    /* Successful */
    RETVAL = 1;
    
  OUTPUT:
	self
	RETVAL

 
	
##
## Get connection status
##
const char*
xs_status( self )
	HV* self

  PREINIT:
  	MQISDPCH	handle = MQISDP_INV_CONN_HANDLE;
	int			statusCode=0;
	int			debug=0;
	char        infoString[MQISDP_INFO_STRING_LENGTH] = "";
	const char	*statusString = NULL;
	
  CODE:
  	/* get the connection handle */
  	handle = get_handle_from_hv( self );  
  	debug = get_debug_from_hv( self );
  	
  	/* Not connected ? */
  	if (handle == NULL) {
  		statusCode = MQISDP_DISCONNECTED;
  	} else {
		/* get the connection status */
		statusCode = MQIsdp_status( handle, MQISDP_RC_STRING_LENGTH, NULL, infoString );
 	}
 	
 	/* Turn status code into a string */
 	statusString = get_status_string( statusCode );
 	if (debug) {
 		fprintf(stderr, "xs_status: %s [%d] - %s\n", statusString, statusCode, infoString);
 	}
 	
	RETVAL = statusString;
 	
  OUTPUT:
	RETVAL
 	
 
 
  
##
## Connect to broker
##
const char*
xs_connect( self, pApiTaskInfo )
	HV* self
   	MQISDPTI	*pApiTaskInfo

 PREINIT:
  	CONN_PARMS	*pCp = NULL;
  	MQISDPCH	handle = MQISDP_INV_CONN_HANDLE;
  	long        connMsgLength = 0;
  	SV**		svp = NULL;
 	SV*			sv = NULL;
 	int			rc = MQISDP_FAILED;
  	
  CODE:
  	/* length of Connect Messgae */
	connMsgLength = sizeof(CONN_PARMS);
	
	/* Create Connect data structure */
	pCp = (CONN_PARMS*)malloc( connMsgLength );
	pCp->strucLength = connMsgLength;



    /* Fill out parameters from hashref */
    svp = hv_fetch( self, "clientid", 8, 0 );
    if (svp && SvPOK(*svp))	strcpy( pCp->clientId, SvPV_nolen(*svp) );
	else		croak("'clientid' setting isn't available");
    
    svp = hv_fetch( self, "retry_count", 11, 0 );
    if (svp && SvIOK(*svp))	pCp->retryCount = SvIV(*svp);
	else		croak("'retry_count' setting isn't available");

    svp = hv_fetch( self, "retry_interval", 14, 0 );
    if (svp && SvIOK(*svp))	pCp->retryInterval = SvIV(*svp);
	else		croak("'retry_interval' setting isn't available");

    svp = hv_fetch( self, "keep_alive", 10, 0 );
    if (svp && SvIOK(*svp))	pCp->keepAliveTime = SvIV(*svp);
	else		croak("'keep_alive' setting isn't available");

    svp = hv_fetch( self, "host", 4, 0 );
    if (svp && SvPOK(*svp))	pCp->brokerHostname = SvPV_nolen(*svp);
	else		croak("'host' setting isn't available");

    svp = hv_fetch( self, "port", 4, 0 );
    if (svp && SvIOK(*svp))	pCp->brokerPort = SvIV(*svp);
	else		croak("'port' setting isn't available");

    svp = hv_fetch( self, "persist", 7, 0 );
    if (svp && SvOK(*svp)) {
		if (sv_isobject(*svp)) {
			pCp->pPersistFuncs = new_persistence_wrapper(*svp);
			sv=sv_setref_pv(newSV(0), "MQISDPTIPtr", (void *)pCp->pPersistFuncs);
			if (hv_store(self, "persist_info", 12, sv, 0) == NULL) {
				croak("persist_info not stored");
			}
		}
		else	croak("'persist' setting must be an object");
    }
    else	pCp->pPersistFuncs = NULL;

	/* Set options flags */
	pCp->options = MQISDP_NONE;
	svp = hv_fetch( self, "clean_start", 11, 0 );
	if (svp) {
		if (SvIV(*svp)) pCp->options |= MQISDP_CLEAN_START;
	} else {
		croak("'clean_start' setting isn't available");
	}

	/* Perform the connect */
	rc = MQIsdp_connect( &handle, pCp, pApiTaskInfo );
	free( pCp );


    /* Store connection handle pointer */
	sv=sv_setref_pv(newSV(0), "MQISDPCH", (void *)handle);
	if (hv_store(self, "handle", 6, sv, 0) == NULL) {
		croak("connection handle not stored");
	}
	
	/* Return result code as a string */
	RETVAL = get_status_string( rc );
	
  OUTPUT:
	RETVAL
	


##
## Disconnect from broker
##
const char*
xs_disconnect( self )
	HV* self

  PREINIT:
   	MQISDPCH	handle = MQISDP_INV_CONN_HANDLE;
 	int			rc = MQISDP_FAILED;

  CODE:
  	/* get the connection handle */
  	handle = get_handle_from_hv( self );  	

	if (handle) {  	
  		/* perform the disconnect */
  		rc = MQIsdp_disconnect( &handle );
  	
  		/* Undef 'handle' if its value now NULL */
  		if (handle==MQISDP_INV_CONN_HANDLE) hv_key_undef( self, "handle" );
	}
  
  	RETVAL = get_status_string( rc );
  	
  OUTPUT:
	RETVAL


##
## Free memory and Terminate threads
##
const char*
xs_terminate( self )
	HV* self

  PREINIT:

  CODE:
  	MQISDPTI *pApiTaskInfo = get_task_info_from_hv( self, "api_task_info" );
  	MQISDPTI *pSendTaskInfo = get_task_info_from_hv( self, "send_task_info" );
  	MQISDPTI *pRcvTaskInfo = get_task_info_from_hv( self, "recv_task_info" );
  	MQISDPTI *pPersistInfo = get_task_info_from_hv( self, "persist_info" );
  
  	/* Free the memory */
  	if (pApiTaskInfo) free( pApiTaskInfo );
  	if (pSendTaskInfo) free( pSendTaskInfo );
  	if (pRcvTaskInfo) free( pRcvTaskInfo );
	if (pPersistInfo) free( pPersistInfo );

	/* Undef them in the hash */
	hv_key_undef( self, "api_task_info");
	hv_key_undef( self, "send_task_info");
	hv_key_undef( self, "recv_task_info");
	hv_key_undef( self, "persist_info");

	/* Terminate threads and return result as a string */
  	RETVAL = get_status_string( MQIsdp_terminate() );
  	
  OUTPUT:
	RETVAL





##
## Subscribe to a topic
##
const char*
xs_subscribe( self, topic, qos )
	HV*		self
	char*	topic
	int		qos

  PREINIT:
  	MQISDPCH	handle = MQISDP_INV_CONN_HANDLE;
  	MQISDPMH	hMsg = 0;
  	SUB_PARMS	*pSp = NULL;
	int			bufSize = 0;
	int			rc = 0;
	
  CODE:
  	/* get the connection handle */
  	handle = get_handle_from_hv( self );  
  	
	/* Allocate memory for stucture */
	bufSize = sizeof(SUB_PARMS) + (2 * sizeof(long)) + strlen(topic);
	pSp = (SUB_PARMS*)malloc( bufSize );

	if (pSp) {
		char	*pTmpPtr = NULL;
		long	options = 0;
		long	tLength = 0;
	
		pSp->strucLength = bufSize;
	
        /* Set the topic length field */
        pTmpPtr = (char*)pSp + sizeof(long);
        tLength = strlen(topic);
        memcpy( pTmpPtr, &tLength, sizeof(long) );

        /* Set the topic field */
        pTmpPtr += sizeof(long);
        memcpy( pTmpPtr, topic, strlen(topic) );

        /* Set the options field */
        pTmpPtr += strlen(topic);
        switch ( qos ) {
			case 0: options |= MQISDP_QOS_0; break;
			case 1: options |= MQISDP_QOS_1; break;
			case 2: options |= MQISDP_QOS_2; break;
        }
        memcpy( pTmpPtr, &options, sizeof(long) );

		/* Subscribe */
		rc = MQIsdp_subscribe( handle, &hMsg, pSp );
		free( pSp );

	} else {
		rc = MQISDP_OUT_OF_MEMORY;
	}

	RETVAL = get_status_string(rc);
 	
  OUTPUT:
	RETVAL
 	
 
 
  
##
## Unsubscribe from a topic
##
const char*
xs_unsubscribe( self, topic )
	HV*		self
	char*	topic

  PREINIT:
  	MQISDPCH	handle = MQISDP_INV_CONN_HANDLE;
  	MQISDPMH	hMsg = 0;
  	UNSUB_PARMS	*pUp = NULL;
	int			bufSize = 0;
	int			rc = 0;
	
  CODE:
  	/* get the connection handle */
  	handle = get_handle_from_hv( self );  
  	
	/* Allocate memory for stucture */
	bufSize = sizeof(UNSUB_PARMS) + sizeof(long) + strlen(topic);
	pUp = (UNSUB_PARMS*)malloc( bufSize );

	if (pUp) {
		char	*pTmpPtr = NULL;
		long	tLength = 0;
	
		pUp->strucLength = bufSize;
	
        /* Set the topic length field */
        pTmpPtr = (char*)pUp + sizeof(long);
        tLength = strlen(topic);
        memcpy( pTmpPtr, &tLength, sizeof(long) );

        /* Set the topic field */
        pTmpPtr += sizeof(long);
        memcpy( pTmpPtr, topic, strlen(topic) );

		/* Unsubscribe */
		rc = MQIsdp_unsubscribe( handle, &hMsg, pUp );
		free( pUp );

	} else {
		rc = MQISDP_OUT_OF_MEMORY;
	}

	RETVAL = get_status_string(rc);
 	
  OUTPUT:
	RETVAL



##
## Receive a publication
##
HV*
xs_receivePub( self )
	HV*		self

  PREINIT:
  	MQISDPCH	handle = MQISDP_INV_CONN_HANDLE;
  	HV			*hash = newHV();
  	SV			*sv = NULL;
  	
	int			rc = 0;
	int			stillWaiting = 1;
	long		timeToWait = 10000;	// 10 Seconds
	
	long		dataLength = 0;
	long		topicLength = 0;
	long		pubOptions = 0;
	long		bufferSz = 1024;
	char		*pBuffer = NULL;


  CODE:
  	/* get the connection handle */
  	handle = get_handle_from_hv( self );  
  	
  	
  	/* Allocate some memory to store messgae */
  	pBuffer = (char*)malloc( bufferSz );
  	
  	
  	/* Wait for a message */
  	while( stillWaiting )
	{
  		
  		rc = MQIsdp_receivePub( handle, timeToWait, &pubOptions, &topicLength, &dataLength, bufferSz-1, pBuffer );

		/* Not sure why this is required */
		dataLength -= topicLength;

  		switch( rc ) {
  			case MQISDP_DATA_TRUNCATED:
  				bufferSz = dataLength+topicLength+1;
  				if (pBuffer == NULL) {
  					pBuffer = (char*)malloc( bufferSz );
  				} else {
  					pBuffer = (char*)realloc( pBuffer, bufferSz );
   				}
  			break;
  			
  			case MQISDP_NO_PUBS_AVAILABLE:
  				/* Do nothing */
  			break;
  			
  			case MQISDP_PUBS_AVAILABLE:
  			case MQISDP_OK:
  			
   				/* Store the options */
   				sv = newRV_noinc((SV*)options_to_av( pubOptions ));
  				if (hv_store(hash, "options", 7, sv, 0) == NULL) {
					croak("xs_receivePub: options not stored");
				}

 				/* Store the topic length */
				sv=newSViv(topicLength);
				if (hv_store(hash, "topic_length", 12, sv, 0) == NULL) {
					croak("xs_receivePub: topic_length not stored");
				}

				/* Store the topic */
				sv=newSVpv(pBuffer, topicLength);
				if (hv_store(hash, "topic", 5, sv, 0) == NULL) {
					croak("xs_receivePub: topic not stored");
				}
	
				/* Store the data length */
				sv=newSViv(dataLength);
				if (hv_store(hash, "data_length", 8, sv, 0) == NULL) {
					croak("xs_receivePub: data_length not stored");
				}
			
				/* Store the data */
				sv=newSVpv(pBuffer+topicLength, dataLength);
				if (hv_store(hash, "data", 4, sv, 0) == NULL) {
					croak("xs_receivePub: data not stored");
				}

				/* FALLTHROUGH */

  			default:
  				
				/* Store the status */
				sv=newSVpv(get_status_string(rc), 0);
				if (hv_store(hash, "status", 6, sv, 0) == NULL) {
					croak("xs_receivePub: status not stored");
				}
 				
  				stillWaiting = 0;
  			break;
  		}
  		
   	}
  	

	/* Free the message buffer */
	if (pBuffer) free( pBuffer );

	RETVAL = hash;
 	
  OUTPUT:
	RETVAL



##
## Publish a message
## Note that you cannot send or queue more than MSP_DEFAULT_MAX_OUTQ_SZ
## bytes (defined as 32768 in mspsh.h), or you will get Q_FULL response
##
void
xs_publish( self, data, topic, qos, retain )
	HV*		self
	char*		data
	char*		topic
	int		qos
	int		retain
	
  PREINIT:
  	MQISDPCH	handle = MQISDP_INV_CONN_HANDLE;
  	MQISDPMH	hMsg = MQISDP_INV_MSG_HANDLE;
  	PUB_PARMS	Pp;
	int		rc = 0;
	
  PPCODE:
	
  	/* get the connection handle */
  	handle = get_handle_from_hv( self );

	Pp.strucLength = sizeof(PUB_PARMS);
	
	/* Set the options field */
	Pp.options = MQISDP_NONE;
	switch ( qos ) {
			case 0: Pp.options |= MQISDP_QOS_0; break;
			case 1: Pp.options |= MQISDP_QOS_1; break;
			case 2: Pp.options |= MQISDP_QOS_2; break;
	}
	if ( retain ) {
			Pp.options |= MQISDP_RETAIN;
	}

	/* Set the topic length field */
	Pp.topicLength = strlen(topic);

	/* Set the topic field */
	Pp.topic = topic;

	/* Set the data length field */
	Pp.dataLength = strlen(data);

	/* Set the data field */
	Pp.data = data;

	/* Publish */
	rc = MQIsdp_publish( handle, &hMsg, &Pp );

	/* Return two values as an array */	
	XPUSHs( sv_2mortal( newSVpv( get_status_string(rc), 0 ) ) );
	XPUSHs( sv_2mortal( newSVnv( hMsg ) ) );

##
## Check status of a message published at QOS 1/2
## Returns one of:
## DELIVERED, IN_PROGRESS, RETRYING, MSG_HANDLE_ERROR, CONN_HANDLE_ERROR
##
const char*
xs_getMsgStatus( self, hMsg )
	HV*		self
  	long		hMsg
	
  PREINIT:
  	MQISDPCH	handle = MQISDP_INV_CONN_HANDLE;
	int		rc = MQISDP_INV_MSG_HANDLE;
	
  CODE:
	
  	/* get the connection handle */
  	handle = get_handle_from_hv( self );
	
	rc = MQIsdp_getMsgStatus( handle, hMsg );
	
	RETVAL = get_status_string(rc);
 	
  OUTPUT:
	RETVAL

