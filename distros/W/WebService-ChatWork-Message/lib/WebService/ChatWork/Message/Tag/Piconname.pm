use strict;
use warnings;
package WebService::ChatWork::Message::Tag::Piconname;
use overload q{""} => \&as_string;
use constant PRIMARY => "account_id";
use Mouse;

extends "WebService::ChatWork::Message::Tag";

has account_id => ( is => "ro", isa => "Int" );

sub as_string {
    my $self = shift;
    return sprintf "[piconname:%d]", $self->account_id;
}

1;
