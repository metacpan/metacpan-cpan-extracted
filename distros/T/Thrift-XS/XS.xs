#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <stdlib.h>
#include <stdint.h>
#include <inttypes.h>

#include "xs_object_magic.h"
#include "common.h"
#include "buffer.c"
#include "memory_buffer.h"
#include "binary_protocol.h"

// Include the XS::Object::Magic code inline to simplify things
#include "Magic.c"

// Endian-ness code from TProtocol.h
#ifndef __BYTE_ORDER
# if defined(BYTE_ORDER) && defined(LITTLE_ENDIAN) && defined(BIG_ENDIAN)
#  define __BYTE_ORDER BYTE_ORDER
#  define __LITTLE_ENDIAN LITTLE_ENDIAN
#  define __BIG_ENDIAN BIG_ENDIAN
# else
#  error "Cannot determine endianness"
# endif
#endif

#if __BYTE_ORDER == __BIG_ENDIAN
#  define ntohll(n) (n)
#  define htonll(n) (n)
# if defined(__GNUC__) && defined(__GLIBC__)
#  include <byteswap.h>
#  define htolell(n) bswap_64(n)
#  define letohll(n) bswap_64(n)
# else /* GNUC & GLIBC */
#  define bswap_64(n) \
      ( (((n) & 0xff00000000000000ull) >> 56) \
      | (((n) & 0x00ff000000000000ull) >> 40) \
      | (((n) & 0x0000ff0000000000ull) >> 24) \
      | (((n) & 0x000000ff00000000ull) >> 8)  \
      | (((n) & 0x00000000ff000000ull) << 8)  \
      | (((n) & 0x0000000000ff0000ull) << 24) \
      | (((n) & 0x000000000000ff00ull) << 40) \
      | (((n) & 0x00000000000000ffull) << 56) )
#  define htolell(n) bswap_64(n)
#  define letohll(n) bswap_64(n)
# endif /* GNUC & GLIBC */
#elif __BYTE_ORDER == __LITTLE_ENDIAN
#  define htolell(n) (n)
#  define letohll(n) (n)
# if defined(__GNUC__) && defined(__GLIBC__)
#  include <byteswap.h>
#  define ntohll(n) bswap_64(n)
#  define htonll(n) bswap_64(n)
# else /* GNUC & GLIBC */
#  define ntohll(n) ( (((uint64_t)ntohl(n)) << 32) + ntohl(n >> 32) )
#  define htonll(n) ( (((uint64_t)htonl(n)) << 32) + htonl(n >> 32) )
# endif /* GNUC & GLIBC */
#else /* __BYTE_ORDER */
# error "Can't define htonll or ntohll!"
#endif

MODULE = Thrift::XS		PACKAGE = Thrift::XS		
PROTOTYPES: ENABLE

INCLUDE: MemoryBuffer.xs
INCLUDE: BinaryProtocol.xs
INCLUDE: CompactProtocol.xs
