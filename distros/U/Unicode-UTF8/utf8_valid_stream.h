/*
 * Copyright (c) 2026 Christian Hansen <chansen@cpan.org>
 * <https://github.com/chansen/c-utf8>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
#ifndef UTF8_VALID_STREAM_H
#define UTF8_VALID_STREAM_H
#include <stddef.h>
#include <stdbool.h>

#if defined(UTF8_DFA32_H) && defined(UTF8_DFA64_H)
#  error "utf8_dfa32.h and utf8_dfa64.h are mutually exclusive"
#elif !defined(UTF8_DFA32_H) && !defined(UTF8_DFA64_H)
#  error "include utf8_dfa32.h or utf8_dfa64.h before utf8_valid_stream.h"
#endif

#ifdef __cplusplus
extern "C" {
#endif

#ifndef UTF8_VALID_STREAM_PROBE_WINDOW_SIZE
#  define UTF8_VALID_STREAM_PROBE_WINDOW_SIZE 256
#endif

/*
 * utf8_valid_stream_status_t -- outcome of a streaming validation step.
 *
 *   UTF8_VALID_STREAM_OK         src fully consumed, no errors.
 *   UTF8_VALID_STREAM_PARTIAL    src fully consumed, ends in the middle of a sequence.
 *   UTF8_VALID_STREAM_ILLFORMED  stopped at an ill-formed sequence.
 *   UTF8_VALID_STREAM_TRUNCATED  eof is true and src ends in the middle of a sequence.
 */

typedef enum {
  UTF8_VALID_STREAM_OK,
  UTF8_VALID_STREAM_PARTIAL,
  UTF8_VALID_STREAM_ILLFORMED,
  UTF8_VALID_STREAM_TRUNCATED,
} utf8_valid_stream_status_t;

/*
 * utf8_valid_stream_result_t -- result of a streaming validation step.
 *
 *   status:    outcome of the operation (see utf8_valid_stream_status_t).
 *   consumed:  bytes read from src.
 *   pending:   bytes of an incomplete trailing sequence on PARTIAL, else 0.
 *   advance:   bytes to skip on ILLFORMED or TRUNCATED, else 0.
 *              Resume at src[consumed + advance].
 *   carried:   bytes from a previous chunk that belong to the same subpart.
 */
typedef struct {
  utf8_valid_stream_status_t status;
  size_t consumed;
  size_t pending;
  size_t advance;
  size_t carried;
} utf8_valid_stream_result_t;

typedef struct {
  utf8_dfa_state_t state;
  size_t carried;
  size_t probe_window;
  bool probe_ascii;
} utf8_valid_stream_t;

static inline void
utf8_valid_stream_set_window(utf8_valid_stream_t *s, size_t window) {
  s->probe_window = window;
}

static inline void
utf8_valid_stream_set_ascii(utf8_valid_stream_t *s, bool ascii) {
  s->probe_ascii = ascii;
}

static inline void
utf8_valid_stream_init(utf8_valid_stream_t *s) {
  s->state = UTF8_DFA_ACCEPT;
  s->carried = 0;
  s->probe_window = UTF8_VALID_STREAM_PROBE_WINDOW_SIZE;
#ifdef UTF8_VALID_STREAM_PROBE_ASCII
  s->probe_ascii = true;
#else
  s->probe_ascii = false;
#endif
}

static inline size_t
utf8_valid_stream_probe_boundary(const uint8_t *bytes, 
                                 size_t len, 
                                 size_t probe_window) {
  size_t probe = len > probe_window ? probe_window : len - 1;

  // Back up to a definite UTF-8 boundary:
  // the start of the final sequence in the probe window.
  while (probe > 0 && (bytes[probe] & 0xC0) == 0x80)
    probe--;

  return probe;
}

static inline bool
utf8_valid_stream_probe_run(const uint8_t *bytes, 
                            size_t len, 
                            bool ascii) {
  utf8_dfa_state_t state;

  if (len < 64)
    state = utf8_dfa_run(UTF8_DFA_ACCEPT, bytes, len);
  else if (ascii)
    state = utf8_dfa_run_ascii(UTF8_DFA_ACCEPT, bytes, len);
  else
    state = utf8_dfa_run_dual(UTF8_DFA_ACCEPT, bytes, len);

  return state == UTF8_DFA_ACCEPT;
}

