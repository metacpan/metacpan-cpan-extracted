use strict;
use warnings;
use Config;
use Devel::CheckLib;
use ExtUtils::MakeMaker;

# buffering will ruin your day!
select STDERR; $|=1;
select STDOUT; $|=1;

# prereqs
my $CONF_version = 0;      # Config
my $DL_version   = 0;      # DynaLoader
my $EX_version   = 0;      # Exporter
my $FS_version   = 0;      # File::Spec
my $HRT_version  = 0;      # Time::HiRes
my $DC_version   = '1.14'; # Devel::CheckLib
my $EUMM_version = '7.06'; # ExtUtils::MakeMaker
my $FT_version   = '0.10'; # File::Temp
my $LU_version   = '1.29'; # List::Util
my $TM_version   = '0.88'; # Test::More
my $V_version    = '0.77'; # version

my $UUID_version = get_uuidpm_version();

# Authority poisons everybody who takes
# authority on himself.
#                     -- Vladimir Lenin
my $no_mymeta = ($UUID_version =~ /_/) ? 1 : 0;

my ($libs, $defines) = check_flags();
my $has_threads      = check_threads();

WriteMakefile1(
    'NAME'             => 'UUID',
    'AUTHOR'           => 'Rick Myers <jrm@cpan.org>',
    'VERSION_FROM'     => 'UUID.pm',
    'ABSTRACT_FROM'    => 'UUID.pm',
    'LICENSE'          => 'artistic_2',
    'MIN_PERL_VERSION' => '5.005063', # for U64
    'LIBS'             => $libs,
    'NO_MYMETA'        => $no_mymeta,
    'INC'              => '-I.',
    'CCFLAGS'          => $Config{ccflags},
    'DEFINE'           => $defines,
    'OBJECT'           => '$(O_FILES)',
    'LDFROM'           => join( ' ', qw{
        UUID.o ulib/chacha.o ulib/clear.o ulib/clock.o ulib/compare.o
        ulib/copy.o ulib/gen.o ulib/gettime.o ulib/isnull.o ulib/md5.o
        ulib/node.o ulib/pack.o ulib/parse.o ulib/sha1.o ulib/splitmix.o
        ulib/unpack.o ulib/unparse.o ulib/util.o ulib/xoshiro.o
    }),
    'C' => [qw{
        UUID.c ulib/chacha.c ulib/clear.c ulib/clock.c ulib/compare.c
        ulib/copy.c ulib/gen.c ulib/gettime.c ulib/isnull.c ulib/md5.c
        ulib/node.c ulib/pack.c ulib/parse.c ulib/sha1.c ulib/splitmix.c
        ulib/unpack.c ulib/unparse.c ulib/util.c ulib/xoshiro.c
    }],
    'H' => [qw{
        ulib/EUMM.h ulib/PORT.h ulib/TYPE.h ulib/UUID.h ulib/chacha.h
        ulib/clear.h ulib/clock.h ulib/compare.h ulib/copy.h ulib/md5.h
        ulib/isnull.h ulib/gen.h ulib/gettime.h ulib/node.h ulib/pack.h
        ulib/parse.h ulib/sha1.h ulib/splitmix.h ulib/unpack.h
        ulib/unparse.h ulib/util.h ulib/xoshiro.h
    }],
    'PREREQ_PM'          => {
        'Carp'        => 0,
        'DynaLoader'  => $DL_version,
        'Exporter'    => $EX_version,
        'Time::HiRes' => $HRT_version,
        'strict'      => 0,
        'vars'        => 0,
        'warnings'    => 0,
    },
    'CONFIGURE_REQUIRES' => {
        'Config'              => $CONF_version,
        'Devel::CheckLib'     => $DC_version,
        'ExtUtils::MakeMaker' => $EUMM_version,
        'strict'              => 0,
        'warnings'            => 0,
    },
    'BUILD_REQUIRES' => {
        'Config'              => $CONF_version,
        'Devel::CheckLib'     => $DC_version,
        'ExtUtils::MakeMaker' => $EUMM_version,
        'File::Spec'          => $FS_version,
        'File::Temp'          => $FT_version,
        'List::Util'          => $LU_version,
        'strict'              => 0,
        'warnings'            => 0,
    },
    'TEST_REQUIRES' => {
        'Benchmark'          => 0,
        'Config'             => $CONF_version,
        'CPAN::Meta'         => 0,
        'DynaLoader'         => $DL_version,
        'Exporter'           => $EX_version,
        'ExtUtils::Manifest' => 0,
        'File::Spec'         => $FS_version,
        'File::Temp'         => $FT_version,
        'Test::More'         => $TM_version,
        'Time::HiRes'        => $HRT_version,
        'Try::Tiny'          => 0,
        'lib'                => 0,
        'strict'             => 0,
        'vars'               => 0,
        'version'            => $V_version,
        'warnings'           => 0,
        ( $has_threads
            ? (
            'threads'           => 0,
            'threads::shared'   => 0,
            'Thread::Semaphore' => 0,
            )
            : ()
        ),
    },
    'META_MERGE' => {
        'dynamic_config' => 0,
        'provides' => {
            'UUID' => {
                'file'    => 'UUID.pm',
                'version' => $UUID_version,
            },
        },
    },
    'realclean' => {
        'FILES' => join( ' ', sort qw{
            LICENSE_new
            META_new.json
            META_new.yml
            README_new
            README_new.bak
            UUID.obj
            UUID.pdb
            UUID.xsc
            assertconf*.h
            assertconf*.txt
            assertlib*.c
            assertlib*.exe
            assertlib*.obj
            asserttest*
            perl.core
            perl.exe.stackdump
            ulib/*.obj
            ulib/*.pdb
            ulib/EUMM.h
            uu_to_blib
        }),
    },
);

exit 0;

sub WriteMakefile1 {  #Written by Alexandr Ciornii, version 0.21. Added by eumm-upgrade.
    my %params=@_;
    my $eumm_version=$ExtUtils::MakeMaker::VERSION;
    $eumm_version=eval $eumm_version;
    die "EXTRA_META is deprecated" if exists $params{EXTRA_META};
    die "LICENSE not specified" if not exists $params{LICENSE};
    if ($params{BUILD_REQUIRES} and $eumm_version < 6.5503) {
        #EUMM 6.5502 has problems with BUILD_REQUIRES
        $params{PREREQ_PM}={ %{$params{PREREQ_PM} || {}} , %{$params{BUILD_REQUIRES}} };
        delete $params{BUILD_REQUIRES};
    }
    delete $params{TEST_REQUIRES} if $eumm_version < 6.64;
    delete $params{CONFIGURE_REQUIRES} if $eumm_version < 6.52;
    delete $params{MIN_PERL_VERSION} if $eumm_version < 6.48;
    delete $params{META_MERGE} if $eumm_version < 6.46;
    delete $params{META_ADD} if $eumm_version < 6.46;
    delete $params{LICENSE} if $eumm_version < 6.31;
    delete $params{NO_MYMETA} if $eumm_version < 6.58;
    delete $params{AUTHOR} if $] < 5.005;
    delete $params{ABSTRACT_FROM} if $] < 5.005;
    delete $params{BINARY_LOCATION} if $] < 5.005;

    WriteMakefile(%params);
}

sub get_uuidpm_version {
    open my $fh, '<', 'UUID.pm' or die "open: UUID.pm: $!";
    while (<$fh>) {
        # $VERSION = '0.30_02';
        return $1
            if /^\$VERSION = '([\d\.\_]+)';$/;
    }
    return undef;
}

sub check_flags {
    my $defs = [];
    my $libs = [];
    my $long = 0;

    for my $check ( 1, 0 ) {

        # this is to turn off the copious amount of spewage seen compiling
        # xs code on freebsd.
        # WISHLIST: would be nice if we could inspect the compiler output
        # from building the test file. would like to see if there was a
        # "unsupported command line option" warning. looks like it would
        # be a good bit of work though.
        try_compound($check, \$long, $defs, '-Wno-compound-token-split-by-macro');

        # -liphlpapi is needed for win32 real node discovery.
        try_iphlpapi($check, \$long, $libs, '-liphlpapi');
        #... more ?
    }

    return join(' ', @$libs), join(' ', @$defs);
}

sub check_threads {
    # return true/false
    $Config{useithreads} ? 1 : 0;
}

sub try_compound {
    my ($check, $long, $flags, $try) = @_;
    my $msg = join ' ', 'Checking compound token switch';
    my $len = length $msg;
    if ($check) { $$long = $len if $len > $$long; return; }
    my $more = $$long - $len;
    if ( check_lib(
        lib     => 'c', # always do at least this
        ccflags => $try,
        debug   => 0,
    )) {
        push @$flags, $try;
        print $msg, ' ..', '.'x$more, " works\n";
    }
    else {
        print $msg, ' ..', '.'x$more, " fails\n";
    }
}

sub try_iphlpapi {
    my ($check, $long, $libs, $try) = @_;
    my $msg = join ' ', 'Checking lib iphlpapi';
    my $len = length $msg;
    if ($check) { $$long = $len if $len > $$long; return; }
    my $more = $$long - $len;

    # dont link unless its a native build.
    my $is_win32  = $^O eq 'MSWin32'         ? 1 : 0;
    my $is_nmake  = $Config{make} eq 'nmake' ? 1 : 0;
    my $is_native = $is_win32 && $is_nmake   ? 1 : 0;

    if ( $is_native && check_lib(
        lib   => 'iphlpapi',
        debug => 0,
    )) {
        push @$libs, $try;
        print $msg, ' ..', '.'x$more, " works\n";
    }
    else {
        print $msg, ' ..', '.'x$more, " fails\n";
    }
}



package MY;
use Config;


#
# add 'compare' target.
#
sub top_targets {
    my $t = shift->SUPER::top_targets(@_);
    # add 'compare' targets.
    $t .= "\nspeeds : dynamic pure_all\n";
    $t .= "\t\$(NOECHO) \$(ABSPERLRUN) -Iblib\$(DFSEP)lib -Iblib\$(DFSEP)arch ubin\$(DFSEP)cmp_speeds.pl 1\n";
    $t .= "\n";
    $t .= "\nstyles : dynamic pure_all\n";
    $t .= "\t\$(NOECHO) \$(ABSPERLRUN) -Iblib\$(DFSEP)lib -Iblib\$(DFSEP)arch ubin\$(DFSEP)cmp_styles.pl 1\n";
    $t .= "\n";
    $t .= "\npersist : dynamic pure_all\n";
    $t .= "\t\$(NOECHO) \$(ABSPERLRUN) -Iblib\$(DFSEP)lib -Iblib\$(DFSEP)arch ubin\$(DFSEP)cmp_persist.pl 1\n";
    $t .= "\n";
    $t .= "\ncompare : speeds styles persist\n";
    $t .= "\t\$(NOECHO) \$(NOOP)";
    # remove blibdirs from config prereq.
    $t =~ s{^(config\s*::.*)\s+blibdirs} {$1}m;
    # change pure_all prereqs
    $t =~ s{^(pure_all\s*::\s*).*$} {$1 config blibdirs dynamic bootstrap uu_to_blib}m;
    $t;
}


#
# add distlicense and distreadme prereqs.
## silence manicopy step during config.
#
sub distdir {
    my $t = shift->SUPER::distdir(@_);
    $t =~ s{^(distdir :).*$}{$1 create_distdir license metafile readme distlicense distmeta distreadme}m;
    #$t =~ s{PERLRUN}{NOECHO) \$(PERLRUN};
    $t;
}


#
# remove metafile comments in manifest.
# make metafiles authoritative to cpan.
#
sub distmeta {
    my $t = <<'EOS';
distmeta : create_distdir license metafile readme
	$(NOECHO) $(ECHO) Adding META.json to MANIFEST
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -MExtUtils::Manifest=maniadd \
	  -e "die 'No META.json' unless -f 'META.json';" \
	  -e "die 'No MANIFEST' unless -f 'MANIFEST';" \
	  -e "eval { maniadd({ 'META.json' => '' }) }" \
	  -e "    or die \"Could not add META.json to MANIFEST: $$ @\"" --
	$(NOECHO) $(ECHO) Adding META.yml to MANIFEST
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -MExtUtils::Manifest=maniadd \
	  -e "die 'No META.yml' unless -f 'META.yml';" \
	  -e "die 'No MANIFEST' unless -f 'MANIFEST';" \
	  -e "eval { maniadd({ 'META.yml' => '' }) }" \
	  -e "    or die \"Could not add META.yml to MANIFEST: $$ @\"" --
EOS
    $t;
}


#
# re-order meta generation
#
sub metafile {
    my $t = shift->SUPER::metafile_target(@_);
    $t =~ s{^(metafile :.*)$} {$1 meta_json meta_yml}m;
    $t =~ s{^(\s+.+Generating META.yml.*)$}  {\nmeta_yml :\n$1}m;
    $t =~ s{^(\s+.+Generating META.json.*)$} {\nmeta_json :\n$1}m;
    $t;
}


#
# add UUID_DISTTEST flag to 'make disttest'
#
sub dist_test {
    my $t = shift->SUPER::dist_test(@_);
    $t =~ s{ test }{ test UUID_DISTTEST=1 };
    $t;
}


#
# make TEST_VERBOSE=1 when AUTOMATED_TESTING=1.
# add t/*/*.t to tests.
# add TEST_LIB variable, set to t/lib.
# insert TEST_LIB before other libs.
#
sub test {
    my $t = shift->SUPER::test(@_);
    #
    # make TEST_VERBOSE=1 when AUTOMATED_TESTING=1.
    if ( $ENV{AUTOMATED_TESTING}
        or $ENV{NONINTERACTIVE_TESTING}
        or $ENV{PERL_CPAN_REPORTER_CONFIG}
    ) {
        $t =~ s{TEST_VERBOSE=0}{TEST_VERBOSE=1}msg;
    }
    #
    # add t/*/*.t to tests.
    $t =~ s{^(TEST_FILES\s*=\s*).+$} {$1 t\$(DFSEP)*.t t\$(DFSEP)*\$(DFSEP)*.t}m;
    #
    # add TEST_LIB variable, set to t/lib.
    $t =~ s{^} {TEST_LIB=t\$(DFSEP)0LIB\n}s;
    #
    # insert TEST_LIB before other libs.
    $t =~ s{(\S+)(INST_LIB)(\S+)} {${1}TEST_LIB$3 $1$2$3}g;
    $t;
}


#
# silence "cp_nonempty" bootstrap.
# silence chmod bootstrap.
# remove implicit rules and make our own!
# (some seem to use the implicits first?)
#
sub xs_c { '' }
sub xs_o { '' }
sub dynamic_bs {
    my $t = shift->SUPER::dynamic_bs(@_);
    # add bootstrap target
    $t =~ s{$} {\n\nbootstrap : \$(BASEEXT).bs\n\t\$(NOECHO) \$(NOOP)}m;
    # delay Mkbootstrap() until after c files
    $t =~ s{^(\S+BASEEXT\S+\s*:\s+.+$)} {$1 \$(O_FILES)}m;
    # silence chmod
    $t =~ s{CHMOD} {NOECHO) \$(CHMOD}sg;
    $t;
}
sub perldepend {
    my $t = shift->SUPER::perldepend(@_);
    # make UUID.c depend on UUID.xs and EUMM.h
    $t =~ s{$} { UUID.xs \$(ulib_EUMM).h}s;
    # run xsubpp
    $t .= "\t". '$(XSUBPPRUN) $(XSPROTOARG) $(XSUBPPARGS) $(XSUBPP_EXTRA_ARGS) UUID.xs > UUID.xsc'. "\n";
    $t .= "\t". '$(MV) UUID.xsc UUID.c';
    $t;
}
sub blibdirs {
    my $t = shift->SUPER::blibdirs_target();
    # add EUMM.h as prereq to blibdirs.
    $t =~ s{^(blibdirs\s*:\s*)(\S.*)$} {$1\$(ulib_EUMM).h $2}m;
    $t;
}


#
# remove targets in dynamic_lib section. we do them manually later.
#
sub dynamic_lib {
    my $t = shift->SUPER::dynamic_lib(@_);
    $t =~ s{\n\n.+$} {\n}ms;
    $t;
}


#
# remove most prereqs from dynamic.
#
sub dynamic {
    my $t = shift->SUPER::dynamic(@_);
    # remove most prereqs from dynamic.
    $t =~ s{^(dynamic\s*::)\s+\S+\s+\S+\s+\S+\s+(\S+)\s*$} {$1 $2}m;
    $t;
}


#
# our variables.
# also add ulib/EUMM.h as prereq for pm_to_blib.
#
sub constants {
    my $t = shift->SUPER::constants(@_);
    my $v = <<'EOPC';
ubin_configure = ubin$(DFSEP)configure.pl
ulib_EUMM      = ulib$(DFSEP)EUMM
ulib_TYPE      = ulib$(DFSEP)TYPE
ulib_UUID      = ulib$(DFSEP)UUID
ulib_chacha    = ulib$(DFSEP)chacha
ulib_clear     = ulib$(DFSEP)clear
ulib_clock     = ulib$(DFSEP)clock
ulib_compare   = ulib$(DFSEP)compare
ulib_copy      = ulib$(DFSEP)copy
ulib_gen       = ulib$(DFSEP)gen
ulib_gettime   = ulib$(DFSEP)gettime
ulib_isnull    = ulib$(DFSEP)isnull
ulib_md5       = ulib$(DFSEP)md5
ulib_node      = ulib$(DFSEP)node
ulib_pack      = ulib$(DFSEP)pack
ulib_parse     = ulib$(DFSEP)parse
ulib_sha1      = ulib$(DFSEP)sha1
ulib_splitmix  = ulib$(DFSEP)splitmix
ulib_unpack    = ulib$(DFSEP)unpack
ulib_unparse   = ulib$(DFSEP)unparse
ulib_util      = ulib$(DFSEP)util
ulib_xoshiro   = ulib$(DFSEP)xoshiro
EOPC
    # also add ulib/EUMM.h as prereq for pm_to_blib.
    # terrible hack due to MY::pm_to_blib() never called.
    $t =~ s{^(TO_INST_PM.+)$} {$v\n$1}m;
    #$t =~ s{^(TO_INST_PM.+)$} {$v\n$1 \$(ulib_EUMM).h}m;
    $t;
}


#
# add distlicense and distreadme targets.
# add autoconf generated targets.
# add explicit object rules.
#
sub postamble {
    my $pa = <<'EOP';
# Software::License requires perl-5.12.0
license: create_distdir
	$(NOECHO) $(ECHO) Generating LICENSE
	$(NOECHO) $(RM_F) LICENSE_new
	$(NOECHO) $(ABSPERLRUN) -M5.12.0 -MSoftware::License::Artistic_2_0 \
	  -e 'print Software::License::Artistic_2_0->new({holder => "Rick Myers", year => sprintf("2014-%04d", 1900+(localtime(time))[5])})->fulltext' \
	  > LICENSE_new
	$(NOECHO) $(MV) LICENSE_new $(DISTVNAME)$(DFSEP)LICENSE

distlicense: create_distdir license
	$(NOECHO) $(ECHO) Adding LICENSE to MANIFEST
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -MExtUtils::Manifest=maniadd \
	  -e "die 'No LICENSE' unless -f 'LICENSE';" \
	  -e "die 'No MANIFEST' unless -f 'MANIFEST';" \
	  -e "eval { maniadd({ 'LICENSE' => '' }) }" \
	  -e "    or die \"Could not add LICENSE to MANIFEST: $$ @\"" --
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -e "print sort <>" MANIFEST > MANIFEST_new
	$(NOECHO) $(MV) $(DISTVNAME)$(DFSEP)MANIFEST_new $(DISTVNAME)$(DFSEP)MANIFEST

readme: create_distdir
	$(NOECHO) $(ECHO) Generating README
	$(NOECHO) $(RM_F) README_new
	$(NOECHO) pod2text UUID.pm README_new
	$(NOECHO) $(ABSPERLRUN) -i.bak -pe's{\*(\S+)\*}{\1}g' README_new
	$(NOECHO) $(RM_F) README_new.bak
	$(NOECHO) $(MV) README_new $(DISTVNAME)$(DFSEP)README

distreadme: create_distdir readme
	$(NOECHO) $(ECHO) Adding README to MANIFEST
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -MExtUtils::Manifest=maniadd \
	  -e "die 'No README' unless -f 'README';" \
	  -e "die 'No MANIFEST' unless -f 'MANIFEST';" \
	  -e "eval { maniadd({ 'README' => '' }) }" \
	  -e "    or die \"Could not add README to MANIFEST: $$ @\"" --
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -e "print sort <>" MANIFEST > MANIFEST_new
	$(NOECHO) $(MV) $(DISTVNAME)$(DFSEP)MANIFEST_new $(DISTVNAME)$(DFSEP)MANIFEST

config :: $(ubin_configure) $(ulib_EUMM).h
	$(NOECHO) $(NOOP)

uu_to_blib : UUID.pm $(BASEEXT).bs
	$(CP) UUID.pm $(INST_LIB)$(DFSEP)UUID.pm
	$(NOECHO) $(CHMOD) $(PERM_RW) $(INST_LIB)$(DFSEP)UUID.pm
	$(NOECHO) $(TOUCH) uu_to_blib

deps = $(XSUBPPDEPS) $(ulib_EUMM).h
cccmd = $(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE)

$(ulib_EUMM).h : $(ubin_configure)
	$(NOECHO) $(ECHO) Generating EUMM.h
	$(NOECHO) $(RM_F) $(ulib_EUMM).h       $(ulib_EUMM).h.tmp
	$(NOECHO) $(PERL) -l $(ubin_configure) $(ulib_EUMM).h.tmp
	$(NOECHO) $(MV)   $(ulib_EUMM).h.tmp   $(ulib_EUMM).h


UUID.obj             : $(deps) UUID.c
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) -Fd$(*).pdb $*.c

$(ulib_chacha).obj   : $(deps) $(ulib_chacha).c $(ulib_chacha).h
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) -Fd$(*).pdb -Fo$(*).obj $*.c

$(ulib_clear).obj    : $(deps) $(ulib_clear).c $(ulib_clear).h
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) -Fd$(*).pdb -Fo$(*).obj $*.c

$(ulib_clock).obj    : $(deps) $(ulib_clock).c $(ulib_clock).h
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) -Fd$(*).pdb -Fo$(*).obj $*.c

$(ulib_compare).obj  : $(deps) $(ulib_compare).c $(ulib_compare).h
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) -Fd$(*).pdb -Fo$(*).obj $*.c

