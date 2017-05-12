package Authen::RBAC::Group;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use Authen::RBAC::Group::Acl;

use Data::Dumper;   

require Exporter;

@ISA = qw(Exporter);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);

$VERSION = '0.01';
my $debug = 0;

=head1 NAME

Authen::RBAC::Group - Perl extension to manage authorization Groups

=head1 SYNOPSIS

  use Authen::RBAC::Group;
  my $object = new Authen::RBAC::Group;

=head1 DESCRIPTION

Creates a new Group object

=cut

=head1 INTERFACE
 
The following methods are available in this module.
 
=cut
 
=head2 new();
 
=cut

sub new {
 
        my $class = shift;
        my %args = @_;
	my $self = {};

	bless $self, $class;

        $debug && print _trace(),"called\n";   

	# set debug 
	if ( defined ( $args{debug} ) ) {
		$debug = $args{debug};
	}

	return $self;
}

=head2 set_group_name($group_name)
 
Sets the group_name associated with this object 

Accepts a single group_name
 
=cut

sub set_group_name {
	my $self = shift;
	my $group_name = shift;

        $debug && print _trace(),"called\n";   

	# set group name
        $debug && print _trace(),"setting group_name [$group_name]\n";   
	$self->{group_name} = $group_name;
	return 1;
}

=head2 get_group_name()
 
Gets the group_name associated with this object
 
=cut
 
sub get_group_name {
        my $self = shift;

	# return group name
        $debug && print _trace(),"called\n";   
        return $self->{group_name};
}

=head2 add_acl($acl_name,$default_policy)

Add a new ACL to this group

=cut

sub add_acl {
	my $self = shift;
	my $acl_name = shift;
	my $default_policy = shift;
	my $object;

        $debug && print _trace(),"called\n";   

	# make sure we have all necessary arguments before moving on
	if ( ! ($acl_name && $default_policy) ) {
	        $debug && print _trace(),"missing args: acl_name [$acl_name], default_policy [$default_policy]\n";   
		return undef;
	}

	# make sure we don't already have an ACL by this name
	if ( defined $self->{acl}{$acl_name} ) {
	        $debug && print _trace(),"acl name already in use: acl_name [$acl_name]\n";   
		return undef;
	}

	# create object and make sure it exists
	$object = new Authen::RBAC::Group::Acl(debug=>$debug);
	if (! defined ($object) ) {
	        $debug && print _trace(),"unable to create acl: acl_name [$acl_name], default_policy [$default_policy]\n";   
		return undef;
	}

        $debug && print _trace(),"created acl: acl_name [$acl_name], default_policy [$default_policy]\n";   

	# setting acl name and default policy	
	$object->set_acl_name($acl_name);
	$object->set_default_policy($default_policy);

	# add acl to group
        $debug && print _trace(),"adding acl to group\n";   
	$self->{acl}{ $acl_name } = $object;

	return 1;
}

=head2 add_acl_policy($acl_name,$policy_type,$base_pattern,\@additional_patterns)

Adds a policy to an ACL

=cut

sub add_acl_policy {
	my $self = shift;
	my $acl_name = shift;
	my $policy_type = shift;
	my $base_pattern = shift;
	my $add_patterns = shift;
	my $result;

        $debug && print _trace(),"called\n";   

	# only continue if we have the proper arguments
	if ( ! ($acl_name && $policy_type && $base_pattern) ) {
	        $debug && print _trace(),"missing args: acl_name [$acl_name], policy_type [$policy_type], base_pattern [$base_pattern]\n";   
		return undef;
	}

	# make sure acl exists
	if (! (defined $self->{acl}{$acl_name}) ) {
		$debug && print _trace(), "acl does not exist: acl_name [$acl_name]\n";
		return undef;
	}

	# add policy to acl object
        $debug && print _trace(),"adding policy to acl: acl_name [$acl_name],  policy_type [$policy_type], base_pattern [$base_pattern]\n";   
	$result = $self->{acl}{$acl_name}->add_policy($policy_type, $base_pattern, $add_patterns);
	return $result;
}

=head2 delete_acl_policy($acl_name,$policy_type,$base_pattern, $add_patterns)

Removes a policy from an ACL

=cut

