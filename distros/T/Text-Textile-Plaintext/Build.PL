###############################################################################
#
#   Module::Build file for Text::Textile::Plaintext
#
###############################################################################

use 5.006001;
use strict;
use warnings;

use Module::Build;

my $class = Module::Build->subclass(
    class => 'Text::Textile::Plaintext::Builder',
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
            $self->do_system(qw(perl -Mblib),
                             $textile2x,
                             qw(--format plaintext
                                --input README.textile
                                --output README));

            $self->SUPER::ACTION_manifest();
            $self->SUPER::ACTION_dist();
        }
    |
);

my $builder = $class->new(
    module_name    => 'Text::Textile::Plaintext',
    license        => 'perl',
    dist_author    => 'Randy J. Ray <rjray@blackperl.com>',
    dist_abstract  => 'Convert Textile markup to plain-text, PS or RTF output',
    dist_version   => '0.101',
    build_requires => {
        'Test::More'    => '0.80',
    },
    requires => {
        'perl'              => '5.008',
        'Text::Textile'     => '2.12',
        'HTML::TreeBuilder' => '3.23',
        'HTML::FormatText'  => '2.04'
    },
    add_to_cleanup => [
        qw(Text-Textile-Plaintext-*
          ChangeLog
          MANIFEST
          MANIFEST.bak
          META.yml
          Makefile.PL
          README)
    ],
    meta_merge => {
        resources => {
            homepage => 'http://search.cpan.org/dist/Text-Textile-Plaintext',
            bugtracker =>
              'http://rt.cpan.org/Public/Dist/Display.html?Name=Text-Textile-Plaintext',
            repository =>
              'http://github.com/rjray/text-textile-plaintext/tree/master',
        }
    },

    create_makefile_pl => 'traditional',
    sign               => 'here, please',
);

$builder->create_build_script();

exit 0;
