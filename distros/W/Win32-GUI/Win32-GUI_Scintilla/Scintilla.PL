#! perl -w
use strict;
use warnings;
use File::Basename;
use File::Path;

# $Id: Scintilla.PL,v 1.8 2008/02/09 12:53:44 robertemay Exp $

my $iface_file = "Include/Scintilla.iface";

# MakeMaker provides the output filename as the first argument on the
# command line, we need to ensure the directory exists before opening
# the file:
if ( @ARGV > 0 ) {
    my $file = $ARGV[0];
    my $path = dirname($file);
    unless (-d $path) {
        mkpath($path, 1) or die qq(Failed to create '$path': $!);
    }
    open(my $fh, '>', $file) or die qq(Failed to open '$file': $!);
    select $fh;
}


# Preamble
# Was scintilla.pm.begin
print <<'PREAMBLE';
#------------------------------------------------------------------------
# Scintilla control for Win32::GUI
# by Laurent ROCHER (lrocher@cpan.org)
#------------------------------------------------------------------------
#perl2exe_bundle 'SciLexer.dll'

# This file created by the build process from Scintilla.PL
# change made here will be lost.  Edit Scintilla.PL instead.
# $Id: Scintilla.PL,v 1.8 2008/02/09 12:53:44 robertemay Exp $

package Win32::GUI::Scintilla;

use strict;
use warnings;

use Win32::GUI qw(WS_CLIPCHILDREN WS_TABSTOP WS_VISIBLE WS_HSCROLL WS_VSCROLL);

require DynaLoader;

our @ISA = qw(DynaLoader Win32::GUI::Window);

our $VERSION = "1.91";
our $XS_VERSION = $VERSION;
$VERSION = eval $VERSION;

bootstrap Win32::GUI::Scintilla $XS_VERSION;

#------------------------------------------------------------------------

# Load Scintilla DLL from somewhere on @INC or standard LoadLibrary search
my ($SCILEXER_FILE,$SCILEXER_DLL);
for my $path (@INC) {
    my $lexer_file = $path . '/auto/Win32/GUI/Scintilla/SciLexer.dll';
    if (-f $lexer_file) {
        $SCILEXER_FILE = $lexer_file;
        last;
    }
}

if ($SCILEXER_FILE) {
    $SCILEXER_DLL = Win32::GUI::LoadLibrary($SCILEXER_FILE);
    warn qq(Failed to load SciLexer.dll from "$SCILEXER_FILE") unless $SCILEXER_DLL;
}

unless ($SCILEXER_DLL) {
    warn qq(Final attempt to find SciLexer.dll in PATH);
    $SCILEXER_DLL = Win32::GUI::LoadLibrary('SciLexer');
}

die qq(Failed to load 'SciLexer.dll') unless $SCILEXER_DLL;

Win32::GUI::Scintilla::_Initialise();

END {
  # Free Scintilla DLL
  Win32::GUI::Scintilla::_UnInitialise();
  #Win32::GUI::FreeLibrary($SCILEXER_DLL); 
  #The above line causes some scripts to crash - such as test2.pl in the samples when running under 5.8.7
}

#------------------------------------------------------------------------

#
# Notify event code
#

use constant SCN_STYLENEEDED        => 2000;
use constant SCN_CHARADDED          => 2001;
use constant SCN_SAVEPOINTREACHED   => 2002;
use constant SCN_SAVEPOINTLEFT      => 2003;
use constant SCN_MODIFYATTEMPTRO    => 2004;
use constant SCN_KEY                => 2005;
use constant SCN_DOUBLECLICK        => 2006;
use constant SCN_UPDATEUI           => 2007;
use constant SCN_MODIFIED           => 2008;
use constant SCN_MACRORECORD        => 2009;
use constant SCN_MARGINCLICK        => 2010;
use constant SCN_NEEDSHOWN          => 2011;
use constant SCN_PAINTED            => 2013;
use constant SCN_USERLISTSELECTION  => 2014;
use constant SCN_URIDROPPED         => 2015;
use constant SCN_DWELLSTART         => 2016;
use constant SCN_DWELLEND           => 2017;
use constant SCN_ZOOM               => 2018;
use constant SCN_HOTSPOTCLICK       => 2019;
use constant SCN_HOTSPOTDOUBLECLICK => 2020;
use constant SCN_CALLTIPCLICK       => 2021;

#------------------------------------------------------------------------

#
# New scintilla control
#

