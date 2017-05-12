package WebService::CloudFlare::Host::Role::Request;
use Moose::Role;

sub as_post_params {
    my ( $self ) = @_;
    my %arguments = map { my $v = $self->{$self->req_map->{$_}}; 
        defined($v) ? ($_ => $v) : ()
    } keys %{$self->req_map};
    return %arguments;
}

sub BUILD {
    my ( $self ) = @_;

    if ( $ENV{'CLOUDFLARE_TRACE'} ) {
        my %args = $self->as_post_params;
        print STDERR "<<< BEGIN CLOUDFLARE TRACE >>>\n";
        print STDERR "\t<- API Call (" . $self. ")\n";
        for my $key ( keys %args ) {
            print STDERR "\t\t$key => \t" . $args{$key} . "\n";
        }
        print STDERR "\t\t--- OMMITED HOST KEY ----\n";
        print STDERR "<<< END   CLOUDFLARE TRACE >>>\n";
    }
}

1;
