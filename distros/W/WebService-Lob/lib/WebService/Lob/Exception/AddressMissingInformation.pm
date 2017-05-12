package WebService::Lob::Exception::AddressMissingInformation;
$WebService::Lob::Exception::AddressMissingInformation::VERSION = '0.0107';
use Moo;
extends 'Throwable::Error';

has '+message' => ( default => 'The address you entered was found but more information is needed to match to a specific address.' );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Lob::Exception::AddressMissingInformation

=head1 VERSION

version 0.0107

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/aanari/WebService-Lob/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Ali Anari <ali@anari.me>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Ali Anari.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
