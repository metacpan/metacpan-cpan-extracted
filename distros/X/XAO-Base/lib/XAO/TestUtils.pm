=head1 NAME

XAO::TestUtils - testing framework for XAO modules

=head1 SYNOPSIS

In your Makefile.PL:

 test::
        \$(PERL) -MXAO::TestUtils=xao_all_tests \\
                 -e'xao_all_tests("XAO::testcases::FS")'

=head1 DESCRIPTION

This module is intended for use only in testing of XAO modules and
modules based on XAO.

For instance XAO::FS installs a set of tests in system perl
directories. XAO::TestUtils and these tests can then be used for testing
third party database drivers against this standard set of tests.

Method details:

=over

=cut

###############################################################################
package XAO::TestUtils;
use strict;
use XAO::Utils;
use File::Path;
use File::Basename;
use File::Copy;
use File::Find;
use ExtUtils::Manifest qw(fullcheck maniread);
use Test::Harness;

require Exporter;

use vars qw(@ISA @EXPORT_OK @EXPORT $VERSION);

@ISA=qw(Exporter);
@EXPORT_OK=qw(xao_test_all xao_test
              xao_mf_fix_permissions xao_mf_check_consistency
             );
@EXPORT=();

$VERSION=(0+sprintf('%u.%03u',(q$Id: TestUtils.pm,v 2.2 2006/04/22 01:57:44 am Exp $ =~ /\s(\d+)\.(\d+)\s/))) || die "Bad VERSION";

###############################################################################

=item xao_test_all ($;@)

Runs all tests for a given list of namespaces in random order. As a
special case if first argument is an integer it turns debug output on
using XAO::Utils set_debug() method.

Can be called from command line:

 perl -MXAO::TestUtils=xao_test_all -e'xao_test_all(1,"testcases")'

Test execution is the same as for run_tests() method, see below.

=cut

sub xao_test_all (;$@) {
    XAO::Utils::set_debug(shift @_) if $_[0]=~/^\d+$/;

    my %tests;

    my $diradd=sub {
        my ($dir,$namespace)=@_;
        opendir(D,"$dir") || die "Can't open directory $dir: $!\n";
        while(my $file=readdir(D)) {
            next if $file eq 'base.pm' || $file eq 'Common';
            next unless $file =~ /^(.*)\.pm$/;
            $tests{$namespace . $1}=1;
        }
        closedir(D);
    };

    # A namespace allows packages to pre-define test cases and for
    # another package to reuse them (for example storage drivers for
    # XAO::FS reuse the tests defined in XAO::FS).
    #
    foreach my $namespace (@_) {

        # Scanning @INC to find directory holding these tests
        #
        (my $namedir=$namespace)=~s/::/\//g;
        foreach my $dir (@INC) {
            next unless -d "$dir/$namedir";
            $diradd->("$dir/$namedir",$namespace.'::');
        }
    }

    # More common is to have tests in t/testcases directory
    #
    if(-d 't/testcases') {
        find({
            no_chdir    => 1,
            wanted      => sub {
                return unless -d $File::Find::name;
                (my $cp=$File::Find::name)=~s|/|::|g;
                $cp=~s/^t:://;
                $diradd->($File::Find::name,$cp.'::');
            },
        },'t/testcases');
    }

    # Randomizing tests list order to make sure that tests do not depend on
    # each other.
    #
    my @tests=keys %tests;
    for(my $i=0; $i!=@tests; $i++) {
        push(@tests,splice(@tests,rand(@tests),1));
    }

    dprint "Tests: ".join(',',@tests);

    xao_test(@tests);
}

###############################################################################

=item xao_test (@)

Runs given tests in the given sequence. Tests are given as corresponding
unit package names. Example:

    xao_test('Basic','XAO::testcases::FS::Lists');

It will create 'ta' directory in the current directory and will
store two files for each test case in there - one suitable for 'make
test' with '.t' extension and one for manual checking with debug
output enabled and in different human-readable output mode with '.pl'
extension. At a later time these tests can be individually re-run
manually using simply 'perl ta/testname.pl' command.

Common prefix will be automatically removed from files.

=cut

