package WWW::Pipeline;
$VERSION = '0.1';

use base Application::Pipeline;

=head1 WWW::Pipeline

WWW::Pipeline is a subclass of Application::Pipeline that establishes phases
useful for handling http requests. Those phases are:

 Initialization ParseRequest GenerateResponse SendResponse Teardown.

=cut

#-- pragmas ---------------------------- 
 use strict;
 use warnings;

#===============================================================================

=head2 Methods defined by WWW::Pipeline

=head3 new

 my $pipeline = MyApplication->new( param => value, ... )

Constructor.  Key/value pairs passed into the constructor will be stored in and
accessibly by the application's C<param()> method.

=cut

sub new {

  my( $class, %params ) = @_;
  my $self = bless {}, $class;

   $self->setPhases( qw(
     Initialization
     ParseRequest
     GenerateResponse
     SendResponse
     Teardown
   ));

   $self->setPluginLocations( qw(
     Application::Pipeline::Services
     WWW::Pipeline::Services
   ));

   $self->loadPlugin( 'WWW::Pipeline::Services', \%params )
    or die "Could not install basic www services";

  return $self;
}

#========
1;

=head2 See Also

Application::Pipeline
WWW::Pipeline::Services

=head2 Authors

Stephen Howard <stephen@thunkit.com>

=head2 License

This module may be distributed under the same terms as Perl itself.

=cut
