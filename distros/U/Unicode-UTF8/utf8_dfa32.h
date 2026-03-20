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

/*
 * utf8_dfa32.h -- Shift-based DFA for Forward UTF-8 validation
 * =============================================================================
 *
 *  Same 9-state DFA as utf8_dfa64.h but validation-only (no decode). State
 *  offsets differ: chosen by an SMT solver to pack rows into uint32_t rather
 *  than uniform multiples of 6. Use utf8_dfa64.h if you need codepoint decoding.
 *
 *
 * CONCEPT
 * -------
 *
 *  Scans UTF-8 bytes left-to-right. Feed bytes one at a time starting from
 *  S_ACCEPT. Each return to S_ACCEPT marks a complete valid sequence boundary.
 *  S_ERROR is an absorbing trap: once entered, no byte can leave it.
 *
 *  Because the lead byte arrives first, the DFA must carry forward enough
 *  context to validate the bytes that follow. Two things determine the next
 *  valid byte range:
 *
 *    (1) How many continuation bytes remain (depth 1, 2, or 3)
 *    (2) Whether the lead was E0/ED/F0/F4, which narrows the first
 *        continuation byte range to reject non-shortest form, surrogates,
 *        and codepoints above U+10FFFF
 *
 *
 * STATE DEFINITIONS
 * -----------------
 *
 *   State    Value  Meaning
 *   -------  -----  -----------------------------------------------------
 *   S_ERROR    0    Invalid byte seen (absorbing trap state)
 *   S_ACCEPT   6    Start state / valid sequence boundary
 *   S_TAIL1   16    Expect 1 more continuation  (80-BF → ACCEPT)
 *   S_TAIL2    1    Expect 2 more continuations (80-BF → TAIL1)
 *   S_TAIL3   18    Expect 3 more continuations (80-BF → TAIL2)
 *   S_E0      19    After 0xE0; next must be A0-BF (no non-shortest form)
 *   S_ED      25    After 0xED; next must be 80-9F (no surrogates)
 *   S_F0      11    After 0xF0; next must be 90-BF (no non-shortest form)
 *   S_F4      24    After 0xF4; next must be 80-8F (no >U+10FFFF)
 *
 *  State value offsets are chosen by an SMT solver so all transition
 *  rows fit in a plain uint32_t.
 *
 *  S_ERROR = 0 is not arbitrary: any transition to S_ERROR contributes
 *  (0 << offset) = 0 to the row value, which is itself S_ERROR at every
 *  state offset. The trap is enforced for free by the encoding.
 *
 *  If states or transitions are changed, rerun tool/smt_solver.py to 
 *  find new valid offsets that still pack into uint32_t.
 *
 *
 * TRANSITION TABLE
 * ----------------
 *                                Current State
 *
 *  Input Byte   ACCEPT  TAIL1  TAIL2  TAIL3    E0     ED     F0     F4
 *  ----------   ------  ------ ------ ------ ------ ------ ------ ------
 *   00..7F      ACCEPT    -      -      -      -      -      -      -
 *   80..8F        -     ACCEPT TAIL1  TAIL2    -    TAIL1    -    TAIL2
 *   90..9F        -     ACCEPT TAIL1  TAIL2    -    TAIL1  TAIL2    -
 *   A0..BF        -     ACCEPT TAIL1  TAIL2  TAIL1    -    TAIL2    -
 *   C0..C1        -       -      -      -      -      -      -      -
 *   C2..DF      TAIL1     -      -      -      -      -      -      -
 *   E0          E0        -      -      -      -      -      -      -
 *   E1..EC      TAIL2     -      -      -      -      -      -      -
 *   ED          ED        -      -      -      -      -      -      -
 *   EE..EF      TAIL2     -      -      -      -      -      -      -
 *   F0          F0        -      -      -      -      -      -      -
 *   F1..F3      TAIL3     -      -      -      -      -      -      -
 *   F4          F4        -      -      -      -      -      -      -
 *   F5..FF        -       -      -      -      -      -      -      -
 *
 *  Note: "-" means transition to S_ERROR (invalid in that context)
 *
 *
 * STATE FLOW DIAGRAMS
 * -------------------
 *
 *  1-byte (ASCII):
 *    ACCEPT ─[0x00–0x7F]─→ ACCEPT
 *
 *  2-byte (U+0080–U+07FF):
 *    ACCEPT ─[0xC2–0xDF]─→ TAIL1 ─[0x80–0xBF]─→ ACCEPT
 *
 *  3-byte (U+0800–U+FFFF, excluding surrogates U+D800–U+DFFF):
 *    ACCEPT ─[lead]─→ [state] ─[cont1]─→ TAIL1 ─[cont2]─→ ACCEPT
 *      │                 │        │
 *      ├── 0xE0 ───────→ E0 ──────┴─ 0xA0–0xBF (no non-shortest form)
 *      ├── 0xED ───────→ ED ──────┴─ 0x80–0x9F (no surrogates)
 *      └── 0xE1–0xEC, ─→ TAIL2 ───┴─ 0x80–0xBF (unrestricted)
 *          0xEE–0xEF
 *
 *  4-byte (U+10000–U+10FFFF):
 *    ACCEPT ─[lead]─→ [state] ─[cont1]─→ TAIL2 ─[cont2]─→ TAIL1 ─[cont3]─→ ACCEPT
 *      │                 │        │
 *      ├── 0xF0 ───────→ F0 ──────┴─ 0x90–0xBF (no non-shortest form)
 *      ├── 0xF4 ───────→ F4 ──────┴─ 0x80–0x8F (no >U+10FFFF)
 *      └── 0xF1–0xF3 ──→ TAIL3 ───┴─ 0x80–0xBF (unrestricted)
 *
 *
 * UTF-8 ENCODING FORM
 * -------------------
 *
 *    U+0000..U+007F       0xxxxxxx
 *    U+0080..U+07FF       110xxxxx 10xxxxxx
 *    U+0800..U+FFFF       1110xxxx 10xxxxxx 10xxxxxx
 *   U+10000..U+10FFFF     11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
 *
 *
 *    U+0000..U+007F       00..7F
 *                      N  C0..C1  80..BF                   1100000x 10xxxxxx
 *    U+0080..U+07FF       C2..DF  80..BF
 *                      N  E0      80..9F  80..BF           11100000 100xxxxx
 *    U+0800..U+0FFF       E0      A0..BF  80..BF
 *    U+1000..U+CFFF       E1..EC  80..BF  80..BF
 *    U+D000..U+D7FF       ED      80..9F  80..BF
 *                      S  ED      A0..BF  80..BF           11101101 101xxxxx
 *    U+E000..U+FFFF       EE..EF  80..BF  80..BF
 *                      N  F0      80..8F  80..BF  80..BF   11110000 1000xxxx
 *   U+10000..U+3FFFF      F0      90..BF  80..BF  80..BF
 *   U+40000..U+FFFFF      F1..F3  80..BF  80..BF  80..BF
 *  U+100000..U+10FFFF     F4      80..8F  80..BF  80..BF   11110100 1000xxxx
 *
 *  Legend:
 *    N = Non-shortest form
 *    S = Surrogates
 *
 *
 * PERFORMANCE
 * -----------
 *
 *  - 9 states total (minimal for well-formed forward UTF-8 validation)
 *  - Table-driven: 256-entry uint32_t table (1 KB, fits in L1 cache)
 *  - Branchless step: (table[byte] >> state) & 31
 *
 *
 * REFERENCES
 * ----------
 *
 *  - Unicode Standard §3.9: Unicode Encoding Forms
 *     <https://www.unicode.org/versions/latest/core-spec/chapter-3/#G31703>
 *
 *
 * USAGE PATTERN
 * -------------
 *
 *   utf8_dfa_state_t state = UTF8_DFA_ACCEPT;
 *   for (size_t i = 0; i < len; i++) {
 *     state = utf8_dfa_step(state, buffer[i]);
 *     if (state == UTF8_DFA_REJECT) {
 *       // Invalid UTF-8 at position i
 *       break;
 *     }
 *     if (state == UTF8_DFA_ACCEPT) {
 *       // Complete valid sequence at position i
 *     }
 *   }
 *
 */
