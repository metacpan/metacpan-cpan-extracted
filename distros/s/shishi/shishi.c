/* Shishi dynamic lexer/parser system.  
   Copyright 2002, Simon Cozens Provided to you under the terms of the
   Artistic License
*/

#define SHISHI_INSHISHIC
#include "shishi.h"

Shishi* Shishi_new (const char* creator) { /**/
    Shishi* self = malloc(sizeof(Shishi));
    if (!self) 
	    abort();

    self->creator = strdup(creator);
    self->nodes = malloc(sizeof(ShishiNode*) * SHISHI_NODE_ALLOC);
    if (!self->nodes)
        abort();
    self->num_nodes = 0;
    self->alloc_nodes = SHISHI_NODE_ALLOC;
    self->stack = 0;
    return self;
}

void Shishi_destroy (Shishi* self) { /**/
    int i;
    if (!self)
        abort();

    if (self->creator)
        free(self->creator);

    for (i=0; i < self->num_nodes; i++)
        Shishi_node_destroy((self->nodes)[i]);

    if (self->nodes)
        free(self->nodes);

    free(self);
}

Shishi* Shishi_add_node (Shishi* shishi, ShishiNode* node) { /**/
    if (shishi->alloc_nodes - shishi->num_nodes < 1) {
	shishi->nodes = realloc(shishi->nodes, (size_t)(sizeof(ShishiNode)*(shishi->alloc_nodes + SHISHI_NODE_ALLOC)));
	shishi->alloc_nodes += SHISHI_NODE_ALLOC;
	if (!shishi->nodes)
	    abort();
    }
    shishi->nodes[shishi->num_nodes++] = node;
    return shishi;
}

int Shishi_execute(Shishi* parser, ShishiMatch* match) { /**/
    ShishiNode* first = parser->nodes[0];
    return Shishi_node_execute(first, parser, match);
}

ShishiMatch* Shishi_match_new(char* text) { /**/
    ShishiMatch* mymatch = malloc(sizeof(ShishiMatch));
    if (!mymatch)
	abort();

    mymatch->text = strdup(text);
    mymatch->offset = 0;
    mymatch->end_of_match = 0;
    mymatch->stack = malloc(5 * sizeof(ShishiMatchStack));
    if (!mymatch->stack)
	abort();

    mymatch->stack_top = mymatch->stack;
    mymatch->stack_alloc = mymatch->stack_top+5;
    return mymatch;
}

void Shishi_match_destroy(ShishiMatch* mymatch) { /**/
    DEBUG(printf("Winding match back %i\n", mymatch->offset););
    mymatch->text -= mymatch->offset;
    free(mymatch->stack);
    free(mymatch->text);
    free(mymatch);
}