/*
 * utf8_valid_stream_check -- validate the next chunk of a UTF-8 stream.
 *
 * src[0..len) is the next chunk. eof should be true only for the final chunk.
 * The DFA state is carried in s across calls.
 *
 * Returns a utf8_valid_stream_result_t describing the outcome:
 *
 *   status:
 *     UTF8_VALID_STREAM_OK         src fully consumed, no errors.
 *     UTF8_VALID_STREAM_PARTIAL    src fully consumed, ends in the middle of a sequence.
 *     UTF8_VALID_STREAM_ILLFORMED  stopped at an ill-formed sequence.
 *     UTF8_VALID_STREAM_TRUNCATED  eof is true and src ends in the middle of a sequence.
 *
 *   consumed:  bytes read from src.
 *   pending:   bytes of an incomplete trailing sequence on PARTIAL, else 0.
 *   advance:   bytes to skip on ILLFORMED or TRUNCATED, else 0.
 *              Resume at src[consumed + advance].
 *   carried:   bytes from a previous chunk that belong to the same subpart.
 *
 * On ILLFORMED or TRUNCATED:
 *
 *   subpart length = carried + advance
 *   subpart start  = src + consumed - carried   (chunk-relative)
 *
 * and the stream state is reset to UTF8_DFA_ACCEPT.
 */
static inline utf8_valid_stream_result_t
utf8_valid_stream_check(utf8_valid_stream_t* s,
                        const char* src,
                        size_t len,
                        bool eof) {
  const uint8_t* bytes = (const uint8_t*)src;
  utf8_dfa_state_t state = s->state;
  size_t carried = s->carried;
  size_t consumed = 0;
  size_t chunk_bytes = 0;
  size_t pos = 0;
  bool probe_run = s->probe_window >= 64;

  while (pos < len) {
    state = utf8_dfa_step(state, bytes[pos++]);
    chunk_bytes++;

    if (state == UTF8_DFA_ACCEPT) {
      if (probe_run && len - pos >= 64) {
        do {
          size_t probe = utf8_valid_stream_probe_boundary(bytes + pos, len - pos, s->probe_window);
          if (probe == 0)
            probe_run = false;
          else
            probe_run = utf8_valid_stream_probe_run(bytes + pos, probe, s->probe_ascii);
          if (!probe_run)
            break;
          pos += probe;
        } while (len - pos >= 64);
      }
      consumed = pos;
      chunk_bytes = 0;
      carried = 0;
    }
    else if (state == UTF8_DFA_REJECT) {
      size_t total = carried + chunk_bytes;
      size_t advance = total > 1 ? chunk_bytes - 1 : 1;
      s->state = UTF8_DFA_ACCEPT;
      s->carried = 0;
      return (utf8_valid_stream_result_t){
        .status   = UTF8_VALID_STREAM_ILLFORMED,
        .consumed = carried ? 0 : consumed,
        .pending  = 0,
        .advance  = advance,
        .carried  = carried,
      };
    }
  }

  if (state == UTF8_DFA_ACCEPT) {
    s->state = UTF8_DFA_ACCEPT;
    s->carried = 0;
    return (utf8_valid_stream_result_t){
      .status   = UTF8_VALID_STREAM_OK,
      .consumed = len,
      .pending  = 0,
      .advance  = 0,
      .carried  = 0,
    };
  }

  if (eof) {
    s->state = UTF8_DFA_ACCEPT;
    s->carried = 0;
    return (utf8_valid_stream_result_t){
      .status   = UTF8_VALID_STREAM_TRUNCATED,
      .consumed = carried ? 0 : consumed,
      .pending  = 0,
      .advance  = chunk_bytes,
      .carried  = carried,
    };
  }

  s->state = state;
  s->carried = carried + chunk_bytes;
  return (utf8_valid_stream_result_t){
    .status   = UTF8_VALID_STREAM_PARTIAL,
    .consumed = consumed,
    .pending  = carried + chunk_bytes,
    .advance  = 0,
    .carried  = 0,
  };
}

#ifdef __cplusplus
}
#endif
#endif
