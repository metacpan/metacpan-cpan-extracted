package WebService::BuzzurlAPI::Request;

=pod

=head1 NAME

WebService::BuzzurlAPI::Request - Buzzurl WebService API request package

=head1 VERSION

0.02

=head1 DESCRIPTION

Buzzurl WebService API request package

=head1 METHOD

=cut

use strict;
use base qw(Class::Accessor);
use Carp;
use HTTP::Request;
use Readonly;
use WebService::BuzzurlAPI::Util qw(drop_utf8flag urlencode);

__PACKAGE__->mk_ro_accessors(qw(buzz uri));

our $VERSION = 0.02;

Readonly my @OVERRIDE_METHOD => qw(
                                   filter_param
                                   make_request_url
                                   make_request_content
                                   is_post_request
                                  );

sub import {

    my $class = shift;
    {
        no strict "refs";
        map { *{$_} = sub { croak("\"$_\" abstract method!") } } @OVERRIDE_METHOD;
    }
}

=pod

=head2 new

Create instance

=cut

sub new {

    my($class, %args) = @_;

    if(ref($args{buzz}) ne "WebService::BuzzurlAPI"){
        croak("buzz is not \"WebService::BuzzurlAPI\" object");
    }

    return bless \%args, $class || ref $class;
}

=head2 request

Access API. return HTTP::Response instance

=cut

sub request {

    my($self, %param) = @_;
    
    $self->filter_param(\%param);
    $self->make_request_url(\%param);

    my @option = ($self->is_post_request) ?
                 ( "POST", $self->uri->as_string, [ "Content-Type", "application/x-www-form-urlencoded" ], $self->make_request_content(\%param) ) :
                 ( "GET", $self->uri->as_string );
    return $self->buzz->ua->request(HTTP::Request->new(@option));
}

1;

__END__

=head1 ABSTRACT METHOD

=head2 filter_param

=head2 make_request_url

=head2 make_request_content

=head2 is_post_request

=head1 ACCESSOR METHOD

=head2 buzz

Get WebService::BuzzurlAPI instance(Readonly)

=head1 SEE ALSO

L<Class::Accessor> L<HTTP::Request> L<Readonly>

=head1 AUTHOR

Akira Horimoto

=head1 COPYRIGHT

Copyright (C) 2007 Akira Horimoto

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut


