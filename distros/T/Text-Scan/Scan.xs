#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "INLINE.h"


// The transition. There are no explicit states, just linked
// lists of transitions.
typedef struct TRANS *trans;
typedef struct TRANS {
    char splitchar;
    trans next_trans;
    trans next_state;
} Trans;

typedef struct FSM *fsm;
typedef struct FSM {
    trans root;
    int terminals;
    int transitions;
    int states;
    int maxpath;
    char* ignore;
    char* boundary;
    char* inclboundary ;
    char* charclasses;
    char* wild;     // all chars which match a wildcard
    AV* found_keys;
    AV* found_offsets;
    AV* found_vals;
    int position;
    bool use_wildcards;
    bool squeezeblanks;
    char* s;      // string on which to match
} Fsm;


// function declarations (prototypes) necessary for 
// mutually recursive functions
int _eat_wild_chars(fsm this, int matchlen, trans p);
int _find_match(fsm this, int matchlen, trans p);


// For vector records
#define BIT_ON(vec, offset, pos) \
        ( *(vec + \
            ((unsigned char) offset*32) + \
            (unsigned char)pos/8) |= \
            (1 << ((unsigned char)pos % 8)) \
        )

#define IS_BIT_ON(vec, offset, pos) \
        ( *(vec+((unsigned char) offset*32) + \
            (unsigned char)pos/8) & \
            (1 << ((unsigned char)pos % 8)) \
        )



_malloc(fsm m) {
    av_clear(m->found_keys);
    av_clear(m->found_offsets);
    av_clear(m->found_vals);
}


// Place the top transition where it belongs (in the order \0,*,[others])
trans _demote(trans parent){
    
    trans child, top = parent;
    
    if( !(child = parent->next_trans) ) return top;
    if( !parent->splitchar ) return top;
    if( !child->splitchar ){
        parent->next_trans = child->next_trans;
        child->next_trans = parent;
        top = child;
    }
    if( !(child = parent->next_trans) ) return top;

    if( child->splitchar == '*' ){
        parent->next_trans = child->next_trans;
        child->next_trans = parent;
        if( top != parent ) top->next_trans = child;
        else top = child;
    }
    return top;
}



trans _insert_(fsm m, trans p, char *s, SV* val) {
    
    trans t = p;
    
    // going to be a new state with one transition.
    //if (p == 0 && *s) m->states++;
    if(p == 0) m->states++;
    
    // search for *s in transition list (state) t
    while(t){
//        if(*s == t->splitchar) break;
        if(IS_BIT_ON(m->charclasses, *s, t->splitchar)) break;
        else t = t->next_trans;
    }

    // *s transition not in current state? Make a new one, place
    // it at the top of the list. (but keep terminals, wilds at top)
    if(!t){
        m->transitions++;
        t = (trans) malloc(sizeof(Trans));
        t->splitchar = *s;
        t->next_state = 0;
        t->next_trans = p;
        // flip terminal state and/or wildcard p to top
        p = _demote(t); 
    }

    // continue inserting the rest of the string. If there is no more
    // string, place the SV* val into this termination transition.
    if(*s){
        t->next_state = _insert_(m, t->next_state, ++s, val);
    }
    else {
        if(t->next_state) 
            sv_2mortal((SV*)t->next_state);
        else
            m->terminals++;
        t->next_state = (trans) val;
    }

    return p;
}


// unused, too slow
/*
void _cleanup_(trans p) {

    if (p) {
            
        _cleanup_(p->next_trans);

        if(!p->splitchar){
            sv_2mortal( (SV*) p->next_state);
        }
        else 
            _cleanup_(p->next_state);
    }
    //free(p);
}
*/


int _search(trans root, char *s) {

    trans p = root;
    while (p) {
        while(p)
            if(p->splitchar == *s) break;
            else p = p->next_trans;
        if(!p) return 0;
        if(!p->splitchar) return 1;
        p = p->next_state;
        s++;
    }
    return 0;
}


// Return the node representing the char s, if it exists, from this list.
trans _bsearch( char* vec, char s, trans q ){

    while(q){
        if(IS_BIT_ON(vec, s, q->splitchar)) 
            break;
        else 
            q = q->next_trans;
    }
    return q;
}

void _record_match(fsm this, int matchlen, trans p){

    SV* val = (SV*) p->next_state;
    av_push(this->found_keys,    newSVpvn(this->s,matchlen+1));
    av_push(this->found_offsets, newSViv(this->position));
    av_push(this->found_vals,    val);
    SvREFCNT_inc(val);
}

int _eat_wild_chars(fsm this, int matchlen, trans p){
    char* t = this->s + matchlen;
    
    int wildlength = 0;

    while( IS_BIT_ON( this->wild, 0, *t ) ){
        t++;
        wildlength++;
        if(wildlength > 256) return 0;
    }

    matchlen += wildlength;
    p = p->next_state;
    return _find_match(this, matchlen, p);
}

int _find_match(fsm this, int matchlen, trans p){

// These items are invariant through a complete recursive call.
//this->s             (document to match)
//this->position      (position in document where s starts)
//this->found_keys    (perl list of found text)
//this->found_offsets (perl list of offsets for found text)
//this->found_vals    (perl list of found values stored in fsm)

    int depth = matchlen;
    char* t = this->s + matchlen; //starting point for this match

    while(p){

        // if this is a termination state
        if(!p->splitchar){
            
            if( IS_BIT_ON( this->boundary, 0, *t ) 
                || IS_BIT_ON( this->inclboundary,0,*t)
                ){
                matchlen = depth - 1;
                _record_match(this, matchlen, p);
            }
            p = p->next_trans;
        }
	

        // ignore irrelevant chars
        while( IS_BIT_ON(this->ignore, 0, *t) ){
            t++;
            depth += 1;
        }

        // squeeze spaces cough cough
        if(this->squeezeblanks && IS_BIT_ON(this->charclasses, ' ', *t))
            while(IS_BIT_ON(this->charclasses, ' ', *(t+1))){
                t++;
                depth++;
            }

        // find wildcard matches
        if(p && p->splitchar == '*' && this->use_wildcards)
            matchlen = _eat_wild_chars(this, depth, p);


        // search for t
        p = _bsearch( this->charclasses, *t, p );

        if(p){
            t++;
            depth++;
            p = p->next_state;
        }
    }

    return matchlen;
}


void _scan(fsm this, char *s) {

    int match = 0;
    int position = 0;
    int cue = 0;
    
    while(*s){
        this->s = s;
        this->position = position;
        match = _find_match(this, 0, this->root); 

        // truncate s by single char to match everything possible
        if(match){ s++; position++; }

        // cue up the first possible match:
        // [boundary][ignore]*[firstmatchchar]/
        if( cue = _cue(this, s) ){ 
            position += cue; 
            s += cue; }
        else 
            break;
        
        match = 0;
    }
}

int _cue( fsm this, char *s ){

    int position = 0;

    while(*s){
      
      
      //Move to the first boundary char
      //or stop in case the char is an inclboundary
      // When we are in a word, we dont want to skip the chars who
      // could be included boundary
      // But we still want to skip at least to the next char,
      
      while( ! IS_BIT_ON(this->boundary, 0, *s)  ) {
	s++; position++; 
	if ( IS_BIT_ON(this->inclboundary,0,*s) ) { break ;}
      }
      
      // chop off the first boundary only if not an included boundary
	if(*s != 0
	   && ! IS_BIT_ON(this->inclboundary,0,*s)
	   ) { s++; position++; }
	
	   
        // move past any irrelevant chars
        while( IS_BIT_ON(this->ignore, 0, *s) ) { s++; position++; }

        // found a starting match point?
        if( (int) _bsearch(this->charclasses, *s, this->root) ){
            return position;
        }
    }
    return 0;
}


void _dump(fsm m, trans p, char* k, int depth) {
  
    if (!p) return;

    _dump(m, p->next_trans, k, depth);

    if (p->splitchar){
        *(k+depth) = p->splitchar;
        _dump(m, p->next_state, k, depth+1);
    }
    else {
        av_push(m->found_keys, newSVpvn(k, depth));
        av_push(m->found_vals, (SV*)p->next_state);
        SvREFCNT_inc((SV*)p->next_state);
    }
}


