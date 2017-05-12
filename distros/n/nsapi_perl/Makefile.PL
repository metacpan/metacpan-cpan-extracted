#!perl -w

##-- Makefile.PL for nsapi_perl/Netscape::Server

##----------------------------------------------------------------------
##-- Library requirements

BEGIN { $^W = 1 }
BEGIN { require 5.004 }
use strict;
use ExtUtils::MakeMaker;
use ExtUtils::Embed;
use Config;
use File::Find;



##----------------------------------------------------------------------
##-- Introductory remarks and base questions

print <<EOM;

Welcome to nsapi_perl.  This program will ask some questions and then
generate Makefiles that will be used to compile the nsapi_perl server
plug in and the Netscape:: perl extensions.

Some questions may have default answers.  If a question has a default
answer, it will be presented between square brackets [ ... ] when the
question is asked.  Just hit <return> to accept the default answer.

Proceed? [y]
EOM
{
    my $default_answer = 'y';
    my $answer = <STDIN>;
    chomp $answer;
    $answer = ($answer or $default_answer);
    $answer =~ /^y/i or exit;
}


##-- get Netscape Server root directory
my $ns_server_root;
print <<EOM;

Enter your Netscape server's root directory:
EOM
{
    $ns_server_root = <STDIN>;
    chomp $ns_server_root;
    $ns_server_root =~ s#(\/|\\)+$##;
    $ns_server_root =~ s#\\#\/#;
}


##-- Find possible include directories
my $ns_inc_dir;
my $possible_ns_inc_dir = '';
find(sub { $possible_ns_inc_dir = $File::Find::dir if $_ eq 'netsite.h' },
	$ns_server_root);
print <<EOM;

Enter the directory where the NSAPI header files can
be found: [$possible_ns_inc_dir]
EOM
{
    my($default_answer) = $possible_ns_inc_dir;
    my $answer = <STDIN>;
    chomp $answer;
    $ns_inc_dir = ($answer or $default_answer);
}


##-- get plugin installation directory
my $ns_inst_dir;
print <<EOM;

Enter where you want to install the Netscape plugin and the
nsapi_perl_init.pl start-up script:
[$ns_server_root/lib]
EOM
{
    my $default_answer = "$ns_server_root/lib";
    my $dir = <STDIN>;
    chomp $dir;
    $dir = ($dir or $default_answer);
    $dir =~ s#(\/|\\)+$##;
    $dir =~ s#\\#\/#;
    $ns_inst_dir     = $dir;
}


##-- get OS type
my $os = $^O;
my $osvers = $Config{osvers};
$osvers =~ s/^\s*(\d+\.\d+).*/$1/;  # drop sub-sub-version: 2.5.1 -> 2.5


##-- enable tracing?
my $enable_np_tracing = 0;
print <<EOM;

Enable nsapi_perl tracing? [y]
EOM
{
    my $default_answer = 'y';
    my $answer = <STDIN>;
    chomp $answer;
    $answer = ($answer or $default_answer);
    $enable_np_tracing = 1 if $answer =~ /^y/i;
}


##-- does this look like a threaded server?
my $threaded_server = 0;
my $have_critical = 0;
if( -e "$ns_inc_dir/base/crit.h" ) {
    $threaded_server = 1;
    $have_critical = 1;
}


##-- create build choices
my $use_threads = 0;
my $use_critical = 0;
my @choices;
my $i = 0;

if($threaded_server) {
##XXX kind of clunky... what about FAKE_THREADS? should it matter?

##XXX commented out for the 0.2x series
#    if(defined($Config{'usethreads'})
#       and $Config{'usethreads'} eq 'define') {
#	$choices[$i++] = "Perl threads";
#    }

    $choices[$i++] = "Critical sections";
    $choices[$i++] = "Use no syncronization";

    print <<EOM;

If you are running your Netscape Server in a single process/multithread mode
it is recommended that you choose one of the following syncronization methods
for running perl scripts: [1]
EOM
    $i = 0;
    foreach $i (0 .. $#choices) {	
	print "  " , $i+1 , ". " . $choices[$i] . "?\n";
    }
    {
	my $default_answer = '1';
	my $answer = <STDIN>;
	chomp $answer;
	$answer = ($answer or $default_answer);
	$answer--;
	if($choices[$answer] =~ /threads/i) {
	    $use_threads = 1;
	} elsif($choices[$answer] =~ /critical/i) {
	    $use_critical = 1;
	} elsif($choices[$answer] =~ /no syncronization/i) {
	    warn "\nWarning: you will not be able run your server safely in\n";
	    warn "in multi-threaded mode.\n\n";
	}
    }
}


##-- See if they're using libperl.a or libperl.so
my $uses_static_libperl = 1;
if ($Config{useshrplib} ne 'false') {
    $uses_static_libperl =  0;
}




##----------------------------------------------------------------------
##-- Now we should have assembled enough information to proceed, so
##-- construct the complete set of compile and link options.


##-- Initial declarations common to all platforms
my %ns_compile = (
		  flags => '',
		  defines => " -DNET_SSL -DMCC_HTTPD",
		  inc_dirs => " -I$ns_inc_dir",
		  );
my %ns_link = (
	       flags => '',
	       lib_dirs => '',
	       libs => '',
	       );


##-- Tracing
if ($enable_np_tracing) {
    $ns_compile{defines} .=  " -DPERL_TRACE";
}


##-- Critical sections
if($have_critical) {
    $ns_compile{defines} .= " -DNP_HAVE_CRITICAL";
}


##-- Threadedness
if($use_threads) {
    $ns_compile{defines} .= " -DNP_USE_THREADS";
} elsif($use_critical) {
    $ns_compile{defines} .= " -DNP_USE_CRITICAL";
}


##-- Operating-system specific compile options
if($os eq 'MSWin32') {
    ##-- This seems to be sufficient
    $ns_compile{defines} .= " -DWIN32 -DXP_WIN32";
    
} else {
    
    $ns_compile{defines} .= " -DNP_BOOTSTRAP -DXP_UNIX";
    ##-- Each Unix flavour gets its defines added here
    if ($os eq 'solaris') {
	if ($threaded_server) {
	    $ns_compile{defines} .= " -D_REENTRANT";
	}
	$ns_compile{defines} .= " -DSOLARIS -DSPAPI20";
	$ns_compile{flags} .= " -Wall";
    } else {
	##-- Unverified operating systems
	if ($os eq 'irix') {
	    $ns_compile{defines} .= " -DIRIX -D_SGI_MP_SOURCE";
	    $ns_compile{flags} .= "-fullwarn";
	} elsif ($os eq 'hpux') {
	    $ns_compile{defines} .= " -DHPUX -D_HPUX_SOURCE";
	    $ns_compile{flags} .= "-Aa +DA1.0 +z -c";
	}
	print <<EOM;
	
Warning: build of nsapi_perl on $os is untested.  If successful,
please let the nsapi_perl mailing list (nsapi_perl\@samurai.com)
know.

(You made need to fiddle with the Makefile to get nsapi_perl to work.
Please be patient.)
EOM
        ;
    }
}

##-- Operating system-specific linking flags
if ($os eq 'MSWin32') {
    $ns_link{flags} = "$ns_server_root/nsapi/examples/libhttpd.lib";
} else {
    $ns_link{flags} .= "$Config{archlibexp}/auto/DynaLoader/DynaLoader.a";
    $ns_link{lib_dirs} .= " -L$Config{archlibexp}/CORE";
    $ns_link{libs} .= " -lperl  $Config{libs}";
}


##-----------------------------------------------------------------------------
##-- Other stuff
my $nsapi_install_target = <<EOT;
nsapi_install :: all
	\$(CP) \$(INST_ARCHAUTODIR)/\$(BASEEXT).\$(DLEXT) $ns_inst_dir/.
EOT
    ;
unless ( -e "$ns_inst_dir/nsapi_perl_init.pl") {
    $nsapi_install_target .= <<EOT
	\$(CP) pl/nsapi_perl_init.pl $ns_inst_dir/.
EOT
    ;
}

##----------------------------------------------------------------------
##-- Closing remarks
print <<EOM;
See the INSTALL file for further instructions.  Please contact the
nsapi_perl mailing list (nsapi_perl\@samurai.com) in the event of
success/failure.

Good Luck!
EOM
    ;

##----------------------------------------------------------------------
##-- Create the Makefile.PLs and xsinit code

##-- Create xsinit.c
unless (-e "nsapi/xsinit.c") {
    print "Makefile.PL: creating nsapi/xsinit.c\n";
    xsinit('nsapi/xsinit.c');
}

##-- Create the Netscape::Server Makefile.PL
print "Makefile.PL: creating Netscape/Makefile.PL\n";
open(OUTPUT, '>Netscape/Makefile.PL') or
    die "Makefile.PL: can't open Netscape/Makefile.PL: $!\n";
print OUTPUT <<"EOF";
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME => 'Netscape::Server',
    INC => '-I$ns_inc_dir -I../nsapi',
    DEFINE => '$ns_compile{defines}',
    OBJECT => 'Server.o ../nsapi/nsapi_perl_util.o',
    VERSION_FROM => 'Server.pm',
    PMLIBDIRS => [qw(Server eg)],
EOF
	;

##-- MSWin32 requires the extra linker flags
if($os eq 'MSWin32') {
	print OUTPUT <<"EOF";
    dynamic_lib => { OTHERLDFLAGS => '$ns_link{flags}', },
EOF
    ;
}

##-- finsh off Makefile.PL
print OUTPUT <<"EOF";
);
EOF
    ;

close OUTPUT;

##-- Create the nsapi_perl Makefile.PL
print "Makefile.PL: creating nsapi/Makefile.PL\n";
open(OUTPUT, '>nsapi/Makefile.PL') or
    die "Makefile.PL: can't open nsapi/Makefile.PL: $!\n";
print OUTPUT <<"EOF";
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME => 'nsapi_perl',
    INC => '$ns_compile{inc_dirs} -I.',
    DEFINE => '$ns_compile{defines}',
    OBJECT => '\$(O_FILES)',
    VERSION_FROM => '../Netscape/Server.pm',
    dynamic_lib => { OTHERLDFLAGS => '$ns_link{flags}', },
EOF
    ;

##-- MSWin32 can do without these linker flags; causes a ba-zillion warnings
##-- from MakeMaker.
if($os ne 'MSWin32') {
	print OUTPUT <<"EOF";
    LIBS => [ '$ns_link{lib_dirs} $ns_link{libs}' ],
EOF
	;
}

##-- finish off nsapi_perl Makefile.PL
print OUTPUT <<"EOF";
);
EOF
	;

##-- override dlsyms section on Win32
if($os eq 'MSWin32') {
	print OUTPUT <<'EOF';

# override dlsyms section in Makefile
sub MY::dlsyms
{
	"
\$(EXPORT_LIST):
	\$(TOUCH) \$(EXPORT_LIST)
";
}
EOF
	;
}

close OUTPUT;

##----------------------------------------------------------------------
##-- Engage
WriteMakefile(
	      NAME => 'nsapi_perl',
	      NEEDS_LINKING => 1,
	      DIR => [ 'nsapi', 'Netscape' ],
	      VERSION_FROM => 'Netscape/Server.pm',
	      clean => { FILES=> "nsapi/*\$(OBJ_EXT) nsapi/xsinit.c" },
);


##----------------------------------------------------------------------
##-- Done?
exit;

package MY;
sub install {
    my $inherited = shift->SUPER::install(@_);
    my(@lines) = split(m|$/|o, $inherited);
    foreach my $line (@lines) {
	if ($line =~ /^install\s+:/) {
	    $line .= ' nsapi_install';
	}
    }
    push(@lines, $nsapi_install_target);
    return join("$/", @lines);
}
