#include <sys/types.h>

#define FIX_0_298631336  ((s32)  2446)	/* FIX(0.298631336) */
#define FIX_0_390180644  ((s32)  3196)	/* FIX(0.390180644) */
#define FIX_0_541196100  ((s32)  4433)	/* FIX(0.541196100) */
#define FIX_0_765366865  ((s32)  6270)	/* FIX(0.765366865) */
#define FIX_0_899976223  ((s32)  7373)	/* FIX(0.899976223) */
#define FIX_1_175875602  ((s32)  9633)	/* FIX(1.175875602) */
#define FIX_1_501321110  ((s32)  12299)	/* FIX(1.501321110) */
#define FIX_1_847759065  ((s32)  15137)	/* FIX(1.847759065) */
#define FIX_1_961570560  ((s32)  16069)	/* FIX(1.961570560) */
#define FIX_2_053119869  ((s32)  16819)	/* FIX(2.053119869) */
#define FIX_2_562915447  ((s32)  20995)	/* FIX(2.562915447) */
#define FIX_3_072711026  ((s32)  25172)	/* FIX(3.072711026) */

#define MULTIPLY(var,const)  ( (s32) ((var)*(const)) )
#define DESCALE(x,n) ((x)>>(n))

/* clip yuv to 16..235 (should be 16..240 for cr/cb but ... */

#define RL(x) ((x)>235) ? 235 : (((x)<16) ? 16 : (x))

void RTjpeg_idct_init(void)
{
}

