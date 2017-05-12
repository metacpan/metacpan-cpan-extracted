package arXiv::FileGuess;

=head1 NAME

arXiv::FileGuess - Central file type determination for arXiv

=head1 SYNOPSIS

Central file type identification for arXiv.org. 

Much of this should probably be replaced with the file program with externally
maintained magic information. However, we need here to support a number of cases
special to arXiv and to make some rather fine-grained determinations of TeX
related file formats, along with determination of the order in which they
should be processed.

=cut

use strict;

use base qw(Exporter);
our @EXPORT_OK = qw( guess_file_type is_tex_type type_name );

use vars qw(%NAME %TEX_types);

=head2 INTERNAL VARIABLES

=head3 %TEX_types

A hash of type names which represent TeX types (i.e. should be processed with
AutoTeX). Accessed via function is_tex_type().

=cut

=head3 %NAME

A display name indexed by type. Accessed via function type_name().

=cut

BEGIN {
  # Make sure %TEX_types and %NAME full before use

  @TEX_types{qw(
	       TYPE_LATEX
	       TYPE_TEX
	       TYPE_TEX_priority
	       TYPE_TEX_AMS
	       TYPE_TEX_MAC
	       TYPE_LATEX2e
	       TYPE_TEX_priority2
	       TYPE_TEXINFO
	       TYPE_PDFLATEX
	       TYPE_PDFTEX
	    )} = ();

  $NAME{'TYPE_ABORT'} = 'Immediate stop';
  $NAME{'TYPE_FAILED'} = 'unknown';
  $NAME{'TYPE_ALWAYS_IGNORE'} = 'Always ignore';
  $NAME{'TYPE_INPUT'} = 'Input for (La)TeX';
  $NAME{'TYPE_BIBTEX'} = 'BiBTeX';
  $NAME{'TYPE_POSTSCRIPT'} = 'Postscript';
  $NAME{'TYPE_DOS_EPS'} = 'DOS EPS Binary File';
  $NAME{'TYPE_PS_FONT'} = 'Postscript Type 1 Font';
  $NAME{'TYPE_PS_PC'} = '^D%! Postscript';
  $NAME{'TYPE_IMAGE'} = 'Image (gif/jpg etc)';
  $NAME{'TYPE_ANIM'} = 'Animation (mpeg etc)';
  $NAME{'TYPE_HTML'} = 'HTML';
  $NAME{'TYPE_PDF'} = 'PDF';
  $NAME{'TYPE_DVI'} = 'DVI';
  $NAME{'TYPE_NOTEBOOK'} = 'Mathematica Notebook';
  $NAME{'TYPE_ODF'} = 'OpenDocument Format';
  $NAME{'TYPE_DOCX'} = 'Microsoft DOCX';
  $NAME{'TYPE_TEX'} = 'TEX';
  $NAME{'TYPE_PDFTEX'} = 'PDFTEX';
  $NAME{'TYPE_TEX_priority2'} = 'TeX (with \\end or \\bye - not starting a line)';
  $NAME{'TYPE_TEX_AMS'} = 'AMSTeX';
  $NAME{'TYPE_TEX_priority'} = 'TeX (with \\end or \\bye)';
  $NAME{'TYPE_TEX_MAC'} = 'TeX +macros (harv,lanl..)';
  $NAME{'TYPE_LATEX'} = 'LaTeX';
  $NAME{'TYPE_LATEX2e'} = 'LATEX2e';
  $NAME{'TYPE_PDFLATEX'} = 'PDFLATEX';
  $NAME{'TYPE_TEXINFO'} = 'Texinfo';
  $NAME{'TYPE_MF'} = 'Metafont';
  $NAME{'TYPE_UUENCODED'} = 'UUencoded';
  $NAME{'TYPE_ENCRYPTED'} = 'Encrypted';
  $NAME{'TYPE_PC'} = 'PC-ctrl-Ms';
  $NAME{'TYPE_MAC'} = 'MAC-ctrl-Ms';
  $NAME{'TYPE_CSH'} = 'CSH';
  $NAME{'TYPE_SH'} = 'SH';
  $NAME{'TYPE_JAR'} = 'JAR archive';
  $NAME{'TYPE_RAR'} = 'RAR archive';
  $NAME{'TYPE_COMPRESSED'} = 'UNIX-compressed';
  $NAME{'TYPE_ZIP'} = 'ZIP-compressed';
  $NAME{'TYPE_GZIPPED'} = 'GZIP-compressed';
  $NAME{'TYPE_BZIP2'} = 'BZIP2-compressed';
  $NAME{'TYPE_MULTI_PART_MIME'} = 'MULTI_PART_MIME';
  $NAME{'TYPE_TAR'} = 'TAR archive';
  $NAME{'TYPE_IGNORE'} = ' user defined IGNORE';
  $NAME{'TYPE_README'} = 'override';
  $NAME{'TYPE_TEXAUX'} = 'TeX auxiliary';
  $NAME{'TYPE_ABS'} = 'abstract';
  $NAME{'TYPE_INCLUDE'} = ' keep';
}


