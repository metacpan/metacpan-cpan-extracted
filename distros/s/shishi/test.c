#include "shishi.h"

int test_comparison(ShishiDecision* d, char* text, Shishi* parser, ShishiMatch* match, const char* callback) {
    printf("Hello world! %s\n", callback);
}

int main(void) {
    Shishi* myshishi = Shishi_new("test");
    ShishiNode* nodea = Shishi_node_create("test");
    ShishiNode* nodeb = Shishi_node_create("test");
    ShishiNode* nodec = Shishi_node_create("test");
    ShishiNode* accept = Shishi_node_create("test");
    ShishiDecision* a = Shishi_decision_create();
    ShishiDecision* b = Shishi_decision_create();
    ShishiDecision* c = Shishi_decision_create();
    ShishiDecision* end = Shishi_decision_create();
    ShishiDecision* skip = Shishi_decision_create();
    ShishiMatch* mymatch = Shishi_match_new("xxxabc");

    a->target_type = SHISHI_MATCH_CHAR;
    a->target.token = (token_t)'a';
    a->action = SHISHI_ACTION_CONTINUE;
    a->next_node = nodeb;

    skip->target_type = SHISHI_MATCH_SKIP;
    skip->action = SHISHI_ACTION_CONTINUE;
    skip->next_node = nodea;

    b->target_type = SHISHI_MATCH_CHAR;
    b->target.token = (token_t)'b';
    b->action = SHISHI_ACTION_CONTINUE;
    b->next_node = nodec;

    c->target_type = SHISHI_MATCH_CHAR;
    c->target.token = (token_t)'c';
    c->action = SHISHI_ACTION_CONTINUE;
    c->next_node = accept;
    
    end->target_type = SHISHI_MATCH_END;
    end->action = SHISHI_ACTION_FINISH; 
    
    (void)Shishi_node_add_decision(nodea, a);
    (void)Shishi_node_add_decision(nodea, skip);
    (void)Shishi_node_add_decision(nodeb, b);
    (void)Shishi_node_add_decision(nodec, c);
    (void)Shishi_node_add_decision(accept, end);
    (void)Shishi_add_node(myshishi, nodea);
    (void)Shishi_add_node(myshishi, nodeb);
    (void)Shishi_add_node(myshishi, nodec);
    (void)Shishi_add_node(myshishi, accept);

    if (Shishi_execute(myshishi, mymatch) == SHISHI_MATCHED) {
	printf("Matched\n");
    } else {
	printf("Failed\n");
    }
    Shishi_destroy(myshishi);
    Shishi_match_destroy(mymatch);
    return 0;
}
