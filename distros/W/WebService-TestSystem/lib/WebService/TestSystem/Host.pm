
=head1 NAME

WebService::TestSystem::Host - Methods for inspecting or placing 
requests against a particular system under test.

=head1 SYNOPSIS

    my $host = new WebService::TestSystem::Host;

=head1 DESCRIPTION

B<WebService::TestSystem::Host> provides a set of routines for 
gathering information about a specific host and for placing requests 
against a given host.  This permits inspecting the host's state,
checking the machine out from the regular queue and reserving it
for a period of time, etc.

The routines in this module are all considered 'private access', and
should not be exported directly through SOAP.  Instead, they are
called from a higher level routine in WebService::TestSystem.

=head1 FUNCTIONS

=cut

package WebService::TestSystem::Host;

use strict;
use DBI;

use vars qw($VERSION %FIELDS);
our $VERSION = '0.06';

use fields qw(
              _app
              _error_msg
              _debug
              );

=head2 new(%args)

Establishes a new WebService::TestSystem::Host instance. 

You must give it a valid WebService::TestSystem object in the 'app'
argument.

=cut

sub new {
    my ($this, %args) = @_;
    my $class = ref($this) || $this;
    my $self = bless [\%FIELDS], $class;

    if (defined $args{'app'}) {
        # TODO:  Check to make sure app can do get_db(), etc.
        $self->{'_app'} = $args{'app'};
    } else {
	return undef;
    }

    return $self;
}


# Internal routine for setting the error message
sub _set_error {
    my $self = shift;
    $self->{'_error_msg'} = shift;
}

=head2 get_error()

Returns the most recent error message.  If any of this module's routines
return undef, this routine can be called to retrieve a message about
what happened.  If several errors have occurred, this will only return
the most recently encountered one.

=cut

sub get_error {
    my $self = shift;
    return $self->{'_error_msg'};
}

                       
1;

__END__

