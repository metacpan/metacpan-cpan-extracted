#ifndef TSTR_FORMAT_H
#define TSTR_FORMAT_H

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>
#include "tstr_packed_alnum.h"

typedef enum {
  TSTR_FORMAT_UNKNOWN = 0,
  TSTR_FORMAT_ANSIC,
  TSTR_FORMAT_ASN1GT,
  TSTR_FORMAT_ASN1UT,
  TSTR_FORMAT_CLF,
  TSTR_FORMAT_DATETIME,
  TSTR_FORMAT_ECMASCRIPT,
  TSTR_FORMAT_GITDATE,
  TSTR_FORMAT_ISO8601,
  TSTR_FORMAT_ISO9075,
  TSTR_FORMAT_RFC2616,
  TSTR_FORMAT_RFC2822,
  TSTR_FORMAT_RFC2822FWS,
  TSTR_FORMAT_RFC3339,
  TSTR_FORMAT_RFC3501,
  TSTR_FORMAT_RFC4287,
  TSTR_FORMAT_RFC5280,
  TSTR_FORMAT_RFC5545,
  TSTR_FORMAT_RFC9557,
  TSTR_FORMAT_RUBYDATE,
  TSTR_FORMAT_UNIXDATE,
  TSTR_FORMAT_UNIXSTAMP,
  TSTR_FORMAT_W3CDTF,
  TSTR_FORMAT_TYPE_COUNT,
} tstr_format_t;

static inline bool tstr_format_is_known(tstr_format_t fmt) {
  return (fmt > TSTR_FORMAT_UNKNOWN && fmt < TSTR_FORMAT_TYPE_COUNT);
}

static inline const char * tstr_format_name(tstr_format_t fmt) {
  static const char * kFormatName[TSTR_FORMAT_TYPE_COUNT] = {
    [TSTR_FORMAT_UNKNOWN]    = "Unknown",
    [TSTR_FORMAT_ANSIC]      = "ANSIC",
    [TSTR_FORMAT_ASN1GT]     = "ASN.1 GeneralizedTime",
    [TSTR_FORMAT_ASN1UT]     = "ASN.1 UTCTime",
    [TSTR_FORMAT_CLF]        = "Common Log Format",
    [TSTR_FORMAT_DATETIME]   = "DateTime",
    [TSTR_FORMAT_ECMASCRIPT] = "ECMAScript",
    [TSTR_FORMAT_GITDATE]    = "GitDate",
    [TSTR_FORMAT_ISO8601]    = "ISO 8601",
    [TSTR_FORMAT_ISO9075]    = "ISO 9075",
    [TSTR_FORMAT_RFC2616]    = "RFC 2616",
    [TSTR_FORMAT_RFC2822]    = "RFC 2822",
    [TSTR_FORMAT_RFC2822FWS] = "RFC 2822 (Folding WS)",
    [TSTR_FORMAT_RFC3339]    = "RFC 3339",
    [TSTR_FORMAT_RFC3501]    = "RFC 3501",
    [TSTR_FORMAT_RFC4287]    = "RFC 4287",
    [TSTR_FORMAT_RFC5280]    = "RFC 5280",
    [TSTR_FORMAT_RFC5545]    = "RFC 5545",
    [TSTR_FORMAT_RFC9557]    = "RFC 9557",
    [TSTR_FORMAT_RUBYDATE]   = "RubyDate",
    [TSTR_FORMAT_UNIXDATE]   = "UnixDate",
    [TSTR_FORMAT_UNIXSTAMP]  = "UnixStamp",
    [TSTR_FORMAT_W3CDTF]     = "W3CDTF",
  };

  if (!tstr_format_is_known(fmt))
    fmt = TSTR_FORMAT_UNKNOWN;
  return kFormatName[fmt];
}

