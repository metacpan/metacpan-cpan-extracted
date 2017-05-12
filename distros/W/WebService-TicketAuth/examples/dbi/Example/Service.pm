
package Example::Service;

use lib '.';
use strict;
use vars qw($VERSION %FIELDS);
use Example::TicketAuth;

@Example::Service::ISA = qw(Example::TicketAuth);
our $VERSION = '1.01';

sub new {
    my ($this) = @_;
    my $class = ref($this) || $this;
    my $self = $class->SUPER::new(@_);

    return $self;
}


sub public {
    my $self = shift;

    return 'This is a public routine';
}


sub protected {
    my $self = shift;
    my $header = pop;

#    my $username = $auth->get_username($header);
    my $username = 'none';

    return "This is a protected routine, but '$username' is authorized to use it.\n";
}

sub login {
    my $self = shift;
    return $self->SUPER::login(@_);
}
1;