void _init_charclasses(char* vecs){
    int i;
    for(i=0;i<256;i++){
        // For the ith 256-bit span, turn on bit i
        BIT_ON( vecs, i, i );
    }
}

// Default pattern boundary is EOS (null) and space (' ')
void _init_boundary(char* vec){
    BIT_ON( vec, 0, 0 );
    BIT_ON( vec, 0, (int) ' ' );
}

void _init_inclboundary(char* vec ){
}
 

void _init_wild(char* vec){
    int i;
    for(i=1;i<256;i++){
        // All non-space chars match wilds by default
        if( !isspace(i) )
            BIT_ON( vec, 0, i );
    }

}

SV* new(char* class){
    fsm m = (fsm) malloc( sizeof(Fsm) );
    SV* obj_ref = newSViv(0);
    SV*    obj = newSVrv(obj_ref, class);

    m->root = 0;  
    m->terminals = 0;  
    m->transitions = 0;  
    m->states = 0;  
    m->maxpath = 0;

    m->ignore   = (char*) calloc(256/sizeof(char), sizeof(char));
    m->boundary = (char*) calloc(256/sizeof(char), sizeof(char));
    m->wild     = (char*) calloc(256/sizeof(char), sizeof(char));
    m->inclboundary =  (char*) calloc(256/sizeof(char), sizeof(char));
    m->charclasses = (char*) calloc((256*256)/sizeof(char), sizeof(char));
    
    _init_inclboundary(m->inclboundary);
    _init_boundary(m->boundary);
    _init_charclasses(m->charclasses);
    _init_wild(m->wild);

    m->found_keys = (AV*) newAV(); 
    m->found_offsets = (AV*) newAV();
    m->found_vals = (AV*) newAV();

    m->use_wildcards = FALSE;
    m->squeezeblanks = FALSE;
    
    sv_setiv(obj, (IV)m);
    SvREADONLY_on(obj);
    return obj_ref;
}

void DESTROY(SV* obj){
    fsm m = (fsm)SvIV(SvRV(obj));

// takes *far* too long compared to OS garbage collection.
//    _cleanup_(m->root);
//    free(m->charclasses);
//    free(m->ignore);
//    free(m);
}

void usewild(SV* obj){
    fsm m = (fsm)SvIV(SvRV(obj));
    m->use_wildcards = TRUE;
}

void squeezeblanks(SV* obj){
    fsm m = (fsm)SvIV(SvRV(obj));
    m->squeezeblanks = TRUE;
}


// This must be called before any insert(), but may be called
// any number of times.
void charclass(SV* obj, char* vecstring){
    fsm m = (fsm)SvIV(SvRV(obj));
    char* i = vecstring;
    char* j = vecstring;
    char* vec = m->charclasses;
    while(*i){
        while(*j){
            // For the ith 256-bit span, turn on the jth bit
            BIT_ON( vec, *i, *j);
            j++;
        }
        j = vecstring;
        i++;
    }
}

void ignore(SV* obj, char* vecstring){
    fsm m = (fsm)SvIV(SvRV(obj));
    char* i = vecstring;
    for(; *i; i++ )
        BIT_ON( m->ignore, 0, *i);

    // "ignore" chars also count as boundaries
    i = vecstring;
    for(; *i; i++ )
        BIT_ON( m->boundary, 0, *i );

    // "ignore" chars also match wildcards
    i = vecstring;
    for(; *i; i++ )
        BIT_ON( m->wild, 0, *i );
}

void ignorecase(SV* obj){
    charclass(obj, "Aa");
    charclass(obj, "Bb");
    charclass(obj, "Cc");
    charclass(obj, "Dd");
    charclass(obj, "Ee");
    charclass(obj, "Ff");
    charclass(obj, "Gg");
    charclass(obj, "Hh");
    charclass(obj, "Ii");
    charclass(obj, "Jj");
    charclass(obj, "Kk");
    charclass(obj, "Ll");
    charclass(obj, "Mm");
    charclass(obj, "Nn");
    charclass(obj, "Oo");
    charclass(obj, "Pp");
    charclass(obj, "Qq");
    charclass(obj, "Rr");
    charclass(obj, "Ss");
    charclass(obj, "Tt");
    charclass(obj, "Uu");
    charclass(obj, "Vv");
    charclass(obj, "Ww");
    charclass(obj, "Xx");
    charclass(obj, "Yy");
    charclass(obj, "Zz");
}

// define class of chars that qualify as beginning/ending of patterns
// meaning, what is allowed to occur right before or after pattern
void boundary(SV* obj, char* b){
    fsm m = (fsm)SvIV(SvRV(obj));
    int i;

    // Reset boundary to none
    for( i=0; i<(256/sizeof(char)); i++ )
        *(m->boundary + i) = 0;

    BIT_ON( m->boundary, 0, 0 );

    // Special case: if null string specified, all chars are boundary
    if(!*b)
        for( i=0; i<256; i++ )
            BIT_ON( m->boundary, 0, i );

    // Otherwise set the specified chars as boundary
    else
        for(; *b; b++ )
            BIT_ON( m->boundary, 0, *b );
    
    
}


void inclboundary(SV* obj, char* b){
  fsm m = (fsm)SvIV(SvRV(obj));
  int i;
  
  // Reset boundary to none
  for( i=0; i<(256/sizeof(char)); i++ )
      *(m->inclboundary + i) = 0;  

  if(!*b){ return ; }
  
  for(; *b; b++ )
    BIT_ON( m->inclboundary, 0, *b );
    
}


int insert(SV* obj, SV* key, SV* val) {
    fsm m = (fsm)SvIV(SvRV(obj));

    //Don't make a copy of the key, but do make one of the value
    SV* v = newSVsv( val );
    char* s = SvPV_nolen( key );
    int keylen = strlen(s);
    if(keylen > m->maxpath) m->maxpath = keylen;
    if(keylen == 0) return 1;
    m->root = _insert_(m, m->root, s, v);
    return 1;
}


int has(SV* obj, char *s) {
    fsm m = (fsm)SvIV(SvRV(obj));
    return _search(m->root, s);
}

SV* val(SV* obj, char *s) {
    fsm m = (fsm)SvIV(SvRV(obj));
    trans p = m->root;
    while (p) {
        while(p)
            if(p->splitchar == *s) break;
            else p = p->next_trans;
        if(!p) return &PL_sv_undef;
        if(!p->splitchar) return newSVsv((SV*) p->next_state);
        p = p->next_state;
        s++;
    }
    return &PL_sv_undef;
}


void dump(SV* obj){
    fsm m = (fsm)SvIV(SvRV(obj));
    int i;
    SV** ptr;
    char *k;
    INLINE_STACK_VARS;

    k = (char*) malloc(sizeof(char) * m->maxpath);
    _malloc(m);
    _dump(m, m->root, k, 0);
    free(k);

    INLINE_STACK_RESET;
    for (i = 0; i <= av_len(m->found_keys); i++) {
        ptr = av_fetch(m->found_keys, i, 0);
        INLINE_STACK_PUSH(sv_2mortal(newSVsv(*ptr)));
        ptr = av_fetch(m->found_vals, i, 0);
        INLINE_STACK_PUSH(sv_2mortal(newSVsv(*ptr)));
    }
    INLINE_STACK_DONE;
}

void keys(SV* obj){
    fsm m = (fsm)SvIV(SvRV(obj));
    int i;
    SV** ptr;
    char *k;
    INLINE_STACK_VARS;

    k = (char*) malloc(sizeof(char) * m->maxpath);
    _malloc(m);
    _dump(m, m->root, k, 0);
    free(k);

    INLINE_STACK_RESET;
    for (i = 0; i <= av_len(m->found_keys); i++) {
        ptr = av_fetch(m->found_keys, i, 0);
        INLINE_STACK_PUSH(sv_2mortal(newSVsv(*ptr)));
    }
    INLINE_STACK_DONE;
}

void values(SV* obj){
    fsm m = (fsm)SvIV(SvRV(obj));
    int i;
    SV** ptr;
    char *k;
    INLINE_STACK_VARS;

    k = (char*) malloc(sizeof(char) * m->maxpath);
    _malloc(m);
    _dump(m, m->root, k, 0);
    free(k);

    INLINE_STACK_RESET;
    for (i = 0; i <= av_len(m->found_vals); i++) {
        ptr = av_fetch(m->found_vals, i, 0);
        INLINE_STACK_PUSH(sv_2mortal(newSVsv(*ptr)));
    }
    INLINE_STACK_DONE;

}

