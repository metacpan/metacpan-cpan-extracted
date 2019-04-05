package URI::s3;
use 5.008001;
use strict;
use warnings;
use version;

use parent qw/URI::_server/;

our $VERSION = version->declare('v0.2');

sub bucket { shift->host }

sub key {
    my $self = shift;
    (my $key = $self->path) =~ s!^/!!;
    return $key;
}

1;
__END__

=encoding utf-8

=head1 NAME

URI::s3 - s3 URI scheme

=head1 SYNOPSIS

    use URI;

    my $uri = URI->new("s3://example-bucket/path/to/object");
    $uri->bucket; # example-bucket
    $uri->key;    # path/to/object

=head1 DESCRIPTION

URI::s3 is an URI scheme handler for C<s3://> protocol.

=head1 SEE ALSO

L<URI>

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut

