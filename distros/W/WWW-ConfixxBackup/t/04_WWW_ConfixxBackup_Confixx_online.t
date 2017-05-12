# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl WWW-ConfixxBackup.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 7;
use FindBin ();

use_ok('WWW::ConfixxBackup::Confixx');

my $backup = WWW::ConfixxBackup::Confixx->new();
isa_ok($backup,'WWW::ConfixxBackup::Confixx');


my $t_user           = 'username';
my $t_password       = 'password';
my $t_server         = 'confixx_server';

my %hash;
if(open(my $fh,"<",$FindBin::Bin . '/userfile.txt')){
  while(my $line = <$fh>){
    chomp $line;
    next if($line =~ /^\s*$/);
    my ($key,$value) = split(/=/,$line,2);
    $hash{$key} = $value;
  }
  close $fh;
}

my $user = $hash{user} || $hash{confixx_user} || $hash{ftp_user} || $t_user;
my $pwd = $hash{password} || $hash{confixx_password} || $hash{ftp_password} || $t_password;
my $server = $hash{server} || $hash{confixx_server} || $t_server;

$backup->user($user);
$backup->password($pwd);
$backup->server($server);

ok($backup->user eq $user);
ok($backup->password eq $pwd);
ok($backup->server eq $server);

SKIP: {
  skip "could not connect to $server",2 if($server eq $t_server);
  
  ok($backup->login() == 1);
  ok($backup->backup() == 1);
}
