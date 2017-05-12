use strict;
use warnings;
package WebService::ChatWork::Message::Tag;
use overload q{""} => \&as_string;
use constant PRIMARY => "message";
use Mouse;

has message => ( is => "ro", isa => "Str" );

sub new_with_primary {
    my $class = shift;
    my $self = bless { $class->PRIMARY => shift }, $class;
    return $self;
}

sub new_with_attributes {
    my $class = shift;
    return bless { @_ }, $class;
}

sub new {
    my $class = shift;
    my @args  = @_;

    return $class->new_with_primary( @args )
        if @args == 1;

    return $class->new_with_attributes( @args );
}

sub as_string {
    my $self = shift;
    my $name = $self->PRIMARY;
    return $self->$name;
}

1;
