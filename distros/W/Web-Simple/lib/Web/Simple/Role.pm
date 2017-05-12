package Web::Simple::Role;
use strictures 1;
use warnings::illegalproto ();
use Moo::Role ();

our $VERSION = '0.033';

sub import {
  my ($class, $app_package) = @_;
  $app_package ||= caller;
  eval "package $app_package; use Web::Dispatch::Wrapper; use Moo::Role; 1"
    or die "Failed to setup app package: $@";
  strictures->import;
  warnings::illegalproto->unimport;
}

1;
__END__

=head1 NAME

Web::Simple::Role - Define roles for Web::Simple applications

=head1 SYNOPSIS

  package MyApp;
  use Web::Simple;
  with MyApp::Role;

  sub dispatch_request { ... }

and in the role:

  package MyApp::Role;
  use Web::Simple::Role;

  around dispatch_request => sub {
    my ($orig, $self) = @_;
    return (
      $self->$orig,
      sub (GET + /baz) { ... }
    );
  };

Now C<MyApp> can also dispatch C</baz>

=head1 AUTHORS

See L<Web::Simple> for authors.

=head1 COPYRIGHT AND LICENSE

See L<Web::Simple> for the copyright and license.

=cut
