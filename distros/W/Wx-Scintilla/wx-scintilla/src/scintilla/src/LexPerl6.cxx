// Scintilla source code edit control
/** 
 * @file LexPerl6.cxx
 *
 * An experimental Perl 6 syntax highlighter for Scintilla
 * written by Ahmad M. Zawawi <ahmad.zawawi@gmail.com>
 */
// Copyright 1998-2001 by Neil Hodgson <neilh@scintilla.org>
// The License.txt file describes the conditions under which this software may be distributed.

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <stdarg.h>
#include <assert.h>
#include <ctype.h>

#include "ILexer.h"
#include "Scintilla.h"
#include "SciLexer.h"

#include "WordList.h"
#include "LexAccessor.h"
#include "Accessor.h"
#include "StyleContext.h"
#include "CharacterSet.h"
#include "LexerModule.h"

#ifdef SCI_NAMESPACE
using namespace Scintilla;
#endif

/**
 * Colourize the Perl 6 document
 */
static void ColourisePerl6Doc(unsigned int startPos, int length, int, WordList *keywordLists[], Accessor &styler)
{
	int state = SCE_P6_DEFAULT;
	char chNext = styler[startPos];
	int lengthDoc = startPos + length;

	// Create a buffer large enough to take the largest chunk...
	char *buffer = new char[length];

	// Perl 6 Keyword list
	//WordList &keywords = *keywordLists[0];

	// Go through all provided text segment
	// using the hand-written state machine shown below
	styler.StartAt(startPos);
	styler.StartSegment(startPos);
	for (int i = startPos; i < lengthDoc; i++) {
		char ch = chNext;
		chNext = styler.SafeGetCharAt(i + 1);

		if (styler.IsLeadByte(ch)) {
			chNext = styler.SafeGetCharAt(i + 2);
			i++;
			continue;
		}
		switch(state) {
			case SCE_P6_DEFAULT:
				if( ch == '\n' || ch == '\r' || ch == '\t' || ch == ' ') {
					// Whitespace is ignored here
					styler.ColourTo(i,SCE_P6_DEFAULT);
					break;
				} else if( ch == '#' ) {
					// The start of a comment
					state = SCE_P6_COMMENT;
					styler.ColourTo(i,SCE_P6_COMMENT);
				} else if( ch == '"') {
					// The start of a string
					state = SCE_P6_STRING;
					styler.ColourTo(i,SCE_P6_STRING);
				} else {
					// The default style..
					styler.ColourTo(i,SCE_P6_DEFAULT);
				}
				break;

			case SCE_P6_COMMENT:
				// If we find a newline here, we go to the default state otherwise we continue to work on it
				if( ch == '\n' || ch == '\r' ) {
					state = SCE_P6_DEFAULT;
				} else {
					styler.ColourTo(i,SCE_P6_COMMENT);
				}
				break;

			case SCE_P6_STRING:
				// if we find the end of a string character, then we go to default state
				// otherwise we are still dealing with a string
				if( (ch == '"' && styler.SafeGetCharAt(i-1)!='\\') || (ch == '\n') || (ch == '\r') ) {
					state = SCE_P6_DEFAULT;
				}
				styler.ColourTo(i,SCE_P6_STRING);
				break;

		}
	}

	delete [] buffer;
}

static const char * const perl6WordListDesc[] = {
	"Keywords",
	0
};

LexerModule lmPerl6(SCLEX_PERL6, ColourisePerl6Doc, "perl6", 0, perl6WordListDesc);