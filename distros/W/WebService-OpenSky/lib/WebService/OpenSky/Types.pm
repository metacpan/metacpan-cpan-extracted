package WebService::OpenSky::Types;

# ABSTRACT: Type library for WebService::OpenSky

use v5.20.0;
use warnings;

use Type::Library
  -base,
  -declare => qw(
  Longitude
  Latitude
  Route
  );

use Type::Utils -all;
our $VERSION = '0.5';

BEGIN {
    extends qw(
      Types::Standard
      Types::Common::Numeric
      Types::Common::String
    );
}

declare Longitude, as Num, where { $_ >= -180 and $_ <= 180 };
declare Latitude,  as Num, where { $_ >= -90  and $_ <= 90 };
declare Route,     as NonEmptySimpleStr, where {
    $_ =~ m{
    ^ 
    /\w+
    (?:/\w+)*
$}x
};

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OpenSky::Types - Type library for WebService::OpenSky

=head1 VERSION

version 0.5

=head1 DESCRIPTION

No user-serviceable parts inside.

=head1 CUSTOM TYPES

=head2 Longitude

A number between -180 and 180, inclusive.

=head2 Latitude

A number between -90 and 90, inclusive.

=head2 Route

A non-empty string that matches C<< /^\/\w+(?:\/\w+)*$/ >>.

=head1 AUTHOR

Curtis "Ovid" Poe <curtis.poe@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023 by Curtis "Ovid" Poe.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
