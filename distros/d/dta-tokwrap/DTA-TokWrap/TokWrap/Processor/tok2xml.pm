## -*- Mode: CPerl; coding: utf-8; -*-

## File: DTA::TokWrap::Processor::tok2xml.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Descript: DTA tokenizer wrappers: t -> t.xml, via dtatw-tok2xml

package DTA::TokWrap::Processor::tok2xml;

use DTA::TokWrap::Version;
use DTA::TokWrap::Base;
use DTA::TokWrap::Utils qw(:progs :files :slurp :time);
use DTA::TokWrap::Processor;

use IO::File;
use Carp;
use strict;
use utf8;

##==============================================================================
## Constants
##==============================================================================
our @ISA = qw(DTA::TokWrap::Processor);

##==============================================================================
## Constructors etc.
##==============================================================================

## $t2x = CLASS_OR_OBJ->new(%args)
## %defaults = CLASS->defaults()
##  + static class-dependent defaults
##  + %args, %defaults, %$t2x:
##    (
##    txmlsort => $bool,	     ##-- if true (default), sort output .t.xml data as close to input document-order as __paragraph__ boundaries will allow
##    txmlsort_bysentence => $bool,  ##-- use old sentence-level sort (default: false)
##    txmlextids => $bool,           ##-- if true, attempt to parse "<a>$SID/$WID</a>" pseudo-analyses as IDs (default:true; uses regex hack)
##    t2x => $path_to_dtatw_tok2xml, ##-- default: search
##    b2xb => $path_to_dtatw_b2xb,   ##-- default: search; 'off' to disable
##    inplace => $bool,              ##-- prefer in-place programs for search?
##    )
sub defaults {
  my $that = shift;
  return (
	  ##-- inherited
	  $that->SUPER::defaults(),

	  ##-- sorting?
	  txmlsort => 1,
	  #txmlsort_bysentence => 0,
	  txmlextids => 1,

	  ##-- programs
	  t2x => undef,
	  b2xb => undef,
	  inplace => 1,
	 );
}

## $t2x = $t2x->init()
##  compute dynamic object-dependent defaults
sub init {
  my $t2x = shift;

  ##-- search for program(s)
  if (!defined($t2x->{t2x})) {
    $t2x->{t2x} = path_prog('dtatw-tok2xml',
			    prepend=>($t2x->{inplace} ? ['.','../src'] : undef),
			    warnsub=>sub {$t2x->logconfess(@_)},
			   );
  }

  if (!defined($t2x->{b2xb})) {
    $t2x->{b2xb} = path_prog('dtatw-b2xb',
			    prepend=>($t2x->{inplace} ? ['.','../src'] : undef),
			    warnsub=>sub {$t2x->logconfess(@_)},
			   );
  }

  return $t2x;
}

##==============================================================================
## Methods: Document Processing
##==============================================================================

