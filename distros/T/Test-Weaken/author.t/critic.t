#!perl

use strict;
use warnings;

use Test::More;
use Fatal qw( open close waitpid );
use English qw( -no_match_vars );
use IPC::Open2;
use POSIX qw(WIFEXITED);

my %exclude = map { ( $_, 1 ) } qw(
    Makefile.PL
);

sub run_critic {
    my $file = shift;
    my @cmd  = (
        #<<< perltidy messes this up
        'perlcritic',
        '--verbose', '%l:%c %p %r\n',
        '--exclude', 'Dynamic::*',
        '-profile', 'author.t/perlcriticrc',
        #>>>
    );
    push @cmd, $file;
    my ( $child_out, $child_in );

    my $pid = IPC::Open2::open2( $child_out, $child_in, @cmd )
        or Carp::croak("IPC::Open2 of perlcritic pipe failed: $ERRNO");
    close $child_in;
    my $critic_output = do {
        local ($RS) = undef;
        <$child_out>;
    };
    close $child_out;
    waitpid $pid, 0;
    if ( my $child_error = $CHILD_ERROR ) {
        my $error_message;

        if (WIFEXITED(
                ## perlcritic does not seem to understand what CHILD_ERROR_NATIVE is
                ## no critic (Variables::ProhibitPunctuationVars)
                ${^CHILD_ERROR_NATIVE}
                    ## use critic
            ) != 1
            )
        {
            $error_message = "perlcritic returned $child_error";
        } ## end if ( WIFEXITED( ${^CHILD_ERROR_NATIVE} ) != 1 )

        if ( defined $error_message ) {
            print {*STDERR} $error_message, "\n"
                or Carp::croak("Cannot print to STDERR: $ERRNO");
            $critic_output .= "$error_message\n";
        }
        return \$critic_output;
    }
    return q{};
}

open my $manifest, '<', 'MANIFEST'
    or Carp::croak("open of MANIFEST failed: $ERRNO");

my @test_files = ();
FILE: while ( my $file = <$manifest> ) {
    chomp $file;
    $file =~ s/\s*[#].*\z//xms;
    next FILE if -d $file;
    next FILE if $exclude{$file};
    my ($ext) = $file =~ / [.] ([^.]+) \z /xms;
    next FILE if not defined $ext;
    $ext = lc $ext;
    next FILE
        if $ext ne 'pl'
            and $ext ne 'pm'
            and $ext ne 't';

    push @test_files, $file;
}    # FILE
close $manifest;

Test::More::plan tests => scalar @test_files;

open my $error_file, '>', 'author.t/perlcritic.errs';
FILE: for my $file (@test_files) {
    if ( not -f $file ) {
        Test::More::fail("perlcritic of non-file: $file");
        next FILE;
    }
    my $warnings = run_critic($file);
    my $clean    = 1;
    my $message  = "perlcritic clean for $file";
    if ($warnings) {
        $clean = 0;
        my @newlines = ( ${$warnings} =~ m/\n/xmsg );
        $message =
              "perlcritic for $file: "
            . ( scalar @newlines )
            . ' lines of warnings';
    }
    Test::More::ok( $clean, $message );
    next FILE if $clean;
    print {$error_file} "=== $file ===\n" . ${$warnings}
        or Carp::croak("print failed: $ERRNO");
}
close $error_file;
