use strict;
use warnings;
package WebService::ChatWork::Message::Tag::To;
use overload q{""} => \&as_string;
use constant PRIMARY => "account_id";
use Mouse;

extends "WebService::ChatWork::Message::Tag";

has account_id   => ( is => "ro", isa => "Int" );
has account_name => ( is => "ro", isa => "Str" );

sub as_string {
    my $self = shift;
    my $string = sprintf "[To:%d]", $self->account_id;

    if ( defined $self->account_name ) {
        $string = join q{ }, $string, $self->account_name;
    }

    return $string;
}

1;
