use Modern::Perl;
use YAML;
use App::Tables ':all';
use Test::More;

sub die_with (&$) {
    my ( $code, $like ) = @_;
    eval { $code->() };
    $@ ~~ $like
}

sub shouldnt_die (&$) {
    my ( $code, $description ) = @_;
    my $r = eval { $code->() };
    my $alive = not $@;
    ok $alive, "didn't die while $description" or do {
        diag "error: $@";
        done_testing;
    };
    $r;
}

sub test_working_case {
    my ( $description, $arguments, $expected ) = @$_;
    local @ARGV = @$arguments;
    my $conf = shouldnt_die {init} $description;
    is_deeply $conf, $expected, $description
        or diag YAML::Dump $conf;
}

test_working_case for

(   [ "parsing from excel to directory "
    ,   [qw< can create from foo.xls to foo >]
    ,   { can => [qw< create >]
        , from => {qw< base foo.xls type xls >}
        , to   => {qw< base foo     type dir >} } ]

,   [ "will and as arguments"
    ,   [qw< can create from foo is xls to foo2 will / >]
    ,   { can => [qw< create >]
        , from => {qw< base foo   type xls >}
        , to   => {qw< base foo2  type dir >} } ]

);

# no more testing overwrite: it's your business after all
# for
# ( [ "don't overwrite (from foo to foo)"
#   , [qw< from foo to foo >]
#   , qr{overwrite} ]
# ) {
#     my ( $description, $arguments, $caught ) = @$_;
#     local @ARGV = @$arguments;
#     ok
#     ( (die_with {init} $caught)
#     , $description)
# }

done_testing;
