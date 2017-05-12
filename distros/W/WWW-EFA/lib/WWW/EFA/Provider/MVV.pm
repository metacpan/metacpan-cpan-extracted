package WWW::EFA::Provider::MVV;
use Moose;

extends 'WWW::EFA';

=head1 NAME

WWW::EFA::Provider::MVV - Interface to the MVV (Münchner Verkehrs- und Tarifverbund GmbH)

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

See WWW::EFA for details

=cut

has '+base_url' => (
    default  => sub{ 'http://efa.mvv-muenchen.de/mobile/' },
    );

1;
