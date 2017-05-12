# $Id$

# If we are on platforms other than Windows,
# exit now. This should play nice for CPAN testers.
my $running_on_windows = $^O eq 'MSWin32' || $^O eq 'cygwin' || $^O eq 'msys';
die qq(OS unsupported\n)
    unless $running_on_windows
    or $ENV{WIN32_API_BUILD}     # So I can build it on Linux too
    ;

# Must be a better way to do this, surely...
use Config;
require './W32ATest.pm';

my $is_64bit_build = ($Config{ptrsize} == 8);
my $is_msvc_compiler = ($Config{cc} =~ /cl/);

#maybe this CC will banned in the future due to SEGV in DllMain
#die "Mingw 3.4.5 will generate unloadble DLLs, upgrade your GCC"
#     if index($Config{gccversion}, '3.4.5 (mingw-vista special r3)') != -1);

use ExtUtils::MakeMaker;

#some assertions to make sure pack returns the same info as Config
#to avoid loading Config at Win32::API runtime
die "properties of pack() dont match the properties of your perl build from %Config"
    if length(pack($] >= 5.007003 ? 'J' : 'I' ,0)) != $Config{ivsize} || length pack('p', undef) != $Config{ptrsize};

WriteMakefile1(
    PL_FILES => {},
    LICENSE => 'perl',
    META_MERGE => {
        resources => {
            repository => 'https://github.com/bulk88/perl5-win32-api',
        },
        keywords => ['win32','api','dll','libraries'],
        recommends => {'Math::Int64' => 0}
    },
    BUILD_REQUIRES => {
        'Test::More'    => 0,
        'Math::Int64'   => 0,
        'File::Spec'    => 0,
        'Win32'         => 0,
        'Win32API::File'=> 0,
        'IPC::Open3'    => 0,
        'Encode::compat'=> 0,
        'Config::Perl::V'=>0
    },

    'NAME'	=> 'Win32::API',

    'AUTHOR'        	=> 'Aldo Calpini <dada@perl.it>, Cosimo Streppone <cosimo@cpan.org>, Daniel Dragan <bulkdd@cpan.org>',
    'ABSTRACT'      	=> 'Perl Win32 API Import Facility',

    'PM' => {
        'API.pm'      => '$(INST_LIBDIR)/API.pm',
        'Type.pm'     => '$(INST_LIBDIR)/API/Type.pm',
        'Struct.pm'   => '$(INST_LIBDIR)/API/Struct.pm',
        'Callback.pm' => '$(INST_LIBDIR)/API/Callback.pm',
        'IATPatch.pod'=> '$(INST_LIBDIR)/API/Callback/IATPatch.pod'
	},

    'VERSION_FROM' => 'API.pm',

    'dist' => {
        COMPRESS => 'gzip -9f', 
        SUFFIX   => 'gz'
    },

    # Win32 is a prerequisite, at least for our tests
    'PREREQ_PM' => { 'Scalar::Util' => 0},
    # One day, I'd like to restore the dynamic API_test.dll
    #'clean' => {FILES => 'API_test.dll API_test_dll/Release/*'},
    
    XSOPT  => ' -nolinenumbers ',
    TYPEMAPS => ['TYPEMAP'],
    #for custom alloca
    (!$is_64bit_build && $is_msvc_compiler ?  (dynamic_lib => {OTHERLDFLAGS => '-FORCE:MULTIPLE'}) : ()),
    ($ExtUtils::MakeMaker::VERSION >= 6.47 ? (MIN_PERL_VERSION => 5.000000) : ()),
    
    #for disassembler to locate these likely to break functions, off in stables to keep export list small
    #FUNCLIST => ['boot_Win32__API', '@Call_asm@16', 'XS_Win32__API_ImportCall'],

    (
        $is_64bit_build
	    ? ( $is_msvc_compiler
		    ? ( 'OBJECT' => '$(BASEEXT)$(OBJ_EXT) call_asm_x64_msvc$(OBJ_EXT)' )
		    : ( 'OBJECT' => '$(BASEEXT)$(OBJ_EXT) call_asm_x64_gnu$(OBJ_EXT)' )
		)
	    : ( $is_msvc_compiler
                    ? ( 'OBJECT' => '$(BASEEXT)$(OBJ_EXT) call_asm_x86_msvc$(OBJ_EXT)' )
                    : ( 'OBJECT' => '$(BASEEXT)$(OBJ_EXT) call_asm_x86_gnu$(OBJ_EXT)' )
              )
    )
);

