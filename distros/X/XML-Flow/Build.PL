use Module::Build;
use 5.8.0;
Module::Build->new
    ( module_name => 'XML::Flow',
    license => 'perl',
   prereq => {
	'XML::Parser'=>'0',
	'XML::Writer'=>'0',
	'Encode'=>0,
	     },
   dist_version_from=>'lib/XML/Flow.pm',
   dist_author=>'Zahatski Aliaksandr zag@cpan.org',
    create_makefile_pl=>$ENV{DO_OUTCPAN} ? 'traditional':'passthrough'
    )->create_build_script;
