package Net::eNom;

use strict;
use warnings;
use utf8;

use Moose;
use namespace::autoclean;

extends 'WWW::eNom';

warnings::warnif(
    deprecated => 'This module is deprecated; use WWW::eNom instead.'
);

our $VERSION = 'v2.7.0'; # VERSION
# ABSTRACT: DEPRECATED: Namespace Retired - Use WWW::eNom Instead

1;

__END__

=pod

=encoding utf8

=head1 NAME

Net::eNom - Interact with eNom, Inc.'s Reseller API

=head1 SYNOPSIS

    use Net::eNom;

=head1 DEPRECATION WARNING

B<This namespace is deprecated!>

You should be making use of L<WWW::eNom> instead.

=head1 DESCRIPTION

This module is a subclass of L<WWW::eNom> with no additional features. It exists to provide backward compatibility with the present distribution's previous namespace.

=head1 AUTHOR

Robert Stone, C<< <drzigman AT cpan DOT org> >>

Original version by Simon Cozens C<< <simon at simon-cozens.org> >>.
Then maintained and expanded by Richard Simões, C<< <rsimoes AT cpan DOT org> >>.

=head1 COPYRIGHT & LICENSE

Copyright © 2016 Robert Stone. This module is released under the terms of the B<MIT License> and may be modified and/or redistributed under the same or any compatible license.
