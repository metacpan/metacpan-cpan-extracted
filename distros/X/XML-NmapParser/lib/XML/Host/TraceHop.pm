package NmapParser::Host::TraceHop; 
use base NmapParser::Host;

my @ISA = "Host";
  
use vars qw($AUTOLOAD);


sub new {
    my $pkg = shift;
    my $self = bless {}, $pkg;

    $self->initialize(@_);
    return $self;
}

sub initialize {
    my $self = shift;
    $self->SUPER::initialize(shift, shift);
    $self->{TraceHop} = shift;
}


sub ttl{ }
sub rtt{ }
sub ipaddr{ }
sub host{ }
