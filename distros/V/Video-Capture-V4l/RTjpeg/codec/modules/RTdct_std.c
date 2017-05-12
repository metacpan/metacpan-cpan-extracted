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

void RTjpeg_dct_init(void)
{
}

void RTjpeg_dct(u8 *idata, s16 *odata, int rskip)
{
  s32 tmp0, tmp1, tmp2, tmp3, tmp4, tmp5, tmp6, tmp7;
  s32 tmp10, tmp11, tmp12, tmp13;
  s32 z1, z2, z3, z4, z5;
  u8 *idataptr;
  s16 * odataptr;
  int ctr;

  idataptr = idata;
  odataptr = odata;
  for (ctr = 7; ctr >= 0; ctr--) {
    tmp0 = idataptr[0] + idataptr[7];
    tmp7 = idataptr[0] - idataptr[7];
    tmp1 = idataptr[1] + idataptr[6];
    tmp6 = idataptr[1] - idataptr[6];
    tmp2 = idataptr[2] + idataptr[5];
    tmp5 = idataptr[2] - idataptr[5];
    tmp3 = idataptr[3] + idataptr[4];
    tmp4 = idataptr[3] - idataptr[4];
    
    tmp10 = tmp0 + tmp3;
    tmp13 = tmp0 - tmp3;
    tmp11 = tmp1 + tmp2;
    tmp12 = tmp1 - tmp2;
    
    odataptr[0] = (s32) ((tmp10 + tmp11) << 2);
    odataptr[4] = (s32) ((tmp10 - tmp11) << 2);
    
    z1 = MULTIPLY(tmp12 + tmp13, FIX_0_541196100);
    odataptr[2] = (s32) DESCALE(z1 + MULTIPLY(tmp13, FIX_0_765366865), 11);
    odataptr[6] = (s32) DESCALE(z1 + MULTIPLY(tmp12, - FIX_1_847759065), 11);
    
    z1 = tmp4 + tmp7;
    z2 = tmp5 + tmp6;
    z3 = tmp4 + tmp6;
    z4 = tmp5 + tmp7;
    z5 = MULTIPLY(z3 + z4, FIX_1_175875602); /* sqrt(2) * c3 */
    
    tmp4 = MULTIPLY(tmp4, FIX_0_298631336); /* sqrt(2) * (-c1+c3+c5-c7) */
    tmp5 = MULTIPLY(tmp5, FIX_2_053119869); /* sqrt(2) * ( c1+c3-c5+c7) */
    tmp6 = MULTIPLY(tmp6, FIX_3_072711026); /* sqrt(2) * ( c1+c3+c5-c7) */
    tmp7 = MULTIPLY(tmp7, FIX_1_501321110); /* sqrt(2) * ( c1+c3-c5-c7) */
    z1 = MULTIPLY(z1, - FIX_0_899976223); /* sqrt(2) * (c7-c3) */
    z2 = MULTIPLY(z2, - FIX_2_562915447); /* sqrt(2) * (-c1-c3) */
    z3 = MULTIPLY(z3, - FIX_1_961570560); /* sqrt(2) * (-c3-c5) */
    z4 = MULTIPLY(z4, - FIX_0_390180644); /* sqrt(2) * (c5-c3) */
    
    z3 += z5;
    z4 += z5;
    
    odataptr[7] = (s32) DESCALE(tmp4 + z1 + z3, 11);
    odataptr[5] = (s32) DESCALE(tmp5 + z2 + z4, 11);
    odataptr[3] = (s32) DESCALE(tmp6 + z2 + z3, 11);
    odataptr[1] = (s32) DESCALE(tmp7 + z1 + z4, 11);
    
    odataptr += 8;		/* advance pointer to next row */
    idataptr += rskip;
  }

  odataptr = odata;
  for (ctr = 7; ctr >= 0; ctr--) {
    tmp0 = odataptr[0] + odataptr[56];
    tmp7 = odataptr[0] - odataptr[56];
    tmp1 = odataptr[8] + odataptr[48];
    tmp6 = odataptr[8] - odataptr[48];
    tmp2 = odataptr[16] + odataptr[40];
    tmp5 = odataptr[16] - odataptr[40];
    tmp3 = odataptr[24] + odataptr[32];
    tmp4 = odataptr[24] - odataptr[32];
    
    tmp10 = tmp0 + tmp3;
    tmp13 = tmp0 - tmp3;
    tmp11 = tmp1 + tmp2;
    tmp12 = tmp1 - tmp2;
    
    odataptr[0] = (s32) DESCALE(tmp10 + tmp11, 2);
    odataptr[32] = (s32) DESCALE(tmp10 - tmp11, 2);
    
    z1 = MULTIPLY(tmp12 + tmp13, FIX_0_541196100);
    odataptr[16] = (s32) DESCALE(z1 + MULTIPLY(tmp13, FIX_0_765366865), 15);
    odataptr[48] = (s32) DESCALE(z1 + MULTIPLY(tmp12, - FIX_1_847759065), 15);
    
    z1 = tmp4 + tmp7;
    z2 = tmp5 + tmp6;
    z3 = tmp4 + tmp6;
    z4 = tmp5 + tmp7;
    z5 = MULTIPLY(z3 + z4, FIX_1_175875602); /* sqrt(2) * c3 */
    
    tmp4 = MULTIPLY(tmp4, FIX_0_298631336); /* sqrt(2) * (-c1+c3+c5-c7) */
    tmp5 = MULTIPLY(tmp5, FIX_2_053119869); /* sqrt(2) * ( c1+c3-c5+c7) */
    tmp6 = MULTIPLY(tmp6, FIX_3_072711026); /* sqrt(2) * ( c1+c3+c5-c7) */
    tmp7 = MULTIPLY(tmp7, FIX_1_501321110); /* sqrt(2) * ( c1+c3-c5-c7) */
    z1 = MULTIPLY(z1, - FIX_0_899976223); /* sqrt(2) * (c7-c3) */
    z2 = MULTIPLY(z2, - FIX_2_562915447); /* sqrt(2) * (-c1-c3) */
    z3 = MULTIPLY(z3, - FIX_1_961570560); /* sqrt(2) * (-c3-c5) */
    z4 = MULTIPLY(z4, - FIX_0_390180644); /* sqrt(2) * (c5-c3) */
    
    z3 += z5;
    z4 += z5;
    
    odataptr[56] = (s32) DESCALE(tmp4 + z1 + z3, 15);
    odataptr[40] = (s32) DESCALE(tmp5 + z2 + z4, 15);
    odataptr[24] = (s32) DESCALE(tmp6 + z2 + z3, 15);
    odataptr[8] = (s32) DESCALE(tmp7 + z1 + z4, 15);
    
    odataptr++;			/* advance pointer to next column */
  }
}
