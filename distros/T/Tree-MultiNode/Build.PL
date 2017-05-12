use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Tree::MultiNode',
    author              => 'Kyle R. Burton <krburton@cpan.org>',
    dist_version_from   => 'lib/Tree/MultiNode.pm',
    abstract_from       => 'lib/Tree/MultiNode.pm',
    dist_abstract       => 'lib/Tree/MultiNode.pm',
    license             => 'perl',
    build_requires      => {
	'Test::More'    => '0.40', 
	'Module::Build' => '0.35',
    },
    add_to_cleanup      => ['Tree-MultiNode-*' ],
    create_makefile_pl  => 'traditional',
    meta_merge     => {
      resources => {
        homepage => 'http://github.com/toddr/Tree-MultiNode',
        bugtracker => 'https://rt.cpan.org/NoAuth/Bugs.html?Dist=Tree-MultiNode',
        MailingList => 'mailto:toddr@cpan.org',
        repository  => 'git://github.com/toddr/Tree-MultiNode.git',
      }
    }
);

$builder->create_build_script;
