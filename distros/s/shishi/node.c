/* Shishi dynamic lexer/parser system.   
   Copyright 2002, Simon Cozens
   Provided to you under the terms of the Artistic License 
*/

#include "shishi.h" 

ShishiNode* Shishi_node_create(const char* creator) { /**/
    ShishiNode* self = malloc(sizeof(ShishiNode));
    if (!self)
        return 0;

    self->creator = strdup(creator);
    self->children = 0;
    self->parents = 0;

    self->decisions = malloc(sizeof(ShishiDecision) * SHISHI_DEC_ALLOC);
    if (self->decisions == 0) {
	abort();
    }

    self->alloc = SHISHI_DEC_ALLOC;

    return self;
}

void Shishi_node_destroy(ShishiNode* node) { /**/
    int i;
    for (i = 0; i < node->children; i++)
	Shishi_decision_destroy(node->decisions[i]);
    free(node->decisions);
    free(node->creator);
    if (node->parents > 0) {
	fprintf(stderr, "You tried to delete a node which is in use\n");
	abort();
    }
    DEBUG(printf("Freeing node at %p", node););
    free(node);
}

int Shishi_node_execute(ShishiNode* node, Shishi* parser, ShishiMatch* match) { /**/ 
    int i;

    ShishiDecision** dend = node->decisions + node->children;
    ShishiDecision** dp = node->decisions;
    ShishiDecision** dstart = dp;
    ShishiDecision* d;

recurse:
    DEBUG(printf("Recursing: stack top is %p, sp is %p, stack base is %p\n",
                    match->stack_alloc, match->stack_top, match->stack));
    for (d = *dp; dp < dend; dp++) {
	char* text = match->text;
	int matched = 0;
	int rc;

    d = *dp;
        DEBUG(
	      printf("Trying decision %s (%p) on %s\n", Shishi_debug_matchtypes[d->target_type], d, text);
	);
        switch (d->target_type) {
	case SHISHI_MATCH_TEXT:
        if (strncmp(text, d->target.string.buffer, d->target.string.length) == 0)
           matched=1;
	case SHISHI_MATCH_CHAR:
	case SHISHI_MATCH_TOKEN:
        DEBUG(printf("Testing %c against %c\n", *text, d->target.token));
	    if ((token_t)(*(text++)) == d->target.token)
		matched = 1;
	    break;
	case SHISHI_MATCH_END:
	    if (*text == '\0')
		matched =1;
	    break;
	case SHISHI_MATCH_ANY:
	case SHISHI_MATCH_SKIP:
	    if (*(++text) != '\0')
		matched=1;
	    break;
	case SHISHI_MATCH_TRUE:
	    matched = 1;
	    break;
	case SHISHI_MATCH_CODE:
        BREAKPOINT;
	    if ((*(shishi_comparison_t)(d->target.comparison.function))(d, text, parser, match,d->target.comparison.data) != 0)
		matched = 1;
	    break;
	}

	if (matched == 0) {
        DEBUG(printf("Decision failed\n"));
	    continue;
    }

	match->offset += text - match->text;
	match->text = text;

	DEBUG (
	       printf("%s match succeeded, action %s\n", 
		      Shishi_debug_matchtypes[d->target_type], 
		      Shishi_debug_actiontypes[d->action]
		      );
        );

	switch (d->action) {
	case SHISHI_ACTION_CONTINUE:
	    /* Put stuff on stack */

	    if (match->stack_top >= match->stack_alloc -1) {
		/* Want more core! */
		ShishiMatchStack* oldstack = match->stack;
		match->stack = realloc(match->stack, sizeof(ShishiMatchStack) * ((size_t)(match->stack_alloc - match->stack) + SHISHI_MATCH_STACK_ALLOC));
		match->stack_alloc += (match->stack-oldstack) + SHISHI_MATCH_STACK_ALLOC;
		match->stack_top += match->stack-oldstack;
		DEBUG(printf("I have more stack!: stack top is %p, sp is %p, stack base is %p\n",
			     match->stack_alloc, match->stack_top, match->stack));
		if (!match->stack)
		    abort;
	    }
	    
        DEBUG(printf("Stack level is %i\n", match->stack_top - match->stack));
        DEBUG(printf("Writing on stack at %p\n", match->stack_top););
	    match->stack_top->doffset = d - *dstart;
        DEBUG(if(!node){printf("I'm not writing *that* on the stack\n");abort();});
	    match->stack_top->node = node;
	    match->stack_top->ptr = text;
	    match->stack_top++;
        DEBUG(printf("Stack level is %i\n", match->stack_top - match->stack));

	    /* Swizzle variables */
	    node = d->next_node;
DEBUG(
        if (!node) { printf("MY PARSER'S GOT NO NODES!\n"); abort(); };
     );
	    dp = node->decisions;
        dend = node->decisions + node->children;
        dstart = dp;

	    /* "Recurse" */
	    goto recurse;
	case SHISHI_ACTION_FINISH:
	    DEBUG(printf("Finishing!\n"));
	    return SHISHI_MATCHED;
	case SHISHI_ACTION_FAIL:
	    DEBUG(printf("Bailing!\n"));
	    return SHISHI_FAILED;
	}
    }
    if (match->stack_top - match->stack > 0) {
        ShishiMatchStack* pframe = --match->stack_top;
        char* text = pframe->ptr;
        DEBUG(printf("Popping stack\n"));
        DEBUG(printf("Stack level is %i, I got stuff from %p\n", match->stack_top - match->stack, pframe));
	    node = pframe->node;	    
DEBUG(
        if (!node) { printf("MY PARSER'S GOT NO NODES!\n"); abort(); };
     );
	    match->offset += text - match->text; /* Rewind */
	    match->text = text; 
	    dstart = node->decisions + pframe->doffset + 1;
        dend = node->decisions + node->children;
        dp = dstart;
	    DEBUG(printf("Restarting from decision %p\n", dstart););
	    goto recurse;
	}
    return SHISHI_AGAIN;
}

ShishiNode* Shishi_node_add_decision(ShishiNode* node, ShishiDecision* d) { /**/
    /* Alloc room for another decision */
    if (node->alloc - node->children < 1) {
	node->decisions = realloc(node->decisions, sizeof(ShishiDecision*) * (size_t)(node->alloc + SHISHI_DEC_ALLOC));
        node->alloc += SHISHI_DEC_ALLOC;
	if (!node->decisions)
	    abort();
    }
    node->decisions[node->children++] = d;
    return node;
}

