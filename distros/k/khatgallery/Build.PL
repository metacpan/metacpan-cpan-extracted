use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'HTML::KhatGallery',
    dist_name           => 'khatgallery',
    license             => 'perl',
    dist_author         => 'Kathryn Andersen',
    dist_version_from   => 'lib/HTML/KhatGallery.pm',
	requires            => {
	     # module requirements here
	'Getopt::Long' => 2.34,
	'Pod::Usage' => 0,
	'Getopt::ArgvFile' => 1.09,
	'POSIX' => 0,
	'File::Basename' => 2.73,
	'File::Spec' => 3.0,
	'Cwd' => 3.0,
	'File::stat' => 1.0,
	'YAML' => 0.35,
	'Image::Info' => 1.16,
	'Image::Magick' => 6.2,

	},
    build_requires => {
        'Test::More' => 0,
    },
#    add_to_cleanup      => [ 'khatgallery-*' ],
    script_files => [qw(scripts/khatgallery scripts/kg_image_info)],

);

$builder->create_build_script();
# create the Makefile.PL
use Module::Build::Compat;
print "creating Makefile.PL\n";
Module::Build::Compat->create_makefile_pl('passthrough', $builder);
