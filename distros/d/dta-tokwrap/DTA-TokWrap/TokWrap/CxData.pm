## -*- Mode: CPerl -*-

## File: DTA::TokWrap::CxData.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: DTA tokenizer wrappers: cx data

package DTA::TokWrap::CxData;
use DTA::TokWrap::Version;
use version;

use Carp;
use strict;

##==============================================================================
## Constants
##==============================================================================

##-- cxRecordType
our @cxType2Name = qw(c lb pb formula EOF);
our %cxName2Type = map {($cxType2Name[$_]=>$_)} (0..$#cxType2Name);
our ($cxrChar,$cxrLb,$cxrPb,$cxrFormula,$cxrEOF) = @cxName2Type{qw(c lb pb formula EOF)};

##-- flags
our $cxfTypeMask     = 0x7;
our $cxfHasXmlOffset = 0x8;
our $cxfHasTxtLength = 0x10;
our $cxfHasAttrs     = 0x20;

##-- header
our $cxhMagic = "dta-tokwrap cx bin\n";
our $cxhVersion     = $DTA::TokWrap::Version::VERSION;
our $cxhVersionMinR = "0.39"; ##-- minimum file-version we can read

##-- records: indexing of returned arrays
our $CX_FLAGS = 0;
our $CX_XOFF  = 1;
our $CX_XLEN  = 2;
our $CX_TLEN  = 3;
our $CX_ATTRS = 4;

##-- indexing: attrs: $cxrPb
our $CX_ATTR_FACS = $CX_ATTRS;

##-- indexing: attrs: $cxrChar
our $CX_ATTR_ULX = $CX_ATTRS;
our $CX_ATTR_ULY = $CX_ATTRS+1;
our $CX_ATTR_LRX = $CX_ATTRS+2;
our $CX_ATTR_LRY = $CX_ATTRS+3;

##==============================================================================
## Functions
##==============================================================================

## \%hdr = cx_get_header($fh)
##  + reads and parses header from $fh
sub cx_get_header {
  my $fh = shift;
  my $len = 32+8+8; ##-- header length: magic[32]+version[8]+version_min[8]
  read($fh, my $buf, $len)==$len
    or die("failed to read cx header");

  my %h = qw();
  @h{qw(magic version version_min)} = unpack('(Z32)(Z8)(Z8)', $buf);
  return \%h;
}

## $bool = cx_check_header($hdr)
##  + die()s on error
sub cx_check_header {
  my ($hdr) = @_;

  ##-- check: magic
  die("bad magic '$hdr->{magic}' in cx-file") if ($cxhMagic ne $hdr->{magic});

  ##-- check: versions
  my $xv    = version->new("$cxhVersion");
  my $xvmin = version->new("$cxhVersionMinR");
  my $hv    = version->new("$hdr->{version}");
  my $hvmin = version->new("$hdr->{version_min}");

  die("cx-file requires v$hvmin, but we have only v$xv") if ($hvmin > $xv);
  die("we require v$xvmin, but cx-file is only v$hv") if ($xvmin > $hv);

  return 1;
}

## [$flags,$xoff,$xlen,$tlen,@attrs] = cx_get($fh)
## [$flags,$xoff,$xlen,$tlen,@attrs] = cx_get($fh,$xmlOffset)
##  + uses package-global temporaries: $_tmp,$_flags,$_cx
my ($_tmp,$_flags,$_cx);
sub cx_get_record {
  $_cx = [$cxrEOF];

  ##-- flags
  read($_[0],$_tmp,1)==1 or return $_cx;
  $_flags = $_cx->[$CX_FLAGS] = ord($_tmp);

  ##-- xoff
  if ($_flags & $cxfHasXmlOffset) {
    read($_[0],$_tmp,4);
    $_cx->[$CX_XOFF] = unpack('L',$_tmp);
  } else {
    $_cx->[$CX_XOFF] = exists($_[1]) ? $_[1] : 0;
  }

  ##-- xlen
  read($_[0],$_tmp,1);
  $_cx->[$CX_XLEN] = ord($_tmp);

  ##-- tlen
  if ($_flags & $cxfHasTxtLength) {
    read($_[0],$_tmp,1);
    $_cx->[$CX_TLEN] = ord($_tmp);
  } else {
    $_cx->[$CX_TLEN] = $_cx->[$CX_XLEN];
  }

  ##-- attrs
  if ($_flags & $cxfHasAttrs) {
    if (($_flags & $cxfTypeMask) == $cxrChar) {
      read($_[0],$_tmp,16);
      @$_cx[$CX_ATTRS..($CX_ATTRS+3)] = unpack('L4',$_tmp);
    }
    elsif (($_flags & $cxfTypeMask) == $cxrPb) {
      read($_[0],$_tmp,4);
      $_cx->[$CX_ATTRS] = unpack('L',$_tmp);
    }
  }

  return $_cx;
}

## \@cxRecords = cx_slurp($filename_or_fh)
sub cx_slurp {
  my $file = shift;
  my ($fh);
  if (ref($file)) {
    $fh = $file;
  } else {
    open($fh,"<$file") or die("cx_slurp(): open failed for file '$file': $!");
  }

  ##-- get & check header
  my $hdr = cx_get_header($fh);
  cx_check_header($hdr) or die("cx_slurp(): bad header for file '$file': $!");

  my $xmlOffset = 0;
  my @data      = qw();
  my ($cx);
  while (!eof($fh)) {
    push(@data, $cx=cx_get_record($fh,$xmlOffset));
    $xmlOffset = $cx->[$CX_XOFF] + $cx->[$CX_XLEN];
  }
  close($fh) if (!ref($file));

  return \@data;
}


##==============================================================================
## Exports
##==============================================================================
our @ISA = qw(Exporter);

our @EXPORT = qw();
our %EXPORT_TAGS = (
		    const => [
			      qw(@cxType2Name %cxName2Type $cxrChar $cxrLb $cxrPb $cxrFormula $cxrEOF),
			      qw($cxfTypeMask $cxfHasXmlOffset $cxfHasTxtLength $cxfHasAttrs),
			      qw($cxhMagic $cxhVersion $cxhVersionMinR),
			      qw($CX_FLAGS $CX_XOFF $CX_XLEN $CX_TLEN $CX_ATTRS),
			      qw($CX_ATTR_FACS $CX_ATTR_ULX $CX_ATTR_ULY $CX_ATTR_LRX $CX_ATTR_LRY),
			     ],
		    func  => [qw(cx_get_header cx_check_header cx_get_record cx_slurp)],
		   );
$EXPORT_TAGS{all} = [map {@$_} values(%EXPORT_TAGS)];
our @EXPORT_OK = @{$EXPORT_TAGS{all}};



1; ##-- be happy

__END__

##========================================================================
## POD DOCUMENTATION
=pod

=cut

##========================================================================
## NAME
=pod

=head1 NAME

DTA::TokWrap::CxData - DTA tokenizer wrappers: utilities for binary cx-file I/O

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 use DTA::TokWrap::CxData;
 
 # ... use the source luke ...


=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

DTA::TokWrap::CxData provides some utilities for dealing with
*.cx files as written by the dtatw-mkindex(1) program.

=cut


##======================================================================
## See Also
##======================================================================

=pod

=head1 SEE ALSO

L<DTA::TokWrap::Intro(3pm)|DTA::TokWrap::Intro>,
L<DTA::TokWrap::Processor::mkindex(3pm)|DTA::TokWrap::Processor::mkindex>,
L<dta-tokwrap.perl(1)|dta-tokwrap.perl>,
...

=cut

##======================================================================
## See Also
##======================================================================

=pod

=head1 SEE ALSO

L<DTA::TokWrap::Intro(3pm)|DTA::TokWrap::Intro>,
L<dta-tokwrap.perl(1)|dta-tokwrap.perl>,
...

=cut

##======================================================================
## Footer
##======================================================================

=pod

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2018 by Bryan Jurish

This package is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut


