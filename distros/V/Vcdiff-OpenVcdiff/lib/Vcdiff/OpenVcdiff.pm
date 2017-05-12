package Vcdiff::OpenVcdiff;

use strict;

use Carp;
use Guard;

use Vcdiff;

our $VERSION = '0.106';
$VERSION = eval $VERSION;

require XSLoader;
XSLoader::load('Vcdiff::OpenVcdiff', $VERSION);



sub diff {
  my ($source, $input, $output) = @_;

  my ($source_str, $input_fileno, $input_str, $output_fileno, $output_str);
  my $source_str_guard;

  $input_fileno = $output_fileno = -1;

  if (!defined $source) {
    croak "diff needs source argument";
  } elsif (ref $source eq 'GLOB') {
    require Sys::Mmap;

    if (!defined Sys::Mmap::mmap($source_str, 0, Sys::Mmap::PROT_READ(), Sys::Mmap::MAP_SHARED(), $source)) {
      croak "unable to mmap filehandle (maybe it's a pipe or socket instead of a file): $!";
    }

    $source_str_guard = guard {
      Sys::Mmap::munmap($source_str) || carp "failed to munmap: $!";
    };
  } else {
    $source_str = $source;
  }

  if (!defined $input) {
    croak "diff needs target argument";
  } elsif (ref $input eq 'GLOB') {
    $input_fileno = fileno($input);
    croak "target file handle is closed or invalid" if !defined $input_fileno || $input_fileno == -1;
  } else {
    $input_str = $input;
  }

  if (defined $output) {
    croak "output argument to diff should be a file handle or undef"
      if ref $output ne 'GLOB';

    $output_fileno = fileno($output);
    croak "output file handle is closed or invalid" if !defined $output_fileno || $output_fileno == -1;
  } else {
    $output_str = '';
  }

  my $ret = _encode($source_str, $input_fileno, $input_str, $output_fileno, $output_str);

  _check_ret($ret, 'diff');

  return $output_str if !defined $output;
}




sub patch {
  my ($source, $input, $output) = @_;

  my ($source_str, $input_fileno, $input_str, $output_fileno, $output_str);
  my $source_str_guard;

  $input_fileno = $output_fileno = -1;

  if (!defined $source) {
    croak "patch needs source argument";
  } elsif (ref $source eq 'GLOB') {
    require Sys::Mmap;

    if (!defined Sys::Mmap::mmap($source_str, 0, Sys::Mmap::PROT_READ(), Sys::Mmap::MAP_SHARED(), $source)) {
      croak "unable to mmap filehandle (maybe it's a pipe or socket instead of a file): $!";
    }

    $source_str_guard = guard {
      Sys::Mmap::munmap($source_str) || carp "failed to munmap: $!";
    };
  } else {
    $source_str = $source;
  }

  if (!defined $input) {
    croak "patch needs delta argument";
  } elsif (ref $input eq 'GLOB') {
    $input_fileno = fileno($input);
    croak "delta file handle is closed or invalid" if !defined $input_fileno || $input_fileno == -1;
  } else {
    $input_str = $input;
  }

  if (defined $output) {
    croak "output argument to patch should be a file handle or undef"
      if ref $output ne 'GLOB';

    $output_fileno = fileno($output);
    croak "output file handle is closed or invalid" if !defined $output_fileno || $output_fileno == -1;
  } else {
    $output_str = '';
  }

  my $ret = _decode($source_str, $input_fileno, $input_str, $output_fileno, $output_str);

  _check_ret($ret, 'patch');

  return $output_str if !defined $output;
}





my $exception_map = {
  1 => 'unable to initialize HashedDictionary',
  2 => 'StartEncoding error',
  3 => 'error reading from target/delta',
  4 => 'EncodeChunk error',
  5 => 'error writing to output',
  6 => 'FinishEncoding error',
  7 => 'DecodeChunk error',
  8 => 'FinishDecoding error',
  9 => 'unknown C++ exception',
};

sub _check_ret {
  my ($ret, $func) = @_;

  return unless $ret;

  my $exception = $exception_map->{$ret};

  croak "error in Vcdiff::OpenVcdiff::$func: $exception" if $exception;

  croak "unknown error in Vcdiff::OpenVcdiff::$func ($ret)";
}



1;


__END__


=head1 NAME

Vcdiff::OpenVcdiff - open-vcdiff backend for Vcdiff

=head1 SYNOPSIS

    use Vcdiff::OpenVcdiff;

    my $delta = Vcdiff::OpenVcdiff::diff($source, $target);

    my $target2 = Vcdiff::OpenVcdiff::patch($source, $delta);

    ## $target2 eq $target

This module is a backend to the L<Vcdiff> module and isn't usually used directly.



=head1 DESCRIPTION

This module uses L<Alien::OpenVcdiff> which is a module that configures, builds, and installs Google's L<open-vcdiff|http://code.google.com/p/open-vcdiff/> library.

The alien package installs the C<vcdiff> binary for your convenience but this module uses the C<libvcdenc.so> and C<libvcddec.so> shared libraries so that the diffing computation is done in-process instead of forking processes.


=head1 PROS

=over

=item *

Apache licensed

=item *

open-vcdiff has a really cool feature that lets you re-use "hashed dictionaries" for multiple diff operations (but this module doesn't expose that yet).

=back


=head1 CONS

=over

=item *

Even with the streaming API C<open-vcdiff> has a hard upper-limit of 2G file sizes and the default (which this module hasn't changed) is 64M so be warned.

=item *

If the source argument is a file handle, L<Vcdiff::OpenVcdiff> will try to C<mmap(2)> the entire file into memory with L<Sys::Mmap>. As well as adding a dependency, this means that source files must be able to fit in your address space. Because of the file size limitation described above, this shouldn't be an issue. See the "STREAMING API" section of L<Vcdiff> for more details.

=item *

The L<Alien::OpenVcdiff> dependency takes a long time to compile compared to L<Vcdiff::Xdelta3> although it's not a completely fair comparison because the alien module also runs open-vcdiff's test-suite (which is good).

=item *

The library writes to standard error in the event of errors and I don't believe there is any way to silence these messages.

=back




=head1 SEE ALSO

L<Vcdiff-OpenVcdiff github repo|https://github.com/hoytech/Vcdiff-OpenVcdiff>

L<Vcdiff>

L<Alien::OpenVcdiff>

L<Official open-vcdiff website|http://code.google.com/p/open-vcdiff/>


=head1 AUTHOR

Doug Hoyte, C<< <doug@hcsw.org> >>


=head1 COPYRIGHT & LICENSE

Copyright 2013 Doug Hoyte.

This module is licensed under the same terms as perl itself.

=cut
