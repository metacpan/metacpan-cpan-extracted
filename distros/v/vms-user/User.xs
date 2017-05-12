#ifdef __cplusplus
extern "C" {
#endif
#include <starlet.h>
#include <descrip.h>
#include <uaidef.h>
#include <ssdef.h>
#include <stsdef.h>
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

typedef  struct {short   buflen,          /* Length of output buffer */
                         itmcode;         /* Item code */
                 void    *buffer;         /* Buffer address */
                 void    *retlen;         /* Return length address */
               } ITMLST;

typedef struct {char  *ItemName;         /* Name of the item we're getting */
                unsigned short *ReturnLength; /* Pointer to the return */
                                              /* buffer length */
                void  *ReturnBuffer;     /* generic pointer to the returned */
                                         /* data */
                int   ReturnType;        /* The type of data in the return */
                                         /* buffer */
                int   ItemListEntry;     /* Index of the entry in the item */
                                         /* list we passed to syscall */
              } FetchedItem; /* Use this keep track of the items in the */
                             /* 'grab everything' GETDVI call */ 

#define user_bit_test(a, b, c) \
{ \
    if (c & UIC$M_##b) \
    hv_store(a, #b, strlen(#b), &sv_yes, 0); \
    else \
    hv_store(a, #b, strlen(#b), &sv_no, 0);}   

/* Macro to expand out entries for generic_bitmap_encode */
#define UAI_D(a) { if (!strncmp(FlagName, #a, FlagLen)) { \
                       EncodedValue[0] = EncodedValue[0] | DMT$M_##a; \
                       break; \
                     } \
                 }

/* Macro to define an entry in the user info array */
#define UAI_ENT(a, b, c) {#a, UAI$_##a, b, c}

#define IS_STRING 1
#define IS_LONGWORD 2
#define IS_QUADWORD 3
#define IS_WORD 4
#define IS_BYTE 5
#define IS_VMSDATE 6
#define IS_BITMAP 7   /* Each bit in the return value indicates something */
#define IS_ENUM 8     /* Each returned value has a name, and we ought to */
                      /* return the name instead of the value */
#define IS_ODD 9      /* A catchall */
#define IS_COUNTSTRING 10 /* A counted string--first byte's the count */

struct GenericID {
  char *ItemName; /* Pointer to the item name */
  int  SyscallValue;      /* Value to use in the getDVI item list */
  int  BufferLen;     /* Length the return va buf needs to be. (no nul */
                      /* terminators, so must be careful with the return */
                      /* values. */
  int  ReturnType;    /* Type of data the item returns */
};


struct GenericID UserInfoList[] = {
  UAI_ENT(ACCOUNT, 32, IS_STRING),
  UAI_ENT(ASTLM, 2, IS_WORD),
  UAI_ENT(BATCH_ACCESS_P, 3, IS_ODD),
  UAI_ENT(BATCH_ACCESS_S, 3, IS_ODD),
  UAI_ENT(BIOLM, 2, IS_WORD),
  UAI_ENT(BYTLM, 4, IS_LONGWORD),
  UAI_ENT(CLITABLES, 32, IS_COUNTSTRING),
  UAI_ENT(CPUTIM, 4, IS_LONGWORD),
  UAI_ENT(DEFCLI, 32, IS_COUNTSTRING),
  UAI_ENT(DEFDEV, 32, IS_COUNTSTRING),
  UAI_ENT(DEFDIR, 64, IS_COUNTSTRING),
  UAI_ENT(DEF_PRIV, 8, IS_QUADWORD),
  UAI_ENT(DFWSCNT, 4, IS_LONGWORD),
  UAI_ENT(DIOLM, 2, IS_WORD),
  UAI_ENT(DIALUP_ACCESS_P, 3, IS_ODD),
  UAI_ENT(DIALUP_ACCESS_S, 3, IS_ODD),
  UAI_ENT(ENCRYPT, 1, IS_ENUM),
  UAI_ENT(ENCRYPT2, 1, IS_ENUM),
  UAI_ENT(ENQLM, 2, IS_WORD),
  UAI_ENT(EXPIRATION, 8, IS_VMSDATE),
  UAI_ENT(FILLM, 2, IS_WORD),
  UAI_ENT(FLAGS, 4, IS_BITMAP),
  UAI_ENT(JTQUOTA, 4, IS_LONGWORD),
  UAI_ENT(LASTLOGIN_I, 8, IS_VMSDATE),
  UAI_ENT(LASTLOGIN_N, 8, IS_VMSDATE),
  UAI_ENT(LGICMD, 64, IS_COUNTSTRING),
  UAI_ENT(LOCAL_ACCESS_P, 3, IS_ODD),
  UAI_ENT(LOCAL_ACCESS_S, 3, IS_ODD),
  UAI_ENT(LOGFAILS, 2, IS_WORD),
  UAI_ENT(MAXACCTJOBS, 2, IS_WORD),
  UAI_ENT(MAXDETACH, 2, IS_WORD),
  UAI_ENT(MAXJOBS, 2, IS_WORD),
  UAI_ENT(NETWORK_ACCESS_P, 3, IS_ODD),
  UAI_ENT(NETWORK_ACCESS_S, 3, IS_ODD),
  UAI_ENT(OWNER, 32, IS_COUNTSTRING),
  UAI_ENT(PBYTLM, 4, IS_LONGWORD),
  UAI_ENT(PGFLQUOTA, 4, IS_LONGWORD),
  UAI_ENT(PRCCNT, 4, IS_LONGWORD),
  UAI_ENT(PRI, 1, IS_BYTE),
  UAI_ENT(PRIV, 8, IS_QUADWORD),
  UAI_ENT(PWD, 8, IS_STRING),
  UAI_ENT(PWD_DATE, 8, IS_VMSDATE),
  UAI_ENT(PWD_LENGTH, 4, IS_LONGWORD),
  UAI_ENT(PWD_LIFETIME, 8, IS_VMSDATE),
  UAI_ENT(PWD2, 8, IS_QUADWORD),
  UAI_ENT(PWD2_DATE, 8, IS_VMSDATE),
  UAI_ENT(QUEPRI, 1, IS_BYTE),
  UAI_ENT(REMOTE_ACCESS_P, 3, IS_ODD),
  UAI_ENT(REMOTE_ACCESS_S, 3, IS_ODD),
  UAI_ENT(SALT, 2, IS_WORD),
  UAI_ENT(SHRFILLM, 2, IS_WORD),
  UAI_ENT(TQCNT, 2, IS_WORD),
  UAI_ENT(UIC, 4, IS_LONGWORD),
  UAI_ENT(USER_DATA, 255, IS_STRING),
  UAI_ENT(WSEXTENT, 4, IS_LONGWORD),
  UAI_ENT(WSQUOTA, 4, IS_LONGWORD),
  {NULL, 0, 0, 0}
};

char *MonthNames[12] = {
  "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep",
  "Oct", "Nov", "Dec"} ;

/* Globals to track how many different pieces of info we can return, as */
/* well as how much space we'd need to grab to store it. */
static int UserInfoCount = 0;
static int UserInfoMallocSize = 0;

/* Macro to fill in a 'traditional' item-list entry */
#define init_itemlist(ile, length, code, bufaddr, retlen_addr) \
{ \
    (ile)->buflen = (length); \
    (ile)->itmcode = (code); \
    (ile)->buffer = (bufaddr); \
    (ile)->retlen = (retlen_addr) ;}

/* Take a pointer to a bitmap hash (like decode_bitmap gives), an item */
/* code, and a pointer to the output buffer and encode the bitmap */
void
generic_bitmap_encode(HV * FlagHV, int ItemCode, void *Buffer)
{
  char *FlagName;
  I32 FlagLen;
  int *EncodedValue; /* Pointer to an integer

  /* Shut Dec C up */
  FlagName = NULL;

  /* Buffer's a pointer to an integer array, really it is */
  EncodedValue = Buffer;

  /* Initialize our hash iterator */
  hv_iterinit(FlagHV);

  /* Rip through the hash */
  while (hv_iternextsv(FlagHV, &FlagName, &FlagLen)) {
    
    switch (ItemCode) {
    default:
      croak("Invalid item specified");
    }
  }
}

/* Take a pointer to an itemlist, a hashref, and some flags, and build up */
/* an itemlist from what's in the hashref. Buffer space for the items is */
/* allocated, as are the length shorts and stuff. If the hash entries have */
/* values, those values are copied into the buffers, too. Returns the */
/* number of items stuck in the itemlist */
int build_itemlist(struct GenericID InfoList[], ITMLST *ItemList, HV *HashRef)
{
  /* standard, dopey index variable */
  int i = 0;
  int ItemListIndex = 0;
  char *TempCharPointer;
  unsigned int TempStrLen;
  
  int TempNameLen;
  SV *TempSV;
  unsigned short *TempLen;
  int ItemCode;
  char *TempBuffer;
  char StringLength;
  int BufferLength;
  long TempLong;
  struct dsc$descriptor_s TimeStringDesc;
  int Status;
  int CopyData;

  for(i = 0; InfoList[i].ItemName; i++) {
    TempNameLen = strlen(InfoList[i].ItemName);
    /* Figure out some stuff. Avoids duplication, and makes the macro */
    /* expansion of init_itemlist a little easier */
    ItemCode = InfoList[i].SyscallValue;
    CopyData = TRUE;
    switch(InfoList[i].ReturnType) {
      /* Quadwords are treated as strings for right now */
    case IS_QUADWORD:
    case IS_COUNTSTRING:
    case IS_STRING:
      /* Allocate us some buffer space */
      Newz(NULL, TempBuffer, InfoList[i].BufferLen, char);
      Newz(NULL, TempLen, 1, unsigned short);
      
      BufferLength = InfoList[i].BufferLen;
      
      /* Set the string buffer to spaces */
      memset(TempBuffer, ' ', InfoList[i].BufferLen);
        
      /* If we're copying data, then fetch it and stick it in the buffer */
      if (CopyData) {
        TempSV = *hv_fetch(HashRef,
                           InfoList[i].ItemName,
                           TempNameLen, FALSE);
        TempCharPointer = SvPV(TempSV, TempStrLen);
        
        /* If there was something in the SV, then copy it over */
        if (TempStrLen) {
          BufferLength = TempStrLen < InfoList[i].BufferLen
            ? TempStrLen : InfoList[i].BufferLen;
          Copy(TempCharPointer, TempBuffer, BufferLength, char);
        }
      }
      
      init_itemlist(&ItemList[ItemListIndex],
                    BufferLength,
                    ItemCode,
                    TempBuffer,
                    TempLen);
      break;
    case IS_VMSDATE:
      /* Allocate us some buffer space */
      Newz(NULL, TempBuffer, InfoList[i].BufferLen, char);
      Newz(NULL, TempLen, 1, unsigned short);
      
      if (CopyData) {
        TempSV = *hv_fetch(HashRef,
                           InfoList[i].ItemName,
                           TempNameLen, FALSE);
        TempCharPointer = SvPV(TempSV, TempStrLen);
        
        /* Fill in the time string descriptor */
        TimeStringDesc.dsc$a_pointer = TempCharPointer;
        TimeStringDesc.dsc$w_length = TempStrLen;
        TimeStringDesc.dsc$b_dtype = DSC$K_DTYPE_T;
        TimeStringDesc.dsc$b_class = DSC$K_CLASS_S;
        
        /* Convert from an ascii rep to a VMS quadword date structure */
        Status = sys$bintim(&TimeStringDesc, TempBuffer);
        if (Status != SS$_NORMAL) {
          croak("Error converting time!");
        }
      }
      
      init_itemlist(&ItemList[ItemListIndex],
                    InfoList[i].BufferLen,
                    ItemCode,
                    TempBuffer,
                    TempLen);
      break;
      
    case IS_LONGWORD:
      /* Allocate us some buffer space */
      Newz(NULL, TempBuffer, InfoList[i].BufferLen, char);
      Newz(NULL, TempLen, 1, unsigned short);
      
      if (CopyData) {
        TempSV = *hv_fetch(HashRef,
                           InfoList[i].ItemName,
                           TempNameLen, FALSE);
        TempLong = SvIVX(TempSV);
        
        /* Set the value */
        *TempBuffer = TempLong;
      }
      
      init_itemlist(&ItemList[ItemListIndex],
                    InfoList[i].BufferLen,
                    ItemCode,
                    TempBuffer,
                    TempLen);
      break;
      
    case IS_BITMAP:
      /* Allocate us some buffer space */
      Newz(NULL, TempBuffer, InfoList[i].BufferLen, char);
      Newz(NULL, TempLen, 1, unsigned short);
      
      if (CopyData) {
        TempSV = *hv_fetch(HashRef,
                           InfoList[i].ItemName,
                           TempNameLen, FALSE);
        
        /* Is the SV an integer? If so, then we'll use that value. */
        /* Otherwise we'll assume that it's a hashref of the sort that */
        /* generic_bitmap_decode gives */
        if (SvIOK(TempSV)) {
          TempLong = SvIVX(TempSV);
          /* Set the value */
          *TempBuffer = TempLong;
        } else {
          generic_bitmap_encode((HV *)SvRV(TempSV), ItemCode, TempBuffer);
        }
      }
      
      init_itemlist(&ItemList[ItemListIndex],
                    InfoList[i].BufferLen,
                    ItemCode,
                    TempBuffer,
                    TempLen);
      break;
      
    default:
      croak("Unknown item type found!");
      break;
    }
    ItemListIndex++;
  }

  return(ItemListIndex);
}

/* Takes an item list pointer and a count of items, and frees the buffer */
/* memory and length buffer memory */
void
tear_down_itemlist(ITMLST *ItemList, int NumItems)
{
  int i;

  for(i=0; i < NumItems; i++) {
    if(ItemList[i].buffer != NULL)
      Safefree(ItemList[i].buffer);
    if(ItemList[i].retlen != NULL)
      Safefree(ItemList[i].retlen);
  }
}
         
char *
de_enum(int UAICode, int UAIVal)
{
  switch(UAICode) {
  case UAI$_ENCRYPT:
    switch (UAIVal) {
    case UAI$C_AD_II:
      return "AD_II";
    case UAI$C_PURDY:
      return "PURDY";
    case UAI$C_PURDY_V:
      return "PURDY_V";
    case UAI$C_PURDY_S:
      return "PURDY_S";
    default:
      return "Unknown";
    }
  case UAI$_ENCRYPT2:
    switch (UAIVal) {
    case UAI$C_AD_II:
      return "AD_II";
    case UAI$C_PURDY:
      return "PURDY";
    case UAI$C_PURDY_V:
      return "PURDY_V";
    case UAI$C_PURDY_S:
      return "PURDY_S";
    default:
      return "Unknown";
    }
  default:
    return "Unknown";
  }
}

void
tote_up_items()
{
  for(UserInfoCount = 0; UserInfoList[UserInfoCount].ItemName;
      UserInfoCount++) {
    /* While we're here, we might as well get a generous estimate of how */
    /* much space we'll need for all the buffers */
    UserInfoMallocSize += UserInfoList[UserInfoCount].BufferLen;
    /* Add in a couple extra, just to be safe */
    UserInfoMallocSize += 8;
  }
}    

/* This routine takes a DVI item list ID and the value that wants to be */
/* de-enumerated and returns a pointer to an SV with the de-enumerated name */
/* in it */
SV *
enum_name(long UAICode, long UAIVal)
{
  SV *WorkingSV = newSV(10);
  char TempSprintfBuffer[512];
  switch(UAICode) {
  case UAI$_ENCRYPT:
  case UAI$_ENCRYPT2:
    switch (UAIVal) {
    case UAI$C_AD_II:
      sv_setpv(WorkingSV,  "AD_II");
      break;
    case UAI$C_PURDY:
      sv_setpv(WorkingSV,  "PURDY");
      break;
    case UAI$C_PURDY_V:
      sv_setpv(WorkingSV,  "PURDY_V");
      break;
    case UAI$C_PURDY_S:
      sv_setpv(WorkingSV,  "PURDY_S");
      break;
    default:
      sprintf(TempSprintfBuffer, "Unknown encrypt type (%i)",UAIVal); 
      sv_setpv(WorkingSV,  TempSprintfBuffer);
      break;
    }
    break;
  default:
    sv_setpv(WorkingSV,  "Unknown");
  }
  
  return WorkingSV;
}

/* This routine gets passed a pre-cleared array that's big enough for all */
/* the pieces we'll fill in, and that has the input parameter stuck in */
/* entry 0. We allocate the memory and fill in the rest of the array, and */
/* pass back a hash that has all the return results in it. */
SV *
generic_getuai_call(ITMLST *ListOItems, int InfoCount, SV *UserName)

{
  FetchedItem *OurDataList;
  unsigned short *ReturnLengths;
  int i, LocalIndex;
  unsigned int PVLength;
  int status;
  HV *AllPurposeHV;
  SV *ReturnedSV;
  unsigned short ReturnedTime[7];
  char AsciiTime[100];
  char QuadWordString[65];
  char *TempCharPointer;
  short *TempWordPointer;
  long *TempLongPointer;
  __int64 *TempQuadPointer;
  char *TempStringBuffer;
  char StringLength;
  long EnumVal;
  struct dsc$descriptor_s UserDesc;

  UserDesc.dsc$a_pointer = SvPV(UserName, PVLength);
  UserDesc.dsc$w_length = PVLength;
  UserDesc.dsc$b_dtype = DSC$K_DTYPE_T;
  UserDesc.dsc$b_class = DSC$K_CLASS_S;
  
  LocalIndex = 0;
  
  /* Allocate the local tracking array */
  OurDataList = malloc(sizeof(FetchedItem) * InfoCount);
  memset(OurDataList, 0, sizeof(FetchedItem) * InfoCount);
  
  /* We also need room for the buffer lengths */
  ReturnLengths = malloc(sizeof(short) * InfoCount);
  memset(ReturnLengths, 0, sizeof(short) * InfoCount);
  
  
  /* Fill in the item list and the tracking list */
  for (i = 0; UserInfoList[i].ItemName; i++) {
    /* Allocate the return data buffer and zero it. Can be oddly
       sized, so we use the system malloc instead of New */
    OurDataList[LocalIndex].ReturnBuffer =
      malloc(UserInfoList[i].BufferLen);
    memset(OurDataList[LocalIndex].ReturnBuffer, 0,
           UserInfoList[i].BufferLen); 
    
    /* Note some important stuff (like what we're doing) in our local */
    /* tracking array */
    OurDataList[LocalIndex].ItemName =
      UserInfoList[i].ItemName;
    OurDataList[LocalIndex].ReturnLength =
      &ReturnLengths[LocalIndex];
    OurDataList[LocalIndex].ReturnType =
      UserInfoList[i].ReturnType;
    OurDataList[LocalIndex].ItemListEntry = i;
    
    /* Fill in the item list */
    init_itemlist(&ListOItems[LocalIndex], UserInfoList[i].BufferLen,
                  UserInfoList[i].SyscallValue,
                  OurDataList[LocalIndex].ReturnBuffer,
                  &ReturnLengths[LocalIndex]);
    
    /* Increment the local index */
    LocalIndex++;
  }

  /* Make the GETQUIW call */
  status = sys$getuai(0, NULL, &UserDesc, ListOItems, NULL, NULL, NULL);

  /* Did it go OK? */
  if (status == SS$_NORMAL) {
    /* Looks like it */
    AllPurposeHV = newHV();
    for (i = 0; i < LocalIndex; i++) {
      switch(OurDataList[i].ReturnType) {
      case IS_ODD:
      case IS_STRING:
        /* copy the return string into a temporary buffer with C's string */
        /* handling routines. For some reason $GETQUI returns values with */
        /* embedded nulls and bogus lengths, which is really */
        /* strange. Anyway, this is a cheap way to see how long the */
        /* string is without doing a strlen(), which might fall off the */
        /* end of the world */
        TempStringBuffer = malloc(*(OurDataList[i].ReturnLength) + 1);
        memset(TempStringBuffer, 0, *(OurDataList[i].ReturnLength) + 1);
        strncpy(TempStringBuffer, OurDataList[i].ReturnBuffer,
                *(OurDataList[i].ReturnLength));
        if (strlen(TempStringBuffer) < *OurDataList[i].ReturnLength)
          *OurDataList[i].ReturnLength = strlen(TempStringBuffer);
        free(TempStringBuffer);
        /* Check to make sure we got something back, otherwise set the */
        /* value to undef */
        if (*OurDataList[i].ReturnLength) {
          hv_store(AllPurposeHV, OurDataList[i].ItemName,
                   strlen(OurDataList[i].ItemName),
                   newSVpv(OurDataList[i].ReturnBuffer,
                           *(OurDataList[i].ReturnLength)), 0);
        } else {
          hv_store(AllPurposeHV, OurDataList[i].ItemName,
                   strlen(OurDataList[i].ItemName),
                   &PL_sv_undef, 0);
        }
        break;
      case IS_COUNTSTRING:
        /* Check to make sure we got something back, otherwise set the */
        /* value to undef */        
        if (*OurDataList[i].ReturnLength) {
          StringLength = *(char *)OurDataList[i].ReturnBuffer;
          hv_store(AllPurposeHV, OurDataList[i].ItemName,
                   strlen(OurDataList[i].ItemName),
                   newSVpv((char *)OurDataList[i].ReturnBuffer + 1,
                           StringLength), 0);
        } else {
          hv_store(AllPurposeHV, OurDataList[i].ItemName,
                   strlen(OurDataList[i].ItemName),
                   &PL_sv_undef, 0);
        }
        break;
      case IS_VMSDATE:
        sys$numtim(ReturnedTime, OurDataList[i].ReturnBuffer);
        sprintf(AsciiTime, "%02hi-%s-%hi %02hi:%02hi:%02hi.%hi",
                ReturnedTime[2], MonthNames[ReturnedTime[1] - 1],
                ReturnedTime[0], ReturnedTime[3], ReturnedTime[4],
                ReturnedTime[5], ReturnedTime[6]);
        hv_store(AllPurposeHV, OurDataList[i].ItemName,
                 strlen(OurDataList[i].ItemName),
                 newSVpv(AsciiTime, 0), 0);
        break;
      case IS_ENUM:
        if ( 1 == *OurDataList[i].ReturnLength) {
          EnumVal = *(char *)OurDataList[i].ReturnBuffer;
        } else {
           if ( 4 == *OurDataList[i].ReturnLength) {
             EnumVal = *(short *)OurDataList[i].ReturnBuffer;
           } else {
             if ( 4 == *OurDataList[i].ReturnLength) {
               EnumVal = *(long *)OurDataList[i].ReturnBuffer;
             }
           }
         }
        hv_store(AllPurposeHV, OurDataList[i].ItemName,
                 strlen(OurDataList[i].ItemName),
                 enum_name(UserInfoList[i].SyscallValue,
                           EnumVal), 0);
        break;
      case IS_BITMAP:
      case IS_LONGWORD:
        TempLongPointer = OurDataList[i].ReturnBuffer;
        hv_store(AllPurposeHV, OurDataList[i].ItemName,
                 strlen(OurDataList[i].ItemName),
                 newSViv(*TempLongPointer),
                 0);
        break;
      case IS_WORD:
        TempWordPointer = OurDataList[i].ReturnBuffer;
        hv_store(AllPurposeHV, OurDataList[i].ItemName,
                 strlen(OurDataList[i].ItemName),
                 newSViv(*TempWordPointer),
                 0);
        break;
      case IS_BYTE:
        TempCharPointer = OurDataList[i].ReturnBuffer;
        hv_store(AllPurposeHV, OurDataList[i].ItemName,
                 strlen(OurDataList[i].ItemName),
                 newSViv(*TempCharPointer),
                 0);
        break;
      case IS_QUADWORD:
        TempQuadPointer = OurDataList[i].ReturnBuffer;
        sprintf(QuadWordString, "%llu", *TempQuadPointer);
        hv_store(AllPurposeHV, OurDataList[i].ItemName,
                 strlen(OurDataList[i].ItemName),
                 newSVpv(QuadWordString, 0), 0);
        break;
        
      }
    }
    /* Set the returned status and return the HV we built */
    ReturnedSV = newRV_noinc((SV *) AllPurposeHV);
  } else {
    /* Well, things weren't fine and dandy. */
    if (SS$_BADPARAM == status)
      printf("Badparam\n");
    if (RMS$_RSZ == status)
      printf("RSZ\n");
    if (SS$_ACCVIO == status)
      printf("ACCVIO\n");
    SETERRNO(EVMSERR, status);
    ReturnedSV = &PL_sv_undef;
  }

  
  /* Free up our allocated memory */
  for(i = 0; i < InfoCount; i++) {
    free(OurDataList[i].ReturnBuffer);
  }
  free(OurDataList);
  free(ReturnLengths);

  return(ReturnedSV);
}


MODULE = VMS::User		PACKAGE = VMS::User		

void
user_info(UserName)
     SV *UserName
   PPCODE:
{
  
  ITMLST *ListOItems;
  unsigned short ReturnBufferLength = 0;
  unsigned int UserFlags;
  unsigned short UserFlagsLength;
  unsigned int Status;
  unsigned int ReturnedUAIStatus;
  unsigned int SubType;
  
  /* If we've not gotten the count of items, go get it now */
  if (UserInfoCount == 0) {
    tote_up_items();
  }

  /* We need room for our item list */
  ListOItems = malloc(sizeof(ITMLST) * (UserInfoCount + 1));
  memset(ListOItems, 0, sizeof(ITMLST) * (UserInfoCount + 1));

  /* Make the call to the generic fetcher and make it the return */
  /* value. We don't need to go messing with the item list, since what we */
  /* used for the last call is OK to pass along to this one. */
  XPUSHs(generic_getuai_call(ListOItems, UserInfoCount, UserName));
  /* Give back the allocated item list memory */
  free(ListOItems);
}

