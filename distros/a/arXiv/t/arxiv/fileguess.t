# Test code for arXiv::FileGuess
# 2006-04-17 Simeon Warner
#
# $Id: fileguess.t,v 1.1 2010-12-25 17:04:01 simeon Exp $
use strict;

use Test::More;
use arXiv::FileGuess qw(guess_file_type type_name is_tex_type);
plan(tests=>39);

# Detection of file types
{
  my $testdir='t/arxiv/fileguess';
  chdir($testdir) || die;

  foreach my $a ( (
    [ 'pipnss.jar', 'TYPE_JAR' ],
    [ 'holtxdoc.zip', 'TYPE_ZIP' ],
    [ '00README.XXX', 'TYPE_README' ],
    [ '0604408.pdf', 'TYPE_RAR' ],
    [ 'Agenda_Elegant_Style_EN.Level1.docx', 'TYPE_DOCX' ],
    [ 'Hellotest.docx', 'TYPE_DOCX' ],
    [ 'Hellotest.not_docx_ext', 'TYPE_ZIP' ],
    [ 'odf_test.odt', 'TYPE_ODF' ],
    [ 'odf_test.not_odt_ext', 'TYPE_ZIP' ],
    [ 'verlinde.dvi', 'TYPE_DVI' ],
    [ 'polch.tex', 'TYPE_LATEX' ],
    [ 'paper-t4.1_Vienna_preprint.tex', 'TYPE_LATEX2e' ],
    [ 'pascal_petit.tex', 'TYPE_PDFLATEX' ],
    [ 'short-1.txt.bz2', 'TYPE_BZIP2' ],
    [ 'short-4.txt.bz2', 'TYPE_BZIP2' ],
    [ 'short-9.txt.bz2', 'TYPE_BZIP2' ],
    # a \pdfoutput=1 may come in various places, all valid 
    [ 'pdfoutput_before_documentclass.tex', 'TYPE_PDFLATEX' ],
    [ 'pdfoutput_sameline_documentclass.tex', 'TYPE_PDFLATEX' ],
    [ 'pdfoutput_after_documentclass.tex', 'TYPE_PDFLATEX' ],
    [ 'pdfoutput_after_documentclass_big_comment_before.tex', 'TYPE_PDFLATEX' ],
    # but if we put it too late it is ignored
    [ 'pdfoutput_too_far_after_documentclass.tex', 'TYPE_LATEX2e' ],
    [ 'pdfoutput_too_far_after_documentclass_big_comment_before.tex', 'TYPE_LATEX2e' ],
    # EPS
    [ 'dos_eps_1.eps', 'TYPE_DOS_EPS' ],
    [ 'dos_eps_2.eps', 'TYPE_DOS_EPS' ],
    # font files must not be detected as simple PS
    [ 'rtxss.pfb', 'TYPE_PS_FONT' ],
    [ 'c059036l.pfb', 'TYPE_PS_FONT' ],
    [ 'hrscs.pfa', 'TYPE_PS_FONT' ],
    [ 'bchbi.pfa', 'TYPE_PS_FONT' ],
    # error cases
    [ '10240_null_chars.tar', 'TYPE_FAILED' ],
    [ 'file_does_not_exit', 'TYPE_FAILED', [ 'TYPE_FAILED', undef, "failed to open 'file_does_not_exit' to guess its format: No such file or directory. Continuing.\n"] ] ) ) {
    my ($filename,$type,$deep)=@$a;
    is ( (guess_file_type($filename))[0], $type, "Expected (guess_file_type($filename))[0] eq $type" );
    if ($deep) {
      is_deeply ( [guess_file_type($filename)], $deep, "Full test of guess_file_type($filename)" );
    }
  }
}

# tests for type to name translation and tex format identification
foreach my $a ( (
  [ 'TYPE_ODF', 'OpenDocument Format', '' ],
  [ 'TYPE_DOCX', 'Microsoft DOCX', '' ],
  [ 'TYPE_TEX', 'TEX', 1 ],
  [ 'BLAH', 'unknown', '' ] ) ) {
  my ($type,$name,$tex)=@$a;
  is ( type_name($type), $name, "Expected type_name($type) eq $name" );
  is ( is_tex_type($type), $tex, "Expected is_tex_type($type) eq $tex" );
}
