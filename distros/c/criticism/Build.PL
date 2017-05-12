#######################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/tags/criticism-1.02/Build.PL $
#     $Date: 2008-07-27 16:11:59 -0700 (Sun, 27 Jul 2008) $
#   $Author: thaljef $
# $Revision: 206 $
########################################################################

use 5.006001;

use strict;
use warnings;

use Module::Build;

my $class = Module::Build->subclass( code => <<'END_SUBCLASS' );

    sub ACTION_test {
        my ($self) = @_;

        $self->depends_on('manifest');

        return $self->SUPER::ACTION_test();
    }

    sub ACTION_authortest {
        my ($self) = @_;

        $self->depends_on('build');
        $self->depends_on('manifest');
        $self->depends_on('distmeta');

        $self->test_files( qw< t xt/author > );
        $self->recursive_test_files(1);

        $self->depends_on('test');

        return;
    }

    sub ACTION_distdir {
        my ($self) = @_;

        $self->depends_on('authortest');

        return $self->SUPER::ACTION_distdir();
    }

END_SUBCLASS

my $builder = $class->new(
    module_name     => 'criticism',
    dist_author     => 'Jeffrey Thalhammer <thaljef@cpan.org>',
    dist_abstract   => 'Perl pragma to enforce coding standards and best-practices.',
    license         => 'perl',
    dynamic_config  => 1,
    create_readme   => 1,
    create_packlist => 1,
    sign            => 0,

    requires        => {
        'Perl::Critic' => 1.089
    },

    build_requires  => {
        'Test::More'   => 0,
        'IO::String'   => 0,
    },

    add_to_cleanup  => [
	qw<
	    Makefile
            Makefile.old
            MANIFEST
            MANIFEST.bak
            META.yml
            pm_to_blib
            README
         >,
    ],

    meta_merge      => {
        resources   => {
            homepage    => 'http://perlcritic.com',
            license     => 'http://dev.perl.org/licenses/',
            Repository  => 'http://perlcritic.tigris.org/svn/perlcritic/trunk/criticism/',
            MailingList => 'http://perlcritic.tigris.org/servlets/SummarizeList?listName=users',
        }
    },
);

$builder->create_build_script();
