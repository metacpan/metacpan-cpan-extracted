/* X11::GUITest ($Id: script_file.c 231 2014-01-11 14:26:57Z ctrondlp $)
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
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <libintl.h>
#include <sys/time.h>
#include "Common.h"
#include "script_file.h"


static FILE *sfp = NULL; // script output

BOOL OpenScript(char *scriptFile)
{ 
	sfp = fopen(scriptFile, "wt");
	if (sfp == NULL) {
		fprintf(stderr, _("Unable to open script file '%s'!\n"), scriptFile);	
		return FALSE;	
	}
	return TRUE;
}

void WriteScript(char *format, ...)
{
	if (sfp == NULL) {
		fprintf(stderr, _("Unable to write to script file!\n"));	
		return;
	} 

	char buffer[MAX_SCRIPT_BUFFER] = "\0";
	va_list args;
	va_start(args, format);
	vsprintf(buffer, format, args);
	fwrite(buffer, sizeof(char), strlen(buffer), sfp);
	va_end(args);
}

void CloseScript(void)
{
	if (sfp != NULL) {
		fflush(sfp);
		fclose(sfp);
	}
}