sub new {

  my $class  = shift;

  my (%in)   = @_;
  my %out;

  ### Filtering option
  for my $option (qw(
        -name -parent
        -left -top -width -height -pos -size
        -pushstyle -addstyle -popstyle -remstyle -notstyle -negstyle
        -exstyle -pushexstyle -addexstyle -popexstyle -remexstyle -notexstyle
        )) {
    $out{$option} = $in{$option} if exists $in{$option};
  }

  ### Default window
  my $constant     = ($Win32::GUI::VERSION < 1.0303 ?
                       Win32::GUI::constant("WIN32__GUI__STATIC",0) :
                       Win32::GUI::_constant("WIN32__GUI__STATIC"));
  $out{-addstyle}  = WS_CLIPCHILDREN;
  $out{-class}     = "Scintilla";

  ### Window style
  $out{-addstyle} |= WS_TABSTOP unless exists $in{-tabstop} && $in{-tabstop} == 0; #Default to -tabstop => 1
  $out{-addstyle} |= WS_VISIBLE unless exists $in{-visible} && $in{-visible} == 0; #Default to -visible => 1
  $out{-addstyle} |= WS_HSCROLL if     exists $in{-hscroll} && $in{-hscroll} == 1;
  $out{-addstyle} |= WS_VSCROLL if     exists $in{-vscroll} && $in{-vscroll} == 1;

  my $self = Win32::GUI->_new($constant, $class, -remstyle => 0xFFFFFFFF, %out);
  if (defined ($self)) {

    # Option Text :
    $self->SetText($in{-text}) if exists $in{-text};
    $self->SetReadOnly($in{-readonly}) if exists $in{-readonly};
  }

  return $self;
}

#
# Win32 shortcut
#

sub Win32::GUI::Window::AddScintilla {
  my $parent  = shift;
  return Win32::GUI::Scintilla->new (-parent => $parent, @_);
}

#------------------------------------------------------------------------
# Miscolous function
#------------------------------------------------------------------------

#
# Clear Scintilla Text
#

sub NewFile {
  my $self = shift;

  $self->ClearAll();
  $self->EmptyUndoBuffer();
  $self->SetSavePoint();
}

#
# Load text file to Scintilla
#

sub LoadFile {
  my ($self, $file) = @_;

  $self->ClearAll();
  $self->Cancel();
  $self->SetUndoCollection(0);

  open my $fh, "<$file" or return 0;
  while ( <$fh> ) {
    $self->AppendText($_);
  }
  close $fh;

  $self->SetUndoCollection(1);
  $self->EmptyUndoBuffer();
  $self->SetSavePoint();
  $self->GotoPos(0);

  return 1;
}

#
# Save Scintilla text to file
#

sub SaveFile {
  my ($self, $file) = @_;

  open my $fh, ">$file" or return 0;

  for my $i (0 .. ($self->GetLineCount() - 1)) {
    print $fh $self->GetLine ($i);
  }

  close $fh;

  $self->SetSavePoint();

  return 1;
}

#
# Help routine for StyleSet
#

sub StyleSetSpec {
  my ($self, $style, $textstyle) = @_;

  foreach my $prop (split (/,/, $textstyle)) {

    my ($key, $value) = split (/:/, $prop);

    $self->StyleSetFore($style, $value) if $key eq 'fore';
    $self->StyleSetBack($style, $value) if $key eq 'back';

    $self->StyleSetFont($style, $value) if $key eq 'face';

    $self->StyleSetSize($style, int ($value) )  if $key eq 'size';

    $self->StyleSetBold($style, 1)      if $key eq 'bold';
    $self->StyleSetBold($style, 0)      if $key eq 'notbold';
    $self->StyleSetItalic($style, 1)    if $key eq 'italic';
    $self->StyleSetItalic($style, 0)    if $key eq 'notitalic';
    $self->StyleSetUnderline($style, 1) if $key eq 'underline';
    $self->StyleSetUnderline($style, 0) if $key eq 'notunderline';
    $self->StyleSetEOLFilled ($style, 1) if $key eq 'eolfilled';
    $self->StyleSetEOLFilled ($style, 0) if $key eq 'noteolfilled';
  }
}

#------------------------------------------------------------------------
# Begin Autogenerate
#------------------------------------------------------------------------

PREAMBLE


# Autogenerate the contents from Include\Scintilla.iface


# Build Scintilla interface

open my $fh, "<" , $iface_file or die "Failed to open '$iface_file' for reading: $!";

