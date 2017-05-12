void RTjpeg_quant_init(void)
{
 int i;
 s16 *qtbl;
 
 qtbl=(s16 *)RTjpeg_lqt;
 for(i=0; i<64; i++)qtbl[i]=(s16)RTjpeg_lqt[i];

 qtbl=(s16 *)RTjpeg_cqt;
 for(i=0; i<64; i++)qtbl[i]=(s16)RTjpeg_cqt[i];
}

static mmx_t RTjpeg_ones=(mmx_t)(long long)0x0001000100010001LL;
static mmx_t RTjpeg_half=(mmx_t)(long long)0x7fff7fff7fff7fffLL;

void RTjpeg_quant(s16 *block, s32 *qtbl)
{
 int i;
 mmx_t *bl, *ql;
 
 ql=(mmx_t *)qtbl;
 bl=(mmx_t *)block;
 
 movq_m2r(RTjpeg_ones, mm6);
 movq_m2r(RTjpeg_half, mm7);

 for(i=0; i<16; i++)
 {
  movq_m2r(*ql, mm0); /* quant vals (4) */
  movq_m2r(*bl, mm2); /* block vals (4) */
  movq_r2r(mm0, mm1);
  movq_r2r(mm2, mm3);
  
  punpcklwd_r2r(mm6, mm0); /*           1 qb 1 qa */
  punpckhwd_r2r(mm6, mm1); /* 1 qd 1 qc */
  
  punpcklwd_r2r(mm7, mm2); /*                   32767 bb 32767 ba */
  punpckhwd_r2r(mm7, mm3); /* 32767 bd 32767 bc */
  
  pmaddwd_r2r(mm2, mm0); /*                         32767+bb*qb 32767+ba*qa */
  pmaddwd_r2r(mm3, mm1); /* 32767+bd*qd 32767+bc*qc */
  
  psrad_i2r((mmx_t)(long long)16, mm0);
  psrad_i2r((mmx_t)(long long)16, mm1);
  
  packssdw_r2r(mm1, mm0);
  
  movq_r2m(mm0, *bl);
  
  bl++;
  ql++;
 }
}
