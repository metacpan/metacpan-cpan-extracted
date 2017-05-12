/*
 * Copyright (c) 2012 Marc Alexander Lehmann <schmorp@schmorp.de>
 * 
 * Redistribution and use in source and binary forms, with or without modifica-
 * tion, are permitted provided that the following conditions are met:
 * 
 *   1.  Redistributions of source code must retain the above copyright notice,
 *       this list of conditions and the following disclaimer.
 * 
 *   2.  Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MER-
 * CHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPE-
 * CIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTH-
 * ERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Alternatively, the contents of this file may be used under the terms of
 * the GNU General Public License ("GPL") version 2 or any later version,
 * in which case the provisions of the GPL are applicable instead of
 * the above. If you wish to allow the use of your version of this file
 * only under the terms of the GPL and not to allow others to use your
 * version of this file under the BSD license, indicate your decision
 * by deleting the provisions above and replace them with the notice
 * and other provisions required by the GPL. If you do not delete the
 * provisions above, a recipient may use your version of this file under
 * either the BSD or the GPL.
 */

#ifndef URLIB_H_
#define URLIB_H_

#define URLADER "urlader"
#define URLADER_VERSION "1.0" /* a decimal number, not a version string */

enum
{
  T_NULL, // 5
  T_META, // 1 : exe_id, exe_ver
  T_ENV,  // 2 : name, value
  T_ARG,  // 3 : arg
  T_DIR,  // 4+: path
  T_FILE, // 4+: path, data
  T_NUM
};

enum
{
  F_LZF  = 0x01,
  F_EXEC = 0x10,
  F_NULL = 0
};

#define TAIL_MAGIC "ScHmOrp_PaCk_000"

struct u_pack_hdr
{
  unsigned char type;
  unsigned char flags;
  unsigned char namelen[2];
  unsigned char datalen[4];
};

#define u_16(ptr) (((ptr)[0] << 8) | (ptr)[1])
#define u_32(ptr) (((ptr)[0] << 24) | ((ptr)[1] << 16) | ((ptr)[2] << 8) | (ptr)[3])

struct u_pack_tail {
  unsigned char max_uncompressed[4]; /* maximum uncompressed file size */
  unsigned char size[4]; /* how many bytes to seke backwards from end(!) of tail */
  unsigned char reserved[8]; /* must be 0 */
  char magic[16];
  char md5_head[16]; /* md5(urlader) or 0, if there is no checksum */
  char md5_pack[16]; /* md5(pack) or 0, if there is no checksum */
};

#endif

