package eris::log::decoder::json;

use Const::Fast;
use JSON::MaybeXS;
use Moo;
use namespace::autoclean;

with qw(
    eris::role::decoder
);

sub _build_priority { 99; }

sub decode_message {
    my ($self,$msg) = @_;
    my $decoded;
    # JSON Docs will start with a '{', check for it.
    my $start = index($msg, '{');
    if( $start >= 0 ) {
        my $json_str = substr($msg, $start);
        eval {
            $decoded = decode_json( $json_str );
            1;
        };
    }
    return $decoded;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

eris::log::decoder::json

=head1 VERSION

version 0.003

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
