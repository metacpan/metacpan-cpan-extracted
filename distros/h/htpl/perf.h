#ifndef __PERL_PERF_H__
#define __PERL_PERF_H__

struct hash_t {
        char **words;
        int *locations;
        int *entries;
};

#ifdef __cplusplus
extern "C" {
#endif
int search_hash(struct hash_t *, char *, int);
#ifdef __cplusplus
}
#endif

#endif