while ( <$fh> )
{
    #chomp;
    s/\r?\n$//; # throw away line endings - chomp on cygwin only removes '\n'
                # done this way in case dos2unix didn't get run on this file
                # - Scintilla.iface probably didn't get dealt with as a text file?

    #--- Constant ---
    if (/^val (.*)=(.*)$/) {
        print "use constant $1 => $2 ;\n";
    }
    #--- Get ---
    elsif (/^get colour (.*)=(.*)\(,\)$/ ) {
        print "sub $1 {\n  my \$self = shift;\n  my \$colour = \$self->SendMessage ($2, 0, 0);\n  \$colour = sprintf ('#%x', \$colour);\n  \$colour =~ s/(.)(..)(..)(..)/\$1\$4\$3\$2/;\n  return \$colour;\n}\n";
    }
    elsif (/^get colour (.*)=(.*)\(int (.*),\)$/ ) {
        print "sub $1 {\n  my (\$self, \$$3) = \@_;\n  my \$colour = \$self->SendMessage ($2, \$$3, 0);\n  \$colour = sprintf ('#%x', \$colour);\n  \$colour =~ s/(.)(..)(..)(..)/\$1\$4\$3\$2/;\n  return \$colour;\n}";
    }
    elsif (/^get (.*) (.*)=(.*)\(,\)$/ ) {
        print "sub $2 {\n  my \$self = shift;\n  return \$self->SendMessage ($3, 0, 0);\n}\n";
    }
    elsif (/^get int GetCharAt=2007\(position pos,\)$/ ) {
        print "sub GetCharAt {\n  my (\$self, \$pos) = \@_;\n  return chr \$self->SendMessage (2007, \$pos, 0);\n}\n";
    }
    elsif (/^get int GetPropertyInt=4010\(string key,\)$/ ) {
        print "sub GetPropertyInt {\n  my (\$self, \$key) = \@_;\n  return \$self->SendMessagePP (4010, \$key, '');\n}\n";
    }
    elsif (/^get (.*) (.*)=(.*)\(position (.*),\)$/ ) {
        print "sub $2 {\n  my (\$self, \$$4) = \@_;\n  return \$self->SendMessage ($3, \$$4, 0);\n}\n";
    }
    elsif (/^get (.*) (.*)=(.*)\(int (.*),\)$/ ) {
        print "sub $2 {\n  my (\$self, \$$4) = \@_;\n  return \$self->SendMessage ($3, \$$4, 0);\n}\n";
    }
    elsif (/^get (.*) (.*)=(.*)\(int (.*), int (.*)\)$/ ) {
        print "sub $2 {\n  my (\$self, \$$4, \$$5) = \@_;\n  return \$self->SendMessage ($3, \$$4, \$$5);\n}\n";
    }
    #--- Set ---
    elsif (/^set (.*) (.*)=(.*)\(,\)$/ ) {
        print "sub $2 {\n  my \$self = shift;\n  return \$self->SendMessage ($3, 0, 0);\n}\n";
    }
    elsif (/^set (.*) (.*)=(.*)\(bool (.*),\)$/ ) {
        print "sub $2 {\n  my (\$self, \$$4) = \@_;\n  return \$self->SendMessage ($3, \$$4, 0);\n}\n";
    }
    elsif (/^set (.*) (.*)=(.*)\(int (.*),\)$/ ) {
        print "sub $2 {\n  my (\$self, \$$4) = \@_;\n  return \$self->SendMessage ($3, \$$4, 0);\n}\n";
    }
    elsif (/^set (.*) (.*)=(.*)\(position (.*),\)$/ ) {
        print "sub $2 {\n  my (\$self, \$$4) = \@_;\n  return \$self->SendMessage ($3, \$$4, 0);\n}\n";
    }
    elsif (/^set (.*) (.*)=(.*)\(colour (.*),\)$/ ) {
        print "sub $2 {\n  my (\$self, \$$4) = \@_;\n  \$$4 =~ s/.(..)(..)(..)/\$3\$2\$1/;\n  return \$self->SendMessage ($3, int hex \$$4, 0);\n}\n";
    }
    elsif (/^set (.*) (.*)=(.*)\(int (.*), int (.*)\)$/ ) {
        print "sub $2 {\n  my (\$self, \$$4, \$$5) = \@_;\n  return \$self->SendMessage ($3, \$$4, \$$5);\n}\n";
    }
    elsif (/^set (.*) (.*)=(.*)\(int (.*), bool (.*)\)$/ ) {
        print "sub $2 {\n  my (\$self, \$$4, \$$5) = \@_;\n  return \$self->SendMessage ($3, \$$4, \$$5);\n}\n";
    }
    elsif (/^set (.*) (.*)=(.*)\(bool (.*), colour (.*)\)$/ ) {
        print "sub $2 {\n  my (\$self, \$$4, \$$5) = \@_;\n  \$$5 =~ s/.(..)(..)(..)/\$3\$2\$1/;\n  return \$self->SendMessage ($3, \$$4, int hex \$$5);\n}\n";
    }
    elsif (/^set (.*) (.*)=(.*)\(int (.*), colour (.*)\)$/ ) {
        print "sub $2 {\n  my (\$self, \$$4, \$$5) = \@_;\n  \$$5 =~ s/.(..)(..)(..)/\$3\$2\$1/;\n  return \$self->SendMessage ($3, \$$4, int hex \$$5);\n}\n";
    }
    elsif (/^set (.*) (.*)=(.*)\(int (.*), string (.*)\)$/ ) {
        print "sub $2 {\n  my (\$self, \$$4, \$$5) = \@_;\n  return \$self->SendMessageNP ($3, \$$4, \$$5);\n}\n";
    }
    elsif (/^set (.*) (.*)=(.*)\(string (.*), string (.*)\)$/ ) {
        print "sub $2 {\n  my (\$self, \$$4, \$$5) = \@_;\n  return \$self->SendMessagePP ($3, \$$4, \$$5);\n}\n";
    }
    elsif (/^set (.*) (.*)=(.*)\(, string (.*)\)$/ ) {
        print "sub $2 {\n  my (\$self, \$$4) = \@_;\n  return \$self->SendMessageNP ($3, 0, \$$4);\n}\n";
    }
    elsif (/^set (.*) (.*)=(.*)\(,\s?int (.*)\)$/ ) {
        print "sub $2 {\n  my (\$self, \$$4) = \@_;\n  return \$self->SendMessage ($3, 0, \$$4);\n}\n";
    }
    #--- Special Function ---
    # AddText, ReplaceTarget, ReplaceTargetRE, SearchInTarget, AppendText, CopyText
    elsif (/^fun (.*) (.*)=(.*)\(int length, string text\)$/ ) {
        print "# $2(text)\n";
        print "sub $2 {\n";
        print '  my ($self, $text) = @_;', "\n";
        print '  my $length = length $text;', "\n";
        print "  return \$self->SendMessageNP ($3, \$length, \$text);\n";
        print '}', "\n";
    }
    # AddStyledText
    elsif (/^fun void AddStyledText=2002\(int length, cells c\)$/ ) {
        print '# AddStyledText(styledtext)', "\n";
        print 'sub AddStyledText {', "\n";
        print '  my ($self, $text) = @_;', "\n";
        print '  my $length = length $text;', "\n";
        print '  return $self->SendMessageNP (2002, $length, $text);', "\n";
        print '}', "\n";
    }
    # GetStyledText and GetTextRange
    elsif (/^fun (.*) (.*)=(.*)\(, textrange (.*)\)$/ ) {
        print "sub $2 {\n  my \$self = shift;\n  my \$start = shift || 0;\n  my \$end = shift || \$self->GetLength();\n\n";
        print "  return undef if \$start >= \$end;\n\n";
        if ( $2 eq 'GetStyledText') {
            print "  my \$text = \" \" x ((\$end - \$start + 1)*2);\n";
        }
        else {
            print "  my \$text = \" \" x (\$end - \$start + 1);\n";
        }
        print "  my \$textrange = pack(\"LLp\", \$start, \$end, \$text);\n";
        print "  \$self->SendMessageNP ($3, 0, \$textrange);\n";
        print "  return \$text;\n}\n";
    }
    # GetCurLine
    elsif (/^fun int GetCurLine=2027\(int length, stringresult text\)$/) {
        print '# GetCurline () : Return curent line Text', "\n";
        print 'sub GetCurLine {', "\n";
        print '  my ($self) = @_;',"\n";
        print '  my $line   = $self->GetLineFromPosition ($self->GetCurrentPos());',"\n";
        print '  my $length = $self->LineLength($line);',"\n";
        print '  my $text   = " " x $length;',"\n\n";
        print '  if ($self->SendMessageNP (2027, $length, $text)) {',"\n";
        print '    return $text;',"\n";
        print '  } else {',"\n";
        print '    return undef;',"\n";
        print '  }',"\n";
        print '}',"\n";
    }
    # GetLine
    elsif (/^fun int GetLine=2153\(int line, stringresult text\)/) {
        print '# Getline (line)', "\n";
        print 'sub GetLine {', "\n";
        print '  my ($self, $line)  = @_;', "\n";
        print '  my $length = $self->LineLength($line);', "\n";
        print '  my $text   = " " x $length;', "\n\n";
        print '  if ($self->SendMessageNP (2153, $line, $text)) {', "\n";
        print '    return $text;', "\n";
        print '  } else {', "\n";
        print '    return undef;', "\n";
        print '  }', "\n";
        print '}', "\n";
    }
    # GetSelText
    elsif (/^fun int GetSelText=2161\(, stringresult text\)/) {
        print '# GetSelText() : Return selected text', "\n";
        print 'sub GetSelText {', "\n";
        print '  my $self  = shift;', "\n";
        print '  my $start = $self->GetSelectionStart();', "\n";
        print '  my $end   = $self->GetSelectionEnd();', "\n\n";

        print '  return undef if $start >= $end;', "\n";
        print '  my $text   = " " x ($end - $start + 1);', "\n\n";

        print '  $self->SendMessageNP (2161, 0, $text);', "\n";
        print '  return $text;', "\n";
        print '}', "\n";
    }
    # TargetAsUTF8
    elsif (/^fun int TargetAsUTF8=2447\(, stringresult s\)/) {
        print '# TargetAsUTF8() :', "\n";
        print '# Returns the target converted to UTF8.',"\n";
        print 'sub TargetAsUTF8 {', "\n";
        print '  my $self  = shift;', "\n";
        print '  my $len   = $self->SendMessage(2447,0,0);',"\n";
        print '  my $text   = " " x $len;', "\n\n";

        print '  $self->SendMessageNP (2447, 0, $text);', "\n";
        print '  return $text;', "\n";
        print '}', "\n";
    }
    # EncodeFromUTF8
    elsif (/^fun int EncodedFromUTF8=2449\(string utf8, stringresult encoded\)/) {
        print '# EncodedFromUTF8() :', "\n";
        print '# Translates a UTF8 string into the document encoding.',"\n";
        print '# Return the length of the result in bytes.',"\n";
        print '# On error return 0.',"\n";
        print 'sub EncodedFromUTF8 {', "\n";
        print '  my ($self, $src)  = @_;', "\n";
        print '  my $len   = $self->SendMessagePN(2449,$src,0);',"\n";
        print '  my $text   = " " x $len;', "\n\n";

        print '  if($self->SendMessagePP (2449, $src, $text)) {', "\n";
        print '    return $text;', "\n";
        print '  }', "\n";
        print '  else {', "\n";
        print '    return undef;', "\n";
        print '  }', "\n";
        print '}', "\n";
    }
    # GetText :
    elsif (/^fun int GetText=2182\(int length, stringresult text\)/) {
        print '# GetText() : Return all text', "\n";
        print 'sub GetText {', "\n";
        print '  my $self   = shift;', "\n";
        print '  my $length = $self->SendMessage(2182, 0, 0); # includes trailing NUL', "\n";
        print '  my $text   = " " x $length;', "\n\n";
        print '  $self->SendMessageNP (2182, $length, $text);', "\n";
        print '  $text =~ s/.$//; # remove trailing NUL (regexp is faster than sbstr)', "\n";
        print '  return $text;', "\n";
        print '}', "\n";
    }
    # FindText :
    elsif (/^fun position FindText=2150\(int flags, findtext ft\)/) {
        print '# FindText (textToFind, start=0, end=GetLength(), flag = SCFIND_WHOLEWORD)', "\n";
        print 'sub FindText {', "\n";
        print '  my $self       = shift;', "\n";
        print '  my $text       = shift;', "\n";
        print '  my $start      = shift || 0;', "\n";
        print '  my $end        = shift || $self->GetLength();', "\n";
        print '  my $flag       = shift || SCFIND_WHOLEWORD;', "\n\n";
        print '  return undef if $start >= $end;', "\n\n";
        print '  my $texttofind =  pack("LLpLL", $start, $end, $text, 0, 0);', "\n";
        print '  my $pos = $self->SendMessageNP (2150, $flag, $texttofind);', "\n";
        print '  return $pos unless defined wantarray;', "\n";
        print '  my @res = unpack("LLpLL", $texttofind);', "\n";
        print '  return ($res[3], $res[4]); # pos , length', "\n";
        print '}', "\n";
    }
    # GetProperty and GetPropertyExpanded :
    elsif (/^fun int (.+)=(\d+)\(string key, stringresult buf\)/) {
        print '# GetProperty(): Retrieve a "property" value previously set with SetProperty.',"\n";
        print '# GetPropertyExpanded() with "$()" variable replacement on returned buffer.',"\n";
        print 'sub '.$1.' {', "\n";
        print '  my ($self, $key)   = @_;', "\n";
        print '  my $len = $self->SendMessagePN('.$2.', $key, 0);', "\n";
        print '  my $text   = " " x $len;', "\n\n";

        print '  $self->SendMessagePP ('.$2.', $key, $text);', "\n";
        print '  return $text;', "\n";
        print '}', "\n";
    }
    # GetPropertyExpanded :
    elsif (/^fun int GetPropertyExpanded=4008\(string key, stringresult buf\)/) {
        print '# GetPropertyExpanded(): Retrieve a "property" value previously set with SetProperty.',"\n";
        print 'sub GetProperty {', "\n";
        print '  my ($self, $key)   = @_;', "\n";
        print '  my $len = $self->SendMessagePN(4008, $key, 0);', "\n";
        print '  my $text   = " " x $len;', "\n\n";

        print '  $self->SendMessagePP (4008, $key, $text);', "\n";
        print '  return $text;', "\n";
        print '}', "\n";
    }
    # FindRange :
    elsif (/^fun position FormatRange=2151\(bool draw, formatrange fr\)/) {
        print '# FormatRange (start=0, end=GetLength(), draw=1)', "\n";
        print 'sub FormatRange {', "\n";
        print '  my $self       = shift;', "\n";
        print '  my $start      = shift || 0;', "\n";
        print '  my $end        = shift || $self->GetLength();', "\n";
        print '  my $draw       = shift || 1;', "\n";
        print '  return undef if $start >= $end;', "\n\n";
        print '  my $formatrange = pack("LL", $start, $end);', "\n";
        print '  return $self->SendMessageNP (2151, $draw, $formatrange);', "\n";
        print '}', "\n";
    }
    #--- Function ---
    elsif (/^fun (.*) (.*)=(.*)\(,\)$/ ) {
        print "sub $2 {\n  my \$self = shift;\n  return \$self->SendMessage ($3, 0, 0);\n}\n";
    }
    elsif (/^fun (.*) (.*)=(.*)\(bool (.*),\)$/ ) {
        print "sub $2 {\n  my (\$self, \$$4) = \@_;\n  return \$self->SendMessage ($3, \$$4, 0);\n}\n";
    }
    elsif (/^fun (.*) (.*)=(.*)\(int (.*),\)$/ ) {
        print "sub $2 {\n  my (\$self, \$$4) = \@_;\n  return \$self->SendMessage ($3, \$$4, 0);\n}\n";
    }
    elsif (/^fun (.*) (.*)=(.*)\(position (.*),\)$/ ) {
        print "sub $2 {\n  my (\$self, \$$4) = \@_;\n  return \$self->SendMessage ($3, \$$4, 0);\n}\n";
    }
    elsif (/^fun (.*) (.*)=(.*)\(, position (.*)\)$/ ) {
        print "sub $2 {\n  my (\$self, \$$4) = \@_;\n  return \$self->SendMessage ($3, 0, \$$4);\n}\n";
    }
    elsif (/^fun (.*) (.*)=(.*)\(int (.*), int (.*)\)$/ ) {
        print "sub $2 {\n  my (\$self, \$$4, \$$5) = \@_;\n  return \$self->SendMessage ($3, \$$4, \$$5);\n}\n";
    }
    elsif (/^fun (.*) (.*)=(.*)\(int (.*), colour (.*)\)$/ ) {
        print "sub $2 {\n  my (\$self, \$$4, \$$5) = \@_;\n  \$$5 =~ s/.(..)(..)(..)/\$3\$2\$1/;\n  return \$self->SendMessage ($3, \$$4, int hex \$$5);\n}\n";
    }
    elsif (/^fun (.*) (.*)=(.*)\(int (.*), string (.*)\)$/ ) {
        print "sub $2 {\n  my (\$self, \$$4, \$$5) = \@_;\n  return \$self->SendMessageNP ($3, \$$4, \$$5);\n}\n";
    }
    elsif (/^fun (.*) (.*)=(.*)\(, string (.*)\)$/ ) {
        print "sub $2 {\n  my (\$self, \$$4) = \@_;\n  return \$self->SendMessageNP ($3, 0, \$$4);\n}\n";
    }
    elsif (/^fun (.*) (.*)=(.*)\(, int (.*)\)$/ ) {
        print "sub $2 {\n  my (\$self, \$$4) = \@_;\n  return \$self->SendMessage ($3, 0, \$$4);\n}\n";
    }
    elsif (/^fun (.*) (.*)=(.*)\(position (.*), string (.*)\)$/ ) {
        print "sub $2 {\n  my (\$self, \$$4, \$$5) = \@_;\n  return \$self->SendMessageNP ($3, \$$4, \$$5);\n}\n";
    }
    elsif (/^fun (.*) (.*)=(.*)\(position (.*), bool (.*)\)$/ ) {
        print "sub $2 {\n  my (\$self, \$$4, \$$5) = \@_;\n  return \$self->SendMessage ($3, \$$4, \$$5);\n}\n";
    }
    elsif (/^fun (.*) (.*)=(.*)\(position (.*), int (.*)\)$/ ) {
        print "sub $2 {\n  my (\$self, \$$4, \$$5) = \@_;\n  return \$self->SendMessage ($3, \$$4, \$$5);\n}\n";
    }
    elsif (/^fun (.*) (.*)=(.*)\(position (.*), position (.*)\)$/ ) {
        print "sub $2 {\n  my (\$self, \$$4, \$$5) = \@_;\n  return \$self->SendMessage ($3, \$$4, \$$5);\n}\n";
    }
    elsif (/^fun (.*) (.*)=(.*)\(bool (.*), colour (.*)\)$/ ) {
        print "sub $2 {\n  my (\$self, \$$4, \$$5) = \@_;\n  \$$5 =~ s/.(..)(..)(..)/\$3\$2\$1/;\n  return \$self->SendMessage ($3, \$$4, int hex \$$5);\n}\n";
    }
    elsif (/^fun (.*) (.*)=(.*)\(int (.*), cells (.*)\)$/ ) {
        print "sub $2 {\n  my (\$self, \$$4, \$$5) = \@_;\n  return \$self->SendMessageNP ($3, \$$4, \$$5);\n}\n";
    }
    elsif (/^fun (.*) (.*)=(.*)\(keymod (.*),\)$/ ) {
        print "sub $2 {\n  my (\$self, \$key, \$modifiers) = \@_;\n";
        print "  my \$param = pack ('ss', \$key, \$modifiers);\n";
        print "  return \$self->SendMessage ($3, \$param, 0);\n}\n";
    }
    elsif (/^fun (.*) (.*)=(.*)\(keymod (.*), int (.*)\)$/ ) {
        print "sub $2 {\n  my (\$self, \$key, \$modifiers, \$$5) = \@_;\n";
        print "  my \$param = pack ('ss', \$key, \$modifiers);\n";
        print "  return \$self->SendMessage ($3, \$param, \$$5);\n}\n";
    }
    #--- Comment ---
    elsif (/^\#\s(.*)$/) {
        print "# $1\n";
    }
    elsif (/^lex (.*)$/) {
        print "# $1\n";
    }
    #--- Error ----
    elsif (/^fun (.*)$/) {
        print STDERR "===> Function = $1\n";
    }
    elsif (/^set (.*)$/) {
        print STDERR "===> Set      = $1\n";
    }
    elsif (/^get (.*)$/) {
        print STDERR "===> Get      = $1\n";
    }
}
close $fh;

