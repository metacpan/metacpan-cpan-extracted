/* X11::GUITest ($Id: Common.h 231 2014-01-11 14:26:57Z ctrondlp $)
 *
 * Copyright (c) 2003-2014  Dennis K. Paulsen, All Rights Reserved.
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

#define APP_VERSION "0.28"
#define APP_TEXTDOMAIN "/usr/share/locale"

#ifndef _
#define _(str) gettext(str)
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
