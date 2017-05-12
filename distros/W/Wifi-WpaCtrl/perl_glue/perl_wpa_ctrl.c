#include "perl_wpa_ctrl.h"

SV*
perl_wpa_ctrl_new_sv_from_wpa_ctrl_ptr(struct wpa_ctrl *ctrl, const char *CLASS) {
	SV *obj;
	SV *sv;
	HV *stash;

	obj = (SV*)newHV();
	sv_magic(obj, 0, PERL_MAGIC_ext, (const char*)ctrl, 0);
	sv = newRV_inc(obj);
	stash = gv_stashpv(CLASS, 1);
	sv_bless(sv, stash);

	return sv;
}

struct wpa_ctrl*
perl_wpa_ctrl_get_wpa_ctrl_ptr_from_sv(SV *sv) {
	MAGIC *mg;

	/* TODO: $sv->isa('Wifi::WpaCtrl') */
	if (!sv || !SvOK(sv) || !SvROK(sv) || !(mg = mg_find(SvRV(sv), PERL_MAGIC_ext)))
		return NULL;

	return (struct wpa_ctrl*)mg->mg_ptr;
}
