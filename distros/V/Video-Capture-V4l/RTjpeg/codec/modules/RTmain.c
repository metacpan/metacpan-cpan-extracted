/*

   Main Routines

   This file contains most of the initialisation and control functions

   (C) Justin Schoeman 1998

 */

/*

   Private function

   Initialise all the cache-aliged data blocks

 */

void
RTjpeg_init_data (void)
{
  unsigned long dptr;

  dptr = (unsigned long) &(RTjpeg_alldata[0]);
  dptr += 32;
  dptr = dptr >> 5;
  dptr = dptr << 5;		/* cache align data */

  RTjpeg_block = (s16 *) dptr;
  dptr += sizeof (s16) * 64;
  RTjpeg_lqt = (s32 *) dptr;
  dptr += sizeof (s32) * 64;
  RTjpeg_cqt = (s32 *) dptr;
  dptr += sizeof (s32) * 64;
  RTjpeg_liqt = (u32 *) dptr;
  dptr += sizeof (u32) * 64;
  RTjpeg_ciqt = (u32 *) dptr;
}

/*

   External Function

   Re-set quality factor

   Input: buf -> pointer to 128 ints for quant values store to pass back to
   init_decompress.
   Q -> quality factor (192=best, 32=worst)
 */

void
RTjpeg_init_Q (u8 Q)
{
  int i;
  u64 qual;

  qual = (u64) Q << (32 - 7);	/* 32 bit FP, 255=2, 0=0 */

  for (i = 0; i < 64; i++)
    {
      RTjpeg_lqt[i] = (s32) ((qual / ((u64) RTjpeg_lum_quant_tbl[i] << 16)) >> 3);
      if (RTjpeg_lqt[i] == 0)
	RTjpeg_lqt[i] = 1;
      RTjpeg_cqt[i] = (s32) ((qual / ((u64) RTjpeg_chrom_quant_tbl[i] << 16)) >> 3);
      if (RTjpeg_cqt[i] == 0)
	RTjpeg_cqt[i] = 1;
      RTjpeg_liqt[i] = (1 << 16) / (RTjpeg_lqt[i] << 3);
      RTjpeg_ciqt[i] = (1 << 16) / (RTjpeg_cqt[i] << 3);
      RTjpeg_lqt[i] = ((1 << 16) / RTjpeg_liqt[i]) >> 3;
      RTjpeg_cqt[i] = ((1 << 16) / RTjpeg_ciqt[i]) >> 3;
    }

  RTjpeg_lb8 = 0;
  while (RTjpeg_liqt[RTjpeg_ZZ[++RTjpeg_lb8]] <= 8);
  RTjpeg_lb8--;
  RTjpeg_cb8 = 0;
  while (RTjpeg_ciqt[RTjpeg_ZZ[++RTjpeg_cb8]] <= 8);
  RTjpeg_cb8--;

  RTjpeg_dct_init ();
  RTjpeg_idct_init ();
  RTjpeg_quant_init ();
}

/*

   External Function

   Initialise compression.

   Input: buf -> pointer to 128 ints for quant values store to pass back to 
   init_decompress.
   width -> width of image
   height -> height of image
   Q -> quality factor (192=best, 32=worst)

 */

