package Authen::RBAC::Group::Acl::PolicyFactory::Permit;

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

Authen::RBAC::Group::Acl::PolicyFactory::Permit - Perl extension to process "Permit" policies

=head1 SYNOPSIS

  use Authen::RBAC::Group::Acl::PolicyFactory::Permit;
  my $object = new Authen::RBAC::Group::Acl::PolicyFactory::Permit();

=head1 DESCRIPTION

Creates a new Permit object

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
	$self->{typename} = shift;

	# set type name
        $debug && print _trace(),"called\n";   
        $debug && print _trace(),"set typename [".$self->{typename}."]\n";   
	return 1;
}

=head2 get_typename()
 
Gets the typename associated with this object
 
=cut
 
sub get_typename {
        my $self = shift;

	# return typename
        $debug && print _trace(),"called\n";   
        return $self->{typename};
}

=head2 set_base_pattern($base_pattern)
 
Sets the base pattern associated with this object
 
Accepts a single base pattern
 
=cut
 
sub set_base_pattern {
        my $self = shift;
        $self->{base_pattern} = shift;

	# set base pattern
        $debug && print _trace(),"called\n";   
        $debug && print _trace(),"set base_pattern [".$self->{base_pattern}."]\n";   
        return 1;
}
 
=head2 get_base_pattern()
 
Gets the base pattern associated with this object
 
=cut
 
sub get_base_pattern {
        my $self = shift;
	
	# get base pattern
        $debug && print _trace(),"called\n";   
        return $self->{base_pattern};
}

=head2 set_arg_patterns(\@arg_patterns)
 
Sets the argument patterns associated with this object
 
Accepts a reference to an array of argument patterns
 
=cut
 
sub set_arg_patterns {
        my $self = shift;
        $self->{arg_patterns} = shift;

	# set arg patterns
        $debug && print _trace(),"called\n";   
        $debug && print _trace(),"set arg patterns [".join(",",@{$self->{arg_patterns}})."]\n";   
        return 1;
}
 
=head2 get_arg_patterns()
 
Gets the argument patterns associated with this object
 
=cut
 
sub get_arg_patterns {
        my $self = shift;

	# return a reference to an array of arg patterns
        $debug && print _trace(),"called\n";   
	return $self->{arg_patterns};
}

=head2 output_xml()
 
Output this object as XML
 
=cut

sub output_xml {
	my $self = shift;
	my @result;
	my $base_pattern = $self->get_base_pattern();
	my @arg_patterns = (ref $self->get_arg_patterns() eq 'ARRAY')?@{$self->get_arg_patterns()}:();

        $debug && print _trace(),"called\n";   

	# build an XML array and return a reference to it
	if ( $base_pattern && scalar (@arg_patterns) ) {
		push @result,"<permit cmd=\"$base_pattern\">";
			for my $arg ( @arg_patterns ) {
				push @result,"\t<argmask>$arg</argmask>";
			}
		push @result,"</permit>";
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
