typedef struct tnode *Tptr;

typedef struct tnode {
  char splitchar;
  Tptr lokid, eqkid, hikid;
} Tnode;

typedef struct tobj {
  Tptr root;
  int terminals;
  int nodes;
  char ** searchchar;
  int searchcharn;
  int searchn;
} Tobj;


extern Tobj  t_new        (void);
extern void  t_DESTROY    (Tobj *pTernary);
extern void  t_insert     (Tobj *pTernary, char* s);
extern int   t_search     (Tobj *pTernary, char* s);
extern void  t_pmsearch   (Tobj *pTernary, char* w, char* s);
extern void  t_nearsearch (Tobj *pTernary, char* s, int i);
extern void  t_traverse   (Tobj *pTernary);
extern int   t_terminals  (Tobj *pTernary);
extern int   t_nodes      (Tobj *pTernary);

Tptr _insert     (Tobj *pTernary, Tptr p, char *s, char *insertstr);
void _cleanup    (Tptr p);
void _pmsearch   (Tobj *pTernary, Tptr p, char *w, char *s);
void _nearsearch (Tobj *pTernary, Tptr p, char *s, int i);
int  _search     (Tptr p, char *s);
void _traverse   (Tobj *pTernary, Tptr p);