$(ulib_copy).obj     : $(deps) $(ulib_copy).c $(ulib_copy).h
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) -Fd$(*).pdb -Fo$(*).obj $*.c

$(ulib_gen).obj      : $(deps) $(ulib_gen).c $(ulib_gen).h
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) -Fd$(*).pdb -Fo$(*).obj $*.c

$(ulib_gettime).obj  : $(deps) $(ulib_gettime).c $(ulib_gettime).h
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) -Fd$(*).pdb -Fo$(*).obj $*.c

$(ulib_isnull).obj   : $(deps) $(ulib_isnull).c $(ulib_isnull).h
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) -Fd$(*).pdb -Fo$(*).obj $*.c

$(ulib_md5).obj      : $(deps) $(ulib_md5).c $(ulib_md5).h
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) -Fd$(*).pdb -Fo$(*).obj $*.c

$(ulib_node).obj     : $(deps) $(ulib_node).c $(ulib_node).h
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) -Fd$(*).pdb -Fo$(*).obj $*.c

$(ulib_pack).obj     : $(deps) $(ulib_pack).c $(ulib_pack).h
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) -Fd$(*).pdb -Fo$(*).obj $*.c

$(ulib_parse).obj    : $(deps) $(ulib_parse).c $(ulib_parse).h
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) -Fd$(*).pdb -Fo$(*).obj $*.c

