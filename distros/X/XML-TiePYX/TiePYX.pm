package XML::TiePYX;
use strict;
use vars qw($VERSION);
use Carp;
use IO::File;
use XML::Parser;

use base 'Tie::Handle';

$VERSION = '0.05';

sub TIEHANDLE {
  my $class=shift;
  my $source=shift;
  my %args=(Condense=>1,Validating=>0,Latin=>0,Catalog=>0,@_);
  my $self={output=>[],EOF=>0,offset=>0,in_tag=>0};
  my $parser;
  $self->{condense}=delete $args{Condense};
  $self->{latin}=delete $args{Latin};
  my $catname=delete $args{Catalog};
  if ($args{Validating}) {
    require XML::Checker::Parser;
    $parser=XML::Checker::Parser->new(%args) or croak "$!";
  } else {
    $parser=XML::Parser->new(%args) or croak "$!";
  }
  $parser->setHandlers(Start=>\&start,End=>\&end,Char=>\&char,Proc=>\&proc);
  if ($catname) {
    require XML::Catalog;
    my $catalog=XML::Catalog->new($catname) or croak "$!";
    $parser->setHandlers(ExternEnt=>$catalog->get_handler($parser));
  }
  $self->{parser}=$parser->parse_start(TiePYX=>$self) or croak "$!";  
  if (ref($source) eq 'SCALAR') {
    $self->{src}=$source;
    $self->{src_offset}=0;
  }
  elsif (ref($source)=~/^IO:|^GLOB$/) {
    $self->{srcfile}=$source;
  }
  else {
    $self->{srcfile}=IO::File->new($source) or return undef;
    $self->{opened}=1;
  }
  bless $self,$class;
}

sub CLOSE {
  my $self=shift;
  $self->{srcfile}->close() if $self->{opened};
  $self->{parser}=undef;
}

sub DESTROY {
  my $self=shift;
  $self->{parser}=undef;
}

sub READLINE {
  my $self=shift;
  $self->parsechunks(wantarray());
  if (wantarray()) {
    if (@{$self->{output}}) {
      $self->{output}[0]=substr($self->{output}[0],$self->{offset});
      return @{$self->{output}};
    }
    else {
      return undef;
    }
  }  
  my $buf=substr((shift @{$self->{output}}) || '',$self->{offset});
  $self->{offset}=0;
  return $buf||undef;
}

sub READ {
  my ($self,$data,$length,$offset)=@_;
  my $buf;
  while (length($buf)<$length && !$self->{EOF}) {
    $self->parsechunks(0);
    my $t=$self->{output}[0] or last;
    my $t1=$length-length($buf);
    if ($t1>=length(substr($t,$self->{offset}))) {
      $buf.=$t;
      shift @{$self->{output}};
      $self->{offset}=0;
    }
    else {    
      $buf.=substr($t,$self->{offset},$t1);
      $self->{offset}+=$t1;
    }
  }
  substr($_[1],$offset||0,$length)=$buf;
  return length($buf);
}

sub PRINTF {
  my $self=shift;
  my $fmt=shift;
  my $buf=sprintf($fmt,@_);
  $self->WRITE($buf,length($buf),0);
}

sub WRITE {
  my ($self,$data)=@_;
  if ($self->{latin} && $self->{offset}==0) {
    $self->output(qq{<?xml version="1.0" encoding="ISO-8859-1"?>\n});
  }
  ++$self->{offset};
  foreach my $line (split /\n/,$data) {
    my $type=substr($line,0,1);
    $line=substr($line,1);
    if ($type eq 'A') {
      my ($attr,$val)=split(/\s+/,$line,2);
      my $quote='"';
      $self->output(" $attr=",0);
      if ($val=~tr/"//) {
        $quote="'";
        $val=~s/'/&apos;/g if $val=~tr/'//;
      }
      $self->output("${quote}$val$quote",1);
      next;
    }
    if ($self->{in_tag}) {
      $self->output('>',0);
      $self->{in_tag}=0;
    }
    if ($type eq '(') {
      $self->output("<$line",0);
      $self->{in_tag}=1;
    }
    elsif ($type eq ')') {
      $self->output("</$line>",0);
    }
    elsif ($type eq '-') {
      $self->output($line,1);
    }
    elsif ($type eq '?') {
      $self->output('<?',0);
      $self->output($line,1);
      $self->output('?>',0);
    }
  }
}

