package WWW::Pipeline::Services::RunModes;
$VERSION = '0.1';

#-- pragmas ---------------------------- 
 use strict;
 use warnings;

=head1 WWW::Pipeline::Services::RunModes

This plugin is an implementation of the Run Mode paradigm as seen in Jesse
Erlbaum's CGI::Application module.

The quick summary of the Run Mode concept is that a web application will
typically need one function for each screen of output.  Which screen to produce
is determined by the data in the request received.  Rather than writing a very
large set of if/else statements or a switch statement, the Run Mode concept uses
a hash table of named callbacks to represent the possible responses, and a
decision mechanism generates the key to the hash which determines which run mode
is run.  The decision mechanism may be as simple as a CGI parameter, or as
complex as parsing different parts of the request, paired with authorization
data.

One thing that this plugin does not replicate, however, is the run mode decision
mechanism. Deciding which run mode to use can be done in many ways, and would
best be done by a handler (or two - in the case where the run mode may be
changed according to user authorization) installed during the ParseRequest phase
of the Pipeline.

=cut

#== Plugin =====================================================================

sub load {
    my( $class, $pipeline ) = @_;

    my $self = bless {}, $class;

    $pipeline->addServices(
        run_modes => sub { $self->run_modes(@_) },
        mode => sub { $self->mode(@_) }
    );

    $pipeline->addHandler( 'GenerateResponse', \&executeRunMode );

    return $self;
}

#== Services ===================================================================

=head2 Services

=head3 run_modes

 #set:
 $self->run_modes(
     one => \&doSomething,
     two => 'doSomethingElse'
 );

 #retrieve
 my $method = $self->run_modes('one');

 #reassign:
 $self->run_modes('one' => \&someOtherMethod );

 #delete:
 $self->run_modes( two => undef );

This service stores and manipulates a list of run modes to be used by the
plugin's GenerateResponse handler.  Run Modes may either be specified by name
or by subroutine reference. Specifying by name makes way for inheritence, while

=cut

sub run_modes {

    my( $self, $pipeline, @params ) = @_;

    if( @params == 1 ) {
        return defined $self->{_run_modes}{$params[0]}
             ? $self->{_run_modes}{$params[0]}
             : undef;
    }

    die "run_modes expects a hash of run modes if you pass it more than one parameter"
      if @params % 2 != 0;

    my %modes = @params;
    while( my( $key,$mode ) = each %modes ) {
        if( defined $mode ) {
            $self->{_run_modes}{$key} = $mode;
        }
        else {
            delete $self->{_run_modes}{$key};
        }
    }
}

#-------------------------------------------------------------------------------

=head3 mode

 #set
 $self->mode('one');
 
 #retrieve
 $self->mode();

This service stores the decision made by the application as to which run mode is
to be run during the GenerateResponse phase.

=cut

sub mode {

    my( $self, $pipeline, $value ) = @_;

    if( @_ == 3 ) {
        return $self->{_mode} = $value;
    }

    return $self->{_mode};
}

#== Handlers ===================================================================

=head2 Handlers

=head3 executeRunMode

this handler, installed during the GenerateResponse phase, takes the information
provided to the C<run_modes> and C<mode> services and determines what method to
execute.  It then runs that run mode, capturing its output. It expects that the
output the method returns is the content it wants to return to the user, and
stores it via the application's C<response> service for later retrieval.

=cut

sub executeRunMode {
    my $pipeline = shift;
    my $method   = $pipeline->run_modes( $pipeline->mode() );
    my $response = defined $pipeline->response()
                 ? $pipeline->response()
                 : '';

    if( ref $method eq 'CODE' ) {

        $response .= $pipeline->$method();
    }
    elsif($pipeline->can($method)) {
        $response .= $pipeline->$method();
    }
    else {
        die "pipeline can't run method '$method'";
    }

    $pipeline->response($response);
}

#========
1;

=head2 Authors

Stephen Howard <stephen@thunkit.com>

=head2 License

This module may be distributed under the same terms as Perl itself.

=cut