void RTjpeg_idct(u8 *odata, s16 *data, int rskip)
{
  s32 tmp0, tmp1, tmp2, tmp3;
  s32 tmp10, tmp11, tmp12, tmp13;
  s32 z1, z2, z3, z4, z5;
  s16 *inptr;
  s32 *wsptr;
  u8 *outptr;
  int ctr;
  s32 dcval;
  s32 workspace[64];

  inptr = data;
  wsptr = workspace;
  for (ctr = 8; ctr > 0; ctr--) {
    
    if ((inptr[8] | inptr[16] | inptr[24] |
	 inptr[32] | inptr[40] | inptr[48] | inptr[56]) == 0) {
      dcval=inptr[0]<<2;
      wsptr[0] = dcval;
      wsptr[8] = dcval;
      wsptr[16] = dcval;
      wsptr[24] = dcval;
      wsptr[32] = dcval;
      wsptr[40] = dcval;
      wsptr[48] = dcval;
      wsptr[56] = dcval;
      inptr++;
      wsptr++;
      continue;
    } 
    
    z2 = inptr[16];
    z3 = inptr[48];
    z1 = MULTIPLY(z2 + z3, FIX_0_541196100);
    tmp2 = z1 + MULTIPLY(z3, - FIX_1_847759065);
    tmp3 = z1 + MULTIPLY(z2, FIX_0_765366865);
    z2 = inptr[0];
    z3 = inptr[32];

    tmp0 = (z2 + z3) << 13;
    tmp1 = (z2 - z3) << 13;
    
    tmp10 = tmp0 + tmp3;
    tmp13 = tmp0 - tmp3;
    tmp11 = tmp1 + tmp2;
    tmp12 = tmp1 - tmp2;
    
    tmp0 = inptr[56];
    tmp1 = inptr[40];
    tmp2 = inptr[24];
    tmp3 = inptr[8];
    
    z1 = tmp0 + tmp3;
    z2 = tmp1 + tmp2;
    z3 = tmp0 + tmp2;
    z4 = tmp1 + tmp3;
    z5 = MULTIPLY(z3 + z4, FIX_1_175875602); /* sqrt(2) * c3 */
    
    tmp0 = MULTIPLY(tmp0, FIX_0_298631336); /* sqrt(2) * (-c1+c3+c5-c7) */
    tmp1 = MULTIPLY(tmp1, FIX_2_053119869); /* sqrt(2) * ( c1+c3-c5+c7) */
    tmp2 = MULTIPLY(tmp2, FIX_3_072711026); /* sqrt(2) * ( c1+c3+c5-c7) */
    tmp3 = MULTIPLY(tmp3, FIX_1_501321110); /* sqrt(2) * ( c1+c3-c5-c7) */
    z1 = MULTIPLY(z1, - FIX_0_899976223); /* sqrt(2) * (c7-c3) */
    z2 = MULTIPLY(z2, - FIX_2_562915447); /* sqrt(2) * (-c1-c3) */
    z3 = MULTIPLY(z3, - FIX_1_961570560); /* sqrt(2) * (-c3-c5) */
    z4 = MULTIPLY(z4, - FIX_0_390180644); /* sqrt(2) * (c5-c3) */
    
    z3 += z5;
    z4 += z5;
    
    tmp0 += z1 + z3;
    tmp1 += z2 + z4;
    tmp2 += z2 + z3;
    tmp3 += z1 + z4;
    
    wsptr[0] = (int) DESCALE(tmp10 + tmp3, 11);
    wsptr[56] = (int) DESCALE(tmp10 - tmp3, 11);
    wsptr[8] = (int) DESCALE(tmp11 + tmp2, 11);
    wsptr[48] = (int) DESCALE(tmp11 - tmp2, 11);
    wsptr[16] = (int) DESCALE(tmp12 + tmp1, 11);
    wsptr[40] = (int) DESCALE(tmp12 - tmp1, 11);
    wsptr[24] = (int) DESCALE(tmp13 + tmp0, 11);
    wsptr[32] = (int) DESCALE(tmp13 - tmp0, 11);
    
    inptr++;			/* advance pointers to next column */
    wsptr++;
  }

  wsptr = workspace;
  for (ctr = 0; ctr < 8; ctr++) {
    outptr=&(odata[ctr*rskip]);
    z2 = (s32) wsptr[2];
    z3 = (s32) wsptr[6];
    
    z1 = MULTIPLY(z2 + z3, FIX_0_541196100);
    tmp2 = z1 + MULTIPLY(z3, - FIX_1_847759065);
    tmp3 = z1 + MULTIPLY(z2, FIX_0_765366865);
    
    tmp0 = ((s32) wsptr[0] + (s32) wsptr[4]) << 13;
    tmp1 = ((s32) wsptr[0] - (s32) wsptr[4]) << 13;
    
    tmp10 = tmp0 + tmp3;
    tmp13 = tmp0 - tmp3;
    tmp11 = tmp1 + tmp2;
    tmp12 = tmp1 - tmp2;
    
    tmp0 = (s32) wsptr[7];
    tmp1 = (s32) wsptr[5];
    tmp2 = (s32) wsptr[3];
    tmp3 = (s32) wsptr[1];
    
    z1 = tmp0 + tmp3;
    z2 = tmp1 + tmp2;
    z3 = tmp0 + tmp2;
    z4 = tmp1 + tmp3;
    z5 = MULTIPLY(z3 + z4, FIX_1_175875602);
    
    tmp0 = MULTIPLY(tmp0, FIX_0_298631336);
    tmp1 = MULTIPLY(tmp1, FIX_2_053119869);
    tmp2 = MULTIPLY(tmp2, FIX_3_072711026);
    tmp3 = MULTIPLY(tmp3, FIX_1_501321110);
    z1 = MULTIPLY(z1, - FIX_0_899976223);
    z2 = MULTIPLY(z2, - FIX_2_562915447);
    z3 = MULTIPLY(z3, - FIX_1_961570560);
    z4 = MULTIPLY(z4, - FIX_0_390180644);
    
    z3 += z5;
    z4 += z5;
    
    tmp0 += z1 + z3;
    tmp1 += z2 + z4;
    tmp2 += z2 + z3;
    tmp3 += z1 + z4;
    
    outptr[0] = (s32) RL(DESCALE(tmp10 + tmp3, 18));
    outptr[7] = (s32) RL(DESCALE(tmp10 - tmp3, 18));
    outptr[1] = (s32) RL(DESCALE(tmp11 + tmp2, 18));
    outptr[6] = (s32) RL(DESCALE(tmp11 - tmp2, 18));
    outptr[2] = (s32) RL(DESCALE(tmp12 + tmp1, 18));
    outptr[5] = (s32) RL(DESCALE(tmp12 - tmp1, 18));
    outptr[3] = (s32) RL(DESCALE(tmp13 + tmp0, 18));
    outptr[4] = (s32) RL(DESCALE(tmp13 - tmp0, 18));
    
    wsptr += 8;		
  }
}