# Add Postamble
# was: scintilla.pm.end
print <<'POSTAMBLE';

#------------------------------------------------------------------------
# End Autogenerate
#------------------------------------------------------------------------

# Code Here because need constant

#------------------------------------------------------------------------
# BraceHighEvent Management
#------------------------------------------------------------------------

sub BraceHighEvent {

  my $self   = shift;
  my $braces = shift || "[]{}()";

  my $braceAtCaret = -1;
  my $braceOpposite = -1;
  my $caretPos = $self->GetCurrentPos();

  if ($caretPos > 0) {
    my $charBefore  = $self->GetCharAt($caretPos - 1);
    $braceAtCaret = $caretPos - 1 if (index ($braces, $charBefore) >= 0 );
  }

  if ($braceAtCaret < 0)
  {
    my $charAfter  = $self->GetCharAt($caretPos);
    my $styleAfter = $self->GetCharAt($caretPos);

    $braceAtCaret = $caretPos if (index ($braces, $charAfter) >= 0);
  }

  $braceOpposite = $self->BraceMatch($braceAtCaret) if ($braceAtCaret >= 0);

  if ($braceAtCaret != -1  and $braceOpposite == -1) {
    $self->BraceBadLight($braceAtCaret);
  }
  else {
    $self->BraceHighlight($braceAtCaret, $braceOpposite);
  }
}

