use Test::More;
use Test::Mojo;
use Mojo::File qw(tempdir tempfile);
use Cwd;

use FindBin;
use lib "$FindBin::Bin/../lib";

# Prepare temp file
my $tc = 'foo';
my $td = tempdir;
my $tf = tempfile(DIR => $td)->spurt($tc);

subtest 'Directory from environment' => sub {
    local $ENV{SERVE_DIRECTORY} = $td->to_string;
    my $t = Test::Mojo->new('ojo::ServeDir::App');

    $t->get_ok('/')->status_is(404);
    $t->get_ok('/' . $tf->basename)->status_is(200)->content_is($tc);
};

subtest 'Directory = current working directory' => sub {
    my $cwd = getcwd;
    chdir $td;
    my $t = Test::Mojo->new('ojo::ServeDir::App');

    $t->get_ok('/' . $tf->basename)->status_is(200)->content_is($tc);
    chdir $cwd;
};

done_testing;
