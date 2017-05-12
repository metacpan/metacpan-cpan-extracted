#! perl

open G, ">Scintilla.pm" or return 1;

# Add Startup
open F, "<scintilla.pm.begin" or return 1;
while ( <F> )
{
  print G $_;
}
close F;

# Build Scintilla interface
open F, "<include/scintilla.iface" or return 2;
while ( <F> )
{
  #--- Constant ---
  if (/^val (.*)=(.*)$/)
  {
    print G "use constant $1 => $2 ;\n";
  }
  #--- Get ---
  elsif (/^get colour (.*)=(.*)\(,\)$/ )
  {
    print G "sub $1 {\n  my \$self = shift;\n  my \$colour = \$self->SendMessage ($2, 0, 0);\n  \$colour = sprintf ('#%x', \$colour);\n  \$colour =~ s/(.)(..)(..)(..)/\$1\$4\$3\$2/;\n  return \$colour;\n}\n";
  }
  elsif (/^get colour (.*)=(.*)\(int (.*),\)$/ )
  {
    print G "sub $1 {\n  my (\$self, \$$3) = \@_;\n  my \$colour = \$self->SendMessage ($2, \$$3, 0);\n  \$colour = sprintf ('#%x', \$colour);\n  \$colour =~ s/(.)(..)(..)(..)/\$1\$4\$3\$2/;\n  return \$colour;\n}";
  }
  elsif (/^get (.*) (.*)=(.*)\(,\)$/ )
  {
    print G "sub $2 {\n  my \$self = shift;\n  return \$self->SendMessage ($3, 0, 0);\n}\n";
  }
  elsif (/^get int GetCharAt=2007\(position pos,\)$/ )
  {
    print G "sub GetCharAt {\n  my (\$self, \$pos) = \@_;\n  return chr \$self->SendMessage (2007, \$pos, 0);\n}\n";
  }
  elsif (/^get (.*) (.*)=(.*)\(position (.*),\)$/ )
  {
    print G "sub $2 {\n  my (\$self, \$$4) = \@_;\n  return \$self->SendMessage ($3, \$$4, 0);\n}\n";
  }
  elsif (/^get (.*) (.*)=(.*)\(int (.*),\)$/ )
  {
    print G "sub $2 {\n  my (\$self, \$$4) = \@_;\n  return \$self->SendMessage ($3, \$$4, 0);\n}\n";
  }
  elsif (/^get (.*) (.*)=(.*)\(int (.*), int (.*)\)$/ )
  {
    print G "sub $2 {\n  my (\$self, \$$4, \$$5) = \@_;\n  return \$self->SendMessage ($3, \$$4, \$$5);\n}\n";
  }
  #--- Set ---
  elsif (/^set (.*) (.*)=(.*)\(,\)$/ )
  {
    print G "sub $2 {\n  my \$self = shift;\n  return \$self->SendMessage ($3, 0, 0);\n}\n";
  }
  elsif (/^set (.*) (.*)=(.*)\(bool (.*),\)$/ )
  {
    print G "sub $2 {\n  my (\$self, \$$4) = \@_;\n  return \$self->SendMessage ($3, \$$4, 0);\n}\n";
  }
  elsif (/^set (.*) (.*)=(.*)\(int (.*),\)$/ )
  {
    print G "sub $2 {\n  my (\$self, \$$4) = \@_;\n  return \$self->SendMessage ($3, \$$4, 0);\n}\n";
  }
  elsif (/^set (.*) (.*)=(.*)\(position (.*),\)$/ )
  {
    print G "sub $2 {\n  my (\$self, \$$4) = \@_;\n  return \$self->SendMessage ($3, \$$4, 0);\n}\n";
  }
  elsif (/^set (.*) (.*)=(.*)\(colour (.*),\)$/ )
  {
    print G "sub $2 {\n  my (\$self, \$$4) = \@_;\n  \$$4 =~ s/.(..)(..)(..)/\$3\$2\$1/;\n  return \$self->SendMessage ($3, int hex \$$4, 0);\n}\n";
  }
  elsif (/^set (.*) (.*)=(.*)\(int (.*), int (.*)\)$/ )
  {
    print G "sub $2 {\n  my (\$self, \$$4, \$$5) = \@_;\n  return \$self->SendMessage ($3, \$$4, \$$5);\n}\n";
  }
  elsif (/^set (.*) (.*)=(.*)\(int (.*), bool (.*)\)$/ )
  {
    print G "sub $2 {\n  my (\$self, \$$4, \$$5) = \@_;\n  return \$self->SendMessage ($3, \$$4, \$$5);\n}\n";
  }
  elsif (/^set (.*) (.*)=(.*)\(bool (.*), colour (.*)\)$/ )
  {
    print G "sub $2 {\n  my (\$self, \$$4, \$$5) = \@_;\n  \$$5 =~ s/.(..)(..)(..)/\$3\$2\$1/;\n  return \$self->SendMessage ($3, \$$4, int hex \$$5);\n}\n";
  }
  elsif (/^set (.*) (.*)=(.*)\(int (.*), colour (.*)\)$/ )
  {
    print G "sub $2 {\n  my (\$self, \$$4, \$$5) = \@_;\n  \$$5 =~ s/.(..)(..)(..)/\$3\$2\$1/;\n  return \$self->SendMessage ($3, \$$4, int hex \$$5);\n}\n";
  }
  elsif (/^set (.*) (.*)=(.*)\(int (.*), string (.*)\)$/ )
  {
    print G "sub $2 {\n  my (\$self, \$$4, \$$5) = \@_;\n  return \$self->SendMessageNP ($3, \$$4, \$$5);\n}\n";
  }
  elsif (/^set (.*) (.*)=(.*)\(string (.*), string (.*)\)$/ )
  {
    print G "sub $2 {\n  my (\$self, \$$4, \$$5) = \@_;\n  return \$self->SendMessagePP ($3, \$$4, \$$5);\n}\n";
  }
  elsif (/^set (.*) (.*)=(.*)\(, string (.*)\)$/ )
  {
    print G "sub $2 {\n  my (\$self, \$$4) = \@_;\n  return \$self->SendMessageNP ($3, 0, \$$4);\n}\n";
  }
  elsif (/^set (.*) (.*)=(.*)\(,\s?int (.*)\)$/ )
  {
    print G "sub $2 {\n  my (\$self, \$$4) = \@_;\n  return \$self->SendMessage ($3, 0, \$$4);\n}\n";
  }
  #--- Special Function ---
  # AddText, ReplaceTarget, ReplaceTargetRE, SearchInTarget, AppendText, CopyText
  elsif (/^fun (.*) (.*)=(.*)\(int length, string text\)$/ )
  {
    print G "# $2(text)\n";
    print G "sub $2 {\n";
    print G '  my ($self, $text) = @_;', "\n";
    print G '  my $length = length $text;', "\n";
    print G "  return \$self->SendMessageNP ($3, \$length, \$text);\n";
    print G '}', "\n";
  }
  # AddStyledText
  elsif (/^fun void AddStyledText=2002\(int length, cells c\)$/ )
  {
    print G '# AddStyledText(styledtext)', "\n";
    print G 'sub AddStyledText {', "\n";
    print G '  my ($self, $text) = @_;', "\n";
    print G '  my $length = length $text;', "\n";
    print G '  return $self->SendMessageNP (2002, $length, $text);', "\n";
    print G '}', "\n";
  }
  # GetStyledText and GetTextRange
  elsif (/^fun (.*) (.*)=(.*)\(, textrange (.*)\)$/ )
  {
    print G "sub $2 {\n  my \$self = shift;\n  my \$start = shift || 0;\n  my \$end = shift || \$self->GetLength();\n\n";
    print G "  return undef if \$start >= \$end;\n\n";
    if ( $2 eq 'GetStyledText')
    {
      print G "  my \$text = \" \" x ((\$end - \$start + 1)*2);\n";
    }
    else
    {
      print G "  my \$text = \" \" x (\$end - \$start + 1);\n";
    }
    print G "  my \$textrange = pack(\"LLp\", \$start, \$end, \$text);\n";
    print G "  \$self->SendMessageNP ($3, 0, \$textrange);\n";
    print G "  return \$text;\n}\n";
  }
  # GetCurLine
  elsif (/^fun int GetCurLine=2027\(int length, stringresult text\)$/)
  {
    print G '# GetCurline () : Return curent line Text', "\n";
    print G 'sub GetCurLine {', "\n";
    print G '  my ($self) = @_;',"\n";
    print G '  my $line   = $self->GetLineFromPosition ($self->GetCurrentPos());',"\n";
    print G '  my $lenght = $self->LineLength($line);',"\n";
    print G '  my $text   = " " x ($lenght+1);',"\n\n";
    print G '  if ($self->SendMessageNP (2027, $lenght, $text)) {',"\n";
    print G '    return $text;',"\n";
    print G '  } else {',"\n";
    print G '    return undef;',"\n";
    print G '  }',"\n";
    print G '}',"\n";
  }
  # GetLine
  elsif (/^fun int GetLine=2153\(int line, stringresult text\)/)
  {
    print G '# Getline (line)', "\n";
    print G 'sub GetLine {', "\n";
    print G '  my ($self, $line)  = @_;', "\n";
    print G '  my $lenght = $self->LineLength($line);', "\n";
    print G '  my $text   = " " x ($lenght + 1);', "\n\n";
    print G '  if ($self->SendMessageNP (2153, $line, $text)) {', "\n";
    print G '    return $text;', "\n";
    print G '  } else {', "\n";
    print G '    return undef;', "\n";
    print G '  }', "\n";
    print G '}', "\n";
  }

  # GetSelText
  elsif (/^fun int GetSelText=2161\(, stringresult text\)/)
  {
    print G '# GetSelText() : Return selected text', "\n";
    print G 'sub GetSelText {', "\n";
    print G '  my $self  = shift;', "\n";
    print G '  my $start = $self->GetSelectionStart();', "\n";
    print G '  my $end   = $self->GetSelectionEnd();', "\n\n";

    print G '  return undef if $start >= $end;', "\n";
    print G '  my $text   = " " x ($end - $start + 1);', "\n\n";

    print G '  $self->SendMessageNP (2161, 0, $text);', "\n";
    print G '  return $text;', "\n";
    print G '}', "\n";
  }
  # GetText :
  elsif (/^fun int GetText=2182\(int length, stringresult text\)/)
  {
    print G '# GetText() : Return all text', "\n";
    print G 'sub GetText {', "\n";
    print G '  my $self   = shift;', "\n";
    print G '  my $lenght = $self->GetTextLength() + 1;', "\n";
    print G '  my $text   = " " x ($lenght+1);', "\n\n";
    print G '  if ($self->SendMessageNP (2182, $lenght, $text)) {', "\n";
    print G '    return $text;', "\n";
    print G '  } else {', "\n";
    print G '    return undef;', "\n";
    print G '  }', "\n";
    print G '}', "\n";
  }
  # FindText :
  elsif (/^fun position FindText=2150\(int flags, findtext ft\)/)
  {
    print G '# FindText (textToFind, start=0, end=GetLength(), flag = SCFIND_WHOLEWORD)', "\n";
    print G 'sub FindText {', "\n";
    print G '  my $self       = shift;', "\n";
    print G '  my $text       = shift;', "\n";
    print G '  my $start      = shift || 0;', "\n";
    print G '  my $end        = shift || $self->GetLength();', "\n";
    print G '  my $flag       = shift || SCFIND_WHOLEWORD;', "\n\n";
    print G '  return undef if $start >= $end;', "\n\n";
    print G '  my $texttofind =  pack("LLpLL", $start, $end, $text, 0, 0);', "\n";
    print G '  my $pos = $self->SendMessageNP (2150, $flag, $texttofind);', "\n";
    print G '  return $pos unless defined wantarray;', "\n";
    print G '  my @res = unpack("LLpLL", $texttofind);', "\n";
    print G '  return ($res[3], $res[4]); # pos , lenght', "\n";
    print G '}', "\n";
  }
  # FindRange :
  elsif (/^fun position FormatRange=2151\(bool draw, formatrange fr\)/)
  {
    print G '# FormatRange (start=0, end=GetLength(), draw=1)', "\n";
    print G 'sub FormatRange {', "\n";
    print G '  my $self       = shift;', "\n";
    print G '  my $start      = shift || 0;', "\n";
    print G '  my $end        = shift || $self->GetLength();', "\n";
    print G '  my $draw       = shift || 1;', "\n";
    print G '  return undef if $start >= $end;', "\n\n";
    print G '  my $formatrange = pack("LL", $start, $end);', "\n";
    print G '  return $self->SendMessageNP (2151, $draw, $formatrange);', "\n";
    print G '}', "\n";
  }
  #--- Function ---
  elsif (/^fun (.*) (.*)=(.*)\(,\)$/ )
  {
    print G "sub $2 {\n  my \$self = shift;\n  return \$self->SendMessage ($3, 0, 0);\n}\n";
  }
  elsif (/^fun (.*) (.*)=(.*)\(bool (.*),\)$/ )
  {
    print G "sub $2 {\n  my (\$self, \$$4) = \@_;\n  return \$self->SendMessage ($3, \$$4, 0);\n}\n";
  }
  elsif (/^fun (.*) (.*)=(.*)\(int (.*),\)$/ )
  {
    print G "sub $2 {\n  my (\$self, \$$4) = \@_;\n  return \$self->SendMessage ($3, \$$4, 0);\n}\n";
  }
  elsif (/^fun (.*) (.*)=(.*)\(position (.*),\)$/ )
  {
    print G "sub $2 {\n  my (\$self, \$$4) = \@_;\n  return \$self->SendMessage ($3, \$$4, 0);\n}\n";
  }
  elsif (/^fun (.*) (.*)=(.*)\(, position (.*)\)$/ )
  {
    print G "sub $2 {\n  my (\$self, \$$4) = \@_;\n  return \$self->SendMessage ($3, 0, \$$4);\n}\n";
  }
  elsif (/^fun (.*) (.*)=(.*)\(int (.*), int (.*)\)$/ )
  {
    print G "sub $2 {\n  my (\$self, \$$4, \$$5) = \@_;\n  return \$self->SendMessage ($3, \$$4, \$$5);\n}\n";
  }
  elsif (/^fun (.*) (.*)=(.*)\(int (.*), colour (.*)\)$/ )
  {
    print G "sub $2 {\n  my (\$self, \$$4, \$$5) = \@_;\n  \$$5 =~ s/.(..)(..)(..)/\$3\$2\$1/;\n  return \$self->SendMessage ($3, \$$4, int hex \$$5);\n}\n";
  }
  elsif (/^fun (.*) (.*)=(.*)\(int (.*), string (.*)\)$/ )
  {
    print G "sub $2 {\n  my (\$self, \$$4, \$$5) = \@_;\n  return \$self->SendMessageNP ($3, \$$4, \$$5);\n}\n";
  }
  elsif (/^fun (.*) (.*)=(.*)\(, string (.*)\)$/ )
  {
    print G "sub $2 {\n  my (\$self, \$$4) = \@_;\n  return \$self->SendMessageNP ($3, 0, \$$4);\n}\n";
  }
  elsif (/^fun (.*) (.*)=(.*)\(, int (.*)\)$/ )
  {
    print G "sub $2 {\n  my (\$self, \$$4) = \@_;\n  return \$self->SendMessage ($3, 0, \$$4);\n}\n";
  }
  elsif (/^fun (.*) (.*)=(.*)\(position (.*), string (.*)\)$/ )
  {
    print G "sub $2 {\n  my (\$self, \$$4, \$$5) = \@_;\n  return \$self->SendMessageNP ($3, \$$4, \$$5);\n}\n";
  }
  elsif (/^fun (.*) (.*)=(.*)\(position (.*), bool (.*)\)$/ )
  {
    print G "sub $2 {\n  my (\$self, \$$4, \$$5) = \@_;\n  return \$self->SendMessage ($3, \$$4, \$$5);\n}\n";
  }
  elsif (/^fun (.*) (.*)=(.*)\(position (.*), int (.*)\)$/ )
  {
    print G "sub $2 {\n  my (\$self, \$$4, \$$5) = \@_;\n  return \$self->SendMessage ($3, \$$4, \$$5);\n}\n";
  }
  elsif (/^fun (.*) (.*)=(.*)\(position (.*), position (.*)\)$/ )
  {
    print G "sub $2 {\n  my (\$self, \$$4, \$$5) = \@_;\n  return \$self->SendMessage ($3, \$$4, \$$5);\n}\n";
  }
  elsif (/^fun (.*) (.*)=(.*)\(bool (.*), colour (.*)\)$/ )
  {
    print G "sub $2 {\n  my (\$self, \$$4, \$$5) = \@_;\n  \$$5 =~ s/.(..)(..)(..)/\$3\$2\$1/;\n  return \$self->SendMessage ($3, \$$4, int hex \$$5);\n}\n";
  }
  elsif (/^fun (.*) (.*)=(.*)\(int (.*), cells (.*)\)$/ )
  {
    print G "sub $2 {\n  my (\$self, \$$4, \$$5) = \@_;\n  return \$self->SendMessageNP ($3, \$$4, \$$5);\n}\n";
  }
  elsif (/^fun (.*) (.*)=(.*)\(keymod (.*),\)$/ )
  {
    print G "sub $2 {\n  my (\$self, \$key, \$modifiers) = \@_;\n";
    print G "  my \$param = pack ('ss', \$key, \$modifiers);\n";
    print G "  return \$self->SendMessage ($3, \$param, 0);\n}\n";
  }
  elsif (/^fun (.*) (.*)=(.*)\(keymod (.*), int (.*)\)$/ )
  {
    print G "sub $2 {\n  my (\$self, \$key, \$modifiers, \$$5) = \@_;\n";
    print G "  my \$param = pack ('ss', \$key, \$modifiers);\n";
    print G "  return \$self->SendMessage ($3, \$param, \$$5);\n}\n";
  }
  #--- Comment ---
  elsif (/^\#\s(.*)$/)
  {
    print G "# $1\n";
  }
  elsif (/^lex (.*)$/)
  {
    print G "# $1\n";
  }
  #--- Error ----
  elsif (/^fun (.*)$/)
  {
    print "===> Function = $1\n";
  }
  elsif (/^set (.*)$/)
  {
    print "===> Set      = $1\n";
  }
  elsif (/^get (.*)$/)
  {
    print "===> Get      = $1\n";
  }
}
close F;

# Add End
open F, "<scintilla.pm.end" or return 3;
while ( <F> )
{
  print G $_;
}
close F;

close G;