#------------------------------------------------------------------------
# Folder Management
#------------------------------------------------------------------------

# Folder Event call
# If Shift and Control are pressed, open or close all folder
# Otherwise
#  if shift is pressed, Toggle 1 level of current folder
#  else if control is pressed, expand all subfolder of current folder
#  else Toggle current folder
sub FolderEvent {

  my $self  = shift;
  my (%evt) = @_;

  if ($evt{-shift} and $evt{-control}) {
    $self->FolderAll();
  }
  else {
    my $lineClicked = $self->LineFromPosition($evt{-position});

    if ($self->GetFoldLevel($lineClicked) & Win32::GUI::Scintilla::SC_FOLDLEVELHEADERFLAG) {
       if ($evt{-shift}) {
           $self->SetFoldExpanded($lineClicked, 1);
           $self->FolderExpand($lineClicked, 1, 1, 1);
       }
       elsif ($evt{-control}) {
           if ($self->GetFoldExpanded($lineClicked)) {
               $self->SetFoldExpanded($lineClicked, 0);
               $self->FolderExpand($lineClicked, 0, 1, 0);
           }
           else {
               $self->SetFoldExpanded($lineClicked, 1);
               $self->FolderExpand($lineClicked, 1, 1, 100);
           }
       }
       else {
          $self->ToggleFold($lineClicked);
       }
     }
  }
}

