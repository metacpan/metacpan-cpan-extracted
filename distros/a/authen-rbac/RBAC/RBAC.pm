package Authen::RBAC;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use XML::Parser;
use Data::Dumper;
use Authen::RBAC::Group;
use Unix::Syslog qw(:macros :subs);

require Exporter;

@ISA = qw(Exporter);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(

);

$VERSION = '0.01';

my $debug = 0;
sub AUTH_DIR {'/usr/local/etc/auth'}
sub GROUP_FILE {'/etc/group'}

=head1 NAME

Authen::RBAC - Perl extension to manage Authen::RBAC configs

=head1 SYNOPSIS
  
use Authen::RBAC;

=head1 DESCRIPTION

This perl module manages manages Authen::RBAC XML configs and authorize against them

=cut

=head1 INTERFACE
  
The following methods are available in this module.

=cut

=head2 new(debug=>$debug);

=cut

sub new {
  
        my $class = shift;
        my %args = @_;

        my $self = {};
        bless $self, $class;

	$debug && print _trace(),"called\n";

	if ($args{debug}) {
		$self->debug($args{debug});
	}

	# allow user to override the default XML directory
	if ($args{conf}) {
		$self->{conf} = $args{conf};
	}
	else {
		$self->{conf} = AUTH_DIR;
	}

	# load all existing groups
	$self->parse_xml_dir( $self->{conf} );
	$self->_preload_unix_groups();

        return $self;

}

=head2 parse_xml_file($xmlfile) 

Parse XML config file

=cut

sub parse_xml_file {
	my $self = shift;
	my $xmlfile = shift;
	my $result;

	$debug && print _trace(),"called\n";

	if (! ( -e $xmlfile ) ) {
		$debug && print _trace(),"xml file does not exist: xmlfile [$xmlfile]\n";
		return undef;
	}

	# parse config file
	$result = $self->_parse( [$xmlfile] );
	return ${$result}{$xmlfile};
}

=head2 parse_xml_dir($xmldir) 

Parse XML config file(s)

=cut

sub parse_xml_dir {
	my $self = shift;
	my $xmldir = shift;
	my $result;
	my $groups;

	# parse xml files
	$debug && print _trace(),"called\n";

	# get list of xml configs from config directory
	if ( ! opendir (CONFIGS, $xmldir) ) {
		$self->_syslog("unable to open config directory [".$xmldir."]");
		return undef;
	}
	my @xmlconfs = grep /\.xml$/, readdir CONFIGS;  

	# prepend with dir path
	foreach (@xmlconfs) {
		s/^/$xmldir.'\/'/e; 
	}

        closedir (CONFIGS);  

	# parse config files
	$result = $self->_parse(\@xmlconfs);
	for my $xmlfile (keys %{$result}) {
		if ( defined ${$result}{$xmlfile}) {
			push @{$groups}, $xmlfile;
		}
	}
	return $groups;
}

=head2 output_xml($group) 

Output XML config file for a specific group

=cut

sub output_xml {
	my $self = shift;
	my $group = shift;
	my @result;

	$debug && print _trace(),"called\n";

	# only continue if group is loaded
	if ( ! ($group && defined $self->{groups}{$group})) {
		$debug && print _trace(),"group does not exist: group_name [$group]\n";
		return undef;
	}

	# build XML array
	$debug && print _trace(),"building XML array: group_name [$group]\n";
	push @result, "<xml>";
	for my $line ( @{ $self->{groups}{$group}->output_xml()} ) {
		push @result, "\t$line";
	}
	push @result, "</xml>";

	return \@result;
}

=head2 get_loaded_groups() 

Returns a reference to an array containing the names of currently loaded groups

=cut

sub get_loaded_groups {
	my $self = shift;
	my $result;

	$debug && print _trace(),"called\n";

	# return a list of loaded groups
	@{$result} = keys %{ $self->{groups} };

	return $result;
}

=head2 get_acls_in_group($group)

Returns a reference to an array of acl names in a group

=cut

sub get_acls_in_group {
	my $self = shift;
	my $group = shift;

        $debug && print _trace(),"called\n";

	# make sure we are passed a group name
	if (! $group ){
	        $debug && print _trace(),"missing groupname\n";
		return undef;
	}

	# make sure the group exists
	if (! defined ($self->{groups}{$group}) ) {
	        $debug && print _trace(),"group doesn't exist: group_name [$group]\n";
		return undef;
	}

	# call the group's list_acls() method
	return $self->{groups}{$group}->list_acls();
}

=head2 get_policies_in_acl($group,$acl)

Returns a reference to an array of policies in a specific acl

=cut

