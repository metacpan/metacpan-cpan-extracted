# a lot of this taken from the fine example of the gtk2perl Makefile.PL

use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::Spec;
use Cwd;

our %build_reqs = (
    'perl-ExtUtils-Depends'   => '0.2',
    'perl-ExtUtils-PkgConfig' => '1.03',
    'perl-Glib'               => '1.081',
    'perl-Gtk2'               => '1.081',
    'Xfce4'                   => '4.3.4',
);

our %PREREQ_PM = (
    'ExtUtils::Depends'   => $build_reqs{'perl-ExtUtils-Depends'},
    'ExtUtils::PkgConfig' => $build_reqs{'perl-ExtUtils-PkgConfig'},
    'Glib'                => $build_reqs{'perl-Glib'},
    'Gtk2'                => $build_reqs{'perl-Gtk2'},
);

# write a fake makefile for cpan, so it picks up deps properly
unless(eval "use ExtUtils::Depends '$build_reqs{'perl-ExtUtils-Depends'}';"
          . "use ExtUtils::PkgConfig '$build_reqs{'perl-ExtUtils-PkgConfig'}';"
          . "use Glib '$build_reqs{'perl-Glib'}';"
          . "use Glib::MakeHelper;" # for do_pod_files()
          . "use Gtk2 '$build_reqs{'perl-Gtk2'}';"
          . "use Gtk2::CodeGen;"
          . "1") {
   warn "$@\n";
   WriteMakefile(
         PREREQ_FATAL => 1,
         PREREQ_PM    => \%PREREQ_PM,
   );
   exit 1; # not reached
}

require Gtk2::CodeGen;

mkdir('build', 0777);

my %pkgcfg = ExtUtils::PkgConfig->find('libxfcegui4-1.0 >= '
                                        . $build_reqs{'Xfce4'});

# this will let me support xfce versions >= 4.2, and allow me to
# conditionally compile files based on version (i.e., if new widgets
# appear in newer versions
my @xfce_version = split(/\./, $pkgcfg{modversion});
our @xs_files = ();
our @xs_lists = Glib::MakeHelper->select_files_by_version("xs_files", @xfce_version);
foreach my $file (@xs_lists) {
    my @names = Glib::MakeHelper->read_source_list_file($file);
    print "Loaded ".scalar(@names)." xs files from $file\b";
    push(@xs_files, @names);
}

# apparently i need to define install paths manually, since i've strayed
# from MakeMaker's usual path
our %pm_files = (
    'Xfce4.pm' => '$(INST_LIBDIR)/Xfce4.pm',
);
our %pod_files = (
    'Xfce4.pm' => '$(INST_MAN3DIR)/Xfce4.$(MAN3EXT)',
    Glib::MakeHelper->do_pod_files(@xs_files),
);

# autogenerate some code.  the first step is to parse the typemaps file.  this
# file is generated by tools/genmaps.pl.
Gtk2::CodeGen->parse_maps('xfce4perl', input => [<maps-[0-9]\.[0-9]>]);
# but make sure we only document the stuff for the version we're compiling
our @used_maps = Glib::MakeHelper->select_files_by_version("maps", @xfce_version);

# this generates code to boot all the xs modules that don't have .pm files.
Gtk2::CodeGen->write_boot(xs_files => \@xs_files);

# todo: look for #define enums to convert to key=>value hashes

# ok, now generate the makefile itself.  get dependency info:
our $xfce4 = ExtUtils::Depends->new('Xfce4', 'Gtk2');
# set the include path, libs, etc.
$xfce4->set_inc($pkgcfg{cflags}.' -I./build ');
$xfce4->set_libs($pkgcfg{libs});  # fixme: this won't work on win32
$xfce4->add_pm(%pm_files);
$xfce4->add_xs(@xs_files);
my $cwd = cwd();
$xfce4->add_typemaps(map {File::Spec->catfile($cwd, $_)}
                     'build/xfce4perl.typemap',
                     'xfce4.typemap');
$xfce4->install(qw(xfce4perl.h
                   build/xfce4perl-autogen.h
                   doctypes));
$xfce4->save_config('build/IFiles.pm');

# todo make exports file for win32

# finally, write the damned thing out
WriteMakefile(
    NAME => 'Xfce4',
    VERSION_FROM => 'Xfce4.pm',
    ABSTRACT_FROM => 'Xfce4.pm',
    PREREQ_PM => \%PREREQ_PM,
    XSPROTOARG => '-noprototypes',
    MAN3PODS => \%pod_files,
#    FUNCLIST => \@exports,
    DL_FUNCS => { Xfce4 => [] },
    $xfce4->get_makefile_vars,
);

# i don't know what any of this stuff does.
sub MY::postamble
{
    my $text = "#POD_DEPENDS=build/stock_items.podi\n\n"
         . Glib::MakeHelper->postamble_clean ()
         . Glib::MakeHelper->postamble_docs_full (
                DEPENDS => $xfce4,
                DOCTYPES => 'doctypes',
                COPYRIGHT_FROM => 'copyright.pod',
           )
         . Glib::MakeHelper->postamble_rpms (
                'Xfce4' => $build_reqs{'Xfce4'},
                'PERL_EXTUTILS_DEPENDS' =>
                        $build_reqs{'perl-ExtUtils-Depends'},
                'PERL_EXTUTILS_PKGCONFIG' =>
                        $build_reqs{'perl-ExtUtils-PkgConfig'},
                'PERL_GTK2' => $build_reqs{'perl-Gtk2'},
           )
             . "
# rebuild the makefile if the file lists change
Makefile : ".join(" ", @xs_lists)."

\$(INST_LIB)/\$(FULLEXT)/enums.pod : \$(BLIB_DONE) @used_maps tools/podifyenums.pl
	\$(PERLRUNINST) -M\$(NAME) tools/podifyenums.pl \$(NAME) @used_maps > \$@

#build/stock_items.podi: \$(BLIB_DONE) tools/podifystockitems.pl
#	\$(PERLRUNINST) -M\$(NAME) tools/podifystockitems.pl > \$@

build/FAQ.pod: tools/fetch_faq.pl
	$^X \$<
";

    # this installation stuff doesn't make sense on windows, where
    # we don't really have a /usr.  also, nmake barfs on $+.
    unless ($^O eq 'MSWin32') {
        $text .= "
# the tmp-xxx stuff is just so that only the pl files get installed
install-\%: %
	\@\$(MKPATH) tmp-\$+/
	\@\$(CP) \$+/*.* tmp-\$+/
	\@\$(MOD_INSTALL) ./tmp-\$+/ \\
		\$(PREFIX)/share/doc/perl-\$(DISTNAME)/\$+
	\@\$(RM_RF) tmp-\$+/
";
    }

    return $text;
}
