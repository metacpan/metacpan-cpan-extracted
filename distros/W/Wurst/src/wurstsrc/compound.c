#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "prob_vec.h"
#include "coord.h"
#include "compound.h"

char * get_compound_vec(struct prob_vec *v){
return(v->compnd);
}


char * get_compound_coord(struct coord *c){
return(c->compnd);
}
