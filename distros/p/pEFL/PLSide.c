#include "PLSide.h"

char* _get_keybuffer(char *event, UV addr, int *len) {
	// the maximal keybuffer is the key for the function:
	// event###addresstofunc\0
	if (event == NULL) {
		 int number_of_digits = snprintf(NULL, 0, "%"UVuf, addr);
		*len = number_of_digits + 1;
	}
	else {
		int number_of_digits = snprintf(NULL, 0, "%"UVuf, addr);
		*len = strlen(event) + 3 + number_of_digits + 1;
	}
	char *keybuffer = malloc(*len);
	if (keybuffer == NULL) {
		croak("Speicherfehler\n");
	}
	return keybuffer;
}

char* _get_keybuffer2(pTHX_ char *event, SV* funcname, int *len) {
	// the maximal keybuffer is the key for the function:
	// event###addresstofunc\0
	if (event == NULL) {
		 int number_of_digits = snprintf(NULL, 0, "%s", SvPV_nolen(funcname));
		*len = number_of_digits + 1;
	}
	else {
		int number_of_digits = snprintf(NULL, 0, "%s", SvPV_nolen(funcname));
		*len = strlen(event) + 3 + number_of_digits + 1;
	}
	char *keybuffer = malloc(*len);
	if (keybuffer == NULL) {
		croak("Speicherfehler\n");
	}
	return keybuffer;
}


HV* _get_smart_cb_hash(pTHX_ UV objaddr,char *event,SV *funcname, char* hashName) {
	HV* Obj_Cbs;
	int len, n;
	char *keybuffer = _get_keybuffer2(aTHX_ event,funcname, &len);

	HV *Callbacks = get_hv(hashName, 0);
	if (Callbacks == NULL) {
		croak("pEFL::PLSide::Callbacks hash does not exist\n");
	}

	n = snprintf(keybuffer, len, "%" UVuf, objaddr);
	if (hv_exists(Callbacks,keybuffer,strlen(keybuffer))) {
		SV** Obj_CbsPtr = hv_fetch(Callbacks, keybuffer,strlen(keybuffer),FALSE);
		Obj_Cbs = (HV*) (SvRV(*Obj_CbsPtr));
	}
	else {
		croak("Error in _get_smart_cb_hash: No callbacks found\n");
	}


	n = snprintf(keybuffer, len, "%s###%s", event, SvPV_nolen(funcname));
	SV** Cb_DataPtr = hv_fetch(Obj_Cbs, keybuffer, strlen(keybuffer), FALSE);
	HV *cb_data = (HV*) SvRV(*Cb_DataPtr);

	free(keybuffer);

	return cb_data;
}

_perl_callback *perl_save_callback(pTHX_ SV *func, UV objaddr, char *event, char *hashName) {
	_perl_callback *cb;

	cb = (_perl_callback *)malloc(sizeof(_perl_callback));
	memset(cb, '\0', sizeof(_perl_callback));
	cb->funcname = newSV(0);

	if (func && SvOK(func)) {
		cv_name((CV*)SvRV(func),cb->funcname,0);
	}
	else {
		croak("No function passed\n");
	}

	if (objaddr) {
		cb->objaddr = objaddr;
	}
	else {
		croak("EvasObject missing\n");
	}

	if (event) {
			strcpy(cb->event, event);
	}

	// For Smart Callbacks and Evas Callbacks we have to save
	// a pointer to the c struct in the perl hash, too
	// This is necessary for deletion
	if (strcmp(hashName,"pEFL::PLSide::Format_Cbs") == 0) {
		HV *cb_data = _get_format_cb_hash(aTHX_ cb->objaddr);
		hv_store(cb_data, "cstructaddr",11,newSVuv(PTR2UV(cb)),0);
	}
	else if (strcmp(hashName,"pEFL::PLSide::Callbacks") == 0) {
		HV *smart_cb = _get_smart_cb_hash(aTHX_ cb->objaddr,cb->event,cb->funcname, hashName);
		hv_store(smart_cb, "cstructaddr",11,newSVuv(PTR2UV(cb)),0);
	}

	return cb;
}


void call_perl_sub(void *data, Evas_Object *obj, void *event_info) {
	dTHX;
	dSP;

	int n;
	int count;
	SV *s_obj = newSV(0);
	_perl_callback *perl_saved_cb = data;

	SV *s_ei  = newSV(0);
	if (event_info) {
		if (SvTRUE(get_sv("pEFL::Debug",0)))
			fprintf(stderr, "event has an event info\n");
		IV adress;
		adress = PTR2IV(event_info);
		sv_setiv(s_ei,adress);
	}

	HV *cb_data = _get_smart_cb_hash(aTHX_ perl_saved_cb->objaddr,perl_saved_cb->event,perl_saved_cb->funcname, "pEFL::PLSide::Callbacks");

	SV *pclass = *( hv_fetch(cb_data, "pclass",6,FALSE) );
	SV *func = *( hv_fetch(cb_data, "function",8,FALSE) );
	SV *args = *( hv_fetch(cb_data, "data",4,FALSE) ) ;



	sv_setref_pv(s_obj, SvPV_nolen(pclass), obj);

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);

	XPUSHs(args);
	XPUSHs(sv_2mortal(s_obj));
	XPUSHs(sv_2mortal(s_ei));


	PUTBACK;

	count = call_sv(func, G_DISCARD);
	if (count != 0) {
		croak("Expected 0 value got %d\n", count);
	}

	FREETMPS;
	LEAVE;

	/* TODO free data? */
}

