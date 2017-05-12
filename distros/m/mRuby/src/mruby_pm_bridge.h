#include "use_perl.h"

#include "mruby.h"
#include "mruby/value.h"

SV * mruby_pm_bridge_value2sv(pTHX_ mrb_state *mrb, const mrb_value v);
mrb_value mruby_pm_bridge_sv2value(pTHX_ mrb_state *mrb, SV *sv);
