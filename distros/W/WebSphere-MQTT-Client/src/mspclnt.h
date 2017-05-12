/****************************************************************************/
/*                                                                          */
/* Program name: MQIsdp protocol C Language implementation                  */
/*                                                                          */
/* Description: This header file contains the structure definition for a    */
/* connection handle.                                                       */
/*                                                                          */
/*  Statement:  Licensed Materials - Property of IBM                        */
/*                                                                          */
/*              MQSeries SupportPac IA93                                    */
/*              (C) Copyright IBM Corp. 2002                                */
/*                                                                          */
/****************************************************************************/
/* Version @(#) IA93/ship/mspclnt.h, SupportPacs, S000 1.2 03/08/26 16:38:17  */
/*                                                                          */
/* Function:                                                                */
/*                                                                          */
/* Defines the connection handle that is passed back to the client          */
/* application.                                                             */
/*                                                                          */
/****************************************************************************/
/*                                                                          */
/* Change history:                                                          */
/*                                                                          */
/* V1.0   19-02-2003  IRH  Initial release                                  */
/*                                                                          */
/*==========================================================================*/
/* Module Name: mspclnt.h                                                   */
#include <mspsh.h>

/* This header file defines the Client Control Block which holds connection   */
/* information required by the API. The address of this structure is returned */
/* as the connection handle.                                                  */
typedef struct struct_scd {
    MSPCMN   comParms;
    IPCCB    ipcCb;
    #ifdef MSP_SINGLE_THREAD
    HCONNCB *pSendHconn;
    char     mspIpcBuffer[sizeof(CB_HEAD)];    
    #endif
} MSPCCB;

