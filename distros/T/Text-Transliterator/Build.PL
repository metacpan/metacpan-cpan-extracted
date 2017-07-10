use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Text::Transliterator',
    license             => 'perl',
    dist_author         => q{Laurent Dami <dami@cpan.org>},
    dist_version_from   => 'lib/Text/Transliterator.pm',
    requires            => { 'Unicode::UCD'       => 0,
                             'Unicode::Normalize' => 0, },
    build_requires      => { 'Test::More'         => 0, },
    add_to_cleanup      => [ 'Text-Transliterator-*' ],
    meta_merge => {
      resources => {
        repository => 'https://github.com/damil/Text-Transliterator',
       }
     },
);

$builder->create_build_script();
