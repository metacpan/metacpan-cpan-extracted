use Module::Build;
# See perldoc Module::Build for details of how this works

my $prog;
my $build=Module::Build->new
( module_name     => 'iCal::Parser::SAX',
  version_from    => 'iCal::Parser::SAX',
  license         => 'perl',
  requires => {
	       iCal::Parser => 1.07,
	       IO::File => 1.10,
	       IO::String => 1.05,
	       XML::SAX::Base => 1.04,
	       DateTime => 0.22,
	       XML::SAX::Writer => 0.44,
	      },
  build_requires => {
		     Test::More => 0.47,
		     Test::XML => 0.06,
		    },
  recommends => {
		 LWP::UserAgent => 2.032,
		},
  create_readme => 1,
  create_makefile_pl => 'passthrough',
);
if($build->y_n
   ('Would you like to install ical2xml, a command line frontend?','n')) {
    $build->{properties}->{script_files}=['scripts/ical2xml'];
}
$build->create_build_script;
if($build->y_n(q{Would you like to test a remote (http) calendar?
(Requires LWP::UserAgent and may fail if you don't have access
to the internet or the remote file has moved) },'y')) {
    open OUT, '>_build/DOHTTP';
    close(OUT);
}
