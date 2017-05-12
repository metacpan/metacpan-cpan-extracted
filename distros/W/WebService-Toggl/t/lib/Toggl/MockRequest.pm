package Toggl::MockRequest;

use Toggl::DummyAPI;
use Toggl::DummyReport;

use Moo;
use namespace::clean;

has get_call_count => (is => 'ro', default => 0);
sub incr_get_call { $_[0]->{get_call_count}++ }

has user_agent_id => (is => 'ro', default => 'Toggl-MockRequest');

sub get {
    my ($self, $url) = @_;
    $self->incr_get_call;
    $url =~ s{^/}{};
    my $class = $url =~ m/reports/ ? 'Toggl::DummyReport' : 'Toggl::DummyAPI';
    return $class->new({url => $url});
}


1;
__END__
