package Tie::Redis::Attribute;
{
  $Tie::Redis::Attribute::VERSION = '0.26';
}
# ABSTRACT: Variable attribute based interface to Tie::Redis

use 5.010001; # >= 5.10.1
use strict;
use warnings;

use Attribute::Handlers;
use Tie::Redis;
use PadWalker qw(var_name);

no warnings 'redefine';

sub import {
  my($class) = @_;
  my $pkg = caller;
  eval qq{
    sub ${pkg}::Redis :ATTR(VAR) {
      unshift \@_, \$class;
      goto &_do_tie;
    }
    1
  } or die;
}

sub _do_tie {
  my($class, $ref, $data) = @_[0, 3, 5];
  return if tied $ref; # Already applied

  if($data && !ref $data) {
    # Attribute::Handlers couldn't make into perl, warn rather than do
    # something surprising.
    require Carp;
    Carp::croak "Invalid attribute";
  }

  my $type = ref $ref;
  my %args = ref $data ? @$data : ();

  if(!exists $args{key}) {
    my $sigil = {
      ARRAY => '@',
      HASH  => '%'
    }->{$type};

    # Find where we were actually called from, ignoring attributes and
    # Attribute::Handlers.
    my $c = 1;
    $c++ while((caller $c)[3] =~ /^(?:attributes|Attribute::Handlers)::/);

    # The first part of the key is either the name of the subroutine if this is
    # within sub scope else the package name.
    my $pkg = (caller $c+1)[0];
    my $sub = (caller $c+1)[3] || $pkg;

    # Now we want a unique name for it
    my $name = var_name($c, $ref);

    if(!$name) {
      # Maybe package variable?
      no strict 'refs';
      for my $glob(values %{"${pkg}::"}) {
        next unless ref \$glob eq 'GLOB';
        if(*$glob{$type} && *$glob{$type} == $ref) {
          $name = $sigil . ($glob =~ /::([^:]+)$/)[0];
        }
      }
    }

    if(!$name) {
      require Carp;
      local $Carp::CarpLevel = $c;
      Carp::croak "Can't automatically work out a name";
    }

    if($pkg eq 'main') {
      # DWIM..., hopefully not *too* magical
      ($pkg) = $0 =~ m{(?:^|/)([^/]+)$};
      $sub =~ s/^main(::|$)/${pkg}$1/;
    }
    $args{key} = "autoattr:${sub}::${name}";
  }

  if($type eq 'HASH') {
    tie %$ref, "Tie::Redis::" . ucfirst lc $type,
      redis => $class->server(%args), %args;
  } elsif($type eq 'ARRAY') {
    tie @$ref, "Tie::Redis::" . ucfirst lc $type,
      redis => $class->server(%args), %args;
  } else {
    die "Only hashes and arrays are supported";
  }
}

sub server {
  my($class, %args) = @_;
  state %server;

  $server{($args{host}||"") . ":" . ($args{port}||"")}
    ||= Tie::Redis::Connection->new(%args);
}

1;



=pod

=head1 NAME

Tie::Redis::Attribute - Variable attribute based interface to Tie::Redis

=head1 VERSION

version 0.26

=head1 SYNOPSIS

  use Tie::Redis::Attribute;

  my %hash : Redis; # %hash now magically resides in a redis instance

=head1 DESCRIPTION

This is an B<experimental> module that implements attribute based tying for
Redis.

Currently tying of arrays or hashes is supported.

=head1 OPTIONS

Options may be specified using perl list syntax within the C<Redis(...)>
attribute.

However note that L<attributes> cannot use lexical variables, so C<my %p :
Redis(host => $host)> will unfortunately not work if C<$host> is lexical.

=over 4

=item * key

The key to use, if this isn't provided a key is invented based on the package
name and variable name. This means for some simple purposes you may not need to
specify a key.

For example:

  our @queue : Redis(key => "my-queue");

=back

Other options are as per L<Tie::Redis>'s constructor (prefix) and
L<AnyEvent::Redis> (host, port, encoding).

=head1 METHODS

=head2 server

You may subclass this and define a C<server> method that returns an instance of
L<Tie::Redis>. Due to the I<tricky> nature of attributes it is recommended to
B<not> define an C<import> method in your subclass other than the one provided
by this class.

=head1 SEE ALSO

L<Tie::Redis>, L<Attribute::Tie>, L<Attribute::TieClasses>.

=head1 AUTHOR

David Leadbeater <dgl@dgl.cx>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by David Leadbeater.

This program is free software. It comes without any warranty, to the extent
permitted by applicable law. You can redistribute it and/or modify it under the
terms of the Beer-ware license revision 42.

=cut


__END__


