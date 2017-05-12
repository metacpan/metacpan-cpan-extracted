
package Example::TicketAuth;

@Example::TicketAuth::ISA = qw(WebService::TicketAuth::DBI);

use strict;
use WebService::TicketAuth::DBI;
use Config::Simple;

use vars qw($VERSION %FIELDS);
our $VERSION = '1.00';

my $config_file = 'service.cfg';

sub new {
    my ($this) = @_;
    my $class = ref($this) || $this;

    # Load up config file
    my %config;
    if (! Config::Simple->import_from($config_file, \%config)) {
        die "Could not load config file '$config_file': "
            . Config::Simple->error() . "\n";
    }

    my $self = $class->SUPER::new(%config);

    return $self;
}

# Override how long to allow ticket
sub ticket_duration {
    my $self = shift;
    my $username = shift;
    if ($username eq 'admin') {
        # Give admins 15 min login access
        return 15*60;
    } else {
        # Give everyone else 24 hour login
        return 24*60*60;
    }
}

1;
