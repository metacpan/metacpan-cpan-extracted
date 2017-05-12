#ifndef TXS_HASH_H_
#define TXS_HASH_H_
/*
 Hash buckets will be in the following format:
 [int next_offset; char *data; ], ....
*/

#define txs_hash2slot(hash, n_buckets) \
    hash % (n_buckets-1)

struct TXS_HashTable {
    /*How many buckets*/
    int n_buckets;
    char **buckets;
    
    int slot_min;
    int slot_max;
};

typedef unsigned int txs_ht_off_t;

static inline uint32_t mkhash(const char *str, int len)
{
    register uint32_t hash = 5381;
    
    for(len; len > 8; len -= 8, str += 8) {
        hash ^= *(uint32_t*)(str);
        hash ^= *(uint32_t*)(str+4);
    }
    
    for(len; len > 4; len -= 4, str += 4) {
        hash ^= *(uint32_t*)(str);
    }
    
    for(len; len > 2; len -=2, str += 2) {
        hash = hash * (33 + str[0]);
        hash = hash * (33 + str[1]);
    }
    
    for(len; len; len--, str++) {
        hash = hash * (33 + *str);
    }
    return hash;
}

#define QUAL_COUNT 8

static inline struct TXS_HashTable*
THX_txs_ht_build(pTHX_ HV *perl_hv)
#define txs_ht_build(hv) THX_txs_ht_build(aTHX_ hv)
{
    uint32_t n_buckets = 1;    
    while(n_buckets < HvKEYS(perl_hv)) {
        n_buckets <<= 1;
    }
        
    int retlen;
    uint32_t hash;
    HE *entry;
    char *str;
    int i;
    uint32_t slot = 0;
    
    char **buckets;
    char *slotp;
    int *bucket_sizes;
    
    struct TXS_HashTable *ret;
    Newx(ret, 1, struct TXS_HashTable);
    
    ret->slot_min =  n_buckets;
    ret->slot_max = 0;
    
    Newxz(buckets, n_buckets, char*);
    Newxz(bucket_sizes, n_buckets, int);
    
    
    hv_iterinit(perl_hv);
    while(entry = hv_iternext(perl_hv)) {
        
        str = hv_iterkey(entry, &retlen);
        
        slot = txs_hash2slot(mkhash(str, retlen), n_buckets);
        if(ret->slot_min > slot) {
            ret->slot_min = slot;
        }
        if(ret->slot_max < slot) {
            ret->slot_max = slot;
        }
        
        bucket_sizes[slot] += (sizeof(txs_ht_off_t));
        bucket_sizes[slot] += retlen;
    }
    
    /*Now, allocate the buckets*/
    for(i = 0; i < n_buckets; i++) {
        if(!bucket_sizes[i]) {
            continue;
        }
        Newxz(buckets[i], bucket_sizes[i]+sizeof(int), char);
    }
    
    /*Now, fill the buckets, again*/
    hv_iterinit(perl_hv);
    while (entry = hv_iternext(perl_hv)) {
        str = hv_iterkey(entry, &retlen);
        
        slot = txs_hash2slot(mkhash(str, retlen), n_buckets);
        
        slotp = buckets[slot];
        while(*slotp) {
            slotp += *(txs_ht_off_t*)(slotp) + sizeof(txs_ht_off_t);
        }
        *(txs_ht_off_t*)(slotp) = retlen;
        slotp += sizeof(txs_ht_off_t);
        memcpy(slotp, str, retlen);
    }
    
    Safefree(bucket_sizes);
    
    
    ret->n_buckets = n_buckets;
    ret->buckets = buckets;
    
    return ret;
}

static inline int
txs_ht_check(const struct TXS_HashTable *ht, const char *str, int len)
{
    register char *slotp;
    register uint32_t slot = txs_hash2slot(mkhash(str, len), ht->n_buckets);
    
    if(ht->buckets[slot] == NULL) {
        return 0;
    }
    
    for(slotp = ht->buckets[slot]; *(txs_ht_off_t*)slotp;
        slotp += (sizeof(txs_ht_off_t)) + *(txs_ht_off_t*)slotp) {
        
        if(*(txs_ht_off_t*)(slotp) != len) {
            continue;
        }
        
        if(memcmp(slotp+sizeof(txs_ht_off_t), str, len) == 0) {
            return 1;
        }
    }
    return 0;
}

static inline void
txs_ht_free(struct TXS_HashTable *ht)
{
    int i;
    for(i = 0; i < ht->n_buckets; i++) {
        if(ht->buckets[i]) {
            Safefree(ht->buckets[i]);
        }
    }
    Safefree(ht->buckets);
    Safefree(ht);
}

txs_ht_dump_stats(struct TXS_HashTable *ht)
{
    int i;
    int tmp_count = 0;
    char *slotp;
    int bucket_stats[QUAL_COUNT] = { 0 };
    
    for(i = 0; i < ht->n_buckets; i++) {
        if(!ht->buckets[i]) {
            continue;
        }
        
        for(
            tmp_count = 0, slotp = ht->buckets[i];
            *slotp;
            tmp_count++, slotp += sizeof(txs_ht_off_t) + *(txs_ht_off_t*)slotp
        );
        if(!tmp_count) {
            continue; /*Eh?*/
        }
        
        if(tmp_count >= QUAL_COUNT) {
            bucket_stats[QUAL_COUNT-1]++;
        } else {
            bucket_stats[tmp_count-1]++;
        }
    }
    
    for(i = 0; i < QUAL_COUNT; i++) {
        printf("[%d: %d] ", i+1, bucket_stats[i]);
    }
    printf("\n");
}

#endif /*TXS_HASH_H_*/