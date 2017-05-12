#include "perl_wpa_ctrl.h"

MODULE = Wifi::WpaCtrl	PACKAGE = Wifi::WpaCtrl	PREFIX = wpa_ctrl_

void
wpa_ctrl_new(class, ctrl_path=NULL)
		const char *class
		const char *ctrl_path
	PREINIT:
		struct wpa_ctrl *ctrl = NULL;
	PPCODE:
		ctrl = wpa_ctrl_open(ctrl_path);

		if (ctrl == NULL) {
			ST(0) = &PL_sv_undef;
		} else {
			ST(0) = perl_wpa_ctrl_new_sv_from_wpa_ctrl_ptr(ctrl, class);
		}

		sv_2mortal(ST(0));
		XSRETURN(1);

void
wpa_ctrl_close(ctrl)
		struct wpa_ctrl *ctrl

SV*
wpa_ctrl_request(ctrl, cmd)
		struct wpa_ctrl *ctrl
		SV* cmd
	PREINIT:
		const char *cmd_str = NULL;
		size_t cmd_len = 0;
		char reply[2048];
		size_t reply_len = sizeof(reply) - 1;
		int return_value = 0;
	CODE:
		cmd_str = SvPV(cmd, cmd_len);
		return_value = wpa_ctrl_request(ctrl, cmd_str, cmd_len, reply, &reply_len, NULL);

		if (return_value == -2)
			croak("Wifi::WpaCtrl::request: got timeout");

		if (return_value == -1) {
			RETVAL = &PL_sv_undef;
		} else {
			RETVAL = newSVpvn(reply, reply_len);
		}
	OUTPUT:
		RETVAL

SV*
wpa_ctrl_attach(ctrl)
		struct wpa_ctrl *ctrl
	PREINIT:
		int return_value = 0;
	CODE:
		return_value = wpa_ctrl_attach(ctrl);

		if (return_value == 0) {
			RETVAL = newSViv(1);
		} else if (return_value == -2) {
			RETVAL = &PL_sv_undef;
		} else {
			RETVAL = newSViv(0);
		}
	OUTPUT:
		RETVAL

SV*
wpa_ctrl_detach(ctrl)
		struct wpa_ctrl *ctrl
	PREINIT:
		int return_value = 0;
	CODE:
		return_value = wpa_ctrl_detach(ctrl);

		if (return_value == 0) {
			RETVAL = newSViv(1);
		} else if (return_value == -2) {
			RETVAL = &PL_sv_undef;
		} else {
			RETVAL = newSViv(0);
		}
	OUTPUT:
		RETVAL

SV*
wpa_ctrl_recv(ctrl)
		struct wpa_ctrl *ctrl
	PREINIT:
		char reply[2048];
		size_t reply_len = sizeof(reply) - 1;
		int return_value = 0;
	CODE:
		return_value = wpa_ctrl_recv(ctrl, reply, &reply_len);

		if (return_value == -1) {
			RETVAL = &PL_sv_undef;
		} else {
			RETVAL = newSVpvn(reply, reply_len);
		}

		printf("%s\n", SvPV_nolen(RETVAL));
	OUTPUT:
		RETVAL

int
wpa_ctrl_pending(ctrl)
		struct wpa_ctrl *ctrl

int
wpa_ctrl_get_fd(ctrl)
		struct wpa_ctrl *ctrl
