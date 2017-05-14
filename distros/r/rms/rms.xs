#ifdef __cplusplus
extern "C" {
#endif
#include <rmsdef.h>
#include <rms.h>
#include <rab.h>
#include <fab.h>
#include <starlet.h>
#include <descrip.h>
#include <dvidef.h>
#include <math.h>
#include <iodef.h>
#include <msgdef.h>
#include <ssdef.h>
#include <stsdef.h>
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif


MODULE = rms		PACKAGE = rms		

PROTOTYPES: DISABLE


int 
open_read(file,rfab, rrab)
char *file
int rfab
int rrab
CODE:
{   
   long int r;
   double s=1.0;
   struct RAB *rab;
   struct FAB *fab;
   rab = malloc(sizeof(struct RAB));
   fab = malloc(sizeof(struct FAB));
   *fab = cc$rms_fab;
   *rab = cc$rms_rab;


   /*  Write in the block the relevant file access options                   */
   fab->fab$b_fac = FAB$M_GET;
   fab->fab$l_fna = file;
   fab->fab$b_fns = strlen(file);
   fab->fab$b_org = FAB$C_IDX;
   fab->fab$b_rfm = FAB$C_FIX;
   r                 = (int)(ldexp(s,FAB$V_SHRPUT)) 
     | (int)(ldexp(s,FAB$V_SHRGET)) 
     | (int)(ldexp(s,FAB$V_SHRDEL)) 
     | (int)(ldexp(s,FAB$V_SHRUPD));
   
   fab->fab$b_shr = r;                           
   
   /*  Write in the block the relevant record parameters                     */
   rab->rab$l_fab = fab;
   rab->rab$b_rac = RAB$C_KEY;
   
   RETVAL = sys$open ( fab );
   if (1 & RETVAL){
      RETVAL = sys$connect ( rab );
      if (1 & RETVAL){
	 RETVAL = sys$rewind ( rab );
	 if (1 & RETVAL){
	    rrab = (int)(rab);
	    rfab = (int)(fab);
	 }
      }
   }
}
OUTPUT:
rrab
rfab
RETVAL



int 
open_write (file,rfab, rrab)
char *file
int rfab
int rrab
CODE:
{  long int   r;
   struct RAB *rab;
   struct FAB *fab;
   double s=1.0;
   rab = malloc(sizeof(struct RAB));
   fab = malloc(sizeof(struct FAB));
   *fab = cc$rms_fab;
   *rab = cc$rms_rab;
   fab->fab$l_fna = file;
   fab->fab$b_fns = strlen(file);
   fab->fab$b_org = FAB$C_IDX;
   fab->fab$b_rfm = FAB$C_FIX;

   r                 = (int)(ldexp(s,FAB$V_SHRPUT)) 
     | (int)(ldexp(s,FAB$V_SHRGET)) 
     | (int)(ldexp(s,FAB$V_SHRDEL)) 
     | (int)(ldexp(s,FAB$V_SHRUPD));
   
   fab->fab$b_shr = r;

   r                 =  (int)(ldexp(s,FAB$V_PUT)) 
     |  (int)(ldexp(s,FAB$V_GET)) 
     |  (int)(ldexp(s,FAB$V_DEL)) 
     |  (int)(ldexp(s,FAB$V_UPD));
   fab->fab$b_fac =  r;


   /*  Write in the block the relevant record parameter                      */
   rab->rab$l_fab = fab;
   rab->rab$b_rac = RAB$C_KEY;
   
   RETVAL = sys$open ( fab );
   if (1 & RETVAL){
      RETVAL = sys$connect ( rab );
      if (1 & RETVAL){
	 RETVAL = sys$rewind ( rab );
	 if (1 & RETVAL){
	    rrab = (int)(rab);
	    rfab = (int)(fab);
	 }
      }
   }
}
OUTPUT:
rrab
rfab
RETVAL


     
     

int 
close (rfab,rrab)
int rfab
int rrab
CODE:
{   
   struct FAB *fab;
   struct RAB *rab;
   rab = (struct RAB *)(rrab);
   fab = (struct FAB *)(rfab);
   RETVAL=sys$close ( fab );
   free(fab);
   free(rab);
}
OUTPUT:
RETVAL

int 
delete (rrab) 
int rrab
CODE:
{   
   double r,s=1.0;                                                          

   struct RAB *rab;
   rab = (struct RAB *)(rrab);
   rab->rab$b_rac = RAB$C_RFA;                                              
   rab->rab$l_kbf = NULL   ;                                                

   r                 = ldexp(s,RAB$V_ASY);
   rab->rab$l_rop = (long int)(r);                                          
                                                                             

   RETVAL=sys$delete(rab);
   if (1 & RETVAL){
      RETVAL = sys$wait ( rab );
   }
}
OUTPUT:
RETVAL

int 
find (rrab, key_val, match)
int rrab
char *key_val
char *match
CODE:
{  long int Status;
   double r,s=1.0;                                                           
   struct RAB *rab;
   rab = (struct RAB *)(rrab);
   rab->rab$b_rac = RAB$C_KEY;
   rab->rab$l_kbf = key_val;
   sys$rewind(rab);                                               
   sys$wait(rab);
   if(!(memcmp(match,"GE",2))) {r = ldexp(s,RAB$V_EQNXT);
      rab->rab$l_rop = (int)(r);}
   if(!(memcmp(match,"GT",2))) {r = ldexp(s,RAB$V_NXT);                   
      rab->rab$l_rop = (int)(r);}             
   if(!(memcmp(match,"EQ",2))) rab->rab$l_rop = 0;                   
   RETVAL=sys$find(rab);
}
OUTPUT:
RETVAL

int 
put_index (rrab, buffer, size, key_val) 
int rrab
char *buffer
int size
char *key_val
CODE:
{   
   double r,s=1.0;                                                             
   struct RAB *rab;
   rab = (struct RAB *)(rrab);
   rab->rab$b_rac = RAB$C_KEY;                                              
   rab->rab$l_kbf = key_val;                                                
   rab->rab$l_ubf = buffer;                                                 
   rab->rab$l_rbf = buffer;                                                 
   rab->rab$w_usz = size;                                         
   rab->rab$w_rsz = size;                                         
   
   r                 = ldexp(s,RAB$V_ASY);
   rab->rab$l_rop = (long int)(r);                                          
   
   
   RETVAL = sys$put(rab);
   if (1 & RETVAL){
      RETVAL = sys$wait(rab);
   }
}
OUTPUT:
RETVAL


int 
put_seq (rrab, buffer, size)                                 
int rrab
char *buffer
int size
CODE:
{   
   struct RAB *rab;
   rab = (struct RAB *)(rrab);
   rab->rab$b_rac = RAB$C_SEQ;                                              
   rab->rab$l_kbf = NULL   ;                                                
   rab->rab$l_ubf = buffer;                                                 
   rab->rab$l_rbf = buffer;                                                 
   rab->rab$w_usz = size;                                         
   rab->rab$w_rsz = size;                                         
   rab->rab$l_rop = 0;                                                      
                                                                             
   RETVAL = sys$put(rab);
   if (1 & RETVAL){
      RETVAL = sys$wait(rab);                                       
   }
}                                                                            
OUTPUT:
RETVAL



int 
read_seq (rrab, buffer, size)                                 
int rrab
char *buffer
int size
CODE:
{   
   struct RAB *rab;
   rab = (struct RAB *)(rrab);
   rab->rab$b_rac = RAB$C_SEQ;                                              
   rab->rab$l_kbf = NULL   ;                                                
   rab->rab$l_ubf = buffer;                                                 
   rab->rab$l_rbf = buffer;                                                 
   rab->rab$w_usz = size;                                         
   rab->rab$w_rsz = size;                                         
   rab->rab$l_rop = 0;                                                      
   RETVAL = sys$get ( rab );
   if (1 & RETVAL){
      RETVAL = sys$wait ( rab );                                       
   }
}
OUTPUT:
buffer
RETVAL

int 
sel_index (rrab, key_size, key_no)
int rrab
int key_size
int key_no
CODE:
{ 
   struct RAB *rab;
   rab = (struct RAB *)(rrab);
   rab->rab$b_rac = RAB$C_KEY;
   rab->rab$b_krf = key_no;
   rab->rab$b_ksz = key_size;
   RETVAL=sys$rewind(rab);
}
OUTPUT:
RETVAL



int 
unlock (rrab) 
int rrab
CODE:
{   
   double r,s=1.0;                                                             
   struct RAB *rab;
   rab = (struct RAB *)(rrab);
   rab->rab$b_rac = RAB$C_RFA;                                              
   rab->rab$l_kbf = NULL   ;                                                
   r                 = ldexp(s,RAB$V_ASY);
   rab->rab$l_rop = (long int)(r);                                          
   RETVAL=sys$free(rab);
}
OUTPUT:
RETVAL

int
update (rrab, buffer, size) 
int rrab
char *buffer
int size
CODE:
{   
   double r,s=1.0;                                                             
   struct RAB *rab;
   rab = (struct RAB *)(rrab);
   rab->rab$b_rac = RAB$C_RFA;                                              
   rab->rab$l_kbf = NULL   ;                                                
   rab->rab$l_ubf = buffer;                                                 
   rab->rab$l_rbf = buffer;                                                 
   rab->rab$w_usz = size;                                         
   rab->rab$w_rsz = size;                                         
   r                 = ldexp(s,RAB$V_ASY);
   rab->rab$l_rop = (long int)(r);                                          
   RETVAL=sys$update(rab);
   if (1 & RETVAL){
      RETVAL=sys$wait(rab );
   }
}
OUTPUT:
RETVAL



