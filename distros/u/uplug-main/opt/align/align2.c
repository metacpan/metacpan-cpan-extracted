/* 
William A. Gale and Kenneth W. Church, "A Program for Aligning Sentence 
in Bilingual Corpora" in Susan Armstong ed. "Using Large Corpora", MIT
Press, 1994, p91-102.

with Michael D. Riley

The following code is the core of align. It is a C language program
that inputs two files, with one token (word) per line. The text files
contain a number of delimiter tokens: "hard" and "soft". The hard
regions (e.g. paragraphs) may not be changed, and there must be 
equal numbers of them in the two input files. The soft regions 
(e.g. sentences) may be deleted (1-0), inserted (0-1), contracted
(2-1), expanded (1-2) or merged (2-2) as necessary so that the
output ends up with the same number of soft regions. The program
generates two output files. The two output files contain an equal
number of soft regions, each on a line. If the -v command line 
option is included, each soft region is preceded by its probability
score. 
*/

#include <fcntl.h>
#include <malloc.h>
#include <math.h>
#include <stdio.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <values.h>
#include <sys/stat.h>

/*
  usage:
  align_regions -D '.PARA' -d '.End of Sentence' file1 file2

  outputs two files: file1.al & file2.al

  hard regions are delimited by the -D arg
  soft regions are delimited by the -d arg
*/

#define dist(x,y) distances[(x)*((ny)+1)+(y)]
#define pathx(x,y) path_x[(x)*((ny)+1)+(y)]
#define pathy(x,y) path_y[(x)*((ny)+1)+(y)]
#define MAX_FILENAME 256
#define BIG_DISTANCE 2500
/* 1999-06-16/PS:  I don't know understand why ET added this line
   and I got a conflict with the value in /usr/include/values.h.
   I guess it was need on AIX for some reason. */
#ifdef AIX
/* added by ET 960405 */
#define MAXINT (~(1L << (BITS(long) - 1)))
#endif

/* Dynamic Programming Optimization */

struct alignment {
  int x1;
  int y1;
  int x2;
  int y2;
  int d;
};

char *hard_delimiter=NULL; /* -D arg */
char *soft_delimiter=NULL; /* -d arg */
int verbose=0;             /* -v arg */

/* utility functions */

char *readchars(),**readlines(),**substrings();
void err();
/* added by ET 960405 */
void bcopy();

/*
  seq_align() by Mike Riley

  x and y are sequences of objects, represented as non-zero ints, 
  to be aligned.

  dist_func(x1,y1,x2,y2) is a distance function of 4 args:

    dist_func(x1,y1, 0, 0) gives cost of substitution of x1 by y1.
    dist_func(x1, 0, 0, 0) gives cost of deletion of x1.
    dist_func( 0,y1, 0, 0) gives cost of insertion of y1.
    dist_func(x1,y1,x2, 0) gives cost of contraction of (x1,x2) to y1.
    dist_func(x1,y1, 0,y2) gives cost of expansion of x1 to (y1,y2). 
    dist_func(x1,y1,x2,y2) gives cost to match (x1,x2) to (y1,y2).

  align is the alignment, with (align[i].x1,align[i].x2) aligned
    with (align[i].y1,align[i].y2). Zero in align[].x1 and align[].y1
    correspond to insertion and deletion respectively. Non-zero in
    align[].x2 and align[].y2 correspond to contraction and expansion,
    respectively. align[].d gives the distance for that pairing.

  The function returns the length of the alignment.

  Function call in main:

  seq_align(len1,len2,number_of_soft_regions1,number_of_soft_regions2,
            two_side_distance,&align);
*/

int seq_align(x,y,nx,ny,dist_funct,align)
int *x,*y,nx,ny;
int (*dist_funct)();
struct alignment **align;
{
  int *distances,*path_x,*path_y,n;
  int i,j,oi,oj,di,dj,d1,d2,d3,d4,d5,d6,dmin;
  struct alignment *ralign;

  distances=(int *) malloc((nx+1)*(ny+1)*sizeof(int));
  path_x=(int *) malloc((nx+1)*(ny+1)*sizeof(int));
  path_y=(int *) malloc((nx+1)*(ny+1)*sizeof(int));
  ralign=(struct alignment *) malloc((nx+ny)*sizeof(struct alignment));

printf("seq_align: x:%d y:%d nx:%d ny:%d \n",x[0],y[0],nx,ny);fflush(stdout);

