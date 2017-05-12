package Authen::RBAC::Group::Acl::PolicyFactory;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use Data::Dumper; 

require Exporter;

@ISA = qw(Exporter);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);

$VERSION = '0.01';
my $debug = 1;

=head1 NAME

Authen::RBAC::Group::Acl::PolicyFactory - Perl extension to create POLICY objects of different types

=head1 SYNOPSIS

  use Authen::RBAC::Group::Acl::PolicyFactory;
  my $object = new Authen::RBAC::Group::Acl::PolicyFactory( policy_type => $policy_type );

=head1 DESCRIPTION

If passed an policy_type, this object will return a new POLICY object of the type specified

=cut

=head1 INTERFACE
 
The following methods are available in this module.
 
=cut
 
=head2 new();
 
=cut

sub new {
 
        my $class = shift;
        my %args = @_;
	my $policy_class;
	my $policy_type;

	$debug && print _trace(),"called\n"; 

        # set debug option
        if ( defined ( $args{debug} ) ) {
                $debug =  $args{debug};
        }


	if ( defined ( $args { policy_type } ) ) {
		$policy_type = $args{ policy_type };
		$debug && print _trace(),"policy_type [".$args { policy_type }."]\n"; 
	}
	else {
		$debug && print _trace(),"frivilous request - declined\n"; 
		return undef;
	}

	# this class must exist
	$policy_class = "Authen::RBAC::Group::Acl::PolicyFactory::".$policy_type;
	$debug && print _trace(),"requiring [$policy_class]\n"; 
	eval "require $policy_class";
	return undef if ($@);

	# return a new policy class of the correct type
	$debug && print _trace(),"returning new policy object\n"; 
	return $policy_class->new( debug=>$debug, policy_type=> $policy_type );
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