#ifndef UTF8_DFA32_H
#define UTF8_DFA32_H
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef uint32_t utf8_dfa_state_t;

#define UTF8_DFA_REJECT ((utf8_dfa_state_t)0)
#define UTF8_DFA_ACCEPT ((utf8_dfa_state_t)6)

#define S_ERROR   0
#define S_ACCEPT  6
#define S_TAIL1  16
#define S_TAIL2   1
#define S_TAIL3  18
#define S_E0     19
#define S_ED     25
#define S_F0     11
#define S_F4     24

/* clang-format off */

#define DFA_ROW(accept,error,tail1,tail2,tail3,e0,ed,f0,f4) \
  ( ((utf8_dfa_state_t)(accept) << S_ACCEPT) \
  | ((utf8_dfa_state_t)(error)  << S_ERROR) \
  | ((utf8_dfa_state_t)(tail1)  << S_TAIL1) \
  | ((utf8_dfa_state_t)(tail2)  << S_TAIL2) \
  | ((utf8_dfa_state_t)(tail3)  << S_TAIL3) \
  | ((utf8_dfa_state_t)(e0)     << S_E0) \
  | ((utf8_dfa_state_t)(ed)     << S_ED) \
  | ((utf8_dfa_state_t)(f0)     << S_F0) \
  | ((utf8_dfa_state_t)(f4)     << S_F4) )

