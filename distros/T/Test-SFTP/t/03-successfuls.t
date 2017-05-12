#!perl

# we're testing if we can connect
use strict;
use warnings;

use English '-no_match_vars';
use Test::More tests => 11;
use Test::SFTP;
use Term::ReadLine;
use Term::ReadPassword;

SKIP: {
    eval "getpwuid $REAL_USER_ID";
    if ( $EVAL_ERROR ) {
        skip "no getpwuid", 11;
    }

    my $term     = Term::ReadLine->new('test_term');
    my $host     = 'localhost';
    my $timeout  = 10;
    my $SPACE    = q{ };
    my $EMPTY    = q{};

    my $username = getpwuid $REAL_USER_ID || $EMPTY;

    my ( $password, $test, $prompt );
    my ( $full_status, $status_number, $status_string );

    SKIP: {
        eval {
            local $SIG{'ALRM'} = sub {
                die "input failed\n";
            };

            alarm $timeout;

            my $msg = "Press [enter] to help me test or wait $timeout seconds";
            $test = $term->readline($msg);
            chomp $test;

            alarm 0;
        };

        if ( $EVAL_ERROR eq "input failed\n" || $test eq 'q' ) {
            skip "Alright, nevermind...\n", 11;
        }

        $prompt = $term->readline("SSH/SFTP host to test [$host]: ");
        $prompt and $host = $prompt;

        $prompt = $term->readline("Username [$username]: ");
        $prompt and $username = $prompt;

        $password = read_password('Password: ');

        my $sftp = Test::SFTP->new(
            host     => $host,
            user     => $username,
            password => $password,
            timeout  => 2,
        );

        $sftp->can_connect('can connect to SFTP');
        is( $sftp->connected, 1, 'we are really connected' );

        $status_number = 0;

        $sftp->is_status( $status_number, 'Checking SFTP status number' );
        $sftp->is_error(  $status_number, 'Checking SFTP error status'  );

        SKIP: {
            if ( ! $ENV{'TEST_SFTP_DANG'} ) {
                skip "Dangerous tests only tests if TEST_SFTP_DANG is set", 2;
            }

            eval 'use File::Util';

            if ($EVAL_ERROR) {
                skip 'Missing File::Util', 2;
            }

            my $random_file = rand 99999;

            my $file_util = File::Util->new;
            $file_util->touch($random_file);

            $sftp->can_put(
                $random_file,
                $random_file,
                'Trying to upload to good location',
            );

            $sftp->can_get(
                $random_file,
                "$random_file.tmp",
                'Trying to get a file',
            );

            # this is dangerous
            # we need to finish some stuff
            # before allowing people to run all these tests
            $sftp->object->remove( $random_file );

            # we do not need this file anymore
            # TODO: if in the process of getting a file
            # we overwritten that file, we will be accidently removing it
            # so we need to check if it is so
            unlink $random_file, "$random_file.tmp";
        };

        my $random_file = rand 99999;
        my $bad_path    = "/$random_file";

        # TODO: OS portability
        $sftp->can_ls( '/', 'Trying to do ls'   );
        $sftp->cannot_ls( $bad_path, 'Trying to fail ls' );

        $sftp->cannot_put(
            $random_file,
            $bad_path,
            'Trying to upload to bad location',
        );

        $sftp->cannot_get( $bad_path, '/', 'Trying to get a nonexistent file' );

        ok(
            $sftp->object->status =~ /^(?:No such file|File not found)$/,
            'Checking SFTP nonexistent path complete status',
        );
    }
}

