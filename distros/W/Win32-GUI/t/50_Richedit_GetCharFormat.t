#!perl -wT
# Win32::GUI test suite.
# $Id: 50_Richedit_GetCharFormat.t,v 1.2 2006/05/16 18:57:26 robertemay Exp $

# Testing RichEdit::GetCharFormat()

use strict;
use warnings;

BEGIN { $| = 1 } # Autoflush

use Test::More tests => 16;

use Win32::GUI();

 my %font;
# --------------------------------------------------------------------------
# Test Win32::GUI::RichEdit::GetCharFormat() returning 0 for lack of formatting
#
# Dan Dascalescu
# dandv@users.sourceforge.net
# --------------------------------------------------------------------------

# check that the methods we want to use are available
can_ok('Win32::GUI::RichEdit', qw(Text Select GetCharFormat) );

my $W = Win32::GUI::Window->new();
isa_ok($W, "Win32::GUI::Window", "\$W");

my $re = $W->AddRichEdit();
isa_ok($re, "Win32::GUI::RichEdit", "\$re");

my $rtf_prolog = '{\rtf1\ansi\deff0
{\fonttbl{\f0 \fcharset1\fnil Times New Roman;}}
{\stylesheet {\*\cs0 \additive Default Paragraph Font;}}';

$re->Text($rtf_prolog . '\b bold\b0' . '}');
$re->Select(0, -1);
undef %font;
%font = $re->GetCharFormat();
is($font{-bold}, 1, "Text is bold");

# Test for a value of '0' being returned for lack of formatting
$re->Text($rtf_prolog . 'normal' . '}');
$re->Select(0, -1);
undef %font;
%font = $re->GetCharFormat();
is($font{-bold},      0, "normal text not bold");
is($font{-italic},    0, "normal text not italic");
is($font{-underline}, 0, "normal text not underline");
is($font{-strikeout}, 0, "normal text not strikeout");

# Test that each style is omitted if it does not apply to the whole selection
$re->Text($rtf_prolog . '\b bold\i italic\ul underline\strike striked\strike0\ul0\i0\b0 normal' . '}');
$re->Select(0, -1);
undef %font;
%font = $re->GetCharFormat();
ok(not(exists $font{-bold}),      "Text is not all bold");
ok(not(exists $font{-italic}),    "Text is not all italic");
ok(not(exists $font{-underline}), "Text is not all underline");
ok(not(exists $font{-strikeout}), "Text is not all strikeout");

# Test the bold text is bold
$re->Select(0, length('bolditalicunderlinestriked'));
undef %font;
%font = $re->GetCharFormat();
is($font{-bold}, 1, "bold text is bold");

# Test italic in the middle off the italic
$re->Select(length('bolditalicunderlines'), length('bolditalicunderlinest'));
undef %font;
%font = $re->GetCharFormat();
is($font{-italic}, 1, "italic character is italic");

# Test the underline text
$re->Select(length('bolditalic'), length('bolditalicunderlinestriked'));
undef %font;
%font = $re->GetCharFormat();
is($font{-underline}, 1, "underlined text is underlined");

# Test the strikeout text
$re->Select(length('bolditalicunderline'), length('bolditalicunderlinestriked'));
undef %font;
%font = $re->GetCharFormat();
is($font{-strikeout}, 1, "strikeout text is strikeout");
