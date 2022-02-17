package Test::TMF;    # inspired by App::Yath::Tester

use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Explain;

use Test2::API qw/context run_subtest/;
use Test2::Tools::Compare qw/is/;

use Carp qw/croak/;
use File::Temp qw/tempfile tempdir/;
use File::Basename qw(basename);

use POSIX;
use Fcntl qw/SEEK_CUR/;

use Cwd 'abs_path';

use Test2::Harness::Util::IPC qw/run_cmd/;

use Exporter 'import';
our @EXPORT = qw{

  tmf_test_code

  t2_run_script

};

our $TMP;    # directory

sub _setup_tmp_dir {
    $TMP //= File::Temp->newdir();
}

my @_tmf_test_args;

sub tmf_test_code {

    my (%params) = @_;

    if ( !scalar @_tmf_test_args ) {
        require Test::MockFile;
        my $path = $INC{"Test/MockFile.pm"} or die;
        $path =~ s{\QTest/MockFile.pm\E$}{};
        push @_tmf_test_args, '-I' . $path;
    }

    return t2_run_script( perl_args => \@_tmf_test_args, %params );
}

sub t2_run_script {
    my (%params) = @_;

    my $perl_args = delete $params{perl_args} // [];
    my $test_code = delete $params{test_code} // croak("no test code");

    my ( $fh, $filename ) = tempfile( DIR => _setup_tmp_dir() );
    print {$fh} <<"EOS";
use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

$test_code

done_testing;
EOS
    close $fh;

    return _test_script( sub { return ( $filename, @$perl_args ) }, %params );
}

sub _test_script {

    my ( $finder, %params ) = @_;

    my $ctx = context();

    my $cmd    = delete $params{cmd} // delete $params{command};
    my $cli    = delete $params{cli} // delete $params{args} // [];
    my $env    = delete $params{env} // {};
    my $prefix = delete $params{prefix};

    my $subtest  = delete $params{test} // delete $params{tests} // delete $params{subtest};
    my $exittest = delete $params{exit};

    my $debug   = delete $params{debug}   // 0;
    my $capture = delete $params{capture} // 1;

    my $name = delete $params{name};

    if ( keys %params ) {
        croak "Unexpected parameters: " . join( ', ', sort keys %params );
    }

    my ( $wh, $cfile );
    if ($capture) {
        ( $wh, $cfile ) = tempfile( "cpdev-$$-XXXXXXXX", TMPDIR => 1, CLEANUP => 1, SUFFIX => '.out' );
        $wh->autoflush(1);
    }

    die q[Finder need to be a coderef] unless ref $finder eq 'CODE';
    my ( $script, @lib ) = $finder->();
    my @all_args = ( $cmd ? ($cmd) : (), @$cli );

    my @cmd = ( $^X, @lib, $script, @all_args );

    print STDERR "DEBUG: Command = " . join( ' ' => @cmd ) . "\n" if $debug;

    local %ENV = %ENV;
    $ENV{$_} = $env->{$_} for keys %$env;
    my $pid = run_cmd(
        no_set_pgrp => 1,
        $capture ? ( stderr => $wh, stdout => $wh ) : (),
        command       => \@cmd,
        run_in_parent => [ sub { close($wh) } ],
    );

    my ( @lines, $exit );
    if ($capture) {
        open( my $rh, '<', $cfile ) or die "Could not open output file: $!";
        $rh->blocking(0);
        while (1) {
            seek( $rh, 0, SEEK_CUR );    # CLEAR EOF
            my @new = <$rh>;
            push @lines => @new;
            print map { chomp($_); "DEBUG: > $_\n" } @new if $debug > 1;

            waitpid( $pid, WNOHANG ) or next;
            $exit = $?;
            last;
        }

        while ( my @new = <$rh> ) {
            push @lines => @new;
            print map { chomp($_); "DEBUG: > $_\n" } @new if $debug > 1;
        }
    }
    else {
        print STDERR "DEBUG: Waiting for $pid\n" if $debug;
        waitpid( $pid, 0 );
        $exit = $?;
    }

    print STDERR "DEBUG: Exit: $exit\n" if $debug;

    my $out = {
        exit => $exit,
        $capture ? ( output => join( '', @lines ) ) : (),
    };

    $name //= join( ' ', map { length($_) < 30 ? $_ : substr( $_, 0, 10 ) . "[...]" . substr( $_, -10 ) } grep { defined($_) } basename($script), @all_args );
    run_subtest(
        $name,
        sub {
            if ( defined $exittest ) {
                my $ictx = context( level => 3 );
                is( $exit, $exittest, "Exit Value Check" );
                $ictx->release;
            }

            if ($subtest) {
                local $_ = $out->{output};
                local $? = $out->{exit};
                $subtest->($out);
            }

            my $ictx = context( level => 3 );

            $ictx->diag( "Command = " . join( ' ' => grep { defined $_ } @cmd ) . "\nExit = $exit\n==== Output ====\n$out->{output}\n========" )
              unless $ictx->hub->is_passing;

            $ictx->release;
        },
        { buffered => 1 },
        $out,
    ) if $subtest || defined $exittest;

    $ctx->release;

    return $out;
}

1;
