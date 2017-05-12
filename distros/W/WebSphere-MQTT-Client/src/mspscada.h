/****************************************************************************/
/*                                                                          */
/* Program name: MQIsdp protocol C Language implementation                  */
/*                                                                          */
/* Description: This header file contains functions prototypes for building */
/* and parsing MQIsdp messgaes, as well as useful macros.                   */
/*                                                                          */
/*  Statement:  Licensed Materials - Property of IBM                        */
/*                                                                          */
/*              MQSeries SupportPac IA93                                    */
/*              (C) Copyright IBM Corp. 2002                                */
/*                                                                          */
/****************************************************************************/
/* Version @(#) IA93/ship/mspscada.h, SupportPacs, S000 1.2 03/08/26 16:38:27  */
/*                                                                          */
/* Function:                                                                */
/*                                                                          */
/* Provides macros that are useful when constructing or parsing MQIsdp      */
/* messages.                                                                */
/*                                                                          */
/****************************************************************************/
/*                                                                          */
/* Change history:                                                          */
/*                                                                          */
/* V1.0   19-02-2003  IRH  Initial release                                  */
/*                                                                          */
/*==========================================================================*/
/* Module Name: mspscada.h                                                  */
/* This header file defines MQIsdp specific macros to make the */
/* task of constructing/parsing a MQIsdp message simpler.      */
                                                      
/* Length boundaries for the remaining length field of the SCADA fixed header */
#define MSP_SCADA_BYTE_1 127L
#define MSP_SCADA_BYTE_2 16383L
#define MSP_SCADA_BYTE_3 2097151L
#define MSP_SCADA_BYTE_4 268435455L

/* A macro to calulate the size of the fixed header */
#define MSP_CALC_FHEADER_LENGTH( DLen, FHLen ) { \
    if ( DLen <= MSP_SCADA_BYTE_1 ) {            \
        FHLen = 2;                               \
    } else if ( DLen <= MSP_SCADA_BYTE_2 ) {     \
        FHLen = 3;                               \
    } else if ( DLen <= MSP_SCADA_BYTE_3 ) {     \
        FHLen = 4;                               \
    } else if ( DLen <= MSP_SCADA_BYTE_4 ) {     \
        FHLen = 5;                               \
    } else {                                     \
        FHLen = -1;                              \
    }                                            \
}
    
/* define the protocol name as it appears on the wire */
#define MSP_PROTOCOL_NAME      "MQIsdp"
#define MSP_PROTOCOL_NAME_SZ   6
#define MSP_PROTOCOL_VERSION_3 0x03

/* Some response flags specific to CONNACK */
#define MSP_CONN_ACCEPTED        0x00
#define MSP_CONN_REFUSED_VERSION 0x01
#define MSP_CONN_REFUSED_ID      0x02
#define MSP_CONN_REFUSED_BROKER  0x03

/* define all the SCADA message types */
#define MSP_CONNECT     0x10
#define MSP_CONNACK     0x20
#define MSP_PUBLISH     0x30
#define MSP_PUBACK      0x40
#define MSP_PUBREC      0x50
#define MSP_PUBREL      0x60
#define MSP_PUBCOMP     0x70
#define MSP_SUBSCRIBE   0x80
#define MSP_SUBACK      0x90
#define MSP_UNSUBSCRIBE 0xA0
#define MSP_UNSUBACK    0xB0
#define MSP_PINGREQ     0xC0
#define MSP_PINGRESP    0xD0
#define MSP_DISCONNECT  0xE0

/* Mask to get the message type from a MQIsdp message */
#define MSP_GET_MSG_TYPE 0xF0

/* Fixed header options */
#define MSPF_RETAIN     0x01
#define MSPF_QOS_1      0x02
#define MSPF_QOS_2      0x04
#define MSPF_DUPLICATE  0x08

/* Variable header connect options */
#define MSPC_WILL_RETAIN     0x20
#define MSPC_WILL            0x04
#define MSPC_CLEAN_START     0x02
#define MSPC_CLEAN_START_OFF 0xFD /* AND mask - turn off bit 1 */
#define MSPC_QOS_0           0xE7 /* AND mask - turn off bits 3 and 4 */
#define MSPC_QOS_1           0x08
#define MSPC_QOS_2           0x10

/* Subscribe payload QoS options */
#define MSPS_QOS_0       0x00
#define MSPS_QOS_1       0x01
#define MSPS_QOS_2       0x02

int mspSendPublishResponse( HCONNCB *pHconn, RPQ* pRipqEntry, u_short wmqttMsgId );
int mspSendPubReceivedResponse( HCONNCB *pHconn, u_short msgId );
int mspSendPubReleaseResponse( HCONNCB *pHconn, u_short msgId );
int mspSendPingResponse( HCONNCB *pHconn );
int mspUTFEncodeString( u_short bufLen, char *buf, char *outBuf );
int mspUTFDecodeString( u_short *bufLen, char *bufToDecode, char **ppBuffer );
      
