#define FIX_0_382683433  ((s32)   98)		/* FIX(0.382683433) */
#define FIX_0_541196100  ((s32)  139)		/* FIX(0.541196100) */
#define FIX_0_707106781  ((s32)  181)		/* FIX(0.707106781) */
#define FIX_1_306562965  ((s32)  334)		/* FIX(1.306562965) */

#define DESCALE10(x) (s16)( ((x)+128) >> 8)
#define DESCALE20(x)  (s16)(((x)+32768) >> 16)
#define D_MULTIPLY(var,const)  ((s32) ((var) * (const)))

void RTjpeg_dct_init(void)
{
 int i;
 
 for(i=0; i<64; i++)
 {
  RTjpeg_lqt[i]=(((u64)RTjpeg_lqt[i]<<32)/RTjpeg_aan_tab[i]);
  RTjpeg_cqt[i]=(((u64)RTjpeg_cqt[i]<<32)/RTjpeg_aan_tab[i]);
 }
}

void RTjpeg_dct (u8 *idata, s16 *odata, int rskip)
{
  s32 tmp0, tmp1, tmp2, tmp3, tmp4, tmp5, tmp6, tmp7;
  s32 tmp10, tmp11, tmp12, tmp13;
  s32 z1, z2, z3, z4, z5, z11, z13;
  u8 *idataptr;
  s16 *odataptr;
  s32 *wsptr;
  int ctr;

  idataptr = idata;
  wsptr = RTjpeg_ws;
  for (ctr = 7; ctr >= 0; ctr--) {
    tmp0 = idataptr[0] + idataptr[7];
    tmp7 = idataptr[0] - idataptr[7];
    tmp1 = idataptr[1] + idataptr[6];
    tmp6 = idataptr[1] - idataptr[6];
    tmp2 = idataptr[2] + idataptr[5];
    tmp5 = idataptr[2] - idataptr[5];
    tmp3 = idataptr[3] + idataptr[4];
    tmp4 = idataptr[3] - idataptr[4];
    
    tmp10 = (tmp0 + tmp3);	/* phase 2 */
    tmp13 = tmp0 - tmp3;
    tmp11 = (tmp1 + tmp2);
    tmp12 = tmp1 - tmp2;
    
    wsptr[0] = (tmp10 + tmp11)<<8; /* phase 3 */
    wsptr[4] = (tmp10 - tmp11)<<8;
    
    z1 = D_MULTIPLY(tmp12 + tmp13, FIX_0_707106781); /* c4 */
    wsptr[2] = (tmp13<<8) + z1;	/* phase 5 */
    wsptr[6] = (tmp13<<8) - z1;
    
    tmp10 = tmp4 + tmp5;	/* phase 2 */
    tmp11 = tmp5 + tmp6;
    tmp12 = tmp6 + tmp7;

    z5 = D_MULTIPLY(tmp10 - tmp12, FIX_0_382683433); /* c6 */
    z2 = D_MULTIPLY(tmp10, FIX_0_541196100) + z5; /* c2-c6 */
    z4 = D_MULTIPLY(tmp12, FIX_1_306562965) + z5; /* c2+c6 */
    z3 = D_MULTIPLY(tmp11, FIX_0_707106781); /* c4 */

    z11 = (tmp7<<8) + z3;		/* phase 5 */
    z13 = (tmp7<<8) - z3;

    wsptr[5] = z13 + z2;	/* phase 6 */
    wsptr[3] = z13 - z2;
    wsptr[1] = z11 + z4;
    wsptr[7] = z11 - z4;

    idataptr += rskip;		/* advance pointer to next row */
    wsptr += 8;
  }

  wsptr = RTjpeg_ws;
  odataptr=odata;
  for (ctr = 7; ctr >= 0; ctr--) {
    tmp0 = wsptr[0] + wsptr[56];
    tmp7 = wsptr[0] - wsptr[56];
    tmp1 = wsptr[8] + wsptr[48];
    tmp6 = wsptr[8] - wsptr[48];
    tmp2 = wsptr[16] + wsptr[40];
    tmp5 = wsptr[16] - wsptr[40];
    tmp3 = wsptr[24] + wsptr[32];
    tmp4 = wsptr[24] - wsptr[32];
    
    tmp10 = tmp0 + tmp3;	/* phase 2 */
    tmp13 = tmp0 - tmp3;
    tmp11 = tmp1 + tmp2;
    tmp12 = tmp1 - tmp2;
    
    odataptr[0] = DESCALE10(tmp10 + tmp11); /* phase 3 */
    odataptr[32] = DESCALE10(tmp10 - tmp11);
    
    z1 = D_MULTIPLY(tmp12 + tmp13, FIX_0_707106781); /* c4 */
    odataptr[16] = DESCALE20((tmp13<<8) + z1); /* phase 5 */
    odataptr[48] = DESCALE20((tmp13<<8) - z1);

    tmp10 = tmp4 + tmp5;	/* phase 2 */
    tmp11 = tmp5 + tmp6;
    tmp12 = tmp6 + tmp7;

    z5 = D_MULTIPLY(tmp10 - tmp12, FIX_0_382683433); /* c6 */
    z2 = D_MULTIPLY(tmp10, FIX_0_541196100) + z5; /* c2-c6 */
    z4 = D_MULTIPLY(tmp12, FIX_1_306562965) + z5; /* c2+c6 */
    z3 = D_MULTIPLY(tmp11, FIX_0_707106781); /* c4 */

    z11 = (tmp7<<8) + z3;		/* phase 5 */
    z13 = (tmp7<<8) - z3;

    odataptr[40] = DESCALE20(z13 + z2); /* phase 6 */
    odataptr[24] = DESCALE20(z13 - z2);
    odataptr[8] = DESCALE20(z11 + z4);
    odataptr[56] = DESCALE20(z11 - z4);

    odataptr++;			/* advance pointer to next column */
    wsptr++;
  }
}
