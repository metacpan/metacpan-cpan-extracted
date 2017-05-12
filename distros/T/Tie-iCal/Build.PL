use Module::Build;
my $build = Module::Build->new(
	module_name => 'Tie::iCal',
	license => 'perl',
	requires => {
		'Tie::File'   => '0.97',
	},
	dist_author => 'Blair Sutton <bsdz@cpan.org>',
	dist_abstract => 'Tie iCal files to Perl hashes',
);
$build->create_build_script;