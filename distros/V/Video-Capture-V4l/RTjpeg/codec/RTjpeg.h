#include "stdint.h"

typedef int8_t   s8;
typedef int16_t  s16;
typedef int32_t  s32;
typedef uint8_t  u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;

typedef u32 RTjpeg_tables[128];

void RTjpeg_init_Q(u8 Q);
void RTjpeg_init_compress(u32 *buf, int width, int height, u8 Q);
void RTjpeg_init_decompress(u32 *buf, int width, int height);
int RTjpeg_compress(s8 *sp, unsigned char *bp);
void RTjpeg_decompress(s8 *sp, u8 *bp);

void RTjpeg_init_mcompress(void);
int RTjpeg_mcompress(s8 *sp, unsigned char *bp, u16 lmask, u16 cmask,
		     int x, int y, int w, int h);
void RTjpeg_set_test(int i);

void RTjpeg_yuvrgb(u8 *buf, u8 *rgb);
void RTjpeg_yuvrgb32(u8 *buf, u8 *rgb);
void RTjpeg_yuvrgb24(u8 *buf, u8 *rgb);
void RTjpeg_yuvrgb16(u8 *buf, u8 *rgb);
void RTjpeg_yuvrgb8(u8 *buf, u8 *rgb);

void RTjpeg_double32(u32 *buf);
void RTjpeg_double24(u8 *buf);
void RTjpeg_double16(u16 *buf);
void RTjpeg_double8(u8 *buf);
