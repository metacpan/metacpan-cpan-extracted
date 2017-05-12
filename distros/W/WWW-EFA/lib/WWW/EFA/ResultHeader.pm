package WWW::EFA::ResultHeader;
use Moose;
with 'WWW::EFA::Roles::Printable'; # provides to_string

=head1 NAME

WWW::EFA::ResultHeader - Information from the root (itdRequest) element found in every result

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

ResultHeader object acquired through an EFA interface

    use WWW::EFA::ResultHeader;

    my $header = WWW::EFA::ResultHeader->new();
    ...

=head1 ATTRIBUTES

# TODO: RCL 2011-11-06 Document attributes

=cut

has 'version'       => ( is => 'ro', isa => 'Str',          );
has 'language'      => ( is => 'ro', isa => 'Str',          );
has 'length_unit'   => ( is => 'ro', isa => 'Str',          );
has 'session_id'    => ( is => 'ro', isa => 'Str',          );
has 'server_id'     => ( is => 'ro', isa => 'Str',          );
has 'server_time'   => ( is => 'ro', isa => 'Class::Date',  );

1;

=head1 COPYRIGHT

Copyright 2011, Robin Clarke, Munich, Germany

=head1 AUTHOR

Robin Clarke <perl@robinclarke.net>

