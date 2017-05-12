use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'URL::Transform',
    license             => 'perl',
    dist_author         => 'Jozef Kutej <jkutej@cpan.org>',
    dist_version_from   => 'lib/URL/Transform.pm',
    requires => {
        'Class::Accessor::Fast'   => 0,
        'XML::SAX::Base'          => 0,
        'Carp::Clan'              => 0,
        'Compress::Zlib'          => 0,
        'Cwd'                     => 0,
        'File::Slurp'             => 0,
        'HTML::Parser'            => 0,
        'HTML::Tagset'            => 0,
        'List::Util'              => 0,
        'XML::SAX'                => 0,
        'XML::SAX::ParserFactory' => 0,
        'XML::SAX::Writer'        => 0,
    },
    build_requires => {
        'Test::More'        => 0,
        'Test::Differences' => 0,
        'Test::Exception'   => 0,
        'Cwd'               => 0,
    },
    add_to_cleanup      => [ 'URL-Transform-*' ],
    create_readme       => 1,
    sign                => 1,
    meta_merge => {
        resources => {
            repository => 'git://github.com/jozef/URL-Transform.git',
            bugtracker => 'http://github.com/jozef/URL-Transform/issues',
        },
        keywords => [ qw/ url edit / ],
    },
);
$builder->create_build_script();
