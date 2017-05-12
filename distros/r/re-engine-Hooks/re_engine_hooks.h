/* This file is part of the re::engine::Hooks Perl module.
 * See http://search.cpan.org/dist/re-engine-Hooks/ */

#ifndef RE_ENGINE_HOOKS_H
#define RE_ENGINE_HOOKS_H 1

typedef void (*reh_comp_node_hook)(pTHX_ regexp *, regnode *);
typedef void (*reh_exec_node_hook)(pTHX_ regexp *, regnode *, regmatch_info *, regmatch_state *);

typedef struct {
 reh_comp_node_hook comp_node;
 reh_exec_node_hook exec_node;
} reh_config;

void reh_register(pTHX_ const char *, reh_config *);
#define reh_register(K, C) reh_register(aTHX_ (K), (C))

#endif /* RE_ENGINE_HOOKS_H */