void call_perl_evas_event_cb(void *data, Evas *e, Evas_Object *obj, void *event_info) {
	dTHX;
	dSP;

	int n;
	int count;
	SV *s_obj = newSV(0);
	SV *s_canvas = newSV(0);
	_perl_callback *perl_saved_cb = data;

	SV *s_ei  = newSV(0);
	if (event_info) {
		if (SvTRUE(get_sv("pEFL::Debug",0)))
			fprintf(stderr, "event has an event info\n");
		IV adress;
		adress = PTR2IV(event_info);
		sv_setiv(s_ei,adress);
	}

	HV *cb_data = _get_smart_cb_hash(aTHX_ perl_saved_cb->objaddr,perl_saved_cb->event,perl_saved_cb->funcname, "pEFL::PLSide::Callbacks");

	SV *pclass = *( hv_fetch(cb_data, "pclass",6,FALSE) );
	SV *func = *( hv_fetch(cb_data, "function",8,FALSE) );
	SV *args = *( hv_fetch(cb_data, "data",4,FALSE) ) ;



	sv_setref_pv(s_obj, SvPV_nolen(pclass), obj);
	sv_setref_pv(s_canvas, "pEFL::Evas::Canvas", e);

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);

	XPUSHs(args);
	XPUSHs(sv_2mortal(s_canvas));
	XPUSHs(sv_2mortal(s_obj));
	XPUSHs(sv_2mortal(s_ei));


	PUTBACK;

	count = call_sv(func, G_DISCARD);
	if (count != 0) {
		croak("Expected 0 value got %d\n", count);
	}

	FREETMPS;
	LEAVE;

	/* TODO free data? */
}

Evas_Object* call_perl_tooltip_content_cb(void *data, Evas_Object *obj, Evas_Object *tooltip) {
	dTHX;
	dSP;

	int count;
	SV *s_content;
	IV tmp;
	Evas_Object *ret_obj;

	_perl_callback *perl_saved_cb = data;
	HV *cb_data = _get_smart_cb_hash(aTHX_ perl_saved_cb->objaddr,perl_saved_cb->event,perl_saved_cb->funcname, "pEFL::PLSide::Callbacks");

	// Object
	SV *s_obj = newSV(0);
	SV *pclass = *( hv_fetch(cb_data, "pclass",6,FALSE) );
	sv_setref_pv(s_obj, SvPV_nolen(pclass), obj);

	// Tooltip
	SV *s_tooltip = newSV(0);
	sv_setref_pv(s_tooltip, "EvasObjectPtr", tooltip);


	SV *func = *( hv_fetch(cb_data, "function",8,FALSE) );
	SV *args = *( hv_fetch(cb_data, "data",4,FALSE) ) ;



	sv_setref_pv(s_obj, SvPV_nolen(pclass), obj);

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);

	XPUSHs(args);
	XPUSHs(sv_2mortal(s_obj));
	XPUSHs(sv_2mortal(s_tooltip));


	PUTBACK;

	if (count != 1) {
		croak("Expected 1 value got %d\n", count);
	}

	s_content = POPs;

	if (!SvROK(s_content)) {
			ret_obj = NULL;
		}
	else {
		IV tmp = SvIV((SV*)SvRV(s_content));
		ret_obj = INT2PTR(Evas_Object*,tmp);
		sv_setref_pv(s_obj, "EvasObjectPtr", obj);
	}

	PUTBACK;
	FREETMPS;
	LEAVE;

	return ret_obj;

	/* TODO free data? */
}

void del_tooltip(void *data, Evas_Object *obj, void *event_info) {
	dTHX;
	dSP;

	int n;
	int count;
	SV *s_obj = newSV(0);
	_perl_callback *perl_saved_cb = data;

	SV *s_ei  = newSV(0);
	if (event_info) {
		if (SvTRUE(get_sv("pEFL::Debug",0)))
			fprintf(stderr, "event has an event info\n");
		IV adress;
		adress = PTR2IV(event_info);
		sv_setiv(s_ei,adress);
	}

	HV *cb_data = _get_smart_cb_hash(aTHX_ perl_saved_cb->objaddr,perl_saved_cb->event,perl_saved_cb->funcname, "pEFL::PLSide::Callbacks");

	SV *pclass = *( hv_fetch(cb_data, "pclass",6,FALSE) );
	SV *func = *( hv_fetch(cb_data, "function",8,FALSE) );
	SV *args = *( hv_fetch(cb_data, "data",4,FALSE) ) ;



	sv_setref_pv(s_obj, SvPV_nolen(pclass), obj);

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);

	XPUSHs(args);
	XPUSHs(sv_2mortal(s_obj));
	XPUSHs(sv_2mortal(s_ei));


	PUTBACK;

	count = call_sv(func, G_DISCARD);
	if (count != 0) {
		croak("Expected 0 value got %d\n", count);
	}

	FREETMPS;
	LEAVE;
	
	
	Safefree(data);
}


void call_perl_edje_message_handler(void *data, Evas_Object *obj, int type, int id,void *msg) {
	dTHX;
	dSP;

	int n;
	int count;
	SV *s_data, *s_obj, *s_type, *s_id, *s_msg;
	char messageClass[26];
	
	_perl_callback *perl_saved_cb = data;
	
	// Get data
	HV *cb_data = _get_smart_cb_hash(aTHX_ perl_saved_cb->objaddr,perl_saved_cb->event,perl_saved_cb->funcname, "pEFL::PLSide::Callbacks");
	SV *pclass = *( hv_fetch(cb_data, "pclass",6,FALSE) );
	SV *func = *( hv_fetch(cb_data, "function",8,FALSE) );
	
	// Data
	s_data = *( hv_fetch(cb_data, "data",4,FALSE) ) ;
		
	// Object
	s_obj = newSV(0);
	sv_setref_pv(s_obj, SvPV_nolen(pclass), obj);
	
	// Type
	s_type = newSViv(type);
	
	//ID
	s_id = newSViv(id);
	
	// msg
	s_msg  = newSV(0);
	if (type == EDJE_MESSAGE_STRING) {
		strcpy(messageClass,"EdjeMessageStringPtr");
	}
	else if (type == EDJE_MESSAGE_INT) {
		strcpy(messageClass,"EdjeMessageStringIntPtr");
	}
	else if (type == EDJE_MESSAGE_FLOAT) {
		strcpy(messageClass,"EdjeMessageFloatPtr");
	}
	else if (type == EDJE_MESSAGE_STRING_SET) {
		strcpy(messageClass,"EdjeMessageStringSetPtr");
	}
	else if (type == EDJE_MESSAGE_INT_SET) {
		strcpy(messageClass,"EdjeMessageIntSetPtr");
	}
	else if (type == EDJE_MESSAGE_FLOAT_SET) {
		strcpy(messageClass,"EdjeMessageFloatSetPtr");
	}
	else if (type == EDJE_MESSAGE_STRING_INT) {
		strcpy(messageClass,"EdjeMessageStringIntPtr");
	}
	else if (type == EDJE_MESSAGE_STRING_FLOAT) {
		strcpy(messageClass,"EdjeMessageStringFloatPtr");
	}
	else {
		croak("Not supported message type\n");
	}
	sv_setref_pv(s_msg, messageClass, msg);
	

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);

	XPUSHs(s_data);
	XPUSHs(sv_2mortal(s_obj));
	XPUSHs(sv_2mortal(s_type));
	XPUSHs(sv_2mortal(s_id));
	XPUSHs(sv_2mortal(s_msg));


	PUTBACK;

	count = call_sv(func, G_DISCARD);
	if (count != 0) {
		croak("Expected 0 value got %d\n", count);
	}

	FREETMPS;
	LEAVE;

	/* TODO free data? */
}

// -----------------
// FORMAT CB STUFF
// -----------------
HV* _get_format_cb_hash(pTHX_ UV objaddr) {
	HV* cb_data;
	int len, n;
	char *keybuffer = _get_keybuffer(NULL,objaddr, &len);

	HV *Callbacks = get_hv("pEFL::PLSide::Format_Cbs", 0);
	if (Callbacks == NULL) {
		croak("pEFL::PLSide::Format_Cbs hash does not exist\n");
	}

	n = snprintf(keybuffer, len, "%" UVuf, objaddr);
	if (hv_exists(Callbacks,keybuffer,strlen(keybuffer))) {
		SV** Cb_DataPtr = hv_fetch(Callbacks, keybuffer,strlen(keybuffer),FALSE);
		cb_data = (HV*) (SvRV(*Cb_DataPtr));
	}
	else {
		croak("Error in _get_format_cb_hash: No callbacks found\n");
	}

	free(keybuffer);

	return cb_data;
}

char* call_perl_format_cb(double value, void* data) {
	dTHX;
	dSP;

	int count; STRLEN len;
	SV *s_string; char* buf = NULL;
	SV *s_value = newSV(0);

	_perl_callback *perl_saved_cb = data;

	HV *cb_data = _get_format_cb_hash(aTHX_ perl_saved_cb->objaddr);


	SV *func = *( hv_fetch(cb_data, "function",8,FALSE) );

	sv_setnv(s_value, value);

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);

	XPUSHs(sv_2mortal(s_value));

	PUTBACK;

	count = call_sv(func, G_SCALAR);

	SPAGAIN;

	if (count != 1) {
		croak("Expected 1 value got %d\n", count);
	}

	s_string = POPs;
	len = sv_len(s_string);
	buf = savepv(SvPV(s_string,len));

	PUTBACK;
	FREETMPS;
	LEAVE;

	return buf;
}

void free_buf(char *buf) {
	Safefree(buf);
}

// -------------------------------------
//	ELM_ENTRY
// ---------------------------------------

HV* _get_markup_filter_cb(pTHX_ UV objaddr,SV* funcname) {
	HV* markup_filters;
	HV* cb_data;
	int len, n;

	HV *cbs = get_hv("pEFL::PLSide::MarkupFilter_Cbs", 0);
	if (cbs == NULL) {
		croak("pEFL::PLSide::MarkupFilter_Cbs hash does not exist\n");
	}

	char *addr_keybuffer = _get_keybuffer(NULL, objaddr,&len);
	n = snprintf(addr_keybuffer, len, "%" UVuf, objaddr);

	if (hv_exists(cbs,addr_keybuffer,strlen(addr_keybuffer))) {
		SV** markup_filtersPtr = hv_fetch(cbs, addr_keybuffer, strlen(addr_keybuffer), FALSE);
		markup_filters = (HV*) SvRV(*markup_filtersPtr);
	}
	else {
		croak("No markup filters found\n");
	}

	free(addr_keybuffer);

	char *keybuffer = _get_keybuffer2(aTHX_ NULL,funcname, &len);
	n = snprintf(keybuffer, len, "%s", SvPV_nolen(funcname));
	if (hv_exists(markup_filters,keybuffer,strlen(keybuffer))) {
		SV** cb_dataPtr = hv_fetch(markup_filters, keybuffer, strlen(keybuffer), FALSE);
		cb_data = (HV*) SvRV(*cb_dataPtr);
	}
	else {
		croak("Error in _get_markup_filters_cb: No callbacks found\n");
	}

	free(keybuffer);

	return cb_data;
}

_perl_callback *save_markup_filter_struct(pTHX_ SV *func, UV addr) {
	_perl_callback *cb;

	cb = (_perl_callback *)malloc(sizeof(_perl_callback));
	memset(cb, '\0', sizeof(_perl_callback));
	cb->funcname = newSV(0);

	if (SvPOK(func) && (strcmp(SvPV_nolen(func),"limit_size") == 0)) {
		cb->funcname = func;
	}
	else if (SvPOK(func) && (strcmp(SvPV_nolen(func),"accept_set") == 0)) {
		cb->funcname = func;
	}
	else if (func && SvOK(func)) {
		cv_name((CV*)SvRV(func),cb->funcname,0);
	}
	else {
		croak("No function passed\n");
	}

	if (addr) {
		cb->objaddr = addr;
	}
	else {
		croak("No object address passed\n");
	}


	HV *markup_filter_cb = _get_markup_filter_cb(aTHX_ cb->objaddr,cb->funcname);
	hv_store(markup_filter_cb, "cstructaddr",11,newSVuv(PTR2UV(cb)),0);

	return cb;
}

