use strict;
use warnings;
use Devel::CheckLib;
use ExtUtils::MakeMaker;

BEGIN {
    local $/;
    open my $fh, '<', 'UUID.pm' or die $!;
    my $content = <$fh>;
    $main::DEV_VERSION = $content =~ /VERSION\s+=\s+\S+_/;

    $main::USE_DEBUG = 0;
    @ARGV = map {
        ( /^UUID_DEBUG=(.+)/ and (($main::USE_DEBUG=$1) or 1) ) ? () : $_
    } @ARGV;
}

use constant DEBUG => $ENV{UUID_DEBUG}
    || ( $main::USE_DEBUG ? 1 : 0 )
    || ( $ENV{AUTOMATED_TESTING} && $main::DEV_VERSION )
    || 0
;


# buffering will ruin your day!
select STDERR; $|=1;
select STDOUT; $|=1;


# ARRRRR!.. there are _at_least_ 3 different UUID interfaces:
# Free/NetBSD/MacOSX, Windows, and e2fsprogs.
# ... this is gonna suck!
warn "#\n" if DEBUG;


my @hfiles;
for my $try (qw{ uuid/uuid.h uuid.h rpc.h }) {
    warn "# ===> Checking for #include <${try}>\n" if DEBUG;
    eval { assert_lib(
        #lib      => $link_lib,  <-- dont link yet
        header   => $try,
        debug    => DEBUG,
    )};
    unless ( $@ ) {
        push @hfiles, $try;
        warn "# ===> Found!\n" if DEBUG;
    }
    warn "#\n" if DEBUG;
}

bail('No headers found.') unless @hfiles;


my $header;
my $defs = [];
my $libs = [];

HEADER: while ( $header = shift @hfiles ) {
    for my $try_lib (qw{ rpcrt4 uuid c }) {
        try_rpc(  $header, $try_lib ) and last HEADER;
        try_e2fs( $header, $try_lib ) and last HEADER;
        try_win(  $header, $try_lib ) and last HEADER;
    }
}

bail('No interface found.') unless $header;


sub try_rpc {
    my ( $hdr, $tlib ) = @_;
    warn "# ===> Checking for RPC interface in $hdr with -l$tlib\n" if DEBUG;
    eval { assert_lib(
        lib      => $tlib,
        header   => $hdr,
        debug    => DEBUG,
        function => qq/
            char *str,buff[37];
            uuid_t u1,u2;
            int32_t r,s;
            str=buff;
            uuid_create(&u1,&s);
            uuid_create_nil(&u2,&s);
            uuid_from_string(str,&u1,&s);
            uuid_to_string(&u1,&str,&s);
            r = uuid_compare(&u1,&u2,&s);
            r = uuid_equal(&u1,&u2,&s);
            r = uuid_is_nil(&u1,&s);
            return 0;
        /,
    )};
    if ($@) { my $L = length $@; warn "# ===> Err($L): \"$@\"\n" if DEBUG; return 0 }
    push @$defs, '-DPERL__UUID__RPC_INT';
    push @$libs, "-l$tlib";
    warn "# ===> Found!\n" if DEBUG;
    warn "#\n" if DEBUG;
    return 1;
}

sub try_e2fs {
    my ( $hdr, $tlib ) = @_;
    warn "# ===> Checking for e2fs interface in $hdr with -l$tlib\n" if DEBUG;
    eval { assert_lib(
        lib      => $tlib,
        header   => $hdr,
        debug    => DEBUG,
        function => qq/
            int i;
            char s[37];
            uuid_t u,uu;
            uuid_generate(u);
            uuid_generate_random(u);
            uuid_generate_time(u);
            uuid_unparse(u,s);
            uuid_parse(s,u);
            uuid_clear(u);
            uuid_copy(uu,u);
            i = uuid_compare(u,uu);
            i = uuid_is_null(u);
            return 0;
        /,
    )};
    if ($@) { my $L = length $@; warn "# ===> Err($L): \"$@\"\n" if DEBUG; return 0 }
    push @$defs, '-DPERL__UUID__E2FS_INT';
    push @$libs, "-l$tlib";
    warn "# ===> Found!\n" if DEBUG;
    warn "#\n" if DEBUG;
    return 1;
}

