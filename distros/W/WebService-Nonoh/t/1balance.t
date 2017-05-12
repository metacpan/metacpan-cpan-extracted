use strict;
use warnings;
use Test::More;
use WebService::Nonoh;
use utf8;

my @login = eval { do "$ENV{HOME}/.nonohrc" };
unless (@login >= 3) {
    plan skip_all => 'no config file for testing';
}

plan tests => 9;

my @info;
sub rdr {
    push @info, [@_];
}

my $o = WebService::Nonoh->new(
    service => $login[0],
    user    => $login[1],
    pass    => $login[2],
    printer => \&rdr,
   );

$o->login;
is(@info, 3, '3 infos');
is("@{$info[0]}", WebService::Nonoh::INFO . $" . 'checking with ' . $" . $login[0]);
like("@{$info[1]}", '/^' . WebService::Nonoh::INFO . $" . 'choosing form \\d+$/');
is("@{$info[2]}", WebService::Nonoh::INFO . $" . 'log in ' . $" . $login[1]);
@info = ();
my ($bala, $free) = $o->bala(0);
is(@info, 0, 'no infos');
SKIP: {
    skip 'login failed', 2 if
	$bala eq '' && $free eq '';
    like($bala, qr/^€ \d+\.\d+$/);
    like($free, qr/^\d+ days/);
}
@info = ();
$o->logout;
is(@info, 1, '1 infos');
is("@{$info[0]}", WebService::Nonoh::INFO . $" . 'log out');
