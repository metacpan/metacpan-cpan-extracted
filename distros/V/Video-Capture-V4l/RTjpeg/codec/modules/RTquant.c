void RTjpeg_quant_init(void)
{
}

void RTjpeg_quant(s16 *block, s32 *qtbl)
{
 int i;
 
 for(i=0; i<64; i++)
   block[i]=(s16)((block[i]*qtbl[i]+32767)>>16);
}
