use 5.008008;
use Module::Build;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my $build = new Module::Build(
    module_name			=> 'WWW::BBB::API',
	license				=> 'perl',
    requires			=> {
							'URI'	 		=> 0,
							'Digest::SHA'	=> 0,
							'XML::Simple'	=> 0,
							'LWP::Simple'	=> 0,
							}, 
	build_requires		=> { 'Module::Build'  => 0.26 },
	create_makefile_pl	=> 'small',

    dist_author			=> 'Emiliano Bruni <info@ebruni.it>',
	build_class			=> 'Module::Build',
);

my ($run_network, $bbb_host, $bbb_salt);

$build->create_build_script();

$run_network = Module::Build->y_n('Do you want to run the network test?', 'n');
if ($run_network) {
	$bbb_host = Module::Build->prompt( "Give me a BigBlueButton server: ", undef);
	$bbb_salt = Module::Build->prompt( "Give me the salt key of this host: ", undef);
}

$build->notes( run_network 	=> $run_network );
$build->notes( bbb_host 	=> $bbb_host );
$build->notes( bbb_salt 	=> $bbb_salt );




