use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'HTML::ToDocBook',
    dist_name		=> 'html2dbk',
    license             => 'perl',
    dist_author         => 'Kathryn Andersen',
    dist_version_from   => 'lib/HTML/ToDocBook.pm',
	requires            => {
	'Getopt::Long' => 2.34,
	'Pod::Usage' => 0,
	'Getopt::ArgvFile' => 1.09,
	'Cwd' => 0,
	'File::Basename' => 0,
	'File::Spec' => 0,
	'XML::LibXML' => 0,
	'XML::LibXSLT' => 0,
	'HTML::SimpleParse' => 0,
	},
    build_requires => {
        'Test::More' => 0,
    },
#    add_to_cleanup      => [ 'html2dbk-*' ],
    script_files => [qw(scripts/html2dbk)],
    meta_add => {
        resources  => {
            repository  => 'git://github.com/rubykat/html2dbk.git',
            homepage  => 'http://github.com/rubykat/html2dbk',
        },
    },
);

$builder->create_build_script();
