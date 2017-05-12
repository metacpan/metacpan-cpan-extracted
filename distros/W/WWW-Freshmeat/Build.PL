use 5.008;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WWW::Freshmeat',
    license             => 'perl',
    dist_author         => 'Alexandr Ciornii <alexchorny@gmail.com>',
    dist_version_from   => 'lib/WWW/Freshmeat.pm',
    requires => {
        'LWP::UserAgent' => 0,
        'XML::Simple' => 0,
        'XML::Parser' => 0, #for XML::Simple, in case of dependency problems
        'perl' => 5.008,
        #'HTML::TreeBuilder::XPath' => 0.09,
        'Mouse' => 0.24, #recent one
    },
    build_requires => {
        'Test::More' => 0.17, #isa_ok
        'LWP::Online' => 1.06,
        'File::Slurp' => 0,
    },
    meta_merge => {
        resources=> {
            repository => 'http://github.com/chorny/WWW-Freshmeat',
            Ohloh => 'https://www.ohloh.net/p/WWW-Freshmeat',
        },
        keywords => ['freshmeat','API'],
    },
    add_to_cleanup      => [ 'WWW-Freshmeat-*' ],
);

$builder->create_build_script();
