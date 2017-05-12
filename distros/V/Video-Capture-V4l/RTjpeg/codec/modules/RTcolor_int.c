void RTjpeg_color_init(void)
{
}  

#define KcrR 76284
#define KcrG 53281
#define KcbG 25625
#define KcbB 132252
#define Ky 76284

void RTjpeg_yuvrgb(u8 *buf, u8 *rgb)
{
 int tmp;
 int i, j;
 s32 y, crR, crG, cbG, cbB;
 u8 *bufcr, *bufcb, *bufy, *bufoute, *bufouto;
 int oskip, yskip;
 
 oskip=RTjpeg_width*3;
 yskip=RTjpeg_width;
 
 bufcb=&buf[RTjpeg_width*RTjpeg_height];
 bufcr=&buf[RTjpeg_width*RTjpeg_height+(RTjpeg_width*RTjpeg_height)/4];
 bufy=&buf[0];
 bufoute=rgb;
 bufouto=rgb+oskip;
 
 for(i=0; i<(RTjpeg_height>>1); i++)
 {
  for(j=0; j<RTjpeg_width; j+=2)
  {
   crR=(*bufcr-128)*KcrR;
   crG=(*(bufcr++)-128)*KcrG;
   cbG=(*bufcb-128)*KcbG;
   cbB=(*(bufcb++)-128)*KcbB;
  
   y=(bufy[j]-16)*Ky;
   
   tmp=(y+crR)>>16;
   *(bufoute++)=(tmp>255)?255:((tmp<0)?0:tmp);
   tmp=(y-crG-cbG)>>16;
   *(bufoute++)=(tmp>255)?255:((tmp<0)?0:tmp);
   tmp=(y+cbB)>>16;
   *(bufoute++)=(tmp>255)?255:((tmp<0)?0:tmp);

   y=(bufy[j+1]-16)*Ky;

   tmp=(y+crR)>>16;
   *(bufoute++)=(tmp>255)?255:((tmp<0)?0:tmp);
   tmp=(y-crG-cbG)>>16;
   *(bufoute++)=(tmp>255)?255:((tmp<0)?0:tmp);
   tmp=(y+cbB)>>16;
   *(bufoute++)=(tmp>255)?255:((tmp<0)?0:tmp);

   y=(bufy[j+yskip]-16)*Ky;

   tmp=(y+crR)>>16;
   *(bufouto++)=(tmp>255)?255:((tmp<0)?0:tmp);
   tmp=(y-crG-cbG)>>16;
   *(bufouto++)=(tmp>255)?255:((tmp<0)?0:tmp);
   tmp=(y+cbB)>>16;
   *(bufouto++)=(tmp>255)?255:((tmp<0)?0:tmp);

   y=(bufy[j+1+yskip]-16)*Ky;

   tmp=(y+crR)>>16;
   *(bufouto++)=(tmp>255)?255:((tmp<0)?0:tmp);
   tmp=(y-crG-cbG)>>16;
   *(bufouto++)=(tmp>255)?255:((tmp<0)?0:tmp);
   tmp=(y+cbB)>>16;
   *(bufouto++)=(tmp>255)?255:((tmp<0)?0:tmp);
   
  }
  bufoute+=oskip;
  bufouto+=oskip;
  bufy+=yskip<<1;
 }
}


