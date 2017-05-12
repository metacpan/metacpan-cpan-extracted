package WWW::EFA::Departure;
use Moose;
with 'WWW::EFA::Roles::Printable'; # provides to_string

=head1 NAME

WWW::EFA::Departure - An instance of a Departure detail

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Departure object acquired through an EFA interface

    use WWW::EFA::Departure;

    my $departure = WWW::EFA::Departure->new();
    ...

=head1 ATTRIBUTES

# TODO: RCL 2011-11-06 Document attributes

=cut

has 'stop_id'           => ( is => 'ro', isa => 'Int',          );
has 'time'              => ( is => 'ro', isa => 'Class::Date',  );
has 'line_id'           => ( is => 'ro', isa => 'Str',          );
has 'area'              => ( is => 'ro', isa => 'Int'           );
has 'platform'          => ( is => 'ro', isa => 'Str',          );
has 'platform_name'     => ( is => 'ro', isa => 'Str',          );
has 'countdown'         => ( is => 'ro', isa => 'Int',          );

1;

=head1 COPYRIGHT

Copyright 2011, Robin Clarke, Munich, Germany

=head1 AUTHOR

Robin Clarke <perl@robinclarke.net>
