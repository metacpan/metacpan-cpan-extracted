use strict;
use warnings;

use Test::More;
use LWP::Simple;

use_ok('Test::Httpd::Apache2');

# skip if httpd cannot be found
if ($^O eq 'MSWin32'
        ? find_prog('httpd.exe')
            : (find_prog('httpd') && find_prog('apxs'))
                || (find_prog('apache2') && find_prog('apxs2'))) {
    # ok
} else {
    warn "httpd or apxs not found, skipping actual tests";
    goto DONE_TESTING;
}

# start httpd
my $httpd = Test::Httpd::Apache2->new(
    custom_conf => join(
        "\n",
        q(DocumentRoot t/assets/htdocs),
    ),
);

ok $httpd, 'spawn httpd';
is get("http://@{[$httpd->listen]}/hello.txt"), 'hello';

# stop httpd
$httpd->stop();

ok ! $httpd->pid(), 'httpd should be down';

# try to load module if has support for dso
if (my %mods = %{$httpd->get_dynamic_modules}) {
    $httpd->required_modules([ (sort keys %mods)[0] ]);
    $httpd->start(); # will die on error
}

undef $httpd;

DONE_TESTING:
done_testing;

sub find_prog {
    no warnings qw(once);
    my $prog = shift;
    my @paths = (
        split(Test::Httpd::Apache2::PATH_SEP(), $ENV{PATH}),
        @{$Test::Httpd::Apache2::Defaults{search_paths}},
    );
    return scalar(grep { -x "$_/$prog" } @paths) != 0;
}
