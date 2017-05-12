package Win32::WindowsMedia;

use warnings;
use strict;
use Win32::OLE qw( in with HRESULT );
use Win32::OLE::Const "Windows Media Services Server Object Model and Plugin 9.0 Type Library";
use Win32::WindowsMedia::BaseVariables;

=head1 NAME

Win32::WindowsMedia - Base Module for Provisiong and control for Windows Media Services

=head1 VERSION

Version 0.258

=cut

our $VERSION = '0.258';

=head1 SYNOPSIS

This is a module to control Windows Media services for a Windows 2003/2008 server. This is a 
complete change to the pre-alpha releases (0.15 and 0.16) as all functions are now in one module.
To create a Windows Media control instance do the following

    use Win32::WindowsMedia;
    use strict;

    my $main =new Win32::WindowsMedia;

    my $create_server = $main->Server_Create("127.0.0.1");

The $create_server variable should return 1 on success or 0 on failure. You can then call the other
functions against the main object, an example would be

    my $publishing_point = $main->Publishing_Point_Create( "127.0.0.1","andrew", "push:*", "broadcast" );

If you can create objects for multiple addresses (need to be in the same domain) you call the functions
against the specific IPs. Most uses of the module will be against the local instance of Windows Media which
should be 127.0.0.1

=head1 Server FUNCTIONS

=item C<< Server_Create >>

This function create an instance to communicate with the Windows Media Server running. You
can specify an IP address, however 99% of the time it should be one of the local interface
IPs or localhost(127.0.0.1). It does not matter which IP is used as Windows Media services
is not bound to a specific IP.

    Server_Create( "<IP>" );

Example of Use

    my $result = $main->Server_Create("127.0.0.1");

On success $result will return 1, on failure 0. If there is a failure error is set and can be retrieved.

=item C<< Server_Destroy >>

This function destroys an instance created to communicate with the Windows Media Server running. You
must specify the IP address used to create the instance.

    Server_Destroy( "<IP>" );

Example of Use

    my $result = $main->Server_Destroy("127.0.0.1");

On success $result will return 1, on failure 0. If there is a failure, error is set and can be retrieved.

=head1 Control FUNCTIONS

=item C<< Publishing_Point_Create >>

This function creates a new publishing point on the Windows Media server specified. You need to specify
the publishing point, the URL to use ( see example ) and also the type ( again see example ). This function
is called through eval ( do not worry if you have no idea what this means ). If the URL specified is invalid
Windows Media services will attempt to resolve it and return an invalid callback via OLE. This causes any 
scripts to stop without warning thus eval catches this nicely.

    Publishing_Point_Create( "<IP>", "<publishing point name>", "<URL>", "<Type>" );

    Publishing point name - Can be any alphanumeric and _ characters
    URL - can be one of push:* , or http://<ip>/<pub point> for relay
    Type - Can be one of OnDemand, Broadcast, CacheProxyOnDemand, CacheProxyBroadcast

Example of Use

    my $result = $main->Publishing_Point_Create("127.0.0.1","andrew","push:*","broadcast");

On success $result will return 1, on failure 0. If there is a failure, error is set and can be retrieved.

=item C<< Publishing_Point_Remove >>

This function removes the publishing point name specified. You need to specify the IP and the publishing
point name. 

    Publishing_Point_Remove( "<IP>", "<publishing point name>" );

    my $result = $main->Publishing_Point_Remove("127.0.0.1","andrew");

On success $result will return 1, on failure 0. If there is a failure, error is set and can be retrieved.

=item C<< Publishing_Point_Start >>

This function is only required if the publishing point in question is not using Push and auto start is off.

    Publishing_Point_Start( "<IP>", "<publishing point name>" );

Example of Use

    my $result = $main->Publishing_Point_Start("127.0.0.1","andrew");

On success $result will return 1, on failure 0. If there is a failure, error is set and can be retrieved.

=item C<< Publishing_Point_Stop >>

This can be used on all types of publishing points and causes the source to be disconnected. If auto start
is configured on the publishing point will not stop for long, max 30 seconds. If auto start on client
connection it will be stopped until a client reconnects.

    Publishing_Point_Stop( "<IP>", "<publishing point name>" );

Example of Use

    my $result = $main->Publishing_Point_Stop("127.0.0.1","andrew");

On success $result will return 1, on failure 0. If there is a failure, error is set and can be retrieved.

=item C<< Publishing_Point_List >>

This function returns an array of the currently provisioned publishing point names. You *may* find at least
two which do not show up in the Windows Media adminitration panel. These are for proxy and cache use and
should be ignored. You can optionally specify a partial match name which will then only return those
publishing points that match.

    Publishing_Point_List( "<IP>", "<partial match>" );

Example of Use

    my @publishing_point = $main->Publishing_Point_List( "127.0.0.1", "*");

The above will return all publishing points defined.

=item C<< Publishing_Point_Authorization_ACL_Add >>

This function adds a username to the authorization list allowed to connect to this stream. The defaults
are dependent on the Parent configuration, but you can change them at this level. In order to make a change
you must first delete a user, you can not add them again ( their previous entry will remain so adding them
again with a different mask will not have any effect ).

    Publishing_Point_Authorization_ACL_Add ("<IP>","<publishing point name>","<pointer to hash of users");

