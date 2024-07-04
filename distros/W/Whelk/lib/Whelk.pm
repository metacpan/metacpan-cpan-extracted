package Whelk;
$Whelk::VERSION = '0.02';
use Kelp::Base 'Kelp';

attr 'config_module' => '+Whelk::Config';

sub before_dispatch { }

sub build
{
	my ($self) = @_;

	$self->whelk->finalize;
}

1;

__END__

=pod

=head1 NAME

Whelk - A friendly API framework based on Kelp

=head1 SYNOPSIS

	$ kelp-generator --type=whelk MyResource
	$ plackup

=head1 DESCRIPTION

Whelk is an API framework which helps you create correct, fast,
self-documenting APIs. It's easy to learn, fun to work with and extremely
customizable. It can be run either standalone as a L<Plack> application, or
inside a L<Kelp> application as a module.

Whelk is integrated with OpenAPI/Swagger and automatically generates a document
according to spec v3 rules. All the data for the document is taken directly
from your endpoint validation rules, which ensures only minimal effort is
needed to generate a documentation for your project. The resulting
documentation can be beautifully visualized using OpenAPI tools like Swagger
UI.

Whelk is currently in beta. It's not production ready and some changes in
interface are possible. Beta phase will end no later than Q3 2024 with version
C<1.00>.

To get started, take a look at L<Whelk::Manual>.

=head1 ACKNOWLEDGEMENTS

This module was inspired by L<Raisin>.

Thank you to Stefan Geneshky who created L<Kelp>.

=head1 AUTHOR

Bartosz Jarzyna E<lt>bbrtj.pro@gmail.comE<gt>

Consider supporting my effort: L<https://bbrtj.eu/support>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Bartosz Jarzyna

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

