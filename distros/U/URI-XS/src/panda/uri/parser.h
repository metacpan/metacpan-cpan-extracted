#include "URI.h"

#define SAVE(dest)  dest = str.substr(mark, p - ps - mark);
#define NSAVE(dest) dest = acc; acc = 0
