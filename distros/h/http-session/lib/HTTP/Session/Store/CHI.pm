package HTTP::Session::Store::CHI;
use strict;
use warnings;
use base qw/Class::Accessor::Fast/;
use CHI;
use Encode qw( encode_utf8 is_utf8 );

__PACKAGE__->mk_ro_accessors(qw/chi expires/);

sub new {
    my $class = shift;
    my %args = ref($_[0]) ? %{$_[0]} : @_;
    # check required parameters
    for (qw/chi expires/) {
        Carp::croak "missing parameter $_" unless $args{$_};
    }
    # coerce
    if (ref $args{chi} && ref $args{chi} eq 'HASH') {
        $args{chi} = CHI->new(%{$args{chi}});
    }
    bless {%args}, $class;
}

sub _filter_sid($) {
    my $session_id = shift;
    $session_id = encode_utf8($session_id) if is_utf8($session_id);
    if ($session_id =~ /[\x00-\x20\x7f-\xff]/ || length($session_id) > 250) {
        die "detected memcached injection: $session_id";
    }
    return $session_id;
}

sub select {
    my ( $self, $session_id ) = @_;
    my $data = $self->chi->get(_filter_sid $session_id);
}

sub insert {
    my ($self, $session_id, $data) = @_;
    $self->chi->set( _filter_sid($session_id), $data, $self->expires );
}

sub update {
    my ($self, $session_id, $data) = @_;
    $self->chi->set( _filter_sid($session_id), $data, $self->expires );
}

sub delete {
    my ($self, $session_id) = @_;
    $self->chi->remove( _filter_sid($session_id) );
}

sub cleanup { Carp::croak "This storage doesn't support cleanup" }

1;
__END__

=head1 NAME

HTTP::Session::Store::CHI - store session data with CHI

=head1 SYNOPSIS

    HTTP::Session->new(
        store => HTTP::Session::Store::CHI->new(
            chi => CHI->new(driver => 'memory'),
        ),
        state => ...,
        request => ...,
    );

    # or 

    HTTP::Session->new(
        store => HTTP::Session::Store::CHI->new(
            chi => {driver => 'memory'},
        ),
        state => ...,
        request => ...,
    );

=head1 DESCRIPTION

store session data with CHI

=head1 CONFIGURATION

=over 4

=item memd

instance of CHI::Driver

=item expires

session expire time(in seconds)

=back

=head1 METHODS

=over 4

=item select

=item update

=item delete

=item insert

for internal use only

=back

=head1 SEE ALSO

L<HTTP::Session>, L<CHI>

