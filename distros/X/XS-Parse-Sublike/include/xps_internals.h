#ifndef __XPS_INTERNALS_H__
#define __XPS_INTERNALS_H__

struct HooksAndData {
  const struct XSParseSublikeHooks *hooks;
  void *data;
};

#define FOREACH_HOOKS_FORWARD \
  for(hooki = 0; \
    (hooki < nhooks) && (hooks = hooksanddata[hooki].hooks, hookdata = hooksanddata[hooki].data), (hooki < nhooks); \
    hooki++)

#define FOREACH_HOOKS_REVERSE \
  for(hooki = nhooks - 1; \
    (hooki >= 0) && (hooks = hooksanddata[hooki].hooks, hookdata = hooksanddata[hooki].data), (hooki >= 0); \
    hooki--)

struct XPSContextWithPointer {
  struct XSParseSublikeContext ctx;
  void *sigctx;
};

#endif
