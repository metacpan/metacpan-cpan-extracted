#include "perf.h"

int search_hash(hash, word, sensitive) 
        struct hash_t* hash;
        char *word;
        int sensitive; {

        int ch1, ch2;
        int len, val;
        int loc, w;

        if (!word) return -1;
        if (!*word) return -1;
        if (!hash) return -1;
        ch1 = *word;
        len = strlen(word);
        ch2 = word[len - 1];
        val = ((ch1 * ch2) ^ len) % 10;
        loc = hash->entries[val];
        if (loc < 0) return -1;
        while ((w = hash->locations[loc]) >= 0) {
                if (sensitive && !strcmp(hash->words[w], word) ||
                    !sensitive && !strcasecmp(hash->words[w], word)) return w;
                loc++;
        }
        return -1;
}
