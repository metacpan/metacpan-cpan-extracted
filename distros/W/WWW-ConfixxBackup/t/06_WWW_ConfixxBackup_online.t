# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl WWW-ConfixxBackup.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 7;
use FindBin ();

use WWW::ConfixxBackup;
ok(1); # If we made it this far, we're ok.

my $backup = WWW::ConfixxBackup->new();
ok(ref($backup) eq 'WWW::ConfixxBackup');

my $t_user           = 'username';
my $t_password       = 'password';
my $t_confixx_server = 'http://confixx_server';
my $t_ftp_server     = 'ftp_server';

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
my $password = $hash{password} || $hash{confixx_password} || $hash{ftp_password} || $t_password;
my $confixx_server = $hash{server} || $hash{confixx_server} || $t_confixx_server;
my $ftp_server = $hash{server} || $hash{ftp_server} || $t_ftp_server;

$backup->user($user);
ok($backup->user eq $user);

$backup->password($password);
ok($backup->password eq $password);

$backup->confixx_server($confixx_server);
ok($backup->confixx_server eq $confixx_server);

$backup->ftp_server($ftp_server);
ok($backup->ftp_server eq $ftp_server);


SKIP:{
  skip "don't test the default value", 1 if $confixx_server eq $t_confixx_server;
  skip "no internet connection",1 unless($backup->login);
  
  ok($backup->login == 1);
}