## $doc_or_undef = $CLASS_OR_OBJECT->tok2xml($doc)
## $doc_or_undef = $CLASS_OR_OBJECT->tok2xml($doc,%opts)
## + $doc is a DTA::TokWrap::Document object
## + %opts:
##     tokfilekey => $tokfilekey,   ##-- document key for tokenized file (default='tokfile1')
##     xtokdatakey => $xtokdatakey, ##-- document key for tokenized data (default='xtokdata')
##     %t2x_options,                ##-- ... other options override %$t2x sort defaults
## + %$doc keys:
##    $tokfilekey  => $tokfile1,  ##-- (input) tokenizer output file, must already be populated
##    cxfile       => $cxfile,    ##-- (input) character index file, must already be populated
##    bxfile       => $bxfile,    ##-- (input) block index data file, must already be populated
##    $xtokdatakey => $xtokdata,  ##-- (output) tokenizer output as XML (string)
##    tok2xml_stamp0 => $f,       ##-- (output) timestamp of operation begin
##    tok2xml_stamp  => $f,       ##-- (output) timestamp of operation end
##    xtokdata_stamp => $f,       ##-- (output) timestamp of operation end
sub tok2xml {
  my ($t2x,$doc,%opts) = @_;
  $doc->setLogContext();

  ##-- log, stamp
  $t2x->vlog($t2x->{traceLevel},"tok2xml()");
  $doc->{tok2xml_stamp0} = timestamp();

  ##-- defaults
  my $tokfilekey  = $opts{tokfilekey} // $t2x->{tokfilekey} // 'tokfile1';
  my $xtokdatakey = $opts{xtokdatakey} // $t2x->{xtokdatakey} // 'xtokdata';

  ##-- sanity check(s)
  $t2x = $t2x->new() if (!ref($t2x));
  ##
  $t2x->logconfess("tok2xml(): no cxfile key defined") if (!$doc->{cxfile});
  $t2x->logconfess("tok2xml(): no bxfile key defined") if (!$doc->{bxfile});
  $t2x->logconfess("tok2xml(): no tokfilekey {$tokfilekey} key defined") if (!$doc->{$tokfilekey});
  ##
  file_try_open($doc->{cxfile}) || $t2x->logconfess("tok2xml(): could not open .cx file '$doc->{cxfile}': $!");
  file_try_open($doc->{bxfile}) || $t2x->logconfess("tok2xml(): could not open .bx file '$doc->{bxfile}': $!");
  file_try_open($doc->{$tokfilekey}) || $t2x->logconfess("tok2xml(): could not open .t1 file '$doc->{$tokfilekey}': $!");

  ##-- run client program(s)
  my ($cmd);
  if ($t2x->{b2xb} ne 'off') {
    $t2x->vlog($t2x->{traceLevel},"command: $t2x->{b2xb} | $t2x->{t2x}");
    $cmd = "'$t2x->{b2xb}' '$doc->{$tokfilekey}' '$doc->{cxfile}' '$doc->{bxfile}' - | '$t2x->{t2x}' - - '$doc->{xmlbase}' |";
  } else {
    $t2x->vlog($t2x->{traceLevel},"command: $t2x->{t2x}");
    $cmd = "'$t2x->{t2x}' '$doc->{$tokfilekey}' - '$doc->{xmlbase}' |";
  }
  my $cmdfh = opencmd("$cmd")
    or $t2x->logconfess("tok2xml(): open failed for pipe '$t2x->{b2xb}'|'$t2x->{t2x}'|: $!");
  $doc->{$xtokdatakey} = undef;
  slurp_fh($cmdfh,\$doc->{$xtokdatakey});
  $cmdfh->close();

  ##-- re-sort?
  if ($opts{txmlsort_bysentence}//$t2x->{txmlsort_bysentence}) {
    ##-- sort by sentence (< v0.49)
    $t2x->vlog($t2x->{traceLevel},"sort (by sentence)");
    my $data = \$doc->{$xtokdatakey};
    my ($off,$len,$xb);
    my @s = qw();  ##-- ([xml_off0, txml_off, txml_len], ...)
    while ($$data =~ m{<s\b[^>]*>.*?</s>\s*}sg) {
      ($off,$len) = ($-[0],$+[0]-$-[0]);
      $xb = substr($$data, $off,$len) =~ m{<w[^>]*\bxb="([0-9]+)}s ? $1 : 1e38;
      push(@s,[$xb,$off,$len]);
    }
    my $prefix = substr($$data,0,$s[0][1]);
    my $suffix = substr($$data,$s[$#s][1]+$s[$#s][2]);
    my $sorted = $prefix.join('',map {substr($$data,$_->[1],$_->[2])} sort {$a->[0]<=>$b->[0]} @s).$suffix;
    $$data = $sorted;
  }
  elsif ($opts{txmlsort}//$t2x->{txmlsort}) {
    ##-- sort by paragraph (>= v0.49)
    $t2x->vlog($t2x->{traceLevel},"sort (by paragraph)");
    my $data = \$doc->{$xtokdatakey};
    open(my $fh,"<",$data) or die("could not open string filehandle: $!");
    my @p   = qw(); ##-- ([xml_off0, txml_off, txml_len], ...)
    my $pid = '';
    my $off = 0;
    my $lasteos = 0;
    my ($pr,$buf);
    while (defined($_=<$fh>)) {
      if (/<s[^>]*\bpn=\"([^\"]*)\"/ && $1 ne $pid) {
	$pr->[2] = $off-$pr->[1] if ($pr);
	push(@p,$pr=[undef,$off,undef]);
	$pid = $1;
      }
      elsif (/<\/s>/) {
	$lasteos = $off + bytes::length($_);
      }
    } continue {
      $off += bytes::length($_);
    }
    $pr->[2] = $lasteos-$pr->[1] if ($pr);

    ##-- get original xml offset for each paragraph
    foreach (@p) {
      $_->[0] = substr($$data, $_->[1],$_->[2]) =~ m{<w[^>]*\bxb="([0-9]+)}s ? $1 : 1e38;
    }

    ##-- prefix, suffix, sort: by paragraph
    if (@p) {
      my $prefix = substr($$data,0,$p[0][1]);
      my $suffix = substr($$data,$lasteos);
      my $sorted = $prefix.join('',map {substr($$data,$_->[1],$_->[2])} sort {$a->[0]<=>$b->[0]} @p).$suffix;
      $$data = $sorted;
    }
  }

  ##-- parse external IDs
  if ($opts{txmlextids}//$t2x->{txmlextids}) {
    $t2x->vlog($t2x->{traceLevel},"parse external IDs");
    my $data = \$doc->{$xtokdatakey};

    ##-- split into sentences
    my ($off,$len);
    my @sloc = qw();  ##-- ([txml_off, txml_len], ...)
    while ($$data =~ m{<s\b[^\>]*>.*?</s>\s*}sg) {
      push(@sloc,[$-[0], $+[0]-$-[0]]);
    }
    my $prefix = substr($$data,0,$sloc[0][0]);
    my $suffix = substr($$data,$sloc[$#sloc][0]+$sloc[$#sloc][1]);

    ##-- parse IDs
    my ($s,$sid);
    my $parsed = ($prefix
		  .join('',
			map {
			  ($off,$len) = @$_;
			  $s = substr($$data,$off,$len);
			  $s =~ s{<s([^>]*)id="[^"]*"(.*?)<a>(\w*)/(\w*)</a>}{<s${1}id="${3}"${2}<a>${3}/${4}</a>}s;
			  $s =~ s{<w(.*?)\bid="[^"]*"(.*?)<a>\w*/(\w*)</a>}{<w${1}id="${3}"${2}}g;
			  $s =~ s{<toka></toka>}{}g;
			  $s =~ s{<w([^>]*)></w>}{<w$1/>}g;
			  $s
			} @sloc)
		  .$suffix);
    $$data = $parsed;
  }

  ##-- finalize
  $doc->{tok2xml_stamp} = $doc->{"${xtokdatakey}_stamp"} = timestamp(); ##-- stamp
  return $doc;
}

1; ##-- be happy
__END__

##========================================================================
## POD DOCUMENTATION, auto-generated by podextract.perl

##========================================================================
## NAME
=pod

=head1 NAME

DTA::TokWrap::Processor::tok2xml - DTA tokenizer wrappers: t -> t.xml

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 use DTA::TokWrap::Processor::tok2xml;
 
 $t2x = DTA::TokWrap::Processor::tok2xml->new(%opts);
 $doc_or_undef = $t2x->tok2xml($doc);

=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

DTA::TokWrap::Processor::tok2xml provides an object-oriented
L<DTA::TokWrap::Processor|DTA::TokWrap::Processor> wrapper
for converting "raw" CSV-format (.t) low-level tokenizer output
to a "master" tokenized XML (.t.xml) format,
for use with L<DTA::TokWrap::Document|DTA::TokWrap::Document> objects.

Most users should use the high-level
L<DTA::TokWrap|DTA::TokWrap> wrapper class
instead of using this module directly.

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::TokWrap::Processor::tok2xml: Constants
=pod

=head2 Constants

=over 4

=item @ISA

DTA::TokWrap::Processor::tok2xml
inherits from
L<DTA::TokWrap::Processor|DTA::TokWrap::Processor>.

=item $NOC

Integer indicating a missing or implicit 'c' record;
should be equivalent in value to the C code:

 unsigned int NOC = ((unsigned int)-1)

for 32-bit "unsigned int"s.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::TokWrap::Processor::tok2xml: Constructors etc.
=pod

=head2 Constructors etc.

=over 4

=item new

 $t2x = $CLASS_OR_OBJECT->new(%args);

Constructor.

%args, %$t2x:

  txmlsort => $bool,             ##-- if true (default), sort output .t.xml data as close to input document-order as __paragraph__ boundaries will allow
  txmlsort_bysentence => $bool,  ##-- use old sentence-level sort (default: false)
  txmlextids => $bool,           ##-- if true, attempt to parse "<a>$SID/$WID</a>" pseudo-analyses as IDs (default:true; uses regex hack)
  t2x => $path_to_dtatw_tok2xml, ##-- default: search
  b2xb => $path_to_dtatw_b2xb,   ##-- default: search; 'off' to disable
  inplace => $bool,              ##-- prefer in-place programs for search?

You probably should B<NOT> change any of the default output document
structure options (unless this is the final module in your
processing pipeline), since their values have ramifications beyond
this module.

=item defaults

 %defaults = CLASS->defaults();

Static class-dependent defaults.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::TokWrap::Processor::tok2xml: Methods: tok2xml (bx0doc, txfile) => bxdata
=pod

=head2 Methods: tok2xml (bxdata, tokdata1, cxdata) =E<gt> xtokdata

=over 4

=item tok2xml

 $doc_or_undef = $CLASS_OR_OBJECT->tok2xml($doc);
 $doc_or_undef = $CLASS_OR_OBJECT->tok2xml($doc,%opts);

Converts "raw" CSV-format (.t) low-level tokenizer output
to a "master" tokenized XML (.t.xml) format
in the
L<DTA::TokWrap::Document|DTA::TokWrap::Document> object
$doc.
If specified, %opts override $CLASS_OR_OBJECT sorting and parsing defaults.

Relevant %$doc keys:

 bxdata        => \@bxdata,   ##-- (input) block index data
 $tokfile_key  => $tokfile,  ##-- (input) tokenizer output filename (default='tokfile1')
 cxdata        => \@cxchrs,   ##-- (input) character index data (array of arrays)
 cxfile        => $cxfile,    ##-- (input) character index file
 $xtokdata_key => $xtokdata,  ##-- (output) tokenizer output as XML (default='xtokdata')
 nchrs         => $nchrs,     ##-- (output) number of character index records
 ntoks         => $ntoks,     ##-- (output) number of tokens parsed
 ##
 tok2xml_stamp0 => $f,   ##-- (output) timestamp of operation begin
 tok2xml_stamp  => $f,   ##-- (output) timestamp of operation end
 xtokdata_stamp => $f,   ##-- (output) timestamp of operation end


=back

=cut

##========================================================================
## END POD DOCUMENTATION, auto-generated by podextract.perl

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