$(ulib_sha1).obj     : $(deps) $(ulib_sha1).c $(ulib_sha1).h
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) -Fd$(*).pdb -Fo$(*).obj $*.c

$(ulib_splitmix).obj : $(deps) $(ulib_splitmix).c $(ulib_splitmix).h
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) -Fd$(*).pdb -Fo$(*).obj $*.c

$(ulib_unpack).obj   : $(deps) $(ulib_unpack).c $(ulib_unpack).h
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) -Fd$(*).pdb -Fo$(*).obj $*.c

$(ulib_unparse).obj  : $(deps) $(ulib_unparse).c $(ulib_unparse).h
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) -Fd$(*).pdb -Fo$(*).obj $*.c

$(ulib_util).obj     : $(deps) $(ulib_util).c $(ulib_util).h
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) -Fd$(*).pdb -Fo$(*).obj $*.c

$(ulib_xoshiro).obj  : $(deps) $(ulib_xoshiro).c $(ulib_xoshiro).h
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) -Fd$(*).pdb -Fo$(*).obj $*.c


UUID.o             : $(deps) UUID.c
	$(cccmd) UUID.c             -o UUID.o

$(ulib_chacha).o   : $(deps) $(ulib_chacha).c $(ulib_chacha).h
	$(cccmd) $(ulib_chacha).c   -o $(ulib_chacha).o

