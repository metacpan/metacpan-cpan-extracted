use lib inc; use Devel::AssertOS qw(Cygwin Linux FreeBSD DragonflyBSD OpenBSD MacOSX NetBSD);

use strict;
use warnings;

use Module::Build 0.28;

my $IS_BSD = $^O =~ /^(?:darwin|dragonfly|(?:free|open|net)bsd)$/;
my $WANT_XS = $IS_BSD;
$WANT_XS = 0 if $ENV{NO_XS};

my $build = Module::Build->new(
    module_name     => 'Unix::Uptime',
    license         => 'perl',
    sign            => 1,
    configure_requires  => {
        'Module::Build' => 0.28,
    },
    build_requires  => {
        'Module::Build' => 0.28,
        ($WANT_XS ? ('ExtUtils::CBuilder' => 0) : ()),
    },
    recommends => {
        ($IS_BSD ? ('Time::HiRes' => 0) : ()),
    },
    meta_merge => {
        resources => {
            repository => 'https://github.com/pioto/Unix-Uptime',
            bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Unix-Uptime',
        },
    },
);
$build->xs_files({}) unless $WANT_XS;
$build->create_build_script();

