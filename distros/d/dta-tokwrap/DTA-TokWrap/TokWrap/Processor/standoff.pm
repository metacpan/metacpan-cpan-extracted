## -*- Mode: CPerl -*-

## File: DTA::TokWrap::Processor::standoff
## Author: Bryan Jurish <moocow@cpan.org>
## Description: DTA tokenizer wrappers: t.xml -> (s.xml, w.xml, a.xml) via dtatw-txml2[swa]xml

package DTA::TokWrap::Processor::standoff;

use DTA::TokWrap::Version;
use DTA::TokWrap::Base;
use DTA::TokWrap::Utils qw(:progs :time);
use DTA::TokWrap::Processor;

use File::Basename qw(basename dirname);

use Carp;
use strict;

##==============================================================================
## Constants
##==============================================================================
our @ISA = qw(DTA::TokWrap::Processor);

##==============================================================================
## Constructors etc.
##==============================================================================

## $so = CLASS_OR_OBJ->new(%args)
##  + %args:
##    t2w => $path_to_dtatw_txml2wxml, ##-- default: search
##    t2s => $path_to_dtatw_txml2sxml, ##-- default: search
##    t2a => $path_to_dtatw_txml2axml, ##-- default: search
##    inplace => $bool,                ##-- prefer in-place programs for search?

## %defaults = CLASS->defaults()
sub defaults {
  my $that = shift;
  return (
	  $that->SUPER::defaults(),
	  t2w=>undef,
	  t2s=>undef,
	  t2a=>undef,
	  inplace=>1,
	 );
}

## $so = $so->init()
sub init {
  my $so = shift;

  ##-- search for program(s)
  foreach ('s','w','a') {
    if (!defined($so->{"t2$_"})) {
      $so->{"t2$_"} = path_prog("dtatw-txml2${_}xml",
				prepend=>($so->{inplace} ? ['.','../src'] : undef),
				warnsub=>sub {$so->logconfess(@_)},
			       );
    }
  }

  return $so;
}

##==============================================================================
## Methods: Backwards-compatible
##==============================================================================

## $so_xsl = $so->_xsl()
sub _xsl {
  require DTA::TokWrap::Processor::standoff::xsl;
  return $_[0]{_xsl} if (defined($_[0]{_xsl}));
  return $_[0]{_xsl} = DTA::TokWrap::Processor::standoff::xsl->new(%{$_[0]});
}

## $so_or_undef = $so->ensure_stylesheets()
sub ensure_stylesheets { $_[0]->_xsl->ensure_stylesheets(); }

## $str = $so->t2s_stylestr()
sub t2s_stylestr { $_[0]->_xsl->t2s_stylestr(); }

## $str = $so->t2w_stylestr()
sub t2w_stylestr { $_[0]->_xsl->t2w_stylestr(); }

## $str = $so->t2a_stylestr()
sub t2a_stylestr { $_[0]->_xsl->t2a_stylestr(); }


