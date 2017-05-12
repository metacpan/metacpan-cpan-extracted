# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl WWW-ConfixxBackup.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use FindBin ();
use Test::More tests => 10;

use WWW::ConfixxBackup::FTP;
ok(1); # If we made it this far, we're ok.

my $backup = WWW::ConfixxBackup::FTP->new();
ok(ref($backup) eq 'WWW::ConfixxBackup::FTP');

my $t_user           = 'username';
my $t_password       = 'password';
my $t_confixx_server = 'confixx_server';
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
my $pwd = $hash{password} || $hash{confixx_password} || $hash{ftp_password} || $t_password;
my $server = $hash{server} || $hash{ftp_server} || $t_ftp_server;

$backup->user($user);
$backup->password($pwd);
$backup->server($server);

ok($backup->user() eq $user);
ok($backup->password eq $pwd);
ok($backup->server eq $server);

SKIP: {
  skip "could not connect to $server",5 if(ref($backup->ftp) ne 'Net::FTP');
  
  ok($backup->login() == 1);
  ok($backup->download() == 1);
  
  my @files = qw(mysql.tar.gz html.tar.gz files.tar.gz);
  for(@files){
    $_ = $FindBin::Bin . '/../' . $_;
  }
  
  ok(-e $files[0]);
  ok(-e $files[1]);
  ok(-e $files[2]);
  
  for(@files){
    unlink $_ if(-e $_);
  }
}

