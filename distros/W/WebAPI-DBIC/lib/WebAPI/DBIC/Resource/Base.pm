package WebAPI::DBIC::Resource::Base;
$WebAPI::DBIC::Resource::Base::VERSION = '0.004002';

use Moo;
use namespace::clean -except => [qw(meta)];
use MooX::StrictConstructor;

extends 'Web::Machine::Resource';

require WebAPI::HTTP::Throwable::Factory;

# vvv --- these allow us to use MooX::StrictConstructor
has 'request'  => (is => 'ro');
has 'response' => (is => 'ro');
sub FOREIGNBUILDARGS {
    my ($class, %args) = @_;
    return (request => $args{request}, response => $args{response});
}
# ^^^ ---

has writable => (
    is => 'ro',
    default => $ENV{WEBAPI_DBIC_WRITABLE},
);

has http_auth_type => (
   is => 'ro',
   default => $ENV{WEBAPI_DBIC_HTTP_AUTH_TYPE} || 'Basic',
);

has throwable => (
    is => 'rw',
    default => 'WebAPI::HTTP::Throwable::Factory',
);

has type_namer => (
   is => 'ro',
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebAPI::DBIC::Resource::Base

=head1 VERSION

version 0.004002

=head1 DESCRIPTION

This class is a subclass of WebAPI::DBIC::Resource.

=head1 NAME

WebAPI::DBIC::Resource::Base - Base class for WebAPI::DBIC::Resource's

=head1 AUTHOR

Tim Bunce <Tim.Bunce@pobox.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Tim Bunce.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
