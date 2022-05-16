use strict;
use warnings;

use Cwd qw(cwd abs_path);
use File::Spec;

use lib::relative::to HgRepository => 'lib';

# No import, we test class method invocation in this file.
# We also test returning multiple dirs in this file, but don't
# bother in the others, and likewise test that @INC isn't polluted, and that scalar/list sensitivity matters.

use Directory::relative::to;

use Test::More;
use Test::Exception;

my @lookfor = map {
    my $l = $_;
    $l =~ s/\//\\/g if($l =~ /^[A-Z]:\//);
    $l;
} (
    abs_path(File::Spec->catdir(
        cwd(),
        qw(t fakehgrepo lib)
    )),
    abs_path(File::Spec->catdir(
        cwd(),
        qw(t fakehgrepo t)
    ))
);

ok(
    (grep { $_ eq $lookfor[0] } @INC),
    "Found '$lookfor[0]' in \@INC"
) || diag('@INC contains ['.join(', ', @INC).']');

my $count = 0;
$count++ foreach(grep { $_ eq $lookfor[0] } @INC);
ok($count == 1, "$lookfor[0] was added to \@INC once");

is_deeply(
    [Directory::relative::to->relative_dir( HgRepository => qw(lib t) )],
    \@lookfor,
    "Directory::relative::to->relative_dir returns the correct directories"
);

$count = 0;
$count++ foreach(grep { $_ eq $lookfor[0] } @INC);
ok($count == 1, "$lookfor[0] was not added to \@INC again");

is(
    scalar(Directory::relative::to->relative_dir( HgRepository => 'lib' )),
    $lookfor[0],
    "in scalar context relative_dir can return a single item"
);

throws_ok {
    scalar(Directory::relative::to->relative_dir( HgRepository => qw(lib t) ))
} qr/Multiple results/, "scalar context, multiple results == EXPLOSM";

is(
    do {
        Directory::relative::to->relative_dir( HgRepository => qw(lib t) );
        "i like pie"
    },
    "i like pie",
    "in void context relative_dir doesn't care"
);

done_testing();
