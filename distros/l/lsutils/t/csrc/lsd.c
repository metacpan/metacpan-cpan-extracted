/*********************************
 * By Leo Charre leocharre at gmail dot com
 * list dirs in argument dir paths
 *
 */

#include <stdio.h>
#include <sys/types.h>
#include <dirent.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>

int lsd ( char dir_path[] )
{
   DIR *dp;
   int entry_count;
   struct dirent *ep;


   dp = opendir( dir_path );
   
   if ( dp == NULL )
   {
      (void) closedir(dp);
      
      perror("could not open dir, ");

      exit(EXIT_FAILURE);
   }


   while ((ep = readdir(dp)) != NULL) 
   {  
      char abspath[255]=""; /* have to reset this, because 
      although the scope is valid here, it does NOT get reset every iteration!!!!
      */
      
      if ( strcmp("..", ep->d_name) == 0 )
      {
         continue;
      }

      
      if ( strcmp(".", ep->d_name)  == 0)
      {
         continue;
      }
     
      

      strcat( abspath, dir_path );
      strcat( abspath, ep->d_name );

      /*printf("# trying dir_path: %s, dname: %s\n---%s---\n\n", dir_path, ep->d_name, abspath );*/
      struct stat es;      
      stat( abspath , &es ); /* man stat.h */

      if ( S_ISDIR( (es.st_mode) ) )   
               printf("%s\n", ep->d_name );

   }

   closedir(dp);

}



int main ( int argc, char *argv[] )  
{
   int i;
   for ( i = 1; i < argc ; i++ )
   {
      /* i'm having a problem, if the path is /home/, this works, but if
       * the trialing / is left off.. it doesnt */
      lsd(argv[i]);
   }
   exit(0);
}


