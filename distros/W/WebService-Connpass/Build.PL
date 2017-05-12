use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name         => 'WebService::Connpass',
	license             => 'perl',
	dist_author         => 'Masanori Ohgita (http://ohgita.info)',
	dist_version_from   => 'lib/WebService/Connpass.pm',
	requires => {
		'Test::More'					 => 0,
		'version'					 => 0,
		'Carp'						 => 0,
		'Class::Accessor'			 => 0,
		'Data::Recursive::Encode'	 => 0,
		'DateTime::Format::ISO8601'	 => 0,
		'Hash::AsObject'				 => 0,
		'JSON'						 => 0,
		'LWP::UserAgent'				 => 0,
		'URI'						 => 0,

		'Module::Build'					 => 0,
		'Test::Pod'		 			 => 0,
		'Test::Pod::Coverage'		 => 1.08,
		'File::Slurp'				 => 0,
		'FindBin'					 => 0,
		'Plack::Loader'				 => 0,
		'Test::TCP'					 => 0,
		'Test::Perl::Critic'			 => 0,
	},
	add_to_cleanup      => [ 'WebService-Connpass-*' ],
);

$builder->create_build_script();
