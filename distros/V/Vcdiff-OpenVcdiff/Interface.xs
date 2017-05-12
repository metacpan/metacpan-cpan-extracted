#ifdef __cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef __cplusplus
}
#endif


#include <google/vcdecoder.h>
#include <google/vcencoder.h>

#include <memory>


// FIXME: figure out the right value for this: maybe dynamic?
#define BUF_SIZE 65536


int encode(SV *source_sv, int input_fd, SV *input_sv, int output_fd, SV *output_sv) {
  std::auto_ptr<open_vcdiff::HashedDictionary> hashed_dictionary;
  char *source_str;
  size_t source_str_size;

  source_str_size = SvCUR(source_sv);
  source_str = SvPV(source_sv, source_str_size);
  hashed_dictionary.reset(new open_vcdiff::HashedDictionary(source_str, source_str_size));

  if (!hashed_dictionary->Init()) {
    return 1;
  }

  open_vcdiff::VCDiffFormatExtensionFlags format_flags = open_vcdiff::VCD_STANDARD_FORMAT;
  open_vcdiff::VCDiffStreamingEncoder encoder(hashed_dictionary.get(), format_flags, false);

  std::string output_string;

  if (!encoder.StartEncoding(&output_string)) {
    return 2;
  }


  char *ibuf_ptr = NULL;
  std::string ibuf_str;
  size_t ibuf_len = 0;
  char *input_str_ptr = NULL;
  size_t input_str_size = 0;

  if (input_fd != -1) {
    ibuf_str.resize(BUF_SIZE);
  } else {
    input_str_size = SvCUR(input_sv);
    input_str_ptr = SvPV(input_sv, input_str_size);
    ibuf_ptr = input_str_ptr;
  }


  while(1) {
    if (input_fd != -1) {
      ibuf_len = read(input_fd, &ibuf_str[0], BUF_SIZE);
      if (ibuf_len < 0) {
        return 3;
      }
    } else {
      ibuf_ptr += ibuf_len;
      ibuf_len = MIN(BUF_SIZE, input_str_size - (ibuf_ptr - input_str_ptr));
    }

    if (ibuf_len == 0) break;

    if (!encoder.EncodeChunk((input_fd != -1) ? &ibuf_str[0] : ibuf_ptr, ibuf_len, &output_string)) {
      return 4;
    }

    if (output_fd != -1) {
      if (output_string.length() && write(output_fd, output_string.c_str(), output_string.length()) != output_string.length()) {
        return 5;
      }

      output_string.clear();
    }

    if (input_fd != -1 && ibuf_len < BUF_SIZE) break; // stream is empty
  }


  if (!encoder.FinishEncoding(&output_string)) {
    return 6;
  }


  if (output_fd != -1) {
    if (output_string.length() && write(output_fd, output_string.c_str(), output_string.length()) != output_string.length()) {
      return 5;
    }

    output_string.clear();
  } else {
    sv_catpvn(output_sv, output_string.c_str(), output_string.length());
  }


  return 0;
}


int decode(SV *source_sv, int input_fd, SV *input_sv, int output_fd, SV *output_sv) {
  open_vcdiff::VCDiffStreamingDecoder decoder;

  char *source_str;
  size_t source_str_size;

  source_str_size = SvCUR(source_sv);
  source_str = SvPV(source_sv, source_str_size);

  decoder.StartDecoding(source_str, source_str_size);


  std::string output_string;

  char *ibuf_ptr = NULL;
  std::string ibuf_str;
  size_t ibuf_len = 0;
  char *input_str_ptr = NULL;
  size_t input_str_size = 0;

  if (input_fd != -1) {
    ibuf_str.resize(BUF_SIZE);
  } else {
    input_str_size = SvCUR(input_sv);
    input_str_ptr = SvPV(input_sv, input_str_size);
    ibuf_ptr = input_str_ptr;
  }


  while(1) {
    if (input_fd != -1) {
      ibuf_len = read(input_fd, &ibuf_str[0], BUF_SIZE);
      if (ibuf_len < 0) {
        return 3;
      }
    } else {
      ibuf_ptr += ibuf_len;
      ibuf_len = MIN(BUF_SIZE, input_str_size - (ibuf_ptr - input_str_ptr));
    }

    if (ibuf_len == 0) break;

    if (!decoder.DecodeChunk((input_fd != -1) ? &ibuf_str[0] : ibuf_ptr, ibuf_len, &output_string)) {
      return 7;
    }

    if (output_fd != -1) {
      if (output_string.length() && write(output_fd, output_string.c_str(), output_string.length()) != output_string.length()) {
        return 5;
      }

      output_string.clear();
    }

    if (input_fd != -1 && ibuf_len < BUF_SIZE) break; // stream is empty
  }


  if (!decoder.FinishDecoding()) {
    return 7;
  }


  if (output_fd != -1) {
    if (output_string.length() && write(output_fd, output_string.c_str(), output_string.length()) != output_string.length()) {
      return 5;
    }

    output_string.clear();
  } else {
    sv_catpvn(output_sv, output_string.c_str(), output_string.length());
  }


  return 0;
}











MODULE = Vcdiff::OpenVcdiff        PACKAGE = Vcdiff::OpenVcdiff
 
PROTOTYPES: ENABLE


int
_encode(source_sv, input_fd, input_sv, output_fd, output_sv)
        SV *source_sv
        int input_fd
        SV *input_sv
        int output_fd
        SV *output_sv
    CODE:
        try {
          RETVAL = encode(source_sv,
                          input_fd, input_sv,
                          output_fd, output_sv);
        } catch(...) {
          RETVAL = 9;
        }

    OUTPUT:
        RETVAL




int
_decode(source_sv, input_fd, input_sv, output_fd, output_sv)
        SV *source_sv
        int input_fd
        SV *input_sv
        int output_fd
        SV *output_sv
    CODE:
        try {
          RETVAL = decode(source_sv,
                          input_fd, input_sv,
                          output_fd, output_sv);
        } catch(...) {
          RETVAL = 9;
        }

    OUTPUT:
        RETVAL