void call_perl_markup_filter_cb(void *data, Elm_Entry *entry, char **text) {
	dTHX;
	dSP;

	int count; STRLEN len;
	SV *s_string;


	_perl_callback *perl_saved_cb = data;

	HV *cb_data = _get_markup_filter_cb(aTHX_ perl_saved_cb->objaddr, perl_saved_cb->funcname);

	// Get functoion
	SV *func = *( hv_fetch(cb_data, "function",8,FALSE) );

	// Get data
	SV* s_data = *( hv_fetch(cb_data, "data",4,FALSE) );

	// Get Object
	SV *s_obj = newSV(0);
	sv_setref_pv(s_obj, "ElmEntryPtr", entry);

	// text
	SV *s_text = newSVpvn(*text,strlen(*text));

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);

	XPUSHs(s_data);
	XPUSHs(sv_2mortal(s_obj));
	XPUSHs(sv_2mortal(s_text));

	PUTBACK;

	count = call_sv(func, G_SCALAR);

	SPAGAIN;

	if (count != 1) {
		croak("Expected 1 value got %d\n", count);
	}

	s_string = POPs;
	if (SvOK(s_string) && SvPOK(s_string)) {
		len = sv_len(s_string);
		*text = savepv(SvPV(s_string,len));
	}
	else {
		*text = NULL;
	}

	PUTBACK;
	FREETMPS;
	LEAVE;
}

// -------------------------------------
// Genlist Item Class
//------------------------------------

AV* _get_gen_items(pTHX_ UV objaddr) {
	AV* cbs;
	int len, n;
	char *keybuffer = _get_keybuffer(NULL,objaddr, &len);

	HV *GenItc_Cbs = get_hv("pEFL::PLSide::GenItems", 0);
	if (GenItc_Cbs == NULL) {
		croak("pEFL::PLSide::GenItems hash does not exist\n");
	}

	n = snprintf(keybuffer, len, "%" UVuf, objaddr);
	if (hv_exists(GenItc_Cbs,keybuffer,strlen(keybuffer))) {
		SV** CbsPtr = hv_fetch(GenItc_Cbs, keybuffer,strlen(keybuffer),FALSE);
		cbs = (AV*) (SvRV(*CbsPtr));
	}
	else {
		croak("No items found in Genlist\n");
	}

	free(keybuffer);

	return cbs;
}

HV* _get_gen_item_hash(pTHX_ UV objaddr, int item_id) {
	AV *GenItems = _get_gen_items(aTHX_ objaddr);

	SV** GenItem_Ptr = av_fetch(GenItems, (I32) item_id,FALSE);
	HV *GenItem = (HV*) (SvRV(*GenItem_Ptr));
	return GenItem;
}

_perl_gendata *perl_save_gen_cb(pTHX_ UV objaddr, UV itcaddr, int id) {
	_perl_gendata *cb;
	
	New(0,cb,1,_perl_gendata);

	if (objaddr) {
		cb->objaddr = objaddr ;
	}
	else {
		croak("No Gen item class passed\n");
	}

	if (itcaddr) {
		cb->itcaddr = itcaddr ;
	}
	else {
		cb->itcaddr = 0;
	}

	if (id>=0) {
		cb->item_id = id;
	}
	else {
		croak("No Item id passed \n");
	}


	// We have to save a pointer to the c struct in the perl hash, too
	// This is necessary for deletion
	//if (event != NULL) {
	HV *perl_cb = _get_gen_item_hash(aTHX_ cb->objaddr, id);
	hv_store(perl_cb, "cstructaddr",11,newSVuv(PTR2UV(cb)),0);
	// }

	return cb;
}

int *perl_save_gen_item_data(pTHX_ Elm_Genlist *obj) {
}

HV* _get_gen_hash(pTHX_ UV objaddr, char *hashName) {
	HV* cbs;
	int len, n;
	char *keybuffer = _get_keybuffer(NULL,objaddr, &len);
	
	HV *GenItc_Cbs = get_hv(hashName, 0);
	if (GenItc_Cbs == NULL) {
		croak("pEFL::PLSide::GenItc hash does not exist\n");
	}
	
	n = snprintf(keybuffer, len, "%" UVuf, objaddr);
	if (hv_exists(GenItc_Cbs,keybuffer,strlen(keybuffer))) {
		SV** CbsPtr = hv_fetch(GenItc_Cbs, keybuffer,strlen(keybuffer),FALSE);
		cbs = (HV*) (SvRV(*CbsPtr));
	}
	else {
		croak("Error in _get_gen_hash: No callbacks found\n");
	}

	free(keybuffer);

	return cbs;
}

char* call_perl_gen_text_get(void *data, Evas_Object *obj, const char *part) {
	dTHX;
	dSP;

	int count; STRLEN len;
	SV *s_part;
	SV *s_string;
	char* buf;

	_perl_gendata *perl_saved_cb = data;

	HV *cb_data = _get_gen_hash(aTHX_ perl_saved_cb->itcaddr,"pEFL::PLSide::GenItc");
	SV *func = *( hv_fetch(cb_data, "text_get",8,FALSE) );

	HV *GenItem = _get_gen_item_hash(aTHX_ perl_saved_cb->objaddr, perl_saved_cb->item_id);

	// Get data
	SV* s_data = *( hv_fetch(GenItem, "data",4,FALSE) );

	// Object
	SV *s_obj = newSV(0);
	sv_setref_pv(s_obj, "ElmGenlistPtr", obj);

	// part
	s_part = newSVpvn(part,strlen(part));

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);

	XPUSHs(s_data);
	XPUSHs(sv_2mortal(s_obj));
	XPUSHs(sv_2mortal(s_part));

	PUTBACK;

	count = call_sv(func, G_SCALAR);

	SPAGAIN;

	if (count != 1) {
		croak("Expected 1 value got %d\n", count);
	}

	s_string = POPs;
	len = sv_len(s_string);

	buf = strdup(SvPV(s_string,len));

	PUTBACK;
	FREETMPS;
	LEAVE;

	return buf;
}

