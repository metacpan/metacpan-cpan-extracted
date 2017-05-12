package Authen::RBAC::Group::Acl;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use Authen::RBAC::Group::Acl::PolicyFactory;
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

Authen::RBAC::Group::Acl - Perl extension to process ACLs

=head1 SYNOPSIS

  use Authen::RBAC::Group::Acl;
  my $object = new Authen::RBAC::Group::Acl();

=head1 DESCRIPTION

Creates a new ACL

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
                $debug  = $args{debug};
        }

	return $self;
}

=head2 set_acl_name($acl_name)
 
Sets the acl_name associated with this object 

Accepts a single acl_name
 
=cut

sub set_acl_name {
	my $self = shift;

	# set acl name
	$debug && print _trace(),"called\n"; 
	$self->{acl_name} = shift;
	$debug && print _trace(),"set acl_name [".$self->{acl_name}."]\n"; 
	return 1;
}

=head2 get_acl_name()
 
Gets the acl_name associated with this object
 
=cut
 
sub get_acl_name {
        my $self = shift;

	# return acl name
	$debug && print _trace(),"called\n"; 
        return $self->{acl_name};
}

=head2 set_default_policy($default_policy)
 
Sets the default policy associated with this object
 
Accepts a default policy pattern
 
=cut
 
sub set_default_policy {
        my $self = shift;
	my $default_policy  = shift;
	
        $debug && print _trace(),"called\n"; 

	# only set the policy to PERMIT if we specify permit explicitly
	if ( uc ($default_policy) eq 'PERMIT') {
	        $debug && print _trace(),"setting default_policy: PERMIT\n"; 
	        $self->{default_policy} = 'PERMIT';
	}
	# otherwise, set it to deny
	else {
	        $debug && print _trace(),"setting default_policy: DENY\n"; 
		$self->{default_policy} = 'DENY';
	}
        return 1;
}

=head2 get_default_policy()
 
Gets the default policy associated with this object
 
=cut
 
sub get_default_policy {
        my $self = shift;

	# return default policy
        $debug && print _trace(),"called\n"; 
        return $self->{default_policy};
}

=head2 add_policy($type,$base_pattern,\@supp_patterns)

Add a new policy to this object

=cut

sub add_policy {
	my $self = shift;
	my $policy_type = shift;
	my $base_pattern = shift;
	my $r_supp_patterns = shift;
	my $object;

        $debug && print _trace(),"called\n"; 

	# make sure we have all necessary args
	if ( ! ($policy_type && $base_pattern) ) {
	        $debug && print _trace(),"missing args: policy_type [$policy_type], base_pattern [$base_pattern]\n"; 
		return undef;
	}

	# see ig this is a duplicate policy
        $debug && print _trace(),"checking uniqueness of base_pattern within this policy_type\n"; 
	for my $policy ( @{ $self->{policy}{$policy_type}} ) {
		if ($policy->get_base_pattern() eq $base_pattern) {

			# if this is an existing policy,
		        $debug && print _trace(),"found existing acl: policy_type [$policy_type], base_pattern [$base_pattern]\n"; 
	
			# see if we have additional patterns to add
			if ( $policy->can('get_arg_patterns') && ( ref $r_supp_patterns eq 'ARRAY' ) ) {
		                if ( ! scalar ( @{$r_supp_patterns} ) ) {
                		        $debug && print _trace(),"missing supplemental patterns\n";
                        		return undef;
		                }
				# prepare to add additional patterns
		                $debug && print _trace(),"adding supplemental patterns\n";
				my %arg_hash;

				# populate hash with existing patterns
				my $existing_patterns = $policy->get_arg_patterns();
				if ( ref ($existing_patterns) eq 'ARRAY') {
					for my $pattern (@{$existing_patterns}) {
						$debug && print _trace(),"found existing pattern: [$pattern]\n";
						$arg_hash{$pattern}++;
					}
				}

				# merge in new patterns
				for my $pattern (@{$r_supp_patterns}) {
					$debug && print _trace(),"found new pattern: [$pattern]\n";
					$arg_hash{$pattern}++;
				}
				
				# set arguments to pattern merge
				$policy->set_arg_patterns( [keys %arg_hash] );
				
				# done
				return 1;
			}
			else {
				$debug && print _trace(), "unable to augment policy: policy_type [$policy_type], base_pattern [$base_pattern]\n";
				return undef;
			}
		}
	}

	# only continue if we were able to create the policy object
	$object = new Authen::RBAC::Group::Acl::PolicyFactory(policy_type=>$policy_type, debug=>$debug);
	if ( ! ( defined $object ) ) {
	        $debug && print _trace(),"failed to create policy object: policy_type [$policy_type]\n"; 
		return undef;
	}

	# set base pattern
        $debug && print _trace(),"setting base_pattern [$base_pattern]\n"; 
	$object->set_base_pattern($base_pattern);

	# if this object can take extra patterns, add them
	if ( $object->can('set_arg_patterns') && ( ref ($r_supp_patterns) eq 'ARRAY' ) ) {
		if ( ! scalar ( @{$r_supp_patterns} ) ) {
		        $debug && print _trace(),"missing supplemental patterns\n"; 
			return undef;
		}
	        $debug && print _trace(),"adding supplemental patterns\n"; 
		$object->set_arg_patterns( $r_supp_patterns );
	}

	# add this object to the correct portion of our policy hash
        $debug && print _trace(),"adding policy to acl as: policy_type [$policy_type]\n"; 
	push @{ $self->{policy}{$policy_type} }, $object;	

	return 1;
}

