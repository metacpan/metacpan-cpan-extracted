package WWW::Marvel;
use strict;
use warnings;

our $VERSION = '0.04';

=head1 NAME

WWW::Marvel - A Marvel Comics API

=head1 VERSION

Version 0.04


=head1 SYNOPSIS

  use WWW::Marvel::Config;
  use WWW::Marvel::Client;

  my $cfg = WWW::Marvel::Config::File->new("my_marvel.conf");

  my $client = WWW::Marvel::Client->new({
    public_key  => $cfg->get_public_key,
	private_key => $cfg->get_private_key
  });

  my $data = $client->characters({ name => 'spider-man' });


=head1 DESCRIPTION

This module is an interface to Marvel Comics API
to "create awesome stuff with the world's greatest comic api".

For more information:
http://developer.marvel.com/

Remember to keep you private key private and not store it publicly.

Right now this is a work in progress.


=head1 USAGE

If you wanna query the Marvel Comics API, probably you have to use
the WWW::Marvel::Client module.



=head1 BUGS



=head1 SUPPORT



=head1 AUTHOR

    Simone "SIMOTRONE" Tampieri

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

1;