#define ERR S_ERROR

#define ASCII_ROW DFA_ROW(S_ACCEPT,ERR,ERR,ERR,ERR,ERR,ERR,ERR,ERR)
#define LEAD2_ROW DFA_ROW(S_TAIL1,ERR,ERR,ERR,ERR,ERR,ERR,ERR,ERR)
#define LEAD3_ROW DFA_ROW(S_TAIL2,ERR,ERR,ERR,ERR,ERR,ERR,ERR,ERR)
#define LEAD4_ROW DFA_ROW(S_TAIL3,ERR,ERR,ERR,ERR,ERR,ERR,ERR,ERR)
#define ERROR_ROW DFA_ROW(ERR,ERR,ERR,ERR,ERR,ERR,ERR,ERR,ERR)

#define E0_ROW DFA_ROW(S_E0,ERR,ERR,ERR,ERR,ERR,ERR,ERR,ERR)
#define ED_ROW DFA_ROW(S_ED,ERR,ERR,ERR,ERR,ERR,ERR,ERR,ERR)
#define F0_ROW DFA_ROW(S_F0,ERR,ERR,ERR,ERR,ERR,ERR,ERR,ERR)
#define F4_ROW DFA_ROW(S_F4,ERR,ERR,ERR,ERR,ERR,ERR,ERR,ERR)

/*
 * Continuation byte rows:
 *
 * Columns: ACCEPT  ERROR   TAIL1     TAIL2    TAIL3    E0       ED       F0       F4
 *
 * 80-8F:   ERR     ERR    ->ACCEPT  ->TAIL1  ->TAIL2  ->ERR    ->TAIL1  ->ERR    ->TAIL2
 * 90-9F:   ERR     ERR    ->ACCEPT  ->TAIL1  ->TAIL2  ->ERR    ->TAIL1  ->TAIL2  ->ERR
 * A0-BF:   ERR     ERR    ->ACCEPT  ->TAIL1  ->TAIL2  ->TAIL1  ->ERR    ->TAIL2  ->ERR
 */
#define CONT_80_8F DFA_ROW(ERR,ERR,S_ACCEPT,S_TAIL1,S_TAIL2,ERR,    S_TAIL1,ERR,     S_TAIL2)
#define CONT_90_9F DFA_ROW(ERR,ERR,S_ACCEPT,S_TAIL1,S_TAIL2,ERR,    S_TAIL1,S_TAIL2, ERR)
#define CONT_A0_BF DFA_ROW(ERR,ERR,S_ACCEPT,S_TAIL1,S_TAIL2,S_TAIL1,ERR,    S_TAIL2, ERR)