Eina_Bool call_perl_gen_state_get(void *data, Evas_Object *obj, const char *part) {
	dTHX;
	dSP;

	int count; STRLEN len;
	SV *s_part;
	SV *s_bool; Eina_Bool e_bool;
	char* buf;

	_perl_gendata *perl_saved_cb = data;

	HV *cb_data = _get_gen_hash(aTHX_ perl_saved_cb->itcaddr,"pEFL::PLSide::GenItc");
	SV *func = *( hv_fetch(cb_data, "state_get",8,FALSE) );

	HV *GenItem = _get_gen_item_hash(aTHX_ perl_saved_cb->objaddr, perl_saved_cb->item_id);

	// Get data
	SV* s_data = *( hv_fetch(GenItem, "data",4,FALSE) );

	// Object
	SV *s_obj = newSV(0);
	sv_setref_pv(s_obj, "ElmGenlistPtr", obj);

	// part
	s_part = newSVpvn(part,strlen(part));

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);

	XPUSHs(s_data);
	XPUSHs(sv_2mortal(s_obj));
	XPUSHs(sv_2mortal(s_part));

	PUTBACK;

	count = call_sv(func, G_SCALAR);

	SPAGAIN;

	if (count != 1) {
		croak("Expected 1 value got %d\n", count);
	}

	s_bool = POPs;
	if (SvTRUE(s_bool) ) {
		e_bool = EINA_TRUE;
	}
	else {
		e_bool = EINA_FALSE;
	}

	PUTBACK;
	FREETMPS;
	LEAVE;

	return e_bool;
}

Evas_Object* call_perl_gen_content_get(void *data, Evas_Object *obj, const char *part) {
	dTHX;
	dSP;

	int count;
	SV *s_part;
	SV *s_content; Evas_Object *ret_obj;
	char* buf;
	
	_perl_gendata *perl_saved_cb = data;

	HV *cb_data = _get_gen_hash(aTHX_ perl_saved_cb->itcaddr,"pEFL::PLSide::GenItc");
	SV *func = *( hv_fetch(cb_data, "content_get",11,FALSE) );

	HV *GenItem = _get_gen_item_hash(aTHX_ perl_saved_cb->objaddr, perl_saved_cb->item_id);
	
	// Get data
	SV* s_data = *( hv_fetch(GenItem, "data",4,FALSE) );

	// Object
	SV *s_obj = newSV(0);
	sv_setref_pv(s_obj, "ElmGenlistPtr", obj);

	// part
	s_part = newSVpvn(part,strlen(part));

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);

	XPUSHs(s_data);
	XPUSHs(sv_2mortal(s_obj));
	XPUSHs(sv_2mortal(s_part));

	PUTBACK;

	count = call_sv(func, G_SCALAR);

	SPAGAIN;

	if (count != 1) {
		croak("Expected 1 value got %d\n", count);
	}

	s_content = POPs;

	if (!SvROK(s_content)) {
			ret_obj = NULL;
		}
	else {
		IV tmp = SvIV((SV*)SvRV(s_content));
		ret_obj = INT2PTR(Evas_Object*,tmp);
		// sv_setref_pv(s_obj, "EvasObjectPtr", obj);
	}

	PUTBACK;
	FREETMPS;
	LEAVE;

	return ret_obj;
}

void call_perl_genitc_del(void *data, Evas_Object *obj) {
	call_perl_gen_del(data,obj, NULL);
}

void call_perl_gen_del(void *data, Evas_Object *obj, void *event_info) {
	dTHX;
	dSP;
	
	_perl_gendata *perl_saved_cb = data;
		
	int id = perl_saved_cb->item_id;
	
	if (SvTRUE(get_sv("pEFL::Debug",0)))
		fprintf(stderr,"Calling call_perl_gen_del() on item %d of Genlist with address %"UVuf"\n", id, perl_saved_cb->objaddr);
	
	HV *cb_data = NULL;
	UV itcaddr = perl_saved_cb->itcaddr;
	if (perl_saved_cb->itcaddr != 0) {
		cb_data = _get_gen_hash(aTHX_ perl_saved_cb->itcaddr,"pEFL::PLSide::GenItc");
	}

	HV *GenItem = _get_gen_item_hash(aTHX_ perl_saved_cb->objaddr, perl_saved_cb->item_id);

	if (cb_data && hv_exists(cb_data,"del",3)) {
		int count;

		SV *func = *( hv_fetch(cb_data, "del",3,FALSE) );
		// Get data
		SV* s_data = *( hv_fetch(GenItem, "data",4,FALSE) );

		// Object
		SV *s_obj = newSV(0);
		sv_setref_pv(s_obj, "ElmGenlistPtr", obj);

		ENTER;
		SAVETMPS;

		PUSHMARK(SP);

		XPUSHs(s_data);
		XPUSHs(sv_2mortal(s_obj));

		PUTBACK;

		count = call_sv(func, G_DISCARD);

		if (count != 0) {
			croak("Expected 0 value got %d\n", count);
		}

		FREETMPS;
		LEAVE;
	}
	// TODO: Check whether hash value exists
	if (SvTRUE(get_sv("pEFL::Debug",0)))
		fprintf(stderr,"Deleting pEFL::PLSide::GenItems hash entry \n");
		
	hv_undef(GenItem);
	
	if (SvTRUE(get_sv("pEFL::Debug",0)))
		fprintf(stderr,"Freeing cstruct \n\n");
		
	Safefree(data);
}

Eina_Bool call_perl_item_pop_cb(void*data,Elm_Naviframe_Item *it) {
	dTHX;
	dSP;
	
	int count; STRLEN len;
	SV *s_bool; Eina_Bool e_bool;
	
	_perl_gendata *perl_saved_cb = data;
	
	HV *GenItem = _get_gen_item_hash(aTHX_ perl_saved_cb->objaddr, perl_saved_cb->item_id);

	// Object
	SV *s_obj = newSV(0);
	sv_setref_pv(s_obj, "ElmNaviframeItemPtr", it);

	// Get func
	SV* func = *( hv_fetch(GenItem, "func",4,FALSE) );
	
		// Get func_data
		SV *func_data = *( hv_fetch(GenItem, "func_data",9,FALSE) );

		ENTER;
		SAVETMPS;

		PUSHMARK(SP);

		XPUSHs(func_data);
		XPUSHs(sv_2mortal(s_obj));

		PUTBACK;

		count = call_sv(func, G_SCALAR);

		SPAGAIN;

		if (count != 1) {
			croak("Expected 1 value got %d\n", count);
		}

		s_bool = POPs;
		if (SvTRUE(s_bool) ) {
			e_bool = EINA_TRUE;
		}
		else {
			e_bool = EINA_FALSE;
		}

		PUTBACK;
		FREETMPS;
		LEAVE;	  

	return e_bool;

}

void call_perl_gen_item_selected(void *data, Evas_Object *obj, void *event_info) {
	dTHX;
	dSP;
	
	int count; STRLEN len;

	_perl_gendata *perl_saved_cb = data;

	HV *GenItem = _get_gen_item_hash(aTHX_ perl_saved_cb->objaddr, perl_saved_cb->item_id);

	// Object
	SV *s_obj = newSV(0);
	SV *pclass = *( hv_fetch(GenItem, "pclass",6,FALSE) );
	sv_setref_pv(s_obj, SvPV_nolen(pclass), obj);

	// Get func
	SV* func = *( hv_fetch(GenItem, "func",4,FALSE) );

	// Execute callback only if a callback is saved :-)
	if (func && SvOK(func)) {
		// Get func_data
		SV *func_data = *( hv_fetch(GenItem, "func_data",9,FALSE) );

		// event info
		// TODO: Make an own function? This is also needed by call_perl_sub
		SV *s_ei  = newSV(0);
		if (event_info) {
			if (SvTRUE(get_sv("pEFL::Debug",0)))
				fprintf(stderr, "event has an event info\n");
			IV adress;
			adress = PTR2IV(event_info);
			sv_setiv(s_ei,adress);
		}

		ENTER;
		SAVETMPS;

		PUSHMARK(SP);

		XPUSHs(func_data);
		XPUSHs(sv_2mortal(s_obj));
		XPUSHs(sv_2mortal(s_ei));

		PUTBACK;

		count = call_sv(func, G_DISCARD);
		if (count != 0) {
			croak("Expected 0 value got %d\n", count);
		}

		FREETMPS;
		LEAVE;
	}

}

//
// Edje Signals
//

// Same as _get_gen_items()
// perhaps make one function??
AV* _get_signals(pTHX_ UV objaddr, int items) {
	AV* cbs;
	int len, n;
	char *keybuffer;
	if ( items == 0 ) {
		keybuffer = _get_keybuffer(NULL,objaddr, &len);
		n = snprintf(keybuffer, len, "%"UVuf, objaddr);
	}
	else if (items == 1) {
		keybuffer = _get_keybuffer("###items",objaddr, &len);
		n = snprintf(keybuffer, len, "%"UVuf"###items", objaddr);
	} 

	HV *Signals_Cbs = get_hv("pEFL::PLSide::EdjeSignals", 0);
	if (Signals_Cbs == NULL) {
		croak("pEFL::PLSide::EdjeSignals hash does not exist\n");
	}

	
	if (hv_exists(Signals_Cbs,keybuffer,strlen(keybuffer))) {
		SV** CbsPtr = hv_fetch(Signals_Cbs, keybuffer,strlen(keybuffer),FALSE);
		cbs = (AV*) (SvRV(*CbsPtr));
	}
	else {
		croak("No signals found\n");
	}

	free(keybuffer);

	return cbs;
}

HV* _get_signal_hash(pTHX_ UV objaddr, int item_id) {
	AV *Items = _get_signals(aTHX_ objaddr, 0);

	SV** Item_Ptr = av_fetch(Items, (I32) item_id,FALSE);
	HV *Item = (HV*) (SvRV(*Item_Ptr));
	return Item;
}

HV* _get_item_signal_hash(pTHX_ UV objaddr, int item_id) {
	AV *Items = _get_signals(aTHX_ objaddr, 1);

	SV** Item_Ptr = av_fetch(Items, (I32) item_id,FALSE);
	HV *Item = (HV*) (SvRV(*Item_Ptr));
	return Item;
}

_perl_signal_cb* perl_save_signal(pTHX_ UV objaddr, int id) {
	_perl_signal_cb *cb;

	New(0,cb,1,_perl_signal_cb);

	if (objaddr) {
		cb->objaddr = objaddr ;
	}
	else {
		croak("Saving Signal Callback failed: No object address passed\n");
	}

	if (id>=0) {
		cb->signal_id = id;
	}
	else {
		croak("Saving Signal Callback failed: No Id passed \n");
	}

	return cb;
}

_perl_signal_cb* perl_save_signal_cb(pTHX_ UV objaddr, int id) {
	_perl_signal_cb *cb;

	cb = perl_save_signal(aTHX_ objaddr,id);

	// For Smart Callbacks and Evas Callbacks we have to save
	// a pointer to the c struct in the perl hash, too
	// This is necessary for deletion
	HV *cb_data = _get_signal_hash(aTHX_ cb->objaddr, cb->signal_id);
	hv_store(cb_data, "cstructaddr",11,newSVuv(PTR2UV(cb)),0);

	return cb;
}

