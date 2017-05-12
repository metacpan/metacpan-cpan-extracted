###############################################################################
#
#   Module::Build file for Test::Without
#
###############################################################################

use 5.008;
use strict;
use warnings;

use Module::Build;

my $class = Module::Build->subclass(
    class => 'Test::Without::Builder',
    code  => q|
        sub ACTION_dist
        {
            my $self = shift;

            use File::Spec;
            my $textile2x = File::Spec->catfile(qw(bin textile2x));

            # Create the text ChangeLog
            $self->do_system('changelog2x',
                             qw(--template text --input ChangeLog.xml),
                             qw(--output ChangeLog));
            # Create the text README
            $self->do_system('textile2x',
                             qw(--format plaintext
                                --input README.textile
                                --output README));

            $self->SUPER::ACTION_manifest();
            $self->SUPER::ACTION_dist();
        }
    |
);

my $builder = $class->new(
    module_name    => 'Test::Without',
    license        => 'perl',
    dist_author    => 'Randy J. Ray <rjray@blackperl.com>',
    dist_abstract  => 'Hide directories and/or modules from test blocks',
    dist_version   => '0.10',
    build_requires => { 'Test::More' => '0.80' },
    requires       => {
        'perl'         => '5.008',
        'Scalar::Util' => '1.21',
    },
    add_to_cleanup => [
        qw(Test-Without-*
          ChangeLog
          MANIFEST
          MANIFEST.bak
          META.yml
          Makefile.PL
          README)
    ],
    meta_merge => {
        resources => {
            homepage => 'http://search.cpan.org/dist/Test-Without',
            bugtracker =>
              'http://rt.cpan.org/Public/Dist/Display.html?Name=Test-Without',
            repository =>
              'http://github.com/rjray/test-without',
        }
    },

    create_makefile_pl => 'traditional',
    sign               => 'here, please',
);

$builder->create_build_script();

exit 0;
