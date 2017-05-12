=head1 NAME

Text::Same::Cache

=head1 DESCRIPTION

A (planned) cache of ChunkedSource objects.  For now there is just one method:
get(), which returns a ChunkedSource object for a particular file.

=head1 SYNOPSIS

my $cache = new Text::Same::Cache();
my $chunked_source = $cache->get($file);

=head1 METHODS

See below.  Methods private to this module are prefixed by an
underscore.

=cut

package Text::Same::Cache;

use warnings;
use strict;
use Carp;

use vars qw($VERSION);
$VERSION = '0.07';

use Text::Same::FileChunkedSource;

=head2 new

 Title   : new
 Usage   : $cache = new Text::Same::Cache();
 Function: return a new, empty cache

=cut

sub new
{
  my $self  = shift;
  my $class = ref($self) || $self;
  return bless {}, $class;
}

=head2 get

 Title   : get
 Usage   : my $chunked_source = $cache->get($file);
 Function: return a ChunkedSource object for the given file, possibly getting
           the ChunkedSource details from a cache

=cut

sub get
{
  my $self = shift;

  my $filename = shift;
  my @lines = ();

  local $/ = "\n";
  if ($filename =~ /(rcs|svn|co).*\|/) {
    open F, "$filename" or die "$!: $filename\n";

    @lines = map {chomp; $_} (<F>);
  } else {
    open F, "<$filename" or die "$!: $filename\n";
    @lines = map {chomp; $_} (<F>);
  }
  return new Text::Same::FileChunkedSource(name=>$filename, chunks=>\@lines);
}

=head1 AUTHOR

Kim Rutherford <kmr+same@xenu.org.uk>

=head1 COPYRIGHT & LICENSE

Copyright 2005,2006 Kim Rutherford.  All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER

This module is provided "as is" without warranty of any kind. It
may redistributed under the same conditions as Perl itself.

=cut

1;