$(ulib_clear).o    : $(deps) $(ulib_clear).c    $(ulib_clear).h
	$(cccmd) $(ulib_clear).c    -o $(ulib_clear).o

$(ulib_clock).o    : $(deps) $(ulib_clock).c    $(ulib_clock).h
	$(cccmd) $(ulib_clock).c    -o $(ulib_clock).o

$(ulib_compare).o  : $(deps) $(ulib_compare).c  $(ulib_compare).h
	$(cccmd) $(ulib_compare).c  -o $(ulib_compare).o

$(ulib_copy).o     : $(deps) $(ulib_copy).c     $(ulib_copy).h
	$(cccmd) $(ulib_copy).c     -o $(ulib_copy).o

$(ulib_gen).o      : $(deps) $(ulib_gen).c      $(ulib_gen).h
	$(cccmd) $(ulib_gen).c      -o $(ulib_gen).o

$(ulib_gettime).o  : $(deps) $(ulib_gettime).c  $(ulib_gettime).h
	$(cccmd) $(ulib_gettime).c  -o $(ulib_gettime).o

$(ulib_isnull).o   : $(deps) $(ulib_isnull).c   $(ulib_isnull).h
	$(cccmd) $(ulib_isnull).c   -o $(ulib_isnull).o

$(ulib_md5).o      : $(deps) $(ulib_md5).c      $(ulib_md5).h
	$(cccmd) $(ulib_md5).c      -o $(ulib_md5).o

