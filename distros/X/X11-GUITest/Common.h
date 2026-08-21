/* X11::GUITest ($Id: Common.h 249 2026-08-15 18:43:40Z ctrondlp $)
 *
 * Copyright (c) 2003-2026  Dennis K. Paulsen, All Rights Reserved.
 * Email: ctrondlp@cpan.org
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, see <http://www.gnu.org/licenses>.
 *
 */
#ifndef COMMON_H
#define COMMON_H

/* Pulls in autoconf's generated defines (HAVE_GETTEXT below, etc.) for the
 * recorder's autotools build; automake supplies -DHAVE_CONFIG_H
 * automatically once configure.ac uses AC_CONFIG_HEADERS. This header is
 * also shared with the plain Perl module build (Makefile.PL, no
 * autoconf), where HAVE_CONFIG_H is never defined, so this is a no-op
 * there. */
#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#define APP_VERSION "0.29"

/* LOCALEDIR is supplied at compile time (see recorder/src/Makefile.am),
 * derived from --prefix/--datadir, so installs outside of /usr (common on
 * BSD, HP-UX, AIX, Solaris) still find their catalogs.  Fall back to the
 * historical default for any build that doesn't define it. */
#ifndef APP_TEXTDOMAIN
#ifdef LOCALEDIR
#define APP_TEXTDOMAIN LOCALEDIR
#else
#define APP_TEXTDOMAIN "/usr/share/locale"
#endif
#endif

/* GNU gettext isn't native on AIX/HP-UX (they use catgets-based i18n
 * instead of libintl.h), and no .po/.mo catalogs are shipped in this
 * project anyway, so translation support is optional: fall back to
 * returning the string unchanged when a usable gettext wasn't found by
 * configure (see recorder/configure.ac). */
#ifdef HAVE_GETTEXT
#include <libintl.h>
#ifndef _
#define _(str) gettext(str)
#endif
#else
#ifndef _
#define _(str) (str)
#endif
#endif

#ifndef TRUE
#define TRUE (1)
#endif
#ifndef FALSE
#define FALSE (0)
#endif

#ifndef BOOL
#define BOOL int
#endif
#ifndef UINT
#define UINT unsigned int
#endif
#ifndef ULONG
#define ULONG unsigned long
#endif
#ifndef NUL
#define NUL '\0'
#endif
#ifndef MAX_PATH
#define MAX_PATH 255
#endif

#endif /* #ifndef COMMON_H */
