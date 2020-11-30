use 5.010000;
use ExtUtils::MakeMaker;
use ExtUtils::PkgConfig;
use Glib::MakeHelper;
use ExtUtils::Depends;

my %pkg_info = ExtUtils::PkgConfig->find('gdk-3.0');
my %gtk_info = ExtUtils::PkgConfig->find('gtk+-3.0');


my $deps = ExtUtils::Depends->new ('WWW::WebKit2' => 'Glib');
my @authors = ( 'Jason Shaun Carty <jc@atikon.com>',  'Philipp Voglhofer <pv@atikon.com>', 'Philipp A. Lehner <pl@atikon.com>');

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WWW::WebKit2',
    VERSION_FROM      => 'lib/WWW/WebKit2.pm', # finds $VERSION
    LICENSE           => 'perl',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
        'ExtUtils::PkgConfig' => 0,
        'ExtUtils::Depends'   => 0,
        'Glib::MakeHelper'    => 0,
    },
    BUILD_REQUIRES => {
        'URI' => 0,
        'Test::More' => 0.88,
        'Test::Fake::HTTPD' => 0,
    },
    PREREQ_PM         => {
        'Gtk3'              => 0,
        'Gtk3::WebKit2'     => 0.013,
        Glib                => 0,
        Moose               => 0,
        'Time::HiRes'       => 0,
        'X11::Xlib'         => 0,
        Carp                => 0,
        DateTime            => 0,
        'File::Slurper'     => 0,
        'File::Path'        => 0,
        Encode              => 0,
        JSON                => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WWW/WebKit2.pm', # retrieve abstract from module
       AUTHOR         => \@authors) : ()),
    LIBS              => [ExtUtils::PkgConfig->libs_only_L('gdk-3.0')], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => $pkg_info{cflags},
    # OBJECT            => '$(O_FILES)', # link all the C files too
    $deps->get_makefile_vars,
);
