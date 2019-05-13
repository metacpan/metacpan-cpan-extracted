package Test::Mojo::Role::Session;

use Role::Tiny;
use Test::Mojo::Session;

sub session_has   { Test::Mojo::Session::session_has(@_) }
sub session_hasnt { Test::Mojo::Session::session_hasnt(@_) }
sub session_is    { Test::Mojo::Session::session_is(@_) }
sub session_ok    { Test::Mojo::Session::session_ok(@_) }

sub _extract_session { Test::Mojo::Session::_extract_session(@_) }

1;

__END__

=head1 NAME

Test::Mojo::Role::Session - Testing session in Mojolicious applications

=head1 SYNOPSIS

  use Mojolicious::Lite;
  use Test::More;
  use Test::Mojo::WithRoles 'Session';

  get '/set' => sub {
    my $c = shift;
    $c->session(s1 => 'session data');
    $c->session(s3 => [1, 3]);
    $c->render(text => 's1');
  } => 'set';

  my $t = Test::Mojo::WithRoles->new;
  $t->get_ok('/set')
    ->status_is(200)
    ->session_ok
    ->session_has('/s1')
    ->session_is('/s1' => 'session data')
    ->session_hasnt('/s2')
    ->session_is('/s3' => [1, 3]);

  done_testing();

=head1 DESCRIPTION

L<Test::Mojo::Role::Session> is an role for the L<Test::Mojo::WithRoles>, which allows you
to conveniently test session in L<Mojolicious> applications.

=head1 METHODS

L<Test::Mojo::Role::Sesssion> has the same methods as L<Test::Mojo::Session>.

=head1 SEE ALSO

L<Test::Mojo::WithRoles>.

=cut
