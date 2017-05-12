#include "sys/types.h"
#include "wpa_ctrl.h"
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "proto.h"

SV* perl_wpa_ctrl_new_sv_from_wpa_ctrl_ptr(struct wpa_ctrl *ctrl, const char *CLASS);

struct wpa_ctrl* perl_wpa_ctrl_get_wpa_ctrl_ptr_from_sv(SV *sv);