sub delete_acl_policy {
	my $self = shift;
	my $acl_name = shift;
	my $policy_type = shift;	
	my $base_pattern = shift;
	my $add_patterns = shift;

	my $result;

        $debug && print _trace(),"called\n";   

	# only continue if we have the proper arguments
	if ( ! ($acl_name && $policy_type && $base_pattern) ) {
	        $debug && print _trace(),"missing args:  acl_name [$acl_name],  policy_type [$policy_type], base_pattern [$base_pattern]\n";   
		return undef;
	}

        # make sure acl exists
        if (! (defined $self->{acl}{$acl_name}) ) {
                $debug && print _trace(), "acl does not exist: acl_name [$acl_name]\n";
                return undef;
        }

	# delete policy from acl
        $debug && print _trace(),"deleting policy from acl: acl_name [$acl_name],  policy_type [$policy_type], base_pattern [$base_pattern]\n";   
	$result = $self->{acl}{$acl_name}->delete_policy($policy_type, $base_pattern, $add_patterns);

        return $result; 
}

=head2 delete_acl($acl_name)

Disassociates an ACL with this record

=cut

sub delete_acl {
	my $self = shift;
	my $acl_name = shift;

        $debug && print _trace(),"called\n";   

	# don't continue without acl name
	if ( !$acl_name) {
	        $debug && print _trace(),"missing acl_name\n";   
		return undef;
	}

	# delete acl from this group
        $debug && print _trace(),"called\n";   
	if ( ! exists $self->{acl}{$acl_name}) {
		$debug && print _trace(),"acl doesn't exist: acl_name [$acl_name]\n";
		return undef;
	}

	delete $self->{acl}{$acl_name};
	return 1;
}

=head2 list_acls()

Returns a reference to a list of acl names

=cut

sub list_acls {
	my $self = shift;
	my @result;

	# fetch list of acl names
	$debug && print _trace(), "called\n";
	@result = keys %{ $self->{acl} };

	return \@result;
}

=head2 get_policies_in_acl($acl_name)

Returns a reference to an array of policy types and base patterns

=cut

sub get_policies_in_acl {
	my $self = shift;
	my $acl_name = shift;

	$debug && print _trace(), "called\n";

	# make sure we were passed an acl name
	if (! $acl_name ) {
		$debug && print _trace(),"missing aclname\n";
		return undef;
	}

	return $self->{acl}{$acl_name}->get_policies_in_acl();
}

=head2 delete_group()

Remove all trace of record

=cut

sub delete_group {
	my $self = shift;

	$debug && print _trace(), "called\n";

	# walk through and delete all acls
	for my $acl_name ( keys %{$self->{acl}} ) {
		$self->delete_acl($acl_name);
	}

	return 1;
}

=head2 check_acl(command,host)

Checks to see if the command passed is allowed to be executed on a specific host

Return 1 for permitted  

Return undef for denied

=cut

sub check_acl {
        my $self = shift;
        my $command = shift;
        my $host = shift;

        $debug && print _trace(),"called with command = [$command], host = [$host]\n";
        for my $acl (keys %{ $self->{acl} }) { 
                if ($self->{acl}{$acl}->check_hostmask($host) ) {
                        $debug && print _trace(),"calling check_hostmask() on host [$host]\n";
                        if ($self->{acl}{$acl}->check_command($command) ) {
                                $debug && print _trace(),"calling check_command() on command [$command]\n";
                                return 1;
                        }
                }
        }
        return undef;
}

=head2 output_xml()
 
Output object as XML
 
=cut

sub output_xml {
        my $self = shift;
        my @result;
        my $group_name = $self->get_group_name();

        $debug && print _trace(),"called\n";   

	# build XML array by recursing ACLs 
	push @result,"<group>";
	push @result,"\t<groupname>$group_name</groupname>";

        for my $acl_name (keys %{$self->{acl}} ) {
		my @object_xml = @{ $self->{acl}{$acl_name}->output_xml() };
		for my $line (@object_xml) {
			push @result,"\t$line";
		}
	}	
	push @result,"</group>";
        return scalar(@result)?\@result:undef;
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

1;
__END__

=head1 AUTHOR

Dennis Opacki, dopacki@adotout.com

=head1 SEE ALSO
perl(1).

=cut