void
RTjpeg_init_compress (u32 * buf, int width, int height, u8 Q)
{
  int i;
  u64 qual;

  RTjpeg_init_data ();

  RTjpeg_width = width;
  RTjpeg_height = height;

  qual = (u64) Q << (32 - 7);	/* 32 bit FP, 255=2, 0=0 */

  for (i = 0; i < 64; i++)
    {
      RTjpeg_lqt[i] = (s32) ((qual / ((u64) RTjpeg_lum_quant_tbl[i] << 16)) >> 3);
      if (RTjpeg_lqt[i] == 0)
	RTjpeg_lqt[i] = 1;
      RTjpeg_cqt[i] = (s32) ((qual / ((u64) RTjpeg_chrom_quant_tbl[i] << 16)) >> 3);
      if (RTjpeg_cqt[i] == 0)
	RTjpeg_cqt[i] = 1;
      RTjpeg_liqt[i] = (1 << 16) / (RTjpeg_lqt[i] << 3);
      RTjpeg_ciqt[i] = (1 << 16) / (RTjpeg_cqt[i] << 3);
      RTjpeg_lqt[i] = ((1 << 16) / RTjpeg_liqt[i]) >> 3;
      RTjpeg_cqt[i] = ((1 << 16) / RTjpeg_ciqt[i]) >> 3;
    }

  RTjpeg_lb8 = 0;
  while (RTjpeg_liqt[RTjpeg_ZZ[++RTjpeg_lb8]] <= 8);
  RTjpeg_lb8--;
  RTjpeg_cb8 = 0;
  while (RTjpeg_ciqt[RTjpeg_ZZ[++RTjpeg_cb8]] <= 8);
  RTjpeg_cb8--;

  RTjpeg_dct_init ();
  RTjpeg_quant_init ();

  for (i = 0; i < 64; i++)
    buf[i] = RTjpeg_liqt[i];
  for (i = 0; i < 64; i++)
    buf[64 + i] = RTjpeg_ciqt[i];
}

void
RTjpeg_init_decompress (u32 * buf, int width, int height)
{
  int i;

  RTjpeg_init_data ();

  RTjpeg_width = width;
  RTjpeg_height = height;

  for (i = 0; i < 64; i++)
    {
      RTjpeg_liqt[i] = buf[i];
      RTjpeg_ciqt[i] = buf[i + 64];
    }

  RTjpeg_lb8 = 0;
  while (RTjpeg_liqt[RTjpeg_ZZ[++RTjpeg_lb8]] <= 8);
  RTjpeg_lb8--;
  RTjpeg_cb8 = 0;
  while (RTjpeg_ciqt[RTjpeg_ZZ[++RTjpeg_cb8]] <= 8);
  RTjpeg_cb8--;

  RTjpeg_idct_init ();

  RTjpeg_color_init ();
}

int
RTjpeg_compress (s8 * sp, unsigned char *bp)
{
  s8 *sb;
  int i, j;

#ifdef MMX
  emms ();
#endif

  sb = sp;
/* Y */
  for (i = 0; i < RTjpeg_height; i += 8)
    {
      for (j = 0; j < RTjpeg_width; j += 8)
	{
	  RTjpeg_dct (bp + j, RTjpeg_block, RTjpeg_width);
	  RTjpeg_quant (RTjpeg_block, RTjpeg_lqt);
	  sp += RTjpeg_b2s (RTjpeg_block, sp, RTjpeg_lb8);
	}
      bp += RTjpeg_width << 3;
    }
/* Cr */
  for (i = 0; i < (RTjpeg_height >> 1); i += 8)
    {
      for (j = 0; j < (RTjpeg_width >> 1); j += 8)
	{
	  RTjpeg_dct (bp + j, RTjpeg_block, RTjpeg_width >> 1);
	  RTjpeg_quant (RTjpeg_block, RTjpeg_cqt);
	  sp += RTjpeg_b2s (RTjpeg_block, sp, RTjpeg_cb8);
	}
      bp += RTjpeg_width << 2;
    }
/* Cb */
  for (i = 0; i < (RTjpeg_height >> 1); i += 8)
    {
      for (j = 0; j < (RTjpeg_width >> 1); j += 8)
	{
	  RTjpeg_dct (bp + j, RTjpeg_block, RTjpeg_width >> 1);
	  RTjpeg_quant (RTjpeg_block, RTjpeg_cqt);
	  sp += RTjpeg_b2s (RTjpeg_block, sp, RTjpeg_cb8);
	}
      bp += RTjpeg_width << 2;
    }
#ifdef MMX
  emms ();
#endif
  return (sp - sb);
}

void
RTjpeg_decompress (s8 * sp, u8 * bp)
{
  int i, j;

#ifdef MMX
  emms ();
#endif

/* Y */
  for (i = 0; i < RTjpeg_height; i += 8)
    {
      for (j = 0; j < RTjpeg_width; j += 8)
	if (*sp == -1)
	  sp++;
	else
	  {
	    sp += RTjpeg_s2b (RTjpeg_block, sp, RTjpeg_lb8, RTjpeg_liqt);
	    RTjpeg_idct (bp + j, RTjpeg_block, RTjpeg_width);
	  }
      bp += RTjpeg_width << 3;
    }
/* Cr */
  for (i = 0; i < (RTjpeg_height >> 1); i += 8)
    {
      for (j = 0; j < (RTjpeg_width >> 1); j += 8)
	if (*sp == -1)
	  sp++;
	else
	  {
	    sp += RTjpeg_s2b (RTjpeg_block, sp, RTjpeg_cb8, RTjpeg_ciqt);
	    RTjpeg_idct (bp + j, RTjpeg_block, RTjpeg_width >> 1);
	  }
      bp += RTjpeg_width << 2;
    }
/* Cb */
  for (i = 0; i < (RTjpeg_height >> 1); i += 8)
    {
      for (j = 0; j < (RTjpeg_width >> 1); j += 8)
	if (*sp == -1)
	  sp++;
	else
	  {
	    sp += RTjpeg_s2b (RTjpeg_block, sp, RTjpeg_cb8, RTjpeg_ciqt);
	    RTjpeg_idct (bp + j, RTjpeg_block, RTjpeg_width >> 1);
	  }
      bp += RTjpeg_width << 2;
    }
#ifdef MMX
  emms ();
#endif
}

/*
   External Function

   Initialise additional data structures for motion compensation

 */

void
RTjpeg_init_mcompress (void)
{
  unsigned long tmp;

  if (!RTjpeg_old)
    {
      RTjpeg_old = malloc (((RTjpeg_width * RTjpeg_height) << 1) + (RTjpeg_width * RTjpeg_height) + 32);
      tmp = (unsigned long) RTjpeg_old;
      tmp += 32;
      tmp = tmp >> 5;
      RTjpeg_old = (s16 *) (tmp << 5);
    }
  if (!RTjpeg_old)
    {
      fprintf (stderr, "RTjpeg: Could not allocate memory\n");
      exit (-1);
    }
  bzero (RTjpeg_old, ((RTjpeg_width * RTjpeg_height) + ((RTjpeg_width * RTjpeg_height) >> 1)) << 1);
}

#ifdef MMX

int
RTjpeg_bcomp (s16 * old, mmx_t * mask)
{
  int i;
  mmx_t *mold = (mmx_t *) old;
  mmx_t *mblock = (mmx_t *) RTjpeg_block;
  mmx_t result;
  static mmx_t neg = (mmx_t) (unsigned long long) 0xffffffffffffffffULL;

  movq_m2r (*mask, mm7);
  movq_m2r (neg, mm6);
  pxor_r2r (mm5, mm5);

  for (i = 0; i < 8; i++)
    {
      movq_m2r (*(mblock++), mm0);
      movq_m2r (*(mblock++), mm2);
      movq_m2r (*(mold++), mm1);
      movq_m2r (*(mold++), mm3);
      psubsw_r2r (mm1, mm0);
      psubsw_r2r (mm3, mm2);
      movq_r2r (mm0, mm1);
      movq_r2r (mm2, mm3);
      pcmpgtw_r2r (mm7, mm0);
      pcmpgtw_r2r (mm7, mm2);
      pxor_r2r (mm6, mm1);
      pxor_r2r (mm6, mm3);
      pcmpgtw_r2r (mm7, mm1);
      pcmpgtw_r2r (mm7, mm3);
      por_r2r (mm0, mm5);
      por_r2r (mm2, mm5);
      por_r2r (mm1, mm5);
      por_r2r (mm3, mm5);
    }
  movq_r2m (mm5, result);

  if (result.q)
    {
      if (!RTjpeg_mtest)
	for (i = 0; i < 16; i++)
	  ((u64 *) old)[i] = ((u64 *) RTjpeg_block)[i];
      return 0;
    }
// printf(".");
  return 1;
}

