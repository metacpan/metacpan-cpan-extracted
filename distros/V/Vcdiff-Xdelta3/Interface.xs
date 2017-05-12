#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdio.h>
#include <stdlib.h>

#include "xdelta3.h"

// FIXME: figure out the right value for this: maybe dynamic?
#define BUF_SIZE 65536

#ifndef MIN
#define MIN(x,y) ((x)<(y)?(x):(y))
#endif

int encode_decode(int encode,
                  int source_fd, SV *source_sv,
                  int input_fd, SV *input_sv,
                  int output_fd, SV *output_sv) {
  int ret;
  ssize_t ssize_ret;
  int error = 0;
  xd3_stream stream;
  xd3_config config;
  xd3_source source;
  char *ibuf = NULL;
  int ibuf_len = 0;
  char *source_str = NULL;
  size_t source_str_size = 0;
  char *input_str = NULL;
  size_t input_str_size = 0;

  memset(&stream, 0, sizeof (stream));
  memset(&source, 0, sizeof (source));

  xd3_init_config(&config, 0);
  config.winsize = BUF_SIZE;
  if (xd3_config_stream(&stream, &config)) {
    // Nothing to clean up so just return error straight away
    return 1;
  }

  source.blksize = BUF_SIZE;
  source.curblkno = 0;

  if (source_fd != -1) {
    source.curblk = malloc(source.blksize);
    if (!source.curblk) {
      error = 2;
      goto bail;
    }
    if (lseek(source_fd, 0, SEEK_SET) < 0) {
      error = 3;
      goto bail;
    }
    ssize_ret = read(source_fd, (void*)source.curblk, source.blksize);
    if (ssize_ret < 0) {
      error = 4;
      goto bail;
    } else {
      source.onblk = (size_t) ssize_ret;
    }
  } else {
    source_str_size = SvCUR(source_sv);
    source_str = SvPV(source_sv, source_str_size);
    source.curblk = (uint8_t *) source_str;
    source.onblk = MIN(source.blksize, source_str_size);
  }

  xd3_set_source(&stream, &source);

  if (input_fd != -1) {
    ibuf = malloc(BUF_SIZE);
    if (!ibuf) {
      error = 5;
      goto bail;
    }
  } else {
    input_str_size = SvCUR(input_sv);
    input_str = SvPV(input_sv, input_str_size);
    ibuf = input_str;
    ibuf_len = 0;
  }

  do {
    if (input_fd != -1) {
      ibuf_len = read(input_fd, ibuf, BUF_SIZE);
      if (ibuf_len < 0) {
        error = 6;
        goto bail;
      }
    } else {
      ibuf += ibuf_len;
      ibuf_len = MIN(BUF_SIZE, input_str_size - (ibuf - input_str));
    }

    if (ibuf_len < BUF_SIZE) {
      xd3_set_flags(&stream, XD3_FLUSH | stream.flags);
    }
    xd3_avail_input(&stream, (uint8_t *) ibuf, ibuf_len);

process:
    if (encode)
      ret = xd3_encode_input(&stream);
    else
      ret = xd3_decode_input(&stream);

    switch (ret) {
      case XD3_INPUT:
        continue;

      case XD3_OUTPUT:
        if (output_fd != -1) {
          ssize_ret = write(output_fd, stream.next_out, stream.avail_out);
          if (ssize_ret < 0 || ((size_t)ssize_ret) != stream.avail_out) {
            error = 7;
            goto bail;
          }
        } else {
          sv_catpvn(output_sv, (char *) stream.next_out, stream.avail_out);
        }

        xd3_consume_output(&stream);

        goto process;

      case XD3_GETSRCBLK:
        source.curblkno = source.getblkno;

        if (source_fd != -1) {
          if (lseek(source_fd, source.blksize * source.getblkno, SEEK_SET) < 0) {
            error = 3;
            goto bail;
          }
          ssize_ret = read(source_fd, (void*)source.curblk, source.blksize);
          if (ssize_ret < 0) {
            error = 4;
            goto bail;
          } else {
            source.onblk = (size_t) ssize_ret;
          }
        } else {
          source.curblk = (uint8_t *) (source_str + (source.blksize * source.getblkno));
          source.onblk = MIN(source.blksize, source_str_size - (source.blksize * source.getblkno));
        }

        goto process;

      case XD3_GOTHEADER:
      case XD3_WINSTART:
      case XD3_WINFINISH:
        goto process;

      default:
        // These values start at -17703 and go down
        error = ret;
        goto bail;
    }

  } while (ibuf_len == BUF_SIZE);

bail:
  if (source_fd != -1 && source.curblk) {
    free((void*)source.curblk);
  }

  if (input_fd != -1 && ibuf) {
    free(ibuf);
  }

  if (xd3_close_stream(&stream) && !error) {
    error = 8;
  }
  xd3_free_stream(&stream);

  return error;
}



MODULE = Vcdiff::Xdelta3		PACKAGE = Vcdiff::Xdelta3

PROTOTYPES: ENABLE



int
_encode(source_fd, source_sv, input_fd, input_sv, output_fd, output_sv)
        int source_fd
        SV *source_sv
        int input_fd
        SV *input_sv
        int output_fd
        SV *output_sv
    CODE:
        RETVAL = encode_decode(1,
                               source_fd, source_sv,
                               input_fd, input_sv,
                               output_fd, output_sv);

    OUTPUT:
        RETVAL



int
_decode(source_fd, source_sv, input_fd, input_sv, output_fd, output_sv)
        int source_fd
        SV *source_sv
        int input_fd
        SV *input_sv
        int output_fd
        SV *output_sv
    CODE:
        RETVAL = encode_decode(0,
                               source_fd, source_sv,
                               input_fd, input_sv,
                               output_fd, output_sv);

    OUTPUT:
        RETVAL
