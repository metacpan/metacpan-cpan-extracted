package MyThrowable;

sub new {
    my ( $class, $message ) = @_;
    return bless { message => $message }, $class;
}

sub throw { die $_[0]->{message} }

1;
