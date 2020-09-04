package DBStore;
use src::com::zoho::api::authenticator::store::TokenStore;
use src::com::zoho::crm::api::util::Constants;
use Moose;
use DBI;
use Log::Handler;
use Try::Catch;
extends 'TokenStore';
has 'user_name' =>(is => "rw");
has 'port_number' =>(is => "rw");
has 'password' =>(is => "rw");
has 'host' =>(is => "rw");
has 'database_name' =>(is => "rw");

sub new
{
	my $class=shift;
	my $self={
	   'host'=>shift,
        'database_name'=>shift,
	   'user_name'=>shift,
	   'password'=>shift,
	   'port_number'=>shift,
	};
	$self->{user_name}=$self->{user_name} eq ''?$Constants::MYSQL_USER_NAME:$self->{user_name};
	$self->{port_number}=$self->{port_number} eq ''?3306:$self->{port_number};
	$self->{password}=$self->{password} eq ''?'':$self->{password};
	$self->{host}=$self->{host} eq ''?$Constants::MYSQL_HOST:$self->{host};
	$self->{database_name}=$self->{database_name} eq ''?$Constants::MYSQL_DATABASE_NAME:$self->{database_name};
	bless $self,$class;
	return $self;
}

sub get_connection{
   my $self=shift;
   try{
   my $source='dbi:mysql:dbname='.$self->{database_name}.';host='.$self->{host}.';port='.$self->{port_number};
   my $conn=DBI->connect($source,$self->{user_name},$self->{password});
   return $conn;
}catch{
	my $e=shift;
	my $log=Log::Handler->get_logger("SDKLogger");
	$log->error($e->to_string());
	die;
}
}

sub get_token{
   my ($self,$user,$token)=@_;
   try{
   my $con=$self->get_connection();
   my $query=$self->construct_dbquery($user,$token,0);
   my $sql=$con->prepare($query);
   my $result=$sql->execute();
   if ($result !=0)
   {
   my ($id, $email, $client_id, $refresh_token, $access_token, $grant_token, $expiry_time) = $sql->fetchrow_array();
   $token->set_access_token($access_token);
   $token->set_grant_token($grant_token);
   $token->set_expires_in($expiry_time);
   return $token;
   }
   return undef;
   $con->disconnect();
}
catch{
	my $e=shift;
	my $log = Log::Handler->get_logger("SDKLogger");
	$log->error($e->to_string());
	die;
}
}

sub save_token{
    my ($self,$user,$token)=@_;
    try{
    $self->delete_token($user,$token);
    my $con=$self->get_connection();
    my $query = 'INSERT INTO oauthtoken (user_mail,client_id,refresh_token,access_token,grant_token,expiry_time) VALUES (\'' . $user->get_email() . '\',' . '\'' . $token->get_client_id() . '\',' . '\'' . $token->get_refresh_token() . '\',' . '\'' . $token->get_access_token() . '\',' . '\'' . $token->get_grant_token() . '\',' . '\'' . $token->get_expires_in() . '\')';
    my $sql=$con->prepare($query);
    my $result=$sql->execute();
    $con->disconnect();
 }
 catch{
	 my $e=shift;
 	my $log=Log::Handler->get_logger("SDKLogger");
 	$log->error($e->to_string());
 	die;
 }
}

sub delete_token{
   my ($self,$user,$token)=@_;
   try{
   my $con=$self->get_connection();
   my $query=$self->construct_dbquery($user,$token,1);
   my $sql=$con->prepare($query);
   my $result=$sql->execute();
   $con->disconnect();
}
catch{
	my $e=shift;
	my $log=Log::Handler->get_logger("SDKLogger");
	$log->error($e->to_string());
	die;
}
}

sub construct_dbquery{
   my ($self,$user,$token,$is_delete)=@_;
   my $query= $is_delete? 'delete from ': 'select * from ';
   $query=$query.'oauthtoken '.'where user_mail =\''.$user->get_email().'\' and client_id=\''.$token->get_client_id().'\' and ';
   if ($token->get_grant_token() eq '')
   {
     $query=$query.'refresh_token =\''.$token->get_refresh_token().'\'';
   }
   else
   {
      $query=$query.'grant_token =\''.$token->get_grant_token().'\'';
   }
   return $query;

}

=head1 NAME

com::zoho::api::authenticator::store::DBStore - This class stores the user token details to the MySQL DataBase

=head1 DESCRIPTION

=head2 METHODS

=over 4

=item C<new>

Creates an DBStore class instance with the specified parameters

Param host  : A String containing the DataBase host name

Param database_name : A String containing the DataBase name

Param user_name : A String containing the DataBase user name

Param password : A String containing the DataBase password

Param port_number : A String containing the DataBase port number

=back

=cut
1;
