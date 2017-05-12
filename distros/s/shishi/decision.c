/* Shishi dynamic lexer/parser system.   
   Copyright 2002, Simon Cozens  
   Provided to you under the terms of the Artistic License 
*/

#include "shishi.h" 

ShishiDecision* Shishi_decision_create(void) { /**/
    ShishiDecision* foo = malloc(sizeof(ShishiDecision));
    if (!foo)
	abort();

    foo->target.string.buffer =0;
    foo->target.string.length =0;
    foo->target_type = 0;
    foo->action = 0;
    foo->next_node = 0;
    return foo;
}

void Shishi_decision_destroy(ShishiDecision* decision) { /**/
    if (!decision)
        abort(); /* Don't paper over cracks */
    if (decision->target_type == SHISHI_MATCH_TEXT)
        free(decision->target.string.buffer);
    free(decision);
}
