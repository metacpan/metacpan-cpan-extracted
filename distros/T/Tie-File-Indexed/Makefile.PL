use ExtUtils::MakeMaker;

##----------------------------------------------------------------------
## MAIN
##----------------------------------------------------------------------
WriteMakefile
  (
   NAME		=> 'Tie::File::Indexed',
   AUTHOR       => 'Bryan Jurish <moocow@cpan.org>',
   ABSTRACT	=> 'fast tied array access to indexed data files',
   VERSION_FROM	=> 'Indexed.pm',
   LICENSE      => 'perl_5',

   ##-- install these
   #EXE_FILES => [glob("*.perl")],

   ##-- prerequisites
   MIN_PERL_VERSION => '5.10.0', ##-- perl <=5.10 chokes on // operator
   PREREQ_PM    => {
		    #'Module' => $version,
		    'Tie::Array' => 0,
		    'JSON' => 0,
		    'Storable' => 0,
		    'File::Copy' => 0,
		    'Test::More' => 0,
		   },
  );


#-----------------------------------------------------------------------
# Extensions
#-----------------------------------------------------------------------

##---------------------------------------------------------------
sub MY::constants {
  package MY;
  my $inherited = shift->SUPER::constants(@_);
  return $inherited;
}

##---------------------------------------------------------------
sub MY::depend {
  package MY;
  my $inherited = shift->SUPER::depend(@_);
  $inherited .= (
		 ###-- depends -> README.txt
		 "\n\n"
		 .join('',
		      map {
			"$_: README.txt\n\n"
		      } qw(dist create_distdir distdir_am distcheck))
		);
  return $inherited;
}

##---------------------------------------------------------------
sub MY::special_targets {
  package MY;
  my $inherited = shift->SUPER::special_targets(@_);
  $inherited .=
"
.SUFFIXES: .pm .pod .rpod .man .txt .html

.pm.html:
\tpod2html --css=\$(CSS) --infile=\$< --outfile=\$@

.pm.txt:
\tpod2text \$< \$@

.pod.html:
\tpod2html --css=\$(CSS) --infile=\$< --outfile=\$@

.pod.txt:
\tpod2text \$< \$@

.rpod.html:
\tpod2html --css=\$(CSS) --infile=\$< --outfile=\$@

.rpod.txt:
\tpod2text \$< \$@

";
  return $inherited;
}

##---------------------------------------------------------------
sub MY::postamble {
  package MY;
  my $inherited = shift->SUPER::postamble(@_);
  return $inherited;
}
