package WebService::ValidSign::Types;
our $VERSION = '0.003';
use warnings;
use strict;

# ABSTRACT: Moo(se) like types defined for WebService::ValidSign

use Types::Standard qw(Str);
use URI;
use Type::Utils -all;
use Type::Library
    -base,
    -declare => qw(
        WebServiceValidSignURI
        WebServiceValidSignAuthModule
    );

class_type WebServiceValidSignURI, {class => 'URI' };
coerce WebServiceValidSignURI, from Str, via { return URI->new($_); };

class_type WebServiceValidSignAuthModule, {class => 'WebService::ValidSign::API::Auth' };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::ValidSign::Types - Moo(se) like types defined for WebService::ValidSign

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    package Foo;
    use Moo;

    use WebService::ValidSign::Types qw(WebServiceValidSignURI);

    has bar => (
        is => 'ro',
        isa => WebServiceValidSignURI,
    );

=head1 DESCRIPTION

Defines custom types for WebService::ValidSign modules

=head1 TYPES

=head2 WebServiceValidSignURI

Allows a scalar URI, eq 'https://foo.bar.nl', or a URI object.

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