_perl_signal_cb* perl_save_item_signal_cb(pTHX_ UV objaddr, int id) {
	_perl_signal_cb *cb;

	cb = perl_save_signal(aTHX_ objaddr,id);

	// For Smart Callbacks and Evas Callbacks we have to save
	// a pointer to the c struct in the perl hash, too
	// This is necessary for deletion
	HV *cb_data = _get_item_signal_hash(aTHX_ cb->objaddr, cb->signal_id);
	hv_store(cb_data, "cstructaddr",11,newSVuv(PTR2UV(cb)),0);

	return cb;
}

void call_perl_signal_cb(void *data, Evas_Object *layout, const char *emission, const char *source) {
	dTHX;
	dSP;

	int n; int count;

	_perl_signal_cb *perl_saved_cb = data;
	HV *cb_data = _get_signal_hash(aTHX_ perl_saved_cb->objaddr, perl_saved_cb->signal_id);

	SV *func = *( hv_fetch(cb_data, "function",8,FALSE) );
	SV *args = *( hv_fetch(cb_data, "data",4,FALSE) ) ;
	SV *s_obj = newSV(0);
	SV *pclass = *( hv_fetch(cb_data, "pclass",6,FALSE) );
	sv_setref_pv(s_obj, SvPV_nolen(pclass), layout);
	SV *s_emission = newSVpvn(emission,strlen(emission));
	SV *s_source = newSVpvn(source,strlen(source));

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);

	XPUSHs( args );
	XPUSHs(sv_2mortal(s_obj) );
	XPUSHs(sv_2mortal(s_emission) );
	XPUSHs(sv_2mortal(s_source));

	PUTBACK;

	count = call_sv(func, G_DISCARD);
	if (count != 0) {
		croak("Expected 0 value got %d\n", count);
	}

	FREETMPS;
	LEAVE;
}

void call_perl_item_signal_cb(void *data, Elm_Object_Item *layout, const char *emission, const char *source) {
	dTHX;
	dSP;

	int n; int count;

	_perl_signal_cb *perl_saved_cb = data;
	HV *cb_data = _get_item_signal_hash(aTHX_ perl_saved_cb->objaddr, perl_saved_cb->signal_id);

	SV *func = *( hv_fetch(cb_data, "function",8,FALSE) );
	SV *args = *( hv_fetch(cb_data, "data",4,FALSE) ) ;
	SV *s_obj = newSV(0);
	sv_setref_pv(s_obj, "ElmObjectItemPtr", layout);
	SV *s_emission = newSVpvn(emission,strlen(emission));
	SV *s_source = newSVpvn(source,strlen(source));

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);

	XPUSHs( args );
	XPUSHs(sv_2mortal(s_obj) );
	XPUSHs(sv_2mortal(s_emission) );
	XPUSHs(sv_2mortal(s_source));

	PUTBACK;

	count = call_sv(func, G_DISCARD);
	if (count != 0) {
		croak("Expected 0 value got %d\n", count);
	}

	FREETMPS;
	LEAVE;
}

// --------------------------------------
// Ecore Evas Event
// -------------------------------------

HV* _get_ecore_evas_event_cb_hash(pTHX_ UV objaddr) {
	HV* cb_data;
	int len, n;
	char *keybuffer = _get_keybuffer(NULL,objaddr, &len);

	HV *Callbacks = get_hv("pEFL::PLSide::EcoreEvasEvent_Cbs", 0);
	if (Callbacks == NULL) {
		croak("pEFL::PLSide::EcoreEvasEvent_Cbs hash does not exist\n");
	}

	n = snprintf(keybuffer, len, "%" UVuf, objaddr);
	if (hv_exists(Callbacks,keybuffer,strlen(keybuffer))) {
		SV** Cb_DataPtr = hv_fetch(Callbacks, keybuffer,strlen(keybuffer),FALSE);
		cb_data = (HV*) (SvRV(*Cb_DataPtr));
	}
	else {
		croak("Error in _get_ecore_evas_event_ch_hash: No callbacks found\n");
	}

	free(keybuffer);

	return cb_data;
}

void call_perl_ecore_evas_event(pTHX_ Ecore_Evas *ee,char *event) {
	dSP;
	int n, count;
	UV eeaddr = PTR2IV(ee);
	HV *functions = _get_ecore_evas_event_cb_hash(aTHX_ eeaddr);

	// Object
	SV *s_obj = newSV(0);
	sv_setref_pv(s_obj,"EcoreEvasPtr",ee);

	//Get func
	SV *func = *( hv_fetch(functions,event,strlen(event), FALSE) );

	if (func && SvOK(func)) {
		ENTER;
		SAVETMPS;

		PUSHMARK(SP);

		XPUSHs(sv_2mortal(s_obj));

		PUTBACK;

		count = call_sv(func, G_DISCARD);
		if (count != 0) {
			croak("Expected 0 value got %d\n", count);
		}

		FREETMPS;
		LEAVE;
	}
}

void call_perl_ecore_evas_resize(Ecore_Evas *ee) {
	dTHX;
	char *event = "resize";
	call_perl_ecore_evas_event(aTHX_ ee,event);
}

void call_perl_ecore_evas_move(Ecore_Evas *ee) {
	dTHX;
	char *event = "move";
	call_perl_ecore_evas_event(aTHX_ ee,event);
}

void call_perl_ecore_evas_show(Ecore_Evas *ee) {
	dTHX;
	char *event = "show";
	call_perl_ecore_evas_event(aTHX_ ee,event);
}

void call_perl_ecore_evas_hide(Ecore_Evas *ee) {
	dTHX;
	char *event = "hide";
	call_perl_ecore_evas_event(aTHX_ ee,event);
}

void call_perl_ecore_evas_delete_request(Ecore_Evas *ee) {
	dTHX;
	char *event = "delete_request";
	call_perl_ecore_evas_event(aTHX_ ee,event);
}

void call_perl_ecore_evas_destroy(Ecore_Evas *ee) {
	dTHX;
	char *event = "destroy";
	call_perl_ecore_evas_event(aTHX_ ee,event);
}

