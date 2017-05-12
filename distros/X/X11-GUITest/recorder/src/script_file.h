/* X11::GUITest ($Id: script_file.h 231 2014-01-11 14:26:57Z ctrondlp $)
 *  
 * Copyright (c) 2003-2014 Dennis K. Paulsen, All Rights Reserved.
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
#ifndef SCRIPT_FILE_H
#define SCRIPT_FILE_H


#define MAX_SCRIPT_BUFFER 2048

BOOL OpenScript(char *scriptFile);
void WriteScript(char *format, ...);
void CloseScript(void);


#endif /* #ifndef SCRIPT_FILE_H */

