package Web::ID::Types;

use 5.010;
use strict;
use utf8;

BEGIN {
	$Web::ID::Types::AUTHORITY = 'cpan:TOBYINK';
	$Web::ID::Types::VERSION   = '1.927';
};

use Math::BigInt;
use RDF::Trine;

use Type::Library
	-base,
	-declare => qw[ Bigint Certificate Finger Model Rsakey San ];
use Type::Utils -all;

BEGIN { extends qw( Types::Standard Types::DateTime Types::URI ) };

class_type Bigint, { class => "Math::BigInt" };
coerce Bigint,
	from Str, q { "Math::BigInt"->new($_) };

class_type Certificate, { class => "Web::ID::Certificate" };
coerce Certificate,
	from HashRef, q { "Web::ID::Certificate"->new(%$_) },
	from Str,     q { "Web::ID::Certificate"->new(pem => $_) };

class_type Finger, { class => "WWW::Finger" };
coerce Finger,
	from Str, q { (UNIVERSAL::can("WWW::Finger", "new") ? "WWW::Finger"->new($_) : undef) };

class_type Model, { class => "RDF::Trine::Model" };

class_type Rsakey, { class => "Web::ID::RSAKey" };
coerce Rsakey,
	from HashRef, q { "Web::ID::RSAKey"->new(%$_) };

class_type San, { class => "Web::ID::SAN" };

__PACKAGE__
__END__

=head1 NAME

Web::ID::Types - type library for Web::ID and friends

=head1 DESCRIPTION

A L<Type::Library> defining:

=head2 Types

=over

=item * C<Bigint>

=item * C<Certificate>

=item * C<Finger>

=item * C<Model>

=item * C<Rsakey>

=item * C<San>

=back

... and re-exporting everything from L<Types::Standard>,
L<Types::DateTime>, and L<Types::URI>.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Web-ID>.

=head1 SEE ALSO

L<Web::ID>, L<Type::Library>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

