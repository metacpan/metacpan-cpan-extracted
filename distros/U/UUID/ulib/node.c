#ifdef __cplusplus
extern "C" {
#endif

#include "ulib/node.h"

#ifdef __cplusplus
}
#endif

/*
 * BSD 4.4 defines the size of an ifreq to be
 * max(sizeof(ifreq), sizeof(ifreq.ifr_name)+ifreq.ifr_addr.sa_len
 * However, under earlier systems, sa_len isn't present, so the size is
 * just sizeof(struct ifreq)
 */
#ifndef max
# define max(a,b) ((a) > (b) ? (a) : (b))
#endif
#ifdef HAVE_SA_LEN
# define ifreq_size(i)                             \
    max(                                           \
        sizeof(struct ifreq),                      \
        sizeof((i).ifr_name) + (i).ifr_addr.sa_len \
    )
#else
# define ifreq_size(i) sizeof(struct ifreq)
#endif /* HAVE_SA_LEN*/

static int try_unix_node(pUCXT, U8 *node_id){
#ifdef HAVE_NET_IF_H
  struct ifconf       ifc;
  struct ifreq        ifr, *ifrp;
#ifdef HAVE_NET_IF_DL_H
  struct sockaddr_dl  *sdlp;
#endif
  unsigned char       *a;
  int                 i, n, sd;
  char                buf[1024];

  if ((sd = socket(AF_INET, SOCK_DGRAM, IPPROTO_IP)) < 0)
    return -1;

  Zero(buf, sizeof(buf), char);
  ifc.ifc_len = sizeof(buf);
  ifc.ifc_buf = buf;

  if (ioctl(sd, SIOCGIFCONF, (char*)&ifc) < 0) {
    close(sd);
    return -1;
  }

  n = ifc.ifc_len;
  for (i = 0 ; i < n ; i += ifreq_size(*ifrp)) {
    ifrp = (struct ifreq*)((char*)ifc.ifc_buf + i);
    Copy(ifrp->ifr_name, ifr.ifr_name, IFNAMSIZ, char);

#if defined(SIOCGIFHWADDR) && ( defined(ifr_hwaddr) || defined(ifr_addr) )
    if (ioctl(sd, SIOCGIFHWADDR, &ifr) < 0)
      continue;
# ifdef ifr_hwaddr
    a = (unsigned char*)&ifr.ifr_hwaddr.sa_data;
# else
#   ifdef ifr_addr
    a = (unsigned char*)&ifr.ifr_addr.sa_data;
#   endif /* ifr_addr */
# endif /* ifr_hwaddr */
#else
# ifdef SIOCGENADDR
    if (ioctl(sd, SIOCGENADDR, &ifr) < 0)
      continue;
    a = (unsigned char*)ifr.ifr_enaddr;
# else
#   ifdef HAVE_NET_IF_DL_H
    sdlp = (struct sockaddr_dl*)&ifrp->ifr_addr;
    if ((sdlp->sdl_family != AF_LINK) || (sdlp->sdl_alen != 6))
      continue;
    a = (unsigned char*)&sdlp->sdl_data[sdlp->sdl_nlen];
#   else
    /* XXX any other way of finding hardware address? */
    close(sd);
    return 0;
#   endif /* HAVE_NET_IF_DL_H */
# endif /* SIOCGENADDR */
#endif /*SIOCGIFHWADDR */

		if (!a[0] && !a[1] && !a[2] && !a[3] && !a[4] && !a[5])
			continue;
		if (node_id) {
			memcpy(node_id, a, 6);
			close(sd);
			return 1;
		}
  }
  close(sd);
#endif /* HAVE_NET_IF_H */
  return 0;
}

static int try_windows_node(pUCXT, U8 *node_id) {
  int rv = 0;
#ifdef USE_WIN32_NATIVE
#ifdef HAVE_IPHLPAPI_H
  IP_ADAPTER_ADDRESSES *pAddr = NULL;
  IP_ADAPTER_ADDRESSES *pCurr = NULL;
  DWORD         dwRetVal  = 0;
  ULONG         outBufLen = 8 * 1024;
  unsigned int  i;

  rv = -1;
  for (i = 0 ; i < 3 ; ++i) {
    Newc(0, pAddr, outBufLen, char, IP_ADAPTER_ADDRESSES);
    if (pAddr == NULL) break;

    dwRetVal = GetAdaptersAddresses(AF_INET, 0, NULL, pAddr, &outBufLen);

    if (dwRetVal == ERROR_SUCCESS) {
      rv = 0;
      break;
    }
    if (dwRetVal != ERROR_BUFFER_OVERFLOW) {
      break;
    }
    Safefree(pAddr);
    pAddr = NULL;
  }

  if (rv == 0) {
    pCurr = pAddr;
    while (pCurr) {
      if (
        pCurr->OperStatus == IfOperStatusUp
        &&
        pCurr->IfType     != IF_TYPE_SOFTWARE_LOOPBACK
        &&
        pCurr->PhysicalAddressLength == 6
      ) {
        /*
        printf("# Physical address:\n");
        for (i = 0; i < (int) pCurr->PhysicalAddressLength; i++) {
          if (i == (pCurr->PhysicalAddressLength - 1))
            printf("# %.2X\n", (int) pCurr->PhysicalAddress[i]);
          else
            printf("# %.2X-", (int) pCurr->PhysicalAddress[i]);
        }
        */
        node_id[0] = pCurr->PhysicalAddress[0];
        node_id[1] = pCurr->PhysicalAddress[1];
        node_id[2] = pCurr->PhysicalAddress[2];
        node_id[3] = pCurr->PhysicalAddress[3];
        node_id[4] = pCurr->PhysicalAddress[4];
        node_id[5] = pCurr->PhysicalAddress[5];
        rv = 1;
        break;
      }
      pCurr = pCurr->Next;
    }
  }

  if (pAddr)
    Safefree(pAddr);
#endif /* HAVE_IPHLPAPI_H */
#endif /* USE_WIN32_NATIVE */
  return rv;
}

int uu_get_node_id(pUCXT, U8 *node_id) {
  /* returns:
   *  -1 if cant find due to error.
   *   0 if cant find.
   *   1 if found.
  */
  return try_unix_node(aUCXT, node_id)
    || try_windows_node(aUCXT, node_id);
}

/* ex:set ts=2 sw=2 itab=spaces: */
