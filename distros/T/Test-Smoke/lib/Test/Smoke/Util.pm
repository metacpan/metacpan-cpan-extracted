package Test::Smoke::Util;
use strict;

our $VERSION = '0.58';

use Exporter 'import';
our @EXPORT = qw(
    &Configure_win32
    &get_cfg_filename &get_config
    &get_patch
    &skip_config &skip_filter
);

our @EXPORT_OK = qw(
    &grepccmsg &grepnonfatal &get_local_patches &set_local_patch
    &get_ncpu &get_smoked_Config &parse_report_Config
    &get_regen_headers &run_regen_headers
    &whereis &clean_filename &read_logfile
    &calc_timeout &time_in_hhmm
    &do_pod2usage
    &set_vms_rooted_logical
);

use Text::ParseWords;
use File::Spec::Functions;
use Encode qw ( decode );
use File::Find;
use Cwd;
use Test::Smoke::LogMixin;

our $NOCASE = $^O eq 'VMS';

=head1 NAME

Test::Smoke::Util - Take out some of the functions of the smoke suite.

=head1 FUNCTIONS

I've taken out some of the general stuff and put it here.
Now I can write some tests!

=head2 Configure_win32( $command[, $win32_maker[, @args]] )

C<Configure_win32()> alters the settings of the makefile for MSWin32.

C<$command> is in the form of './Configure -des -Dusedevel ...'

C<$win32_maker> should either be C<nmake> or C<gmake>, the default
is C<nmake>.

C<@args> is a list of C<< option=value >> pairs that will (eventually)
be passed to L<Config.pm>.

PLEASE read README.win32 and study the comments in the makefile.

It supports these options:

=over 4

=item * B<-Duseperlio>

set USE_PERLIO = define (default) [should be depricated]

=item * B<-Dusethreads>

set USE_ITHREADS = define (also sets USE_MULTI and USE_IMP_SYS)

=item * B<-Duseithreads>

set USE_ITHREADS = define (also sets USE_MULTI and USE_IMP_SYS)

=item * B<-Dusemultiplicity>

sets USE_MULTI = define (also sets USE_ITHREADS and USE_IMP_SYS)

=item * B<-Duseimpsys>

sets USE_IMP_SYS = define (also sets USE_ITHREADS and USE_MULTI)

=item * B<-Uusethreads> or B<-Uuseithreads>

unset C<USE_MULTI>, C<USE_IMP_SYS> and C<USE_ITHREADS>

=item * B<-Dusemymalloc>

set C<PERL_MALLOC := define>

=item * B<-Duselargefiles>

set C<USE_LARGE_FILES := define>

=item * B<-Duse64bint>

set C<USE_64_BIT_INT := define> (always for win64, needed for -UWIN64)

=item * B<-Duselongdouble>

set C<USE_LONG_DOUBLE := define> (GCC only)

=item * B<-Dusequadmath>

set both C<USE_QUADMATH := define> and C<I_QUADMATH := define> (GCC only)

=item  * B<-Dusesitecustomize>

set C<USE_SITECUST := define>

=item * B<-Udefault_inc_excludes_dot>

unsets C<# DEFAULT_INC_EXCLUDES_DOT := define> (comments out the line)

=item * B<-Dbccold>

set BCCOLD = define (this is for bcc32 <= 5.4)

=item * B<-Dgcc_v3_2>

set USE_GCC_V3_2 = define (this is for gcc >= 3.2)

=item * B<-DDEBUGGING>

sets CFG = Debug

=item * B<-DINST_DRV=...>

sets INST_DRV to a new value (default is "c:")

=item * B<-DINST_TOP=...> or B<-Dprefix=...>

sets INST_TOp to a new value (default is "$(INST_DRV)\perl"), this is
where perl will be installed when C<< [ng]make install >> is run.

=item * B<-DINST_VER=...>

sets INST_VER to a new value (default is forced not set), this is also used
as part of the installation path to get a more unixy installation.
Without C<INST_VER> and C<INST_ARCH> you get an ActiveState like
installation.

=item * B<-DINST_ARCH=...>

sets INST_ARCH to a new value (default is forced not set), this is also used
as part of the installation path to get a more unixy  installation.
Without C<INST_VER> and C<INST_ARCH> you get an ActiveState like
installation.

=item * B<-DCCHOME=...>

Set the base directory for the C compiler.
B<$(CCHOME)\bin> still needs to be in the path!

=item * B<-DIS_WIN95>

sets IS_WIN95 to 'define' to indicate this is Win9[58]

=item * B<-DCRYPT_SRC=...>

The file to use as source for des_fcrypt()

=item * B<-DCRYPT_LIB=...>

The library to use for des_fcrypt()

=item * B<-Dcf_email=...>

Set the cf_email option (Config.pm)

=item * B<-Accflags=...>

Sets C<BUILDOPTEXTRA>

=item * B<-Aldflags=...>

Adds and sets C<PRIV_LINK_FLAGS>

=back

=cut

my %win32_makefile_map = (
    nmake => "Makefile",
    gmake => "GNUmakefile",
);

sub Configure_win32 {
    my($command, $win32_maker, @args ) = @_;
    $win32_maker ||= 'nmake'; $win32_maker = lc $win32_maker;
    my $is_nmake = $win32_maker eq 'nmake';
    my $is_gmake = $win32_maker eq 'gmake';

    local $_;
    my %opt_map = (
        "-Dusethreads"               => "USE_ITHREADS",
        "-Duseithreads"              => "USE_ITHREADS",
        "-Duseperlio"                => "USE_PERLIO",
        "-Dusemultiplicity"          => "USE_MULTI",
        "-Duseimpsys"                => "USE_IMP_SYS",
        "-Uuseimpsys"                => "USE_IMP_SYS",
        "-Dusemymalloc"              => "PERL_MALLOC",
        "-Duselargefiles"            => "USE_LARGE_FILES",
        "-Duse64bitint"              => "USE_64_BIT_INT",
        "-Duselongdouble"            => "USE_LONG_DOUBLE",
        "-Dusequadmath"              => "USE_QUADMATH",
        "-Dusesitecustomize"         => "USE_SITECUST",
        "-Uuseshrplib"               => "BUILD_STATIC",
        "-Udefault_inc_excludes_dot" => "DEFAULT_INC_EXCLUDES_DOT",
        "-UWIN64"                    => "WIN64",
        "-Uusethreads"               => "USE_ITHREADS",
        "-Uuseithreads"              => "USE_ITHREADS",
        "-UUSE_MINGW_ANSI_STDIO"     => "USE_MINGW_ANSI_STDIO",
        "-DDEBUGGING"                => "USE_DEBUGGING",
        "-DINST_DRV"                 => "INST_DRV",
        "-DINST_TOP"                 => "INST_TOP",
        "-Dprefix"                   => "INST_TOP",
        "-DINST_VER"                 => "INST_VER",
        "-DINST_ARCH"                => "INST_ARCH",
        "-Dcf_email"                 => "EMAIL",
        "-DCCTYPE"                   => "CCTYPE",
        "-Dgcc_v3_2"                 => "USE_GCC_V3_2",
        "-DGCC_4XX"                  => "GCC_4XX",
        "-DGCCWRAPV"                 => "GCCWRAPV",
        "-DGCCHELPERDLL"             => "GCCHELPERDLL",
        "-Dbccold"                   => "BCCOLD",
        "-DCCHOME"                   => "CCHOME",
        "-DGCCBIN"                   => "GCCBIN",
        "-DIS_WIN95"                 => "IS_WIN95",
        "-DCRYPT_SRC"                => "CRYPT_SRC",
        "-DCRYPT_LIB"                => "CRYPT_LIB",
        "-DEXTRALIBDIRS"             => "EXTRALIBDIRS",
    );
# %opts hash-values:
# undef  => leave option as-is when no override (makefile default)
# 0      => disable option when no override  (forced default)
# (true) => enable option when no override (change value, unless
#           $key =~ /^(?:PERL|USE)_/) (forced default)
    my %opts = (
        USE_MULTI                => 1,
        USE_ITHREADS             => 1,
        USE_IMP_SYS              => 1,
        USE_PERLIO               => 1,
        USE_LARGE_FILES          => 0,        # default define
        PERL_MALLOC              => 0,
        BUILD_STATIC             => 0,
        USE_64_BIT_INT           => 0,
        USE_LONG_DOUBLE          => 0,
        USE_QUADMATH             => 0,
        I_QUADMATH               => 0,
        WIN64                    => 1,
        USE_SITECUST             => 0,
        DEFAULT_INC_EXCLUDES_DOT => 1,
        USE_MINGW_ANSI_STDIO     => 1,
        USE_DEBUGGING            => 0,
        INST_DRV                 => undef,
        INST_TOP                 => undef,
        INST_VER                 => '',
        INST_ARCH                => '',
        EMAIL                    => undef,    # used to be $smoker,
        CCTYPE                   => undef,    # used to be $win32_cctype,
        USE_GCC_V3_2             => 0,
        GCC_4XX                  => 0,
        GCCWRAPV                 => 0,
        GCCHELPERDLL             => undef,
        BCCOLD                   => 0,
        CCHOME                   => undef,
        GCCBIN                   => 'GCC',
        IS_WIN95                 => 0,
        CRYPT_SRC                => undef,
        CRYPT_LIB                => undef,
        EXTRALIBDIRS             => undef,
    );

    # $undef_re: regex for options that should be UNcommented for -Uxxx
    my $undef_re  = qr/WIN64/;

    # $def_re: regex for options that should be UNcommented for -Dxxx
    my $def_re = qr/((?:(?:DEFAULT|PERL|USE|IS|GCC|I)_\w+)|BCCOLD|GCCWRAPV)/;

    my @w32_opts = grep ! /^$def_re/, keys %opts;
    my $config_args = join " ",
        grep /^-[DU][a-z_]+/, quotewords( '\s+', 1, $command );
    push @args, "config_args=$config_args";

    my @adjust_opts = grep {
        /^-A(?:ccflags|ldflags)=/
    } quotewords('\s+', 1, $command);
    my $adjust_ccflags = join(
        " ",
        map {
            s/^-Accflags=(["']?)(.+?)\1// ? $2 : ()
        } grep { /^-Accflags=/ } @adjust_opts
    );
    my $adjust_ldflags = join(
        " ",
        map {
            s/^-Aldflags=(["']?)(.+?)\1// ? $2 : ()
        } grep { /^-Aldflags=/ } @adjust_opts
    );

    $command =~ m{^\s*\./Configure\s+(.*)} or die "unable to parse command";
    my $cmdln = $1;
    foreach ( quotewords( '\s+', 1, $cmdln ) ) {
        m/^-[des]{1,3}$/ and next;
        m/^-Dusedevel$/  and next;
        m/^-A(ccflags|ldflags)/ and next;
        if (my( $option, $value ) = /^(-[DU]\w+)(?:=(.+))?$/) {
            die "invalid option '$_'" unless exists $opt_map{$option};
            $opts{$opt_map{$option}} = $value ? $value : 1;
            $option =~ /^-U/ and $opts{$opt_map{$option}} = 0;
        }
    }

    # Handle some switches that impact more make-vars
    if ( $cmdln =~ /-Uusei?threads\b/ ) {
        $opts{USE_MULTI} = $opts{USE_ITHREADS} = $opts{USE_IMP_SYS} = 0;

    }
    if ( $cmdln =~ /-Dusequadmath\b/ ) {
        $opts{USE_QUADMATH} = $opts{I_QUADMATH} = 1;
    }
    # If you set one, we do all, so you can have fork()
    # unless you set -Uuseimpsys
    if ( $cmdln !~ /-Uuseimpsys\b/ ) {
        if ( $opts{USE_MULTI} || $opts{USE_ITHREADS} || $opts{USE_IMP_SYS} ) {
            $opts{USE_MULTI} = $opts{USE_ITHREADS} = $opts{USE_IMP_SYS} = 1;
        }
    }
    else {
        if ( $opts{USE_MULTI} || $opts{USE_ITHREADS} ) {
            $opts{USE_MULTI} = $opts{USE_ITHREADS} = 1;
        }
    }

    # If you -Dgcc_v3_2 you 'll *want* CCTYPE = GCC
    $opts{CCTYPE} = "GCC" if $opts{USE_GCC_V3_2};

    # If you -DGCC_4XX you 'll *want* CCTYPE = GCC
    $opts{CCTYPE} = "GCC" if $opts{GCC_4XX};

    # If you -Dbccold you 'll *want* CCTYPE = BORLAND
    $opts{CCTYPE} = "BORLAND" if $opts{BCCOLD};

    printf "* %-25s = %s\n", $_, $opts{$_} for grep $opts{$_}, sort keys  %opts;

    local (*ORG, *NEW);
    my $maker = $win32_makefile_map{ $win32_maker }
      or die "no make file for $win32_maker";
    my $in =  "win32/$maker";
    my $out = "win32/smoke.mk";
    open(ORG, "<:raw", $in) or die "Cannot line-end-check '$in': $!";
    my $dummy = <ORG>;
    close(ORG); undef(*ORG);
    my $layer = $dummy =~ /\015\012\Z/ ? ':crlf' : '';

    open ORG, "<$layer", $in  or die "unable to open '$in': $!";
    open NEW, ">:crlf", $out or die "unable to open '$out': $!";
    my $donot_change = 0;
    my $check_linkflags = $adjust_ldflags ? 1 : 0;
    while (<ORG>) {
        if ( $donot_change ) {
            # need to help the Win95 build
            if (m/^\s*CFG_VARS\s*=/) {
                my( $extra_char, $quote ) = ($is_nmake || $is_gmake)
                    ? ( "\t", '"' ) : ("~", "" );
                $_ .= join "", map "\t\t$quote$_$quote\t${extra_char}\t\\\n",
                                   grep /\w+=/, @args;
            }
            print NEW $_;
            next;
        } else {
            $donot_change = /^#+ CHANGE THESE ONLY IF YOU MUST #+/;
        }

        # Only change config stuff _above_ that line!
        if ( m/^\s*#?\s*$def_re(\s*[\*:]?=\s*define)$/ ) {
            $_ = ($opts{$1} ? "" : "#") . $1 . $2 . "\n";
        }
        elsif (m/\s*#?\s*($undef_re)(\s*[*:]?=\s*undef)$/) {
            $_ = ($opts{$1} ? "#" : "") . "$1$2\n";
        }
        elsif (m/^\s*#?\s*(CFG\s*[*:]?=\s*Debug)$/) {
            $_ = ($opts{USE_DEBUGGING} ? "" : "#") . $1 . "\n";
        }
        elsif (m/^\s*#?\s*(BUILD_STATIC)\s*([*:]?=)\s*(.*)$/) {
            my( $macro, $op, $mval ) = ( $1, $2, $3);
            if ( $config_args =~ /-([UD])useshrplib\b/ ) {
                $_ = ( $1 eq 'D' ? "#" : "" ) . "$macro $op $mval\n";
            }
        }
        elsif (m/^\s*#?\s*(BUILDOPT)\s*([*:]?)=\s*\$\(BUILDOPTEXTRA\)/) {
            my $prf = $2 ? $2 : '';
            if ($adjust_ccflags) {
                # Set BUILDOPTEXTRA to $adjust_ccflags
                s/^\s*#\s*//;
                $_ = "BUILDOPTEXTRA\t${prf}= $adjust_ccflags\n$_";
             }
             if ($adjust_ldflags) {
                $_ .= "\n# Additional linker flags\n"
                    . "PRIV_LINK_FLAGS\t${prf}= $adjust_ldflags\n";
             }
        }
        else {
            foreach my $cfg_var ( grep defined $opts{ $_ }, @w32_opts ) {
                if (  m/^\s*#?\s*($cfg_var\s*(\*|:)?=)\s*(.*)$/ ) {
                    my ($name, $val) = ($1, $2);
                    next if $_ =~ /^#/ and !$opts{ $cfg_var };
                    $_ =  $opts{ $cfg_var } ?
                        "$name $opts{ $cfg_var }\n":
                        "#$name $val\n";
                    last;
                }
            }
        }
        print NEW $_;
    }
    close ORG;
    close NEW;
    return $out;
} # Configure_win32

=head2 set_vms_rooted_logical( $logical, $dir )

This will set a VMS rooted logical like:

    define/translation=concealed $logical $dir

=cut

sub set_vms_rooted_logical {
    my( $logical, $dir ) = @_;
    return unless $^O eq 'VMS';

    my $cwd = cwd();
    $dir ||= $cwd;

    -d $dir or do {
        require File::Path;
        File::Path::mkpath( $dir );
    };
    chdir $dir or die "Cannot chdir($dir): $!";

    # On older systems we might exceed the 8-level directory depth limit
    # imposed by RMS.  We get around this with a rooted logical, but we
    # can't create logical names with attributes in Perl, so we do it
    # in a DCL subprocess and put it in the job table so the parent sees it.

    open TSBRL, '> tsbuildrl.com' or die "Error creating DCL-file; $!";

    print TSBRL <<COMMAND;
\$ $logical = F\$PARSE("SYS\$DISK:[]",,,,"NO_CONCEAL")-".][000000"-"]["-"].;"+".]"
\$ DEFINE/JOB/NOLOG/TRANSLATION=CONCEALED $logical '$logical'
COMMAND
    close TSBRL;

    my $result = system '@tsbuildrl.com';
    1 while unlink 'tsbuildrl.com';
    chdir $cwd;
    return $result == 0;
}

=head2 get_cfg_filename( )

C<get_cfg_filename()> tries to find a B<cfg file> and returns it.

=cut

sub get_cfg_filename {
    my( $cfg_name ) = @_;
    return $cfg_name if defined $cfg_name && -f $cfg_name;

    my( $base_dir ) = ( $0 =~ m|^(.*)/| ) || File::Spec->curdir;
    $cfg_name = File::Spec->catfile( $base_dir, 'smoke.cfg' );
    return $cfg_name  if -f $cfg_name && -s _;

    $base_dir = File::Spec->curdir;
    $cfg_name = File::Spec->catfile( $base_dir, 'smoke.cfg' );
    return $cfg_name if -f $cfg_name && -s _;

    return undef;
}

=head2 read_logfile( )

Read the logfile. If an argument is passed, force to (re)read the log
If no argument is passed, return the stored log if available otherwise
read the logfile

=cut

sub read_logfile {
    my ($logfile, $verbose) = @_;
    return if ! defined $logfile;

    open my $fh, "<", $logfile  or return undef;
    my $log = do { local $/; <$fh> };
    close $fh;

    my $es = eval { decode("utf-8",  $log, Encode::FB_CROAK ) };
    $@   and eval { $es = decode("cp1252",     $log, Encode::FB_CROAK ) };
    $@   and eval { $es = decode("iso-8859-1", $log, Encode::FB_CROAK ) };

    warn("Couldn't decode logfile($logfile): $@") if $@;
    return $@ ? $log : $es;
}

=head2 grepccmsg( $cc, $logfile, $verbose )

This is a port of Jarkko Hietaniemi's grepccerr script.

=cut

sub grepccmsg {
    my( $cc, $smokelog, $verbose ) = @_;
    defined $smokelog or return;
    $cc = 'gcc' if !$cc || $cc eq 'g++' || $cc eq 'clang';
    my %OS2PAT = (
        'aix' =>
            # "foo.c", line n.c: pppp-qqq (W) ...error description...
            # "foo.c", line n.c: pppp-qqq (S) ...error description...
            '(^".+?", line \d+\.\d+: \d+-\d+ \([WS]\) .+?$)',

        'dec_osf' =>
            # DEC OSF/1, Digital UNIX, Tru64 (notice also VMS)
            # cc: Warning: foo.c, line nnn: ...error description...(error_tag)
            #     ...error line...
            # ------^
            # cc: Error: foo.c, line nnn: ...error description... (error_tag)
            #     ...error line...
            # ------^
            '(^cc: (?:Warning|Error): .+?^-*\^$)',

        'hpux' =>
            # cc: "foo.c"" line nnn: warning ppp: ...error description...
            # cc: "foo.c"" line nnn: error ppp: ...error description...
            '(^cc: ".+?", line \d+: (?:warning|error) \d+: .+?$)',

        'irix' =>
            # cc-pppp cc: WARNING File = foo.c, Line = nnnn
            # ...error description...
            #
            # ...error line...
            #   ^
            # cc-pppp cc: ERROR File = foo.c, Line = nnnn
            # ...error description...
            #
            # ...error line...
            #   ^
            '^(cc-\d+ cc: (?:WARNING|ERROR) File = .+?, ' .
            'Line = \d+.+?^\s*\^$)',

        'solaris' =>
            # "foo.c", line nnn: warning: ...error description...
            # "foo.c", line nnn: warning: ...:
            #         ...error description...
            # "foo.c", line nnn: syntax error ...
            '(^".+?", line \d+: ' .
            '(?:warning: (?:(?:.+?:$)?.+?$)|syntax error.+?$))',

        'vms' => # same compiler as Tru64, different message syntax
            #     ...error line...
            # ......^
            # %CC-W-MESSAGEID, ...error description...
            # at line number nnn in file foo.c
            '(^\n.+?\n^\.+?\^\n^\%CC-(?:I|W|E|F)-\w+, ' .
            '.+?\nat line number \d+ in file \S+?$)',

        'gcc' =>
            # foo.c: In function `foo':
            # foo.c:nnn: warning: ...
            # foo.c: In function `foo':
            # foo.c:nnn:ppp: warning: ...
                # Sometimes also the column is mentioned.
            # foo.c: In function `foo':
            # foo.c:nnn: error: ...
            # foo.c(:nn)?: undefined reference to ...
            '(^(?-s:.+?):(?: In function .+?:$|' .
               '(?: undefined reference to .+?$)|' .
               '\d+(?:\:\d+)?: ' . '(?:warning:|error:|note:|invalid) .+?$))',

        'mswin32' => # MSVC(?:60)*
            # foo.c : error LNKnnn: error description
            # full\path\to\fooc.c : fatal error LNKnnn: error description
            # foo.c(nnn) : warning Cnnn: warning description
            '(^(?!NMAKE)(?-s:.+?) : (?-s:.+?)\d+: .+?$)',

        'bcc32' => # BORLAND 5.5 on MSWin32
            # Warning Wnnn filename line: warning description
            # Error Ennn:: error description
            '(^(?:(?:Warning W)|(?:Error E))\d+ .+? \d+: .+?$)',

        'icc' => # Intel C on Linux
            # pp_sys.c(4412): warning #num: text
            #       SETi( getpriority(which, who) );
            #       ^
            '(^.*?\([0-9]+\): (?:warning #[0-9]+|error): .+$)',
        'icpc' => # Intel C++
            '(^.*?\([0-9]+\): (?:warning #[0-9]+|error): .+$)',
    );
    exists $OS2PAT{ lc $cc } or $cc = 'gcc';
    my $pat = $OS2PAT{ lc $cc };

    my( $indx, %error ) = ( 1 );
    if ($smokelog) {
        $verbose and print "Pattern($cc): /$pat/\n";
    } else {
        $error{ "Couldn't examine logfile for compiler warnings." } = 1;
    }

    while ($smokelog =~ m/$pat/mg) {
        (my $msg = $1) =~ s/^\s+//;
        $msg =~ s/[\s\r\n]+\Z//;

        # Skip known junk from Configure
        $msg =~ m{^try\.c:[ :0-9]+\bwarning:} and next;

        # We need to think about this IRIX/$Config{cc} thing
        # $cc eq "irix" && $Config{cc} =~ m/-n32|-64/ &&
        #     $msg =~ m/cc-(?:1009|1110|1047) / and next;

        $error{ $msg } ||= $indx++;
    }

    my @errors = sort { $error{ $a } <=> $error{ $b } } keys %error;

    return wantarray ? @errors : \@errors;
}

=head2 grepnonfatal( $cc, $logfile, $verbose )

This is a way to find known failures that do not cause the tests to
fail but are important enough to report, like being unable to install
manual pages.

=cut

sub grepnonfatal {
    my( $cc, $smokelog, $verbose ) = @_;
    $smokelog or return;

    my( $indx, %error ) = ( 1 );

    my $kf = qr{
        # Pod::Man is not available: Can't load module Encode, dynamic loading not available in this perl.
        (\b (\S+) (?-x: is not available: Can't load module )
            (\S+?) , (?-x: dynamic loading not available) )
    }xi;

    while ($smokelog =~ m{$kf}g) {
        my $fail = $1; # $2 = "Pod::Man", $3 = "Encode"

        $error{ $fail } ||= $indx++;
    }

    my @errors = sort { $error{ $a } <=> $error{ $b } } keys %error;

    return wantarray ? @errors : \@errors;
}

=head2 get_local_patches( $ddir )

C<get_local_patches()> reads F<patchlevel.h> to scan for the locally
applied patches array.

=cut

sub get_local_patches {
    my( $ddir, $verbose ) = @_;
    $ddir = shift || cwd();
    my $plevel = catfile( $ddir, 'patchlevel.h' );

    my $logger = Test::Smoke::Logger->new(v => $verbose);

    my @lpatches = ( );
    local *PLEVEL;
    $logger->log_info("Locally applied patches from '%s'", $plevel);
    unless ( open PLEVEL, "< $plevel" ) {
        $logger->log_warn("open(%s) error: %s", $plevel, $!);
        return @lpatches;
    }
    my( $seen, $patchnum );
    while ( <PLEVEL> ) {
        $patchnum = $1 if /#define PERL_PATCHNUM\s+(\d+)/;
        $seen && /^\s*,"(.+)"/ and push @lpatches, $1;
        /^\s*static.+?local_patches\[\]/ and $seen++;
    }
    close PLEVEL;
    if ( defined $patchnum ) {
        @lpatches = map {
            s/^(MAINT|DEVEL)$/$1$patchnum/;
            $_;
        } @lpatches;
    }
    $logger->log_info("Patches: '%s'", join(';', @lpatches));
    return @lpatches;
}

=head2 set_local_patch( $ddir, @descr )

Copy the code from F<patchlevel.h>. Older (pre 5.8.1) perls do not
have it and it doesn't work on MSWin32.

=cut

sub set_local_patch {
    my( $ddir, @descr ) = @_;

    my $plh = catfile( $ddir, 'patchlevel.h' );
    my $pln = catfile( $ddir, 'patchlevel.new' );
    my $plb = catfile( $ddir, 'patchlevel.bak' );
    local( *PLIN, *PLOUT );
    open PLIN,  "< $plh" or return 0;
    open PLOUT, "> $pln" or return 0;
    my $seen=0;
    my $done=0;
    while ( <PLIN> ) {
        if ( /^(\s+),NULL/ and $seen ) {
            $done++;
            while ( my $c = shift @descr ) {
                print PLOUT qq{$1,"$c"\n};
           }
        }
        $seen++ if /local_patches\[\]/;
        print PLOUT;
    }
    close PLIN;
    close PLOUT or return 0;

    if ( not $done ) {
        require Carp;
        Carp::carp("Failed to update patchlevel.h. Content not as expected?");
        return 0;
    }

    -e $plb and 1 while unlink $plb;
    my $errno = "$!";
    if ( -e $plb ) {
        require Carp;
        Carp::carp( "Could not unlink $plb : $errno" );
        return 0;
    }

    unless ( rename $plh, $plb ) {
        require Carp;
        Carp::carp( "Could not rename $plh to $plb : $!" );
        return 0;
    }
    unless ( rename $pln, $plh ) {
        require Carp;
        Carp::carp( "Could not rename '$pln' to '$plh' : $!" );
        return 0;
    }

    return 1;
}

=head2 get_config( $filename )

Read and parse the configuration from file, or return the default
config.

=cut

sub get_config {
    my( $config_file ) = @_;

    return (
        [ "",
          "-Dusethreads -Duseithreads"
        ],
        [ "",
          "-Duse64bitint",
          "-Duse64bitall",
          "-Duselongdouble",
          "-Dusemorebits",
          "-Duse64bitall -Duselongdouble"
        ],
        { policy_target =>       "-DDEBUGGING",
          args          => [ "", "-DDEBUGGING" ]
        },
    ) unless defined $config_file;

    open CONF, "< $config_file" or do {
        warn "Can't open '$config_file': $!\nUsing standard configuration";
        return get_config( undef );
    };
    my( @conf, @cnf_stack, @target );

    # Cheat. Force a break marker as a line after the last line.
    foreach (<CONF>, "=") {
        m/^#/ and next;
        s/\s+$// if m/\s/;      # Blanks, new-lines and carriage returns. M$
        if (m:^/:) {
            m:^/(.*)/$:;
            defined $1 or die "Policy target line didn't end with '/': '$_'";
            push @target, $1;
            next;
        }

        if (!m/^=/) {
            # Not a break marker
            push @conf, $_;
            next;
        }

        # Break marker, so process the lines we have.
        if (@target > 1) {
            warn "Multiple policy target lines " .
                 join (", ", map {"'$_'"} @target) . " - will use first";
        }
        my %conf = map { $_ => 1 } @conf;
        if (keys %conf == 1 and exists $conf{""} and !@target) {
            # There are only blank lines - treat it as if there were no lines
            # (Lets people have blank sections in configuration files without
            #  warnings.)
            # Unless there is a policy target.  (substituting ''  in place of
            # target is a valid thing to do.)
            @conf = ();
        }

        unless (@conf) {
            # They have no target lines
            @target and
                warn "Policy target '$target[0]' has no configuration lines, ".
                     "so it will not be used";
            @target = ();
            next;
        }

        while (my ($key, $val) = each %conf) {
            $val > 1 and
                warn "Configuration line '$key' duplicated $val times";
        }
        my $args = [@conf];
        @conf = ();
        if (@target) {
            push @cnf_stack, { policy_target => $target[0], args => $args };
            @target = ();
            next;
        }

        push @cnf_stack, $args;
    }
    close CONF;
    return @cnf_stack;
}

=head2 get_patch( [$ddir] )

Try to find the patchlevel, look for B<.patch> or try to get it from
B<patchlevel.h> as a fallback.

=cut

sub get_patch {
    my( $ddir ) = @_;
    $ddir ||= File::Spec->curdir;

    my $dot_patch = File::Spec->catfile( $ddir, '.patch' );
    local *DOTPATCH;
    my $patch_level = '?????';
    if ( open DOTPATCH, "< $dot_patch" ) {
        chomp( $patch_level = <DOTPATCH> || '' );
        close DOTPATCH;

        if ( $patch_level ) {
            if ($patch_level =~ /\s/) {
                my ($branch, $sha, $describe) = (split ' ', $patch_level)[0, -2, -1];
                return [$sha, $describe, $branch];
            }
            return [$patch_level];
        }
        return [ '' ];
    }

    my $dot_git_patch = File::Spec->catfile( $ddir, '.git_patch' );

    local *DOTGITPATCH;
    if ( open DOTGITPATCH, "< $dot_git_patch" ) {
        chomp( $patch_level = <DOTGITPATCH> );
        close DOTGITPATCH;
        if ( $patch_level ) {

            return undef if ( $patch_level =~ /^\$Format/ ); # Not expanded

            my @dot_git_patch = split '\|', $patch_level;

            # As we do not use time information, we can just pick the first and
            # the last two elements
            my ($sha, $describe, $names) = @dot_git_patch[0, -2, -1];
            my @names = split /,\s*/, $names;

            my $branch = undef; # or blead?

            my ($first, $last) = @names[0, -1];
            if ($first =~ /^HEAD -> (.*)/ ) {
                # HEAD -> my_branch
                # https://github.com/Perl/perl5/archive/refs/heads/blead.tar.gz
                $branch = $1;
            } elsif ( $first =~ /^tag: .*/ ) {
                # tag: v5.41.6
                # https://github.com/Perl/perl5/archive/refs/tags/v5.41.6.tar.gz
                $branch = $1;
            } elsif ( $first ne $last ) {
                # Pull request with source branch in Perl/perl5 repo
                # https://github.com/Perl/perl5/archive/refs/pull/22991/head.tar.gz
                # OR
                # branch pushed on Perl/perl5
                # https://github.com/Perl/perl5/archive/refs/heads/yves/handle_weird_preprocessor_stmt_in_HeaderParser_pm.tar.gz
                $branch = $last;
            } else { #( $first eq $last ) {
                # Pull request with source branch in fork
                # https://github.com/Perl/perl5/archive/refs/pull/22989/head.tar.gz
                $last =~ /^ref\/pull\/(.*)\/head/;
                $branch = $1;
            }

            return [$sha, $describe, $branch];
        }
    }


    # There does not seem to be a '.patch', try 'git_version.h'
    # We are looking for the line: #define PERL_PATCHNUM "v5.21.6-224-g6324db4"
    my $git_version_h = File::Spec->catfile($ddir, 'git_version.h');
    if (open my $gvh, '<', $git_version_h) {
        while (my $line = <$gvh>) {
            if ($line =~ /^#define PERL_PATCHNUM "(.+)"$/) {
                return [$1];
            }
        }
        close $gvh;
    }
    # This only applies to
    # There does not seem to be a '.patch', and we couldn't find git_version.h
    # Now try 'patchlevel.h'
    # We are looking for the line: ,"DEVEL19999" (within local_patches[] = {}
    local *PATCHLEVEL_H;
    my $patchlevel_h = File::Spec->catfile( $ddir, 'patchlevel.h' );
    if ( open PATCHLEVEL_H, "< $patchlevel_h" ) {
        my( $declaration_seen, $patchnum ) = ( 0, 0 );
        while ( <PATCHLEVEL_H> ) {
            $patchnum = $1 if /#define PERL_PATCHNUM\s+(\d+)/;
            $declaration_seen ||= /local_patches\[\]/;
            $declaration_seen &&
                /^\s+,"(?:(?:DEVEL|MAINT)(\d+)?)|(RC\d+)"/ or next;
            $patch_level = $patchnum || $1 || $2 || '?????';
            if ( $patch_level =~ /^RC/ ) {
                $patch_level = version_from_patchlevel_h( $ddir ) .
                               "-$patch_level";
            } else {
                $patch_level .= $patchnum ? "" : '(+)';
            }
        }
    }
    return [ $patch_level ];
}

=head2 version_from_patchlevel_h( $ddir )

C<version_from_patchlevel_h()> returns a "dotted" version as derived
from the F<patchlevel.h> file in the distribution.

=cut

sub version_from_patchlevel_h {
    my( $ddir ) = @_;
    $ddir ||= File::Spec->curdir;
    my $file = File::Spec->catfile( $ddir, 'patchlevel.h' );

    my( $revision, $version, $subversion ) = qw( 5 ? ? );
    local *PATCHLEVEL;
    if ( open PATCHLEVEL, "< $file" ) {
        my $patchlevel = do { local $/; <PATCHLEVEL> };
        close PATCHLEVEL;

        if ( $patchlevel =~ /^#define PATCHLEVEL\s+(\d+)/m ) {
            # Also support perl < 5.6
            $version = sprintf "%03u", $1;
            $subversion = $patchlevel =~ /^#define SUBVERSION\s+(\d+)/m
                ? sprintf "%02u", $1 : '??';
            return "$revision.$version$subversion";
        }

        $revision   = $patchlevel =~ /^#define PERL_REVISION\s+(\d+)/m
                    ? $1 : '?';
        $version    = $patchlevel =~ /^#define PERL_VERSION\s+(\d+)/m
                    ? $1 : '?';
        $subversion = $patchlevel =~ /^#define PERL_SUBVERSION\s+(\d+)/m
                    ? $1 : '?';
    }
    return "$revision.$version.$subversion";
}

=head2 get_ncpu( $osname )

C<get_ncpu()> returns the number of available (online/active/enabled) CPUs.

It does this by using some operating system specific trick (usually
by running some external command and parsing the output).

If it cannot recognize your operating system an empty string is returned.
If it can recognize it but the external command failed, C<"? cpus">
is returned.

In the first case (where we really have no idea how to proceed),
also a warning (C<get_ncpu: unknown operating system>) is sent to STDERR.

=over

=item B<WARNINGS>

If you get the warning C<get_ncpu: unknown operating system>, you will
need to help us-- how does one tell the number of available CPUs in
your operating system?  Sometimes there are several different ways:
please try to find the fastest one, and a one that does not require
superuser (administrator) rights.

Thanks to Jarkko Hietaniemi for donating this!

=back

=cut

sub get_ncpu {
    # Only *nixy osses need this, so use ':'
    local $ENV{PATH} = "$ENV{PATH}:/usr/sbin:/sbin";

    my $cpus = "?";
    OS_CHECK: {
        local $_ = shift or return "";

        /aix/i && do {
            my @output = `lsdev -C -c processor -S Available`;
            $cpus = scalar @output;
            last OS_CHECK;
        };

        /(?:darwin|.*bsd)/i && do {
            chomp( my @output = `sysctl -n hw.ncpu` );
            $cpus = $output[0];
            last OS_CHECK;
        };

        /hp-?ux/i && do {
            my @output = grep /^processor/ => `ioscan -fnkC processor`;
            $cpus = scalar @output;
            last OS_CHECK;
        };

        /irix/i && do {
            my @output = grep /\s+processors?$/i => `hinv -c processor`;
            $cpus = (split " ", $output[0])[0];
            last OS_CHECK;
        };

        /linux/i && do {
            my @output; local *PROC;
            if ( open PROC, "< /proc/cpuinfo" ) {
                @output = grep /^processor/ => <PROC>;
                close PROC;
            }
            $cpus = @output ? scalar @output : '';
            last OS_CHECK;
        };

        /solaris|sunos|osf/i && do {
            my @output = grep /on-line/ => `psrinfo`;
            $cpus =  scalar @output;
            last OS_CHECK;
        };

        /mswin32|cygwin/i && do {
            $cpus = exists $ENV{NUMBER_OF_PROCESSORS}
                ? $ENV{NUMBER_OF_PROCESSORS} : '';
            last OS_CHECK;
        };

        /vms/i && do {
            my @output = grep /CPU \d+ is in RUN state/ => `show cpu/active`;
            $cpus = @output ? scalar @output : '';
            last OS_CHECK;
        };

        /haiku/i && do {
            eval { require Haiku::SysInfo };
            if (!$@) {
                my $hsi = Haiku::SysInfo->new();
                $cpus = $hsi->cpu_count();
                last OS_CHECK;
            }
        };

        $cpus = "";
        require Carp;
        Carp::carp( "get_ncpu: unknown operationg system" );
    }

    return $cpus ? sprintf( "%s cpu%s", $cpus, $cpus ne "1" ? 's' : '' ) : "";
}

=head2 get_smoked_Config( $dir, @keys )

C<get_smoked_Config()> returns a hash (a listified hash) with the
specified keys. It will try to find F<lib/Config.pm> to get those
values, if that cannot be found (make error?) we can try F<config.sh>
which is used to build F<lib/Config.pm>.
If F<config.sh> is not there (./Configure error?) we try to get some
fallback information from C<POSIX::uname()> and F<patchlevel.h>.

=cut

sub get_smoked_Config {
    my( $dir, @fields ) = @_;
    my %Config = map { ( lc $_ => undef ) } @fields;

    my $perl_Config_heavy = catfile ($dir, "lib", "Config_heavy.pl");
    my $perl_Config_pm    = catfile ($dir, "lib", "Config.pm");
    my $perl_config_sh    = catfile( $dir, 'config.sh' );
    local *CONF;
    if ( open CONF, "< $perl_Config_heavy" ) {

        while (<CONF>) {
            if ( m/^(?:
                       (?:our|my)\ \$[cC]onfig_[sS][hH].*
                    |
                       \$_
                    )\ =\ <<'!END!';/x..m/^!END!/){
                m/!END!(?:';)?$/      and next;
                m/^([^=]+)='([^']*)'/ or next;
                exists $Config{lc $1} and $Config{lc $1} = $2;
            }
        }
        close CONF;
    }
    my %conf2 = map {
        ( $_ => undef )
    } grep !defined $Config{ $_ } => keys %Config;
    if ( open CONF, "< $perl_Config_pm" ) {

        while (<CONF>) {
            if ( m/^(?:
                       (?:our|my)\ \$[cC]onfig_[sS][hH].*
                    |
                       \$_
                    )\ =\ <<'!END!';/x..m/^!END!/){
                m/!END!(?:';)?$/      and next;
                m/^([^=]+)='([^']*)'/ or next;
                exists $conf2{lc $1} and $Config{lc $1} = $2;
            }
        }
        close CONF;
    }
    %conf2 = map {
        ( $_ => undef )
    } grep !defined $Config{ $_ } => keys %Config;
    if ( open CONF, "< $perl_config_sh" ) {
        while ( <CONF> ) {
            m/^([^=]+)='([^']*)'/ or next; # '
            exists $conf2{ $1} and $Config{ lc $1 } = $2;
        }
        close CONF;
    }
    %conf2 = map {
        ( $_ => undef )
    } grep !defined $Config{ $_ } => keys %Config;
    if ( keys %conf2 ) {
        # Fall-back values from POSIX::uname() (not reliable)
        require POSIX;
        my( $osname, undef, $osvers, undef, $arch) = POSIX::uname();
        $Config{osname}   = lc $osname if exists $conf2{osname};
        $Config{osvers}   = lc $osvers if exists $conf2{osvers};
        $Config{archname} = lc $arch   if exists $conf2{archname};
        $Config{version}  = version_from_patchlevel_h( $dir )
            if exists $conf2{version};
    }

    # There should be no under-bars in perl versions!
    exists $Config{version} and $Config{version} =~ s/_/./g;
    return %Config;
}

=head2 parse_report_Config( $report )

C<parse_report_Config()> returns a list attributes from a smoke report.

    my( $version, $plevel, $os, $osvers, $archname, $summary, $branch ) =
        parse_report_Config( $rpt );

=cut

sub parse_report_Config {
    my( $report ) = @_;

    my $branch   = $report =~ /^Automated.+branch (.+?) / ? $1 : 'blead';
    my $version  = $report =~ /^Automated.*for(?: branch \S+)? (.+) patch/ ? $1 : '';
    my $plevel   = $report =~ /^Automated.+?(\S+)$/m
        ? $1 : '';
    if ( !$plevel ) {
        $plevel = $report =~ /^Auto.*patch\s+\S+\s+(\S+)/ ? $1 : '';
    }
    my $osname   = $report =~ /\bon\s+(.*) - / ? $1 : '';
    my $osvers   = $report =~ /\bon\s+.* - (.*)/? $1 : '';
    $osvers =~ s/\s+\(.*//;
    my $archname = $report =~ /:.* \((.*)\)/ ? $1 : '';
    my $summary  = $report =~ /^Summary: (.*)/m ? $1 : '';

    return ( $version, $plevel, $osname, $osvers, $archname, $summary, $branch );
}

=head2 get_regen_headers( $ddir )

C<get_regen_headers()> looks in C<$ddir> to find either
F<regen_headers.pl> or F<regen.pl> (change 18851).

Returns undef if not found or a string like C<< $^X "$regen_headers_pl" >>

=cut

sub get_regen_headers {
    my( $ddir ) = @_;

    $ddir ||= File::Spec->curdir; # Don't smoke in a dir "0"!

    my $regen_headers_pl = File::Spec->catfile( $ddir, "regen_headers.pl" );

    -f $regen_headers_pl and return qq[$^X "$regen_headers_pl"];

    $regen_headers_pl = File::Spec->catfile( $ddir, "regen.pl" );
    -f $regen_headers_pl and return qq[$^X "$regen_headers_pl"];

    return; # Should this be "make regen_headers"?
}

=head2 run_regen_headers( $ddir, $verbose );

C<run_regen_headers()> gets its executable from C<get_regen_headers()>
and opens a pipe from it. warn()s on error.

=cut

sub run_regen_headers {
    my( $ddir, $verbose ) = @_;

    my $regen_headers = get_regen_headers( $ddir );

    defined $regen_headers or do {
        warn "Cannot find a regen_headers script\n";
        return;
    };

    $verbose and print "Running [$regen_headers]\n";
    local *REGENH;
    if ( open REGENH, "$regen_headers |" ) {
        while ( <REGENH> ) { $verbose > 1 and print }
        close REGENH or do {
            warn "Error in pipe [$regen_headers]\n";
            return;
        }
    } else {
        warn "Cannot fork [$regen_headers]\n";
        return;
    }
    return 1;
}

=head2 whereis( $prog )

Try to find an executable instance of C<$prog> in $ENV{PATH}.

Rreturns a full file-path (with extension) to it.

=cut

sub whereis {
    my $prog = shift;
    return undef unless $prog; # you shouldn't call it '0'!
    $^O eq 'VMS' and return vms_whereis( $prog );
    my $logger = Test::Smoke::Logger->new(v => shift || 0);

    my $p_sep = $Config::Config{path_sep};
    my @path = split /\Q$p_sep\E/, $ENV{PATH};
    my @pext = split /\Q$p_sep\E/, $ENV{PATHEXT} || '';
    unshift @pext, '';

    foreach my $dir ( @path ) {
        $logger->log_debug("Looking in %s for %s", $dir, $prog);
        foreach my $ext ( @pext ) {
            my $fname = File::Spec->catfile( $dir, "$prog$ext" );
            $logger->log_debug("    check executable %s", $fname);
            if ( -x $fname ) {
                $logger->log_info("Found %s as %s", $prog, $fname);
                return $fname;
                #return $fname =~ /\s/ ? qq/"$fname"/ : $fname;
            }
        }
    }
    $logger->log_info("Could not find %s", $prog);
    return '';
}

=head2 vms_whereis( $prog )

First look in the SYMBOLS to see if C<$prog> is there.
Next look in the KFE-table C<INSTALL LIST> if it is there.
As a last resort we can scan C<DCL$PATH> like we do on *nix/Win32

=cut

sub vms_whereis {
    my $prog = shift;

    # Check SYMBOLS
    eval { require VMS::DCLsym };
    if ( $@ ) {
        require Carp;
        Carp::carp( "Oops, cannot load VMS::DCLsym: $@" );
    } else {
        my $syms = VMS::DCLsym->new;
        return $prog if scalar $syms->getsym( $prog );
    }
    # Check Known File Entry table (INSTALL LIST)
    my $img_re = '^\s+([\w\$]+);\d+';
    my %kfe = map {
        my $img = /$img_re/ ? $1 : '';
        ( uc $img => undef )
    } grep /$img_re/ => qx/INSTALL LIST/;
    return $prog if exists $kfe{ uc $prog };

    require Config;
    my $dclp_env = 'DCL$PATH';
    my $p_sep = $Config::Config{path_sep} || '|';
    my @path = split /\Q$p_sep\E/, $ENV{ $dclp_env }||"";
    my @pext = ( $Config::Config{exe_ext} || $Config::Config{_exe}, '.COM' );

    foreach my $dir ( @path ) {
        foreach my $ext ( @pext ) {
            my $fname = File::Spec->catfile( $dir, "$prog$ext" );
            if ( -x $fname ) {
                return $ext eq '.COM' ? "\@$fname" : "MCR $fname";
            }
        }
    }
    return '';
}

=head2 clean_filename( $fname )

C<clean_filename()> basically returns a vmsify() type of filename for
VMS, and returns an upcase filename for case-ignorant filesystems.

=cut

sub clean_filename {
    my $fname = shift;

    if ( $^O eq 'VMS' ) {
        my @parts = split /[.@#]/, $fname;
        if ( @parts > 1 ) {
            my $ext = ( pop @parts ) || '';
            $fname = join( "_", @parts ) . ".$ext";
        }
    }
    return $NOCASE ? uc $fname : $fname;
}

=head2 calc_timeout( $killtime[, $from] )

C<calc_timeout()> calculates the timeout in seconds.
C<$killtime> can be one of two formats:

=over 8

=item B<+hh:mm>

This format represents a duration and is the easy format as we only need
to translate that to seconds.

=item B<hh:mm>

This format represents a clock time (localtime).  Calculate minutes
from midnight for both C<$killtime> and C<localtime($from)>, and get
the difference. If C<$from> is omitted, C<time()> is used.

If C<$killtime> is the actual time, the timeout will be 24 hours!

=back

=cut

sub calc_timeout {
    my( $killtime, $from ) = @_;
    my $timeout = 0;
    if ( $killtime =~ /^\+(\d+):([0-5]?[0-9])$/ ) {
        $timeout = 60 * (60 * $1 + $2 );
    } elsif ( $killtime =~ /^((?:[0-1]?[0-9])|(?:2[0-3])):([0-5]?[0-9])$/ ) {
        defined $from or $from = time;
        my $time_min = 60 * $1 + $2;
        my( $now_m, $now_h ) = (localtime $from)[1, 2];
        my $now_min = 60 * $now_h + $now_m;
        my $kill_min = $time_min - $now_min;
        $kill_min += 60 * 24 if $kill_min <= 0;
        $timeout = 60 * $kill_min;
    }
    return $timeout;
}

=head2 time_in_hhmm( $diff )

Create a string telling elapsed time in days, hours, minutes, seconds
from the number of seconds.

=cut

sub time_in_hhmm {
    my $diff = shift;

    # Only show decimal point for diffs < 5 minutes
    my $digits = $diff =~ /\./ ? $diff < 5*60 ? 3 : 0 : 0;
    my $days = int( $diff / (24*60*60) );
    $diff -= 24*60*60 * $days;
    my $hour = int( $diff / (60*60) );
    $diff -= 60*60 * $hour;
    my $mins = int( $diff / 60 );
    $diff -=  60 * $mins;
    $diff = sprintf "%.${digits}f", $diff;

    # GH#78 that sprintf() can round up to 60 secs
    # that can look strange: 18 minutes 60 seconds
    $mins++, $diff -= 60 if $diff >= 60;

    my @parts;
    $days and push @parts, sprintf "%d day%s",   $days, $days == 1 ? "" : 's';
    $hour and push @parts, sprintf "%d hour%s",  $hour, $hour == 1 ? "" : 's';
    $mins and push @parts, sprintf "%d minute%s",$mins, $mins == 1 ? "" : 's';
    $diff && !$days && !$hour and push @parts, "$diff seconds";

    return join " ", @parts;
}

=head2 do_pod2usage( %pod2usage_options )

If L<Pod::Usage> is there then call its C<pod2usage()>.
In the other case, print the general message passed with the C<myusage> key.

=cut

sub do_pod2usage {
    my %p2u_opt = @_;
    eval { require Pod::Usage };
    if ( $@ ) {
        my $usage = $p2u_opt{myusage} || <<__EO_USAGE__;
Usage: $0 [options]
__EO_USAGE__
        print <<EO_MSG;
$usage

Use 'perldoc $0' for the documentation.
Please install 'Pod::Usage' for easy access to the docs.

EO_MSG
        exit( exists $p2u_opt{exitval} ? $p2u_opt{exitval} : 1 );
    } else {
        exists $p2u_opt{myusage} and delete $p2u_opt{myusage};
        Pod::Usage::pod2usage( @_ );
    }
}

=head2 skip_config( $config )

Returns true if this config should be skipped.
C<$config> should be a B<Test::Smoke::BuildCFG::Config> object.

=cut

sub skip_config {
    my( $config ) = @_;

    my $skip = $config->has_arg(qw( -Uuseperlio -Dusethreads )) ||
               $config->has_arg(qw( -Uuseperlio -Duseithreads )) ||
               ( $^O eq 'MSWin32' &&
               (( $config->has_arg(qw( -Duseithreads -Dusemymalloc )) &&
                !$config->has_arg( '-Uuseimpsys' ) ) ||
               ( $config->has_arg(qw( -Dusethreads -Dusemymalloc )) &&
                !$config->has_arg( '-Uuseimpsys' ) ))
               );
    return $skip;
}

=head2 skip_filter( $line )

C<skip_filter()> returns true if the filter rules apply to C<$line>.

=cut

sub skip_filter {
    local( $_ ) = @_;
    # Still to be extended
    return m,^ *$, ||
    m,^\t, ||
    m,^PERL=./perl\s+./runtests choose, ||
    m,^\s+AutoSplitting, ||
    m,^\./miniperl , ||
    m,^\s*autosplit_lib, ||
    m,^\s*PATH=\S+\s+./miniperl, ||
    m,^\s+Making , ||
    m,^make\[[12], ||
    m,make( TEST_ARGS=)? (_test|TESTFILE=|lib/\w+.pm), ||
    m,^make:.*Error\s+\d, ||
    m,^\s+make\s+lib/, ||
    m,^ *cd t &&, ||
    m,^if \(true, ||
    m,^else \\, ||
    m,^fi$, ||
    m,^lib/ftmp-security....File::Temp::_gettemp: Parent directory \((\.|/tmp/)\) is not safe, ||
    m,^File::Temp::_gettemp: Parent directory \((\.|/tmp/)\) is not safe, ||
    m,^ok$, ||
    m,^[-a-zA-Z0-9_/.]+\s*\.*\s*(ok|skipped|skipping test on this platform)$, ||
    m,^(xlc|cc_r) -c , ||
#    m,^\s+$testdir/, ||
    m,^sh mv-if-diff\b, ||
    m,File \S+ not changed, ||
    m,^(not\s+)?ok\s+\d+\s+[-#]\s+(?i:skip\S*[: ]),i ||
    # cygwin
    m,^dllwrap: no export definition file provided, ||
    m,^dllwrap: creating one. but that may not be what you want, ||
    m,^(GNUm|M)akefile:\d+: warning: overriding commands for target `perlmain.o', ||
    m,^(GNUm|M)akefile:\d+: warning: ignoring old commands for target `perlmain.o', ||
    m,^\s+CCCMD\s+=\s+, ||
    # Don't know why BSD's make does this
    m,^Extracting .*with variable substitutions, ||
    # Or these
    m,cc\s+-o\s+perl.*perlmain.o\s+lib/auto/DynaLoader/DynaLoader\.a\s+libperl\.a, ||
    m,^\S+ is up to date, ||
    m,^(   )?### , ||
    # Clean up Win32's output
    m,^(?:\.\.[/\\])?[\w/\\-]+\.*ok$, ||
    m,^(?:\.\.[/\\])?[\w/\\-]+\.*ok\s+\d+(\.\d+)?\s*m?s$, ||
    m,^(?:\.\.[/\\])?[\w/\\-]+\.*ok\,\s+\d+/\d+\s+skipped:, ||
    m,^(?:\.\.[/\\])?[\w/\\-]+\.*skipped[: ], ||
    m,^\t?x?copy , ||
    m,\d+\s+[Ff]ile\(s\) copied, ||
    m,[/\\](?:mini)?perl\.exe ,||
    m,^\t?cd , ||
    m,^\b[ng]make\b, ||
    m,^\s+\d+/\d+ skipped: , ||
    m,^\s+all skipped: , ||
    m,^\s*pl2bat\.bat [\w\\]+, ||
    m,^Making , ||
    m,^Skip , ||
    m,^Creating library file: libExtTest\.dll\.a, ||
    m,^cc: warning 983: ,
}

1;

=head1 COPYRIGHT

(c) 2001-2014, All rights reserved.

  * H. Merijn Brand <h.m.brand@hccnet.nl>
  * Nicholas Clark <nick@unfortu.net>
  * Jarkko Hietaniemi <jhi@iki.fi>
  * Abe Timmerman <abeltje@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See:

  * <http://www.perl.com/perl/misc/Artistic.html>,
  * <http://www.gnu.org/copyleft/gpl.html>

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
