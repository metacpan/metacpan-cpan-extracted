# $Id: Dict.pm,v 1.6 1997/05/01 22:06:54 jake Exp $

#   Copyright 1997 Jake Donham <jake@organic.com>

#   You may distribute under the terms of either the GNU General
#   Public License or the Artistic License, as specified in the README
#   file.

package Tie::Dict;

# This is a partial implementation of hashes tied to the dict
# service.

use strict;

use Dict::Data;
use Dict::Constants;
use Dict::Client;

use Tie::Hash;

@Dict::ISA = qw(Tie::Hash);

sub TIEHASH {
  my ($class, $server, $dict) = @_;
  my $client = Dict::Client->new($server);
  my $dictres = $client->dictproc_open_1($dict);
  die $dictres->msg unless $dictres->status == DICT_OK;
  bless { 'server' => $server,
	  'client' => $client,
	  'dict' => $dict }, $class;
}

sub FETCH {
  my ($self, $key) = @_;

  my $lookupargs = Dict::lookupargs->new;
  $lookupargs->set_dict($self->{'dict'});
  $lookupargs->set_key($key);

  my $dictres =
    $self->{'client'}->dictproc_lookup_1($lookupargs);

  if ($dictres->status == DICT_OK) {
    return $dictres->value;
  }
  else {
    if ($dictres->status eq DICTERR_NOKEY) {
      return undef;
      # no error is thrown, so nonexistent keys don't do anything
      # alarming
    }
    die $dictres->msg;
  }
}

sub STORE {
  my ($self, $key, $val) = @_;

  my $storeargs = Dict::storeargs->new;
  $storeargs->set_dict($self->{'dict'});
  $storeargs->set_key($key);
  $storeargs->set_value($val);

  my $dictres = $self->{'client'}->dictproc_store_1($storeargs);

  die $dictres->msg unless $dictres->status == DICT_OK;
}

sub DELETE {
  my ($self, $key) = @_;

  my $deleteargs = Dict::deleteargs->new;
  $deleteargs->set_dict($self->{'dict'});
  $deleteargs->set_key($key);

  my $dictres = $self->{'client'}->dictproc_delete_1($deleteargs);

  die $dictres->msg unless $dictres->status == DICT_OK;
}

sub DESTROY {
  my ($self) = @_;
  $self->{'client'}->dictproc_close_1($self->{'dict'});
}

1;
__END__

=head1 NAME

Tie::Dict - tie a hash to an RPC dict server

=head1 SYNOPSIS

    use Tie::Dict;

    tie %hash, Tie::Dict, $server, $dictionary;

    $hash{'this'} = 'that';
    $this = $hash{'this'};
    delete $hash{'this'};

    untie %foo;

=head1 DESCRIPTION

B<Tie::Dict> is a module which allows Perl programs to tie a hash to
an RPC server running the 'dict' service. This allows several
processes (on the same machine or different machines) to share a
dictionary without worrying about concurrency (RPC calls are
serialized on the server).

The arguments to the tie call are the hostname of the server and the
dictionary to tie to. If the tie fails for some reason (e.g. the
server is down, the dictionary couldn't be opened, etc.), an exception
is raised.

In the default implementation of the 'dict' service, the dictionary is
the filename of an underlying DB_File. Other implementations could map
names differently.

=head1 SEE ALSO

L<Tie::Hash(3)>, L<Dict.pl(1)>

=head1 AUTHOR

Jake Donham <jake@organic.com>

=head1 THANKS

Thanks to Organic Online <http://www.organic.com/> for letting me hack
at work.

=head1 BUGS

The full tied hash interface is not implemented.

=cut
