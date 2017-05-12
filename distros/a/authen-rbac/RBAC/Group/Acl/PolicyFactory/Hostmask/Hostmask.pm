package Authen::RBAC::Group::Acl::PolicyFactory::Hostmask;

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
my $debug = 0;

=head1 NAME

Authen::RBAC::Group::Acl::PolicyFactory::Hostmask - Perl extension to process "Hostmask" policies

=head1 SYNOPSIS

  use Authen::RBAC::Group::Acl::PolicyFactory::Hostmask;
  my $object = new Authen::RBAC::Group::Acl::PolicyFactory::Hostmask();

=head1 DESCRIPTION

Otherwise, a new Hostmask object will be created

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

        # set debug mode
        if ( defined ( $args{debug} ) ) {
                $debug = $args{debug};
        }

	if ( defined ( $args { policy_type } ) ){
		# Create a new Hostmask object
	        $debug && print _trace(),"received arg:policy_type [".$args{policy_type}."]\n";
		$self->set_typename( $args { policy_type } );
	}
	
	return $self;
}

=head2 set_typename($typename)
 
Sets the typename associated with this object 

Accepts a single typename
 
=cut

sub set_typename {
	my $self = shift;

	# set the typename
	$self->{typename} = shift;
        $debug && print _trace(),"setting typename to [".$self->{typename}."]\n";
	return 1;
}

=head2 get_typename()
 
Gets the typename associated with this object
 
=cut
 
sub get_typename {
        my $self = shift;

	# return the type name
        $debug && print _trace(),"called\n";
        return $self->{typename};
}

=head2 set_base_pattern($base_pattern)
 
Sets the base pattern associated with this object
 
Accepts a single base pattern
 
=cut
 
sub set_base_pattern {
        my $self = shift;

	# set the base pattern
        $self->{base_pattern} = shift;
        $debug && print _trace(),"setting base_pattern to [".$self->{base_pattern}."]\n";
        return 1;
}
 
=head2 get_base_pattern()
 
Gets the base pattern associated with this object
 
=cut
 
sub get_base_pattern {
        my $self = shift;

	# return the stored base pattern
        $debug && print _trace(),"called\n";
        return $self->{base_pattern};
}

=head2 output_xml()
 
Output object as XML
 
=cut

sub output_xml {
        my $self = shift;
        my @result;
        my $base_pattern = $self->get_base_pattern();

        $debug && print _trace(),"called\n";
        $debug && print _trace(),"found base_pattern [$base_pattern]\n";
 
	# build an XML array and return it
        if ( $base_pattern ) {
        	push @result,"<hostmask>$base_pattern</hostmask>";
        }
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
