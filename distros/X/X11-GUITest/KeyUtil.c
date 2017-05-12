/* X11::GUITest ($Id: KeyUtil.c 231 2014-01-11 14:26:57Z ctrondlp $)
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
#ifdef __cplusplus
extern "C" {
#endif
#ifndef NOPERL
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#else
#include <assert.h>
#endif
#ifdef __cplusplus
}
#endif

#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/Intrinsic.h>
#include <X11/StringDefs.h>
#include <X11/keysym.h>
#include <X11/extensions/XTest.h>
#include "KeyUtil.h"

static const KeyNameSymTable kns_table[] = { /* {Name, Sym}, */
	{"BAC", XK_BackSpace},		{"BS", XK_BackSpace},		{"BKS", XK_BackSpace},
 	{"BRE", XK_Break},		{"CAN", XK_Cancel}, 		{"CAP", XK_Caps_Lock},
	{"DEL", XK_Delete},		{"DOWN", XK_Down},		{"END", XK_End},
	{"ENT", XK_Return},		{"ESC", XK_Escape},		{"HEL", XK_Help},
	{"HOM", XK_Home},		{"INS", XK_Insert},		{"LEF", XK_Left},
	{"NUM", XK_Num_Lock},		{"PGD", XK_Next},		{"PGU", XK_Prior},
	{"PRT", XK_Print},		{"RIG", XK_Right},		{"SCR", XK_Scroll_Lock},
	{"TAB", XK_Tab},		{"UP", XK_Up},			{"F1", XK_F1},
	{"F2", XK_F2},			{"F3", XK_F3},			{"F4", XK_F4},
	{"F5", XK_F5},			{"F6", XK_F6},			{"F7", XK_F7},
	{"F8", XK_F8},			{"F9", XK_F9},			{"F10", XK_F10},
	{"F11", XK_F11},		{"F12", XK_F12},		{"SPC", XK_space},
	{"SPA", XK_space},		{"LSK", XK_Super_L}, 		{"RSK", XK_Super_R},
	{"MNU", XK_Menu},		{"~", XK_asciitilde},		{"_", XK_underscore},
	{"[", XK_bracketleft},		{"]", XK_bracketright},		{"!", XK_exclam},
	{"\"", XK_quotedbl}, 		{"#", XK_numbersign},		{"$", XK_dollar},
	{"%", XK_percent},		{"&", XK_ampersand}, 		{"'", XK_quoteright},
	{"*", XK_asterisk},		{"+", XK_plus},			{",", XK_comma},
	{"-", XK_minus},		{".", XK_period}, 		{"?", XK_question},
	{"<", XK_less},			{">", XK_greater},		{"=", XK_equal},
	{"@", XK_at},			{":", XK_colon},		{";", XK_semicolon},
	{"\\", XK_backslash}, 		{"`", XK_grave},		{"{", XK_braceleft},
	{"}", XK_braceright},		{"|", XK_bar},			{"^", XK_asciicircum},
	{"(", XK_parenleft},		{")", XK_parenright}, 		{" ", XK_space},
	{"/", XK_slash},		{"\t", XK_Tab},			{"\n", XK_Return},
	{"LSH", XK_Shift_L},		{"RSH", XK_Shift_R},		{"LCT", XK_Control_L},
	{"RCT", XK_Control_R},		{"LAL", XK_Alt_L},		{"RAL", XK_Alt_R},
        {"LMA", XK_Meta_L},		{"RMA", XK_Meta_R},
};
static const KeyNameSymTable kns_modcode_table[] = { /* {ModCodeName, Sym}, */
	{"^", XK_Control_L},		{"%", XK_Alt_L},		{"+", XK_Shift_L},
	{"#", XK_Meta_L},		{"^", XK_Control_R},		{"&",XK_ISO_Level3_Shift},
	{"+", XK_Shift_R},
};


BOOL GetKeySym(const char *name, KeySym *sym)
{
	size_t x = 0;

	assert(name != NULL);
	assert(sym != NULL);

	/* See if we can obtain the KeySym without looking at table.
	 * Note: XStringToKeysym("space") would return KeySym
	 * XK_space... Case sensitive. */
	*sym = XStringToKeysym(name);
	if (*sym != NoSymbol) {
		/* Got It */
		return(TRUE);
	}
	/* Do case insensitive search for specified name to obtain the KeySym from table */
	for (x = 0; x < (sizeof(kns_table) / sizeof(KeyNameSymTable)); x++) {
		if (strcasecmp(kns_table[x].Name, name) == 0) {
			/* Found It */
			*sym = kns_table[x].Sym;
			return(TRUE);
		}
	}
	/* Not Found */
	*sym = NoSymbol;
	return(FALSE);
}

const char *GetKeyName(KeySym sym)
{
	size_t x = 0;

	/* Look for KeySym in order to obtain name */
	for (x = 0; x < (sizeof(kns_table) / sizeof(KeyNameSymTable)); x++) {
		if (sym == kns_table[x].Sym) {
			/* Found It */
			return kns_table[x].Name;
		}
	}

	return XKeysymToString(sym);
}

const char *GetModifierCode(KeySym sym)
{
	size_t x = 0;

	for (x = 0; x < (sizeof(kns_modcode_table) / sizeof(KeyNameSymTable)); x++) {
		if (sym == kns_modcode_table[x].Sym) {
			return kns_modcode_table[x].Name;
		}
	}

	return NULL;
}
