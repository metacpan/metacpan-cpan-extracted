int RTjpeg_s2b(s16 *data, s8 *strm, u8 bt8, u32 *qtbl)
{
 int ci=1, co=1, tmp;
 register int i;

 i=RTjpeg_ZZ[0];
 data[i]=((u8)strm[0])*qtbl[i];

 for(co=1; co<=bt8; co++)
 {
  i=RTjpeg_ZZ[co];
  data[i]=strm[ci++]*qtbl[i];
 }
 
 for(; co<64; co++)
 {
  if(strm[ci]>63)
  {
   tmp=co+strm[ci]-63;
   for(; co<tmp; co++)data[RTjpeg_ZZ[co]]=0;
   co--;
  } else
  {
   i=RTjpeg_ZZ[co];
   data[i]=strm[ci]*qtbl[i];
  }
  ci++;
 }
 return (int)ci;
}
