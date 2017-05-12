use ExtUtils::MakeMaker;
use strict;
use FindBin;
use 5.005;

BEGIN {
    unless (eval {require mod_perl}) {
        die "Please install mod_perl: 1.25 < version < 1.99\n($@)";
    }
    my $file = $INC{"mod_perl.pm"};
    my $have = "Found $file: version $mod_perl::VERSION";
    if ($mod_perl::VERSION < 1.2402) {
        die "$have\nPlease upgrade mod_perl to 1.24_02 or greater";
    }
    elsif ($mod_perl::VERSION > 1.98) {
        die "$have\nmod_perl 1.x ( < 1.99) is required";
    }
}

use File::Path qw(mkpath);
use lib qw(Apache-Test/lib);

use constant MIN_A_T_VERSION => 1.13;

use constant HAS_APACHE_TEST => eval {
    require Apache::Test &&
        $Apache::Test::VERSION >= MIN_A_T_VERSION;
};

use constant WIN32 => ($^O eq "MSWin32") || $ENV{WIN32_TEST};
if (WIN32) {
    win32_setup() unless ($ENV{APACHE} || grep /^-httpd$/, @ARGV);
}

# enable 'make test|clean'
if (HAS_APACHE_TEST) {
    require Apache::TestMM;
    Apache::TestMM->import(qw(test clean));
}

my $conf_data = join '', <DATA>;
$conf_data =~ s|(blib/arch)|$FindBin::Bin/$1|;

if (HAS_APACHE_TEST) {
    # accept the configs from command line
    Apache::TestMM::filter_args();
    Apache::TestMM::generate_script('t/TEST');
}
else {
    print "\nskipping test setup... which requires Apache::Test " .
    MIN_A_T_VERSION . " or higher\n";
    *MY::test = sub {
        return <<'EOF';
test : pure_all
	@echo \*** This test suite requires Apache::Test available
	@echo \*** available from CPAN

EOF
    };
}

# prerequisites
my %require = (
    "Apache::Test" => MIN_A_T_VERSION,
);

my $myVERSION = MM->parse_version('Request/Request.pm');
$myVERSION =~ s/(\d\d)(\d\d)$/$1_$2/;
my $lib;
check_compat();

if (WIN32) {
    require Cwd;
    my $cwd = Cwd::cwd();
    $cwd =~ s#\\#/#g;

    my $root = "$cwd/blib/arch/auto";
    mkpath $root, 1, 0755 unless -d $root;
    mkpath "$root/libapreq", 1, 0755 unless -d "$root/libapreq";
    $lib = "$root/libapreq/libapreq.lib";

    open (FILE, ">>$lib")
        or die "Cannot touch $lib: $!\n";
    close FILE;

    require Apache::MyConfig;
    $ENV{APREQ_LIB} = "$root/libapreq";
    $ENV{AP_INC} = $Apache::MyConfig::Setup{APACHE_INC};
    $ENV{MP_INC} = $Apache::MyConfig::Setup{MODPERL_INC};
    $ENV{AP_LIB} = $Apache::MyConfig::Setup{APACHE_LIB};
    $ENV{MP_LIB} = $Apache::MyConfig::Setup{MODPERL_LIB};

    unless (-f "$ENV{MP_LIB}/mod_perl.so") {
        die "Cannot find mod_perl.so in $ENV{MP_LIB}. " .
            "Please build mod_perl first";
    }

    unless (-f "$ENV{AP_LIB}/ApacheCore.lib") {
        die "Cannot find ApacheCore.lib in $ENV{AP_LIB}. " .
            "Please build apache first.";
    }
}

WriteMakefile(
    NAME      => 'libapreq',
    VERSION   => $myVERSION,
    DIR       => [qw(c Request Cookie)],
    PREREQ_PM => \%require,
    clean     => {
        FILES => "@{ clean_files() }",
    },
);

sub clean_files {
    return [qw( t/TEST )];
}

if (WIN32 and -e $lib) {
    unlink $lib or die "Cannot unlink $lib: $!\n";
}

sub check_compat {
    eval { require Apache::Request };
    return if $@;

    my $v = $Apache::Request::VERSION;
    return if $v >= 0.2000;

    print "libapreq is not compatible with  Apache::Request version $v\n";
    my $ans = prompt("Continue?", "n");
    if ($ans =~ /^n/i) {
	print "Aborting.\n";
	exit;
    }
}

sub MY::pasthru {
    my $self = shift;
    chomp(my $str = $self->MM::pasthru);
    join $/, "$str\\", "\t".'DEFINE="$(DEFINE)"', "";
}

sub MY::postamble {
    return <<'EOF';

cvs_tag :
	cvs tag v$(VERSION_SYM) .
	@echo update the VERSION in Apache/Request.pm now 

EOF
}

sub win32_setup {
    eval{ require Win32 };
    die "The libwin32 package is needed" if $@;

    require File::Spec;
    my $apache;
    my $exe = 'Apache.exe';

  SEARCH: {
        my $candidate;
        for (File::Spec->path) {
            $candidate = File::Spec->catfile($_, $exe);
            if (-e $candidate and check_win32_apache($candidate)) {
                $apache = $candidate;
                last SEARCH;
            }
        }

        my @drives = drives();
        last SEARCH unless (@drives > 0);
        for my $drive (@drives) {
            for ('Apache', 'Program Files/Apache',
                 'Program Files/Apache Group/Apache') {
                $candidate = File::Spec->catfile($drive, $_, $exe);
                if (-e $candidate and check_win32_apache($candidate)) {
                    $apache = $candidate;
                    last SEARCH;
                }
            }
        }
    }

    unless (-e $apache) {
        $apache = prompt("Please supply the full path to Apache.exe:",
                         $apache);
    }

    if (-d $apache) {
        $apache = File::Spec->catfile($apache, $exe);
    }
    die "Can't find Apache.exe!" 
        unless (-e $apache and check_win32_apache($apache));

    $apache = Win32::GetShortPathName($apache);
    $apache =~ s!\\!/!g;
    push @ARGV, '-httpd', $apache;
    print qq{Using "$apache".\n};
}

sub check_win32_apache {
    my $apache = shift;
    my $vers = qx{"$apache" -v};
    return ($vers =~ m!Apache/1.3!) ? 1 : 0;
}

sub drives {
    my @drives = ();
    eval { require Win32API::File };
    return map {"$_:\\"} ('C' .. 'Z') if $@;

    my @r = Win32API::File::getLogicalDrives();
    return unless @r > 0;
    for (@r) {
        my $t = Win32API::File::GetDriveType($_);
        push @drives, $_ if ($t == 3 or $t == 4);
    }
    return @drives > 0 ? @drives : undef;
}

__DATA__
<Perl>
   unshift @INC, "blib/arch";
</Perl>
PerlModule Apache::PerlRun
PerlModule Apache::Request
PerlModule Apache::Cookie

<FilesMatch "\.pl">
    SetHandler perl-script
    PerlHandler Apache::PerlRun
    Options +ExecCGI
</FilesMatch>











