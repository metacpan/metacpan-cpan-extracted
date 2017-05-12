# $Id: Dict.pl,v 1.6 1997/05/01 22:06:53 jake Exp $

#   Copyright 1997 Jake Donham <jake@organic.com>

#   You may distribute under the terms of either the GNU General
#   Public License or the Artistic License, as specified in the README
#   file.

# Dict service.

use strict;
use RPC::ONC;
use Dict::Data;
use Dict::Constants;
use DB_File;

my (%dicts, %dictfiles, %dicthashes, %refcnt);
my $debug = 0;

sub cleanup {
  my $dict;
  foreach $dict (keys %refcnt) {
    if ($refcnt{$dict}) {
      $dictfiles{$dict}->sync;
      untie %{$dicthashes{$dict}};
    }
  }
  die "Dict service stopped.\n";
}

$SIG{'TERM'} = \&cleanup;

sub dictres {
  my ($status, $msg) = @_;
  my $dictres = Dict::dictres->new;

  $dictres->set_status($status);

  if ($status == DICT_OK) {
    $dictres->set_value($msg);
  }
  else {
    $dictres->set_msg($msg);
  }

  return $dictres;
}

sub nodict {
  my ($dict) = @_;
  &dictres(DICTERR_NODICT, "No such dictionary: $dict");
}

sub nokey {
  my ($key) = @_;
  &dictres(DICTERR_NOKEY, "No such key: $key");
}

# the protocol

sub dictproc_null_1 {}

sub dictproc_open_1 {
  my ($dict) = @_;

  warn("opening $dict") if $debug;

  # more than one client can call open on the same guy.
  if (!$refcnt{$dict}) {
    $dicthashes{$dict} = {};
    $dictfiles{$dict} =
      tie(%{$dicthashes{$dict}}, 'DB_File', $dict,
	  O_CREAT|O_RDWR, 0644) ||
	    return &dictres(int($!), $!);
      warn("successful tie") if $debug;
  }

  $refcnt{$dict}++;
  return &dictres(DICT_OK);
}

sub dictproc_close_1 {
  my ($dictname) = @_;

  warn("closing $dictname") if $debug;

  my $dict = $dictfiles{$dictname} ||
    return &nodict($dictname);

  $refcnt{$dictname}--;
  $refcnt{$dictname} = 0 if $refcnt{$dictname} < 0; # guard against
  						    # extra closes
  if (!$refcnt{$dictname}) {
    $dictfiles{$dictname}->sync;
    untie %{$dicthashes{$dictname}};
    warn("successful untie") if $debug;
  }

  return &dictres(DICT_OK);
}

sub dictproc_store_1 {
  my ($setargs) = @_;

  my $dict = $dictfiles{$setargs->dict} ||
    return &nodict($setargs->dict);
  my $stat = $dict->put($setargs->key, $setargs->value);

  return &dictres(int($!), $!) if ($stat == -1);
  return &dictres(DICT_OK);
}

sub dictproc_lookup_1 {
  my ($lookupargs) = @_;
  my $val;

  my $dict = $dictfiles{$lookupargs->dict} ||
    return &nodict($lookupargs->dict);
  my $stat = $dict->get($lookupargs->key, $val);

  return &nokey($lookupargs->key) if ($stat == 1);
  return &dictres(int($!), $!) if ($stat == -1);
  return &dictres(DICT_OK, $val);
}

sub dictproc_delete_1 {
  my ($deleteargs) = @_;

  my $dict = $dictfiles{$deleteargs->dict} ||
    return &nodict($deleteargs->dict);
  my $stat = $dict->del($deleteargs->key);

  return &nokey($deleteargs->key) if ($stat == 1);
  return &dictres(int($!), $!) if ($stat == -1);
  return &dictres(DICT_OK);
}

__END__

=head1 NAME

Dict.pl - implementation of 'dict' service

=head1 SYNOPSIS

    dict_svc Dict.pl

=head1 DESCRIPTION

Dict.pl implements the procedures in the 'dict' interface (see
dict.x). It represents dictionaries as DB_Files tied to hashes.

=head1 PROCEDURES

=over 4

=item dictproc_null_1

Does nothing.

=item $dictres = dictproc_open_1($dict)

Opens the specified dictionary (by 'tie'ing a DB_File).

=item $dictres = dictproc_close_1($dict)

Closes the specified dictionary (by 'unti'ing a DB_File).

=item $dictres = dictproc_store_1($storeargs)

Stores the ($storeargs->key, $storeargs->value) pair in
$storeargs->dict.

=item $dictres = dictproc_lookup_1($lookupargs)

Looks up $lookupargs->key in $lookupargs->dict and returns its value
(or an error).

=item $dictres = dictproc_delete_1($deleteargs)

Deletes $deleteargs->key from $deleteargs->dict.

=back

=head1 SEE ALSO

L<RPC::ONC(3)>, L<perlrpcgen(1)>, L<Tie::Dict(3)>

=head1 AUTHOR

Jake Donham <jake@organic.com>

=head1 THANKS

Thanks to Organic Online <http://www.organic.com/> for letting me hack
at work.

=cut