The <hash of users> is made up of a username as the key and their mask being comma seperated entries made
up from UserAccessSettings function. The allowable entries are

    ACCESSINIT
    ReadDeny
    WriteDeny
    CreateDeny
    AllDeny
    UNKNOWN
    ReadAllow
    WriteAllow
    CreateAllow
    AllAllow

    To build an entry use the following

    my %user_list = (
		'Username' 	=> 'ReadAllow,WriteAllow'
		'username2'	=> 'ReadAllow'
			);

    This would allow the user 'Username' to read and write to the stream ( so push ), and also allow user 'username2' to
read from the stream ( so listen ).

    You must remember the server must have these usernames configured, or accessable otherwise it will fail (silently). You
can specify a username in a domain, such if the server is configured in a domain, and do to so requires you to put the domain
before the username. To change 'Username' to be part of a domain it should be changed to 'domain\\Username' where 'domain'
is the name of the domain the user is in. Note the double \ is required.

    There is a SPECIAL user called 'Everyone' ( well it is a user defined on the server by default ) and is configured so
that if added to the publishing point it allows anyone to listen. If you do not want to use username/password for encoders
to connect you need to remove and then re-add Everyone with permissions of ReadAllow,WriteAllow.

Example of Use

    my %user_list = ( 'Everyone'	=> 'ReadAllow,WriteAllow');
    $main->Publishing_Point_Authorization_ACL_Remove( "127.0.0.1", "publishing_point", \%user_list);
    $main->Publishing_Point_Authorization_ACL_Add( "127.0.0.1", "publishing_point", \%user_list);

    This will remove the username Everyone from the ACL then add it back in with read and write permissions.

=item C<< Publishing_Point_Authorization_ACL_Remove >>

This function removes a username from the authorization list allowed to connect to this stream. The defaults
are dependent on the Parent configuration, but you can change them at this level. 

    Publishing_Point_Authorization_ACL_Remove ("<IP>","<publishing point name>","<pointer to hash of users");

Example of Use

    my %user_list = ( 'Everyone'        => 'ReadAllow,WriteAllow');
    $main->Publishing_Point_Authorization_ACL_Remove( "127.0.0.1", "publishing_point", \%user_list);

=item C<< Publishing_Point_Authorization_ACL_List >>

This function lists the usernames and their permissions currently defined on the publishing point. The function
requires pointer to a hash which is populated with the username as the key and the value is the numerical value
of the access mask.

    Publishing_Point_Authorization_ACL_List ("<IP>","<publishing point name>","<pointer to hash");

Example of Use

    my %user_list;
    $main->Publishing_Point_Authorization_ACL_List( "127.0.0.1", "publishing_point", \%user_list);

=item C<< Publishing_Point_Log_Set >>

This function sets up the logging facility for the publishing point named. You should only set the variables
you need and leave the others as default.

    Publishing_Point_Log_Set( "<IP>","<publishing point name>","<pointer to hash for template");

Example of Use

    my %log_settings =
		(
		'Template'	=> 'D:\Andrew\logs-<Y><m><d>.log',
		'Cycle'		=> 'Month',
		'UseLocalTime'	=> 'Yes',
		'UseBuffering'	=> 'Yes',
		'UseUnicode'	=> 'Yes',
		'V4Compat'	=> 'No',
		'MaxSize'	=> 0,
		'RoleFilter'	=> 'SHAMROCK',
		'LoggedEvents'	=> 'Player,Local'
		);

    $main->Publishing_Point_Log_Set("127.0.0.1","publishing_point",\%log_settings);

    Cycle can be one of None Size Month Week Day Hour

    MaxSize is in Mbytes and only used when Cycle is Size

    LoggedEvents can be None Player Distribution Local Remote Filter seperated by a comma (,)

    You can also use FreeSpaceQuota. This has a default of 10, which means 10Mbytes. The attribute means
    how much free space should be available for logging to work.

=item C<< Publishing_Point_Log_Enable >>

This function turns on the logging plugin. If you make changes using Publishing_Point_Log_Set you need
to call Publishing_Point_Log_Disable and then Publishing_Point_Log_Enable for them to take effect.

    Publishing_Point_Log_Enable("<IP>","<publishing point name>");

Example of Use

    $main->Publishing_Point_Log_Enable("127.0.0.1","publishing_point");

=item C<< Publishing_Point_Log_Disable >>

This function turns off the logging plugin. If you make changes using Publishing_Point_Log_Set you need
to call Publishing_Point_Log_Disable and then Publishing_Point_Log_Enable for them to take effect.

    Publishing_Point_Log_Disable("<IP>","<publishing point name>");

Example of Use

    $main->Publishing_Point_Log_Disable("127.0.0.1","publishing_point");

=item C<< Publishing_Point_Log_Cycle >>

This function cycles the log file immediately rather than waiting for the log time.

    Publishing_Point_Log_Cycle("<IP>","<publishing point name>");

Example Of Use

    $main->Publishing_Point_Log_Cycle("127.0.0.1","publishing_point");

=item C<< Publishing_Point_Authorization_IPAddress_Add >>

=item C<< Publishing_Point_Authorization_IPAddress_Remove >>

=item C<< Publishing_Point_Authorization_IPAddress_Get >>

=item C<< Publishing_Point_General_Set >>

=item C<< Publishing_Point_General_Get >>

=item C<< Publishing_Point_Players_Get >>

=item C<< Server_CoreVariable_Get >>

=head1 Playlist FUNCTIONS

=item C<< Playlist_Jump_To_Event >>

This function jumps to a specific section of the current playlist. You need to make sure the playlist
you are using is constructed correctly for this to work. You have to specify the server IP, publishing
point name and position in the playlist (known as event). If any of the entries are incorrect or the
playlist is not correct it will FAIL to jump and return no error.

    Playlist_Jump_To_Event( "<IP>", "<publishing point name>", "<playlist position>" );

Example of Use

    my $result = $main->Playlist_Jump_To_Event("127.0.0.1","andrew","position2");

On success $result will return 1, on failure 0. If there is a failure, error is set and can be retrieved.
If an incorrect event, publishing point or IP are specified no error is usually returned.

=cut

sub new {

        my $self = {};
        bless $self;

        my ( $class , $attr ) =@_;

        while (my($field, $val) = splice(@{$attr}, 0, 2))
                { $self->{_GLOBAL}{$field}=$val; }

        $self->{_GLOBAL}{'STATUS'}="OK";

        return $self;
}

sub Server_Create
{
my $self = shift;
my $server_ip = shift;
if ( !$server_ip )
	{
	$self->set_error("IP Address of Windows Media Server required");
	return 0;
	}
my $server_object = new Win32::OLE( [ $server_ip , "WMSServer.Server" ] );
if ( !$server_object )
        {
        $self->set_error("OLE Object Failed To Initialise");
        # need to add error capture here
        return 0;
        }
$self->{_GLOBAL}{'Server'}{$server_ip}=$server_object;
return 1;
}

sub Server_Destroy
{
my ( $self ) = shift;
my ( $server_ip ) = shift;
if ( !$server_ip )
	{
	$self->set_error("IP Address of Windows Media Server required");
	return 0;
	}
if ( !$self->{_GLOBAL}{'Server'}{$server_ip} )
	{
	$self->set_error("IP Address Specified Has No Server");
	return 0;
	}

undef $self->{_GLOBAL}{'Server'}{$server_ip};
delete $self->{_GLOBAL}{'Server'}{$server_ip};
return 1;
}


sub Server_ExportXML
{
my $self = shift;
my $server_ip = shift;
my $filename = shift;
if ( !$server_ip )
        { $self->set_error("IP Address of Windows Media Server required");
        return 0; }
if ( !$self->{_GLOBAL}{'Server'}{$server_ip} )
        { $self->set_error("IP Address Specified Has No Server");
        return 0; }
if ( !$filename )
        { $self->set_error("Filename Not Specified");
        return 0; }

my ( $server_object ) = $self->{_GLOBAL}{'Server'}{$server_ip};

$server_object->ExportXML($filename);
return 1;
}

# Playlist functions go here.

sub Playlist_Jump_To_Event
{
my $self = shift;
my $server_ip = shift;
my $publishing_point_name = shift;
my $event_name = shift;
if ( !$server_ip )
        { $self->set_error("IP Address of Windows Media Server required");
	return 0; }
if ( !$self->{_GLOBAL}{'Server'}{$server_ip} )
        { $self->set_error("IP Address Specified Has No Server");
        return 0; }

my ( $server_object ) = $self->{_GLOBAL}{'Server'}{$server_ip};

if ( !$server_object->PublishingPoints($publishing_point_name) )
        { 
	$self->set_error("Publishing Point Not Defined"); 
	return 0; 
	}

my $publishing_point = $server_object->PublishingPoints( $publishing_point_name );
if ( $publishing_point->{BroadCastStatus}!=2 )
	{ 
	$self->set_error("Publishing Point Not Active"); 
	return 0; 
	}

my $publishing_point_playlist = $publishing_point->{SharedPlaylist};
if ( !$publishing_point_playlist ) 
	{ 
	$self->set_error("Playlist not defined"); 
	return 0; 
	}

my $error = $publishing_point_playlist->FireEvent( $event_name );
return 1;
}

sub Publishing_Point_Authorization_ACL_Enable
{
my $self = shift;
my $server_ip = shift;
my $publishing_point_name = shift;
if ( !$server_ip )
        { $self->set_error("IP Address of Windows Media Server required");
        return 0; }
if ( !$self->{_GLOBAL}{'Server'}{$server_ip} )
        { $self->set_error("IP Address Specified Has No Server");
        return 0; }
my ( $server_object ) = $self->{_GLOBAL}{'Server'}{$server_ip};
if ( !$server_object->PublishingPoints($publishing_point_name) )
        { $self->set_error("Publishing Point Not Defined"); return 0; }
my $publishing_point = $server_object->PublishingPoints( $publishing_point_name );
my $User_Control = $publishing_point->EventHandlers("WMS Publishing Points ACL Authorization");
${$User_Control}{'Enabled'}=1;
return 1;
}

sub Publishing_Point_Authorization_ACL_Disable
{
my $self = shift;
my $server_ip = shift;
my $publishing_point_name = shift;
if ( !$server_ip )
        { $self->set_error("IP Address of Windows Media Server required");
        return 0; }
if ( !$self->{_GLOBAL}{'Server'}{$server_ip} )
        { $self->set_error("IP Address Specified Has No Server");
        return 0; }
my ( $server_object ) = $self->{_GLOBAL}{'Server'}{$server_ip};
if ( !$server_object->PublishingPoints($publishing_point_name) )
        { $self->set_error("Publishing Point Not Defined"); return 0; }
my $publishing_point = $server_object->PublishingPoints( $publishing_point_name );
my $User_Control = $publishing_point->EventHandlers("WMS Publishing Points ACL Authorization");
${$User_Control}{'Enabled'}=0;
return 1;
}


