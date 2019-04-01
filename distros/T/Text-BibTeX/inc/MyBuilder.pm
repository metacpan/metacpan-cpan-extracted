package MyBuilder;
use base 'Module::Build';

use warnings;
use strict;

use Config;
use Carp;

use Config::AutoConf;
use ExtUtils::LibBuilder;

use ExtUtils::ParseXS;
use ExtUtils::Mkbootstrap;

use File::Spec::Functions qw.catdir catfile.;
use File::Path qw.mkpath.;
use Cwd 'abs_path';

my @EXTRA_FLAGS = ();
my @BINARIES = qw(biblex bibparse dumpnames);

## debug
## @EXTRA_FLAGS = ('-g', "-DDEBUG=2");

sub ACTION_install {
    my $self = shift;

    my $usrlib = $self->install_path( 'usrlib' );

    if ($^O =~ /darwin/i) {
    	my $libpath = $self->notes('lib_path');
    	$libpath = catfile($libpath, "libbtparse$LIBEXT");

    	# do it for binaries as well.
    	`install_name_tool -id "$libpath" ./blib/usrlib/libbtparse.dylib`;
        # binries
        my $libfile = "btparse/src/libbtparse$LIBEXT";
        my $abs_path = abs_path($libfile);
        foreach my $bin (@BINARIES) {
            `install_name_tool -change "$abs_path" "$libpath" ./blib/bin/$bin$EXEEXT`;
        }
        my $bundle = $self->notes("bundle");
        `install_name_tool -change "$abs_path" "$libpath" $bundle`;
 	}

    if ($^O =~ /cygwin/i) { # cygwin uses windows lib searching (PATH instead of LD_LIBRARY_PATH)
        $self->install_path( 'usrlib' => '/usr/local/bin' );
    }
    elsif (defined $self->{properties}{install_base}) {
        $usrlib = catdir($self->{properties}{install_base} => 'lib');
        $self->install_path( 'usrlib' => $usrlib );
    }
    $self->SUPER::ACTION_install;
    if ($^O =~ /linux/ && $ENV{USER} eq 'root') {
        my $linux = Config::AutoConf->check_prog("ldconfig");
        system $linux if (-x $linux);
    }
    if ($^O =~ /(?:linux|bsd|sun|sol|dragonfly|hpux|irix|darwin|gnu)/
        &&
        $usrlib !~ m!^/usr(/local)?/lib/?$!)
      {
          warn "\n** WARNING **\n"
             . "It seems you are installing in a non standard path.\n"
             . "You might need to add $usrlib to your library search path.\n";
      }
    
}

sub ACTION_code {
    my $self = shift;

    for my $path (catdir("blib","bindoc"), catdir("blib","bin")) {
        mkpath $path unless -d $path;
    }

    my $libbuilder = ExtUtils::LibBuilder->new;
    $self->notes('libbuilder', $libbuilder);

    my $version = $self->notes('btparse_version');

    my $alloca_h = 'undef HAVE_ALLOCA_H';
    $alloca_h = 'define HAVE_ALLOCA_H 1' if Config::AutoConf->check_header("alloca.h");

    my $vsnprintf = 'undef HAVE_VSNPRINTF';
    $vsnprintf = 'define HAVE_VSNPRINTF 1' if Config::AutoConf->check_func('vsnprintf');

    my $strlcat = 'undef HAVE_STRLCAT';
    $strlcat = 'define HAVE_STRLCAT 1' if Config::AutoConf->check_func('strlcat');

    _interpolate("btparse/src/bt_config.h.in",
                 "btparse/src/bt_config.h",
                 PACKAGE  => "\"libbtparse\"",
                 FPACKAGE => "\"libbtparse $version\"",
                 VERSION  => "\"$version\"",
                 ALLOCA_H => $alloca_h,
		 VSNPRINTF => $vsnprintf,
		 STRLCAT => $strlcat
                );


    $self->dispatch("create_manpages");
    $self->dispatch("create_objects");
    $self->dispatch("create_library");
    $self->dispatch("create_binaries");
    $self->dispatch("create_tests");

    $self->dispatch("compile_xscode");

    $self->copy_if_modified( from    => 'btparse/src/btparse.h',
                                 to_dir  => "blib/usrinclude",
                                 flatten => 1);

    $self->SUPER::ACTION_code;
}

