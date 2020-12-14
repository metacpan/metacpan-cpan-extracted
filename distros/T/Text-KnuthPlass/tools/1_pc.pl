#!/usr/bin/perl
# run perlcritic test suite
#   needless to say, 'perlcritic' command must be installed
# roughly equivalent to pc.bat
# author: Phil M Perry

use strict;
use warnings;

our $VERSION = '1.04'; # VERSION
my $LAST_UPDATE = '1.03'; # manually update whenever code is changed

# command line:
# -5  run perlcritic -5 .  (should be clean)
# -5x                      exclude certain common errors (none at this time)
# -4  run perlcritic -4 .  should get a number of common errors
# -4x                      exclude certain common errors  DEFAULT
# -3  run perlcritic -3 .  should get a number of errors
# -3x                      exclude certain common errors
# -2  run perlcritic -2 .  should get more errors
# -2x                      exclude certain common errors
# -1  run perlcritic -1 .  should get even more errors
# -1x                      exclude certain common errors
# 
# levels 1,2,3 are only for the morbidly curious! 
#   (although some warnings look like they should be addressed)

# output <source name> OK is always ignored
my @ignore_list = (
  # should not ignore any level 5 warnings
     "Use IO::Interactive::is_interactive",
                              # not a core module!

  # common level 4 warnings to ignore
# removed 'no warnings' in 3.021. remove next line 3.022 or later
#    "Code before warnings",  # due to use of "no warnings" pragma 
# removed 'no warnings' in 3.021. remove next line 3.022 or later
#    "Warnings disabled at",  # due to use of "no warnings" pragma
     "Close filehandles as soon as possible", 
                              # it thinks there is no "close" on an open 
			      # filehandle, due to either too many lines for 
			      # it to buffer, or use of other code to close
     "Always unpack ",        # Always unpack @_ first at line
                              # not using @_ or $_[n] directly is good practice,
                              # but it doesn't seem to recognize legitimate uses
#  'default' in Builder.pm would have to be deprecated, and changed to defaultB
#      Perl 'default' (CORE::) not used
#  'close' in Content-Lite.pm would have to be deprecated, and changed to 
#      closePath. Perl 'close' (CORE::) not used in Content-Lite.pm
#  'print' in Lite.pm would have to be deprecated, and changed to 
#      printB. Perl 'print' (CORE::) not used in Lite.pm
#  'link' in NamedDestination.pm would have to be deprecated, and changed to 
#      linkPage. Perl 'link' (CORE::) not used in NamedDestination.pm
#  'next', 'last' in Outline.pm is undocumented internal routine, can rename
#  'open' in Outline.pm would have to be deprecated, and changed to openB.
#      Perl 'open' (CORE::) not used
#  'open' in File.pm would have to be deprecated, and changed to openB
#      Perl 'open' (CORE::) is ALSO used
     "Subroutine name is a homonym for builtin function", 
                              # e.g., we define "open" when there is already a 
			      # system (CORE::) open (ambiguous unless CORE:: 
			      # added)      TBD consider removing
     "Symbols are exported by default", 
                              # it doesn't like something about our use of 
			      # @EXPORT and @EXPORT_OK
# 4 'use constant' for conversion factors in Boxes.pl, 3 in RMtutorial.pl
     "Pragma \"constant\" used at", # will have to investigate why "use constant"
                                    # is flagged. TBD
     "Multiple \"package\" declarations", # might need to break up file

  # common level 3 warnings to ignore for now
     '"die" used instead of "croak"',  # 
     '"warn" used instead of "carp"',  # 
     'Regular expression without "/x" flag',  # 
     "Backtick operator used",  # 
     "high complexity score",  #
     "Cascading if-elsif chain",  #
     "Hard tabs used at",  #
     '"local" variable not initialized',  #
	          );

# Note that level 4 includes any level 5 errors, etc.
# 
my $level;
my @exclude;  # leave empty unless "x" suffix

# one command line arg allowed (-4x is default)
if      (scalar @ARGV == 0) {
    $level = '-4';
    @exclude = @ignore_list;
} elsif (scalar @ARGV == 1) {
    if      ($ARGV[0] eq '-5') {
        $level = '-5';
    } elsif ($ARGV[0] eq '-5x') {
        $level = '-5';
        @exclude = @ignore_list;
    } elsif ($ARGV[0] eq '-4') {
        $level = '-4';
    } elsif ($ARGV[0] eq '-4x') {
	# default
        $level = '-4';
        @exclude = @ignore_list;
    } elsif ($ARGV[0] eq '-3') {
        $level = '-3';
    } elsif ($ARGV[0] eq '-3x') {
        $level = '-3';
        @exclude = @ignore_list;
    } elsif ($ARGV[0] eq '-2') {
        $level = '-2';
    } elsif ($ARGV[0] eq '-2x') {
        $level = '-3';
        @exclude = @ignore_list;
    } elsif ($ARGV[0] eq '-1') {
        $level = '-1';
    } elsif ($ARGV[0] eq '-1x') {
        $level = '-1';
        @exclude = @ignore_list;
    } else {
	die "Unknown command line argument '$ARGV[0]'\n";
    }
} else {
    die "0 or 1 argument permitted. -4 is default.\n";
}

print STDERR "Calling perlcritic $level";
if (scalar @exclude > 0) { print STDERR ", with excluded warning list"; }
print STDERR ". This can take several minutes to run!\n";

my @results = `perlcritic $level .`;
# always remove " source OK"
my @results2 = ();
foreach my $line (@results) { 
    if ($line !~ m/ source OK/) {
	push @results2, $line;
    }
}

if (scalar @exclude > 0 && scalar @results2 > 0) {
    @results = @results2;
    @results2 = ();
    # remove common errors
    foreach my $line (@results) {
	my $keep = 1;
	foreach (@exclude) {
	    if ($line =~ m/$_/) {
		$keep = 0;
		last;
	    }
	}
	if ($keep) {
	    push @results2, $line;
	}
    }
}

if (scalar(@results2) == 0) {
    print STDERR "No errors reported.\n";
} else {
    print STDERR scalar(@results2)." errors reported:\n";
    print "@results2";
}