sub Publishing_Point_Authorization_ACL_Add
{
my $self = shift;
my $server_ip = shift;
my $publishing_point_name = shift;
my $limit_parameters = shift;
if ( !$server_ip )
        { $self->set_error("IP Address of Windows Media Server required");
        return 0; }
if ( !$self->{_GLOBAL}{'Server'}{$server_ip} )
        { $self->set_error("IP Address Specified Has No Server");
        return 0; }

my ( $server_object ) = $self->{_GLOBAL}{'Server'}{$server_ip};
if ( !$server_object->PublishingPoints($publishing_point_name) )
        { $self->set_error("Publishing Point Not Defined"); return 0; }
my $publishing_point = $server_object->PublishingPoints( $publishing_point_name );
my $limit_variables = Win32::WindowsMedia::BaseVariables->UserAccessSettings();
my $User_Control = $publishing_point->EventHandlers("WMS Publishing Points ACL Authorization");
my $User_Custom = $User_Control->CustomInterface();
my $User_List = $User_Custom->AccessControlList();
foreach my $user ( keys %{$limit_parameters} )
	{
	my $user_mask = ${$limit_parameters}{$user};
	my $user_value;
	foreach my $mask_name ( split(/,/,$user_mask) )
		{
		foreach my $limit_names ( keys %{$limit_variables} )
			{ 
			if ( $mask_name=~/${$limit_variables}{$limit_names}/i )
				{ 
				if ( $mask_name=~/^AllowAll$/i || $mask_name=~/^DenyAll$/i )
					{ $user_value=$limit_names; }
					else
					{ $user_value+=$limit_names; }
				} 
			} 
		}
	my $add_user=$User_List->Add( $user, $user_value );
	}
return 1;
}

sub Publishing_Point_Authorization_ACL_List
{
my $self = shift;
my $server_ip = shift;
my $publishing_point_name = shift;
my $users_configured = shift;
if ( !$server_ip )
        { $self->set_error("IP Address of Windows Media Server required");
        return 0; }
if ( !$self->{_GLOBAL}{'Server'}{$server_ip} )
        { $self->set_error("IP Address Specified Has No Server");
        return 0; }

my ( $server_object ) = $self->{_GLOBAL}{'Server'}{$server_ip};
if ( !$server_object->PublishingPoints($publishing_point_name) )
        { $self->set_error("Publishing Point Not Defined"); return 0; }
my $publishing_point = $server_object->PublishingPoints( $publishing_point_name );
my $User_Control = $publishing_point ->EventHandlers("WMS Publishing Points ACL Authorization");
my $User_Custom = $User_Control->CustomInterface();
my $User_List = $User_Custom->AccessControlList();
for ($a=0;$a< ${$User_List}{'Count'}; $a++)
	{
	my $info= ${$User_List}{$a};
	my $name = ${$info}{'Trustee'};
	my $user_mask = ${$info}{'AccessMask'};
	${$users_configured}{$name}=$user_mask;
	}
return 1;
}

sub Publishing_Point_Authorization_ACL_Remove
{
my $self = shift;
my $server_ip = shift;
my $publishing_point_name = shift;
my $limit_parameters = shift;

if ( !$server_ip )
        { $self->set_error("IP Address of Windows Media Server required");
        return 0; }

if ( !$self->{_GLOBAL}{'Server'}{$server_ip} )
        { $self->set_error("IP Address Specified Has No Server");
        return 0; }

my ( $server_object ) = $self->{_GLOBAL}{'Server'}{$server_ip};

if ( !$server_object )
        { $self->set_error("Server Object Not Set"); return 0; }

if ( !$server_object->PublishingPoints($publishing_point_name) )
        { $self->set_error("Publishing Point Not Defined"); return 0; }

my $publishing_point = $server_object->PublishingPoints( $publishing_point_name );
my $User_Control = $publishing_point ->EventHandlers("WMS Publishing Points ACL Authorization");
my $User_Custom = $User_Control->CustomInterface();
my $User_List = $User_Custom->AccessControlList();
foreach my $user ( keys %{$limit_parameters} )
        {
        my $add_user=$User_List->Remove( $user );
        }
return 1;
}

sub Publishing_Point_Authorization_IPAddress_Add
{
my $self = shift;
my $server_object = shift;
my $publishing_point_name = shift;
my $ip_list_type = shift;
my $limit_parameters = shift;
if ( !$server_object )
        { $self->set_error("Server Object Not Set"); return 0; }
if ( !$server_object->PublishingPoints($publishing_point_name) )
        { $self->set_error("Publishing Point Not Defined"); return 0; }
if ( $ip_list_type!~/^AllowIP$/ && $ip_list_type!~/^DisallowIP$/ )
	{ $self->set_error("AllowIP or DisallowIP are the only valid types requested '$ip_list_type'"); return 0; }
my $publishing_point = $server_object->PublishingPoints( $publishing_point_name );
my $IP_Control = $publishing_point ->EventHandlers("WMS IP Address Authorization");
my $IP_Custom = $IP_Control->CustomInterface();
my $IPList = ${$IP_Custom}{$ip_list_type};
foreach my $entry (@{$limit_parameters})
	{
	# Probably need to put some IP address and mask checking
	# in here so not to pass crap to the WindowsMediaService as it appears
	# to go a little screwy if you do.
	my ( $address, $netmask ) = (split(/,/,$entry))[0,1];
	$IPList->Add( $address, $netmask );
	}
return 1;
}