sub try_win {
    my ( $hdr, $tlib ) = @_;
    warn "# ===> Checking for Win interface in $hdr with -l$tlib\n" if DEBUG;
    eval { assert_lib(
        lib      => $tlib,
        header   => [ $hdr, 'rpcdce.h' ],
        debug    => DEBUG,
        function => qq/
            int i;
            UUID u,uu;
            RPC_CSTR cs;
            RPC_STATUS st;
            unsigned char *s;
            i  = UuidCompare(&u,&uu,&st);
            st = UuidCreate(&u);
            st = UuidCreateNil(&uu);
            st = UuidCreateSequential(&uu);
            i  = UuidEqual(&u,&uu,&st);
            st = UuidFromString(cs,&u);
            i  = UuidIsNil(&u,&st);
            st = UuidToString(&u,&s);
            return 0;
        /,
    )};
    if ($@) { my $L = length $@; warn "# ===> Err($L): \"$@\"\n" if DEBUG; return 0 }
    push @$defs, '-DPERL__UUID__WIN_INT';
    push @$libs, "-l$tlib";
    warn "# ===> Found!\n" if DEBUG;
    warn "#\n" if DEBUG;
    return 1;
}

sub get_struct_size {
    my ( $hdrs, $libs ) = @_;
    warn "# ===> Checking binary size\n" if DEBUG;
    ( my $lib = $libs->[0] ) =~ s/-l//;
    check_lib(
        lib      => $lib,
        header   => $hdrs,
        debug    => DEBUG,
        function => qq/
            return sizeof(uuid_t);
        /,
    );
    my $rv = $? >> 8;
    warn "# ===> $rv\n" if DEBUG;
    warn "#\n" if DEBUG;
    return $rv;
}

my $size = get_struct_size( $header, $libs )
    || bail( "Impossible struct size." );
push @$defs, "-DPERL__UUID__STRUCT_SZ=$size";


($header = '-DPERL__UUID__'. uc $header ) =~ y{/.}{__};
push @$defs, $header;


warn "# ===> Writing Makefile\n" if DEBUG;

WriteMakefile1(
    'NAME'               => 'UUID',
    'AUTHOR'             => 'Rick Myers <jrm@cpan.org>',
    'VERSION_FROM'       => 'UUID.pm',
    'ABSTRACT_FROM'      => 'UUID.pm',
    'LICENSE'            => 'artistic_2',
    'MIN_PERL_VERSION'   => '5.005',
    'LIBS'               => $libs,
    'DEFINE'             => join(' ', @$defs), #$header,
    'INC'                => '',
    'PREREQ_PM'          => {},
    'CONFIGURE_REQUIRES' => {
        'Devel::CheckLib' => '1.02',
    },
    'TEST_REQUIRES' => {
        'Test::More' => 0,
    },
    #'META_MERGE'       => {
    #    'resources' => {
    #        #repository => 'URL to repository here',
    #    },
    #},
    #BUILD_REQUIRES => {
    #},
);

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
    delete $params{TEST_REQUIRES} if $eumm_version < 6.64;
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

sub bail {
    my $msg = shift;
    # need some explanatory text here for missing system libs
    warn join '', "
#######################################################################
#
# Bailing out. Can't continue.
#
#   ** $msg
", ( DEBUG ? '' : "#
# It's likely the UUID prerequisite library isn't installed.
#
# On some platforms you can use your package manager to install these.
# In particular, the uuid-dev or uuid-devel packages on Linux.
#
# More information about this failure can be found with the UUID_DEBUG
# flag.
# 
#   perl Makefile.PL UUID_DEBUG=1
" ), "# 
#######################################################################
";
    exit 0;   # used in Devel::CheckLib::check_lib_or_exit()
    exit 255; # same as die() which is suggested in CPAN::Authors FAQ
}

# stay calm. don't blink.
# this is just for me :-)
sub MY::postamble {
    return <<EOP;
readme:
	pod2text UUID.pm README
	perl -i -pe's{\\*(\\S+)\\*}{\\1}g' README
EOP
}

