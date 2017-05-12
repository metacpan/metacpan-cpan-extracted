package WWW::EFA::Location;
use Moose;
with 'WWW::EFA::Roles::Printable'; # provides string

=head1 NAME

WWW::EFA::Location - An instance of a location determined through an EFA interface

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Location object acquired through an EFA interface

    use WWW::EFA::Location;

    my $location = WWW::EFA::Location->new();
    ...

=head1 ATTRIBUTES

# TODO: RCL 2011-11-06 Document attributes

=cut

has 'id'                => ( is => 'rw', isa => 'Int',  );
has 'poi_id'            => ( is => 'rw', isa => 'Int',  );
has 'is_transfer_stop'  => ( is => 'rw', isa => 'Bool', );
has 'street_id'         => ( is => 'rw', isa => 'Int',  );

# Distance in meters
has 'distance'          => ( is => 'rw', isa => 'Int',  );
has 'type'              => ( is => 'rw', isa => 'Str',  );
# TODO: RCL 2011-08-20 normalizeLocationName for place/name
has 'locality'          => ( is => 'rw', isa => 'Str',  );
has 'name'              => ( is => 'rw', isa => 'Str',  );
has 'value'             => ( is => 'rw', isa => 'Str',  );
has 'map_name'          => ( is => 'rw', isa => 'Str',  );
has 'state'             => ( is => 'rw', isa => 'Str',  );
has 'usage'             => ( is => 'rw', isa => 'Str',  );

has 'coordinates'       => ( is => 'rw', isa => 'WWW::EFA::Coordinates' );


1;

=head1 COPYRIGHT

Copyright 2011, Robin Clarke, Munich, Germany

=head1 AUTHOR

Robin Clarke <perl@robinclarke.net>
