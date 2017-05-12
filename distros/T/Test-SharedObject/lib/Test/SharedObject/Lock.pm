package Test::SharedObject::Lock;
use strict;
use warnings;
use utf8;
use Fcntl qw/:flock/;

sub new {
    my ($class, $shared) = @_;
    open my $fh, '+<:raw', $shared->{file} or die "failed to open temporary file: $shared->{file}: $!"; # uncoverable branch
    flock $fh, LOCK_EX;
    return bless { fh => $fh } => $class;
}

sub fh { shift->{fh} }

sub DESTROY {
    my $self = shift;
    flock $self->{fh}, LOCK_UN;
    close $self->{fh};
}

1;
__END__