static inline tstr_format_t tstr_format_from_packed_alnum(uint64_t packed) {
  switch (packed) {
    case TSTR_PACKED_ALNUM5('A','N','S','I','C'):
    case TSTR_PACKED_ALNUM5('C','T','I','M','E'):
      return TSTR_FORMAT_ANSIC;
    case TSTR_PACKED_ALNUM6('A','S','N','1','G','T'):
      return TSTR_FORMAT_ASN1GT;
    case TSTR_PACKED_ALNUM6('A','S','N','1','U','T'):
      return TSTR_FORMAT_ASN1UT;
    case TSTR_PACKED_ALNUM3('C','L','F'):
      return TSTR_FORMAT_CLF;
    case TSTR_PACKED_ALNUM8('D','A','T','E','T','I','M','E'):
    case TSTR_PACKED_ALNUM7('G','E','N','E','R','I','C'):
      return TSTR_FORMAT_DATETIME;
    case TSTR_PACKED_ALNUM10('E','C','M','A','S','C','R','I','P','T'):
    case TSTR_PACKED_ALNUM10('J','A','V','A','S','C','R','I','P','T'):
      return TSTR_FORMAT_ECMASCRIPT;
    case TSTR_PACKED_ALNUM7('G','I','T','D','A','T','E'):
    case TSTR_PACKED_ALNUM3('G','I','T'):
      return TSTR_FORMAT_GITDATE;
    case TSTR_PACKED_ALNUM7('I','S','O','8','6','0','1'):
      return TSTR_FORMAT_ISO8601;
    case TSTR_PACKED_ALNUM7('I','S','O','9','0','7','5'):
    case TSTR_PACKED_ALNUM3('S','Q','L'):
      return TSTR_FORMAT_ISO9075;
    case TSTR_PACKED_ALNUM7('R','F','C','2','6','1','6'):
    case TSTR_PACKED_ALNUM7('R','F','C','7','2','3','1'):
    case TSTR_PACKED_ALNUM4('H','T','T','P'):
      return TSTR_FORMAT_RFC2616;
    case TSTR_PACKED_ALNUM7('R','F','C','2','8','2','2'):
    case TSTR_PACKED_ALNUM7('R','F','C','5','3','2','2'):
    case TSTR_PACKED_ALNUM5('E','M','A','I','L'):
    case TSTR_PACKED_ALNUM3('I','M','F'):
      return TSTR_FORMAT_RFC2822;
    case TSTR_PACKED_ALNUM10('R','F','C','2','8','2','2','F','W','S'):
      return TSTR_FORMAT_RFC2822FWS;
    case TSTR_PACKED_ALNUM7('R','F','C','3','3','3','9'):
      return TSTR_FORMAT_RFC3339;
    case TSTR_PACKED_ALNUM7('R','F','C','3','5','0','1'):
    case TSTR_PACKED_ALNUM7('R','F','C','9','0','5','1'):
    case TSTR_PACKED_ALNUM4('I','M','A','P'):
      return TSTR_FORMAT_RFC3501;
    case TSTR_PACKED_ALNUM7('R','F','C','4','2','8','7'):
    case TSTR_PACKED_ALNUM4('A','T','O','M'):
      return TSTR_FORMAT_RFC4287;
    case TSTR_PACKED_ALNUM7('R','F','C','5','2','8','0'):
    case TSTR_PACKED_ALNUM4('X','5','0','9'):
      return TSTR_FORMAT_RFC5280;
    case TSTR_PACKED_ALNUM7('R','F','C','5','5','4','5'):
    case TSTR_PACKED_ALNUM4('I','C','A','L'):
      return TSTR_FORMAT_RFC5545;
    case TSTR_PACKED_ALNUM7('R','F','C','9','5','5','7'):
    case TSTR_PACKED_ALNUM5('I','X','D','T','F'):
      return TSTR_FORMAT_RFC9557;
    case TSTR_PACKED_ALNUM8('R','U','B','Y','D','A','T','E'):
    case TSTR_PACKED_ALNUM4('R','U','B','Y'):
      return TSTR_FORMAT_RUBYDATE;
    case TSTR_PACKED_ALNUM8('U','N','I','X','D','A','T','E'):
    case TSTR_PACKED_ALNUM4('U','N','I','X'):
      return TSTR_FORMAT_UNIXDATE;
    case TSTR_PACKED_ALNUM9('U','N','I','X','S','T','A','M','P'):
      return TSTR_FORMAT_UNIXSTAMP;
    case TSTR_PACKED_ALNUM6('W','3','C','D','T','F'):
    case TSTR_PACKED_ALNUM3('W','3','C'):
      return TSTR_FORMAT_W3CDTF;
    default:
      return TSTR_FORMAT_UNKNOWN;
  }
}

static inline tstr_format_t tstr_format_from_string(const char* src, 
                                                    size_t len) {
  uint64_t packed;

  if (!len || tstr_packed_alnum_encode(src, len, &packed) != len)
    return TSTR_FORMAT_UNKNOWN;
  return tstr_format_from_packed_alnum(packed);
}

#endif /* TSTR_FORMAT_H */
