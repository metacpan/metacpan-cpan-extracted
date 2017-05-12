package eris::log::context::GeoIP;

use Const::Fast;
use GeoIP2::Database::Reader;
use Moo;
use Types::Standard qw(Any Bool Str);

use namespace::autoclean;
with qw(
    eris::role::context
);

has 'geo_db' => (
    is      => 'ro',
    isa     => Str,
    default => '/usr/share/GeoIP/GeoLite2-City.mmdb',
);
has 'geo_lookup' => (
    is      => 'ro',
    isa     => Any,
    lazy    => 1,
    builder => '_build_geo_lookup',
);
has 'warnings' => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
);

# Config this object
sub _build_priority { 100 }
sub _build_field { '_exists_' }
sub _build_matcher { qr/_ip$/ }
sub _build_geo_lookup {
    my ($self) = @_;

    my $g;
    eval {
        $g = GeoIP2::Database::Reader->new(
            file => $self->geo_db,
            locales => [ 'en' ],
        );
        1;
    } or do {
        my $err = $@;
        warn sprintf "Failed loading GeoIP Database '%s' with error: %s",
            $self->geo_db,
            $err;
    };
    return $g;
}

sub sample_messages {
    my @msgs = split /\r?\n/, <<EOF;
EOF
    return @msgs;
}

sub contextualize_message {
    my ($self,$log) = @_;

    my $geo = $self->geo_lookup;
    return unless $geo;

    my %add = ();
    my $ctxt = $log->context;

    foreach my $f ( keys %{ $ctxt } ) {
        next unless $f =~ /^(.*)_ip$/;
        my $add_key = $1 . "_geoip";
        my %geo = ();
        eval {
            my $city = $self->geo_lookup->city( ip => $ctxt->{$f} );
            $geo{city}  = $city->city->name;
            $geo{country}  = $city->country->iso_code;
            $geo{continent}  = $city->continent->code;
            my $loc = $city->location();
            $geo{location} = join(',', $loc->latitude, $loc->longitude);
            my @traits = ();
            my $traits = $city->traits;
            if( $traits->is_anonymous_proxy ) {
                push @traits, qw(anonymous proxy);
            }
            elsif( $traits->is_legitimate_proxy ) {
                push @traits, 'proxy';
            }
            elsif( $traits->is_satellite_provider ) {
                push @traits, 'satellite';
            }
            $geo{traits} = \@traits if @traits;
            my $pc = $city->postal->code;
            $geo{postal_code} = $pc if $pc;
        } or do {
            my $err = $@;
            warn sprintf("Geo lookup failed on %s: %s", $ctxt->{$f}, $err) if $self->warnings;
        };
        $add{$add_key} = \%geo if keys %geo;
    }

    $log->add_context($self->name,\%add) if keys %add;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

eris::log::context::GeoIP

=head1 VERSION

version 0.003

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