$(ulib_node).o     : $(deps) $(ulib_node).c     $(ulib_node).h
	$(cccmd) $(ulib_node).c     -o $(ulib_node).o

$(ulib_pack).o     : $(deps) $(ulib_pack).c     $(ulib_pack).h
	$(cccmd) $(ulib_pack).c     -o $(ulib_pack).o

$(ulib_parse).o    : $(deps) $(ulib_parse).c    $(ulib_parse).h
	$(cccmd) $(ulib_parse).c    -o $(ulib_parse).o

$(ulib_sha1).o     : $(deps) $(ulib_sha1).c    $(ulib_sha1).h
	$(cccmd) $(ulib_sha1).c     -o $(ulib_sha1).o

$(ulib_splitmix).o : $(deps) $(ulib_splitmix).c $(ulib_splitmix).h
	$(cccmd) $(ulib_splitmix).c -o $(ulib_splitmix).o

$(ulib_unpack).o   : $(deps) $(ulib_unpack).c   $(ulib_unpack).h
	$(cccmd) $(ulib_unpack).c   -o $(ulib_unpack).o

$(ulib_unparse).o  : $(deps) $(ulib_unparse).c  $(ulib_unparse).h
	$(cccmd) $(ulib_unparse).c  -o $(ulib_unparse).o