#else
int
RTjpeg_bcomp (s16 * old, u16 * mask)
{
  int i;

  for (i = 0; i < 64; i++)
    if (abs (old[i] - RTjpeg_block[i]) > *mask)
      {
	if (!RTjpeg_mtest)
	  for (i = 0; i < 16; i++)
	    ((u64 *) old)[i] = ((u64 *) RTjpeg_block)[i];
	return 0;
      }
  return 1;
}
#endif

void
RTjpeg_set_test (int i)
{
  RTjpeg_mtest = i;
}

int
RTjpeg_mcompress (s8 * sp, unsigned char *bp, u16 lmask, u16 cmask,
		  int x, int y, int w, int h)
{
  s8 *sb;
  s16 *block;
  int i, j;

#ifdef MMX
  emms ();
  RTjpeg_lmask = (mmx_t) (((u64) lmask << 48) | ((u64) lmask << 32) | ((u64) lmask << 16) | lmask);
  RTjpeg_cmask = (mmx_t) (((u64) cmask << 48) | ((u64) cmask << 32) | ((u64) cmask << 16) | cmask);
#else
  RTjpeg_lmask = lmask;
  RTjpeg_cmask = cmask;
#endif

  w += x;
  h += y;

  sb = sp;
  block = RTjpeg_old;
/* Y */
  for (i = 0; i < RTjpeg_height; i += 8)
    {
      if (i >= y && i < h)
	{
	  for (j = x; j < w; j += 8)
	    {
	      RTjpeg_dct (bp + j, RTjpeg_block, RTjpeg_width);
	      RTjpeg_quant (RTjpeg_block, RTjpeg_lqt);
	      if (RTjpeg_bcomp (block, &RTjpeg_lmask))
		*((u8 *) sp++) = 255;
	      else
		sp += RTjpeg_b2s (RTjpeg_block, sp, RTjpeg_lb8);
	      block += 64;
	    }
	}
      bp += RTjpeg_width << 3;
    }

  y >>= 1; h >>= 1;

/* Cr */
  for (i = 0; i < (RTjpeg_height >> 1); i += 8)
    {
      if (i >= y && i < h)
	{
	  for (j = x >> 1; j < (w >> 1); j += 8)
	    {
	      RTjpeg_dct (bp + j, RTjpeg_block, RTjpeg_width >> 1);
	      RTjpeg_quant (RTjpeg_block, RTjpeg_cqt);
	      if (RTjpeg_bcomp (block, &RTjpeg_cmask))
		*((u8 *) sp++) = 255;
	      else
		sp += RTjpeg_b2s (RTjpeg_block, sp, RTjpeg_cb8);
	      block += 64;
	    }
	}
      bp += RTjpeg_width << 2;
    }
/* Cb */
  for (i = 0; i < (RTjpeg_height >> 1); i += 8)
    {
      if (i >= y && i < h)
	{
	  for (j = x >> 1; j < (w >> 1); j += 8)
	    {
	      RTjpeg_dct (bp + j, RTjpeg_block, RTjpeg_width >> 1);
	      RTjpeg_quant (RTjpeg_block, RTjpeg_cqt);
	      if (RTjpeg_bcomp (block, &RTjpeg_cmask))
		*((u8 *) sp++) = 255;
	      else
		sp += RTjpeg_b2s (RTjpeg_block, sp, RTjpeg_cb8);
	      block += 64;
	    }
	}
      bp += RTjpeg_width << 2;
    }
#ifdef MMX
  emms ();
#endif
  return (sp - sb);
}