=head2 SUBROUTINES

=head3 guess_file_type($filename)

Guess the file type $filename. Returns ($type, $tex_format, 
$error), all of which are strings. The $type may be supplied to 
is_tex_type($type) or type_name($type) for additional information 
related to the file type.

For most files $tex_format and $error will be undefined. $tex_format 
will be defined for some TeX file formats where there is additional
information about the type of TeX.

=cut

sub guess_file_type {
  my ($filename) = @_;
  local $_ = $filename;

  return 'TYPE_README' if /(^|\/)00README\.XXX$/;

  # Ignore tmp files created by (unpatched) dvihps, in top dir
  return 'TYPE_ALWAYS_IGNORE' if /(^|\/)(head|body)\.tmp$/;

  # missfont.log files created in top dir should abort processing
  # (missfont.log files in subdirs can be ignored)
  return 'TYPE_ABORT' if /(^|\/)missfont.log$/;

  return 'TYPE_TEXAUX' if /\.(sty|cls|mf|\d*pk|bbl|bst|tfm|ax|def|log|hrfldf|cfg|clo|inx|end|fgx|tbx|rtx|rty|toc)$/i;
  return 'TYPE_ABS' if /\.abs$/;
  return 'TYPE_IGNORE' if /\.fig$/; # ignore xfig files
  return 'TYPE_NOTEBOOK' if /\.nb$/i;
  return 'TYPE_INPUT' if /\.inp$/i;

  return 'TYPE_HTML' if /\.html?$/i;
  return 'TYPE_ENCRYPTED' if /\.cry$/;

  # Ignore zero size files
  return 'TYPE_IGNORE' if (-z $filename);

  # Open file and read first few bytes to do magic sequence identification
  # note that file will be auto-closed when $FILE_TO_GUESS goes out of scope
  open(my $FILE_TO_GUESS, '<', $_) ||
    return ('TYPE_FAILED', undef, "failed to open '$filename' to guess its format: $!. Continuing.\n");

  my $b1 = ord(getc($FILE_TO_GUESS) || 0);
  my $b2 = ord(getc($FILE_TO_GUESS) || 0);
  my $b3 = ord(getc($FILE_TO_GUESS) || 0);
  my $b4 = ord(getc($FILE_TO_GUESS) || 0);
  my $b5 = ord(getc($FILE_TO_GUESS) || 0);
  my $b6 = ord(getc($FILE_TO_GUESS) || 0);
  my $b7 = ord(getc($FILE_TO_GUESS) || 0);
  my $b8 = ord(getc($FILE_TO_GUESS) || 0);

  return 'TYPE_COMPRESSED' if $b1 == 037 && $b2 == 0235;
  return 'TYPE_GZIPPED'    if $b1 == 037 && $b2 == 0213;
  return 'TYPE_BZIP2'      if $b1 == 0x42 && $b2 == 0x5A && $b3 == 0x68 && $b4 > 0x2F;

  # POSIX tarfiles: look for the string 'ustar' at posn 257
  # (There used to be additional code to detect non-POSIX tar files
  # which is not detected with above, no longer necessary)
  my $tar_test;
  seek($FILE_TO_GUESS, 257, 0);
  if ( read($FILE_TO_GUESS, $tar_test, 5) && $tar_test eq 'ustar' ) {
    return 'TYPE_TAR';
  }

  # DVI
  return 'TYPE_DVI'        if $b1 == oct(367) && $b2 == oct(2);
  # GIF
  return 'TYPE_IMAGE'      if (sprintf('%c%c%c%c',$b1,$b2,$b3,$b4) eq 'GIF8');
  # PNG
  return 'TYPE_IMAGE'      if sprintf('%c%c%c%c%c%c%c%c',$b1,$b2,$b3,$b4,$b5,$b6,$b7,$b8) eq "\211PNG\r\n\032\n";

  # TIF
  return 'TYPE_IMAGE'      if $b1 == 0115 && $b2 == 0115 && $filename =~ /\.tif/i;
  # JPEG
  return 'TYPE_IMAGE'      if ($b1==0377 && $b2==0330 && $b3==0377 && ($b4==0340 || $b4==0356));

  # MPEG
  return 'TYPE_ANIM'       if $b1 == 0 && $b2 == 0 && $b3 == 01 && $b4 == 0263;

  if (("PK\003\004" eq  sprintf('%c%c%c%c', $b1,$b2,$b3,$b4)) or
      ("PK00PK\003\004" eq sprintf('%c%c%c%c%c%c%c%c', $b1,$b2,$b3,$b4,$b5,$b6,$b7,$b8))) {
    return 'TYPE_JAR' if ($filename =~ /\.jar$/i);
    return 'TYPE_ODF' if ($filename =~ /\.odt$/i);
    return 'TYPE_DOCX' if ($filename =~ /\.docx$/i);
    return 'TYPE_ZIP'
  }
  return 'TYPE_RAR' if ('Rar!' eq sprintf('%c%c%c%c', $b1,$b2,$b3,$b4));

  #:0  belong          0xC5D0D3C6      DOS EPS Binary File
  #->4 long            >0              Postscript starts at byte %d
  return 'TYPE_DOS_EPS' if $b1 == oct(305) && $b2 == oct(320) && $b3 == oct(323) && $b4 == oct(306);

  my $one_kb;
  seek($FILE_TO_GUESS, 0, 0);
  read($FILE_TO_GUESS, $one_kb, 1024);
  return 'TYPE_PDF' if index($one_kb, '%PDF-') >= 0;
  return 'TYPE_MAC' if $one_kb =~ /#!\/bin\/csh -f\r#|(\r|^)begin \d{1,4}\s+\S.*\r[^\n]/;

  my ($maybe_tex, $maybe_tex_priority, $maybe_tex_priority2);
  seek($FILE_TO_GUESS, 0, 0);

  local $/ = "\n";
  my $accum='';
  while (<$FILE_TO_GUESS>) {
    if (/\%auto-ignore/ && $. <= 10) {
      return 'TYPE_IGNORE';
    }
    if ($. <= 10 && /\\input texinfo/) {
      return 'TYPE_TEXINFO';
    }
    if ($. <= 40 && /(^|\r)Content-type: /i ) {
      return 'TYPE_MULTI_PART_MIME';
    }

    # Match strings starting at either 1st or 7th byte. Use $accum
    # to build string of file to this point as the preceding 6 chars
    # may include \n
    $accum.=$_;
    if ($. <= 7 && $accum=~/^(......)?%\!(PS-AdobeFont-1\.|FontType1|PS-Adobe-3\.0\ Resource-Font)/s) {
      return 'TYPE_PS_FONT';
    }

    # This must come after the test for TYPE_PS_FONT
    if ($. == 1 && /^%\!/) {
      return 'TYPE_POSTSCRIPT';
    }

    if (($. == 1 && (/^\%*\004%\!/ || /.*%\!PS-Adobe/))
	|| ($. <= 10 && /^%\!PS/ && !$maybe_tex)) {
      return 'TYPE_PS_PC';
    }

    if ($. <= 12 && /^\r?%\&([^\s\n]+)/) {
      if ($1 eq 'latex209' || $1 eq 'biglatex' ||
          $1 eq 'latex' || $1 eq 'LaTeX') {
        return ('TYPE_LATEX', $1);
      } else {
        return ('TYPE_TEX_MAC', $1);
      }
    }
    if ($. <= 10 && /<html[>\s]/i) {
      return 'TYPE_HTML';
    }
    if ($. <= 10 && /\%auto-include/) {
      return 'TYPE_INCLUDE';
    }
    # All subsequent checks have lines with '%' in them chopped.
    #  if we need to look for a % then do it earlier!
    s/\%[^\r]*//;
    if (/(^|\r)\s*\\documentstyle/) {
      return 'TYPE_LATEX';
    }
    if (/(^|\r)\s*\\documentclass/) {
      return _type_of_latex2e(\*{$FILE_TO_GUESS});
    }
    if (/(^|\r)\s*(\\font|\\magnification|\\input|\\def|\\special|\\baselineskip|\\begin)/) {
      $maybe_tex = 1;
      return 'TYPE_TEX_priority' if /\\input\s+amstex/;
    }
    if (/(^|\r)\s*\\(end|bye)(\s|$)/) {
      $maybe_tex_priority = 1;
    }
    if (/\\(end|bye)(\s|$)/) {
      $maybe_tex_priority2 = 1;
    }
    if (/\\input *(harv|lanl)mac/ || /\\input\s+phyzzx/) {
      return 'TYPE_TEX_MAC';
    }
    if (/beginchar\(/) {
      return 'TYPE_MF';
    }
    if (/(^|\r)\@(book|article|inbook|unpublished)\{/i) {
      return 'TYPE_BIBTEX';
    }
    if (/^begin \d{1,4}\s+[^\s]+\r?$/) {
      return 'TYPE_TEX_priority' if $maybe_tex_priority;
      return 'TYPE_TEX' if $maybe_tex;
      return 'TYPE_PC' if /\r$/;
      return 'TYPE_UUENCODED';
    }
    if (m/paper deliberately replaced by what little/) {
      return 'TYPE_ALWAYS_IGNORE'; # Was 'TYPE_FAILED'
    }
  }
  close $FILE_TO_GUESS || warn "couldn't close file: $!";

  return 'TYPE_TEX_priority' if $maybe_tex_priority;
  return 'TYPE_TEX_priority2' if $maybe_tex_priority2;
  return 'TYPE_TEX' if $maybe_tex;

  return 'TYPE_FAILED';
}


# _type_of_latex2e($filehandle)
#
# Takes an open file handle and searches for some heuristic regexps to
# determine whether the contents is of type pdflatex or regular latex2e.
#
sub _type_of_latex2e {
  my ($filehandle) = @_;
  my $lines_to_search=$.+5; #will search for pdfoutput from beginning to 5 lines beyond
  if (seek($filehandle,0,0)) {
    local $. = 0; #reset line counter if rewind worked
  }

  while (<$filehandle>) {
    if (/^[^%]*\\includegraphics[^%]*\.(?:pdf|png|gif|jpg)\s?\}/i ||
        ($. < $lines_to_search && /^[^%]*\\pdfoutput(?:\s+)?=(?:\s+)?1/)) {
      return 'TYPE_PDFLATEX';
    }
  }
  return 'TYPE_LATEX2e';
}


=head3 is_tex_type($type)

Returns true (1) if the type name supplied is a TeX type, false ('') 
otherwise.

=cut

sub is_tex_type {
  my ($type) = @_;
  return exists $TEX_types{$type};
}


=head3 type_name($type)

Returns display string for the type $type. Or 'unknown' if
$type is not recognized.

=cut

sub type_name {
  my ($type)=@_;
  return( $NAME{$type} || 'unknown' );
}

1;

__END__
