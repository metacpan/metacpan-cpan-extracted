package Win32::AD::User; 
  use strict;
  use Win32::OLE 'in';
  $Win32::OLE::Warn = 3;
  our $VERSION = '0.04';

######################################################################
sub new{
  my $class = shift;
  my ($connect_string,$username) = @_;
  warn "Win32::AD::User -- Warning ADS_CONNECT_STRING not defined.\n"  if(not defined $connect_string);
  warn "Win32::AD::User -- Warning USER_REFERENCE_STRING not defined.\n" if(not defined $username);
  bless { _connect_string => $connect_string,
          _username       => $username,
          _LDAPAdsPath    => ($connect_string =~ /LDAP/) ? "CN=".$username.",".(split /\//,$connect_string)[3] : undef,
          _LDAPAdsSvr     => ($connect_string =~ /LDAP/) ? (split /\//,$connect_string)[2] : undef,
          _WinNTAdsPath   => ($connect_string =~ /WinNT/) ? "WinNT://" . (split /\//,$connect_string)[2] . "/$username,user" : undef,
          _WinNTDomain    => ($connect_string =~ /WinNT/) ? (split /\//,$connect_string)[2] : (split /\./, (split /\//,$connect_string)[2])[0],
          _user_ref       => undef}, $class; 
}

######################################################################
sub print_me{ 
  my $self = shift; print "$_: $self->{$_}\n" for (keys %$self)}

######################################################################
sub create_new{
  my $self = shift;
  my $server = Win32::OLE->GetObject($self->{_connect_string});
  my $user;

  if ($self->_connect_type eq "LDAP"){
    $user = $server->Create("user","cn=".$self->{_username});
    $user->{samAccountName}=$self->{_username};
    $user->SetInfo();
  }
  else{
    $user = $server->Create("user",$self->{_username});
    $user->SetInfo();
  }#fi
  $self->{_user_ref} = $user;
}

######################################################################
sub get_info{
  my $self = shift;
  my $user;

  if ($self->_connect_type eq "LDAP"){
    $user = Win32::OLE->GetObject( join "/", ("LDAP:/",$self->{_LDAPAdsSvr},$self->{_LDAPAdsPath}) );
  }
  else{
    $user = Win32::OLE->GetObject($self->{_WinNTAdsPath}); 
  }#fi
  $self->{_user_ref} = $user;
}

######################################################################
sub delete{
  my $self = shift;
  my $server = Win32::OLE->GetObject($self->{_connect_string});
  if ($self->_connect_type eq "LDAP"){
    $server->Delete("user","cn=".$self->{_username});
  }
  else{
    $server->Delete("user",$self->{_username}); 
  }#fi
  $self->{_user_ref} = undef;
}

######################################################################
sub set_password{
  my $self = shift;
  my ($new_password) = @_;
  $self->{_user_ref}->SetPassword($new_password);
}

######################################################################
sub lock{
  my $self = shift;
  $self->{_user_ref}->{'AccountDisabled'} = '1';
  $self->{_user_ref}->SetInfo();
}

######################################################################
sub un_lock{
  my $self = shift;
  $self->{_user_ref}->{'AccountDisabled'} = '0';
  $self->{_user_ref}->SetInfo();
}

######################################################################
sub is_locked{
  my $self = shift;
  $self->{_user_ref}->{'AccountDisabled'};
}

######################################################################
sub set_properties{
  my $self = shift;
  my ($properties) = @_;
  for my $i (keys %$properties){
    $self->{_user_ref}->{$i} = $properties->{$i};
  }#rof
  $self->{_user_ref}->SetInfo();
}

######################################################################
sub set_property{
  my $self = shift;
  my ($property,$value) = @_;
  $self->{_user_ref}->{$property} = $value;
  $self->{_user_ref}->SetInfo();
}

######################################################################
sub get_properties{
  my $self = shift;
  my @props = @_;
  my %props;
  $props{$_}=$self->{_user_ref}->{$_} for (@props);
  %props;
}

######################################################################
sub get_property{
  my $self = shift;
  my ($property) = @_;
  $self->{_user_ref}->{$property};
}

######################################################################
sub _connect_type{
  my $self = shift;
  ($self->{_connect_string} =~ /^LDAP/) ? return "LDAP" : return "WinNT";
}

######################################################################
sub rename{
 ## Inspiration: 
 # http://www.rallenhome.com/books/adcookbook/src/06.06-rename_user.pls.txt
  my $self = shift;
  my ($new_name) = @_;
  my $old_name = $self->{_username};
  my $server = Win32::OLE->GetObject($self->{_connect_string});
  
  if ($self->_connect_type eq "LDAP"){
    $self->set_property("samAccountName",$new_name);
    $server->MoveHere( join ("/", ("LDAP:/",$self->{_LDAPAdsSvr},$self->{_LDAPAdsPath})),"cn=".$new_name);
    for my $key (keys %$self){
      if ($self->{$key} =~ /$old_name/){
        $self->{$key} =~ s/$old_name/$new_name/g
      }#fi 
    }#rof
    $self->get_info();
  }
  else{
    warn "Win32::AD::User -- The 'rename' function is not available when using \n",
         "a WinNT:// ADsPath... use a LDAP:// ADsPath.\n";
  }#fi
}

######################################################################
sub move{
 #Inspiration:
 # http://www.rallenhome.com/books/adcookbook/src/08.04-move_computer.pls.txt
  my $self = shift;
  my ($new_connect) = @_;

  if ($self->_connect_type eq "LDAP"){
    my $server = Win32::OLE->GetObject($new_connect);
    $server->MoveHere($self->{_user_ref}->{'ADsPath'},$self->{_user_ref}->{'Name'});
    $self->{_connect_string} = $new_connect;
    $self->{_LDAPAdsPath}    = "CN=".$self->{_username}.",".(split /\//,$self->{_connect_string})[3];
    $self->{_LDAPAdsSvr}     = (split /\//,$self->{_connect_string})[2];
    $self->get_info();
  }
  else{
    warn "Win32::AD::User -- The 'move' function is not available when using \n",
         "a WinNT:// ADsPath... use a LDAP:// ADsPath.\n";
  }#fi
  
}

######################################################################
sub get_groups{
  my $self = shift;
  my @grp;
  push(@grp, $_->{Name}) for (in $self->{_user_ref}->{Groups});
@grp;
}

######################################################################
sub add_to_group{
 #Inspiration & Reference:
 # http://www.rallenhome.com/books/adcookbook/src/06.15-set_primary_group.pls.txt
 # http://www.rallenhome.com/books/adcookbook/src/07.04-add_group_member.pls.txt
  my $self = shift;
  my ($group_ads_path) = @_;
  $group_ads_path = "WinNT://".$self->{_WinNTDomain}."/$group_ads_path,group" if ($group_ads_path !~ /\:\/\//);
  my $group = Win32::OLE->GetObject($group_ads_path);

  if ($self->_connect_type eq "LDAP"){
    if($group_ads_path =~ /WinNT:/){
      my $wintmp = "WinNT://".$self->{_WinNTDomain}."/".$self->{_username}.",user";
      $group->Add($wintmp);
    }
    else{
      $group->Add("LDAP://".$self->{_LDAPAdsPath});
    }#fi
    $group->SetInfo();
    $self->get_info();
  }
  else{
    $group->Add($self->{_WinNTAdsPath});
    $group->SetInfo();
  }#fi
}

######################################################################
sub remove_from_group{
 #Inspiration & Reference:
 # http://www.rallenhome.com/books/adcookbook/src/06.15-set_primary_group.pls.txt
 # http://www.rallenhome.com/books/adcookbook/src/07.04-add_group_member.pls.txt
  my $self = shift;
  my ($group_ads_path) = @_;
  $group_ads_path = "WinNT://".$self->{_WinNTDomain}."/$group_ads_path,group" if ($group_ads_path !~ /\:\/\//);
  my $group = Win32::OLE->GetObject($group_ads_path);
  
  if ($self->_connect_type eq "LDAP"){
    if($group_ads_path =~ /WinNT:/){
      my $wintmp = "WinNT://".$self->{_WinNTDomain}."/".$self->{_username}.",user";
      $group->Remove($wintmp);
    }
    else{
      $group->Remove("LDAP://".$self->{_LDAPAdsPath});
    }#fi
    $group->SetInfo();
    $self->get_info();
  }
  else{
    $group->Remove($self->{_WinNTAdsPath});
    $group->SetInfo();
  }#fi
}

######################################################################
sub get_ou_member_list{
 #Inspiration & Reference:
 # http://www.rallenhome.com/books/adcookbook/src/05.03-enumerate_children.pls.txt
  my $self = shift;
  my ($search_mask) = @_;
  my @members;
  my $parent_ou = Win32::OLE->GetObject($self->{_connect_string});
  if ($self->_connect_type eq "LDAP"){
    for my $child (in $parent_ou) {
      push(@members, $child->Name) if (defined $search_mask && $child->Name =~ /$search_mask/);
      push(@members, $child->Name) if (not defined $search_mask);
    }#rof 
  }
  else{
    warn "Win32::AD::User - The 'get_ou_member_list' function is not available when using \n",
         "a WinNT:// ADsPath... use a LDAP:// ADsPath.\n";
  }#fi
@members;
}

1;

__END__

=head1 NAME

Win32::AD::User - provides routines for Active Directory user administration.

=head1 SYNOPSIS

 use Win32::AD::User;

 $user = AdUser->new( ADS_CONNECT_STRING, USER_REFERENCE_STRING );

 $user->print_me();

 $user->create_new();

 $user->get_info();

 $user->lock();

 $user->un_lock();

 $user->is_locked();

 $user->set_properties( PROPERTY_HASH );

 $user->set_property( ADS_PROPERTY_NAME, PROPERTY_VALUE );

 $user->get_properties( ADS_PROPERTY_LIST );
 
 $user->get_property( ADS_PROPERTY_NAME );
 
 $user->delete();

 $user->set_password( PASSWORD_STRING );

 $user->rename( USER_REFERENCE_STRING );

 $user->move( ADS_CONNECT_STRING );

 $user->get_groups();

 $user->add_to_group( ADS_GROUP_STRING );

 $user->remove_from_group( ADS_GROUP_STRING );

 $user->get_ou_member_list( SEARCH_MASK );

=head1 ABSTRACT

Administer user in Active Directory using either LDAP or WinNT AdsPath.

=head1 DESCRIPTION

Connect to an Active Directory (AD) Server and Administer Users. Below
there is more information on each of the various functions of an
Win32::AD::User object.

=head2 new( ADS_CONNECT_STRING, USER_REFERENCE_STRING );

The new function returns an Win32::AD::User object. The function
takes 2 scalars; ADS_CONNECT_STRING and USER_REFERENCE_STRING. The
ADS_CONNECT_STRING can be a valid LDAP or WinNT ADsPath string. More
information about a valid ADsPath String is available via the
Win32::OLE documentation. The USER_REFERENCE_STRING is the username
of the account you would like to either create or modify.

=head2 print_me();

The print_me function will print the value of all object properties.

=head2 create_new();

The 'create_new' function will create a new user object on the AD
Server.  The 'new' function does not actualy connect to the AD
Server either 'create_new or 'get_info' must be used to connect to
the AD Server properly.

=head2 get_info();

The 'get_info' function will get the user information from the AD
Server.  The 'new' function does not actualy connect to the AD
Server either 'create_new or 'get_info' must be used to connect to
the AD Server properly.

=head2 lock(); 

The 'lock' function will lock a user account.

=head2 un_lock();

The 'un_lock' function will unlock a user account.

=head2 is_locked();

The 'is_locked' function returns '0' if the account is not locked
and '1' if it is locked.

=head2 set_properties( PROPERTY_HASH );

The 'set_properties' function will set all properties sent in as
PROPERTY_HASH. PROPERTY_HASH is a hash where every key is a valid
ADS_PROPERTY_NAME and that key's value is a valid PROPERTY_VALUE.
Both of which are defined in the 'set_property' function.

=head2 set_property( ADS_PROPERTY_NAME, PROPERTY_VALUE );

The 'set_property' function will allow you to set any user property.
The function take two scalars ADS_PROPERTY_NAME, and PROPERTY_VALUE.
ADS_PROPERTY_NAME is the name of the property as defined in the ADSI
Specification. The ADSI Browser by Toby Everett is a great tool for
figuring out which ADS_PROPERTY_NAME you want to use. The
PROPERTY_VALUE is what you would like to store in AD.

=head2 get_properties( ADS_PROPERTY_LIST );

The 'get_properties' function will return a hash of elements where
every key is an element from the ADS_PROPERTY_LIST that is sent is
to the funciton as the only argument. The ADS_PROPERTY_LIST is a
list of ADS_PROPERTY_NAME elements, as defined in the 'set_property'
function description.

=head2 get_property( ADS_PROPERTY_NAME );

The 'get_property' function returns a scalar that is the value of
the ADS_PROPERTY_NAME which is sent in as an argument. The
ADS_PROPERTY_NAME is defined in the 'set_property' function
description.

=head2 delete();

The 'delete' function will delete the user object from the AD
Server.  Note that this will not destroy any other data in the
Win32::AD::User object, you can recreate user account (without any
of the previous attiributes) by invoking the 'create_new' function
after using the 'delete' function.

=head2 set_password( PASSWORD_STRING );

The 'set_password' function will set the password of the user. This
function requires one scalar; PASSWORD_STRING. This string is what
will become the user's password.

=head2 rename( USER_REFERENCE_STRING );

The 'rename' function will change the user's name from whatever it
is to the value supplied as USER_REFERENCE_STRING.
USER_REFERENCE_STRING is defined in the 'new' function description.

=head2 move( ADS_CONNECT_STRING );

The 'move' function will change the user's location in AD. The
function requires an ADS_CONNECT_STRING. The ADS_CONNECT_STRING is
defined in the 'new' function description.

=head2 get_groups();

The 'get_groups' function will return a list of groups of which the
user is a member.

=head2 add_to_group( ADS_GROUP_STRING );

The 'add_to_group' function will add the user to the group specified
in the ADS_GROUP_STRING.  The ADS_GROUP_STRING is an
ADS_CONNECT_STRING for a group object. The ADS_CONNECT_STRING is
defined in the 'new' function description.  If a full ADS_GROUP_STRING
is given it will attempt to build a WinNT:// ADS_CONNECT_STRING for
your user and group (based on the string supplied) to perform the
user's addition to the group.

=head2 remove_from_group( ADS_GROUP_STRING );

The 'remove_from_group' function will remove the user from the group
specified in the ADS_GROUP_STRING.  The ADS_GROUP_STRING is an
ADS_CONNECT_STRING for a group object. The ADS_CONNECT_STRING is
defined in the 'new' function description. If a full ADS_GROUP_STRING
is given it will attempt to build a WinNT:// ADS_CONNECT_STRING for
your user and group (based on the string supplied) to perform the
user's removal from the group.

=head2 get_ou_member_list( SEARCH_MASK );

The 'get_ou_member_list' function will return a list of objects in the
OU given as your ADS_CONNECT_STRING. Note, this will only work for
an LDAP:// ADS_CONNECT_STRING. SEARCH_MASK refers to a string that
will be use to filter the list of objects returned. For example if you
only are intrested in CN objects use the mask "CN=". The SEARCH_MASK
is case sensitive.

=head1 AUTHOR

Aaron Thompson <thompson@cns.uni.edu>

=head1 COPYRIGHT

Copyright 2003, Aaron Thompson.  All rights reserved.

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

Win32::OLE; ADSI Browser; perl;

=cut
