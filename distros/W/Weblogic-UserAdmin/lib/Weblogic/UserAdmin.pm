package Weblogic::UserAdmin;

use WWW::Mechanize;
use strict;
use warnings;


=head1 NAME

Weblogic::UserAdmin - Administration Functions For Weblogic 8.1 Automated

=head1 SYNOPSIS

  use Weblogic::UserAdmin;
  
  my $Weblogic = Weblogic::UserAdmin->new({
				console=>"http://$server", 
				port => $port,
				username => "system",
				password => "leper",
			});
  	
  if($Weblogic->user_exist($user)) {
	print "User Already Exists\n";
	exit 1;
  };		

  $Weblogic->user_add({user=>$user, password=>$password});
=cut



BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = '1.03';
    @ISA         = qw(Exporter);
    #Give a hoot don't pollute, do not export more than needed by default
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
}




=head1 DESCRIPTION
	

=head2  my $Weblogic = Weblogic::UserAdmin->new({
				console=>"http://$server", 
				port => $port,
				username => "system",
				password => "leper",
			});

    Create and login to server object specifying host port system username 
    and password. Returns Weblogic::UserAdmin object.
=cut

sub new
{
    my ($class, $parameters) = @_;

    my $self = bless ({}, ref ($class) || $class);
	
	

	
	
	
	
	
	$self->{console} = $parameters->{console}; 
	$self->{port} = $parameters->{port};
    $self->{username} = $parameters->{username} || die "Must Specify Username";
    $self->{password} = $parameters->{password} || die "Must Specify Password";
	
	$self->{browser} = WWW::Mechanize->new();
    
    return $self;
}


=head2 users
	  
    Return an array of all usernames from the server.
=cut

sub users 
{
	
	my $self = shift;
		 
	# login to console
	$self->_loginConsole($self);
	
	
    # Logged in? Jump to Users Page
    my $servernum = substr( $self->{console},length($self->{console})-1, 1 );
    
    $self->_jumpUserPage();	
          
      
    my $list = $self->{browser}->text();
    
       
    $list =~ s/^.*Users\.\.\.Users//;
    $list =~ s/ //g;
    
    my @users=split /\,/, $list;
	
	@{$self->{users}} = @users;
	
	return @users;
	
}

=head2 user_exist('username')

Checks if a user exists 

=cut
sub user_exist 
{
	my ($self, $user) = @_;
	
	
		
	if( !defined $self->{users}) {
		$self->users();
	}


		
	foreach( @{$self->{users}}) {

		if( $_ eq $user ) {
			
			return -1;
		}
	}
	return 0;
	
}

=head2 user_add({user=>$user, password=>$userpassword});

    Add user specifying username and password.

=cut

sub user_add {
	my $self = shift;
	my $parm = shift;
	
	$self->{user} = $parm->{user}; 
	if(!defined $parm->{user}) {
		die ("Must specify user\n");
	}
	if(!defined $parm->{password}) {
		die ("Must specify password\n");
	}
	
	# login to console and jump to user page
	$self->_loginConsole($self);
	$self->_jumpUserPage($self);
	
	# fill in form and submit
	$self->{browser}->form_number(1);
    $self->{browser}->field("Name", $parm->{user});
    $self->{browser}->field("Password", $parm->{password});
    $self->{browser}->field("ConfirmPassword", $parm->{password});
    
    $self->{browser}->click("create");
    
    	
}

=head2 group_list

Lists all groups - returned as an array 

=cut

sub group_list {
	
	my $self = shift;
	my $parm = shift;
	
	# login to console and jump to user page
	$self->_loginConsole($self);
	
	$self->_jumpGroupPage($parm->{group});
	
	my $page = $self->{browser}->text();
	$page =~ s/.*emove\)//g;
	$page =~ s/Add.*//g;

	return split /\s/, $page
}

=head2 user_add_group({user=>$user, group=>$groupname})
  
    Add the specified user to the specified group.

=cut

sub user_add_group {
	
	my $self = shift;
	my $parm = shift;
	
	$self->{user} = $parm->{user}; 
	if(!defined $parm->{user}) {
		die ("Must specify user\n");
	}
	if(!defined $parm->{group}) {
		die ("Must specify group\n");
	}
	
	# login to console and jump to user page
	$self->_loginConsole($self);
	
	$self->_jumpGroupPage($parm->{group});
		
	
	# fill in form and submit
	$self->{browser}->form_number(1);
   
    $self->{browser}->field("AddUsers", $parm->{user});
    $self->{browser}->submit();
    
}

=head2 user_del({user=>$user})
  
    Delete user. USer is automagically removed from group.
=cut
    

sub user_del {
	my $self = shift;
	my $parm = shift;
	
	$self->{user} = $parm->{user}; 
	if(!defined $parm->{user}) {
		die ("Must specify user\n");
	}

	# login to console and jump to user page
	if(!$self->{loggedin}) {
		print "---------\n";
		$self->_loginConsole($self);
	}
	$self->_jumpUserPage($self);

	
	# fill in form and submit
	$self->{browser}->form_number(1);
    $self->{browser}->field("DeleteUsers", $parm->{user});
    
    $self->{browser}->click("delete");
 
    	
}




##
## Jump to the page of users
## used internally
##
sub _jumpUserPage {
	
	my $self = shift;
	
	$self->{browser}->get($self->{console} . ":" . $self->{port} . 
	    "/console/actions/realm/ListRealmEntitiesAction?type=weblogic.management.configuration.User&realm=" .
    	$self->{environment} . "%3AName%3Dwl_default_realm%2CType%3DRealm");
    		
	   
}

##
## Jump to the page of groups
## used internally
##
sub _jumpGroupPage {
	
	my $self = shift;
	my $group = shift;
	
	
	$self->{browser}->get($self->{console} . ":" . $self->{port} . 
	    "/console/actions/realm/EditRealmEntityAction?type=weblogic.management.configuration.Group&realm=" .
    	$self->{environment} . "%3AName%3Dwl_default_realm%2CType%3DRealm&name=" . $group);
    	
   
    
}


##
## Login to the console server
## used internally
##
sub _loginConsole
{
	my $self = shift;
	
	# tell it to get the main page
	$self->{browser}->get($self->{console} .":".$self->{port}. "/console/login/LoginForm.jsp");

    # okay, fill in the box with the name of the
    # module we want to look up
    $self->{browser}->form_number(1);
    $self->{browser}->field("j_username", $self->{username});
    $self->{browser}->field("j_password", $self->{password});
    
    $self->{browser}->submit();
    
    
    
    my $page=$self->{browser}->content();
		
    $page =~ s/\l\n//g;
    $page =~ s/%253AName.*//;
    $page =~ s/.*MBean%3D//;
    
    $self->{environment}= $page;
	$self->{loggedin} = -1;
    
	return $page;
}




sub DESTROY {
	my $self = shift;
	$self->{browser} = undef;
}






    

=head1 AUTHOR

    David Peters
    CPAN ID: DAVIDP
    David.Peters@EssentialEnergy.com.au

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

#################### main pod documentation end ###################


1;
# The preceding line will help the module return a true value