sub output {
  my ($self,$line,$encode)=@_;
  my %enc=('&'=>'&amp;','<'=>'&lt;','>'=>'&gt;');
  my $enc=join '',keys %enc;
  $line=~s/\\n/\n/g;
  $line=~s/([$enc])(?!apos)/$enc{$1}/go if $encode;
  if (exists $self->{src}) {
    ${$self->{src}}.=$line;
  }
  else {
    $self->{srcfile}->print($line);
  }
}

sub parsechunks {
  my ($self,$goforit)=@_;
  my $buf;
  while ((!@{$self->{output}}
         || (substr($self->{output}[-1],0,1) eq '-' && $self->{condense})
         || $goforit)
         && !$self->{EOF}) {
    if (exists $self->{src}) {
      $buf=substr(${$self->{src}},$self->{src_offset},4096);
      $self->{src_offset}+=4096;
    }
    else {
      read($self->{srcfile},$buf,4096);
    }
    if (length($buf)==0) {
      $self->{EOF}=1;
      $self->{parser}->parse_done();
    }
    else {
      $self->{parser}->parse_more($buf);
    }
  }
}

sub start {
  my ($parser,$element,@attrs)=@_;
  my $self=$parser->{TiePYX};
  if (@{$self->{output}} && substr($self->{output}[-1],0,1) eq '-' && $self->{condense}) {
    $self->{output}[-1].="\n";
  }
  push @{$self->{output}},'('.$self->nsname($element)."\n";
  while (@attrs) {
    my ($name,$val)=(shift @attrs,shift @attrs);
    push @{$self->{output}},'A'.$self->nsname($name).' '.$self->encode($val)."\n";
  }
}

sub end {
  my ($parser,$element)=@_;
  my $self=$parser->{TiePYX};
  if (@{$self->{output}} && substr($self->{output}[-1],0,1) eq '-' && $self->{condense}) {
    $self->{output}[-1].="\n";
  }
  push @{$self->{output}},')'.$self->nsname($element)."\n";
}

sub char {
  my ($parser,$text)=@_;
  my $self=$parser->{TiePYX};
  if (@{$self->{output}} && substr($self->{output}[-1],0,1) eq '-' && $self->{condense}) {
    $self->{output}[-1].=$self->encode($text);
  }
  else {
    push @{$self->{output}},'-'.$self->encode($text).($self->{condense}?'':"\n");
  }
}

sub proc {
  my ($parser,$target,$value)=@_;
  my $self=$parser->{TiePYX};
  if (@{$self->{output}} && substr($self->{output}[-1],0,1) eq '-' && $self->{condense}) {
    $self->{output}[-1].="\n";
  }
  push @{$self->{output}},"?$target ".$self->encode($value)."\n";
}

sub nsname {
  my ($self,$name)=@_;
  my $parser=$self->{parser};
  if ($parser->{Namespaces}) {
    my $ns=$parser->namespace($name)||'';
    $name="{$ns}".$name;
  }
  return $self->encode($name);    
}

sub encode {
  my ($self,$text)=@_;
  $text=~s/\x0a/\\n/g;
  if ($self->{latin}) {
    $text=~s{([\xc0-\xc3])(.)}{
      my $hi = ord($1);
      my $lo = ord($2);
      chr((($hi & 0x03) <<6) | ($lo & 0x3F))
     }ge;
  }
  return $text;
}