sub ACTION_compile_xscode {
    my $self = shift;
    my $cbuilder = $self->cbuilder;

    my $archdir = catdir( $self->blib, 'arch', 'auto', 'Text', 'BibTeX');
    mkpath( $archdir, 0, 0777 ) unless -d $archdir;

    print STDERR "\n** Preparing XS code\n";
    my $cfile = catfile("xscode","BibTeX.c");
    my $xsfile= catfile("xscode","BibTeX.xs");

    $self->add_to_cleanup($cfile); ## FIXME
    if (!$self->up_to_date($xsfile, $cfile)) {
        ExtUtils::ParseXS::process_file( filename   => $xsfile,
                                         prototypes => 0,
                                         output     => $cfile);
    }

    my $ofile = catfile("xscode","BibTeX.o");
    $self->add_to_cleanup($ofile); ## FIXME
    if (!$self->up_to_date($cfile, $ofile)) {
        $cbuilder->compile( source               => $cfile,
                            extra_compiler_flags => [@EXTRA_FLAGS],
                            include_dirs         => [ catdir("btparse","src") ],
                            object_file          => $ofile);
    }

    # Create .bs bootstrap file, needed by Dynaloader.
    my $bs_file = catfile( $archdir, "BibTeX.bs" );
    if ( !$self->up_to_date( $ofile, $bs_file ) ) {
        ExtUtils::Mkbootstrap::Mkbootstrap($bs_file);
        if ( !-f $bs_file ) {
            # Create file in case Mkbootstrap didn't do anything.
            open( my $fh, '>', $bs_file ) or confess "Can't open $bs_file: $!";
        }
        utime( (time) x 2, $bs_file );    # touch
    }

    my $objects = $self->rscan_dir("xscode",qr/\.o$/);
    # .o => .(a|bundle)
    my $lib_file = catfile( $archdir, "BibTeX.$Config{dlext}" );
    $self->notes("bundle", $lib_file); # useful for darwin
    if ( !$self->up_to_date( [ @$objects ], $lib_file ) ) {
        my $btparselibdir = $self->install_path('usrlib');
        $cbuilder->link(
                        module_name => 'Text::BibTeX',
                        extra_linker_flags => "-Lbtparse/src -lbtparse ",
                        objects     => $objects,
                        lib_file    => $lib_file,
                       );
    }
}

sub ACTION_create_manpages {
    my $self = shift;

    print STDERR "\n** Creating Manpages\n";

    my $pods = $self->rscan_dir(catdir("btparse","doc"), qr/\.pod$/);

    my $version = $self->notes('btparse_version');
    for my $pod (@$pods) {
        my $man = $pod;
        $man =~ s!.pod!.1!;
        $man =~ s!btparse/doc!blib/bindoc!;   ## FIXME - path
        next if $self->up_to_date($pod, $man);
        ## FIXME
        `pod2man --section=1 --center="btparse" --release="btparse, version $version" $pod $man`;
    }

    my $pod = 'btool_faq.pod';
    my $man = catfile('blib','bindoc','btool_faq.1');
    unless ($self->up_to_date($pod, $man)) {
        ## FIXME
        `pod2man --section=1 --center="btparse" --release="btparse, version $version" $pod $man`;
    }
}

sub ACTION_create_objects {
    my $self = shift;
    my $cbuilder = $self->cbuilder;

    print STDERR "\n** Compiling C files\n";
    my $c_progs = $self->rscan_dir('btparse/progs', qr/\.c$/);
    my $c_src   = $self->rscan_dir('btparse/src',   qr/\.c$/);
    my $c_tests = $self->rscan_dir('btparse/tests', qr/\.c$/);
    my $c_xs    = $self->rscan_dir('xscode/',       qr/\.c$/);

    my @c_files = (@$c_progs, @$c_src, @$c_tests, @$c_xs);
    for my $file (@c_files) {
        my $object = $file;
        $object =~ s/\.c/.o/;
        next if $self->up_to_date($file, $object);
        $cbuilder->compile(object_file  => $object,
                           extra_compiler_flags=>["-D_FORTIFY_SOURCE=1",@EXTRA_FLAGS],
                           source       => $file,
                           include_dirs => ["btparse/src"]);
    }
}


sub ACTION_create_binaries {
    my $self          = shift;
    my $cbuilder      = $self->cbuilder;
    my $libbuilder    = $self->notes('libbuilder');
    my $EXEEXT        = $libbuilder->{exeext};
    my $btparselibdir = $self->install_path('usrlib');

    print STDERR "\n** Creating binaries (",join(", ", map { $_.$EXEEXT } @BINARIES), ")\n";

    my $extra_linker_flags = sprintf("-Lbtparse/src %s -lbtparse ",
                                     ($^O !~ /darwin/)?"-Wl,-R${btparselibdir}":"");

    my @toinstall;

    for my $bin (@BINARIES) {
        my $exe_file = catfile("btparse","progs","$bin$EXEEXT");
        push @toinstall, $exe_file;
        my $objects   = [ catfile("btparse","progs","$bin.o") ];

        if ($bin eq "bibparse") { # hack for now
             $objects   = [map {catfile("btparse","progs","$_.o")} (qw.bibparse args getopt getopt1.)];
        }

        if (!$self->up_to_date($objects, $exe_file)) {
            $libbuilder->link_executable(exe_file => $exe_file,
                                         objects  => $objects ,
                                         extra_linker_flags => $extra_linker_flags);
        }
    }   

    for my $file (@toinstall) {
        $self->copy_if_modified( from    => $file,
                                 to_dir  => "blib/bin",
                                 flatten => 1);
    }

}

sub ACTION_create_tests {
    my $self = shift;
    my $cbuilder = $self->cbuilder;

    my $libbuilder = $self->notes('libbuilder');
    my $EXEEXT = $libbuilder->{exeext};

    print STDERR "\n** Creating test binaries\n";

    my $exe_file = catfile("btparse","tests","simple_test$EXEEXT");
    my $objects  = [ map{catfile("btparse","tests","$_.o")} (qw.simple_test testlib.) ];

    if (!$self->up_to_date($objects, $exe_file)) {
        $libbuilder->link_executable(exe_file => $exe_file,
                                     extra_linker_flags => '-Lbtparse/src -lbtparse ',
                                     objects => $objects);
    }

    $exe_file = catfile("btparse","tests","read_test$EXEEXT");
    $objects  = [ map{catfile("btparse","tests","$_.o")}(qw.read_test testlib.) ];
    if (!$self->up_to_date($objects, $exe_file)) {
        $libbuilder->link_executable(exe_file => $exe_file,
                                     extra_linker_flags => '-Lbtparse/src -lbtparse ',
                                     objects => $objects);
    }

    $exe_file = catfile("btparse","tests","postprocess_test$EXEEXT");
    $objects  = [ map{catfile("btparse","tests","$_.o")}(qw.postprocess_test.) ];
    if (!$self->up_to_date($objects, $exe_file)) {
        $libbuilder->link_executable(exe_file => $exe_file,
                                     extra_linker_flags => '-Lbtparse/src -lbtparse ',
                                     objects => $objects);
    }

    $exe_file = catfile("btparse","tests","tex_test$EXEEXT");
    $objects  = [ map{catfile("btparse","tests","$_.o")}(qw.tex_test.) ];
    if (!$self->up_to_date($objects, $exe_file)) {
        $libbuilder->link_executable(exe_file => $exe_file,
                                     extra_linker_flags => '-Lbtparse/src -lbtparse ',
                                     objects => $objects);
    }

    $exe_file = catfile("btparse","tests","macro_test$EXEEXT");
    $objects  = [ map{catfile("btparse","tests","$_.o")}(qw.macro_test.) ];
    if (!$self->up_to_date($objects, $exe_file)) {
        $libbuilder->link_executable(exe_file => $exe_file,
                                     extra_linker_flags => '-Lbtparse/src -lbtparse ',
                                     objects => $objects);
    }

    $exe_file = catfile("btparse","tests","name_test$EXEEXT");
    $objects  = [ map{catfile("btparse","tests","$_.o")}(qw.name_test.) ];
    if (!$self->up_to_date($objects, $exe_file)) {
        $libbuilder->link_executable(exe_file => $exe_file,
                                     extra_linker_flags => '-Lbtparse/src -lbtparse ',
                                     objects => $objects);
    }

    $exe_file = catfile("btparse","tests","namebug$EXEEXT");
    $objects  = [ map{catfile("btparse","tests","$_.o")}(qw.namebug.) ];
    if (!$self->up_to_date($objects, $exe_file)) {
        $libbuilder->link_executable(exe_file => $exe_file,
                                     extra_linker_flags => '-Lbtparse/src -lbtparse ',
                                     objects => $objects);
    }

    $exe_file = catfile("btparse","tests","purify_test$EXEEXT");
    $objects  = [ map{catfile("btparse","tests","$_.o")}(qw.purify_test.) ];
    if (!$self->up_to_date($objects, $exe_file)) {
        $libbuilder->link_executable(exe_file => $exe_file,
                                     extra_linker_flags => '-Lbtparse/src -lbtparse ',
                                     objects => $objects);
    }
}

sub ACTION_create_library {
    my $self = shift;
    my $cbuilder = $self->cbuilder;


    my $libbuilder = $self->notes('libbuilder');
    my $LIBEXT = $libbuilder->{libext};

    print STDERR "\n** Creating libbtparse$LIBEXT\n";

    my @modules = qw:init input bibtex err scan error
                     lex_auxiliary parse_auxiliary bibtex_ast sym
                     util postprocess macros traversal modify
                     names tex_tree string_util format_name:;

    my @objects = map { "btparse/src/$_.o" } @modules;

    my $libpath = $self->notes('lib_path');
    $libpath = catfile($libpath, "libbtparse$LIBEXT");
    my $libfile = "btparse/src/libbtparse$LIBEXT";

    my $extra_linker_flags = "";
    if ($^O =~ /darwin/) {
       my $abs_path = abs_path($libfile);
       $extra_linker_flags = "-install_name $abs_path";
    } elsif ($LIBEXT eq ".so") {
        $extra_linker_flags = "-Wl,-soname,libbtparse$LIBEXT";
    }

    if (!$self->up_to_date(\@objects, $libfile)) {
        $libbuilder->link(module_name        => 'btparse',
                          objects            => \@objects,
                          lib_file           => $libfile,
                          extra_linker_flags => $extra_linker_flags);
    }

    my $libdir = catdir($self->blib, 'usrlib');
    mkpath( $libdir, 0, 0777 ) unless -d $libdir;

    $self->copy_if_modified( from   => $libfile,
                             to_dir => $libdir,
                             flatten => 1 );
}

sub ACTION_test {
    my $self = shift;

    if ($^O =~ /darwin/i) {
        $ENV{DYLD_LIBRARY_PATH} = catdir($self->blib, "usrlib");
    }
    elsif ($^O =~ /(?:linux|bsd|sun|sol|dragonfly|hpux|irix|gnu)/i) {
        $ENV{LD_LIBRARY_PATH} = catdir($self->blib, "usrlib");
    }
    elsif ($^O =~ /aix/i) {
        my $oldlibpath = $ENV{LIBPATH} || '/lib:/usr/lib';
        $ENV{LIBPATH} = catdir($self->blib, "usrlib").":$oldlibpath";
    }
    elsif ($^O =~ /cygwin/i) {
        # cygwin uses windows lib searching (PATH instead of LD_LIBRARY_PATH)
        my $oldpath = $ENV{PATH};
        $ENV{PATH} = catdir($self->blib, "usrlib").":$oldpath";
    }
    elsif ($^O =~ /mswin32/i) {
        my $oldpath = $ENV{PATH};
        $ENV{PATH} = catdir($self->blib, "usrlib").";$oldpath";
    }
    $self->SUPER::ACTION_test
}


sub _interpolate {
    my ($from, $to, %config) = @_;

    print "Creating new '$to' from '$from'.\n";
    open FROM, $from or die "Cannot open file '$from' for reading.\n";
    open TO, ">", $to or die "Cannot open file '$to' for writing.\n";
    while (<FROM>) {
        s/\[%\s*(\S+)\s*%\]/$config{$1}/ge;		
        print TO;
    }
    close TO;
    close FROM;
}


1;
