use Module::Build;
Module::Build->new
    ( module_name => 'XML::Handler::ExtOn',
    license => 'perl',
   prereq => {
	      'XML::SAX'=>'0',
	      'XML::SAX::Writer'=>0,
	      'XML::Parser::PerlSAX'=>0,
	      'Tie::UnionHash'=>'0',
	      'XML::Filter::SAX1toSAX2' =>0,
	       },
    create_makefile_pl=>$ENV{DO_OUTCPAN} ? 'traditional':'passthrough'
    )->create_build_script;
