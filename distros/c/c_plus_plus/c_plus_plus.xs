#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

class aaa {
  public:
    char name[100];
    aaa(char *s) {strcpy(name,s); printf("Initializing `%s'...\n", name);}
    ~aaa() {printf("Destroying `%s'...\n", name);}
    message() {printf("`%s' got message...\n", name);}
};

aaa a("static");


MODULE = c_plus_plus		PACKAGE = c_plus_plus

BOOT:
    a.message();
    aaa b("auto");
    b.message();
