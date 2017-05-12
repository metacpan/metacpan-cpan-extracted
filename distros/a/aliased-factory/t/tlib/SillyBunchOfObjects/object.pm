package SillyBunchOfObjects::object;

sub new {my $class = shift; bless(\$class, $class)}
sub classname {${shift(@_)}}

1;
