use Cwd;
my $cwd = Cwd::cwd;
$ENV{PATH} = "$cwd/bin:$ENV{PATH}";

exec "$cwd/t/a.tml";