# Open All Folder
sub FolderAll {

  my $self = shift;
  my $lineCount = $self->GetLineCount();
  my $expanding = 1;
  my $lineNum;

  # find out if we are folding or unfolding
  for $lineNum (1..$lineCount) {    # XXX Should this be 0 .. $linecount - 1 ???
    if ($self->GetFoldLevel($lineNum) & Win32::GUI::Scintilla::SC_FOLDLEVELHEADERFLAG) {
      $expanding = not $self->GetFoldExpanded($lineNum);
      last;
    }
  }

  $lineNum = 0;
  while ($lineNum < $lineCount) {
    my $level = $self->GetFoldLevel($lineNum);
    if (($level & Win32::GUI::Scintilla::SC_FOLDLEVELHEADERFLAG) and
        ($level & Win32::GUI::Scintilla::SC_FOLDLEVELNUMBERMASK) == Win32::GUI::Scintilla::SC_FOLDLEVELBASE) {

      if ($expanding) {
        $self->SetFoldExpanded($lineNum, 1);
        $lineNum = $self->FolderExpand($lineNum, 1);
        $lineNum--;
      }
      else {
        my $lastChild = $self->GetLastChild($lineNum, -1);
        $self->SetFoldExpanded($lineNum, 0);
        $self->HideLines($lineNum+1, $lastChild) if ($lastChild > $lineNum);
      }
    }
    $lineNum++;
  }
}