# We must "chmod +x API_test.dll", or cygwin users see test suite fail
# because dll can't be loaded if not marked as executable
sub MY::depend
{
    return "" unless $^O eq 'cygwin';
    return "\ntest_dynamic :: \n\t\$(CHMOD) \$(PERM_RWX) API_test.dll";
}

sub MY::postamble
{
    #old 64bit strawberryperl hack
    if ($Config{'gccversion'} =~ /4.4.3/ &&$Config{'myuname'} =~ /Win32 strawberryperl/) {
      return <<'EOM1';
.asm$(OBJ_EXT):
	ml64 $(ASFLAGS) $(PERL_DEFINES) -c $<

.s$(OBJ_EXT):
	perl -pi.bak -e "s/^(.globl )?Call_x64_real/$$1_Call_x64_real/" call_asm_x64_gnu.s
	$(AS) $(ASFLAGS) $< -o $*$(OBJ_EXT)

#target unused
#make GCC issue "push" instructions rather than "mov" to esp+offset, this is the magic
#recipe to get GCC (4.6.3 tested) to do it
call_i686$(OBJ_EXT): call_i686.c API.h
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) \
-fno-defer-pop -fno-omit-frame-pointer -mno-accumulate-outgoing-args -mno-stack-arg-probe call_i686.c

EOM1
    }
    #end-of old 64bit strawberryperl hack
     
    return  ($is_msvc_compiler?'
ASFLAGS =  -Zi

':'')
.'
.asm$(OBJ_EXT):
	'.($is_64bit_build ? 'ml64' : 'ml').' $(ASFLAGS) $(PERL_DEFINES)  -c $<

.s$(OBJ_EXT):
	$(AS) $(ASFLAGS) $(PERL_DEFINES) $< -o $*$(OBJ_EXT)

#target unused
#make GCC issue "push" instructions rather than "mov" to esp+offset, this is the magic
#recipe to get GCC (4.6.3 tested) to do it
call_i686$(OBJ_EXT): call_i686.c API.h
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) \
-fno-defer-pop -fno-omit-frame-pointer -mno-accumulate-outgoing-args -mno-stack-arg-probe call_i686.c

';
}

sub no_stackprotector {
    if(!$is_msvc_compiler && $is_64bit_build) {
        return ' -fno-stack-protector ';
    } else {
        return '';
    }
}

package MY; #subs below use SUPER::, subs above use main:: vars

sub post_constants {
    #if Call.c changes API.obj must be rebuilt
    return (!$is_msvc_compiler && $] lt '5.014' ? "AS\t= as\n" : '').
'benchmark :: pure_all
	$(FULLPERLRUN) "-MExtUtils::Command::MM" "-e" "test_harness(\'$(TEST_VERBOSE)\', \'$(INST_LIB)\', \'$(INST_ARCHLIB)\')" t/benchmark.t

$(OBJECT) : Call.c

';
}

sub isdev {
    return index(shift->{VERSION}, '_') == -1 ? '' :  ' -DISDEV ';
}