sub Publishing_Point_Authorization_IPAddress_Remove
{
my $self = shift;
my $server_object = shift;
my $publishing_point_name = shift;
my $ip_list_type = shift;
my $limit_parameters = shift;
if ( !$server_object )
        { $self->set_error("Server Object Not Set"); return 0; }
if ( !$server_object->PublishingPoints($publishing_point_name) )
        { $self->set_error("Publishing Point Not Defined"); return 0; }
if ( $ip_list_type!~/^AllowIP/ && $ip_list_type!~/^DisallowIP/ )
        { $self->set_error("AllowIP or DisallowIP are the only valid types requested '$ip_list_type'"); return 0; }
my $publishing_point = $server_object->PublishingPoints( $publishing_point_name );
my $IP_Control = $publishing_point ->EventHandlers("WMS IP Address Authorization");
my $IP_Custom = $IP_Control->CustomInterface();
my $IPList = ${$IP_Custom}{$ip_list_type};
if ( ${$IPList}{'Count'}>0 )
	{
	foreach my $address (@{$limit_parameters})
        	{
		for ( $a=0; $a<${$IPList}{'Count'}; $a++ )
			{
			my $ip_entry = ${$IPList}{$a};
			if ( ${$ip_entry}{'Address'}=~/$address/ )
				{
				$IPList->Remove ($a);
				}
			}
		}
	}
return 1;
}

sub Publishing_Point_General_Set
{
my $self = shift;
my $server_object = shift;
my $publishing_point_name = shift;
my %limit_parameters = shift;
if ( !$server_object )
        { $self->set_error("Server Object Not Set"); return 0; }
if ( !$server_object->PublishingPoints($publishing_point_name) )
        { $self->set_error("Publishing Point Not Defined"); return 0; }
my $publishing_point = $server_object->PublishingPoints( $publishing_point_name );
my $limit_variables = Win32::WindowsMedia::BaseVariables->PublishingPointGeneral();
foreach my $limit_name ( keys %limit_parameters )
	{
	if ( ${$limit_variables}{$limit_name} )
		{ $publishing_point->{ ${$limit_variables}{$limit_name} }=$limit_parameters{$limit_name}; }
	}
return 1;
}

sub Publishing_Point_General_Get
{
my $self = shift;
my $server_object = shift;
my $publishing_point_name = shift;
my $limit_values = shift;
if ( !$server_object )
        { $self->set_error("Server Object Not Set"); return 0; }
if ( !$server_object->PublishingPoints($publishing_point_name) )
        { $self->set_error("Publishing Point Not Defined"); return 0; }
my $publishing_point = $server_object->PublishingPoints( $publishing_point_name );
my $limit_variables = Win32::WindowsMedia::BaseVariables->PublishingPointGeneral();
foreach my $limit_name ( keys %{$limit_variables} )
	{ ${$limit_values}{$limit_name}=${$publishing_point}{$limit_name}; }
return 1;
}

sub Publishing_Point_Limits_Set
{
my $self = shift;
my $server_object = shift;
my $publishing_point_name = shift;
my %limit_parameters = shift;
if ( !$server_object )
        { $self->set_error("Server Object Not Set"); return 0; }
if ( !$server_object->PublishingPoints($publishing_point_name) )
        { $self->set_error("Publishing Point Not Defined"); return 0; }
my $publishing_point = $server_object->PublishingPoints( $publishing_point_name );
my $Limits = $publishing_point->{Limits};
my $limit_variables = Win32::WindowsMedia::BaseVariables->PublishingPointLimits();
foreach my $limit_name ( keys %limit_parameters )
	{
	if ( ${$limit_variables}{$limit_name} )
		{ $Limits->{ ${$limit_variables}{$limit_name} }=$limit_parameters{$limit_name}; }
	}
return 1;
}

sub Publishing_Point_Limits_Get
{
my $self = shift;
my $server_object = shift;
my $publishing_point_name = shift;
my $limit_values = shift;
if ( !$server_object )
        { $self->set_error("Server Object Not Set"); return 0; }
if ( !$server_object->PublishingPoints($publishing_point_name) )
        { $self->set_error("Publishing Point Not Defined"); return 0; }
my $publishing_point = $server_object->PublishingPoints( $publishing_point_name );
my $Limits = $publishing_point->{Limits};
my $limit_variables = Win32::WindowsMedia::BaseVariables->PublishingPointLimits();
foreach my $limit_name ( keys %{$limit_variables} )
	{ ${$limit_values}{$limit_name}=${$Limits}{$limit_name}; }
return 1;
}

sub Publishing_Point_Start
{
my $self = shift;
my $server_ip = shift;
my $publishing_point_name = shift;
if ( !$server_ip )
        {
        $self->set_error("IP Address of Windows Media Server required");
        return 0;
        }
if ( !$self->{_GLOBAL}{'Server'}{$server_ip} )
        {
        $self->set_error("IP Address Specified Has No Server");
        return 0;
        }
my ( $server_object ) = $self->{_GLOBAL}{'Server'}{$server_ip};
if ( !$server_object )
        { $self->set_error("Server Object Not Set"); return 0; }
if ( !$server_object->PublishingPoints($publishing_point_name) )
        { $self->set_error("Publishing Point Not Defined"); return 0; }
my $publishing_point = $server_object->PublishingPoints( $publishing_point_name );
#if ( ${$publishing_point}{'Path'}=~/^push:\*/i )
#        { $self->set_error("Push Publishing Points Can Not Be Started"); return 0; }
$publishing_point->Start();
return 1;
}

