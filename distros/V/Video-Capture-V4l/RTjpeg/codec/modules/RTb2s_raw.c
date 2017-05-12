int RTjpeg_b2s(s16 *data, s8 *strm, u8 bt8)
{
 int ci=1, co=1, tmp;

 (u8)strm[0]=(u8)(data[RTjpeg_ZZ[0]]>254) ? 254:((data[RTjpeg_ZZ[0]]<0)?0:data[RTjpeg_ZZ[0]]);
 
 for(ci=1; ci<=63; ci++)
  if(data[RTjpeg_ZZ[ci]]>0)
  {
   strm[co++]=(s8)(data[RTjpeg_ZZ[ci]]>127)?127:data[RTjpeg_ZZ[ci]];
  } else
  {
   strm[co++]=(s8)(data[RTjpeg_ZZ[ci]]<-128)?-128:data[RTjpeg_ZZ[ci]];
  }
/*
 for(; ci<64; ci++)
  if(data[RTjpeg_ZZ[ci]]>0)
  {
   strm[co++]=(s8)(data[RTjpeg_ZZ[ci]]>63)?63:data[RTjpeg_ZZ[ci]];
  } else if(data[RTjpeg_ZZ[ci]]<0)
  {
   strm[co++]=(s8)(data[RTjpeg_ZZ[ci]]<-64)?-64:data[RTjpeg_ZZ[ci]];
  } else
  {
   tmp=ci;
   do
   {
    ci++;
   } while((ci<64)&&(data[RTjpeg_ZZ[ci]]==0));
   strm[co++]=(s8)(63+(ci-tmp));
   ci--;
  }
*/
 return (int)co;
}
