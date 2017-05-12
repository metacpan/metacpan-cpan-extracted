use strict;
use Test::More tests => 1 + 2;
BEGIN { use_ok('Time::Consts') };

#########################

my $pkg_count;
my $test_import_only = sub {
    my ($str, $imp, $ok) = @_;
    $ok = 1 if not defined $ok;

    my (undef, $file, $line) = caller;

    $pkg_count++;
    my $code = qq{
        package Time::Consts::_::Test::Pkg$pkg_count;
        eval { Time::Consts::->import(\@\$imp); 1 };
        if (\$\@) {
    # line $line "$file"
            ::ok($ok == 0, \$str);
            return;
        }
    };
    $code =~ s/^\s+(# line )/$1/mg;
    eval $code;
    die if $@;
};

$test_import_only->(
    'Importing WRONG',
    [qw/ WRONG /],
    0
);
$test_import_only->(
    'Setting more than one base',
    [qw/ min sec /],
    0
);
