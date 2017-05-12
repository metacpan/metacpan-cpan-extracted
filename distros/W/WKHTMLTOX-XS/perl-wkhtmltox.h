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

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#undef do_open
#undef do_close

#include <stdbool.h>
#include <stdio.h>
#include <wkhtmltox/pdf.h>
#include <wkhtmltox/image.h>

void generate_pdf (SV * global_options, SV * options);
void generate_image (SV * global_options);