  for (j=0;j<=ny;j++) {
    for (i=0;i<=nx;i++) {
printf("***seq_align: %d %d %d %d\n",i,j,x[i],y[j]);fflush(stdout);
      /* substitution */
      d1=i>0&&j>0 ? dist(i-1,j-1)+(*dist_funct)(x[i-1],y[j-1],0,0):MAXINT;
      /* deletion */
      d2=i>0 ? dist(i-1,j)+(*dist_funct)(x[i-1],0,0,0):MAXINT;
      /* insertion */
      d3=j>0 ? dist(i,j-1)+(*dist_funct)(0,y[j-1],0,0):MAXINT;
      /* contraction */
      d4=i>1&&j>0 ? dist(i-2,j-1)+(*dist_funct)(x[i-2],y[j-1],x[i-1],0):MAXINT;
      /* expansion */
      d5=i>0&&j>1 ? dist(i-1,j-2)+(*dist_funct)(x[i-1],y[j-2],0,y[j-1]):MAXINT;
      /* melding */
      d6=i>1&&j>1 ? dist(i-2,j-2)+(*dist_funct)(x[i-2],y[j-2],x[i-1],y[j-1])
        : MAXINT;

printf("seq_align: ");
if (d1<MAXINT) printf("%6d ",d1); else printf("     x ");
if (d2<MAXINT) printf("%6d ",d2); else printf("     x ");
if (d3<MAXINT) printf("%6d ",d3); else printf("     x ");
if (d4<MAXINT) printf("%6d ",d4); else printf("     x ");
if (d5<MAXINT) printf("%6d ",d5); else printf("     x ");
if (d6<MAXINT) printf("%6d\n",d6); else printf("     x\n");
fflush(stdout);
      dmin=d1;
      if (d2<dmin) dmin=d2;
      if (d3<dmin) dmin=d3;
      if (d4<dmin) dmin=d4;
      if (d5<dmin) dmin=d5;
      if (d6<dmin) dmin=d6;
      
      if (dmin==MAXINT) {
        dist(i,j)=0;
      } else if (dmin==d1) {
        dist(i,j)=d1;
        pathx(i,j)=i-1;
        pathy(i,j)=j-1;
      } else if (dmin==d2) {
        dist(i,j)=d2;
        pathx(i,j)=i-1;
        pathy(i,j)=j;
      } else if (dmin==d3) {
        dist(i,j)=d3;
        pathx(i,j)=i;
        pathy(i,j)=j-1;
      } else if (dmin==d4) {
        dist(i,j)=d4;
        pathx(i,j)=i-2;
        pathy(i,j)=j-1;
      } else if (dmin==d5) {
        dist(i,j)=d5;
        pathx(i,j)=i-1;
        pathy(i,j)=j-2;
      } else if (dmin==d6) {
        dist(i,j)=d6;
        pathx(i,j)=i-2;
        pathy(i,j)=j-2;
      }
    }
  }
  n=0;
  for (i=nx,j=ny;i>0||j>0;i=oi,j=oj) {
    oi=pathx(i,j);
    oj=pathy(i,j);
    di=i-oi;
    dj=j-oj;
    if (di==1&&dj==1) {           /* substitution */
      ralign[n].x1=x[i-1];
      ralign[n].y1=y[j-1];
      ralign[n].x2=0;
      ralign[n].y2=0;
      ralign[n++].d=dist(i,j)-dist(i-1,j-1);
    } else if (di==1&&dj==0) {    /* deletion */
      ralign[n].x1=x[i-1];
      ralign[n].y1=0;
      ralign[n].x2=0;
      ralign[n].y2=0;
      ralign[n++].d=dist(i,j)-dist(i-1,j-1);
    } else if (di==0&&dj==1) {    /* insertion */
      ralign[n].x1=0;
      ralign[n].y1=y[j-1];
      ralign[n].x2=0;
      ralign[n].y2=0;
      ralign[n++].d=dist(i,j)-dist(i-1,j-1);
    } else if (dj==1) {           /* contraction */
      ralign[n].x1=x[i-2];
      ralign[n].y1=y[j-1];
      ralign[n].x2=x[i-1];
      ralign[n].y2=0;
      ralign[n++].d=dist(i,j)-dist(i-1,j-1);
    } else if (di==1) {           /* expansion */
      ralign[n].x1=x[i-1];
      ralign[n].y1=y[j-2];
      ralign[n].x2=0;
      ralign[n].y2=y[j-1];
      ralign[n++].d=dist(i,j)-dist(i-1,j-1);
    } else /* (di==2&&dj==2) */ { /* melding */
      ralign[n].x1=x[i-2];
      ralign[n].y1=y[j-2];
      ralign[n].x2=x[i-1];
      ralign[n].y2=y[j-1];
      ralign[n++].d=dist(i,j)-dist(i-1,j-1);
    }
  }
  *align=(struct alignment *) malloc(n*sizeof(struct alignment));

  for (i=0;i<n;i++)
    bcopy(ralign+i,(*align)+(n-i-1),sizeof(struct alignment));

  free(distances);
  free(path_x);
  free(path_y);
  free(ralign);
  return(n);
}

/* Local Distance Function */

/* 
  Returns the area under a normal distribution
  from -inf to z standard deviations 
*/

double pnorm(z)
double z;
{
  double t,pd;

  t=1/(1+0.2316419*z);
  pd=1-0.3989423*exp(-z*z/2)*
     ((((1.330274429*t-1.821255978)*t+1.781477937)*t-0.356563782)*t+
      0.319381530)*t;
  /* 
    see Abramowitz, M. and I. Stegun, "Handbook of Mathematical Functions" 
    (1964), 26.2.17 p932 
  */
  return(pd);
}

/*
  Return -100*log probability that an English sentence of length
  len1 is a translation of a foreign sentence of length len2. The
  probability is based on two parameters, the mean and variance of
  number of foreign characters per English characters
*/

int match(len1,len2)
int len1,len2;
{
  double z,pd,mean;
  double c=1;
  double s2=6.8;

/*printf("match: %d %d\n",len1,len2);fflush(stdout);*/
  if (len1==0&&len2==0) return(0);
  /* added by ET 960405 */
  if (len1<0||len2<0) return(0);
  mean=(len1+len2/c)/2;
  z=(c*len1-len2)/sqrt(s2*mean);

  /* Need to deal with both sides of the normal distribution */  
  if (z<0) z=-z;
  pd=2*(1-pnorm(z));

  if (pd>0) return((int)(-100*log(pd)));
  else return(BIG_DISTANCE);
}

int two_side_distance(x1,y1,x2,y2)
int x1,y1,x2,y2;
{
  int penalty21=230; /* -100*log[prob of 2-1 match] / [prob of 1-1 match]) */
  int penalty22=440; /* -100*log[prob of 2-2 match] / [prob of 1-1 match]) */
  int penalty01=450; /* -100*log[prob of 0-1 match] / [prob of 1-1 match]) */

/*printf("two_side_distance: %d %d %d %d\n",x1,y1,x2,y2);fflush(stdout);*/
  if (x2==0&&y2==0)
    if (x1==0)  
      return(match(x1,y1)+penalty01);     /* insertion */
    else if (y1==0)
      return(match(x1,y1)+penalty01);     /* deletion */
    else return(match(x1,y1));            /* substitution */
  else if (x2==0)  
    return(match(x1,y1+y2)+penalty21);        /* expansion */
  else if (y2==0)
    return(match(x1+x2,y1)+penalty21);        /* contraction */
  else return(match(x1+x2,y1+y2)+penalty22);  /* melding */
}

/* Functions for Manipulating Regions */ 

struct region {
  char **lines;
  int length;
};

void print_region(fd,region,score)
int score;
FILE *fd;
struct region *region;
{
  char **lines,**end;
  
  lines=region->lines;
  end=lines+region->length;
  for (;lines<end;lines++)
      {
	  fprintf(fd,"%s\n",*lines);
      }
}

int length_of_a_region(region)
struct region *region;
{
  int result;
  char **lines,**end;

  lines=region->lines;
  end=lines+region->length;
  result=end-lines;

  for (;lines<end;lines++)
    result+=strlen(*lines);
  return(result);
}

int *region_lengths(regions,n)
struct region *regions;
int n;
{
  int i;
  int *result;

  /* AIX does not accept malloc(0) so increase n with 1 */
  result=(int *)malloc((n+1)*sizeof(int));
  if (result==NULL) err("malloc1 failed");

  for (i=0;i<n;i++) {           /* inserted pointer conversion ET 960405 */
    result[i]=length_of_a_region(&(regions[i]));
    printf("region_lengths: %d %d\n",i,result[i]); fflush(stdout); 
  }
  return(result);
}

