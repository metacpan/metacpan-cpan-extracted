package t::Cache;

use Storable qw/ freeze thaw /;
use YAML::Syck;
use strict;
use warnings;

sub new {
    my $class = shift;
    my $args = shift;
    my $namespace = $args->{namespace} || 'test';
    my $file = "t/cache/$namespace.yml";
    return bless {
        data => load_cache($file),
        file => $file,
    }, $class;
}

sub get {
    my ($self, $key) = @_;
    my $value = $self->{data}->{$key};
    if (defined $value) {
        #warn "Hit!";
        return freeze $value;
    }
    undef;
}

sub set {
    my ($self, $key, $value) = @_;
    $self->{data}->{$key} = thaw $value;
    $self->save_cache;
}

sub load_cache {
    my $fname = shift;
    if (-f $fname) {
        #warn "Cache found";
        return LoadFile($fname);
    }
    return {};
}

sub save_cache {
    my ($self) = @_;
    DumpFile($self->{file}, $self->{data});
}

1;