sub Publishing_Point_Stop
{
my $self = shift;
my $server_ip = shift;
my $publishing_point_name = shift;
if ( !$server_ip )
        {
        $self->set_error("IP Address of Windows Media Server required");
        return 0;
        }
if ( !$self->{_GLOBAL}{'Server'}{$server_ip} )
        {
        $self->set_error("IP Address Specified Has No Server");
        return 0;
        }
my ( $server_object ) = $self->{_GLOBAL}{'Server'}{$server_ip};
if ( !$server_object )
        { $self->set_error("Server Object Not Set"); return 0; }
if ( !$server_object->PublishingPoints($publishing_point_name) )
        { $self->set_error("Publishing Point Not Defined"); return 0; }
my $publishing_point = $server_object->PublishingPoints( $publishing_point_name );
#if ( ${$publishing_point}{'Path'}=~/^push:\*/i )
#	{ $self->set_error("Push Publishing Points Can Not Be Stopped"); return 0; }
$publishing_point->Stop();
return 1;
}

sub Publishing_Point_Remove
{
my $self = shift;
my $server_ip = shift;
my $publishing_point_name = shift;
if ( !$server_ip )
        {
        $self->set_error("IP Address of Windows Media Server required");
        return 0;
        }
if ( !$self->{_GLOBAL}{'Server'}{$server_ip} )
        {
        $self->set_error("IP Address Specified Has No Server");
        return 0;
        }
my ( $server_object ) = $self->{_GLOBAL}{'Server'}{$server_ip};

if ( !$server_object )
        { $self->set_error("Server Object Not Set"); return 0; }
if ( !$server_object->PublishingPoints($publishing_point_name) )
        { $self->set_error("Publishing Point Not Defined"); return 0; }
my $publishing_points = $server_object->PublishingPoints;
my $publishing_point_del = $publishing_points->Remove(
                                $publishing_point_name
				);
undef $publishing_points;
if ( !$publishing_point_del )
	{ $self->set_error("Publishing Point Remove Error"); return 0; }
return 1;
}

sub Publishing_Point_Create
{
my $self = shift;
my $server_ip = shift;
my $publishing_point_name = shift;
my $publishing_point_url = shift;
my $publishing_point_type = shift;

# type can be a name or number,
# 'OnDemand', 'Broadcast', 'CacheProxyOnDemand', 'CacheProxyBroadcast'
my $real_pub_point_type=0;
if ( !$server_ip )
        {
        $self->set_error("IP Address of Windows Media Server required");
        return 0;
        }
if ( !$self->{_GLOBAL}{'Server'}{$server_ip} )
        {
        $self->set_error("IP Address Specified Has No Server");
        return 0;
        }
my ( $server_object ) = $self->{_GLOBAL}{'Server'}{$server_ip};

my $limit_variables = Win32::WindowsMedia::BaseVariables->PublishingPointType();
foreach my $pub_type ( keys %{$limit_variables} )
	{
	if ( ${$limit_variables}{$pub_type}=~/$publishing_point_type/i )
		{
		$real_pub_point_type=$pub_type;
		}
	}

if ( !$real_pub_point_type )
	{
	my $publishing_point_types;
	foreach my $pub_type ( keys %{$limit_variables} )
		{ $publishing_point_types.="${$limit_variables}{$pub_type},"; }
	chop($publishing_point_types);
	$self->set_error("Invalid Publishing Point Type Specified must be one of $publishing_point_types");
	undef $publishing_point_types;
	return 0;
	}

$publishing_point_url="push:*" if !$publishing_point_url;

if ( $publishing_point_name!~/^[0-9a-zA-Z\-_]+$/ )
	{
	$self->set_error("Publishing Point Name Invalid");
	return 0;
	}

if ( length($publishing_point_name)<3 )
	{
	$self->set_error("Publishing Point Name Too Short");
	return 0;
	}

if ( !$server_object )
	{
	$self->set_error("Server Object Not Set");
	return 0;
	}

if ( $server_object->PublishingPoints($publishing_point_name) )
	{
	$self->set_error("Publishing Point Already Defined");
	return 0;
	}

my $publishing_points = $server_object->PublishingPoints;

# We need to eval this with a timer, why you might asked,
# well you can figure it out.

my $publishing_point_new;
eval {
        local $SIG{ALRM} = sub { die "Broken"; };
        alarm 5;
	$publishing_point_new = $publishing_points->Add( 
				$publishing_point_name,
				$real_pub_point_type,
				$publishing_point_url );
alarm 0;
};

if ( !$publishing_point_new )
	{
	$self->set_error("Publishing Point Creation Failed");
	return 0;
	}

undef $publishing_points;

return $publishing_point_new;
}

sub Publishing_Point_Path
{
my $self = shift;
my $server_ip = shift;
my $publishing_point_name = shift;
my $path = shift;
my $stop = $self->Publishing_Point_Stop($server_ip,$publishing_point_name);
if ( !$stop )
	{ return 0; }
my ( $server_object ) = $self->{_GLOBAL}{'Server'}{$server_ip};
if ( !$server_object )
        { $self->set_error("Server Object Not Set"); return 0; }
if ( !$server_object->PublishingPoints($publishing_point_name) )
        { $self->set_error("Publishing Point Not Defined"); return 0; }
my $publishing_point = $server_object->PublishingPoints( $publishing_point_name );
${$publishing_point}{'Path'} =$path;
return 1;
}

