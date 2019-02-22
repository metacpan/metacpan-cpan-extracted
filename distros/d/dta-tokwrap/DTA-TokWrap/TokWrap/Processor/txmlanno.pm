## -*- Mode: CPerl; coding: utf-8; -*-

## File: DTA::TokWrap::Processor::txmlanno.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Descript: DTA tokenizer wrappers: t.xml -> t.xml, via idsplice

package DTA::TokWrap::Processor::txmlanno;

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

## $txa = CLASS_OR_OBJ->new(%args)
## %defaults = CLASS->defaults()
##  + static class-dependent defaults
##  + %args, %defaults, %$x2a:
##    (
##     annojoin=>$bool,   ##-- if true, add TEI att.linguistic 'join' feature (default:false; uses regex hack)
##    )
sub defaults {
  my $that = shift;
  return (
	  ##-- inherited
	  $that->SUPER::defaults(),

	  'annojoin'=>0,
	 );
}

## $txa = $txa->init()
##  + compute dynamic object-dependent defaults
##  + inherited from Base.pm

##==============================================================================
## Methods: Document Processing
##==============================================================================

## $doc_or_undef = $CLASS_OR_OBJECT->txmlanno($doc)
## $doc_or_undef = $CLASS_OR_OBJECT->txmlanno($doc,%opts)
## + $doc is a DTA::TokWrap::Document object
## + %opts:
##     %txa_options,                ##-- ... options override %$txa sort defaults
## + %$doc keys:
##    axtokdatakey => $axdatakey, ##-- (input) XML annotation data key (default='axtokdata')
##    axtokdata    => $axtokdata, ##-- (input) XML annotations to be spliced in (optional)
##    xtokdata     => $xtokdata,  ##-- (input)  un-annotated XML-ified tokenizer output data
##                                ##-- (output) annotated XML-ified tokenizer output data
##    xtokfile0    => $xtokfile0, ##-- (output) save original $xtokdata (optional)
##    txmlanno_stamp0 => $f,      ##-- (output) timestamp of operation begin
##    txmlanno_stamp  => $f,      ##-- (output) timestamp of operation end
##    xtokdata_stamp => $f,       ##-- (output) timestamp of operation end
sub txmlanno {
  my ($txa,$doc,%opts) = @_;
  $doc->setLogContext();

  ##-- log, stamp
  $txa->vlog($txa->{traceLevel},"txmlanno()");
  $doc->{txmlanno_stamp0} = timestamp();

  ##-- sanity check(s)
  $txa = $txa->new() if (!ref($txa));
  ##
  $txa->logconfess("txmlanno(): no xtokdata key defined") if (!$doc->{xtokdata});

  ##-- check for no-op
  my $axtokdatakey = $opts{axtokdatakey} // $txa->{axtokdatakey} // 'axtokdata';
  my $do_join   = $opts{annojoin}//$txa->{annojoin};
  my $do_splice = defined($doc->{$axtokdatakey});
  if ($do_join || $do_splice) {
    ##-- save original xtokfile0
    $doc->saveFileData('xtok','0',$doc->{xtokfile0},\$doc->{xtokdata}) if ($doc->{xtokfile0});
  } else {
    $txa->vlog($txa->{traceLevel},"txmlanno(): nothing to do");
  }

  ##-- compute TEI att.linguistic 'join' attribute?
  if ($opts{annojoin}//$txa->{annojoin}) {
    $txa->vlog($txa->{traceLevel},"txmlanno(): populate //w/\@join attribute");
    my $data = \$doc->{xtokdata};

    ##-- split into tokens
    my ($off,$len);
    my @wloc = qw();  ##-- ([txml_off,txml_len, txt_beg,txt_end, JOIN], ...)
    while ($$data =~ m{<w\b[^\>]*?\sb=\"([0-9]+) ([0-9]+)\"[^\>]*(?:/>|>.*?</w>)\s*}sg) {
      push(@wloc,[$-[0], $+[0]-$-[0], $1,$1+$2]);
    }
    my $prefix = substr($$data,0,$wloc[0][0]);
    my $suffix = substr($$data,$wloc[$#wloc][0]+$wloc[$#wloc][1]);

    ##-- compute & apply //w/@join
    if (@wloc) {
      my ($wi,$loc_cur,$loc_prev,$loc_next);
      $loc_prev = undef;
      $loc_cur  = $wloc[0];
      for ($wi=0; $wi <= $#wloc; ++$wi) {
	$loc_next = $wloc[$wi+1];
	$loc_cur->[4] = ($loc_prev    && $loc_cur->[2] == $loc_prev->[3]
			 ? ($loc_next && $loc_cur->[3] == $loc_next->[2]
			    ? 'both'
			    : 'left')
			 : ($loc_next && $loc_cur->[3] == $loc_next->[2]
			    ? 'right'
			    : undef));
	$loc_prev = $loc_cur;
	$loc_cur  = $loc_next;
      }

      ##-- apply
      my ($w,$wprefix,$join);
      my $off_prev = $wloc[0][0]+$wloc[0][1];
      my $parsed = ($prefix
		    .join('',
			  map {
			    ($off,$len,$join) = @$_[0,1,4];
			    $wprefix  = ($off > $off_prev ? substr($$data,$off_prev,$off-$off_prev) : '');
			    $off_prev = $off+$len;

			    $w = substr($$data,$off,$len);
			    $w =~ s{(/?>)}{ join="$join"$1} if ($join);
			    $wprefix . $w;
			  } @wloc)
		    .$suffix);
      $$data = $parsed;
    } else {
      $txa->vlog('warn', "txmlanno(): no //w/\@b locations found");
    }
  }
  else {
    $txa->vlog($txa->{traceLevel}, "txmlanno(): NOT computing //w/\@join (set option annojoin=1 to enable)");
  }

  ##-- splice in annotations by idsplice proxy if requested
  if (defined($doc->{$axtokdatakey})) {
    $txa->vlog($txa->{traceLevel}, "txmlanno(): splicing in external annotations from {$axtokdatakey} buffer");

    my $idsplice = ($doc->{tw} && $doc->{tw}{idsplice}) || DTA::TokWrap::Processor::idsplice->new();
    my $inbufr   = \$doc->{xtokdata};
    delete $doc->{xtokdata};
    $idsplice->splice_so(base => $inbufr,
			 so   => \$doc->{$axtokdatakey},
			 out  => \$doc->{xtokdata},
			 basename => $doc->{xtokfile},
			)
      or $txa->logconfess("txmlanno(): failed to splice annotations from {$axtokdatakey} buffer");
  } else {
    $txa->vlog($txa->{traceLevel}, "txmlanno(): no external annotations available - skipping");
  }

  ##-- finalize
  $doc->{txmlanno_stamp} = $doc->{"xtokdata_stamp"} = timestamp(); ##-- stamp
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

DTA::TokWrap::Processor::txmlanno - Descript: DTA tokenizer wrappers: t.xml -E<gt> t.xml, via idsplice

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 use DTA::TokWrap::Processor::txmlanno;
 
 $txa = DTA::TokWrap::Processor::txmlanno->new(%opts);
 $doc_or_undef = $CLASS_OR_OBJECT->txmlanno($doc);
 

=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

DTA::TokWrap::Processor::txmlanno provides an object-oriented
L<DTA::TokWrap::Processor|DTA::TokWrap::Processor> wrapper
for adding annotations to a "master" tokenized XML (.t.xml) format,
for use with L<DTA::TokWrap::Document|DTA::TokWrap::Document> objects.

Most users should use the high-level
L<DTA::TokWrap|DTA::TokWrap> wrapper class
instead of using this module directly.

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::TokWrap::Processor::txmlanno: Constants
=pod

=head2 Constants

=over 4

=item Variable: @ISA

DTA::TokWrap::Processor::txmlanno
inherits from
L<DTA::TokWrap::Processor|DTA::TokWrap::Processor>.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::TokWrap::Processor::txmlanno: Constructors etc.
=pod

=head2 Constructors etc.

=over 4

=item new

 $txa = $CLASS_OR_OBJECT_>new(%args);

Constructor.

%args, %$t2x:

 annojoin=>$bool,   ##-- if true, add TEI att.linguistic 'join' feature (default:false; uses regex hack)


=item defaults

 %defaults = CLASS->defaults();

Static class-dependent defaults.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::TokWrap::Processor::txmlanno: Methods: Document Processing
=pod

=head2 Methods: Document Processing

=over 4

=item txmlanno

 $doc_or_undef = $CLASS_OR_OBJECT->txmlanno($doc);
 $doc_or_undef = $CLASS_OR_OBJECT->txmlanno($doc,%opts);

Inserts supplementary annotations into "master" tokenized XML (.t.xml)
in the L<DTA::TokWrap::Document|DTA::TokWrap::Document> object
$doc.
If specified, %opts override $CLASS_OR_OBJECT sorting and parsing defaults.

Relevant %$doc keys:

 axtokdatakey => $axdatakey, ##-- (input) XML annotation data key (default='axtokdata')
 axtokdata    => $axtokdata, ##-- (input) XML annotations to be spliced in (optional)
 xtokdata     => $xtokdata,  ##-- (input+output)
                             ##   + input  : un-annotated XML-ified tokenizer output data
                             ##   + output : annotated XML-ified tokenizer output data

 xtokfile0 => $xtokfile0,    ##-- (output) save original $xtokdata (optional)
 txmlanno_stamp0 => $f,      ##-- (output) timestamp of operation begin
 txmlanno_stamp  => $f,      ##-- (output) timestamp of operation end
 xtokdata_stamp  => $f,      ##-- (output) timestamp of operation end

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
## Footer
##======================================================================

=pod

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018 by Bryan Jurish

This package is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
