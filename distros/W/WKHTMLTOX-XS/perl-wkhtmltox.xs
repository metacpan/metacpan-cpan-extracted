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
 
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <perl-wkhtmltox.h>

MODULE = WKHTMLTOX::XS		PACKAGE = WKHTMLTOX::XS

PROTOTYPES: ENABLE

void
generate_pdf (global_options, options)
    	SV * global_options
	SV * options
	OUTPUT:
	
void
generate_image (global_options)
    	SV * global_options
	OUTPUT:
