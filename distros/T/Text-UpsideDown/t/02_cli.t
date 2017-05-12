use strict;
use warnings;
use utf8;
use open qw(:std :encoding(UTF-8));
use Text::UpsideDown;
use IPC::Run3;
use File::Spec;
use Test::More tests => 2;

my $script = File::Spec->catfile(qw/ bin ud /);
my $salutation = 'hello';
my $response = qr/oʃʃǝɥ/;

subtest 'arg' => sub {
    plan tests => 2;
    run3 [$script, $salutation], \undef, \my $out, \my $err, +{ binmode_stdout => ':encoding(UTF-8)' };
    like $out => $response;
    is $err => '';
};

subtest 'stdin' => sub {
    plan tests => 2;
    run3 [$script], \$salutation, \my $out, \my $err, +{ binmode_stdout => ':encoding(UTF-8)' };
    like $out => $response;
    is $err => '';
};
