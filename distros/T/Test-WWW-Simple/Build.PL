use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Test::WWW::Simple',
    license             => 'perl',
    dist_author         => 'Joe McMahon <mcmahon@cpan.org>',
    dist_abstract       => 'Simple text-based tests for web pages',
    create_makefile_pl  => 0,     #'traditional',
    create_readme       => 0,
    requires            => {
      'Test::Builder'             => 0,
      'Test::LongString'          => 0,
      'Test::Tester'              => 0,
      'HTML::Tree'                => 0,
      'WWW::Mechanize'            => 0,
      'WWW::Mechanize::Pluggable' => 1.07,
      'Regexp::Common'            => 0,

    },
    build_requires      => {
      Mojolicious => 8.11,
    },
);

$builder->create_build_script();