sub Publishing_Point_List
{
my $self = shift;
my $server_ip = shift;
my $publishing_point_name = shift;
my (@found_publishing_points);
if ( !$server_ip )
        {
        $self->set_error("IP Address of Windows Media Server required");
        return 0;
        }
if ( !$self->{_GLOBAL}{'Server'}{$server_ip} )
        {
        $self->set_error("IP Address Specified Has No Server");
        return 0;
        }
my ( $server_object ) = $self->{_GLOBAL}{'Server'}{$server_ip};
if ( !$server_object )
        { $self->set_error("Server Object Not Set"); return 0; }

for ( $a=0; $a< $server_object->PublishingPoints->{'length'}; $a++ )
	{
	if ( $server_object->PublishingPoints->{$a}->{'Name'}=~/$publishing_point_name/ig )
		{ push @found_publishing_points, $server_object->PublishingPoints->{$a}->{'Name'}; }
	}

return @found_publishing_points;
}

sub Publishing_Point_Authorization_IPAddress_Get
{
my $self = shift;
my $server_object = shift;
my $publishing_point_name = shift;
my $ip_list_type = shift;
my $limit_values = shift;
if ( !$server_object )
        { $self->set_error("Server Object Not Set"); return 0; }

if ( !$server_object->PublishingPoints($publishing_point_name) )
        { $self->set_error("Publishing Point Not Defined"); return 0; }

if ( $ip_list_type!~/^AllowIP/ || $ip_list_type!~/^DisallowIP/ )
        { $self->set_error("AllowIP or DisallowIP are the only valid types"); return 0; }

my $publishing_point = $server_object->PublishingPoints( $publishing_point_name );
my $IP_Control = $publishing_point ->EventHandlers("WMS IP Address Authorization");
my $IP_Custom = $IP_Control->CustomInterface();
my $IPList = ${$IP_Custom}{$ip_list_type};
# variables should be 'Address' and 'Mask'
if ( ${$IPList}{'Count'} > 0 )
	{
	for ($a=0; $a<${$IPList}{'Count'}; $a++ )
		{
		my $ip_entry = ${$IPList}{$a};
		foreach my $variable ( keys %{$ip_entry} )
			{
			${$limit_values}{$a}{$variable}=${$ip_entry}{$variable};
			}
		}
	}
return 1;
}


sub Publishing_Point_Players_Get
{
my $self = shift;
my $server_object = shift;
my $publishing_point_name = shift;
my $limit_values = shift;
if ( !$server_object )
        { 
	$self->set_error("Server Object Not Set"); 
	return 0; 
	}

if ( !$server_object->PublishingPoints($publishing_point_name) )
        { 
	$self->set_error("Publishing Point Not Defined"); 
	return 0; 
	}

my $publishing_point = $server_object->PublishingPoints( $publishing_point_name );
my $players = $publishing_point ->{Players};
my $player_status = Win32::WindowsMedia::BaseVariables->PlayerStatus();
if ( ${$players}{'Count'}>0 )
	{
	for ( $a=0; $a<${$players}{'Count'}; $a++ )
		{
		my $ip_client = ${$players}{$a};
		foreach my $variable ( keys %{$ip_client} )
			{
			${$limit_values}{$a}{$variable}= ${$ip_client}{$variable};
			}
		${$limit_values}{$a}{'Status'}=${$player_status}{ ${$limit_values}{$a}{'Status'} };
		}
	}
return 1;
}

sub Publishing_Point_Log_Cycle
{
my ( $self ) = shift;
my ( $server_ip ) = shift;
my ( $publishing_point_name ) = shift;
if ( !$self->{_GLOBAL}{'Server'}{$server_ip} )
        {
        $self->set_error("IP Address Specified Has No Server");
        return 0;
        }
my ( $server_object ) = $self->{_GLOBAL}{'Server'}{$server_ip};
if ( !$server_object )
        {
        $self->set_error("OLE Object Failed To Initialise");
        # need to add error capture here
        return 0;
        }
if ( !$server_object->PublishingPoints($publishing_point_name) )
        {
        $self->set_error("Publishing Point Not Defined");
        return 0;
        }
my $publishing_point = $server_object->PublishingPoints( $publishing_point_name );
my $log_plugin=$publishing_point->EventHandlers("WMS Client Logging");
my $log_custom =$log_plugin->CustomInterface();
$log_custom->CycleNow();
return 1;
}