void RTjpeg_yuvrgb32(u8 *buf, u8 *rgb)
{
 int tmp;
 int i, j;
 s32 y, crR, crG, cbG, cbB;
 u8 *bufcr, *bufcb, *bufy, *bufoute, *bufouto;
 int oskip, yskip;
 
 oskip=RTjpeg_width*4;
 yskip=RTjpeg_width;
 
 bufcb=&buf[RTjpeg_width*RTjpeg_height];
 bufcr=&buf[RTjpeg_width*RTjpeg_height+(RTjpeg_width*RTjpeg_height)/4];
 bufy=&buf[0];
 bufoute=rgb;
 bufouto=rgb+oskip;
 
 for(i=0; i<(RTjpeg_height>>1); i++)
 {
  for(j=0; j<RTjpeg_width; j+=2)
  {
   crR=(*bufcr-128)*KcrR;
   crG=(*(bufcr++)-128)*KcrG;
   cbG=(*bufcb-128)*KcbG;
   cbB=(*(bufcb++)-128)*KcbB;
  
   y=(bufy[j]-16)*Ky;
   
   tmp=(y+cbB)>>16;
   *(bufoute++)=(tmp>255)?255:((tmp<0)?0:tmp);
   tmp=(y-crG-cbG)>>16;
   *(bufoute++)=(tmp>255)?255:((tmp<0)?0:tmp);
   tmp=(y+crR)>>16;
   *(bufoute++)=(tmp>255)?255:((tmp<0)?0:tmp);
   bufoute++;

   y=(bufy[j+1]-16)*Ky;

   tmp=(y+cbB)>>16;
   *(bufoute++)=(tmp>255)?255:((tmp<0)?0:tmp);
   tmp=(y-crG-cbG)>>16;
   *(bufoute++)=(tmp>255)?255:((tmp<0)?0:tmp);
   tmp=(y+crR)>>16;
   *(bufoute++)=(tmp>255)?255:((tmp<0)?0:tmp);
   bufoute++;

   y=(bufy[j+yskip]-16)*Ky;

   tmp=(y+cbB)>>16;
   *(bufouto++)=(tmp>255)?255:((tmp<0)?0:tmp);
   tmp=(y-crG-cbG)>>16;
   *(bufouto++)=(tmp>255)?255:((tmp<0)?0:tmp);
   tmp=(y+crR)>>16;
   *(bufouto++)=(tmp>255)?255:((tmp<0)?0:tmp);
   bufouto++;

   y=(bufy[j+1+yskip]-16)*Ky;

   tmp=(y+cbB)>>16;
   *(bufouto++)=(tmp>255)?255:((tmp<0)?0:tmp);
   tmp=(y-crG-cbG)>>16;
   *(bufouto++)=(tmp>255)?255:((tmp<0)?0:tmp);
   tmp=(y+crR)>>16;
   *(bufouto++)=(tmp>255)?255:((tmp<0)?0:tmp);
   bufouto++;
   
  }
  bufoute+=oskip;
  bufouto+=oskip;
  bufy+=yskip<<1;
 }
}

void RTjpeg_yuvrgb24(u8 *buf, u8 *rgb)
{
 int tmp;
 int i, j;
 s32 y, crR, crG, cbG, cbB;
 u8 *bufcr, *bufcb, *bufy, *bufoute, *bufouto;
 int oskip, yskip;
 
 oskip=RTjpeg_width*3;
 yskip=RTjpeg_width;
 
 bufcb=&buf[RTjpeg_width*RTjpeg_height];
 bufcr=&buf[RTjpeg_width*RTjpeg_height+(RTjpeg_width*RTjpeg_height)/4];
 bufy=&buf[0];
 bufoute=rgb;
 bufouto=rgb+oskip;
 
 for(i=0; i<(RTjpeg_height>>1); i++)
 {
  for(j=0; j<RTjpeg_width; j+=2)
  {
   crR=(*bufcr-128)*KcrR;
   crG=(*(bufcr++)-128)*KcrG;
   cbG=(*bufcb-128)*KcbG;
   cbB=(*(bufcb++)-128)*KcbB;
  
   y=(bufy[j]-16)*Ky;
   
   tmp=(y+cbB)>>16;
   *(bufoute++)=(tmp>255)?255:((tmp<0)?0:tmp);
   tmp=(y-crG-cbG)>>16;
   *(bufoute++)=(tmp>255)?255:((tmp<0)?0:tmp);
   tmp=(y+crR)>>16;
   *(bufoute++)=(tmp>255)?255:((tmp<0)?0:tmp);

   y=(bufy[j+1]-16)*Ky;

   tmp=(y+cbB)>>16;
   *(bufoute++)=(tmp>255)?255:((tmp<0)?0:tmp);
   tmp=(y-crG-cbG)>>16;
   *(bufoute++)=(tmp>255)?255:((tmp<0)?0:tmp);
   tmp=(y+crR)>>16;
   *(bufoute++)=(tmp>255)?255:((tmp<0)?0:tmp);

   y=(bufy[j+yskip]-16)*Ky;

   tmp=(y+cbB)>>16;
   *(bufouto++)=(tmp>255)?255:((tmp<0)?0:tmp);
   tmp=(y-crG-cbG)>>16;
   *(bufouto++)=(tmp>255)?255:((tmp<0)?0:tmp);
   tmp=(y+crR)>>16;
   *(bufouto++)=(tmp>255)?255:((tmp<0)?0:tmp);

   y=(bufy[j+1+yskip]-16)*Ky;

   tmp=(y+cbB)>>16;
   *(bufouto++)=(tmp>255)?255:((tmp<0)?0:tmp);
   tmp=(y-crG-cbG)>>16;
   *(bufouto++)=(tmp>255)?255:((tmp<0)?0:tmp);
   tmp=(y+crR)>>16;
   *(bufouto++)=(tmp>255)?255:((tmp<0)?0:tmp);
   
  }
  bufoute+=oskip;
  bufouto+=oskip;
  bufy+=yskip<<1;
 }
}