sub cflags {
    my($self) = shift;
    my $dlib = $self->SUPER::cflags(@_);
    my $pos = index($dlib,'CCFLAGS = ',0);
    die "bad CCFLAGS match" if $pos == -1;
    my $len = $pos+length('CCFLAGS = ');
    $dlib = substr($dlib, 0, $len)
        .main::GS_flag()
        .isdev($self)
        .substr($dlib, $len, length($dlib)-$len);
#this is for Callback.xs, on Cygwin, $(PASTHRU) is used to override on cmd line
#OPTIMIZE macro from the parent makefile (this one)
    $dlib =~ s/(^OPTIMIZE = .+)$/$1 ${\main::no_stackprotector()}/m;

    my @defs; #On Cygwin (and Win32 Perl one day) all the important defines are
    #not on the command line but in config.h so -V needs to be used to read them out
    #save time by not loading or running Config::Perl::V on newer Perls
    if($] lt '5.014') {
        require Config::Perl::V;
        $optionshash = Config::Perl::V::myconfig()->{build}{options};
        foreach(keys %$optionshash) {
            push @defs, $_ if $optionshash->{$_};
        }
    } else {
        @defs = Config::bincompat_options(), Config::non_bincompat_options();
    }
    return $dlib.'PERL_DEFINES = '.(@defs?'-D':'').join(' -D', @defs)."\n" if $is_msvc_compiler;
#convert -DFOO into GNU AS compatible defines for GNU AS macros
    my $defs = '';
    $defs .= '-defsym '.$_.'=1 ' foreach @defs;
    return $dlib.'PERL_DEFINES = '.$defs."\n";
}

sub test {
    my($self) = shift;
    my $test_sec = $self->SUPER::test(@_);
    substr($test_sec,index($test_sec,'TEST_VERBOSE=0'), length('TEST_VERBOSE=0') ,'TEST_VERBOSE=1');
    return $test_sec;
}

#b/c of this sub, distdir only runs on Cygwin, perm changes are for Kwalitee
sub distdir {
    my($self) = shift;
    my $distdir_sec = $self->SUPER::distdir(@_);
    #in newer perls we are patching create_distdir, in olders, distdir
    #see MM patch "6.25 alphas caused a Makefile to be added to the dist. Fixed. "
    my $repstartpos = index($distdir_sec,"\'\$(DIST_CP)\');\"");
    die "distdir cant match" if $repstartpos == -1;
    substr($distdir_sec
           ,$repstartpos
           ,length("\'\$(DIST_CP)\');\"")
           ,"\'\$(DIST_CP)\');\" \\\n\t&& cd \$(DISTVNAME) && chmod -v -x-x-x Makefile.PL && chmod -v -x-x-x ./Callback/Makefile.PL"
           );
    return $distdir_sec;
}

package main;

sub GS_flag {
    if($is_msvc_compiler
       && Win32::API::Test::compiler_version_from_shell() >= 14 ) {
        return ' -GS- ';
    }
    else {
        return '';
    }
}

sub WriteMakefile1 {  #Written by Alexandr Ciornii, version 0.21. Added by eumm-upgrade.
    my %params=@_;
    my $eumm_version=$ExtUtils::MakeMaker::VERSION;
    $eumm_version=eval $eumm_version;
    die "EXTRA_META is deprecated" if exists $params{EXTRA_META};
    die "License not specified" if not exists $params{LICENSE};
    if ($params{BUILD_REQUIRES} and $eumm_version < 6.5503) {
        #EUMM 6.5502 has problems with BUILD_REQUIRES
        $params{PREREQ_PM}={ %{$params{PREREQ_PM} || {}} , %{$params{BUILD_REQUIRES}} };
        delete $params{BUILD_REQUIRES};
    }
    delete $params{CONFIGURE_REQUIRES} if $eumm_version < 6.52;
    delete $params{MIN_PERL_VERSION} if $eumm_version < 6.48;
    delete $params{META_MERGE} if $eumm_version < 6.46;
    delete $params{META_ADD} if $eumm_version < 6.46;
    delete $params{LICENSE} if $eumm_version < 6.31;
    delete $params{AUTHOR} if $] < 5.005;
    delete $params{ABSTRACT_FROM} if $] < 5.005;
    delete $params{BINARY_LOCATION} if $] < 5.005;

    WriteMakefile(%params);
}

