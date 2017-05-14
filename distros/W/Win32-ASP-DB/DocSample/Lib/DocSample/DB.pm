use Win32::ASP::DB;

package DocSample::DB;

@ISA = ('Win32::ASP::DB');

use strict vars;

$main::TheDB = DocSample::DB->new;

sub new {
  my $class = shift;

  my $user_info = Win32::ASP::Get('user_info');
  $user_info or Win32::ASP::Redirect('session_expired.asp', Win32::ASP::CreatePassURLPair());

  my $self = $class->SUPER::new('Microsoft.Jet.OLEDB.4.0', 'Data Source=W:\\InetPub\\wwwroot\\DocSample\\_database\\DocSample.mdb');
  return $self;
}

sub retrieve_user_info {
  my $self = shift;

  my $user_info = Win32::ASP::Get('user_info');

  my $username = $user_info->{username};

  my $results = $self->exec_sql("SELECT Role FROM Users WHERE Username = '$username'", error_no_records => 1);

  $user_info->{role} = $results->Fields->Item("Role")->Value;

  Win32::ASP::Set('user_info', $user_info);
}

1;
