#include "EXTERN.h"
#define  WINSOCK2_H_REQUESTED
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <packet32.h>
#include "Ntddndis.h"
#include "const-c.inc"

/* ********************************************************
*/

MODULE = Win32::NetPacket   PACKAGE = Win32::NetPacket

INCLUDE: const-xs.inc

PROTOTYPES: DISABLE

#**********************************************************
# ULONG PacketGetAdapterNames(PTSTR pStr, PULONG BufferSize)
#
#----------------------------------------------------------

BOOLEAN
_PacketGetAdapterNames(AdapterName)
    char *AdapterName;
  CODE:
    ULONG AdapterLength=strlen(AdapterName)/2;
    RETVAL = PacketGetAdapterNames(AdapterName, &AdapterLength);
  OUTPUT:
    RETVAL


#**********************************************************
# BOOLEAN PacketGetNetInfo(LPTSTR AdapterName, PULONG netp, PULONG maskp)
#
#----------------------------------------------------------

void
_PacketGetNetInfo(AdapterName)
    char * AdapterName
  CODE:
    ULONG NEntries = 1;
    npf_if_addr *buffer = (npf_if_addr*) safemalloc(sizeof(npf_if_addr));
    if ( PacketGetNetInfoEx(AdapterName, buffer, &NEntries)  )  {
      struct sockaddr_in *t_addr;
      if(buffer->IPAddress.ss_family == AF_INET) {
        t_addr = (struct sockaddr_in *) &(buffer->IPAddress);
        ST(0) = sv_2mortal(newSVuv(t_addr->sin_addr.S_un.S_addr));
        t_addr = (struct sockaddr_in *) &(buffer->SubnetMask);
        ST(1) = sv_2mortal(newSVuv(t_addr->sin_addr.S_un.S_addr));
        XSRETURN(2);
      }
    }
    XSRETURN_EMPTY;
  CLEANUP:
    Safefree(buffer);

#**********************************************************
# LPADAPTER PacketOpenAdapter(LPTSTR AdapterName)
#
#----------------------------------------------------------

void
_PacketOpenAdapter(AdapterName)
    char * AdapterName
  PPCODE:
    LPADAPTER adapter;
    adapter = PacketOpenAdapter(AdapterName);
    if ( adapter ) {
      ST(0) = sv_2mortal(newSViv(PTR2IV(adapter)));
      XSRETURN(1);
    }
    XSRETURN_UNDEF;

#**********************************************************
# VOID PacketCloseAdapter(LPADAPTER lpAdapter)
#
#----------------------------------------------------------

void
_PacketCloseAdapter(adapter)
    LPADAPTER adapter;
  PPCODE:
    SV* pSV;
    if (adapter) {
      PacketCloseAdapter(adapter);
      pSV = ST(0);
      sv_setiv(pSV, 0);
    }
    XSRETURN(0);

#**********************************************************
# LPPACKET PacketAllocatePacket(void)
#
#----------------------------------------------------------

void
_PacketAllocatePacket()
  PPCODE:
    LPPACKET packet;
    packet = PacketAllocatePacket();
    if ( packet ) {
      ST(0) = sv_2mortal(newSViv(PTR2IV(packet)));
      XSRETURN(1);
    }
    XSRETURN_UNDEF;

#**********************************************************
# UINT _GetBytesReceived(LPPACKET lpPacket)
#
#----------------------------------------------------------

void
_GetBytesReceived(packet)
    LPPACKET packet;
  PPCODE:
    if (packet) {
      ST(0) = sv_2mortal(newSVuv(packet->ulBytesReceived));
      XSRETURN(1);
    }
    XSRETURN(0);

#**********************************************************
# VOID PacketFreePacket(LPPACKET lpPacket)
#
#----------------------------------------------------------

void
_PacketFreePacket(packet)
    LPPACKET packet;
  PPCODE:
    SV* pSV;
    if (packet) {
      PacketFreePacket(packet);
      pSV = ST(0);
      sv_setuv(pSV, 0);
    }
    XSRETURN(0);

#**********************************************************
# VOID PacketInitPacket(LPPACKET lpPacket, PVOID Buffer, UINT Length)
#
#----------------------------------------------------------

void
_PacketInitPacket(packet, Buffer)
    LPPACKET packet;
    char * Buffer;
  PPCODE:
    STRLEN Length;
    Buffer = SvPV(ST(1), Length);
    PacketInitPacket(packet, Buffer, Length);
    XSRETURN(0);

#**********************************************************
# BOOLEAN PacketReceivePacket(LPADAPTER AdapterObject, LPPACKET lpPacket,BOOLEAN Sync)
#
#----------------------------------------------------------

void
_PacketReceivePacket(adapter, packet)
    LPADAPTER adapter;
    LPPACKET packet;
  PPCODE:
    if (PacketReceivePacket(adapter, packet, TRUE)) {
      ST(0) = sv_2mortal(newSVuv(packet->ulBytesReceived));
      XSRETURN(1);
      }
    else {
      XSRETURN_UNDEF;
    }

#**********************************************************
# BOOLEAN PacketSetHwFilter(LPADAPTER AdapterObject, ULONG Filter)
#
#----------------------------------------------------------

BOOLEAN
_PacketSetHwFilter(adapter, filter)
    LPADAPTER adapter;
    ULONG filter
  CODE:
    RETVAL = PacketSetHwFilter(adapter, filter);
  OUTPUT:
    RETVAL

