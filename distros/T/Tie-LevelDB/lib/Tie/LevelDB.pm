package Tie::LevelDB;

use 5.010001;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Tie::LevelDB ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.07';

require XSLoader;
XSLoader::load('Tie::LevelDB', $VERSION);

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Tie::LevelDB - A Perl Interface to the Google LevelDB NoSQL database

=head1 SYNOPSIS

  use Tie::LevelDB;

  tie my %hash, 'Tie::LevelDB', "/tmp/testdb";
  # Use the %hash array
  untie %hash;

  -- OR --

  use Tie::LevelDB; 

  my $db = new Tie::LevelDB::DB("/tmp/testdb");
  $db->Put("Google","Don't be evil!");
  print $db->Get("Google")."\n";
  $db->Delete("Google");

  my $batch = new Tie::LevelDB::WriteBatch;
  $batch->Delete("Google");
  $batch->Put("Microsoft","Where Do you Want to Go Today?");
  $db->Write($batch);

  my $it = $db->NewIterator;
  for($it->SeekToFirst;$it->Valid;$it->Next) {
     print $it->key.": ".$it->value."\n";
  }

=head1 DESCRIPTION

B<Tie::LevelDB> is the Perl Interface for Google NoSQL database called
I<LevelDB>. See L<http://code.google.com/p/leveldb/> for more details.

Interface is implemented both as a reflection of an original LevelDB 
C++ API and a Perl-ish TIEHASH mechanism.

=head2 EXPORT

None by default.

=head2 LIMITATIONS

LevelDB does not support storing of C<undef> values. 
If C<undef> is stored, the key is C<deleted> instead.

Perl support for Options specification is not covered.

To use SNAPPY compression method, install it from 
L<http://code.google.com/p/snappy> first and then re-install
this module.

LevelDB sources (version 2011-07-29) are bundled with this packages. 

=head1 SEE ALSO

L<http://code.google.com/p/leveldb/>, L<DB_File(3)>, L<tie>.

=head1 AUTHOR

Martin Sarfy, E<lt>martin.sarfy@sokordia.czE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Sokordia, s.r.o., L<http://www.sokordia.cz>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
