use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
     module_name       => 'threads::variables::reap::attr',
     license           => 'perl',
     dist_author       => q{Jens Rehsack <rehsack@cpan.org>},
     dist_version_from => 'lib/threads/variables/reap/attr.pm',
     build_requires    => { 'Test::More' => '0.90', },
     add_to_cleanup    => ['threads-variables-reap-attr-*'],
     requires          => {
                   'Attribute::Lexical'       => 0.002,
                   'threads::variables::reap' => 0.06,
                   perl                       => 5.008,
                 },
     recommends => { threads => 0, },
     meta_merge =>
       { resources => { repository => "https://github.com/rehsackthreads-variables-reap-attr", }, },
     test_files => join( ' ' => 't/*.t xt/*.t' ),
);

$builder->create_build_script();