#**********************************************************
# BOOLEAN PacketSetBuff(LPADAPTER AdapterObject, int dim)
#
#----------------------------------------------------------

BOOLEAN
_PacketSetBuff(adapter, dim)
    LPADAPTER adapter;
    int dim;
  CODE:
    RETVAL = PacketSetBuff(adapter, dim);
  OUTPUT:
    RETVAL

#**********************************************************
# BOOLEAN PacketGetStats(LPADAPTER AdapterObject, struct bpf_stat *s)
#
#----------------------------------------------------------

void
_PacketGetStats(adapter)
    LPADAPTER adapter;
  PPCODE:
    struct bpf_stat stat;
    if ( PacketGetStats(adapter,&stat) )  {
      ST(0) = sv_2mortal(newSVuv(stat.bs_recv));
      ST(1) = sv_2mortal(newSVuv(stat.bs_drop));
      XSRETURN(2);
    }
    XSRETURN_EMPTY;

#**********************************************************
# BOOLEAN PacketSetReadTimeout ( LPADAPTER AdapterObject , int timeout )
#
#----------------------------------------------------------

BOOLEAN
_PacketSetReadTimeout(adapter, timeout)
    LPADAPTER adapter;
    int timeout;
  CODE:
    RETVAL = PacketSetReadTimeout(adapter, timeout);
  OUTPUT:
    RETVAL

#**********************************************************
# BOOLEAN PacketGetNetType (LPADAPTER AdapterObject,NetType *type)
#
#----------------------------------------------------------

void
_PacketGetNetType(adapter);
    LPADAPTER adapter;
  PPCODE:
    NetType type;
    if ( PacketGetNetType(adapter, &type) ) {
      ST(0) = sv_2mortal(newSVuv(type.LinkType));
      ST(1) = sv_2mortal(newSVuv(type.LinkSpeed));
      XSRETURN(2);
    }
    XSRETURN_EMPTY;

#**********************************************************
# BOOLEAN PacketSetMode(LPADAPTER AdapterObject,int mode)
#
#----------------------------------------------------------

BOOLEAN
_PacketSetMode(adapter, mode)
    LPADAPTER adapter;
    int mode
  CODE:
    RETVAL = PacketSetMode(adapter, mode);
  OUTPUT:
    RETVAL

#**********************************************************
# BOOLEAN PacketSetNumWrites(LPADAPTER AdapterObject,int nwrites)
#
#----------------------------------------------------------

BOOLEAN
_PacketSetNumWrites(adapter, nwrites)
    LPADAPTER adapter;
    int nwrites;
  CODE:
    RETVAL = PacketSetNumWrites(adapter, nwrites);
  OUTPUT:
    RETVAL

#**********************************************************
# BOOLEAN PacketSetMinToCopy(LPADAPTER AdapterObject,int nbytes)
#
#----------------------------------------------------------

BOOLEAN
_PacketSetMinToCopy(adapter, nbytes)
    LPADAPTER adapter;
    int nbytes;
  CODE:
    RETVAL = PacketSetMinToCopy(adapter, nbytes);
  OUTPUT:
    RETVAL
    
#**********************************************************
# Win32::Event GetReadEvent(LPADAPTER AdapterObject)
#
#----------------------------------------------------------

void
_GetReadEvent(adapter)
    LPADAPTER adapter;
  CODE:
    unsigned int h = (unsigned int) PacketGetReadEvent(adapter); 
    ST(0) = sv_newmortal();
	  sv_setref_iv(ST(0), "Win32::Event", h);
    XSRETURN(1);

#**********************************************************
# BOOLEAN PacketSendPacket(LPADAPTER AdapterObject, LPPACKET pPacket, BOOLEAN Sync)
#
#----------------------------------------------------------

BOOLEAN
_PacketSendPacket(adapter, packet)
    LPADAPTER adapter;
    LPPACKET packet;
  CODE:
    RETVAL = PacketSendPacket(adapter, packet, TRUE);
  OUTPUT:
    RETVAL

#**********************************************************
# BOOLEAN PacketRequest(LPADAPTER AdapterObject,BOOLEAN Set, PPACKET_OID_DATA OidData)
#
#----------------------------------------------------------

BOOLEAN
_PacketGetRequest(adapter, OidData)
    LPADAPTER adapter;
    PPACKET_OID_DATA OidData;
  CODE:
    RETVAL = PacketRequest(adapter, FALSE, OidData);
  OUTPUT:
    RETVAL

#----------------------------------------------------------

BOOLEAN
_PacketSetRequest(adapter, OidData)
    LPADAPTER adapter;
    PPACKET_OID_DATA OidData;
  CODE:
    RETVAL = PacketRequest(adapter, TRUE, OidData);
  OUTPUT:
    RETVAL

#**********************************************************
# BOOLEAN PacketSetBpf(LPADAPTER AdapterObject, struct bpf_program *fp)
#
#----------------------------------------------------------

BOOLEAN
_PacketSetBpf(adapter, sv_prg)
    LPADAPTER adapter;
    SV  * sv_prg;
  CODE:
    struct bpf_program prg;
    prg.bf_len = sv_len(sv_prg)/8;
    prg.bf_insns = (struct bpf_insn *) SvPVX(sv_prg);
    RETVAL = PacketSetBpf(adapter, &prg);
  OUTPUT:
    RETVAL

#**********************************************************
# PCHAR PacketGetVersion()
#
#----------------------------------------------------------

char *
GetVersion()
  CODE:
    RETVAL = PacketGetVersion();
  OUTPUT:
    RETVAL

#**********************************************************