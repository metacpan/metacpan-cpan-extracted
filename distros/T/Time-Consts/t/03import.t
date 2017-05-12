use Test::More tests => 1 + 5;
use strict;
use Symbol ();
BEGIN { use_ok('Time::Consts') };

#########################

my %ctrl_chars = (
    "\cA" => 'A',
    "\cB" => 'B',
    "\cC" => 'C',
    "\cD" => 'D',
    "\cE" => 'E',
    "\cF" => 'F',
    "\cG" => 'G',
    "\cH" => 'H',
    "\cI" => 'I',
    "\cJ" => 'J',
    "\cK" => 'K',
    "\cL" => 'L',
    "\cM" => 'M',
    "\cN" => 'N',
    "\cO" => 'O',
    "\cP" => 'P',
    "\cQ" => 'Q',
    "\cR" => 'R',
    "\cS" => 'S',
    "\cT" => 'T',
    "\cU" => 'U',
    "\cV" => 'V',
    "\cW" => 'W',
    "\cX" => 'X',
    "\cY" => 'Y',
    "\cZ" => 'Z',
);

sub is_automain_var {
    return Symbol::qualify($_[0], '_FOOBAR_') !~ /^_FOOBAR_::/
        || $ctrl_chars{substr($_[0], 0, 1)};
}

sub get_vars {
    my ($pkg) = @_;
    my @r;
    no strict 'refs';
    for my $glob (values %{"$pkg\::"}) {
        my $name = *$glob{NAME};
        next if $name =~ /::\z/ or is_automain_var($name);

        my @types = (
            defined $$glob ? '$' : (),
            *$glob{ARRAY}  ? '@' : (),
            *$glob{HASH}   ? '%' : (),
            defined &$glob ? '&' : (),
        );
        push @types, '*' if not @types;

        push @r => map "$_$name", @types;
    }
    return @r;
}

my $pkg_count = 0;
my $test_diff = sub {
    my ($str, $imp, $new) = @_;

    my (undef, $file, $line) = caller;

    $pkg_count++;
    my $code = qq{
        package Time::Consts::_::Test::Pkg$pkg_count;
        my \@pre = ::get_vars(__PACKAGE__);
        eval { Time::Consts::->import(\@\$imp); 1 };
        if (\$\@) {
    # line $line "$file"
            ::ok(0, \$str);
            return;
        }

        my \@post = ::get_vars(__PACKAGE__);
    # line $line "$file"
        ::ok(
            ::eq_array(
                [ sort \@pre, \@\$new ],
                [ sort \@post ]
            ),
            \$str
        );
    };
    $code =~ s/^\s+(# line )/$1/mg;
    eval $code;
    die if $@;
};

my @all = qw/
    MSEC
    SEC
    MIN
    HOUR
    DAY
    WEEK
/;

$test_diff->(
    'Importing all, but not :ALL',
    \@all,
    [ map "&$_" => @all ]
);
$test_diff->(
    'Importing :ALL',
    [qw/ :ALL /],
    [ map "&$_" => @all ]
);
$test_diff->(
    'Importing :ALL, setting base',
    [qw/ min :ALL /],
    [ map "&$_" => @all ]
);
$test_diff->(
    'Importing SEC',
    [qw/ SEC /],
    [qw/ &SEC /]
);
$test_diff->(
    'Importing SEC, setting base',
    [qw/ min SEC /],
    [qw/ &SEC /]
);
