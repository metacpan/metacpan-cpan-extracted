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
my $EX_version   = 0;      # Exporter
my $DL_version   = 0;      # DynaLoader
my $TM_version   = 0;      # Test::More
my $DC_version   = 0;      # Devel::CheckLib
my $EUMM_version = '6.64'; # ExtUtils::MakeMaker

my $UUID_version = get_uuidpm_version();

# Authority poisons everybody who takes
# authority on himself.
#                     -- Vladimir Lenin
my $no_mymeta = ($UUID_version =~ /_/) ? 1 : 0;

my $defines = check_defines();

WriteMakefile1(
    'NAME'             => 'UUID',
    'AUTHOR'           => 'Rick Myers <jrm@cpan.org>',
    'VERSION_FROM'     => 'UUID.pm',
    'ABSTRACT_FROM'    => 'UUID.pm',
    'LICENSE'          => 'artistic_2',
    'MIN_PERL_VERSION' => '5.005',
    'LIBS'             => '',
    'NO_MYMETA'        => $no_mymeta,
    'INC'              => '-Iulib -Iulib/uuid',
    'CCFLAGS'          => $Config{ccflags},
    'DEFINE'           => $defines,
    'OBJECT'           => '$(O_FILES)',
    'LDFROM'           => join( ' ', qw{
        ulib/uuid/clear.o ulib/uuid/compare.o ulib/uuid/copy.o
        ulib/uuid/gen_uuid.o ulib/uuid/isnull.o ulib/uuid/pack.o
        ulib/uuid/parse.o ulib/uuid/unpack.o ulib/uuid/unparse.o
        ulib/uuid/uuid_time.o UUID.o
    }),
    'C' => [qw{
        ulib/uuid/clear.c ulib/uuid/compare.c ulib/uuid/copy.c
        ulib/uuid/gen_uuid.c ulib/uuid/isnull.c ulib/uuid/pack.c
        ulib/uuid/parse.c ulib/uuid/unpack.c ulib/uuid/unparse.c
        ulib/uuid/uuid_time.c UUID.c
    }],
    'H' => [qw{
        ulib/EUMM.h ulib/config.h ulib/dirpaths.h ulib/uuid/uuid.h
        ulib/uuid/uuid_types.h
    }],
    'PREREQ_PM'          => {
        'DynaLoader' => $DL_version,
        'Exporter'   => $EX_version,
        'strict'     => 0,
        'vars'       => 0,
        'warnings'   => 0,
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
        'Text::Patch'         => 0,
        'strict'              => 0,
        'warnings'            => 0,
    },
    'TEST_REQUIRES' => {
        'CPAN::Meta'         => 0,
        'DynaLoader'         => $DL_version,
        'Exporter'           => $EX_version,
        'ExtUtils::Manifest' => 0,
        'Test::More'         => $TM_version,
        'lib'                => 0,
        'strict'             => 0,
        'vars'               => 0,
        'warnings'           => 0,
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
            assertlib*.obj
            perl.core
            perl.exe.stackdump
            ulib
            usrcP
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

sub check_defines {
    my $defs = [];
    my $long = 0;

    for my $check ( 1, 0 ) {

        # this is to turn off the copious amount of spewage seen compiling
        # xs code on freebsd.
        # WISHLIST: would be nice if we could inspect the compiler output
        # from building the test file. would like to see if there was a
        # "unsupported command line option" warning. looks like it would
        # be a good bit of work though.
        try_ccflag($check, \$long, $defs, '-Wno-compound-token-split-by-macro');
        #... more ?
    }

    return join ' ', @$defs;
}

sub try_ccflag {
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



package MY;
use Config;


#
# some of the commented stuff below is just too dangerous
# to fool with just to satisfy ocd.
#


##
## stop rebuilding manifypods.
## hold manifypods until later.
##
#sub manifypods {
#    my $t = shift->SUPER::manifypods(@_);
#    return $t if $t =~ /NOOP/;
#    # dont manifypods every.single.time.
#    $t =~ s{\\$}{\\\n\t\$(INST_MAN3DIR)/UUID.\$(MAN3EXT)\n\n\$(INST_MAN3DIR)/UUID.\$(MAN3EXT): \\}ms;
#    # delay manifypods until after lib build
#    $t =~ s{UUID\.pm$}{UUID.pm \$(INST_DYNAMIC)}ms;
#    $t;
#}


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
# make TEST_VERBOSE=1 when AUTOMATED_TESTING=1
#
sub test {
    my $t = shift->SUPER::test(@_);
    if ( $ENV{AUTOMATED_TESTING}
        or $ENV{NONINTERACTIVE_TESTING}
        or $ENV{PERL_CPAN_REPORTER_CONFIG}
    ) {
        $t =~ s{TEST_VERBOSE=0}{TEST_VERBOSE=1}msg;
    }
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
    # delay Mkbootstrap() until after patch
    $t =~ s{^(\S+\s*:\s+.+$)} {$1 \$(pl2_patch)}m;
    $t;
}
sub perldepend {
    my $t = shift->SUPER::perldepend(@_);
    # make UUID.c depend on UUID.xs
    $t =~ s{$} { UUID.xs}s;
    # run xsubpp
    $t .= "\t". '$(XSUBPPRUN) $(XSPROTOARG) $(XSUBPPARGS) $(XSUBPP_EXTRA_ARGS) UUID.xs > UUID.xsc'. "\n";
    $t .= "\t". '$(MV) UUID.xsc UUID.c';
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
# our variables
#
sub post_constants {
    my $t = shift->SUPER::post_constants(@_);
    $t .= <<'EOPC';
pl0 = usrc
pl1 = usrcP
pl2 = ulib

pl0_uuiddir = $(pl0)$(DFSEP)uuid
pl1_uuiddir = $(pl1)$(DFSEP)uuid
pl2_uuiddir = $(pl2)$(DFSEP)uuid

pl0_config      = $(pl0)$(DFSEP)config
pl0_dirpaths    = $(pl0)$(DFSEP)dirpaths
pl0_clear       = $(pl0_uuiddir)$(DFSEP)clear
pl0_compare     = $(pl0_uuiddir)$(DFSEP)compare
pl0_copy        = $(pl0_uuiddir)$(DFSEP)copy
pl0_gen_uuid    = $(pl0_uuiddir)$(DFSEP)gen_uuid
pl0_gen_uuid_nt = $(pl0_uuiddir)$(DFSEP)gen_uuid_nt
pl0_isnull      = $(pl0_uuiddir)$(DFSEP)isnull
pl0_pack        = $(pl0_uuiddir)$(DFSEP)pack
pl0_parse       = $(pl0_uuiddir)$(DFSEP)parse
pl0_tst_uuid    = $(pl0_uuiddir)$(DFSEP)tst_uuid
pl0_unpack      = $(pl0_uuiddir)$(DFSEP)unpack
pl0_unparse     = $(pl0_uuiddir)$(DFSEP)unparse
pl0_uuid        = $(pl0_uuiddir)$(DFSEP)uuid
pl0_uuid_time   = $(pl0_uuiddir)$(DFSEP)uuid_time
pl0_uuid_types  = $(pl0_uuiddir)$(DFSEP)uuid_types
pl0_uuidP       = $(pl0_uuiddir)$(DFSEP)uuidP
pl0_uuidd       = $(pl0_uuiddir)$(DFSEP)uuidd

pl1_exists      = $(pl1)$(DFSEP).exists
pl1_patch       = $(pl1)$(DFSEP).patch
pl1_config      = $(pl1)$(DFSEP)config
pl1_dirpaths    = $(pl1)$(DFSEP)dirpaths
pl1_clear       = $(pl1_uuiddir)$(DFSEP)clear
pl1_compare     = $(pl1_uuiddir)$(DFSEP)compare
pl1_copy        = $(pl1_uuiddir)$(DFSEP)copy
pl1_gen_uuid    = $(pl1_uuiddir)$(DFSEP)gen_uuid
pl1_gen_uuid_nt = $(pl1_uuiddir)$(DFSEP)gen_uuid_nt
pl1_isnull      = $(pl1_uuiddir)$(DFSEP)isnull
pl1_pack        = $(pl1_uuiddir)$(DFSEP)pack
pl1_parse       = $(pl1_uuiddir)$(DFSEP)parse
pl1_tst_uuid    = $(pl1_uuiddir)$(DFSEP)tst_uuid
pl1_unpack      = $(pl1_uuiddir)$(DFSEP)unpack
pl1_unparse     = $(pl1_uuiddir)$(DFSEP)unparse
pl1_uuid        = $(pl1_uuiddir)$(DFSEP)uuid
pl1_uuid_time   = $(pl1_uuiddir)$(DFSEP)uuid_time
pl1_uuid_types  = $(pl1_uuiddir)$(DFSEP)uuid_types
pl1_uuidP       = $(pl1_uuiddir)$(DFSEP)uuidP
pl1_uuidd       = $(pl1_uuiddir)$(DFSEP)uuidd

pl2_EUMM_h      = $(pl2)$(DFSEP)EUMM.h
pl2_exists      = $(pl2)$(DFSEP).exists
pl2_patch       = $(pl2)$(DFSEP).patch
pl2_config      = $(pl2)$(DFSEP)config
pl2_dirpaths    = $(pl2)$(DFSEP)dirpaths
pl2_clear       = $(pl2_uuiddir)$(DFSEP)clear
pl2_compare     = $(pl2_uuiddir)$(DFSEP)compare
pl2_copy        = $(pl2_uuiddir)$(DFSEP)copy
pl2_gen_uuid    = $(pl2_uuiddir)$(DFSEP)gen_uuid
pl2_gen_uuid_nt = $(pl2_uuiddir)$(DFSEP)gen_uuid_nt
pl2_isnull      = $(pl2_uuiddir)$(DFSEP)isnull
pl2_pack        = $(pl2_uuiddir)$(DFSEP)pack
pl2_parse       = $(pl2_uuiddir)$(DFSEP)parse
pl2_tst_uuid    = $(pl2_uuiddir)$(DFSEP)tst_uuid
pl2_unpack      = $(pl2_uuiddir)$(DFSEP)unpack
pl2_unparse     = $(pl2_uuiddir)$(DFSEP)unparse
pl2_uuid        = $(pl2_uuiddir)$(DFSEP)uuid
pl2_uuid_time   = $(pl2_uuiddir)$(DFSEP)uuid_time
pl2_uuid_types  = $(pl2_uuiddir)$(DFSEP)uuid_types
pl2_uuidP       = $(pl2_uuiddir)$(DFSEP)uuidP
pl2_uuidd       = $(pl2_uuiddir)$(DFSEP)uuidd

ubin = ubin$(DFSEP)

patch_src_clearc       = $(ubin)patch_src_clearc.pl       $(pl0_clear).c         >
patch_src_comparec     = $(ubin)patch_src_comparec.pl     $(pl0_compare).c       >
patch_src_copyc        = $(ubin)patch_src_copyc.pl        $(pl0_copy).c          >
patch_src_genuuidc     = $(ubin)patch_src_genuuidc.pl     $(pl0_gen_uuid).c      >
patch_src_genuuidntc   = $(ubin)patch_src_genuuidntc.pl   $(pl0_gen_uuid_nt).c   >
patch_src_isnullc      = $(ubin)patch_src_isnullc.pl      $(pl0_isnull).c        >
patch_src_packc        = $(ubin)patch_src_packc.pl        $(pl0_pack).c          >
patch_src_parsec       = $(ubin)patch_src_parsec.pl       $(pl0_parse).c         >
patch_src_tstuuidc     = $(ubin)patch_src_tstuuidc.pl     $(pl0_tst_uuid).c      >
patch_src_unpackc      = $(ubin)patch_src_unpackc.pl      $(pl0_unpack).c        >
patch_src_unparsec     = $(ubin)patch_src_unparsec.pl     $(pl0_unparse).c       >
patch_src_uuidPh       = $(ubin)patch_src_uuidPh.pl       $(pl0_uuidP).h         >
patch_src_uuiddh       = $(ubin)patch_src_uuiddh.pl       $(pl0_uuidd).h         >
patch_src_uuidhin      = $(ubin)patch_src_uuidhin.pl      $(pl0_uuid).h.in       >
patch_src_uuidtimec    = $(ubin)patch_src_uuidtimec.pl    $(pl0_uuid_time).c     >
patch_src_uuidtypeshin = $(ubin)patch_src_uuidtypeshin.pl $(pl0_uuid_types).h.in >

ubin_configure_pl = $(ubin)configure.pl
ubin_subst_pl     = $(ubin)subst.pl

patch_eummh       = -l $(ubin_configure_pl)
patch_genuuidc    = $(ubin)patch_genuuidc.pl $(pl1_gen_uuid).c >
patch_uuidh       = $(ubin)patch_uuidh.pl    $(pl2_uuid).h.new >
patch_configh     = $(ubin_subst_pl) $(pl1_config).h.in   >
patch_dirpathsh   = $(ubin_subst_pl) $(pl1_dirpaths).h.in >
patch_parsec      = $(ubin)patch_parsec.pl   $(pl1_parse).c >
patch_uuidhin     = $(ubin_subst_pl) $(pl1_uuid).h.in     >
patch_uuidtimec   = $(ubin)patch_uuidtimec.pl $(pl1_uuid_time).c >
patch_uuidtypesh1 = $(ubin_subst_pl) $(pl1_uuid_types).h.in >
patch_uuidtypesh2 = -i.bak -pe "s!typedef signed char!typedef char!s"
EOPC
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


#
# the usrP dir is a patched copy of usrc tree.
# sources here are either copied from usrc or
# are locally patched to modify types.
#
$(pl1_exists): $(FIRST_MAKEFILE)
	$(NOECHO) $(ECHO) Patching source tree
	$(NOECHO) $(MKPATH) $(pl1_uuid)
	$(NOECHO) $(TOUCH)  $(pl1_exists)

$(pl1_config).h.in: $(pl1_exists) $(pl0_config).h.in
	$(NOECHO) $(RM_F) $(pl1_config).h.in     $(pl1_config).h.in.new
	$(NOECHO) $(CP)   $(pl0_config).h.in     $(pl1_config).h.in.new
	$(NOECHO) $(MV)   $(pl1_config).h.in.new $(pl1_config).h.in

$(pl1_clear).c: $(pl1_exists) $(pl0_clear).c
	$(NOECHO) $(RM_F) $(pl1_clear).c      $(pl1_clear).c.new
	$(NOECHO) $(PERL) $(patch_src_clearc) $(pl1_clear).c.new
	$(NOECHO) $(MV)   $(pl1_clear).c.new  $(pl1_clear).c

$(pl1_compare).c: $(pl1_exists) $(pl0_compare).c
	$(NOECHO) $(RM_F) $(pl1_compare).c      $(pl1_compare).c.new
	$(NOECHO) $(PERL) $(patch_src_comparec) $(pl1_compare).c.new
	$(NOECHO) $(MV)   $(pl1_compare).c.new  $(pl1_compare).c

$(pl1_copy).c: $(pl1_exists) $(pl0_copy).c
	$(NOECHO) $(RM_F) $(pl1_copy).c      $(pl1_copy).c.new
	$(NOECHO) $(PERL) $(patch_src_copyc) $(pl1_copy).c.new
	$(NOECHO) $(MV)   $(pl1_copy).c.new  $(pl1_copy).c

$(pl1_dirpaths).h.in: $(pl1_exists) $(pl0_dirpaths).h.in
	$(NOECHO) $(RM_F) $(pl1_dirpaths).h.in     $(pl1_dirpaths).h.in.new
	$(NOECHO) $(CP)   $(pl0_dirpaths).h.in     $(pl1_dirpaths).h.in.new
	$(NOECHO) $(MV)   $(pl1_dirpaths).h.in.new $(pl1_dirpaths).h.in

$(pl1_gen_uuid).c: $(pl1_exists) $(pl0_gen_uuid).c
	$(NOECHO) $(RM_F) $(pl1_gen_uuid).c     $(pl1_gen_uuid).c.new
	$(NOECHO) $(PERL) $(patch_src_genuuidc) $(pl1_gen_uuid).c.new
	$(NOECHO) $(MV)   $(pl1_gen_uuid).c.new $(pl1_gen_uuid).c

$(pl1_gen_uuid_nt).c: $(pl1_exists) $(pl0_gen_uuid_nt).c
	$(NOECHO) $(RM_F) $(pl1_gen_uuid_nt).c     $(pl1_gen_uuid_nt).c.new
	$(NOECHO) $(PERL) $(patch_src_genuuidntc)  $(pl1_gen_uuid_nt).c.new
	$(NOECHO) $(MV)   $(pl1_gen_uuid_nt).c.new $(pl1_gen_uuid_nt).c

$(pl1_isnull).c: $(pl1_exists) $(pl0_isnull).c
	$(NOECHO) $(RM_F) $(pl1_isnull).c      $(pl1_isnull).c.new
	$(NOECHO) $(PERL) $(patch_src_isnullc) $(pl1_isnull).c.new
	$(NOECHO) $(MV)   $(pl1_isnull).c.new  $(pl1_isnull).c

$(pl1_pack).c: $(pl1_exists) $(pl0_pack).c
	$(NOECHO) $(RM_F) $(pl1_pack).c      $(pl1_pack).c.new
	$(NOECHO) $(PERL) $(patch_src_packc) $(pl1_pack).c.new
	$(NOECHO) $(MV)   $(pl1_pack).c.new  $(pl1_pack).c

$(pl1_parse).c: $(pl1_exists) $(pl0_parse).c
	$(NOECHO) $(RM_F) $(pl1_parse).c      $(pl1_parse).c.new
	$(NOECHO) $(PERL) $(patch_src_parsec) $(pl1_parse).c.new
	$(NOECHO) $(MV)   $(pl1_parse).c.new  $(pl1_parse).c

$(pl1_tst_uuid).c: $(pl1_exists) $(pl0_tst_uuid).c
	$(NOECHO) $(RM_F) $(pl1_tst_uuid).c     $(pl1_tst_uuid).c.new
	$(NOECHO) $(PERL) $(patch_src_tstuuidc) $(pl1_tst_uuid).c.new
	$(NOECHO) $(MV)   $(pl1_tst_uuid).c.new $(pl1_tst_uuid).c

$(pl1_unpack).c: $(pl1_exists) $(pl0_unpack).c
	$(NOECHO) $(RM_F) $(pl1_unpack).c      $(pl1_unpack).c.new
	$(NOECHO) $(PERL) $(patch_src_unpackc) $(pl1_unpack).c.new
	$(NOECHO) $(MV)   $(pl1_unpack).c.new  $(pl1_unpack).c

$(pl1_unparse).c: $(pl1_exists) $(pl0_unparse).c
	$(NOECHO) $(RM_F) $(pl1_unparse).c      $(pl1_unparse).c.new
	$(NOECHO) $(PERL) $(patch_src_unparsec) $(pl1_unparse).c.new
	$(NOECHO) $(MV)   $(pl1_unparse).c.new  $(pl1_unparse).c

$(pl1_uuid).h.in: $(pl1_exists) $(pl0_uuid).h.in
	$(NOECHO) $(RM_F) $(pl1_uuid).h.in      $(pl1_uuid).h.in.new
	$(NOECHO) $(PERL) $(patch_src_uuidhin) $(pl1_uuid).h.in.new
	$(NOECHO) $(MV)   $(pl1_uuid).h.in.new $(pl1_uuid).h.in

$(pl1_uuidP).h: $(pl1_exists) $(pl0_uuidP).h
	$(NOECHO) $(RM_F) $(pl1_uuidP).h      $(pl1_uuidP).h.new
	$(NOECHO) $(PERL) $(patch_src_uuidPh) $(pl1_uuidP).h.new
	$(NOECHO) $(MV)   $(pl1_uuidP).h.new  $(pl1_uuidP).h

$(pl1_uuid_time).c: $(pl1_exists) $(pl0_uuid_time).c
	$(NOECHO) $(RM_F) $(pl1_uuid_time).c     $(pl1_uuid_time).c.new
	$(NOECHO) $(PERL) $(patch_src_uuidtimec) $(pl1_uuid_time).c.new
	$(NOECHO) $(MV)   $(pl1_uuid_time).c.new $(pl1_uuid_time).c

$(pl1_uuid_types).h.in: $(pl1_exists) $(pl0_uuid_types).h.in
	$(NOECHO) $(RM_F) $(pl1_uuid_types).h.in     $(pl1_uuid_types).h.in.new
	$(NOECHO) $(PERL) $(patch_src_uuidtypeshin)  $(pl1_uuid_types).h.in.new
	$(NOECHO) $(MV)   $(pl1_uuid_types).h.in.new $(pl1_uuid_types).h.in

$(pl1_uuidd).h: $(pl1_exists) $(pl0_uuidd).h
	$(NOECHO) $(RM_F) $(pl1_uuidd).h      $(pl1_uuidd).h.new
	$(NOECHO) $(PERL) $(patch_src_uuiddh) $(pl1_uuidd).h.new
	$(NOECHO) $(MV)   $(pl1_uuidd).h.new  $(pl1_uuidd).h

$(pl1_patch):              \
	$(pl1_config).h.in     \
	$(pl1_clear).c         \
	$(pl1_compare).c       \
	$(pl1_copy).c          \
	$(pl1_dirpaths).h.in   \
	$(pl1_gen_uuid).c      \
	$(pl1_gen_uuid_nt).c   \
	$(pl1_isnull).c        \
	$(pl1_pack).c          \
	$(pl1_parse).c         \
	$(pl1_tst_uuid).c      \
	$(pl1_unpack).c        \
	$(pl1_unparse).c       \
	$(pl1_uuid).h.in       \
	$(pl1_uuidP).h         \
	$(pl1_uuid_time).c     \
	$(pl1_uuid_types).h.in \
	$(pl1_uuidd).h
	$(NOECHO) $(TOUCH) $(pl1_patch)


#
# the ulib dir is the final build tree.
# sources here are copied from usrcP or
# modified by configure.
#
$(pl2_exists): $(pl1_patch) $(ubin_configure_pl) $(ubin_subst_pl)
	$(NOECHO) $(MKPATH) $(pl2_uuid)
	$(NOECHO) $(TOUCH)  $(pl2_exists)

$(pl2_EUMM_h): $(pl2_exists) $(ubin_configure_pl)
	$(NOECHO) $(ECHO) Generating EUMM.h
	$(NOECHO) $(RM_F) $(pl2_EUMM_h)     $(pl2_EUMM_h).new
	$(NOECHO) $(PERL) $(patch_eummh)    $(pl2_EUMM_h).new
	$(NOECHO) $(MV)   $(pl2_EUMM_h).new $(pl2_EUMM_h)

$(pl2_clear).c: $(pl2_exists) $(pl1_clear).c
	$(NOECHO) $(RM_F) $(pl2_clear).c     $(pl2_clear).c.new
	$(NOECHO) $(CP)   $(pl1_clear).c     $(pl2_clear).c.new
	$(NOECHO) $(MV)   $(pl2_clear).c.new $(pl2_clear).c

$(pl2_compare).c: $(pl2_exists) $(pl1_compare).c
	$(NOECHO) $(RM_F) $(pl2_compare).c     $(pl2_compare).c.new
	$(NOECHO) $(CP)   $(pl1_compare).c     $(pl2_compare).c.new
	$(NOECHO) $(MV)   $(pl2_compare).c.new $(pl2_compare).c

$(pl2_config).h: $(pl2_exists) $(pl1_config).h.in
	$(NOECHO) $(ECHO) Generating config.h
	$(NOECHO) $(RM_F) $(pl2_config).h     $(pl2_config).h.new
	$(NOECHO) $(PERL) $(patch_configh)    $(pl2_config).h.new
	$(NOECHO) $(ECHO) "#include <EUMM.h>" >> $(pl2_config).h.new
	$(NOECHO) $(MV)   $(pl2_config).h.new $(pl2_config).h

$(pl2_copy).c: $(pl2_exists) $(pl1_copy).c
	$(NOECHO) $(RM_F) $(pl2_copy).c     $(pl2_copy).c.new
	$(NOECHO) $(CP)   $(pl1_copy).c     $(pl2_copy).c.new
	$(NOECHO) $(MV)   $(pl2_copy).c.new $(pl2_copy).c

$(pl2_dirpaths).h: $(pl2_exists) $(pl1_dirpaths).h.in
	$(NOECHO) $(ECHO) Generating dirpaths.h
	$(NOECHO) $(RM_F) $(pl2_dirpaths).h     $(pl2_dirpaths).h.new
	$(NOECHO) $(PERL) $(patch_dirpathsh)    $(pl2_dirpaths).h.new
	$(NOECHO) $(MV)   $(pl2_dirpaths).h.new $(pl2_dirpaths).h

$(pl2_gen_uuid).c: $(pl2_exists) $(pl1_gen_uuid).c
	$(NOECHO) $(RM_F) $(pl2_gen_uuid).c     $(pl2_gen_uuid).c.new
	$(NOECHO) $(PERL) $(patch_genuuidc)     $(pl2_gen_uuid).c.new
	$(NOECHO) $(MV)   $(pl2_gen_uuid).c.new $(pl2_gen_uuid).c

$(pl2_gen_uuid_nt).c: $(pl2_exists) $(pl1_gen_uuid_nt).c
	$(NOECHO) $(RM_F) $(pl2_gen_uuid_nt).c     $(pl2_gen_uuid_nt).c.new
	$(NOECHO) $(CP)   $(pl1_gen_uuid_nt).c     $(pl2_gen_uuid_nt).c.new
	$(NOECHO) $(MV)   $(pl2_gen_uuid_nt).c.new $(pl2_gen_uuid_nt).c

$(pl2_isnull).c: $(pl2_exists) $(pl1_isnull).c
	$(NOECHO) $(RM_F) $(pl2_isnull).c     $(pl2_isnull).c.new
	$(NOECHO) $(CP)   $(pl1_isnull).c     $(pl2_isnull).c.new
	$(NOECHO) $(MV)   $(pl2_isnull).c.new $(pl2_isnull).c

$(pl2_pack).c: $(pl2_exists) $(pl1_pack).c
	$(NOECHO) $(RM_F) $(pl2_pack).c     $(pl2_pack).c.new
	$(NOECHO) $(CP)   $(pl1_pack).c     $(pl2_pack).c.new
	$(NOECHO) $(MV)   $(pl2_pack).c.new $(pl2_pack).c

$(pl2_parse).c: $(pl2_exists) $(pl1_parse).c
	$(NOECHO) $(RM_F) $(pl2_parse).c     $(pl2_parse).c.new
	$(NOECHO) $(PERL) $(patch_parsec)    $(pl2_parse).c.new
	$(NOECHO) $(MV)   $(pl2_parse).c.new $(pl2_parse).c

$(pl2_tst_uuid).c: $(pl2_exists) $(pl1_tst_uuid).c
	$(NOECHO) $(RM_F) $(pl2_tst_uuid).c     $(pl2_tst_uuid).c.new
	$(NOECHO) $(CP)   $(pl1_tst_uuid).c     $(pl2_tst_uuid).c.new
	$(NOECHO) $(MV)   $(pl2_tst_uuid).c.new $(pl2_tst_uuid).c

$(pl2_unpack).c: $(pl2_exists) $(pl1_unpack).c
	$(NOECHO) $(RM_F) $(pl2_unpack).c     $(pl2_unpack).c.new
	$(NOECHO) $(CP)   $(pl1_unpack).c     $(pl2_unpack).c.new
	$(NOECHO) $(MV)   $(pl2_unpack).c.new $(pl2_unpack).c

$(pl2_unparse).c: $(pl2_exists) $(pl1_unparse).c
	$(NOECHO) $(RM_F) $(pl2_unparse).c     $(pl2_unparse).c.new
	$(NOECHO) $(CP)   $(pl1_unparse).c     $(pl2_unparse).c.new
	$(NOECHO) $(MV)   $(pl2_unparse).c.new $(pl2_unparse).c

$(pl2_uuid).h: $(pl2_exists) $(pl1_uuid).h.in
	$(NOECHO) $(ECHO) Generating uuid.h
	$(NOECHO) $(RM_F) $(pl2_uuid).h       $(pl2_uuid).h.new   $(pl2_uuid).h.newer
	$(NOECHO) $(PERL) $(patch_uuidhin)    $(pl2_uuid).h.new
	$(NOECHO) $(PERL) $(patch_uuidh)      $(pl2_uuid).h.newer
	$(NOECHO) $(MV)   $(pl2_uuid).h.newer $(pl2_uuid).h

$(pl2_uuid_time).c: $(pl2_exists) $(pl1_uuid_time).c
	$(NOECHO) $(RM_F) $(pl2_uuid_time).c     $(pl2_uuid_time).c.new
	$(NOECHO) $(PERL) $(patch_uuidtimec)     $(pl2_uuid_time).c.new
	$(NOECHO) $(MV)   $(pl2_uuid_time).c.new $(pl2_uuid_time).c

$(pl2_uuid_types).h: $(pl2_exists) $(pl1_uuid_types).h.in
	$(NOECHO) $(ECHO) Generating uuid_types.h
	$(NOECHO) $(RM_F) $(pl2_uuid_types).h $(pl2_uuid_types).h.new
	$(NOECHO) $(PERL) $(patch_uuidtypesh1) $(pl2_uuid_types).h.new
	$(NOECHO) $(PERL) $(patch_uuidtypesh2) $(pl2_uuid_types).h.new
	$(NOECHO) $(RM_F) $(pl2_uuid_types).h.new.bak
	$(NOECHO) $(MV)   $(pl2_uuid_types).h.new $(pl2_uuid_types).h

$(pl2_uuidd).h: $(pl2_exists) $(pl1_uuidd).h
	$(NOECHO) $(RM_F) $(pl2_uuidd).h     $(pl2_uuidd).h.new
	$(NOECHO) $(CP)   $(pl1_uuidd).h     $(pl2_uuidd).h.new
	$(NOECHO) $(MV)   $(pl2_uuidd).h.new $(pl2_uuidd).h

$(pl2_uuidP).h: $(pl2_exists) $(pl1_uuidP).h
	$(NOECHO) $(RM_F) $(pl2_uuidP).h      $(pl2_uuidP).h.new
	$(NOECHO) $(CP)   $(pl1_uuidP).h      $(pl2_uuidP).h.new
	$(NOECHO) $(MV)   $(pl2_uuidP).h.new  $(pl2_uuidP).h

$(pl2_patch):            \
	$(pl2_EUMM_h)        \
	$(pl2_config).h      \
	$(pl2_dirpaths).h    \
	$(pl2_clear).c       \
	$(pl2_compare).c     \
	$(pl2_copy).c        \
	$(pl2_gen_uuid).c    \
	$(pl2_gen_uuid_nt).c \
	$(pl2_isnull).c      \
	$(pl2_pack).c        \
	$(pl2_parse).c       \
	$(pl2_tst_uuid).c    \
	$(pl2_unpack).c      \
	$(pl2_unparse).c     \
	$(pl2_uuid).h        \
	$(pl2_uuidP).h       \
	$(pl2_uuid_time).c   \
	$(pl2_uuid_types).h  \
	$(pl2_uuidd).h
	$(NOECHO) $(TOUCH) $(pl2_patch)


config :: $(H_FILES)
	$(NOECHO) $(NOOP)

#
# some versions of make dont support $<
#
deps = $(XSUBPPDEPS) $(pl2_patch)
cccmd = $(CCCMD) -Iulib $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE)

UUID.o             : $(deps) UUID.c
	$(cccmd)                 UUID.c              -o UUID.o

$(pl2_clear).o     : $(deps) $(pl2_clear).c
	$(cccmd)                 $(pl2_clear).c      -o $(pl2_clear).o

$(pl2_compare).o   : $(deps) $(pl2_compare).c
	$(cccmd)                 $(pl2_compare).c    -o $(pl2_compare).o

$(pl2_copy).o      : $(deps) $(pl2_copy).c
	$(cccmd)                 $(pl2_copy).c       -o $(pl2_copy).o

$(pl2_gen_uuid).o  : $(deps) $(pl2_gen_uuid).c
	$(cccmd)                 $(pl2_gen_uuid).c   -o $(pl2_gen_uuid).o

$(pl2_isnull).o    : $(deps) $(pl2_isnull).c
	$(cccmd)                 $(pl2_isnull).c     -o $(pl2_isnull).o

$(pl2_pack).o      : $(deps) $(pl2_pack).c
	$(cccmd)                 $(pl2_pack).c       -o $(pl2_pack).o

$(pl2_parse).o     : $(deps) $(pl2_parse).c
	$(cccmd)                 $(pl2_parse).c      -o $(pl2_parse).o

$(pl2_unpack).o    : $(deps) $(pl2_unpack).c
	$(cccmd)                 $(pl2_unpack).c     -o $(pl2_unpack).o

$(pl2_unparse).o   : $(deps) $(pl2_unparse).c
	$(cccmd)                 $(pl2_unparse).c    -o $(pl2_unparse).o

$(pl2_uuid_time).o : $(deps) $(pl2_uuid_time).c
	$(cccmd)                 $(pl2_uuid_time).c  -o $(pl2_uuid_time).o


UUID.obj : UUID.c
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) -Fd$(*).pdb $*.c

$(pl2_clear).obj : $(pl2_clear).c
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) -Fd$(*).pdb -Fo$(*).obj $*.c

$(pl2_compare).obj : $(pl2_compare).c
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) -Fd$(*).pdb -Fo$(*).obj $*.c

$(pl2_copy).obj : $(pl2_copy).c
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) -Fd$(*).pdb -Fo$(*).obj $*.c