int states(SV* obj){
    fsm m = (fsm)SvIV(SvRV(obj));
    return m->states;
}

int transitions(SV* obj){
    fsm m = (fsm)SvIV(SvRV(obj));
    return m->transitions;
}

int terminals(SV* obj){
    fsm m = (fsm)SvIV(SvRV(obj));
    return m->terminals;
}



void scan(SV* obj, char *s) {
    fsm m = (fsm)SvIV(SvRV(obj));
    int i;
    SV** ptr;
    INLINE_STACK_VARS;
    
    _malloc(m);
    _scan(m, s);
    
    INLINE_STACK_RESET;
    for (i = 0; i <= av_len(m->found_keys); i++) {
        ptr = av_fetch(m->found_keys, i, 0);
        INLINE_STACK_PUSH(sv_2mortal(newSVsv(*ptr)));
        ptr = av_fetch(m->found_vals, i, 0);
        INLINE_STACK_PUSH(sv_2mortal(newSVsv(*ptr)));
    }
    INLINE_STACK_DONE;
}

void mindex(SV* obj, char *s) {
    fsm m = (fsm)SvIV(SvRV(obj));
    int i;
    SV** ptr;
    INLINE_STACK_VARS;
    
    _malloc(m);
    _scan(m, s);
    
    INLINE_STACK_RESET;
    for (i = 0; i <= av_len(m->found_keys); i++) {
        ptr = av_fetch(m->found_keys, i, 0);
        INLINE_STACK_PUSH(sv_2mortal(newSVsv(*ptr)));
        ptr = av_fetch(m->found_offsets, i, 0);
        INLINE_STACK_PUSH(sv_2mortal(newSVsv(*ptr)));
    }
    INLINE_STACK_DONE;
}

void multiscan(SV* obj, char *s) {
    fsm m = (fsm)SvIV(SvRV(obj));
    int i;
    SV** ptr;
    AV* result; // holds one result (3-item array)
    INLINE_STACK_VARS;
    
    _malloc(m);
    _scan(m, s);
    
    INLINE_STACK_RESET;
    for (i = 0; i <= av_len(m->found_keys); i++) {

        result = (AV*) newAV();

        ptr = av_fetch(m->found_keys, i, 0);
        av_push(result, (SV*) newSVsv(*ptr));

        ptr = av_fetch(m->found_offsets, i, 0);
        av_push(result, (SV*) newSVsv(*ptr));

        ptr = av_fetch(m->found_vals, i, 0);
        av_push(result, (SV*) newSVsv(*ptr));

        INLINE_STACK_PUSH(sv_2mortal(newRV_noinc((SV*)result)));
    }
    INLINE_STACK_DONE;
}



// This inline uses variables in context
#define RECORD_STATE \
    i = 1; \
    if(front->splitchar == 0){ \
        s = (char *)SvPV_nolen( (SV*)front->next_state ); \
        len = strlen(s); \
        PerlIO_write( valfp, &len, sizeof(unsigned int)); \
        PerlIO_write( valfp, s, sizeof(char) * len); \
    } \
    while(front->next_trans){ \
        *(tlist+i) = front->splitchar; \
        i++; \
        front = front->next_trans; \
        pos++; \
    } \
    *(tlist+i) = front->splitchar; \
    *tlist = i; \
    PerlIO_write(statefp, tlist, sizeof(char) * (size_t) i+1); \

    
    // Record the trie and its values to disk, to be reloaded
// at another time. For this to work, all values must be either 
// numbers or strings, ie Perl scalars but no references.
// tlist - String to record the transition list for each state
// tvector - bit vector of transition positions, to record the 
//         end-of-state position so the trie can be recreated.
int _serialize(SV* obj, char *triename, char *valsname){
    fsm m = (fsm)SvIV(SvRV(obj));
    trans front, back;
    PerlIO *statefp, *valfp;
    int pos, len, i;
    char *tlist = (char*) malloc(sizeof(char) * 255);
    char *tvector = 
        (char*) calloc((size_t)ceil(m->transitions/8), sizeof(char));
    char *s;
    
    if( !(statefp = PerlIO_open(triename, "wb"))){ return errno; }
    if( !(valfp =   PerlIO_open(valsname, "wb"))){ return errno; }

    PerlIO_write( statefp, &m->terminals,   sizeof(int));
    PerlIO_write( statefp, &m->transitions, sizeof(int));
    PerlIO_write( statefp, &m->states,      sizeof(int));
    PerlIO_write( statefp, &m->maxpath,     sizeof(int));
    PerlIO_write( statefp, &m->use_wildcards, sizeof(bool));
    
    // execute breadth-first traversal of the trie
    // recording the positions of state-ending transitions
    // in the bit vector for later reconstruction.
    front = back = m->root;
    pos = 0;
    while( front ){
        // record state [and value if present] at front, 
        // move front to end of state. Increment pos by len of state
        RECORD_STATE;
        BIT_ON(tvector, 0, pos);
        
        if(!back){ break; } //the end
        
        front->next_trans = back->next_state;
        front = front->next_trans; 
        pos++;
        back = back->next_trans;
        while(back && back->splitchar == 0){ 
            back = back->next_trans;
        }
    }

// Now repair the trie, severing horizontal links between states
    front = m->root;
    for( pos=0; pos < m->transitions; pos++ ){
        if(IS_BIT_ON(tvector, 0, pos)){
            back = front;
            front = front->next_trans;
            back->next_trans = 0;
        }
        else {
            front = front->next_trans;
        }
    }
    
    PerlIO_close(statefp);
    PerlIO_close(valfp);

    return 0;
}


// Add a value back into the trie. Called from restore()
void _restore_val(trans t, PerlIO* valfp){    
    unsigned int len = 0;
    char* s;
    
    PerlIO_read(valfp, &len, sizeof(unsigned int));
    s = (char*) malloc(len * sizeof(char));
    PerlIO_read(valfp, s, sizeof(char) * len);

    t->next_state = (trans)    newSVpvn(s, len);     
}

// Restore the serialized trie.
int _restore( SV* obj, char *triename, char *valsname ){
    fsm m = (fsm)SvIV(SvRV(obj));
    trans front, back, last, linker, restorer;
    PerlIO *statefp, *valfp;
    int j, transitions = 0, states = 0, terminals = 0;
    char len;

    if( !(statefp = PerlIO_open(triename, "rb")) ){ return errno; }
    if( !(valfp =   PerlIO_open(valsname, "rb")) ){ return errno; }

    
/* Read in metadata */
    PerlIO_read( statefp, &m->terminals,   sizeof(int));
    PerlIO_read( statefp, &m->transitions, sizeof(int));
    PerlIO_read( statefp, &m->states,      sizeof(int));
    PerlIO_read( statefp, &m->maxpath,     sizeof(int));
    PerlIO_read( statefp, &m->use_wildcards, sizeof(bool));

    // create transitions
    m->root = (trans) malloc(sizeof(Trans));
    front = m->root;
    while( !PerlIO_eof(statefp) ){
        states++;
        PerlIO_read( statefp, &len, sizeof(char) );
        for( j=0; j < len; j++ ){
            front->splitchar = (char) PerlIO_getc(statefp);
            front->next_state = 0;
            front->next_trans = (trans) malloc(sizeof(Trans));
            transitions++;
            last = front;
            front = front->next_trans;
        }
        front->next_trans = 0; 
        front->next_state = 0;
        last->next_state = front;
        last->next_trans = 0;
    }
    last->next_state = 0;
    free(front);
    
    // link transitions appropriately
    front = back = m->root;
    while(back){
        linker = back;
        while(front->next_trans)
            front = front->next_trans;
        front = front->next_state;

        back = back->next_trans ? back->next_trans : back->next_state;
        while(back && !back->splitchar){
            restorer = back;
            back = back->next_trans ? back->next_trans : back->next_state;
            _restore_val(restorer, valfp);
            terminals++;
        }
        linker->next_state = front;
    }

    m->transitions = transitions - 1;
    m->states = states - 1;
    m->terminals = terminals;
    
    PerlIO_close(valfp);
    PerlIO_close(statefp);

    return 0;
}