sub Publishing_Point_Log_Set
{
my ( $self ) = shift;
my ( $server_ip ) = shift;
my ( $publishing_point_name ) = shift;
my ( $template ) = shift;

my ( $real_log_type );

if ( !$self->{_GLOBAL}{'Server'}{$server_ip} )
        {
        $self->set_error("IP Address Specified Has No Server");
        return 0;
        }
my ( $server_object ) = $self->{_GLOBAL}{'Server'}{$server_ip};
if ( !$server_object )
        {
        $self->set_error("OLE Object Failed To Initialise");
        # need to add error capture here
        return 0;
        }
if ( !$server_object->PublishingPoints($publishing_point_name) )
        {
        $self->set_error("Publishing Point Not Defined");
        return 0;
        }
my $publishing_point = $server_object->PublishingPoints( $publishing_point_name );

my $log_plugin=$publishing_point->EventHandlers("WMS Client Logging");

my $log_custom =$log_plugin->CustomInterface();

my $limit_variables = Win32::WindowsMedia::BaseVariables->ServerLogCycle();
foreach my $log_type ( keys %{$limit_variables} )
        {
        if ( ${$limit_variables}{$log_type}=~/${$template}{'Cycle'}/i )
                {
                ${$template}{'Cycle'}=$log_type;
                }
        }


my $option_transform = Win32::WindowsMedia::BaseVariables->Return_Yes_No();

${$log_custom}{'Template'}=${$template}{'Template'};
${$log_custom}{'Cycle'}=${$template}{'Cycle'};
${$log_custom}{'UseLocalTime'}=${$option_transform}{ ${$template}{'UseLocalTime'} };
${$log_custom}{'UseBuffering'}=${$option_transform}{ ${$template}{'UseBuffering'} };
${$log_custom}{'UseUnicode'}=${$option_transform}{ ${$template}{'UseUnicode'} };
${$log_custom}{'V4Compat'}=${$option_transform}{ ${$template}{'V4Compat'} };

${$log_custom}{'MaxSize'}=${$template}{'MaxSize'};
${$log_custom}{'RoleFilter'}=${$template}{'RoleFilter'};

if ( ${$template}{'FreeSpaceQuota'} )
	{ ${$log_custom}{'MaxSize'}=${$template}{'FreeSpaceQuota'}; }

if ( ${$template}{'LoggedEvents'} )
	{
	my $log_value=0;
	my $log_variables = Win32::WindowsMedia::BaseVariables->ServerLogType();
	foreach my $log_entry ( split(/,/,${$template}{'LoggedEvents'}) )
		{
		foreach my $limit_names ( keys %{$log_variables} )
			{
			if ( $log_entry=~/${$log_variables}{$limit_names}/i )
				{ $log_value+=$limit_names; }
			}
		}
        ${$log_custom}{'LoggedEvents'}=$log_value;
	}

return 1;
}

sub Publishing_Point_Log_Disable
{
my ( $self ) = shift;
my ( $server_ip ) = shift;
my ( $publishing_point_name ) = shift;
if ( !$self->{_GLOBAL}{'Server'}{$server_ip} )
        {
        $self->set_error("IP Address Specified Has No Server");
        return 0;
        }
my ( $server_object ) = $self->{_GLOBAL}{'Server'}{$server_ip};
if ( !$server_object )
        {
        $self->set_error("OLE Object Failed To Initialise");
        # need to add error capture here
        return 0;
        }
if ( !$server_object->PublishingPoints($publishing_point_name) )
        {
        $self->set_error("Publishing Point Not Defined");
        return 0;
        }

my $publishing_point = $server_object->PublishingPoints( $publishing_point_name );

my $log_plugin=$publishing_point->EventHandlers("WMS Client Logging");

${$log_plugin}{'Enabled'}=0;

return 1;
}

sub Publishing_Point_Log_Enable
{
my ( $self ) = shift;
my ( $server_ip ) = shift;
my ( $publishing_point_name ) = shift;

if ( !$self->{_GLOBAL}{'Server'}{$server_ip} )
        {
        $self->set_error("IP Address Specified Has No Server");
        return 0;
        }
my ( $server_object ) = $self->{_GLOBAL}{'Server'}{$server_ip};
if ( !$server_object )
        {
        $self->set_error("OLE Object Failed To Initialise");
        # need to add error capture here
        return 0;
        }
if ( !$server_object->PublishingPoints($publishing_point_name) )
        {
        $self->set_error("Publishing Point Not Defined");
        return 0;
        }


my $publishing_point = $server_object->PublishingPoints( $publishing_point_name );

my $log_plugin=$publishing_point->EventHandlers("WMS Client Logging");

${$log_plugin}{'Enabled'}=1;

return 1;
}

sub Server_CoreVariable_Get
{
my $self = shift;
my $server_object = shift;
my $corevariable = shift;
if ( !$server_object )
        {
        $self->set_error("Server Object Not Set");
        return 0;
        }

if ( !$corevariable )
	{
	$self->set_error("Variable Name Required");
	return 0;
	}

my $variable_names = Win32::WindowsMedia::BaseVariables->CoreVariableNames();

foreach my $name ( keys %{$variable_names} )
	{	
	if ( $name=~/$corevariable/i )
		{
		my $type = ${$variable_names}{$name};
		if ( $type!~/^read/i )
			{
			$self->set_error("Variable Name Not Value");
			return 0;
			}
		my $value = $server_object->{$name};
		return $value;
		}
	}
$self->set_error("Variable Name Not Found");
return 0;
}

sub set_error
{
my $self = shift;
my $error = shift;
$self->{_GLOBAL}{'STATUS'} = $error;
return 1;
}

sub get_error
{
my $self = shift;
return $self->{_GLOBAL}{'STATUS'};
}


=head1 AUTHOR

Andrew S. Kennedy, C<< <shamrock at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-win32-windowsmedia at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Win32-WindowsMedia>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Win32-WindowsMedia>

=item * Search CPAN

L<http://search.cpan.org/dist/Win32-WindowsMedia>

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2008 Andrew S. Kennedy, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Win32::WindowsMedia