=head2 delete_policy($policy_type,$base_pattern,$add_patterns)

Removes a policy from this object

=cut

sub delete_policy {
	my $self = shift;
	my $policy_type = shift;
	my $base_pattern = shift;
	my $add_patterns = shift;
	my @policy_array;

        $debug && print _trace(),"called\n"; 

	# only continue if we have necessary args
	if ( ! ($policy_type && $base_pattern) ) {
	        $debug && print _trace(),"missing args: policy_type [$policy_type], base_pattern [$base_pattern]\n"; 
		return undef;
	}

	# loop through policies and delete the bad one
	for my $policy ( @{ $self->{policy}{ $policy_type } } ) {
		if ( $policy->get_base_pattern() ne $base_pattern ) {
			# keep this policy
		        $debug && print _trace(),"keeping policy [".$policy->get_base_pattern()."]\n"; 
			push @policy_array, $policy;
		}
		else {
			# see if we need to delete whole pattern or just args
			if ( ! ( $policy->can('get_arg_patterns') && (ref ( $add_patterns) eq 'ARRAY' ) ) ){
			        $debug && print _trace(),"deleting policy [".$policy->get_base_pattern()."]\n"; 
			}
			else {
				# just delete args
				my $existing_args = $policy->get_arg_patterns();
				if ( ! (ref $existing_args eq 'ARRAY' ) ) {
				        $debug && print _trace(),"policy has no args to delete\n"; 
					next;
				}
				else {
					# remove args
					my %new_args;
					for my $arg (@{$existing_args}) {
						$new_args{$arg}++;
					}
					for my $arg (@{$add_patterns}) {
						delete $new_args{$arg};
					}
				
					# set arg patterns to new args
					$policy->set_arg_patterns([ keys %new_args ]);

					# save policy if necessary
					if ( scalar (keys %new_args) ) {
						$debug && print _trace(),"args updated - keeping policy\n";
						push @policy_array, $policy;
					}
					else {
						$debug && print _trace(), "all args removed - removing policy\n";
					}
				}
			}
		}
	}

	# reset our policy list
	$self->{policy}{ $policy_type }  = \@policy_array;

	return 1;

}

=head2 get_policies_in_acl()

Returns a reference to an array of policies

=cut