# Expand folder
sub FolderExpand {
  my $self     = shift;
  my $line     = shift;
  my $doExpand = shift;
  my $force    = shift || 0;
  my $visLevels= shift || 0;
  my $level    = shift || -1;

  my $lastChild = $self->GetLastChild($line, $level);
  $line++;
  while ($line <= $lastChild) {
      if ($force) {
          if ($visLevels > 0) {
              $self->ShowLines($line, $line);
          }
          else {
              $self->HideLines($line, $line);
          }
      }
      else {
          $self->ShowLines($line, $line) if ($doExpand);
      }

      $level = $self->GetFoldLevel($line) if ($level == -1);

      if ($level & Win32::GUI::Scintilla::SC_FOLDLEVELHEADERFLAG) {
          if ($force) {
              if ($visLevels > 1) {
                  $self->SetFoldExpanded($line, 1);
              }
              else {
                  $self->SetFoldExpanded($line, 0);
              }
              $line = $self->FolderExpand($line, $doExpand, $force, $visLevels-1);
          }
          else {
              if ($doExpand and $self->GetFoldExpanded($line)) {
                  $line = $self->FolderExpand($line, 1, $force, $visLevels-1);
              }
              else {
                  $line = $self->FolderExpand($line, 0, $force, $visLevels-1);
              }
          }
      }
      else {
          $line ++;
      }
  }

  return $line;
}

