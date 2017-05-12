package Trac::RPC::Base;
{
  $Trac::RPC::Base::VERSION = '1.0.0';
}



use strict;
use warnings;

use Data::Dumper;
use RPC::XML::Client;
use Trac::RPC::Exception;
use Carp;

binmode STDOUT, ":utf8";



sub new {
    my ($class, $params) = @_;
    my $self  = {};

    $self->{realm} = $params->{realm};
    $self->{user} = $params->{user};
    $self->{password} = $params->{password};
    $self->{host} = $params->{host};

    $RPC::XML::ENCODING = "utf-8";
    $self->{rxc} = RPC::XML::Client->new(
        $self->{host},
        error_handler => sub {error($self, @_)},
        fault_handler => sub {error($self, @_)},
    );

    if ( $self->{realm} && $self->{user} && $self->{password} ) {
        $self->{rxc}->credentials($self->{realm}, $self->{user}, $self->{password});
    }

    bless($self, $class);
    return $self;
}


sub call {
    my ($self, @params) = @_;

    my $req = RPC::XML::request->new(@params);
    my $res = $self->{rxc}->send_request($req);

    return $res->value;
}


sub error {
    my $self = shift @_;

    if (ref $_[0]) {
        if( $_[0]->as_string =~ /Unknown method/) {
            TracExceptionUnknownMethod->throw( error =>
                "Could not perform method\n"
                . "Got error\n"
                . Dumper($_[0])
            );
        } elsif( $_[0]->as_string =~ /Wiki page .* does not exist/) {
            TracExceptionNoWikiPage->throw( error =>
                "Wiki page not found\n"
                . "Got error\n"
                . Dumper($_[0])
            );
        } else {
            TracException->throw( error =>
                "Got some unknown error while trying to access '$self->{host}'\n"
                . "Got error: \n"
                . Dumper ($_[0])
                . "\n"
            );
        }
    } else {
        if ($_[0] =~ /Connection refused/) {
            TracExceptionConnectionRefused->throw( error =>
                "Could not access '$self->{host}'\n"
                . "Got error '$_[0]'\n"
            );
        } elsif ($_[0] =~ /Not Found/) {
            TracExceptionNotFound->throw( error =>
                "Could not access '$self->{host}'\n"
                . "Got error '$_[0]'\n"
            );
        } elsif( $_[0] =~ /Authorization Required/) {
            TracExceptionAuthProblem->throw( error =>
                "Could not auth to '$self->{host}'\n"
                . "You specified login '$self->{user}' and " . ($self->{password} ? "some" : "no") . " password\n"
                . "Got error '$_[0]'\n"
            );
        } else {
            croak "Got error: '$_[0]'\n";
        }

    }
}

1;

__END__

=pod

=head1 NAME

Trac::RPC::Base

=head1 VERSION

version 1.0.0

=encoding UTF-8

=head1 NAME

Trac::RPC::Base - abstract class for Trac::RPC classes

=head1 GENERAL FUNCTIONS

=head2 new

B<Get:> 1) $class 2) $params

B<Return:> 1) object

Sub creates an object

=head2 call

B<Get:> 1) $self 2) @params with params to send to trac's xml rpc interface

B<Return:> 1) scalar with some data recived from trac

Sending request to trac and returns the answer.

    $self->call(
        'wiki.putPage',
        RPC::XML::string->new($page),
        RPC::XML::string->new($content),
        RPC::XML::struct->new()
    );

=head2 error

Handler that checks for different types of erros and throws exceptions.

=head1 AUTHOR

Ivan Bessarabov <ivan@bessarabov.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Ivan Bessarabov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