## undef = $so->dump_t2s_stylesheet($filename_or_fh)
sub dump_t2s_stylesheet { $_[0]->_xsl->dump_t2s_stylesheet(@_[1..$#_]); }

## undef = $so->dump_t2w_stylesheet($filename_or_fh)
sub dump_t2w_stylesheet { $_[0]->_xsl->dump_t2w_stylesheet(@_[1..$#_]); }

## undef = $so->dump_t2a_stylesheet($filename_or_fh)
sub dump_t2a_stylesheet { $_[0]->_xsl->dump_t2a_stylesheet(@_[1..$#_]); }

##==============================================================================
## Methods: document processing
##==============================================================================

## $doc_or_undef = $CLASS_OR_OBJECT->standoff($doc)
##  + wrapper for sosxml, sowxml, soaxml
sub standoff {
  my ($so,$doc) = @_;
  return $so->sosxml($doc) && $so->sowxml($doc) && $so->soaxml($doc);
}

## $doc_or_undef = $CLASS_OR_OBJECT->soxml($doc,$X,$xmlbase)
## + generic formatter
## + $doc is a DTA::TokWrap::Document object
## + $X is a known standoff infix character ('s', 'w', or 'a')
## + $xml_base is the /*/@xml:base attribute to use (default = $doc->{xmlbase})
## + (re-)creates ${X}.xml standoff FILE $doc->{so${X}file} from .t.xml source STRING $doc->{xtokdata}
## + %$doc keys:
##    xtokdata => $xtokdata, ##-- (input) XML-ified tokenizer output data (string)
##    so${X}file  => $sosfile,  ##-- (output) standoff file, refers to $xml_base
##    so${X}xml_stamp0 => $f,   ##-- (output) timestamp of operation begin
##    so${X}xml_stamp  => $f,   ##-- (output) timestamp of operation end
##    so${X}file_stamp => $f,   ##-- (output) timestamp of operation end
sub soxml {
  my ($so,$doc,$X,$xmlbase) = @_;
  my $method = "so${X}xml";
  $doc->setLogContext();

  ##-- log, stamp
  $so->vlog($so->{traceLevel},"$method()");
  $doc->{"${method}_stamp0"} = timestamp();

  ##-- sanity check(s)
  $so = $so->new() if (!ref($so));
  $so->logconfess("$method(): no document key 'xtokdata' defined")
    if (!$doc->{xtokdata});
  my $t2x = $so->{"t2${X}"};
  $so->logconfess("$method(): no processor key 't2${X}' defined!")
    if (!defined($t2x));
  my $sofile = $doc->{"so${X}file"};
  $so->logconfess("$method(): no document key 'so${X}file' defined!")
    if (!defined($sofile));

  ##-- run command
  $xmlbase = $doc->{xmlbase} if (!defined($xmlbase));
  my $cmdfh = opencmd("| '$t2x' - '$sofile' '$xmlbase'")
    or $so->logconfess("${method}(): open failed for pipe to '$t2x': $!");
  $cmdfh->print($doc->{xtokdata});
  $cmdfh->close();

  $doc->{"${method}_stamp"} = $doc->{"so${X}file_stamp"} = timestamp(); ##-- stamp
  return $doc;
}

## $doc_or_undef = $CLASS_OR_OBJECT->sosxml($doc)
## + $doc is a DTA::TokWrap::Document object
## + (re-)creates s.xml standoff FILE $doc->{sosfile} from .t.xml source STRING $doc->{xtokdata}
## + %$doc keys:
##    xtokdata => $xtokdata, ##-- (input) XML-ified tokenizer output data (string)
##    sosfile  => $sosfile,  ##-- (output) standoff sentence file, refers to 'sowfile'
##    sosxml_stamp0 => $f,   ##-- (output) timestamp of operation begin
##    sosxml_stamp  => $f,   ##-- (output) timestamp of operation end
##    sosfile_stamp => $f,   ##-- (output) timestamp of operation end
sub sosxml {
  my ($so,$doc) = @_;
  return $so->soxml($doc,'s',basename($doc->{sowfile}));
}

## $doc_or_undef = $CLASS_OR_OBJECT->sowxml($doc)
## + $doc is a DTA::TokWrap::Document object
## + (re-)creates s.xml standoff FILE $doc->{sowfile} from .t.xml source STRING $doc->{xtokdata}
## + %$doc keys:
##    xtokdata => $xtokdata, ##-- (input) XML-ified tokenizer output data (string)
##    sowfile  => $sowfile,  ##-- (output) standoff sentence file, refers to 'sowfile'
##    sowxml_stamp0 => $f,   ##-- (output) timestamp of operation begin
##    sowxml_stamp  => $f,   ##-- (output) timestamp of operation end
##    sowfile_stamp => $f,   ##-- (output) timestamp of operation end
sub sowxml {
  my ($so,$doc) = @_;
  return $so->soxml($doc,'w',$doc->{xmlbase});
}

## $doc_or_undef = $CLASS_OR_OBJECT->soaxml($doc)
## + $doc is a DTA::TokWrap::Document object
## + (re-)creates s.xml standoff FILE $doc->{soafile} from .t.xml source STRING $doc->{xtokdata}
## + %$doc keys:
##    xtokdata => $xtokdata, ##-- (input) XML-ified tokenizer output data (string)
##    soafile  => $soafile,  ##-- (output) standoff sentence file, refers to 'soafile'
##    soaxml_stamp0 => $f,   ##-- (output) timestamp of operation begin
##    soaxml_stamp  => $f,   ##-- (output) timestamp of operation end
##    soafile_stamp => $f,   ##-- (output) timestamp of operation end
sub soaxml {
  my ($so,$doc) = @_;
  return $so->soxml($doc,'a',basename($doc->{sowfile}));
}


1; ##-- be happy

__END__

##========================================================================
## POD DOCUMENTATION, auto-generated by podextract.perl, and edited

##========================================================================
## NAME
=pod

=head1 NAME

DTA::TokWrap::Processor::standoff - DTA tokenizer wrappers: t.xml -> (s.xml, w.xml, a.xml) via external filter programs

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 use DTA::TokWrap::Processor::standoff;
 
 $so = DTA::TokWrap::Processor::standoff->new(%opts);
 $doc_or_undef = $CLASS_OR_OBJECT->sosxml($doc);
 $doc_or_undef = $CLASS_OR_OBJECT->sowxml($doc);
 $doc_or_undef = $CLASS_OR_OBJECT->soaxml($doc);
 $doc_or_undef = $CLASS_OR_OBJECT->standoff($doc);
 
 ##-- backwards-compatibility
 undef = $so->dump_t2s_stylesheet($filename_or_fh);
 undef = $so->dump_t2w_stylesheet($filename_or_fh);
 undef = $so->dump_t2a_stylesheet($filename_or_fh);


=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::TokWrap::Processor::standoff: Constants
=pod

=head2 Constants

=over 4

=item Variable: @ISA

DTA::TokWrap::Processor::standoff
inherits from
L<DTA::TokWrap::Processor|DTA::TokWrap::Processor>.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::TokWrap::Processor::standoff: Constructors etc.
=pod

=head2 Constructors etc.

=over 4

=item new

 $so = $CLASS_OR_OBJECT->new(%args);

Constructor.

%args, %$so:

 t2w => $path_to_dtatw_txml2wxml, ##-- default: search
 t2s => $path_to_dtatw_txml2sxml, ##-- default: search
 t2a => $path_to_dtatw_txml2axml, ##-- default: search
 inplace => $bool,                ##-- prefer in-place programs for search?

=item defaults

 %defaults = CLASS->defaults();

Static class-dependent defaults.

=item init

 $so = $so->init();

Dynamic object-dependent defaults.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::TokWrap::Processor::standoff: Methods: Backwards-compatible
=pod

=head2 Methods: Backwards-compatibility

=over 4

=item _xsl

 $so_xsl = $so->_xsl();

Return a L<DTA::TokWrap::Processor::standoff::xsl|DTA::TokWrap::Processor::standoff::xsl>
object which may or may not be logically equivalent to C<$so>.

=item dump_t2s_stylesheet

 undef = $so->dump_t2s_stylesheet($filename_or_fh);

See L<DTA::TokWrap::Processor::standoff::xsl::dump_t2s_stylesheet()|DTA::TokWrap::Processor::standoff::xsl/item_dump_t2s_stylesheet>.

=item dump_t2w_stylesheet

 undef = $so->dump_t2w_stylesheet($filename_or_fh);

See L<DTA::TokWrap::Processor::standoff::xsl::dump_t2w_stylesheet()|DTA::TokWrap::Processor::standoff::xsl/item_dump_t2w_stylesheet>.

=item dump_t2a_stylesheet

 undef = $so->dump_t2a_stylesheet($filename_or_fh);

See L<DTA::TokWrap::Processor::standoff::xsl::dump_t2a_stylesheet()|DTA::TokWrap::Processor::standoff::xsl/item_dump_t2a_stylesheet>.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::TokWrap::Processor::standoff: Methods: document processing
=pod

=head2 Methods: document processing

=over 4

=item soxml

 $doc_or_undef = $CLASS_OR_OBJECT->soxml($doc,$X,$xmlbase);

Low-level generic standoff formatting method.
Generate C<$X>-level standoff for the
L<DTA::TokWrap::Document|DTA::TokWrap::Document> object $doc.

Relevant %$doc keys:

 xtokdata    => $xtokdata, ##-- (input) XML-ified tokenizer output data (string)
 so${X}file  => $sosfile,  ##-- (output) standoff file, refers to $xml_base
 ##
 so${X}xml_stamp0 => $f,   ##-- (output) timestamp of operation begin
 so${X}xml_stamp  => $f,   ##-- (output) timestamp of operation end
 so${X}file_stamp => $f,   ##-- (output) timestamp of operation end

=item sosxml

 $doc_or_undef = $CLASS_OR_OBJECT->sosxml($doc);

Just a wrapper for:

 $so->soxml($doc,'s',basename($doc->{sowfile}));

=item sowxml

 $doc_or_undef = $CLASS_OR_OBJECT->sowxml($doc);

Just a wrapper for:

 $so->soxml($doc,'w',$doc->{xmlbase});

=item soaxml

 $doc_or_undef = $CLASS_OR_OBJECT->soaxml($doc);

Just a wrapper for:

 $so->soxml($doc,'a',basename($doc->{sowfile}));

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


