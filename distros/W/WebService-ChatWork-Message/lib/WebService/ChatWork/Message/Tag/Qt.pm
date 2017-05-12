use strict;
use warnings;
package WebService::ChatWork::Message::Tag::Qt;
use overload q{""} => \&as_string;
use Mouse;

extends "WebService::ChatWork::Message::Tag";

has account_id => ( is => "ro", isa => "Int" );
has time       => ( is => "ro", isa => "Int" );
has message    => ( is => "ro", isa => "Str" );

sub as_string {
    my $self = shift;
    if ( $self->time ) {
        return sprintf "[qt][qtmeta aid=%d time=%d]%s[/qt]", $self->account_id, $self->time, $self->message;
    }
    else {
        return sprintf "[qt][qtmeta aid=%d]%s[/qt]", $self->account_id, $self->message;
    }
}

1;
