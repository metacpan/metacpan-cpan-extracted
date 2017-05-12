#define FIX_1_082392200  ((s32)  277)		/* FIX(1.082392200) */
#define FIX_1_414213562  ((s32)  362)		/* FIX(1.414213562) */
#define FIX_1_847759065  ((s32)  473)		/* FIX(1.847759065) */
#define FIX_2_613125930  ((s32)  669)		/* FIX(2.613125930) */

#define DESCALE(x) (s16)( ((x)+4) >> 3)

/* clip yuv to 16..235 (should be 16..240 for cr/cb but ... */

#define RL(x) ((x)>235) ? 235 : (((x)<16) ? 16 : (x))
#define MULTIPLY(var,const)  (((s32) ((var) * (const)) + 128)>>8)

void RTjpeg_idct_init(void)
{
 int i;
 
 for(i=0; i<64; i++)
 {
  RTjpeg_liqt[i]=((u64)RTjpeg_liqt[i]*RTjpeg_aan_tab[i])>>32;
  RTjpeg_ciqt[i]=((u64)RTjpeg_ciqt[i]*RTjpeg_aan_tab[i])>>32;
 }
}

void RTjpeg_idct(u8 *odata, s16 *data, int rskip)
{
  s32 tmp0, tmp1, tmp2, tmp3, tmp4, tmp5, tmp6, tmp7;
  s32 tmp10, tmp11, tmp12, tmp13;
  s32 z5, z10, z11, z12, z13;
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
      dcval = inptr[0];
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
    
    tmp0 = inptr[0];
    tmp1 = inptr[16];
    tmp2 = inptr[32];
    tmp3 = inptr[48];

    tmp10 = tmp0 + tmp2;
    tmp11 = tmp0 - tmp2;

    tmp13 = tmp1 + tmp3;
    tmp12 = MULTIPLY(tmp1 - tmp3, FIX_1_414213562) - tmp13;

    tmp0 = tmp10 + tmp13;
    tmp3 = tmp10 - tmp13;
    tmp1 = tmp11 + tmp12;
    tmp2 = tmp11 - tmp12;
    
    tmp4 = inptr[8];
    tmp5 = inptr[24];
    tmp6 = inptr[40];
    tmp7 = inptr[56];

    z13 = tmp6 + tmp5;
    z10 = tmp6 - tmp5;
    z11 = tmp4 + tmp7;
    z12 = tmp4 - tmp7;

    tmp7 = z11 + z13;
    tmp11 = MULTIPLY(z11 - z13, FIX_1_414213562);

    z5 = MULTIPLY(z10 + z12, FIX_1_847759065);
    tmp10 = MULTIPLY(z12, FIX_1_082392200) - z5;
    tmp12 = MULTIPLY(z10, - FIX_2_613125930) + z5;

    tmp6 = tmp12 - tmp7;
    tmp5 = tmp11 - tmp6;
    tmp4 = tmp10 + tmp5;

    wsptr[0] = (s32) (tmp0 + tmp7);
    wsptr[56] = (s32) (tmp0 - tmp7);
    wsptr[8] = (s32) (tmp1 + tmp6);
    wsptr[48] = (s32) (tmp1 - tmp6);
    wsptr[16] = (s32) (tmp2 + tmp5);
    wsptr[40] = (s32) (tmp2 - tmp5);
    wsptr[32] = (s32) (tmp3 + tmp4);
    wsptr[24] = (s32) (tmp3 - tmp4);

    inptr++;
    wsptr++;
  }

  wsptr = workspace;
  for (ctr = 0; ctr < 8; ctr++) {
    outptr = &(odata[ctr*rskip]);

    tmp10 = wsptr[0] + wsptr[4];
    tmp11 = wsptr[0] - wsptr[4];

    tmp13 = wsptr[2] + wsptr[6];
    tmp12 = MULTIPLY(wsptr[2] - wsptr[6], FIX_1_414213562) - tmp13;

    tmp0 = tmp10 + tmp13;
    tmp3 = tmp10 - tmp13;
    tmp1 = tmp11 + tmp12;
    tmp2 = tmp11 - tmp12;

    z13 = wsptr[5] + wsptr[3];
    z10 = wsptr[5] - wsptr[3];
    z11 = wsptr[1] + wsptr[7];
    z12 = wsptr[1] - wsptr[7];

    tmp7 = z11 + z13;
    tmp11 = MULTIPLY(z11 - z13, FIX_1_414213562);

    z5 = MULTIPLY(z10 + z12, FIX_1_847759065);
    tmp10 = MULTIPLY(z12, FIX_1_082392200) - z5;
    tmp12 = MULTIPLY(z10, - FIX_2_613125930) + z5;

    tmp6 = tmp12 - tmp7;
    tmp5 = tmp11 - tmp6;
    tmp4 = tmp10 + tmp5;

    outptr[0] = RL(DESCALE(tmp0 + tmp7));
    outptr[7] = RL(DESCALE(tmp0 - tmp7));
    outptr[1] = RL(DESCALE(tmp1 + tmp6));
    outptr[6] = RL(DESCALE(tmp1 - tmp6));
    outptr[2] = RL(DESCALE(tmp2 + tmp5));
    outptr[5] = RL(DESCALE(tmp2 - tmp5));
    outptr[4] = RL(DESCALE(tmp3 + tmp4));
    outptr[3] = RL(DESCALE(tmp3 - tmp4));

    wsptr += 8;
  }
}
