use strict;
use warnings;

use re '/aa';

use 5.014;

use Test::More;

use JSON::Validator::Schema::Troglodyne;

sub validate {
    my ($opts, $args) = @_;
    my $validator = JSON::Validator::Schema::Troglodyne->new();
    return $validator->validate($opts, $args);
}

sub _test {
    my ($input, $data, $test, $msg) = @_;
    my @errors = validate($input, $data);
    like($errors[0], $test, $msg);
}

my %data = (
    type       => 'object',
    required   => [qw{foo bar}],
    properties => {
        foo => { type => 'email' },
        bar => { type => 'callback' },
    },
);

my %input = (
    foo => 'test@test.test',
    bar => '',
);

# Sub checkinz
_test(\%input, \%data, qr/not a fully qualified sub name/i, "non fq Bogus subname results in failure");
$input{bar} = [];
_test(\%input, \%data, qr/not a fully qualified sub name/i, "Bogus subname type results in failure");
$input{bar} = 'Fully::bogus';
_test(\%input, \%data, qr/cannot be loaded/i, "Unloadable Bogus subname results in failure");
$input{bar} = 'JSON::Validator::Schema::Troglodyne::bogus';
_test(\%input, \%data, qr/sub which does not exist/i, "Bogus subname results in failure");
$input{bar} = 'JSON::Validator::Schema::Troglodyne::_troglodyne_path';
my @err = validate(\%input, \%data);
is(scalar(@err), 0, "OK subname & email results in no failure");

# email checkinz
$input{foo} = 'bogus';
_test(\%input, \%data, qr/no email/i, "Bogus email results in failure");
$input{foo} = [];
_test(\%input, \%data, qr/wrong type/i, "Bogus email type results in failure");

# x-errorMessage
my $dependency = {
    type             => 'object',
    minProperties    => 1,
    required         => ['test'],
    not              => { required => ['test'], maxProperties => 1 },
    properties       => { test => { type => 'string' }, deb => { type => 'object', minProperties => 1 } },
    'x-errorMessage' => { not => 'names no packager', minProperties => 'is empty', required => 'needs a test' },
};
my $declaration = { type => 'object', additionalProperties => $dependency };
sub errors_of {
    my ($doc) = @_;
    return [ map { "$_" } validate( $doc, $declaration ) ];
}
is_deeply( errors_of( { ffmpeg => { test => 'x' } } ), ['/ffmpeg: names no packager'], 'the message of not replaces Should not match' );
is_deeply( errors_of( { ffmpeg => {} } ), [ '/ffmpeg: is empty', '/ffmpeg/test: needs a test' ], 'each keyword that fails gets its own message, and required goes to the missing property' );
is_deeply( errors_of( { ffmpeg => { test => 'x', deb => {} } } ), ['/ffmpeg/deb: Not enough properties: 0/1.'], 'a deeper error of a named keyword keeps its own message' );
is_deeply( errors_of( { ffmpeg => { test => 'x', deb => [] } } ), ['/ffmpeg/deb: Expected object - got array.'], 'an error of a keyword that the hash does not name keeps its own message' );
is_deeply( errors_of( { ffmpeg => { test => 'x', deb => { a => 1 } } } ), [], 'valid data has no errors' );

done_testing();