sub get_policies_in_acl {
	my $self = shift;
	my $group = shift;
	my $acl_name = shift;
	my $result;

	$debug && print _trace(), "called\n";

	if (! ($group && $acl_name) ) {
		$debug && print _trace(), "missing args: group_name [$group], acl_name [$acl_name]\n";
		return undef;
	}

	if (! defined ($self->{groups}{$group}) ){
		$debug && print _trace(), "group doesn't exist: group_name [$group]\n";
		return undef;
	}

	$result = $self->{groups}{$group}->get_policies_in_acl($acl_name);

	return $result;

}

=head2 delete_group($group) 

Removes a group

=cut

sub delete_group {
	my $self = shift;
	my $group = shift;
	my $result;

	$debug && print _trace(),"called\n";

	# make sure we were passed a group name
	if (! $group ) {
		$debug && print _trace(),"missing groupname\n";
		return undef;	
	}

	# delete directly if group in memory
	if ( defined $self->{groups}{$group} ) {
		$result = $self->{groups}{$group}->delete_group();
		delete $self->{groups}{$group};
	}

	return $result;
}

=head2 add_group($group)

Add new group

=cut

sub add_group {
	my $self = shift;
	my $group = shift;

	$debug && print _trace(), "called\n";
	if (! $group ){
		$debug && print _trace(), "missing groupname\n";
		return undef;
	}

	if (defined $self->{groups}{$group}) {
		$debug && print _trace(), "group name [$group] in use\n";
		return undef;
	}

	$debug && print _trace(),"creating new group object [$group]\n";
	$self->{groups}{$group} = new Authen::RBAC::Group(group_name=>$group, debug=>$debug);

	return 1;
}	

=head2 add_acl_to_group($group_name, $acl_name, $default_policy)

Add a new ACL to a group

=cut

sub add_acl_to_group {
	my $self = shift;
	my $group = shift;
	my $acl_name = shift;
	my $default_policy = shift;
	my $result;

	$debug && print _trace(), "called\n";

	# make sure we are passed correct arguments
	if ( ! ($group && $acl_name && $default_policy ) ) {
		$debug && print _trace(), "missing args: group [$group], acl_name [$acl_name], default_policy [$default_policy]\n";
		return undef;
	}

	# make sure this group exists
	if (! defined $self->{groups}{$group} ) {
		$debug && print _trace(), "group does not exist: group_name [$group]\n";
		return undef;
	}

	# we are ready to add the new acl
	$result = $self->{groups}{$group}->add_acl($acl_name,$default_policy);
	
	return $result;
}

=head2 delete_acl_from_group($group_name, $acl_name)

Delete an ACL from a group

=cut

sub delete_acl_from_group {
	my $self = shift;
	my $group = shift;
	my $acl_name = shift;
	my $result;

	$debug && print _trace(), "called\n";

	# make sure we are passed correct arguments
	if ( ! ($group && $acl_name ) ) {
		$debug && print _trace(), "missing args: group [$group], acl_name [$acl_name]\n";
		return undef;
	}

	# make sure this group exists
	if (! defined $self->{groups}{$group} ) {
		$debug && print _trace(), "group does not exist: group_name [$group]\n";
		return undef;
	}

	# delete acl
	$debug && print _trace(), "deleting: acl_name [$acl_name]\n";
	$result = $self->{groups}{$group}->delete_acl($acl_name);	

	return $result;
}

=head2 add_policy_to_acl($group_name, $acl_name, $policy_type, $base_pattern, \@additional_patterns)

Add a new policy to ACL

=cut

sub add_policy_to_acl {
	my $self = shift;
	my $group = shift;
	my $acl_name = shift;
	my $policy_type = shift;
	my $base_pattern = shift;
	my $additional_patterns = shift;
	my $result;

	$debug && print _trace(), "called\n";

	# make sure we are passed correct arguments
	if ( ! ($group && $acl_name && $policy_type && $base_pattern ) ) {
		$debug && print _trace(), "missing args: group [$group], acl_name [$acl_name], policy_type [$policy_type], base_pattern [$base_pattern\n";
		return undef;
	}

	# make sure this group exists
	if (! defined $self->{groups}{$group} ) {
		$debug && print _trace(), "group does not exist: group_name [$group]\n";
		return undef;
	}

	# we are ready to add the new policy
	$result = $self->{groups}{$group}->add_acl_policy($acl_name,$policy_type,$base_pattern,$additional_patterns);
	
	return $result;
}

=head2 delete_policy_from_acl($group_name, $acl_name, $policy_type, $base_pattern, \@add_patterns)

Delete a policy from an acl

=cut

