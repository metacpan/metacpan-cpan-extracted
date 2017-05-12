use strict;
use warnings;
package WebService::ChatWork::Message::Tag::Info;
use overload q{""} => \&as_string;
use constant PRIMARY => "message";
use Mouse;

extends "WebService::ChatWork::Message::Tag";

has message => ( is => "ro", isa => "Str" );
has title   => ( is => "ro", isa => "Str" );

sub as_string {
    my $self = shift;
    if ( defined $self->title ) {
        return sprintf "[info][title]%s[/title]%s[/info]", $self->title, $self->message;
    }
    else {
        return sprintf "[info]%s[/info]", $self->message;
    }
}

1;
