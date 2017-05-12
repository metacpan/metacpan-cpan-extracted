require 5.006;

BEGIN {
    die "'forks' is currently not supported on this system (Win32).\n"
     if ($^O =~ m#Win32# or $ENV{THIS_IS_WIN32});
} #BEGIN

use strict;
use ExtUtils::MakeMaker 6.10;
eval "use Devel::Required";

# Taken from ExtUtils::MakeMaker 6.98 (Michael Schwern) so that 
# the prompt() function can be emulated for older versions of ExtUtils::MakeMaker.
*prompt = sub {
    my($mess, $def) = @_;
    die("prompt function called without an argument")
        unless defined $mess;

    my $isa_tty = -t STDIN && (-t STDOUT || !(-f STDOUT || -c STDOUT)) ;

    my $dispdef = defined $def ? "[$def] " : " ";
    $def = defined $def ? $def : "";

    local $|=1;
    local $\;
    print "$mess $dispdef";

    my $ans;
    if ($ENV{PERL_MM_USE_DEFAULT} || (!$isa_tty && eof STDIN)) {
        print "$def\n";
    }
    else {
        $ans = <STDIN>;
        if( defined $ans ) {
            $ans =~ s{\015?\012$}{};
        }
        else { # user hit ctrl-D
            print "\n";
        }
    }

    return (!defined $ans || $ans eq '') ? $def : $ans;
} unless defined &prompt;

### Perl version-specific code modifications and modified requirements ###
my $old = 'forks.xs';
my $new = "$old.new";
my @from = (
    qq{#    PROTOTYPE: \\[\$\@\%]\n},
    qq{#    PROTOTYPE: \\[\$\@\%];\\[\$\@\%]\n},
    qq{#    PROTOTYPE: \\[\$\@\%]\$;\\[\$\@\%]\n}
);
my @to = (
    qq{    PROTOTYPE: \\[\$\@\%]\n},
    qq{    PROTOTYPE: \\[\$\@\%];\\[\$\@\%]\n},
    qq{    PROTOTYPE: \\[\$\@\%]\$;\\[\$\@\%]\n}
);

my @extra_prereq;
if ($] < 5.008) { # no complex prototypes before 5.8.0, we need to filter also
    my @from_tmp = @from;
    @from = @to;
    @to = @from_tmp;
    push @extra_prereq,qw(Filter::Util::Call 0);
}

warn "Fixing prototypes in $old\n";
open my $in,'<',$old   or die "Could not open $old: $!\n";
open my $out,'>',$new  or die "Could not create $new: $!\n";

while (<$in>) {
    my $filtered = 0;
    for (my $i = 0; $i < scalar @from; $i++) {
        if ($_ eq $from[$i]) {
            print $out $to[$i];
            $filtered = 1;
            last;
        }
    }
    print $out $_ unless $filtered;
}

close $out        or die "Could not close $new: $!\n";
close $in         or die "Could not close $old: $!\n";
chmod 0644, $old  or die "Could not change permissions on $old\n";
unlink $old       or die "Could not remove $old\n";
rename $new,$old  or die "Could not rename $new to $old\n";
chmod 0444, $old  or die "Could not change permissions on $old\n";

### Determine whether ithreads simulated feature may be used ###
use Config ();
my $simulate_useithreads = 0;
unless ($Config::Config{useithreads}) {
    if ($ENV{FORKS_SIMULATE_USEITHREADS}
        || prompt("\nIt appears your perl was not built with native ithreads.\n"
               ."\nWould you like to create references to forks, such that\n"
               ."using 'use threads' and 'use threads::shared' will quietly\n"
               ."load forks and forks::shared?", "no") =~ /^y(?:es)?$/i) {
        $simulate_useithreads = 1;
        print "\n";
        print "NOTE: Be sure to 'make install UNINST=1' when installing\n"
           ."      module to insure that old threads.pm modules do not\n"
           ."      shadow the new forks modules.\n";
        print "\n";
    } elsif (exists $ENV{FORKS_SIMULATE_USEITHREADS}) {
        $simulate_useithreads = $ENV{FORKS_SIMULATE_USEITHREADS} ? 1 : 0;
    }
}

if ($simulate_useithreads) {
#    eval {
#package MY; # so that "SUPER" works right
#sub all_target {
#    my $inherited = shift->SUPER::all_target(@_);
#    $inherited .= 
#        qq{\t-(\$(TEST_F) blib/lib/threads.pm && \$(RM_F) blib/lib/threads.pm) || \$(NOOP)\n}
#        .qq{\t-(\$(TEST_F) blib/lib/threads/shared.pm && \$(RM_F) blib/lib/threads/shared.pm) || \$(NOOP)\n}
#        .qq{\t-\$(CP) blib/lib/forks.pm blib/lib/threads.pm\n}
#        .qq{\t-\$(CP) blib/lib/forks/shared.pm blib/lib/threads/shared.pm\n}
#        .qq{\t-\$(TEST_F) blib/lib/threads.pm && perl -pi -e 's\/(\\\$\$forks::threads_override =\\s*) 0;\/\$\$1 1;\/' blib/lib/threads.pm || \$(NOOP)\n};
#    $inherited;
#};
#    };
    
#    eval {
require ExtUtils::MM_Any; #kludge: MY::all_target doesn't work (as of MakeMaker 6.17)
require ExtUtils::MM_Unix;
*ExtUtils::MM_Any::__all_target = \&ExtUtils::MM_Any::all_target;
*ExtUtils::MM_Unix::__all_target = \&ExtUtils::MM_Unix::all_target;
*ExtUtils::MM_Any::all_target = *ExtUtils::MM_Unix::all_target = sub {
    my $inherited = shift->__all_target(@_);
    $inherited .= 
        qq{\t-(\$(TEST_F) blib/lib/threads.pm && \$(RM_F) blib/lib/threads.pm) || \$(NOOP)\n}
        .qq{\t-(\$(TEST_F) blib/lib/threads/shared.pm && \$(RM_F) blib/lib/threads/shared.pm) || \$(NOOP)\n}
        .qq{\t-\$(CP) blib/lib/forks.pm blib/lib/threads.pm\n}
        .qq{\t-\$(CP) blib/lib/forks/shared.pm blib/lib/threads/shared.pm\n}
        .qq{\t-\$(TEST_F) blib/lib/threads.pm && perl -pi -e 's\/(\\\$\$forks::threads_override =\\s*) 0;\/\$\$1 1;\/' blib/lib/threads.pm || \$(NOOP)\n};
    $inherited;
#};
    };
}

my $storable_min_version = 0;
if (eval{require Storable; $Storable::VERSION < 2.05}) {
    if (prompt("\nYou have Storable version $Storable::VERSION, but version\n"
               ."2.05 or later is required to be able to store CODE refs in\n"
               ."forks::shared shared variables.  Do you wish to install a more\n"
               ."recent version of Storable at this time?", "no") =~ /^y(?:es)?$/i) {
        $storable_min_version = 2.05;
        print "\nStorable 2.05 will be added to list of install requirements.\n";
        print "\n";
    }
}

# Address RT#94542
if (($] >= 5.019002 && $] <= 5.019010) && eval{require Storable; $Storable::VERSION < 2.49}) {
    $storable_min_version = 2.49;
}

### Standard MakeMaker Makefile.PL directives ###
package main;
WriteMakefile (
 NAME       => "forks",
 AUTHOR     => 'Eric Rybski (rybskej@yahoo.com)',
 ABSTRACT   => 'forks - emulate threads with fork',
 LICENSE    => 'perl',
 VERSION_FROM   => 'lib/forks.pm',

 PREREQ_PM  => {@extra_prereq,qw(
            Acme::Damn          0
            Attribute::Handlers 0
            Devel::Symdump      0
            List::MoreUtils     0.15
            File::Spec          0
            if                  0
            IO::Socket          1.18
            Scalar::Util        1.11
            Storable            ), $storable_min_version, qw(
            Sys::SigAction      0.11
            Test::More          0
            Time::HiRes         0
                )},
(MM->can('signature_target') ? (SIGN => 1) : ()),
);