MODULE = Text::Scan	PACKAGE = Text::Scan	

PROTOTYPES: DISABLE


void
_init_charclasses (vecs)
	char *	vecs
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	_init_charclasses(vecs);
	if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
	  PL_markstack_ptr = temp;
	  XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
	return; /* assume stack size is correct */

void
_init_boundary (vec)
	char *	vec
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	_init_boundary(vec);
	if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
	  PL_markstack_ptr = temp;
	  XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
	return; /* assume stack size is correct */

void
_init_inclboundary (vec)
	char *	vec
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	_init_inclboundary(vec);
	if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
	  PL_markstack_ptr = temp;
	  XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
	return; /* assume stack size is correct */

void
_init_wild (vec)
	char *	vec
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	_init_wild(vec);
	if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
	  PL_markstack_ptr = temp;
	  XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
	return; /* assume stack size is correct */

SV *
new (class)
	char *	class

void
DESTROY (obj)
	SV *	obj
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	DESTROY(obj);
	if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
	  PL_markstack_ptr = temp;
	  XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
	return; /* assume stack size is correct */

void
usewild (obj)
	SV *	obj
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	usewild(obj);
	if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
	  PL_markstack_ptr = temp;
	  XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
	return; /* assume stack size is correct */

void
squeezeblanks (obj)
	SV *	obj
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	squeezeblanks(obj);
	if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
	  PL_markstack_ptr = temp;
	  XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
	return; /* assume stack size is correct */

void
charclass (obj, vecstring)
	SV *	obj
	char *	vecstring
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	charclass(obj, vecstring);
	if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
	  PL_markstack_ptr = temp;
	  XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
	return; /* assume stack size is correct */

void
ignore (obj, vecstring)
	SV *	obj
	char *	vecstring
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	ignore(obj, vecstring);
	if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
	  PL_markstack_ptr = temp;
	  XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
	return; /* assume stack size is correct */

void
ignorecase (obj)
	SV *	obj
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	ignorecase(obj);
	if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
	  PL_markstack_ptr = temp;
	  XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
	return; /* assume stack size is correct */

void
boundary (obj, b)
	SV *	obj
	char *	b
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	boundary(obj, b);
	if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
	  PL_markstack_ptr = temp;
	  XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
	return; /* assume stack size is correct */

void
inclboundary (obj, b)
	SV *	obj
	char *	b
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	inclboundary(obj, b);
	if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
	  PL_markstack_ptr = temp;
	  XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
	return; /* assume stack size is correct */

int
insert (obj, key, val)
	SV *	obj
	SV *	key
	SV *	val

int
has (obj, s)
	SV *	obj
	char *	s

SV *
val (obj, s)
	SV *	obj
	char *	s

void
dump (obj)
	SV *	obj
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	dump(obj);
	if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
	  PL_markstack_ptr = temp;
	  XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
	return; /* assume stack size is correct */

void
keys (obj)
	SV *	obj
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	keys(obj);
	if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
	  PL_markstack_ptr = temp;
	  XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
	return; /* assume stack size is correct */

void
values (obj)
	SV *	obj
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	values(obj);
	if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
	  PL_markstack_ptr = temp;
	  XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
	return; /* assume stack size is correct */

int
states (obj)
	SV *	obj

int
transitions (obj)
	SV *	obj

int
terminals (obj)
	SV *	obj

void
scan (obj, s)
	SV *	obj
	char *	s
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	scan(obj, s);
	if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
	  PL_markstack_ptr = temp;
	  XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
	return; /* assume stack size is correct */

void
mindex (obj, s)
	SV *	obj
	char *	s
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	mindex(obj, s);
	if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
	  PL_markstack_ptr = temp;
	  XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
	return; /* assume stack size is correct */

void
multiscan (obj, s)
	SV *	obj
	char *	s
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	multiscan(obj, s);
	if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
	  PL_markstack_ptr = temp;
	  XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
	return; /* assume stack size is correct */

int
_serialize (obj, triename, valsname)
	SV *	obj
	char *	triename
	char *	valsname

int
_restore (obj, triename, valsname)
	SV *	obj
	char *	triename
	char *	valsname