#------------------------------------------------------------------------
# Find Management
#------------------------------------------------------------------------

sub FindAndSelect {

  my $self = shift;
  my $text = shift;
  my $flag = shift || Win32::GUI::Scintilla::SCFIND_WHOLEWORD;
  my $direction = shift || 1;
  my $wrap = shift || 1;

  my ($start, $end);

  # Set Search target
  if ($direction >= 0) {
    $start = $self->GetSelectionEnd ();
    $end   = $self->GetLength();
  }
  else {
    $start = $self->GetSelectionStart() - 1;
    $end   = 0;
  }

  $self->SetTargetStart ($start);
  $self->SetTargetEnd   ($end);
  $self->SetSearchFlags  ($flag);

  # Find text
  my $pos = $self->SearchInTarget($text);

  # Not found and Wrap mode
  if ($pos == -1 and $wrap == 1)
  {
    # New search target
    if ($direction >= 0) {
     $start = 0;
     $end = $self->GetLength();
    }
    else {
     $start = $self->GetLength();
     $end = 0;
    }

    $self->SetTargetStart ($start);
    $self->SetTargetEnd   ($end);

    # Find Text
    $pos = $self->SearchInTarget($text);
  }

  # Select and visible
  unless ($pos == -1)
  {
    # GetTarget
    $start = $self->GetTargetStart();
    $end   = $self->GetTargetEnd();

    # Ensure range visible
    my ($lstart, $lend);
    if ($start <= $end)
    {
      $lstart = $self->LineFromPosition($start);
      $lend   = $self->LineFromPosition($end);
    }
    else
    {
      $lstart = $self->LineFromPosition($end);
      $lend   = $self->LineFromPosition($start);
    }

    for my $i ($lstart .. $lend)
    {
      $self->EnsureVisible ($i);
    }

    # Select Target
    $self->SetSel ($start, $end);
  }
  else
  {
    $self->SetSelectionStart ($self->GetSelectionEnd());
  }

  return $pos;
}

1; # End of Scintilla.pm
__END__
POSTAMBLE
__END__
