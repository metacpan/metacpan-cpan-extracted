package WWW::Google::Cloud::Messaging::Constants;

use strict;
use warnings;
use Exporter 'import';

our @EXPORT = qw{
    MissingRegistration
    MismatchSenderId
    InvalidRegistration
    NotRegistered
    MessageTooBig
    InvalidDataKey
    InvalidTtl
    Unavailable
    InternalServerError
    InvalidPackageName
};

use constant {
    MissingRegistration => 'MissingRegistration',
    InvalidRegistration => 'InvalidRegistration',
    MismatchSenderId    => 'MismatchSenderId',
    NotRegistered       => 'NotRegistered',
    MessageTooBig       => 'MessageTooBig',
    InvalidDataKey      => 'InvalidDataKey',
    InvalidTtl          => 'InvalidTtl',
    Unavailable         => 'Unavailable',
    InternalServerError => 'InternalServerError',
    InvalidPackageName  => 'InvalidPackageName',
};

1;

__END__

=encoding utf-8

=for stopwords

=head1 NAME

WWW::Google::Cloud::Messaging::Constants - constants for WWW::Google::Cloud::Messaging

=head1 FUNCTIONS

=head2 C<< MissingRegistration >>

=head2 C<< InvalidRegistration >>

=head2 C<< MismatchSenderId >>

=head2 C<< NotRegistered >>

=head2 C<< MessageTooBig >>

=head2 C<< InvalidDataKey >>

=head2 C<< InvalidTtl >>

=head2 C<< Unavailable >>

=head2 C<< InternalServerError >>

=head2 C<< InvalidPackageName >>

=head1 AUTHOR

xaicron E<lt>xaicron@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2012 - xaicron

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<< WWW::Google::Cloud::Messaging >>

=cut
