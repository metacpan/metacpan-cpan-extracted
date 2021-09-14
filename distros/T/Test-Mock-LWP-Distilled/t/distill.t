#!/usr/bin/env perl
# General tests for Test::Mock::LWP::Distilled.

use strict;
use warnings;
use lib::abs 'lib';
use English qw(-no_match_vars);

use Test::Mock::LWP::Distilled;

use Capture::Tiny qw(capture);
use Cwd qw(cwd);
use File::Spec::Functions qw(catfile);
use File::Temp;
use HTTP::Status qw(:constants);
use Test::Fatal;
use Test::More import => [qw(!like)];
use Test2::Tools::Compare qw(like);

use_ok 'Simple::Mock::Class';
my $test_class = 'Simple::Mock::Class';

subtest 'Environment variable determines default mode' => \&test_mode;
subtest 'Record mode produces new mocks'               => \&test_record_mode;
subtest 'Play mode uses the recorded mocks'            => \&test_play_mode;
subtest 'We derive the mock filename'                  => \&test_filename;
subtest 'Mocks are read from a file'                   => \&test_read_mocks;
subtest 'Mocks are written to a file also'             => \&test_write_mocks;
subtest 'Writing mocks to a file can fail'             => \&test_fail_to_write;

done_testing();

# The environment variable REGENERATE_MOCK_FILE determines the initial
# mode for any Test::Mock::LWP::Distilled-using class.

sub test_mode {
    {
        local $ENV{REGENERATE_MOCK_FILE};
        my $mock_object = $test_class->new;
        is $mock_object->mode, 'play',
            'Without an environment variable, we play mocks';
    }
    {
        local $ENV{REGENERATE_MOCK_FILE} = 1;
        my $mock_object = $test_class->new;
        is $mock_object->mode, 'record',
            'With the environment variable set, we record mocks';
    }
}

# When in record mode, requests attempt to contact a live server and record
# a new mock.

sub test_record_mode {
    # Create a new mock object, which only records the path of the URI.
    # Make sure that the responses relate to something in the URI *other*
    # than the path, so we can be sure this is us doing things.
    my $mock_object = $test_class->new(mode => 'record');
    $mock_object->_monkey_patched_simple_request(
        sub {
            my ($self, $request, $arg, $size) = @_;

            my $response = HTTP::Response->new;
            $response->code(HTTP_I_AM_A_TEAPOT);
            $response->content($request->uri->host . ' says yes');
            return $response;
        }
    );

    # Ask for a remote URL. We talked to our monkey-patched code, as expected,
    # and the results are recorded in mocks.
    like $mock_object->mocks, [], 'No mocks at first';
    my $response = $mock_object->get('https://wossname.lol/get-badgers');
    is $response->code, HTTP_I_AM_A_TEAPOT, 'Surprising HTTP code returned';
    is $response->decoded_content,
        my $expected_content = 'wossname.lol says yes',
        'Surprising content returned';
    like $mock_object->mocks,
        [
            my $badger_mock = {
                distilled_request  => '/get-badgers',
                distilled_response => $expected_content,
            }
        ],
        'This was recorded in our mocks';

    # Further mocks get added to the list.
    $mock_object->get('ftp://hooray-henry/upper-class/twit');
    like $mock_object->mocks,
        [
            $badger_mock,
            {
                distilled_request  => '/upper-class/twit',
                distilled_response => 'hooray-henry says yes',
            }
        ],
        'A further request gets added to the mocks';

    # Further tests will check that mocks get written to a file, but for now
    # let's not bother, so remove the mocks before our object
    # goes out of scope.
    @{ $mock_object->mocks } = ();
}

# When in play mode, requests use the mocks and generate a response from the
# distilled response. If you're out of mocks, or your request doesn't match
# the distilled request of the first mock available, you get an error.

sub test_play_mode {
    # Set up a mock object with two mocks.
    my $mock_object = $test_class->new(mode => 'play', base_dir => cwd());
    $mock_object->mocks;
    @{ $mock_object->mocks } = (
        {
            distilled_request  => '/login',
            distilled_response => 'Welcome!'
        },
        {
            distilled_request  => '/login',
            distilled_response => 'You did that already',
        }
    );

    # We get a response generated from the mock.
    my $response = $mock_object->get('https://some-random.website/login');
    is $response->code, undef, q{Our minimal class didn't bother to set a code};
    is $response->decoded_content, 'Welcome!',
        'We took our response from a mock';
    ok $mock_object->mocks->[0]{used}, 'The first mock is marked as used...';
    ok !$mock_object->mocks->[1]{used}, '...but not the second';

    # If we ask again, we get a new response, even though the distilled
    # request was different.
    $response = $mock_object->get('https://other.website/login');
    is $response->decoded_content, 'You did that already',
        'Response from the second mock, even though the distilled request'
            . ' also matches the first mock';
    ok $mock_object->mocks->[0]{used}, 'The first mock is still used...';
    ok $mock_object->mocks->[1]{used}, '...and now the second is also';

    # If we ask a third time, no dice: there are no mocks left so you can't
    # possibly get anything useful.
    ok my $exception_no_mocks_left
        = exception { $mock_object->get('https://yet-another.website/login') },
        'Trying a third time when there are no mocks left gets us an exception';
    like $exception_no_mocks_left, qr/No mocks left to use/,
        'The exception complains about no mocks left';
    like $exception_no_mocks_left,
        my $re_stack_trace = qr{
            Test::Mock::LWP::Distilled
            .+
            $test_class
            .+
            distill[.]t
        }xsm,
        'We got a stack trace that mentioned useful stuff';

    # Say we haven't used the last mock after all: that works again.
    $mock_object->{mocks}[1]{used} = 0;
    $response = $mock_object->get('https://how-many-websites-are-there/login');
    is $response->decoded_content, 'You did that already',
        'Marking a mock as unused lets us retry it (naughty!)';
    ok $mock_object->{mocks}[1]{used}, 'That mock is marked as used again';

    # But if it doesn't match, we complain.
    $mock_object->{mocks}[1]{used} = 0;
    ok my $exception_mismatch = exception {
        $mock_object->get('https://some-random.website/do_stuff')
    },
        q{If the request doesn't distill to what we expected, error};
    like $exception_mismatch, qr/does not match/,
        q{We complain that the request and mock don't match};
    like $exception_mismatch, qr/do_stuff/, 'We mention the request...';
    like $exception_mismatch, qr/login/,    '...and what we expected';
    like $exception_mismatch, $re_stack_trace, 'We also include a stack trace';
}

# We decide where to read mocks to, and where to write them to, depending on
# constructor parameters.

sub test_filename {
    # By default, the filename is derived from the calling filename.
    my $tempdir = _tempdir();
    my $mock_object_from_file = $test_class->new(base_dir => $tempdir);
    is $mock_object_from_file->mock_filename,
        catfile($tempdir, 'distill-simple-mock.json'),
        'Default: derive the file name from our temp directory and filename';
    isnt $mock_object_from_file->_calling_filename, 'distill.t',
        q{That wasn't because our idea of the calling filename was just the leafname...};
    isnt $mock_object_from_file->_calling_filename, 't/distill.t',
        '...or the leafname under the t directory';
    is $mock_object_from_file->_calling_filename,
        File::Spec->rel2abs(__FILE__),
        '...it was in fact the absolute path of this file';

    # If we say "take the name from the calling class" instead, we turn
    # that into a directory hierarchy.
    my $mock_object_from_class;
    package Some::Test::Class;
    $mock_object_from_class = $test_class->new(
        base_dir                     => $tempdir,
        file_name_from_calling_class => 1,
    );
    package main;
    is $mock_object_from_class->mock_filename,
        catfile($tempdir, 'Some', 'Test', 'Class-simple-mock.json'),
        'The mock filename was derived from our temp directory and class name';
}

# We'll read (lazily) mocks from a file, but they have to look the part.

sub test_read_mocks {
    my $tempdir = _tempdir();

    # If the data's not JSON, no dice.
    my $mock_object = _mock_object_with_stored_mocks(
        tempdir   => $tempdir,
        mock_data => 'This is JSON, right?'
    );
    my $exception_not_json = exception { $mock_object->mocks };
    ok $exception_not_json, 'Invalid JSON throws an exception...';
    like $exception_not_json, qr/invalid JSON/i, '...a reasonable one';

    # Valid JSON which isn't an array is also a problem.
    $mock_object = _mock_object_with_stored_mocks(
        tempdir   => $tempdir,
        mock_data => '{"mocks": ["Yo mama", "Your hat is stupid", "etc."]}',
    );
    my $exception_bad_json = exception { $mock_object->mocks };
    ok $exception_bad_json, 'JSON in the wrong format throws an exception...';
    like $exception_bad_json, qr/Expected an arrayref of data .+ got HASH/,
        '...which tells us what happened';

    # Any mock that doesn't contain distilled_request and distilled_response
    # is enough for the mock file to be rejected.
    $mock_object = _mock_object_with_stored_mocks(
        tempdir   => $tempdir,
        mock_data => <<'SUBTLY_BAD_JSON',
[
    {
        "distilled_request": "Tap, tap, is this thing on?",
        "distilled_response": true
    },
    {
        "distilled_request": "Life, the Universe and everything"
    },
    {
        "distilled_response": "Tricky"
    }
]
SUBTLY_BAD_JSON
    );
    my $exception_subtly_bad_json = exception { $mock_object->mocks };
    ok $exception_subtly_bad_json, 'JSON which is subtly wrong also throws...';
    like $exception_subtly_bad_json,
        qr/distilled_request and distilled_response/,
        '...an exception which mentions what it was expecting to find';
    
    # If the JSON is valid, though, the mocks work.
    $mock_object = _mock_object_with_stored_mocks(
        tempdir   => $tempdir,
        mock_data => <<'JSON',
[
    {
        "distilled_request": "/get-stuff",
        "distilled_response": "Not what you expected?"
    }
]
JSON
    );
    ok !exception { $mock_object->mocks },
        'Reading the mocks works fine with valid data';

    # And we can use them in a request.
    my $response = $mock_object->get('https://doesnt.matter.lol/get-stuff');
    is $response->decoded_content, 'Not what you expected?',
        'Response matches what we put in the mock file';
    like $mock_object->mocks,
        [
            {
                distilled_request  => '/get-stuff',
                distilled_response => 'Not what you expected?',
                used               => 1,
            }
        ],
        'That mock is indeed stored and marked as used';
}

# When we record mocks, they're written to a file when the object goes out
# of scope.

sub test_write_mocks {
    # Gear up to recording mocks.
    my $tempdir = _tempdir();
    my $mock_dir = _ensure_dirs_exist($tempdir, qw(Some Mock Writing Test));
    my $mock_file = catfile($mock_dir, 'Class-simple-mock.json');
    ok !-e $mock_file, 'The mock file does not exist before we record';

    # Create a mock object...
    my $mock_object;
    package Some::Mock::Writing::Test::Class;
    $mock_object = $test_class->new(
        base_dir                     => $tempdir,
        file_name_from_calling_class => 1,
        mode                         => 'record',
    );
    package main;

    # ...and monkey-patch the object to generate responses.
    my $response_number;
    $mock_object->_monkey_patched_simple_request(
        sub {
            my ($self, $request, $arg, $size) = @_;

            my $response = HTTP::Response->new;
            $response->code(HTTP_PAYMENT_REQUIRED);
            $response->content('Pay me #' . ++$response_number);
            return $response;
        }
    );

    # Send a number of requests, and destroy the mock object.
    $mock_object->get('https://some.website/get/free/stuff');
    $mock_object->get('https://some.other.website/free/stuff/please');
    $mock_object->get('https://en.wikipedia.org/wiki/Entitlement#Psychology');
    undef $mock_object;

    # These mocks were written to a file.
    ok -e $mock_file, 'There is now a mock file';
    my $mock_file_contents;
    open my $fh, '<', $mock_file;
    { local $/ = undef; $mock_file_contents = <$fh> };
    is $mock_file_contents, <<'MOCK_FILE_CONTENTS', 'Mocks were serialised';
[
   {
      "distilled_request" : "/get/free/stuff",
      "distilled_response" : "Pay me #1"
   },
   {
      "distilled_request" : "/free/stuff/please",
      "distilled_response" : "Pay me #2"
   },
   {
      "distilled_request" : "/wiki/Entitlement",
      "distilled_response" : "Pay me #3"
   }
]
MOCK_FILE_CONTENTS
}

# If we try to write to our mock file and fail, that's reported.
# Via spewing to STDERR for some reason rather than a properly-caught
# exception, but that's good enough.

sub test_fail_to_write {
    # If the directory it wants to write to doesn't exist, that's
    # going to cause problems.
    my $tempdir   = _tempdir();
    my $mock_object;
    package Some::Class::Whose::Dirs::We::Didnt::Create;
    $mock_object = $test_class->new(
        base_dir                     => $tempdir,
        file_name_from_calling_class => 1,
        mode                         => 'record',
    );
    package main;
    @{ $mock_object->mocks } = (
        {
            distilled_request  => 'woo',
            distilled_response => 'watch me fail'
        }
    );
    my ($stdout, $stderr, $exit) = capture { undef $mock_object; };
    ok $stderr, q{We complain to STDERR if we can't write our mocks...};
    like $stderr, qr/Tried writing mocks/, '...and we blame the file system';

    # Now make sure the directory exists, but stick stuff in the mocks that
    # can't be serialised to JSON. That also generates an error.
    my $mock_dir  = _ensure_dirs_exist(
        $tempdir, qw(Some Mock Failing To Write Test)
    );
    my $mock_file = catfile($mock_dir, 'Class-simple-mock.json');
    package Some::Mock::Failing::To::Write::Test::Class;
    $mock_object = $test_class->new(
        base_dir                     => $tempdir,
        file_name_from_calling_class => 1,
        mode                         => 'record',
    );
    package main;
    @{ $mock_object->mocks } = (
        {
            distilled_request => \'No scalarrefs in JSON',
            distilled_response => bless { } => 'Mwahahaha::No::JSON::For::You',
        }
    );
    ($stdout, $stderr, $exit) = capture { undef $mock_object; };
    ok $stderr, q{We die if we can't write JSON...};
    like $stderr, qr/Couldn't encode mocks as JSON/,
        '...and we blame JSONifying';
}

# Supplied with a hash of arguments, creates mock object prepared to read
# mocks from a file.
# Arguments are:
# * tempdir: the name of a directory to store mock data in
# * mock_data: the raw data to store in the mock file.

sub _mock_object_with_stored_mocks {
    my (%args) = @_;

    # Create a mock object...
    my $mock_object;
    package Some::Mock::Read::Test::Class;
    $mock_object = $test_class->new(
        base_dir                     => $args{tempdir},
        file_name_from_calling_class => 1,
        mode                         => 'play',
    );
    package main;

    # ...set up a file for it to read from...
    my $mock_path = _ensure_dirs_exist($args{tempdir}, qw(Some Mock Read Test));
    my $mock_filename = catfile($mock_path, 'Class-simple-mock.json');

    # ...and inject the raw JSON.
    open my $fh, '>', $mock_filename
        or die "Couldn't write $mock_filename: $OS_ERROR";
    print $fh $args{mock_data};
    close $fh;

    return $mock_object;
}

# Supplied with a base directory and a sequence of subdirectories, makes sure
# that each subdirectory exists, and returns the filename of the resulting
# directory.

sub _ensure_dirs_exist {
    my ($basedir, @subdirs) = @_;
    my $dir_to_create = $basedir;
    path:
    for my $subdir (@subdirs) {
        $dir_to_create = catfile($dir_to_create, $subdir);
        next path if -d $dir_to_create;
        mkdir $dir_to_create or die "Couldn't create $dir_to_create: $OS_ERROR";
    }
    return $dir_to_create;
}

# Returns a tempdir that will get automatically deleted when this object
# goes out of scope.

sub _tempdir {
    File::Temp::tempdir(
        'Test-Mock-LWP-Distilled-XXXXX',
         TMPDIR => 1, CLEANUP => 1
    );
}

