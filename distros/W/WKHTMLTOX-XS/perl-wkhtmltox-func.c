/*
 * Copyright 2014 Kurt Wagner
 *
 * perl-wkhtmltox is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * perl-wkhtmltox is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with wkhtmltopdf.  If not, see <http: *www.gnu.org/licenses/>.
 */

#include "perl-wkhtmltox.h"

void _pdf_error(wkhtmltopdf_converter * c, const char * msg) { croak(msg); }
void _pdf_warning(wkhtmltopdf_converter * c, const char * msg) { warn(msg); }
void _image_error(wkhtmltoimage_converter * c, const char * msg) { croak(msg); }
void _image_warning(wkhtmltoimage_converter * c, const char * msg) { warn(msg); }

void generate_pdf (SV * global_options, SV * options)
{
	HV * global_options_hv;
	HV * options_hv;
	HE * item;
	
	wkhtmltopdf_global_settings * gs;
	wkhtmltopdf_object_settings * os;
	wkhtmltopdf_converter * c;

	if (!SvROK(global_options)) {
		croak("First argument: global_options must be a reference");
	}
	if (!SvROK(options)) {
		croak("Second argument: global_options must be a reference");
	}
	if (SvTYPE(SvRV(global_options)) != SVt_PVHV) {
		croak("First argument: global_options must be a hash reference");
	}
	if (SvTYPE(SvRV(options)) != SVt_PVHV) {
		croak("Second argument: options must be a hash reference");
	}

	global_options_hv = (HV *)SvRV(global_options);
	options_hv = (HV *)SvRV(options);

	wkhtmltopdf_init(false);
	
	gs = wkhtmltopdf_create_global_settings();
	item = hv_iternext(global_options_hv);
	while (item) {
		const char *value = SvPV_nolen(HeVAL(item));
		const char *key = HeKEY(item);
		wkhtmltopdf_set_global_setting(gs, key, value);
		item = hv_iternext(global_options_hv);
	}
	
	os = wkhtmltopdf_create_object_settings();
	item = hv_iternext(options_hv);
	while (item) {
		const char *value = SvPV_nolen(HeVAL(item));
		const char *key = HeKEY(item);
		wkhtmltopdf_set_object_setting(os, key, value);
		item = hv_iternext(options_hv);
	}

	c = wkhtmltopdf_create_converter(gs);
	wkhtmltopdf_set_error_callback(c, _pdf_error);
	wkhtmltopdf_set_warning_callback(c, _pdf_warning);
	wkhtmltopdf_add_object(c, os, NULL);

	if (!wkhtmltopdf_convert(c)) {
		croak("Conversion failed");
	}

	wkhtmltopdf_destroy_converter(c);
	wkhtmltopdf_deinit();
}

void generate_image (SV * global_options)
{
	HV * global_options_hv;
	HE * item;
	
	wkhtmltoimage_global_settings * gs;
	wkhtmltoimage_converter * c;

	if (!SvROK(global_options)) {
		croak("First argument: global_options must be a reference");
	}
	if (SvTYPE(SvRV(global_options)) != SVt_PVHV) {
		croak("First argument: global_options must be a hash reference");
	}

	global_options_hv = (HV *)SvRV(global_options);

	wkhtmltoimage_init(false);

	gs = wkhtmltoimage_create_global_settings();
	item = hv_iternext(global_options_hv);
	while (item) {
		const char *value = SvPV_nolen(HeVAL(item));
		const char *key = HeKEY(item);
		wkhtmltoimage_set_global_setting(gs, key, value);
		item = hv_iternext(global_options_hv);
	}

	c = wkhtmltoimage_create_converter(gs, NULL);
	wkhtmltoimage_set_error_callback(c, _image_error);
	wkhtmltoimage_set_warning_callback(c, _image_warning);

	if (!wkhtmltoimage_convert(c)) {
		croak("Conversion failed");
	}

	wkhtmltoimage_destroy_converter(c);
	wkhtmltoimage_deinit();
}



