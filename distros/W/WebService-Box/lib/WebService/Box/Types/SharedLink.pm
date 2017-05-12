package WebService::Box::Types::SharedLink;

use strict;
use warnings;

use Moo;
use Types::Standard qw(Int Str Dict);

use WebService::Box::Types::Library qw(
    OptionalTimestamp OptionalStr SharedLinkPermissionHash
);

our $VERSION = 0.01;

has [qw/url download_url access/]        => (is => 'ro', isa => Str);
has [qw/download_count preview_count/]   => (is => 'ro', isa => Int);
has [qw/vanity_url is_password_enabled/] => (is => 'ro', isa => OptionalStr);

has unshared_at => (is => 'ro', isa => OptionalTimestamp);
has permission  => (is => 'ro', isa => SharedLinkPermissionHash);

1;

__END__

=pod

=head1 NAME

WebService::Box::Types::SharedLink

=head1 VERSION

version 0.02

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
