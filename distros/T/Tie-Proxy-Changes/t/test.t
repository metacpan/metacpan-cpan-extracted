use strict;
use warnings;
use Test::More tests=>17;
eval {
	require Test::NoWarnings;
	Test::NoWarnings->import();
	1;
} or do {
	SKIP: {
		skip "Test::NoWarnings is not installed", 1;
	};
};
require_ok("Tie::Proxy::Changes");

require Tie::Proxy::Changes;

my $newvalue;

#We don't need a real tied thing to test this, just fake one.

sub STORE {
    my $self=shift;
    my $s=shift;
    $newvalue=undef;
    if ($s eq "secret") {
        $newvalue=shift;
        pass("STORE call recived") ;
    }
    else {
        fail("Something went wrong: recived $s instead of the secret phrase");
    }

}

my $x = bless {},"main";

my $t=Tie::Proxy::Changes->new($x,"secret");
$t->{FOO}="Bar";
is_deeply($newvalue,{FOO=>"Bar"},"Without data");
my $s=Tie::Proxy::Changes->new($x,"secret",{test=>1});
if ($s->{test}) {
    $s->{test}=2;
}
is_deeply($newvalue,{test=>2},"With hash data");

my $a=Tie::Proxy::Changes->new($x,"secret",[1,2]);
push @{$a},3;
is_deeply($newvalue,[1,2,3],"With array data");

my $autovivify=Tie::Proxy::Changes->new($x,"secret");
$autovivify->{XXX}->{YYY}->[1]="ZZZ";
is_deeply($newvalue,{XXX=>{YYY=>[undef,"ZZZ"]}},"autovivify");

my $multilevel=Tie::Proxy::Changes->new($x,"secret",{XXX=>{YYY=>[undef,"ZZZ"]}});
$multilevel->{XXX}->{YYY}->[0]="WWW";
is_deeply($newvalue,{XXX=>{YYY=>["WWW","ZZZ"]}},"multilevel");

my $var="";

my $scalar=Tie::Proxy::Changes->new($x,"secret",{foo=>\$var});
${$scalar->{foo}}="BAR";
is($var,"BAR","scalar");

my $hash={R=>"T"};
my $scalarmulti=Tie::Proxy::Changes->new($x,"secret",{foo=>\$hash});
${$scalarmulti->{foo}}->{R}="V";
is_deeply($newvalue,{foo=>\{R=>"V"}},"scalar multilevel");
is_deeply($hash,{R=>"V"},"scalar multilevel changed the reference");
