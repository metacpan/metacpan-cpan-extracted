package WARC::Index::File::CDX::Builder;			# -*- CPerl -*-

use strict;
use warnings;

require WARC::Index::Builder;
our @ISA = qw(WARC::Index::Builder);

require WARC; *WARC::Index::File::CDX::Builder::VERSION = \$WARC::VERSION;

use URI;
use Carp;
use Cwd qw//;
use File::Spec;
use Fcntl qw/:seek/;
require File::Spec::Unix;

our %Record_Field_Handlers =
  # each handler is called with WARC::Record and index builder objects and
  # returns the text value for that field or undef, which is written as '-'
  (a => sub { (shift)->field('WARC-Target-URI') },
   k => sub { (shift)->field('WARC-Payload-Digest') },
   u => sub { (shift)->id },

   b => sub { my $date = (shift)->date;
	      $date =~ y/-T:Z//d; substr $date, 0, 14 },
   N => sub { my $uri = (shift)->field('WARC-Target-URI');
	      return undef unless $uri;
	      $uri = new URI ($uri);
	      return undef unless $uri->can('host') && $uri->can('path');
	      my $surt_host = join ',', reverse split /[.]/, $uri->host;
	      return $surt_host.')'.$uri->path
	    },

   g => sub { my $record = shift; my $builder = shift;
	      return $builder->_get_relvolname($record->volume) },
   S => sub { (shift)->{sl_packed_size} },
   v => sub { my $record = shift;
	      return undef if $record->volume->filename !~ m/[.]warc\z/;
	      return $record->offset },
   V => sub { my $record = shift;
	      return undef if $record->volume->filename =~ m/[.]warc\z/;
	      return $record->offset },

   # HTTP responses only
   m => sub { my $response = (shift)->replay;
	      return undef unless UNIVERSAL::can($response, 'headers');
	      $response->headers->content_type },
   r => sub { my $response = (shift)->replay;
	      return undef unless UNIVERSAL::can($response, 'headers');
	      $response->headers->header('Location') },
   s => sub { my $response = (shift)->replay;
	      return undef unless UNIVERSAL::can($response, 'code');
	      $response->code },
  );

# This implementation uses a hash as the underlying structure.

#  Keys defined by this class:
#
#   file_name
#	Name of CDX file where records will be appended.
#   file
#	Handle opened for writing/appending on that file.
#   fields
#	CDX field letters to be written.
#   fieldgen
#	Array of handlers to call to produce field values.
#   delimiter
#	Field delimiter used in CDX file. Default is space; cannot be set
#	 as an option but can be read from an existing CDX file header.
#   volnames
#	Hash mapping volume names to relative paths from the CDX file.

sub _get_relvolname {
  my $self = shift;
  my $name = (shift)->filename;

  return $self->{volnames}->{$name} if defined $self->{volnames}{$name};

  # otherwise ...
  my ($vol, $cdx_dirs, $file) = File::Spec->splitpath($self->{file_name});
  my $relname = File::Spec->abs2rel
    ($name, File::Spec->catpath($vol, $cdx_dirs, undef));
  my ($rvol, $rel_dirs, $rel_file) = File::Spec->splitpath($relname);
  my @rel_dirs = File::Spec->splitdir($rel_dirs);
  my $warcfilename = File::Spec::Unix->catpath
    ($rvol, File::Spec::Unix->catdir(@rel_dirs), $rel_file);
  return $self->{volnames}{$name} = $warcfilename;
}

sub _new {
  my $class = shift;
  my %args = @_;

  croak "required parameter 'into' missing" unless $args{into};

  my $ob = { delimiter => ' ', fields => [qw/N b a m s k r M S V g u/],
	     file_name => Cwd::abs_path($args{into}) };

  $ob->{fields} = $args{fields} if $args{fields};

  open my $fh, '+>>', $args{into} or croak $args{into}.': '.$!;
  {
    local $/ = "\012";
    seek $fh, 0, SEEK_SET or croak 'seek '.$args{into}.': '.$!;
    my $header = <$fh>;
    if ($header) {
      $header =~ m/^(.)CDX((?:\1[[:alpha:]])+)/
	or croak $args{into}.' exists but lacks CDX header';
      $ob->{delimiter} = $1;
      $ob->{fields} = [split /\Q$1/, $2];
      shift @{$ob->{fields}};	# remove leading empty field
    } else {
      # write CDX header
      print $fh ' CDX ', join(' ', @{$ob->{fields}}), "\012";
    }
    seek $fh, 0, SEEK_END or croak 'seek '.$args{into}.': '.$!;
  }
  $ob->{file} = $fh;

  $ob->{fieldgen} =
    [map { $Record_Field_Handlers{$_} or sub { undef } } @{$ob->{fields}}];

  bless $ob, $class
}

# inherit add

sub _add_record {
  my $self = shift;
  my $record = shift;

  my $line = join $self->{delimiter}, map { defined $_ && $_ ne '' ? $_ : '-' }
    map { $_->($record, $self) } @{$self->{fieldgen}};

  print {$self->{file}} $line, "\012";
}

sub flush {
  my $self = shift;

  seek $self->{file}, 0, SEEK_END
}

1;
__END__

=head1 NAME

WARC::Index::File::CDX::Builder - build CDX WARC indexes

=head1 SYNOPSIS

  use WARC::Index;

  build WARC::Index::File::CDX into => $cdx_file, from => [@files];

  $builder = build WARC::Index::File::CDX into => $cdx_file;
  $builder->add($record);

=head1 DESCRIPTION

The C<WARC::Index::File::CDX::Builder> class provides the implementation
for building CDX indexes.

=head2 Options for C<build> method when building CDX indexes

=over

=item C<into>

Name of CDX file to write.  If this file already exists, the C<fields>
option is ignored and read from the header.

=item C<fields>

Array reference of CDX field letters to use, in order.  See
L<WARC::Index::File::CDX> for details about supported fields.

Default:  [qw/N b a m s k r M S V g u/]

=back

=head1 AUTHOR

Jacob Bachmeyer, E<lt>jcb@cpan.orgE<gt>

=head1 SEE ALSO

L<WARC>, L<WARC::Index::Builder>, L<WARC::Index::File::CDX>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019, 2020 by Jacob Bachmeyer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
