package Tie::Redis::Hash;
{
  $Tie::Redis::Hash::VERSION = '0.26';
}
# ABSTRACT: Connect a Redis hash to a Perl hash

sub TIEHASH {
  my($class, %args) = @_;

  return bless {
    redis => $args{redis},
    key => $args{key}
  };
}

sub _cmd {
  my($self, $cmd, @args) = @_;
  return $self->{redis}->_cmd($cmd, $self->{key}, @args);
}

sub FETCH {
  my($self, $key) = @_;
  $self->_cmd(hget => $key);
}

sub STORE {
  my($self, $key, $value) = @_;
  $self->_cmd(hset => $key, $value);
}

sub FIRSTKEY {
  my($self) = @_;
  $self->{keys} = $self->_cmd("hkeys");
  $self->NEXTKEY;
}

sub NEXTKEY {
  my($self) = @_;
  shift @{$self->{keys}};
}

sub EXISTS {
  my($self, $key) = @_;
  $self->_cmd(hexists => $key);
}

sub DELETE {
  my($self, $key) = @_;
  my $val = $self->_cmd(hget => $key);
  $self->_cmd(hdel => $key);
  $val;
}

sub CLEAR {
  my($self) = @_;
  # technically should keep the hash around, this will do for now, rather
  # than doing three commands...
  $self->_cmd("del");
}

sub SCALAR {
  my($self) = @_;
  $self->_cmd("hlen");
}

1;



__END__
=pod

=head1 NAME

Tie::Redis::Hash - Connect a Redis hash to a Perl hash

=head1 VERSION

version 0.26

=head1 SYNOPSIS

=head1 AUTHOR

David Leadbeater <dgl@dgl.cx>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by David Leadbeater.

This program is free software. It comes without any warranty, to the extent
permitted by applicable law. You can redistribute it and/or modify it under the
terms of the Beer-ware license revision 42.

=cut

