package Ubic::ServiceLoader::Base;
$Ubic::ServiceLoader::Base::VERSION = '1.60';
# ABSTRACT: abstract base class for service loaders

use strict;
use warnings;

sub new {
    die "not implemented";
}

sub load {
    die "not implemented";
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Ubic::ServiceLoader::Base - abstract base class for service loaders

=head1 VERSION

version 1.60

=head1 DESCRIPTION

If you want to add new loader for file with extension C<.foo>, you should implement C<Ubic::ServiceLoader::Ext::foo> module, inheriting from this class and overriding its methods.

=head1 METHODS

=over

=item B<new>

Constructor.

=item B<load($file)>

Service loading code. Should return L<Ubic::Service> object based on config file C<$file>.

=back

=head1 AUTHOR

Vyacheslav Matyukhin <mmcleric@yandex-team.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
