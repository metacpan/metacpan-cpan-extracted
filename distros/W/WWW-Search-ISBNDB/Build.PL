use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WWW::Search::ISBNDB',
    license             => 'perl',
    dist_author         => 'Nick Gerakines <nick@socklabs.com>',
    dist_version_from   => 'lib/WWW/Search/ISBNDB.pm',
    requires => {
        'Carp' => 0,
        'LWP::UserAgent' => 0,
        'WWW::Search' => 0,
        'XML::Simple' => 0,
    },
    build_requires => {
        'Test::More' => 0,
        'Test::Deep' => 0,
        'Test::Exception' => 0,
        'File::Temp' => 0,
        'Cwd' => 0,
        'Test::Group' => 0,
    },
	get_options => {
		'key' => { type  => '=s' },
	},
    add_to_cleanup      => [ 'WWW-Search-ISBNDB-*' ],
);

$builder->create_build_script();