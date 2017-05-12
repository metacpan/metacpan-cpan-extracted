use ExtUtils::MakeMaker;

WriteMakefile( 
               'NAME'          => 'XML::Document::RTML',
	       'VERSION_FROM'  => 'RTML.pm',
               'PREREQ_PM'     => { 'XML::Simple'         => 0,
	                            'XML::Writer'         => 0,
				    'XML::Writer::String' => 0,
				    'Net::Domain'         => 0,
				    'File::Spec'          => 0,
				    'Carp'                => 0,
				    'Data::Dumper'        => 0,
				    'Scalar::Util'        => 0 },
	       'dist'          => { COMPRESS => "gzip -9f"},
	       ($] >= 5.005 ?   ## 
	       ( ABSTRACT      => 'Module designed to parse RTML messages',
		 AUTHOR        => 'Alasdair Allan <aa@astro.ex.ac.uk>') : ()),
             );

