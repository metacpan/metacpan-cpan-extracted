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
 int i;
 u8 *bufy, *bufout;
 
 bufy=&buf[0];
 bufout=rgb;
 
 for(i=0; i<RTjpeg_height*RTjpeg_width; i++)
 {
   *bufout++=*bufy;
   *bufout++=*bufy;
   *bufout++=*bufy++;
 }
}


void RTjpeg_yuvrgb32(u8 *buf, u8 *rgb)
{
 int i;
 u8 *bufy, *bufout;
 
 bufy=&buf[0];
 bufout=rgb;
 
 for(i=0; i<RTjpeg_height*RTjpeg_width; i++)
 {
   *bufout++=*bufy;
   *bufout++=*bufy;
   *bufout++=*bufy;
   *bufout++=*bufy++;
 }
}

void RTjpeg_yuvrgb24(u8 *buf, u8 *rgb)
{
 int i;
 u8 *bufy, *bufout;
 
 bufy=&buf[0];
 bufout=rgb;
 
 for(i=0; i<RTjpeg_height*RTjpeg_width; i++)
 {
   *bufout++=*bufy;
   *bufout++=*bufy;
   *bufout++=*bufy++;
 }
}

void RTjpeg_yuvrgb16(u8 *buf, u8 *rgb)
{
 int i, tmp;
 u8 *bufy, *bufout;
 
 bufy=&buf[0];
 bufout=rgb;
 
 for(i=0; i<RTjpeg_height*RTjpeg_width; i++)
 {
 
   tmp=(int)((int)*bufy >> 3);
   tmp|=(int)(((int)*bufy >> 2) << 5);
   tmp|=(int)(((int)*(bufy++) >> 3) << 11);
           
   *(bufout++)=tmp&0xff;;
   *(bufout++)=tmp>>8;
 }
}

void RTjpeg_yuvrgb8(u8 *buf, u8 *rgb)
{
 int i;
 u8 *bufy, *bufout;
 
 bufy=&buf[0];
 bufout=rgb;
 
 for(i=0; i<RTjpeg_height*RTjpeg_width; i++)
 {
   *bufout++=*bufy++;
 }
}

