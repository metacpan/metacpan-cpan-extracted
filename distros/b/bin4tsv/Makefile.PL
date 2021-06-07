use ExtUtils::MakeMaker;

WriteMakefile (
  NAME            => 'bin4tsv' ,
  VERSION_FROM    => 'lib/bin4tsv.pm' , 
  EXE_FILES => [ map {"scripts/$_"} qw { colchop colorplus colsummary crosstable csel csv2tsv expskip freq latextable madeafter saikoro sampler transpose venn } ] ,
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)' , 
  LICENSE => 'perl_5' 
) ;
 