void call_perl_ecore_evas_focus_in(Ecore_Evas *ee) {
	dTHX;
	char *event = "focus_in";
	call_perl_ecore_evas_event(aTHX_ ee,event);
}

void call_perl_ecore_evas_focus_out(Ecore_Evas *ee) {
	dTHX;
	char *event = "focus_out";
	call_perl_ecore_evas_event(aTHX_ ee,event);
}

void call_perl_ecore_evas_sticky(Ecore_Evas *ee) {
	dTHX;
	char *event = "sticky";
	call_perl_ecore_evas_event(aTHX_ ee,event);
}

void call_perl_ecore_evas_unsticky(Ecore_Evas *ee) {
	dTHX;
	char *event = "unsticky";
	call_perl_ecore_evas_event(aTHX_ ee,event);
}

void call_perl_ecore_evas_mouse_in(Ecore_Evas *ee) {
	dTHX;
	char *event = "mouse_in";
	call_perl_ecore_evas_event(aTHX_ ee,event);
}

void call_perl_ecore_evas_mouse_out(Ecore_Evas *ee) {
	dTHX;
	char *event = "mouse_out";
	call_perl_ecore_evas_event(aTHX_ ee,event);
}

void call_perl_ecore_evas_pre_render(Ecore_Evas *ee) {
	dTHX;
	char *event = "pre_render";
	call_perl_ecore_evas_event(aTHX_ ee,event);
}

void call_perl_ecore_evas_post_render(Ecore_Evas *ee) {
	dTHX;
	char *event = "post_render";
	call_perl_ecore_evas_event(aTHX_ ee,event);
}

void call_perl_ecore_evas_pre_free(Ecore_Evas *ee) {
	dTHX;
	char *event = "pre_free";
	call_perl_ecore_evas_event(aTHX_ ee,event);
}

void call_perl_ecore_evas_state_change(Ecore_Evas *ee) {
	dTHX;
	char *event = "state_change";
	call_perl_ecore_evas_event(aTHX_ ee,event);
}

// --------------------------------------
// Ecore Event Handler
// --------------------------------------

HV* _get_event_handler_hash(pTHX_ int item_id) {
	AV *Task_Cbs = get_av("pEFL::PLSide::EcoreEventHandler_Cbs", 0);
	if (Task_Cbs == NULL) {
		croak("pEFL::PLSide::EcoreEventHandler_Cbs array does not exist\n");
	}

	SV** Task_Ptr = av_fetch(Task_Cbs, (I32) item_id,FALSE);
	HV *Task = (HV*) (SvRV(*Task_Ptr));
	return Task;
}

Eina_Bool call_perl_ecore_event_handler_cb(void *data, int type, void *event) {
	dTHX;
	dSP;
	int n, count;
	SV *s_bool; Eina_Bool e_bool;

	int item_id = (intptr_t) data;
	HV *Task = _get_event_handler_hash(aTHX_ item_id);

	// Object
	SV *s_data = *( hv_fetch(Task,"data",4, FALSE) );

	// Type
	// TODO: Not needed to save in the EventHandler Hash
	// instead create a new SvIV?
	SV *s_type = *( hv_fetch(Task,"type",4, FALSE) );

	// eventinfo
	SV *s_event  = newSV(0);
	if (event) {
		if (SvTRUE(get_sv("pEFL::Debug",0)))
			fprintf(stderr, "event has an event info\n");
		IV adress;
		adress = PTR2IV(event);
		sv_setiv(s_event,adress);
	}

	//Get func
	SV *func = *( hv_fetch(Task,"function",8, FALSE) );

	if (func && SvOK(func)) {
		ENTER;
		SAVETMPS;

		PUSHMARK(SP);

		XPUSHs(s_data);
		XPUSHs(s_type);
		XPUSHs(s_event);

		PUTBACK;

		count = call_sv(func, G_SCALAR);

		SPAGAIN;

		if (count != 1) {
			croak("Expected 1 value got %d\n", count);
		}

		s_bool = POPs;

		if (SvTRUE(s_bool) ) {
		e_bool = EINA_TRUE;
	}
	else {
		e_bool = EINA_FALSE;
	}

	PUTBACK;
	FREETMPS;
	LEAVE;

	return e_bool;
	}
}

// --------------------------------------
// Ecore Task Cbs
// -------------------------------------

HV* _get_task_hash(pTHX_ int item_id) {
	AV *Task_Cbs = get_av("pEFL::PLSide::EcoreTask_Cbs", 0);
	if (Task_Cbs == NULL) {
		croak("pEFL::PLSide::EcoreTask_Cbs array does not exist\n");
	}

	SV** Task_Ptr = av_fetch(Task_Cbs, (I32) item_id,FALSE);
	HV *Task = (HV*) (SvRV(*Task_Ptr));
	return Task;
}

Eina_Bool call_perl_task_cb(void *data) {
	dTHX;
	dSP;
	int n, count;
	SV *s_bool; Eina_Bool e_bool;

	int item_id = (intptr_t) data;
	HV *Task = _get_task_hash(aTHX_ item_id);

	// Object
	SV *s_data = *( hv_fetch(Task,"data",4, FALSE) );

	//Get func
	SV *func = *( hv_fetch(Task,"function",8, FALSE) );

	if (func && SvOK(func)) {
		ENTER;
		SAVETMPS;

		PUSHMARK(SP);

		XPUSHs(s_data);

		PUTBACK;

		count = call_sv(func, G_SCALAR);

		SPAGAIN;

		if (count != 1) {
			croak("Expected 1 value got %d\n", count);
		}

		s_bool = POPs;

		if (SvTRUE(s_bool) ) {
		e_bool = EINA_TRUE;
	}
	else {
		e_bool = EINA_FALSE;
	}

	PUTBACK;
	FREETMPS;
	LEAVE;

	return e_bool;
	}
}
