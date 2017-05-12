package Vcdiff::Xdelta3;

use strict;

use Carp;

use Vcdiff;

our $VERSION = '0.104';

require XSLoader;
XSLoader::load('Vcdiff::Xdelta3', $VERSION);



sub diff {
  my ($source, $input, $output) = @_;

  my ($source_fileno, $source_str, $input_fileno, $input_str, $output_fileno, $output_str);

  $source_fileno = $input_fileno = $output_fileno = -1;

  if (!defined $source) {
    croak "diff needs source argument";
  } elsif (ref $source eq 'GLOB') {
    $source_fileno = fileno($source);
    croak "source file handle is closed or invalid" if !defined $source_fileno || $source_fileno == -1;
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

  my $ret = _encode($source_fileno, $source_str, $input_fileno, $input_str, $output_fileno, $output_str);

  _check_ret($ret, 'diff');

  return $output_str if !defined $output;
}


sub patch {
  my ($source, $input, $output) = @_;

  my ($source_fileno, $source_str, $input_fileno, $input_str, $output_fileno, $output_str);

  $source_fileno = $input_fileno = $output_fileno = -1;

  if (!defined $source) {
    croak "patch needs source argument";
  } elsif (ref $source eq 'GLOB') {
    $source_fileno = fileno($source);
    croak "source file handle is closed or invalid" if !defined $source_fileno || $source_fileno == -1;
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

  my $ret = _decode($source_fileno, $source_str, $input_fileno, $input_str, $output_fileno, $output_str);

  _check_ret($ret, 'patch');

  return $output_str if !defined $output;
}



my $exception_map = {
  1 => 'xd3_config_stream',
  2 => 'unable to allocate memory for source.blksize',
  3 => 'source is not lseek()able (must be a regular file, not a pipe/socket)',
  4 => 'error reading from source',
  5 => 'unable to allocate memory for ibuf',
  6 => 'error reading from target/delta',
  7 => 'error writing to output',
  8 => 'xd3_close_stream',
};

sub _check_ret {
  my ($ret, $func) = @_;

  return unless $ret;

  my $exception = $exception_map->{$ret};

  croak "error in Vcdiff::Xdelta3::$func: $exception" if $exception;

  croak "unknown error in Vcdiff::Xdelta3::$func ($ret)";
}


1;




=head1 NAME

Vcdiff::Xdelta3 - Xdelta3 backend for Vcdiff

=head1 SYNOPSIS

    use Vcdiff::Xdelta3;

    my $delta = Vcdiff::Xdelta3::diff($source, $target);

    my $target2 = Vcdiff::Xdelta3::patch($source, $delta);

    ## $target2 eq $target

This module is a backend to the L<Vcdiff> module and isn't usually used directly.


=head1 DESCRIPTION

Xdelta3 is a delta encoding library by Joshua MacDonald. The Xdelta3 source code is embedded into this module and built as a shared object. The C<xdelta3> command-line binary is not built.


=head1 PROS

=over

=item *

Doesn't have arbitrary size limitations on source, target, or delta files.

=item *

Has a really neat feature that lets you merge VCDIFF deltas into a single delta. Unfortunately this module doesn't expose that yet.

=back


=head1 CONS

=over

=item *

GPL licensed

=item *

Build system is really weird. I didn't bother figuring out how to run Xdelta3's test-suite when installing the CPAN module which is unfortunate. Note that installing this module does still run the shared test-suite in L<Vcdiff>.

=back


=head1 SEE ALSO

L<Vcdiff-Xdelta3 github repo|https://github.com/hoytech/Vcdiff-Xdelta3>

L<Vcdiff>

L<Official Xdelta3 website|http://xdelta.org/>


=head1 AUTHOR

Doug Hoyte, C<< <doug@hcsw.org> >>


=head1 COPYRIGHT & LICENSE

Copyright 2013 Doug Hoyte.

This module includes xdelta3 which is copyright Joshua P. MacDonald. xdelta3 is licensed under the GNU GPL 2 which can be found in the inc/COPYING file of this distribution.

Because of xdelta3's license, this module is licensed under the GNU GPL 2.
