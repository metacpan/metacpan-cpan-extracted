package Test2::Tools::HTTP::UA::Mojo::Proxy;

use strict;
use warnings;
use Mojo::Base 'Mojo::UserAgent::Proxy';

# ABSTRACT: Proxy class for Test2::Tools::HTTP::UA::Mojo
our $VERSION = '0.03'; # VERSION


has 'apps';
has 'apps_proxy_url';

sub prepare
{
  my ($self, $tx) = @_;
  
  if($self->apps->uri_to_app($tx->req->url.""))
  {
    $tx->req->proxy($self->apps_proxy_url);
    return;
  }
  else
  {
    return $self->SUPER::prepare($tx);
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Tools::HTTP::UA::Mojo::Proxy - Proxy class for Test2::Tools::HTTP::UA::Mojo

=head1 VERSION

version 0.03

=head1 SYNOPSIS

 use Test2::Tools::HTTP::UA::Mojo;

=head1 DESCRIPTION

This is a private class.  For details on how to use, see
L<Test2::Tools::HTTP::UA::Mojo>.

=head1 SEE ALSO

=over 4

=item L<Test2::Tools::HTTP::UA::Mojo>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
