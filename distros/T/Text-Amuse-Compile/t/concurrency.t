#!perl

BEGIN {
    $ENV{AMW_DEBUG} = 1;
}

use strict;
use warnings;
use Test::More;
use Text::Amuse::Compile;
use File::Spec::Functions qw/catfile/;
use Cwd;

if ( $ENV{RELEASE_TESTING} ) {
    plan tests => 3;
}
else {
    plan skip_all => "Concurrency tests not required for installation";
    exit;
}


my $target = catfile(qw/t testfile deleted.muse/);
my $cwd = getcwd();
if (my $pid = fork()) {
    sleep 1;
    my $c = Text::Amuse::Compile->new(html => 1);
    my $error;
    my $failed;
    $c->logger(sub { $error .= join('', @_) });
    $c->report_failure_sub(sub { $failed = shift });
    $c->compile($target);
    ok ($failed, "$target compilation failed");
    like $error, qr/lock/, "Found lock exception";
    is $cwd, getcwd(), "Still in $cwd";
    wait;
}
else {
    my $c = Text::Amuse::Compile->new(html => 1);
    $c->compile($target);
    exit;
}