sub delete_policy_from_acl {
	my $self = shift;
	my $result;
	my $group = shift;
	my $acl_name = shift;
	my $policy_type = shift;
	my $base_pattern = shift;
	my $add_patterns = shift;

	$debug && print _trace(), "called\n";

	# make sure we are passed correct arguments
	if ( ! ($group && $acl_name && $policy_type && $base_pattern ) ) {
		$debug && print _trace(), "missing args: group [$group], acl_name [$acl_name], policy_type [$policy_type], base_pattern [$base_pattern\n";
		return undef;
	}

	# make sure this group exists
	if (! defined $self->{groups}{$group} ) {
		$debug && print _trace(), "group does not exist: group_name [$group]\n";
		return undef;
	}

	# we are ready to add the new policy
	$result = $self->{groups}{$group}->delete_acl_policy($acl_name,$policy_type,$base_pattern,$add_patterns);
	
	return $result;
}

=head2 authorize(user,command,hostname)
                
Checks whether a user is allowed to execute a command on a specific device
                        
Accepts a scalar user name, scalar command, and a scalar hostname
         
Returns 1 for success
        
Returns undef for failure
        
=cut

sub authorize {
        my $self = shift;
        my $user = shift;
        my $command = shift;
        my $hostname = shift;
        
        $debug && print _trace(),"called with user = [$user], command = [$command], hostname = [$hostname]\n";
         
        # we must have all three arguments to make an informed decision
        if ( ! ($self && $user && $hostname) ) {

                $debug && print _trace(),"missing required arg(s) - returning undef\n";
                return undef;
        }

        # it doesn't make any sense to go further if there is no config file
        if ( ! $self->{parsed} ) {

                $debug && print _trace(),"config file was never parsed - returning undef\n";
                return undef;
        }

        # even if there is a config file, we need groups defined to authorize anything
        if ( ! scalar (keys %{ $self->{groups} } ) ) {

                $debug && print _trace(),"no Authen::RBAC groups are defined\n";
                return undef;
        }
        
        # even if there is are groups defined, if we didn't preload any unix groups - why bother
        if ( ! scalar (keys %{ $self->{usergroups} } ) ) {
        
                $debug && print _trace(),"no unix groups are defined\n";
                return undef;
        }
        
        # attempt to authorize this as a group  
        if ( defined $self->{groups}{$user} ) {
                
                $debug && print _trace(), "attempting to authorize group [$user]\n";
         
                if ( $self->{groups}{$user}->check_acl($command,$hostname) ) {
                        $debug && print _trace(),"command authorized through for group [$user]\n";
                        return 1; 
                }
        }
                
        # get a list of groups this user belongs to
        if ( ! (defined $self->{usergroups}{$user} && scalar ( @{ $self->{usergroups}{$user} } ) ) ) {
        
                $debug && print _trace(),"user [$user] does not belong to any Authen::RBAC groups\n";
                return undef;
        }
        # cycle through the groups and see if our membership to them allows this command/host pair
        for my $group ( @{ $self->{usergroups}{$user} } ) {
        
                $debug && print _trace(),"checking group [$group]\n";
        
                if ( exists $self->{groups}{$group} ) {
                        if ( $self->{groups}{$group}->check_acl($command,$hostname) ) {
                                $debug && print _trace(),"command authorized through membership to group [$group]\n";
                                return 1;
                        }
                }
        }       
        $debug && print _trace(),"command not permitted via any group membership\n";
        return undef;
}

=head2 debug()

Set the module debug level

=cut

sub debug {

        my $self = shift;
        $debug   = shift;
        
        $debug && print _trace(),"called\n";
        
        return 1;
}

#################
# Private methods, not to be used in the public API
#################

=head2 _preload_unix_groups

Determines unix group memberships for all users

=cut

sub _preload_unix_groups {
        my $self = shift;

        $debug && print _trace(),"called\n";
                        
        if  ( ! open(GROUPS,GROUP_FILE) ) {
                $self->_syslog("unable to open groups file [".GROUP_FILE."]");
                die ( _trace(),"unable to open groups file [".GROUP_FILE."]\n");
        }
        while (<GROUPS>) {
                my @fields = split(/:/,$_);
                chomp(@fields);
                my $groupname = $fields[0];
                my $members = $fields[3];
         
                # don't waste our time if there are no members
                next if (!$members);
        
                # don't process non-Authen::RBAC groups
                next if (! (exists $self->{groups}{$groupname}) );   
        
                # add group to the user array
                my @users = split(/,/,$members);
                for my $user (@users) {
                        $debug && print _trace(),"adding user [$user] to group [$groupname]\n";
                        push @{ $self->{usergroups}{$user} }, $groupname;
                }
        }       
        return 1;
}

