package FileStore;
use strict;
use warnings;
use Try::Catch;
use Log::Handler;
use Moose;
use src::com::zoho::api::authenticator::store::TokenStore;


extends 'TokenStore';

sub new
{
  my ($class, $args) = @_;
  my $self = {
    #can contain all args of that class - dynamic constructor - take values during object init
    file_path => $args->{file_path}
  };

  if(-e $self->{file_path})
  {
    #checks whether file is present
    if(-z $self->{file_path})
    {
      # checks whether file is empty
     open(my $data,'>',$self->{file_path}) or die;
     print $data "user_email,client_id,refresh_token,access_token,grant_token,expiry_time";
     close($data);
    }
  }
  else
  {
    open(my $data,'>',$self->{file_path}) or die;
    print $data "user_email,client_id,refresh_token,access_token,grant_token,expiry_time";
    close($data);
  }

  bless $self, $class;
}

sub get_token
{
  my ($self, $user, $token) = @_;

  my $file = $self->{file_path};

  my $check = 0;

  try
  {
    open(my $data, '<', $file) or die;

    while (my $line = <$data>)
    {
      # body...
      my @words = split ",", $line;

      my $arrSize = @words;

      my $tokenCheck= (defined($token->get_grant_token()))? $token->get_grant_token eq $words[4] : $token->get_refresh_token eq $words[2];

      if ($self->check_token_exists($user, $token, \@words))
      {
        $check=1;

        $token->set_refresh_token($words[2]);

        $token->set_access_token($words[3]);

        $token->set_expires_in($words[5]);
      }
    }

    close($data);

    if ($check)
    {
      return $token;
    }
    else
    {
      return undef;
    }
  }
  catch
  {
    my $e = shift;

    my $log=Log::Handler->get_logger("SDKLogger");

    $log->error($e->to_string());

    die;
  }
}

sub save_token
{

  my ($self, $user, $token) = @_;

  my $file = $self->{file_path};

  $self->delete_token($user, $token);

  try
  {
    open(my $data, '>>', $file) or die;

    print $data "\n" . $user->get_email().','.$token->get_client_id().','.$token->get_refresh_token().','.$token->get_access_token().','.$token->get_grant_token().','.$token->get_expires_in();

    close($data);
  }
  catch
  {
    my $e=shift;

    my $log=Log::Handler->get_logger("SDKLogger");

    $log->error($e->to_string());

    die;
  }
}

sub delete_token
{
    my ($self, $user, $token) = @_;

    my $file = $self->{file_path};

    try
    {
      open(my $data, '<', $file);

      my @LINES = <$data>;

      close($data);

      open($data, '>', $file);

      my $arrSize = @LINES;

      for(my $a = 0; $a < $arrSize; $a = $a + 1 )
      {
        my $LINE = $LINES[$a];

        my @words = split ",", $LINE;

        unless($self->check_token_exists($user, $token, \@words))
        {
          print $data $LINE;

          print $data "\n";
        }
      }
      close($data);
    }
    catch
    {
      my $e=shift;

      my $log=Log::Handler->get_logger("SDKLogger");

      $log->error($e->to_string());

      die;
    }
}

sub check_token_exists
{
  my($self, $user, $token, $row) = @_;

  my @row = @$row;

  my $client_id = $token->get_client_id();

  my $email = $user->get_email();

  my $grant_token = $token->get_grant_token();

  my $refresh_token = $token->get_refresh_token();

  my $token_check = (defined($grant_token))? ($grant_token eq $row[4]) : ($refresh_token eq $row[2]);

  if(($row[0] eq $email) && ($row[1] eq $client_id) && $token_check)
  {
    return 1;
  }

  return 0;
}

=head1 NAME

com::zoho::api::authenticator::store::FileStore - This class stores the user token details to the file

=head1 DESCRIPTION

=head2 METHODS

=over 4

=item C<new>

Creates an FileStore class instance with the specified parameters

Param file_path : A String containing the absolute file path to store tokens

=back

=cut
1;