$(ulib_util).o     : $(deps) $(ulib_util).c     $(ulib_util).h
	$(cccmd) $(ulib_util).c     -o $(ulib_util).o

$(ulib_xoshiro).o  : $(deps) $(ulib_xoshiro).c  $(ulib_xoshiro).h
	$(cccmd) $(ulib_xoshiro).c  -o $(ulib_xoshiro).o


EOP

    if ($Config{make} eq 'nmake') {
        $pa .= <<'EOP';
$(INST_DYNAMIC) : \
	UUID.obj \
	ulib/chacha.obj \
	ulib/clear.obj \
	ulib/clock.obj \
	ulib/compare.obj \
	ulib/copy.obj \
	ulib/copy.obj \
	ulib/gen.obj \
	ulib/gettime.obj \
	ulib/isnull.obj \
	ulib/md5.obj \
	ulib/node.obj \
	ulib/pack.obj \
	ulib/parse.obj \
	ulib/sha1.obj \
	ulib/splitmix.obj \
	ulib/unpack.obj \
	ulib/unparse.obj \
	ulib/util.obj \
	ulib/xoshiro.obj \
	$(INST_ARCHAUTODIR)$(DFSEP).exists $(EXPORT_LIST) \
	$(PERL_ARCHIVEDEP) $(INST_DYNAMIC_DEP)
	$(LD) -out:$@ $(LDDLFLAGS) \
	UUID.obj \
	ulib/chacha.obj \
	ulib/clear.obj \
	ulib/clock.obj \
	ulib/compare.obj \
	ulib/copy.obj \
	ulib/gen.obj \
	ulib/gettime.obj \
	ulib/isnull.obj \
	ulib/md5.obj \
	ulib/node.obj \
	ulib/pack.obj \
	ulib/parse.obj \
	ulib/sha1.obj \
	ulib/splitmix.obj \
	ulib/unpack.obj \
	ulib/unparse.obj \
	ulib/util.obj \
	ulib/xoshiro.obj \
	$(OTHERLDFLAGS) $(MYEXTLIB) "$(PERL_ARCHIVE)" $(LDLOADLIBS) \
	-def:$(EXPORT_LIST)
	if exist $@.manifest mt -nologo -manifest $@.manifest -outputresource:$@;2
	if exist $@.manifest del $@.manifest
	$(CHMOD) $(PERM_RWX) $@
EOP
    }
    else {
        $pa .= <<'EOP';
$(INST_DYNAMIC) : $(OBJECT) $(MYEXTLIB) $(INST_ARCHAUTODIR)$(DFSEP).exists \
	$(EXPORT_LIST) $(PERL_ARCHIVEDEP) $(PERL_ARCHIVE_AFTER) $(INST_DYNAMIC_DEP)
	$(RM_F) $@
	$(LD) $(LDDLFLAGS) $(LDFROM) $(OTHERLDFLAGS) -o $@ $(MYEXTLIB) $(PERL_ARCHIVE) $(LDLOADLIBS) $(PERL_ARCHIVE_AFTER) $(EXPORT_LIST) $(INST_DYNAMIC_FIX)
	$(NOECHO) $(CHMOD) $(PERM_RWX) $@
EOP
    }

    return $pa;
}