sub xao_test (@) {
    my $testdir='t';

    -d $testdir || mkdir "$testdir",0755 ||
        die "Can't create '$testdir' directory: $!\n";

    my $prefix_count;
    my $prefix;
    foreach my $test (@_) {
        my @p=split(/::/,$test);
        if(defined $prefix) {
            while($prefix_count) {
                my $np=join('::',@p[0..$prefix_count]);
                last if length($np) <= length($prefix) &&
                        $np eq substr($prefix,0,length($np));
                $prefix_count--;
            }
        }
        else {
            $prefix_count=scalar(@p)-2;
        }
        last if $prefix_count<0;
        $prefix=join('::',@p[0..$prefix_count]);
    }

    $prefix_count++;
    my %fnames;
    foreach my $test (@_) {
        my @p=split(/::/,$test);
        my $testfile=join('_',@p[$prefix_count..$#p]);
        $fnames{$test}=$testfile;
        dprint "Test: $test file=$testfile";

        # Non-standard name (.xt vs .t) to avoid double executing by the
        # standard build code.
        #
        my $tatest="$testdir/$testfile.xt";
        open(F,"> $tatest") || die "Can't create test script ($tatest): $!\n";
        print F <<EOT;
#!$^X
#### GENERATED AUTOMATICALLY, DO NOT EDIT ####
use strict;
use warnings;
use Test::Unit::Lite;

unshift(\@INC,'t') if -d 't';

my \$r=Test::Unit::HarnessUnit->new();
\$r->start('$test');
#### GENERATED AUTOMATICALLY, DO NOT EDIT ####
EOT
        close(F);

        # Human friendlier output version
        #
        my $pltest="$testdir/$testfile.pl";
        open(F,"> $pltest") || die "Can't create test script ($pltest): $!\n";
        print F <<EOT;
#!$^X
#### GENERATED AUTOMATICALLY, DO NOT EDIT ####
use strict;
use warnings;
use blib;
use Test::Unit::Lite;
use XAO::Utils;

XAO::Utils::set_debug(1);

unshift(\@INC,'t') if -d 't';

my \$r=Test::Unit::TestRunner->new();
\$r->start('$test');
print "\\n";
#### GENERATED AUTOMATICALLY, DO NOT EDIT ####
EOT
        close(F);

        chmod 0755, '$testdir/$testfile.pl';
    }

    # Executing tests
    #
    print <<'END_OF_WARNING';
===========================================================
If you see that a test failed, please run it as follows:

   perl t/failed_test_name.pl

Send the output to the module author along with your perl
version and a note of what you think might be the reason.
-----------------------------------------------------------
END_OF_WARNING

    ### dprint join(",",(map { "$testdir/$fnames{$_}.t" } @_));

    runtests(map { "$testdir/$fnames{$_}.xt" } @_);

    print <<EOT;
===========================================================
EOT
}

###############################################################################

sub xao_mf_check_consistency {
    die "Must have MANIFEST in the current directory\n" unless -r 'MANIFEST';
    my ($missing,$extra)=fullcheck();
    if($missing && @$missing) {
        die "There are missing files, aborting!\n";
    }
    if($extra && @$extra) {
        warn "There are some new files, add them to the MANIFEST!\n";
    }
}

###############################################################################

sub xao_mf_fix_permissions {
    die "Must have MANIFEST in the current directory\n" unless -r 'MANIFEST';

    my @skip;
    if(open('F','MANIFEST.SKIP')) {
        while(<F>) {
            next unless /^(\S+)(\s*.*)?$/;
            my $regex=$1;
            push(@skip,qr/$regex/);
        }
        close(F);

    }

    my @modes;
    if(open('F','MANIFEST.MODES')) {
        while(<F>) {
            next unless /^([0-7]+)\s+([0-7]+)\s+(.*?)\s*$/;
            my $dirmode=oct($1);
            my $filemode=oct($2);
            my $regex=$3;

            warn "Strange dirmode $dirmode for $regex\n"
                if ($dirmode&0500) != 0500;
            warn "Strange filemode $filemode for $regex\n"
                if ($filemode&0400) != 0400;

            push(@modes,{
                regex       => qr/$regex/,
                filemode    => $filemode,
                dirmode     => $dirmode,
            });
        }
        close(F);
    }

    find({
        no_chdir    => 1,
        preprocess  => sub {
            my @list;
            foreach my $fn (@_) {
                my $file=$File::Find::dir . '/' . $fn;
                $file=~s/^.\/(.*)$/$1/;

                next if $file =~ /(^|\/)(\.|\.\.)/;
                if(grep { $file =~ $_ } @skip) {
                    dprint "Skipping $file";
                    next;
                }

                push(@list,$fn);
            }
            return @list;
        },
        wanted      => sub {
            my $file=$File::Find::name;
            $file=~s/^\.\/(.*)$/$1/;
            die "Wrong file path '$file'" if $file =~ /^\// || $file =~ /\.\.\//;

            my $perm;
            foreach my $ml (@modes) {
                if($file =~ $ml->{'regex'}) {
                    dprint "Permission override for $file";
                    $perm=$ml;
                    last;
                }
            }
            $perm||={
                filemode    => 0644,
                dirmode     => 0755,
            };

            die "Can't stat $file\n" unless stat($file);

            my $newperm=-d _ ? $perm->{'dirmode'} : $perm->{'filemode'};
            my $oldperm=((stat(_))[2]) & 07777;

            if($oldperm != $newperm) {
                printf STDERR "Setting %s from %04o to %04o\n",$file,$oldperm,$newperm;
                chmod($newperm,$file) ||
                    die "Can't change $file to ".sprintf('%04o',$newperm).": $!\n";
            }
        },
    },'.');
}

###############################################################################
1;
__END__

=head1 AUTHOR

Copyright (c) 2005 Ejelta LLC.
Copyright (c) 2003 XAO Inc.

The author is Andrew Maltsev <am@ejelta.com>.
