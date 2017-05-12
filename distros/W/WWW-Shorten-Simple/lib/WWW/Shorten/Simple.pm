package WWW::Shorten::Simple;

use strict;
use 5.008_001;
our $VERSION = '0.02';

use Carp;

sub new {
    my($class, $impl, @args) = @_;

    unless ($impl) {
        Carp::croak "WWW::Shorten subclass name is required";
    }

    my $subclass =  "WWW::Shorten::$impl";
    $subclass =~ s!::!/!g;
    $subclass .= ".pm";
    eval { require $subclass };
    Carp::croak "Can't load $impl: $@" if $@;

    bless { impl => "WWW::Shorten::$impl", args => \@args }, $class;
}

sub shorten {
    my $self = shift;
    my($url) = @_;

    $self->call_method("makeashorterlink", $url, @{$self->{args}});
}

sub makeashorterlink { shift->shorten(@_) }
sub short_link       { shift->shorten(@_) }

sub unshorten {
    my $self = shift;
    my($url) = @_;

    $self->call_method("makealongerlink", $url, @{$self->{args}});
}

sub makealongerlink { shift->unshorten(@_) }
sub long_link       { shift->unshorten(@_) }

sub call_method {
    my($self, $method, @args) = @_;

    no strict 'refs';
    &{$self->{impl}."::$method"}(@args);
}

1;
__END__

=encoding utf-8

=for stopwords

=for test_synopsis
my $long_url;

=head1 NAME

WWW::Shorten::Simple - Factory wrapper around WWW::Shorten to avoid imports

=head1 SYNOPSIS

  use WWW::Shorten::Simple;

  my $svc = WWW::Shorten::Simple->new('TinyURL');
  my $short_url = $svc->shorten($long_url);
  my $canon_url = $svc->unshorten($short_url);

=head1 DESCRIPTION

WWW::Shorten::Simple is a wrapper (factory) around WWW::Shorten so
that you can create an object representing each URL shortening
service, instead of I<import>ing C<makeashorterlink> function into
your namespace.

This allows you to call multiple URL shortening services in one
package, for instance to call L<WWW::Shorten::RevCanonical> to extract
rev="canonical", fallback to bit.ly if username and API key are
present, and then finally to TinyURL.

  use WWW::Shorten::Simple;

  my @shorteners = (
      WWW::Shorten::Simple->new('RevCanonical'),
      WWW::Shorten::Simple->new('Bitly', $bitly_username, $bitly_api_key),
      WWW::Shorten::Simple->new('TinyURL'),
  );

  my $short_url;
  for my $shortener (@shorteners) {
      $short_url = eval { $shortener->shorten($long_url) } # eval to ignore errors
          and last;
  }

This wrapper works with most WWW::Shorten implementation that
implements the default C<makeashorterlink> and C<makealongerlink>
functions. The options should be able to be passed as an optional
parameters to C<makeashorterlink> function.

=head1 METHODS

=over 4

=item new

  $svc = WWW::Shorten::Simple->new('TinyURL');
  $svc = WWW::Shorten::Simple->new('Bitly', $bitly_username, $bitly_api_key);

Creates a new WWW::Shoten::Simple object. Takes a subclass name and
optional parameters to C<makeashorterlink> call.

=item shorten

  my $short_url = $svc->shorten($url);

Shortens the given URL. Aliases: C<makeashorterlink>, C<short_link>

=item unshorten

  my $long_url = $svc->unshorten($short_url);

Unshortens the given URL. Aliases: C<makealongerlink>, C<long_link>

=back

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<WWW::Shorten>, L<WWW::Shorten::RevCanonical>

=cut