=head2 _parse(\@xmlconfs)

Parses the current Authen::RBAC XML configuration file

Returns reference to a hash containing the config file name and "1" for success and undef for failure
Returns undef for failure

=cut

sub _parse {
	my $self = shift;
	my $a_xmlconfs = shift;
	my %result;	

        $debug && print _trace(),"called\n";

	# instantiate a new XML parser
        my $parser = new XML::Parser(Handlers => {Start => sub { _handle_start($self,@_) },
                                           End  =>  sub { _handle_end($self,@_) },
                                           Char  => sub { _handle_char($self,@_) } });
        	
	for my $xmlconf (@{$a_xmlconfs}) {

		my $config;
		my @groups;

		$debug && print _trace(),"reading in [$xmlconf] with XML::Parser\n";

		eval {
			$parser->parsefile($xmlconf);
		};
	
		if ($@) {
			$debug && print _trace(), "XML::Parser::paresfile(\"$xmlconf\") failed\n",$@;
			$self->_syslog("couldn't parse [$xmlconf] as xml");
			$result{$xmlconf} = undef;
		}
		else {
			$result{$xmlconf} = 1;
		}
		$self->{parsed} = 1;
		return \%result;
	}
}

sub _handle_start {
        my $self = shift;  
        my $p = shift;  
        my $el = shift;
        my %arg = @_;

        if ( ($el eq 'acl') && (defined $arg{info}) && (defined $self->{group_name}) ) {
                $self->{acl_name} = $arg{info};
        }                                           
        elsif ( ( $el eq 'permit') || ( $el eq 'deny') ) {
                $self->{policy_type} = $el;
                $self->{policy_cmd}  = $arg{cmd};
        }

        return;
}

sub _handle_end {
        my $self = shift;
        my $p = shift;
        my $el = shift;
                 
         
        if ($el eq 'group') {
                $self->{group_name} = undef;
        }
        elsif ( $el eq 'acl' ){
                $self->{acl_name} = undef;
        }
        elsif ( ( $el eq 'permit') || ( $el eq 'deny' ) ){
                $self->{policy_type} = undef;
                $self->{policy_cmd}  = undef;
        }
                                           
        return;
}

sub _handle_char {
        my $self = shift;
        my ($p, $data) = @_;

        return if ($data =~ /^\s*$/m);

        if ( ($p->current_element eq 'groupname') && $data) {
                if ( ! defined $self->{groups}{$data}) {

                        $self->{groups}{$data} = new Authen::RBAC::Group;
                        $self->{groups}{$data}->debug($debug);
                        $self->{groups}{$data}->set_group_name($data);
                }
                $self->{group_name} = $data;
        }
        elsif ( ($p->current_element eq 'default') && $data && (defined $self->{acl_name}) &&( defined $self->{groups}{$self->{group_name}} )) {
                $self->{groups}{$self->{group_name}}->add_acl($self->{acl_name},$data);
        }
        elsif ( ($p->current_element eq 'hostmask') && $data && (defined $self->{acl_name}) && ( defined $self->{groups}{$self->{group_name}} )) {
                $self->{groups}{$self->{group_name}}->add_acl_policy($self->{acl_name},'Hostmask',$data);
        }
        elsif ( ($p->current_element eq 'argmask') && $data && ( defined $self->{policy_type})  && (defined $self->{acl_name}) && ( defined $self->{groups}{$self->{group_name}} ) ) {

		# capitalize policy type
		my $type = $self->{policy_type};
		$type =~ s/\b(\w)/uc($1)/e;

		# add new policy
                $self->{groups}{$self->{group_name}}->add_acl_policy($self->{acl_name},$type, $self->{policy_cmd}, [$data]);
        }

        return;
}

sub _trace {

        my @timedat = localtime( time );
        my $timestring = $timedat[ 2 ] . ':' . $timedat[ 1 ] . ':' . $timedat[ 0 ];

        return @{[ ( caller( 1 )) [ 3 ] . "(): " . $timestring . "\t" ]};
}

sub _dump {

        my $self = shift;
        my $dumper = Data::Dumper->new( [ $self ], [ qw( Conf ) ]  );

        print $dumper->Dumpxs;
}

sub _syslog {
	my $self = shift;
	my $mesg = shift;

	openlog( "Authen::RBAC", LOG_PID, LOG_DAEMON );
	syslog LOG_EMERG, $mesg; 
	closelog();	

}

1;
__END__

=head1 AUTHOR

Dennis Opacki, dopacki@adotout.com

=head1 SEE ALSO

perl(1).

=cut

