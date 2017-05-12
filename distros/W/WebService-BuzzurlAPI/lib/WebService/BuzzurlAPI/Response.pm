package WebService::BuzzurlAPI::Response;

=pod

=head1 NAME

WebService::BuzzurlAPI::Response - Buzzurl WebService API response package

=head1 VERSION

0.02

=head1 DESCRIPTION

Buzzurl WebService API response package

=head1 METHOD

=cut

use strict;
use base qw(Class::Accessor);
use JSON::Syck;

__PACKAGE__->mk_accessors(qw(errstr));
__PACKAGE__->mk_ro_accessors(qw(json res));

our $VERSION = 0.02;

=pod

=head2 new

Create instance

=cut

sub new {

    my($class, $res) = @_;

    if(ref($res) ne "HTTP::Response"){
        croak("\$res is not \"HTTP::Response\" object");
    }
    return bless { json => undef, res => $res }, $class || ref $class;
}

=pod

=head2 analysis_response

Analysis http response

=cut

sub analysis_response {

    my $self = shift;
    my $json;

# response check
# for WebService::BuzzurlAPI::Request::Add and 
    if(!$self->res->is_success){
        return $self->_error($self->res->code, $self->res->message);
    }

# for redirect error
    if($self->res->content_type !~ /^application\/json/){
        return $self->_error(0, "invalid_param [" . $self->res->previous->request->uri . "]" );
    }

    $json = JSON::Syck::Load($self->res->content);

# faild json check
# for WebService::BuzzurlAPI::Request::Add
    if(ref($json) eq "HASH" && exists $json->{status} && $json->{status} ne "success"){
        return $self->_error(999, $json->{status} . " " . $json->{reason});       
    }
    
    $self->{json} = $json;
    return 1;
}

=head2 is_success

Check response

=cut

sub is_success {

    return shift->res->is_success ? 1 : 0;
}

=head2 _error

Set error code and message

=cut

sub _error {

    my($self, $code, $message) = @_;
    $self->res->code($code);
    $self->res->message($message);
    $self->errstr($message);
    return 0;
}

1;

__END__

=head1 ACCESSOR METHOD

=head2 errstr

Get/Set error message

=head2 json

Get json2refrence(Readonly)

=head2 res

Get HTTP::Response instance(Readonly)

=head1 SEE ALSO

L<Class::Accessor> L<JSON::Syck>

=head1 AUTHOR

Akira Horimoto

=head1 COPYRIGHT

Copyright (C) 2007 Akira Horimoto

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut


