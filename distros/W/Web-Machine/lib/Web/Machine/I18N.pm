package Web::Machine::I18N;
# ABSTRACT: The I18N support for HTTP information

use strict;
use warnings;

use parent 'Locale::Maketext';

our $VERSION = '0.17';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Web::Machine::I18N - The I18N support for HTTP information

=head1 VERSION

version 0.17

=head1 SYNOPSIS

  use Web::Machine::I18N;

=head1 DESCRIPTION

This is basic support for internationalization of HTTP
information. Currently it just provides response bodies
for HTTP errors.

=head1 SUPPORT

bugs may be submitted through L<https://github.com/houseabsolute/webmachine-perl/issues>.

=head1 AUTHORS

=over 4

=item *

Stevan Little <stevan@cpan.org>

=item *

Dave Rolsky <autarch@urth.org>

=back

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2016 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
