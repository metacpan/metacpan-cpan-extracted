package Wurm::mob;

use strict;
use warnings;

use Plack::Util::Accessor qw(mind env log req res tube seen grit vent);
use Plack::Request;
use Plack::Response;

sub new {
  my ($class, $meal) = @_;

  $meal->{req} = Plack::Request->new($meal->{env});
  $meal->{res} = Plack::Response->new(200);
  return bless $meal, $class;
}

sub response {$_[0]->{res}}
sub request  {$_[0]->{req}}

'.oOo.' # in wurm i trust
__END__

=pod

=head1 NAME

Wurm::mob - Meal OBject.  You asked.

=head1 SYOPSIS

  use Wurm qw(mob);

  ...

  sub handler {
    my $meal = shift;

    $meal->log->({level => 'debug', message => 'Meal OBjects!'});

    $meal->res->header('Content-Type', 'text/plain');
    $meal->res->content('Hi, '. $meal->req->address. '!');
    return $meal->res;
  }

  ...

=head1 DESCRIPTION

Tired of crummy old C<HASH>es in your request handlers?  Upgrade them
with the power of mob!  There are two ways:

  use Wurm::mob;

- or -

  use Wurm qw(mob);

=head1 ADDITIONS

It wouldn't be correct to enable OO without adding some stuff!  Here are
some additions to the C<meal> that each of your request handlers will enjoy:

=over

=item req

Set to a C<Plack::Request> object created with the current C<$env>.  First
class meals for first class requests.  Can also be accessed with C<request()>.

=item res

Set to a C<Plack::Response> object wth the status set to 200.  Provides a
very convenient way to generate PSGI responses and C<finalize()> will be
called for you.  Can also be accessed with C<response()>.

=back

=head1 ACCESSORS

The following accessors are provided for ease-of-abuse:

=over

=item mind

=item env

=item log

=item req

=item res

=item tube

=item seen

=item grit

=item vent

=back

=head1 THE BAD NEWS

If mob is loaded, L<Wurm> will automatically upgrade all incoming requests
to use C<Wurm::mob>s for all C<meal>s for all applications.  For ever.  If
you need to turn this behavior off in a particular application, you can
add C<mob =E<gt> 0> to your folding ruleset and C<meal>s will remain a C<HASH>.

=head1 SEE ALSO

=over

=item L<Wurm>

=back

=head1 AUTHOR

jason hord E<lt>pravus@cpan.orgE<gt>

=head1 LICENSE

This software is information.
It is subject only to local laws of physics.

=cut