1;
__END__

=head1 NAME

XML::TiePYX - Read or write XML data in PYX format via tied filehandle

=head1 SYNOPSIS

  use XML::TiePYX;

  tie *XML,'XML::TiePYX','file.xml'

  open IN,'file.xml' or die $!;
  tie *XML,'XML::TiePYX',\*IN,Condense=>0;

  my $text='<tag xmlns="http://www.omsdev.com">text</tag>';
  tie *XML,'XML::TiePYX',\$text,Namespaces=>1;

  tie *XML,'XML::TiePYX',\*STDOUT;
  print XML "(start\n","-Hello, world!\n",")start\n";

=head1 DESCRIPTION

XML::TiePYX lets you use a tied filehandle to read from or write to an XML 
file or string.  PYX is a line-oriented, parsed representation of XML 
developed by Sean McGrath (http://www.pyxie.org).  Each line corresponds to 
one "event" in the XML, with the first character indicating the type of 
event:

=over 4

=item (

The start of an element; the rest of the line is its name.

=item A

An attribute; the rest of the line is the attribute's name, a space, and 
its value.

=item )

The end of an element; the rest of the line is its name.

=item -

Literal text (characters).  The rest of the line is the text.

=item ?

A processing instruction.  The rest of the line is the instruction's 
target, a space, and the instruction's value.

=back

Newlines in attribute values, text, and processing instruction values are 
represented as the literal sequence '\n' (that is, a backslash followed by 
an 'n').  By default, consecutive runs of characters are always gathered 
into a single text event when reading, but this behavior can be disabled.  
Comments are *not* available through PYX.

Just as SAX is an API well suited to "push"-mode XML parsing, PYX is well- 
suited to "pull"-mode parsing where you want to capture the state of the 
parse through your program's flow of code rather than through a bunch of 
state variables.  This module uses incremental parsing to avoid the need to 
buffer up large numbers of events.

This module implements an (unofficial) extension to the PYX format to allow 
namespace processing.  If namespaces are enabled, an element or attribute 
name will be prefixed by its namespace URI (*NOT* any namespace prefix used 
in the document) enclosed in curly braces.  A name with no namespace will 
be prefixed with {}.  At the present time, this module does not implement 
namespace processing in output mode; attempting to write '(', ')', or 'A' 
lines that contain a namespace URI in curly braces will merely result in 
generating ill-formed element or attribute names.


=head1 INTERFACE

  tie *tied_handle, 'XML::TiePYX', source, [Option=>value,...]

I<tied_handle> is the filehandle which the PYX events will be read from or 
written to.  

I<source> is either a reference to a string containing the XML, the name of 
a file containing the XML, or an open IO::Handle or filehandle glob 
reference which the XML can be read or written to.

The I<Option>s can be any options allowed by XML::Parser and 
XML::Parser::Expat, as well as four module-specific options:

=over 4

=item I<Validating>

This will provide a validating parse by using XML::Checker::Parser 
in place of XML::Parser if set to a true value.

=item I<Condense>

Causes all consecutive runs of character data to be gathered up into a 
single PYX event if set to a true value (the default).  If set false, 
multiple consecutive character data events may occur in the stream (which 
may be desirable when dealing with large chunks of text).  This option has 
no effect when writing.

=item I<Latin>

If set to a true value, causes Unicode characters in the range 128-255 to 
be returned as ISO-Latin-1 characters rather than UTF-8 characters when 
reading, and an XML declaration specifying an encoding of "ISO-8859-1" to 
be output when writing.

=item I<Catalog>

Specifies the URL of a catalog to use for resolving public identifiers and 
remapping system identifiers used in document type declarations or external 
entity references.  This option requires XML::Catalog to be installed.

=back

The tied filehandle may be read from with either the diamond operator 
(<HANDLE>), getc(), or read().  The diamond operator always returns a line 
at a time regardless of the setting of $/.  It may be written to with 
print() or printf(); it is necessary to print one or more complete PYX 
lines at a time.  This module does not support read/write mode.

=head1 EXAMPLE

This program (B<psectp.plx> in the distribution) prints a numbered outline from an 
XML file in which an <outline> can contain zero or more <sect>s, each with 
a I<title> attribute, and each <sect> can contain zero or more nested 
<sect>s or <para>s containing text, as in the B<sects.otl> file included with 
the distribution.  The -c option makes it print just a table of contents.

This is actually a traditional recursive-descent parser using PYX events as tokens.

  #!/usr/bin/perl -w

  use strict;
  use XML::TiePYX;
  use Text::Wrap;
  use Getopt::Std;

  my (@sectnums,%opts);

  getopts('c',\%opts);

  die "usage: psect [-c] file\n" unless @ARGV==1;

  tie *XML,'XML::TiePYX',$ARGV[0];
  die "illegal structure" unless get_event() =~ /^\(outline/;
  push @sectnums,0;
  print_sect() while get_event() =~ /^\(sect/;
  die unless /^\)outline/;
  close XML;

  sub print_sect {
    <XML>=~/^Atitle (.*)/ or die "missing title";
    ++$sectnums[-1];
    print ' ' x (4*$#sectnums),join('.',@sectnums)," $1\n";
    print "\n" unless $opts{c};
    push @sectnums,0;
    while (get_event() !~ /^\)sect/) {
      /^\(sect/ and print_sect(),next;
      /^\(para/ and print_para(),next;
      die "illegal structure";
    }
    pop @sectnums;    
  }
  
  sub print_para() {
    die "illegal structure" unless <XML> =~ /^-(.*)/;
    $_=$1;
    s/\\n/ /g;
    s/^\s+//;
    s/\s+$//;
    print wrap((' ' x (4*($#sectnums-1))) x 2,$_),"\n\n" unless $opts{c};
    die "illegal structure" unless <XML> =~ /^\)para/;
  }

  sub get_event {
    $_=<XML>;
    $_=<XML> if /^-(\s|\\n)*$/;
    $_;
  }

=head1 RATIONALE

There's already an XML::PYX module (written by Matt Sergeant) available, so 
why another PYX implementation?  Mainly because XML::PYX is intended to be 
used in a standalone PYX-outputting program which you open as a pipe.  That 
works very well under Unix, aside from the overhead of forking a separate 
process, but is problematic on Win32 systems for a variety of niggling 
reasons: the standalone script is supplied as a batch file, whose output 
can't be properly redirected into a pipe unless you invoke it as 'perl 
/perl/bin/pyx|' instead of just 'pyx|'.  Both Win95 and Win98, as well as 
possibly other Win32 systems, implement pipes using temporary files and the 
reading process can't start reading until the writing process is done 
writing, which means that if you're parsing a huge file you may have to 
wait a long time before getting *any* output.  The ability to guarantee a 
single character data event for any run of characters can often simplify 
processing.  And finally, when I wrote this the only supported namespace- 
aware way to parse XML was the raw handlers interface of XML::Parser, which 
is needlessly complicated for simple applications (there are, of course, 
those who would argue that "simple applications" and "namespace-aware" are 
mutually-exclusive categories).

=head1 BUGS

The I<Validating> option does not work correctly, as XML::Checker::Parser 
does not implement the parse_start() method.

Error handling leaves much to be desired.

=head1 AUTHOR

Eric Bohlman (ebohlman@netcom.com, ebohlman@omsdev.com)

=head1 COPYRIGHT

Copyright 2000 Eric Bohlman.  All rights reserved.

This program is free software; you can use/modify/redistribute it under the
same terms as Perl itself.

=head1 SEE ALSO

  XML::PYX
  XML::Parser
  XML::Parser::Expat
  XML::Checker
  XML::Catalog
  perl(1).

=cut