static const utf8_dfa_state_t utf8_dfa[256] = {
  // 00-7F
  [0x00]=ASCII_ROW,[0x01]=ASCII_ROW,[0x02]=ASCII_ROW,[0x03]=ASCII_ROW,
  [0x04]=ASCII_ROW,[0x05]=ASCII_ROW,[0x06]=ASCII_ROW,[0x07]=ASCII_ROW,
  [0x08]=ASCII_ROW,[0x09]=ASCII_ROW,[0x0A]=ASCII_ROW,[0x0B]=ASCII_ROW,
  [0x0C]=ASCII_ROW,[0x0D]=ASCII_ROW,[0x0E]=ASCII_ROW,[0x0F]=ASCII_ROW,
  [0x10]=ASCII_ROW,[0x11]=ASCII_ROW,[0x12]=ASCII_ROW,[0x13]=ASCII_ROW,
  [0x14]=ASCII_ROW,[0x15]=ASCII_ROW,[0x16]=ASCII_ROW,[0x17]=ASCII_ROW,
  [0x18]=ASCII_ROW,[0x19]=ASCII_ROW,[0x1A]=ASCII_ROW,[0x1B]=ASCII_ROW,
  [0x1C]=ASCII_ROW,[0x1D]=ASCII_ROW,[0x1E]=ASCII_ROW,[0x1F]=ASCII_ROW,
  [0x20]=ASCII_ROW,[0x21]=ASCII_ROW,[0x22]=ASCII_ROW,[0x23]=ASCII_ROW,
  [0x24]=ASCII_ROW,[0x25]=ASCII_ROW,[0x26]=ASCII_ROW,[0x27]=ASCII_ROW,
  [0x28]=ASCII_ROW,[0x29]=ASCII_ROW,[0x2A]=ASCII_ROW,[0x2B]=ASCII_ROW,
  [0x2C]=ASCII_ROW,[0x2D]=ASCII_ROW,[0x2E]=ASCII_ROW,[0x2F]=ASCII_ROW,
  [0x30]=ASCII_ROW,[0x31]=ASCII_ROW,[0x32]=ASCII_ROW,[0x33]=ASCII_ROW,
  [0x34]=ASCII_ROW,[0x35]=ASCII_ROW,[0x36]=ASCII_ROW,[0x37]=ASCII_ROW,
  [0x38]=ASCII_ROW,[0x39]=ASCII_ROW,[0x3A]=ASCII_ROW,[0x3B]=ASCII_ROW,
  [0x3C]=ASCII_ROW,[0x3D]=ASCII_ROW,[0x3E]=ASCII_ROW,[0x3F]=ASCII_ROW,
  [0x40]=ASCII_ROW,[0x41]=ASCII_ROW,[0x42]=ASCII_ROW,[0x43]=ASCII_ROW,
  [0x44]=ASCII_ROW,[0x45]=ASCII_ROW,[0x46]=ASCII_ROW,[0x47]=ASCII_ROW,
  [0x48]=ASCII_ROW,[0x49]=ASCII_ROW,[0x4A]=ASCII_ROW,[0x4B]=ASCII_ROW,
  [0x4C]=ASCII_ROW,[0x4D]=ASCII_ROW,[0x4E]=ASCII_ROW,[0x4F]=ASCII_ROW,
  [0x50]=ASCII_ROW,[0x51]=ASCII_ROW,[0x52]=ASCII_ROW,[0x53]=ASCII_ROW,
  [0x54]=ASCII_ROW,[0x55]=ASCII_ROW,[0x56]=ASCII_ROW,[0x57]=ASCII_ROW,
  [0x58]=ASCII_ROW,[0x59]=ASCII_ROW,[0x5A]=ASCII_ROW,[0x5B]=ASCII_ROW,
  [0x5C]=ASCII_ROW,[0x5D]=ASCII_ROW,[0x5E]=ASCII_ROW,[0x5F]=ASCII_ROW,
  [0x60]=ASCII_ROW,[0x61]=ASCII_ROW,[0x62]=ASCII_ROW,[0x63]=ASCII_ROW,
  [0x64]=ASCII_ROW,[0x65]=ASCII_ROW,[0x66]=ASCII_ROW,[0x67]=ASCII_ROW,
  [0x68]=ASCII_ROW,[0x69]=ASCII_ROW,[0x6A]=ASCII_ROW,[0x6B]=ASCII_ROW,
  [0x6C]=ASCII_ROW,[0x6D]=ASCII_ROW,[0x6E]=ASCII_ROW,[0x6F]=ASCII_ROW,
  [0x70]=ASCII_ROW,[0x71]=ASCII_ROW,[0x72]=ASCII_ROW,[0x73]=ASCII_ROW,
  [0x74]=ASCII_ROW,[0x75]=ASCII_ROW,[0x76]=ASCII_ROW,[0x77]=ASCII_ROW,
  [0x78]=ASCII_ROW,[0x79]=ASCII_ROW,[0x7A]=ASCII_ROW,[0x7B]=ASCII_ROW,
  [0x7C]=ASCII_ROW,[0x7D]=ASCII_ROW,[0x7E]=ASCII_ROW,[0x7F]=ASCII_ROW,
  // 80-8F
  [0x80]=CONT_80_8F,[0x81]=CONT_80_8F,[0x82]=CONT_80_8F,[0x83]=CONT_80_8F,
  [0x84]=CONT_80_8F,[0x85]=CONT_80_8F,[0x86]=CONT_80_8F,[0x87]=CONT_80_8F,
  [0x88]=CONT_80_8F,[0x89]=CONT_80_8F,[0x8A]=CONT_80_8F,[0x8B]=CONT_80_8F,
  [0x8C]=CONT_80_8F,[0x8D]=CONT_80_8F,[0x8E]=CONT_80_8F,[0x8F]=CONT_80_8F,
  // 90-9F
  [0x90]=CONT_90_9F,[0x91]=CONT_90_9F,[0x92]=CONT_90_9F,[0x93]=CONT_90_9F,
  [0x94]=CONT_90_9F,[0x95]=CONT_90_9F,[0x96]=CONT_90_9F,[0x97]=CONT_90_9F,
  [0x98]=CONT_90_9F,[0x99]=CONT_90_9F,[0x9A]=CONT_90_9F,[0x9B]=CONT_90_9F,
  [0x9C]=CONT_90_9F,[0x9D]=CONT_90_9F,[0x9E]=CONT_90_9F,[0x9F]=CONT_90_9F,
  // A0-BF
  [0xA0]=CONT_A0_BF,[0xA1]=CONT_A0_BF,[0xA2]=CONT_A0_BF,[0xA3]=CONT_A0_BF,
  [0xA4]=CONT_A0_BF,[0xA5]=CONT_A0_BF,[0xA6]=CONT_A0_BF,[0xA7]=CONT_A0_BF,
  [0xA8]=CONT_A0_BF,[0xA9]=CONT_A0_BF,[0xAA]=CONT_A0_BF,[0xAB]=CONT_A0_BF,
  [0xAC]=CONT_A0_BF,[0xAD]=CONT_A0_BF,[0xAE]=CONT_A0_BF,[0xAF]=CONT_A0_BF,
  [0xB0]=CONT_A0_BF,[0xB1]=CONT_A0_BF,[0xB2]=CONT_A0_BF,[0xB3]=CONT_A0_BF,
  [0xB4]=CONT_A0_BF,[0xB5]=CONT_A0_BF,[0xB6]=CONT_A0_BF,[0xB7]=CONT_A0_BF,
  [0xB8]=CONT_A0_BF,[0xB9]=CONT_A0_BF,[0xBA]=CONT_A0_BF,[0xBB]=CONT_A0_BF,
  [0xBC]=CONT_A0_BF,[0xBD]=CONT_A0_BF,[0xBE]=CONT_A0_BF,[0xBF]=CONT_A0_BF,
  // C0-C1
  [0xC0]=ERROR_ROW,[0xC1]=ERROR_ROW,
  // C2-DF
  [0xC2]=LEAD2_ROW,[0xC3]=LEAD2_ROW,[0xC4]=LEAD2_ROW,[0xC5]=LEAD2_ROW,
  [0xC6]=LEAD2_ROW,[0xC7]=LEAD2_ROW,[0xC8]=LEAD2_ROW,[0xC9]=LEAD2_ROW,
  [0xCA]=LEAD2_ROW,[0xCB]=LEAD2_ROW,[0xCC]=LEAD2_ROW,[0xCD]=LEAD2_ROW,
  [0xCE]=LEAD2_ROW,[0xCF]=LEAD2_ROW,[0xD0]=LEAD2_ROW,[0xD1]=LEAD2_ROW,
  [0xD2]=LEAD2_ROW,[0xD3]=LEAD2_ROW,[0xD4]=LEAD2_ROW,[0xD5]=LEAD2_ROW,
  [0xD6]=LEAD2_ROW,[0xD7]=LEAD2_ROW,[0xD8]=LEAD2_ROW,[0xD9]=LEAD2_ROW,
  [0xDA]=LEAD2_ROW,[0xDB]=LEAD2_ROW,[0xDC]=LEAD2_ROW,[0xDD]=LEAD2_ROW,
  [0xDE]=LEAD2_ROW,[0xDF]=LEAD2_ROW,
  // E0
  [0xE0]=E0_ROW,
  // E1-EC
  [0xE1]=LEAD3_ROW,[0xE2]=LEAD3_ROW,[0xE3]=LEAD3_ROW,[0xE4]=LEAD3_ROW,
  [0xE5]=LEAD3_ROW,[0xE6]=LEAD3_ROW,[0xE7]=LEAD3_ROW,[0xE8]=LEAD3_ROW,
  [0xE9]=LEAD3_ROW,[0xEA]=LEAD3_ROW,[0xEB]=LEAD3_ROW,[0xEC]=LEAD3_ROW,
  // ED
  [0xED]=ED_ROW,
  // EE-EF
  [0xEE]=LEAD3_ROW,[0xEF]=LEAD3_ROW,
  // F0
  [0xF0]=F0_ROW,
  // F1-F3
  [0xF1]=LEAD4_ROW,[0xF2]=LEAD4_ROW,[0xF3]=LEAD4_ROW,
  // F4
  [0xF4]=F4_ROW,
  // F5-FF
  [0xF5]=ERROR_ROW,[0xF6]=ERROR_ROW,[0xF7]=ERROR_ROW,[0xF8]=ERROR_ROW,
  [0xF9]=ERROR_ROW,[0xFA]=ERROR_ROW,[0xFB]=ERROR_ROW,[0xFC]=ERROR_ROW,
  [0xFD]=ERROR_ROW,[0xFE]=ERROR_ROW,[0xFF]=ERROR_ROW,
};

