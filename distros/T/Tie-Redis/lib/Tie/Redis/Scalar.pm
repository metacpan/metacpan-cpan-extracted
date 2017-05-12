package Tie::Redis::Scalar;
{
  $Tie::Redis::Scalar::VERSION = '0.26';
}

# Consider using overload instead of this maybe, could then implement things
# like ++ in terms of Redis commands.

sub TIESCALAR {
  my($class, %args) = @_;
  bless \%args, $class;
}

sub _cmd {
  my($self, $cmd, @args) = @_;
  return $self->{redis}->_cmd($cmd, $self->{key}, @args);
}

sub FETCH {
  my($self) = @_;
  $self->_cmd("get");
}

sub STORE {
  my($self, $value) = @_;
  $self->_cmd("set", $value);
}

1;


__END__
=pod

=head1 NAME

Tie::Redis::Scalar

=head1 VERSION

version 0.26

=head1 SYNOPSIS

=head1 NAME

Tie::Redis::Scalar - Connect a Redis key to a Perl scalar

=head1 VERSION

version 0.26

=head1 AUTHOR

David Leadbeater <dgl@dgl.cx>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by David Leadbeater.

This program is free software. It comes without any warranty, to the extent
permitted by applicable law. You can redistribute it and/or modify it under the
terms of the Beer-ware license revision 42.

=cut