void RTjpeg_yuvrgb16(u8 *buf, u8 *rgb)
{
 int tmp;
 int i, j;
 s32 y, crR, crG, cbG, cbB;
 u8 *bufcr, *bufcb, *bufy, *bufoute, *bufouto;
 int oskip, yskip;
 unsigned char r, g, b;
 
 oskip=RTjpeg_width*2;
 yskip=RTjpeg_width;
 
 bufcb=&buf[RTjpeg_width*RTjpeg_height];
 bufcr=&buf[RTjpeg_width*RTjpeg_height+(RTjpeg_width*RTjpeg_height)/4];
 bufy=&buf[0];
 bufoute=rgb;
 bufouto=rgb+oskip;
 
 for(i=0; i<(RTjpeg_height>>1); i++)
 {
  for(j=0; j<RTjpeg_width; j+=2)
  {
   crR=(*bufcr-128)*KcrR;
   crG=(*(bufcr++)-128)*KcrG;
   cbG=(*bufcb-128)*KcbG;
   cbB=(*(bufcb++)-128)*KcbB;
  
   y=(bufy[j]-16)*Ky;
   
   tmp=(y+cbB)>>16;
   b=(tmp>255)?255:((tmp<0)?0:tmp);
   tmp=(y-crG-cbG)>>16;
   g=(tmp>255)?255:((tmp<0)?0:tmp);
   tmp=(y+crR)>>16;
   r=(tmp>255)?255:((tmp<0)?0:tmp);
   tmp=(int)((int)b >> 3);
   tmp|=(int)(((int)g >> 2) << 5);
   tmp|=(int)(((int)r >> 3) << 11);
   *(bufoute++)=tmp&0xff;
   *(bufoute++)=tmp>>8;
   

   y=(bufy[j+1]-16)*Ky;

   tmp=(y+cbB)>>16;
   b=(tmp>255)?255:((tmp<0)?0:tmp);
   tmp=(y-crG-cbG)>>16;
   g=(tmp>255)?255:((tmp<0)?0:tmp);
   tmp=(y+crR)>>16;
   r=(tmp>255)?255:((tmp<0)?0:tmp);
   tmp=(int)((int)b >> 3);
   tmp|=(int)(((int)g >> 2) << 5);
   tmp|=(int)(((int)r >> 3) << 11);
   *(bufoute++)=tmp&0xff;
   *(bufoute++)=tmp>>8;

   y=(bufy[j+yskip]-16)*Ky;

   tmp=(y+cbB)>>16;
   b=(tmp>255)?255:((tmp<0)?0:tmp);
   tmp=(y-crG-cbG)>>16;
   g=(tmp>255)?255:((tmp<0)?0:tmp);
   tmp=(y+crR)>>16;
   r=(tmp>255)?255:((tmp<0)?0:tmp);
   tmp=(int)((int)b >> 3);
   tmp|=(int)(((int)g >> 2) << 5);
   tmp|=(int)(((int)r >> 3) << 11);
   *(bufouto++)=tmp&0xff;
   *(bufouto++)=tmp>>8;

   y=(bufy[j+1+yskip]-16)*Ky;

   tmp=(y+cbB)>>16;
   b=(tmp>255)?255:((tmp<0)?0:tmp);
   tmp=(y-crG-cbG)>>16;
   g=(tmp>255)?255:((tmp<0)?0:tmp);
   tmp=(y+crR)>>16;
   r=(tmp>255)?255:((tmp<0)?0:tmp);
   tmp=(int)((int)b >> 3);
   tmp|=(int)(((int)g >> 2) << 5);
   tmp|=(int)(((int)r >> 3) << 11);
   *(bufouto++)=tmp&0xff;
   *(bufouto++)=tmp>>8;

  }
  bufoute+=oskip;
  bufouto+=oskip;
  bufy+=yskip<<1;
 }
}

void RTjpeg_yuvrgb8(u8 *buf, u8 *rgb)
{
 bcopy(buf, rgb, RTjpeg_width*RTjpeg_height);
}

void RTjpeg_double32(u32 *buf)
{
 int i, j;
 
 u32 *iptr, *optr1, *optr2;
 
 iptr=buf+(RTjpeg_width*RTjpeg_height)-1;
 optr1=buf+(RTjpeg_width*RTjpeg_height*4)-1;
 optr2=optr1-(2*RTjpeg_width);
 
 for(i=0; i<RTjpeg_height; i++)
 {
  for(j=0; j<RTjpeg_width; j++)
  {
   *(optr1--)=*iptr;
   *(optr1--)=*iptr;
   *(optr2--)=*iptr;
   *(optr2--)=*(iptr--);
  }
  optr2=optr2-2*RTjpeg_width;
  optr1=optr1-2*RTjpeg_width;
 } 
}

void RTjpeg_double24(u8 *buf)
{
}

void RTjpeg_double16(u16 *buf)
{
 int i, j;
 
 u16 *iptr, *optr1, *optr2;
 
 iptr=buf+(RTjpeg_width*RTjpeg_height)-1;
 optr1=buf+(RTjpeg_width*RTjpeg_height*4)-1;
 optr2=optr1-(2*RTjpeg_width);
 
 for(i=0; i<RTjpeg_height; i++)
 {
  for(j=0; j<RTjpeg_width; j++)
  {
   *(optr1--)=*iptr;
   *(optr1--)=*iptr;
   *(optr2--)=*iptr;
   *(optr2--)=*(iptr--);
  }
  optr2=optr2-2*RTjpeg_width;
  optr1=optr1-2*RTjpeg_width;
 } 
}

void RTjpeg_double8(u8 *buf)
{
 int i, j;
 
 u8 *iptr, *optr1, *optr2;
 
 iptr=buf+(RTjpeg_width*RTjpeg_height)-1;
 optr1=buf+(RTjpeg_width*RTjpeg_height*4)-1;
 optr2=optr1-(2*RTjpeg_width);
 
 for(i=0; i<RTjpeg_height; i++)
 {
  for(j=0; j<RTjpeg_width; j++)
  {
   *(optr1--)=*iptr;
   *(optr1--)=*iptr;
   *(optr2--)=*iptr;
   *(optr2--)=*(iptr--);
  }
  optr2=optr2-2*RTjpeg_width;
  optr1=optr1-2*RTjpeg_width;
 } 
}