/* clang-format on */

#undef S_ERROR
#undef S_ACCEPT
#undef S_TAIL1
#undef S_TAIL2
#undef S_TAIL3
#undef S_E0
#undef S_ED
#undef S_F0
#undef S_F4

#undef ERR
#undef DFA_ROW
#undef ASCII_ROW
#undef CONT_80_8F
#undef CONT_90_9F
#undef CONT_A0_BF
#undef LEAD2_ROW
#undef LEAD3_ROW
#undef LEAD4_ROW
#undef ERROR_ROW
#undef E0_ROW
#undef ED_ROW
#undef F0_ROW
#undef F4_ROW

static inline utf8_dfa_state_t utf8_dfa_step(utf8_dfa_state_t state,
                                             unsigned char c) {
  return (utf8_dfa[c] >> state) & 31;
}

static inline utf8_dfa_state_t utf8_dfa_run(utf8_dfa_state_t state,
                                            const unsigned char* src,
                                            size_t len) {
  for (size_t i = 0; i < len; i++)
    state = utf8_dfa[src[i]] >> (state & 31);
  return state & 31;
}

static inline utf8_dfa_state_t utf8_dfa_run16(utf8_dfa_state_t state,
                                              const unsigned char* src) {
  #pragma GCC unroll 16
  for (size_t i = 0; i < 16; i++)
    state = utf8_dfa[src[i]] >> (state & 31);
  return state & 31;
}

#ifdef __cplusplus
}
#endif
#endif // UTF8_DFA32_H