struct region *find_sub_regions(region,delimiter,len_ptr)
struct region *region;
char *delimiter;
int *len_ptr;
{
  struct region *result;
  char **l,**lines,**end;
  int n=0;

printf("find_sub_regions:1, delimiter=%s\n",delimiter);fflush(stdout);
  lines=region->lines;
printf("find_sub_regions:2\n");fflush(stdout);
  end=lines+region->length;

  for (l=lines;l<end;l++)
    if (delimiter&&strcmp(*l,delimiter)==0) n++;
  result=(struct region *)calloc(n+1,sizeof(struct region));
  if (result==NULL) err("malloc2 failed");
  *len_ptr=n;
  n=0;
  result[0].lines=lines;
  for (l=lines;l<end;l++)
    if (delimiter&&strcmp(*l,delimiter)==0) {
      result[n].length=l-result[n].lines;
      result[n+1].lines=l+1;
      n++;
    }
  result[n].length=l-result[n].lines;
  if (n!=*len_ptr) {
    fprintf(stderr,"find_sub_regions: n=%d, *len_ptr=%d\n",n,*len_ptr);
    exit(2);
  }
  return(result);
}

/* Top Level Main Function */

int main(argc,argv)
int argc;
char **argv;
{
  char **lines1,**lines2;
  int number_of_lines1,number_of_lines2;
  struct region *hard_regions1,*hard_regions2,*soft_regions1,*soft_regions2;
  struct region *hard_end1,*hard_end2,tmp;
  int number_of_hard_regions1;
  int number_of_hard_regions2;
  int number_of_soft_regions1;
  int number_of_soft_regions2;
  int *len1,*len2;
  int c,n,i,ix,iy,prevx,prevy, stop;
  struct alignment *align,*a;
  FILE *out1,*out2;
  char filename[MAX_FILENAME];
  extern char *optarg;
  extern int optind;
  int hardCounter,softCounter;

  /* parse arguments */
  while ((c=getopt(argc,argv,"vd:D:"))!=EOF)
    switch(c){
    case 'v': verbose=1; break;
    case 'd': soft_delimiter=strdup(optarg); break;
    case 'D': hard_delimiter=strdup(optarg); break;
    default:
      fprintf(stderr,"usage: align_regions [d (soft delimiter)] [D (hard delimiter)]\n");
      exit(2);
    }
  if (argc!=optind+2) err("wrong number of arguments");

  /* open output files */
  sprintf(filename,"%s.al",argv[optind]);
  out1=fopen(filename,"w");
  if (out1==NULL) {
    fprintf(stderr,"can't open %s\n",filename);
    exit(2);
  }
  sprintf(filename,"%s.al",argv[optind+1]);
  out2=fopen(filename,"w");
  if (out2==NULL) {
    fprintf(stderr,"can't open %s\n",filename);
    exit(2);
  }

  lines1=readlines(argv[optind],&number_of_lines1);
  lines2=readlines(argv[optind+1],&number_of_lines2);
  tmp.lines=lines1;
  tmp.length=number_of_lines1;
  hard_regions1=find_sub_regions(&tmp,hard_delimiter,&number_of_hard_regions1);
  tmp.lines=lines2;
  tmp.length=number_of_lines2;

  hard_regions2=find_sub_regions(&tmp,hard_delimiter,&number_of_hard_regions2);
  
  if (number_of_hard_regions1!=number_of_hard_regions2)
    {
      fprintf(stderr, "Antal sidor: dokument 1=%d dokument 2=%d\n", number_of_hard_regions1,number_of_hard_regions2);
    err("align_regions: input files do not contain the same number
         of hard regions");
    
    }
  hard_end1=hard_regions1+number_of_hard_regions1;
  hard_end2=hard_regions2+number_of_hard_regions2;
  hardCounter=0;
  for (;hard_regions1<hard_end1;hard_regions1++,hard_regions2++) {
    softCounter=1;
    /* changed hardregions1 and 2 to pointers iso scalars (ET 960405) */
    soft_regions1=find_sub_regions(hard_regions1,soft_delimiter,
                                   &number_of_soft_regions1);
    soft_regions2=find_sub_regions(hard_regions2,soft_delimiter,
                                   &number_of_soft_regions2);

    len1=region_lengths(soft_regions1,number_of_soft_regions1);
    len2=region_lengths(soft_regions2,number_of_soft_regions2);

    n=seq_align(len1,len2,number_of_soft_regions1,number_of_soft_regions2,
                two_side_distance,&align);

    /* for (i=0;i<number_of_soft_regions1;i++) {
	fprintf(stderr,"region_lengths 1: %d: %d\n",i+1,len1[i]);
    }
    for (i=0;i<number_of_soft_regions2;i++) {
	fprintf(stderr,"region_lengths 2: %d: %d\n",i+1,len2[i]); 
    }
    fprintf(stderr, "n=%d\n",n); */

    prevx=prevy=ix=iy=0;
    for (i=0;i<n;i++) {  
      a=&align[i];
      /* if (number_of_soft_regions1 != number_of_soft_regions2)
	 fprintf(stderr, "mening=%d: x1=%d x2=%d ; y1=%d y2=%d ; d=%d\n", i+1, a->x1,a->x2, a->y1, a->y2, a->d); */
            
      if (a->x2>0) ix++; else if (a->x1==0) ix--;
      if (a->y2>0) iy++; else if (a->y1==0) iy--;

      if (a->x2 > 0 && a->x1 == 0 && a->y1 == 0 && a->y2 == 0) 
	  iy++;
      else if (a->y2 > 0 && a->y1 == 0 && a->x1 == 0 && a->x2 == 0) 
	  ix++;
      else if (a->x1==0&&a->y1==0&&a->x2==0&&a->y2==0) 
	  {
	      ix++; iy++; 
	  }
      ix++;
      iy++;
      fprintf(stderr, "ix=%d prevx=%d; iy=%d prevy=%d\n",ix, prevx, iy, prevy);
      if (verbose) {
         fprintf(out1,".Score %d\n",a->d);
         fprintf(out2,".Score %d\n",a->d);
      }
      for (;prevx<ix;prevx++)
	  print_region(out1,&(soft_regions1[prevx]),a->d);
      fprintf(out1,"%s %d.%d\n",soft_delimiter,hardCounter,softCounter);
      for (;prevy<iy;prevy++)
	  print_region(out2,&(soft_regions2[prevy]),a->d);
      fprintf(out2,"%s %d.%d\n",soft_delimiter,hardCounter,softCounter);
      softCounter++;
    }
    fprintf(out1,"%s\n",hard_delimiter);
    fprintf(out2,"%s\n",hard_delimiter);
    free(align);
    free(soft_regions1);
    free(soft_regions2);
    free(len1);
    free(len2);
    hardCounter++;
  }
  /* added by ET 960405 */
  exit(0);
}

/* Utility functions */

void err(msg)
char *msg;
{
  fprintf(stderr,"**ERROR**: %s\n",msg);
  exit(2);
}

/*
  return the contents of the file as a string
  and stuff the length of this string into len_ptr
*/

char *readchars(filename,len_ptr)
char *filename;
int *len_ptr;
{
  FILE *fd;
  char *result;
  struct stat stat_buf;

  fd=fopen(filename,"r");
  if (fd==NULL) err("open failed");
  if (fstat(fileno(fd),&stat_buf)==-1) err("stat failed");
  *len_ptr=stat_buf.st_size;
  result=malloc(*len_ptr);
  if (result==NULL) err("malloc3 failed\n");
  if (fread(result,sizeof(char),*len_ptr,fd)!=*len_ptr) err("fread failed");
  if (fclose(fd)==-1) err("fclose failed");
  return(result);
}

/*
  split string into a number of substrings delimited by a delimiter chararcter
  return an array of substrings
  stuff the length of this arry into len_ptr
*/

char **substrings(string,end,delimiter,len_ptr)
char *string,*end,delimiter;
int *len_ptr;
{
  char *s,**result;
  int i=0;

  while (string<end&&*string==delimiter) string++;
  for (s=string;s<end;s++) if (*s==delimiter) i++;
  *len_ptr=i;

  result=(char **)malloc(sizeof(char *)*(i+1));
  if (result==NULL) err("malloc4 failed");

  i=0;
  result[i++]=string;
  for (s=string;s<end;s++)
    if (*s==delimiter) {
      result[i++]=s+1;
      *s=0;
    }
  i--; /* the last entry is beyond the end */
  if (i!=*len_ptr) {
    fprintf(stderr,"align_regions: confusion; i=%d; len_ptr=%d\n",i,*len_ptr);
    exit(2);
  }
  return(result);
}

/* 
  return an array of strings, one string for each line of the file
  set len_ptr to the number of lines in the file
*/

char **readlines(filename,len_ptr)
char *filename;
int *len_ptr;
{
  char *chars;
  int number_of_chars;

  chars=readchars(filename,&number_of_chars);
  /* printf("line = '%s'\n", chars); */
  return(substrings(chars,chars+number_of_chars,'\n',len_ptr));
}