sub get_policies_in_acl {
	my $self = shift;
	my $result;

	$debug && print _trace(), "called\n";

	# can't continue without default policy
	if (! $self->get_default_policy() ) {
		$debug && print _trace(), "default policy not set - can't continue\n";
		return undef;
	}

	# add the default policy
	push @{$result},"Default: ".$self->get_default_policy();

	# walk through each type of policy
	for my $policy_type (qw /Hostmask Deny Permit/) {

		# step through each policy in this type
		for my $policy (@{$self->{policy}{$policy_type}}) {
			my $base_pattern = $policy->get_base_pattern();

			# some policies take additional arguments - handle differently
			if ( $policy->can('get_arg_patterns') ) {
				$debug && print _trace(), "policy has additional args\n";
				my @supp_patterns = @{$policy->get_arg_patterns()};
				for my $pattern (@supp_patterns) {
					push @{$result},"$policy_type: $base_pattern $pattern";
				}
			}
			else {
				$debug && print _trace(), "policy has a single pattern\n";
				push @{$result},"$policy_type: $base_pattern";
			}
		}
	}

	return $result;
}

=head2 check_hostmask(hostmask)

Checks to see if the host specified matches any hostmask

Return mask for match

Return undef for no match

=cut

sub check_hostmask {
        my $self  = shift;
        my $host = shift;
        my $result;

        $debug && print _trace(),"called with host = [$host]\n";
        
        for my $hostmask ( @{ $self->{policy}{Hostmask} }) {
		my $mask = $hostmask->get_base_pattern();
                if ($host =~ /^$mask/) {
                        $debug && print _trace(),"match - [$host] =~ [$mask]\n";
                        $result = $mask;
                }
        }

        return $result;
}

=head2 check_command(command)
        
Checks to see if the command specified is allowed by command masks

Return 1 for allowed

Return undef for denied

=cut

sub check_command {
        my $self = shift;
        my $command = shift;
        
        $debug && print _trace(),"called with command = [$command]\n";
        
        for my $deny ( @{ $self->{policy}{Deny} }) {
		my $base_pattern = $deny->get_base_pattern;
                my @supp_patterns = @{$deny->get_arg_patterns()};
		for my $pattern (@supp_patterns) {
			my $deny_mask = $base_pattern." ".$pattern;
                	$debug && print _trace(),"checking deny mask [$deny_mask] against [$command]\n";
                
	                if ($command =~ /^$deny_mask/) {
         
        	                $debug && print _trace(),"[$command] expressly denied by [$deny_mask]\n";
                	        return undef;
                	}
		}
        }

        for my $permit ( @{ $self->{policy}{Permit} }) {
		my $base_pattern = $permit->get_base_pattern;
                my @supp_patterns = @{$permit->get_arg_patterns()};
		for my $pattern (@supp_patterns) {
			my $permit_mask = $base_pattern." ".$pattern;
                	$debug && print _trace(),"checking permit mask [$permit_mask] against [$command]\n";
                
	                if ($command =~ /^$permit_mask/) {
         
        	                $debug && print _trace(),"[$command] expressly permitted by [$permit_mask]\n";
                	        return 1;
                	}
		}
        }
        
        $debug && print _trace(),"[$command] matches implicit [".$self->get_default_policy()."]\n";
        return ($self->get_default_policy() eq "PERMIT")?1:undef;
}       


=head2 output_xml()
 
Output object as XML
 
=cut

sub output_xml {
        my $self = shift;
        my @result;
        my $acl_name = $self->get_acl_name();
        my $default_policy = $self->get_default_policy();

        $debug && print _trace(),"called\n";			

	# don't continue unless we have proper args
	if ( ! ($acl_name && $default_policy) ) {
	        $debug && print _trace(),"missing args: acl_name [$acl_name], default_policy [$default_policy]\n";			
		return undef;
	}

	# generating XML by recuring policies
        $debug && print _trace(),"generating xml\n";			
	push @result,"<acl info=\"$acl_name\">";
	push @result,"\t<default>$default_policy</default>";
        for my $policy_type ( qw / Hostmask Deny Permit / ) {
                for my $object ( @{$self->{policy}{$policy_type}} ) {
			my @object_xml = @{ $object->output_xml() };
			for my $line (@object_xml) {
				push @result,"\t$line";
			}
		}
	}	
	push @result,"</acl>";

        return scalar(@result)?\@result:undef;
}

=head2 debug()
 
Set the module debug level
 
=cut
 
sub debug {
        my $self = shift;

	# set debug flag
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
