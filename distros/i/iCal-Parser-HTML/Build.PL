use Module::Build 0.26;
# $Id: Build.PL 5 2005-03-19 23:27:33Z rick $
# See perldoc Module::Build for details of how this works
my $build=
Module::Build->new
    ( module_name     => 'iCal::Parser::HTML',
      version_from    => 'iCal::Parser::HTML',
      requires => {
		   iCal::Parser::SAX => 1.05,
		   XML::LibXML => 1.58,
		   XML::LibXSLT => 1.57,
		  },
      build_requires => {Test::More => 0.47},
      license         => 'perl',
      create_readme => 1,
      create_makefile_pl => 'passthrough',
    );
$build->add_build_element('xsl');
if($build->y_n
   ('Would you like to install ical2html, a command line frontend?','n')) {
    $build->{properties}->{script_files}=['scripts/ical2html'];
}
$build->create_build_script;

