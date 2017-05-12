/*
 * print to screen how many entries are in a directory
 * $Version$
 */ 

#include <stdio.h>
#include <sys/types.h>
#include <dirent.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>

int lscount ( char dir_path[], int typeflag )
{
   DIR *dp;
   int entry_count;
   struct dirent *ep;
   strcat( dir_path, "/" );


   switch ( typeflag )
   {
      case 0:
         break;
   
      case 1:
         break;
   
      case 2:
         break;
   
      default:
         printf("no such type %d\n", typeflag );
         exit(1);
   }

   entry_count = 0;

   dp = opendir( dir_path );

   
   if ( dp == NULL )
   {
      (void) closedir(dp);
      
      perror("didnt work");

      exit(EXIT_FAILURE);
   }


   while ((ep = readdir(dp)) != NULL) 
   {  
      char abspath[255]=""; /* have to reset this, because 
      although the scope is valid here, it does NOT get reset every iteration!!!!
      */

      strcat( abspath, dir_path );
      strcat( abspath, ep->d_name );

      /*printf("# trying dir_path: %s, dname: %s\n---%s---\n\n", dir_path, ep->d_name, abspath );*/
      struct stat es;      
      stat( abspath , &es ); /* man stat.h */

      switch ( typeflag )
      {
         case 0: 
            entry_count++;
            break;

         case 1: 
            if ( S_ISREG( (es.st_mode) ) )
               entry_count++;

            break;

         case 2: 
            if ( S_ISDIR( (es.st_mode) ) )
               entry_count++;

            break;
      }


   }

   (void) closedir(dp);

   return entry_count;
}


int main ( int argc, char *argv[] )  
{
   int i;
   for ( i = 1; i < argc ; i++ )
   {
      /* i'm having a problem, if the path is /home/, this works, but if
       * the trialing / is left off.. it doesnt */
      printf("%6d %s\n", (lscount(argv[i], 1)) , (argv[i]) );
   }
   exit(0);
}