$(pl2_gen_uuid).obj : $(pl2_gen_uuid).c
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) -Fd$(*).pdb -Fo$(*).obj $*.c

$(pl2_isnull).obj : $(pl2_isnull).c
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) -Fd$(*).pdb -Fo$(*).obj $*.c

$(pl2_pack).obj : $(pl2_pack).c
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) -Fd$(*).pdb -Fo$(*).obj $*.c

$(pl2_parse).obj : $(pl2_parse).c
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) -Fd$(*).pdb -Fo$(*).obj $*.c

$(pl2_unpack).obj : $(pl2_unpack).c
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) -Fd$(*).pdb -Fo$(*).obj $*.c

$(pl2_unparse).obj : $(pl2_unparse).c
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) -Fd$(*).pdb -Fo$(*).obj $*.c

$(pl2_uuid_time).obj : $(pl2_uuid_time).c
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) -Fd$(*).pdb -Fo$(*).obj $*.c


EOP

    if ($Config{make} eq 'nmake') {
        $pa .= <<'EOP';
$(INST_DYNAMIC) : \
	UUID.obj $(pl2_clear).obj $(pl2_compare).obj $(pl2_copy).obj \
	$(pl2_gen_uuid).obj $(pl2_isnull).obj $(pl2_pack).obj \
	$(pl2_parse).obj $(pl2_unpack).obj $(pl2_unparse).obj \
	$(pl2_uuid_time).obj \
	$(INST_ARCHAUTODIR)$(DFSEP).exists $(EXPORT_LIST) \
	$(PERL_ARCHIVEDEP) $(INST_DYNAMIC_DEP)
	$(LD) -out:$@ $(LDDLFLAGS) \
	UUID.obj $(pl2_clear).obj $(pl2_compare).obj $(pl2_copy).obj \
	$(pl2_gen_uuid).obj $(pl2_isnull).obj $(pl2_pack).obj \
	$(pl2_parse).obj $(pl2_unpack).obj $(pl2_unparse).obj \
	$(pl2_uuid_time).obj \
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
	$(LD)  $(LDDLFLAGS)  $(LDFROM) $(OTHERLDFLAGS) -o $@ $(MYEXTLIB) \
	  $(PERL_ARCHIVE) $(LDLOADLIBS) $(PERL_ARCHIVE_AFTER) $(EXPORT_LIST) \
	  $(INST_DYNAMIC_FIX)
	$(CHMOD) $(PERM_RWX) $@
EOP
    }

    return $pa;
}
