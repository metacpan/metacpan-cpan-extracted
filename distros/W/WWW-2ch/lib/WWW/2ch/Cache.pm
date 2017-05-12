package WWW::2ch::Cache;
use strict;

use Storable qw(freeze thaw);

use WWW::2ch::Cache::File;

sub new {
    my $class = shift;
    my $cache = shift;

    my $self = bless {}, $class;

    if (ref($cache) =~ /^Cache::/) {
	$self->{cache} = $cache;
    } elsif ($cache) {
	$self->{cache} = WWW::2ch::Cache::File->new($cache);
    }
    $self;
}

sub set {
    my ($self, $key, $data) = @_;
    return unless $self->{cache};
    $self->{cache}->set($key, freeze $data);
}

sub get {
    my ($self, $key) = @_;
    return +{} unless $self->{cache};

    my $data = $self->{cache}->get($key);
    return +{} unless $data;
    thaw $data;
}

1;
