use ExtUtils::MakeMaker;

#To bypass make test: t/*.t for perl 5.005
#if( $] < 5.006 ){
#    rename('t', 'TEST') ;
#    open(MANIFEST, '+<MANIFEST') or warn ('Eep! no MANIFEST?');
#    $_ = do{ undef $/; <MANIFEST> };
#    s%^t/%TEST/%mg;
#    seek(MANIFEST, 0, 0);
#    print MANIFEST;
#}

WriteMakefile(
	      NAME	   => 'Text::FIGlet',
	      VERSION_FROM => 'lib/Text/FIGlet.pm',
	      PL_FILES     =>{'bin/minifig.PL'=>'bin/minifig.pl' },
	      EXE_FILES    =>[ glob('bin/*.pl'), 'bin/minifig.pl' ],
	      ($] < 5.006 ? () :#Test dependency bypass
	       (PREREQ_PM    =>{'Test::Differences' => undef})),
	      LICENSE      => 'perl', #More or less
	     );
