#-------------------------------------------------------------------------------
#      $URL$
#     $Date$
#   $Author$
# $Revision$
#-------------------------------------------------------------------------------
package Wetware::Test::Utilities;

use strict;
use warnings;
use FindBin qw($Bin);
use File::Basename qw(basename);

use File::Spec;

#------------------------------------------------------------------------------

our $VERSION = 0.03;

#------------------------------------------------------------------------------
# So we do NOT need to export them....
# Since we expect that we will work with Test::Class Cases...
# but may work outside of the Test::Class cases....
#
use Exporter;
use base qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	is_testsuite_module
	path_to_data_dir
	path_to_data_dir_from
	readable_file_path
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

#------------------------------------------------------------------------------

sub readable_file_path {
	my ( $file_path ) = @_;
	return unless $file_path;
	return ( -r $file_path );
}

sub is_testsuite_module {
	my ( $file_path ) = @_;
	
	return unless readable_file_path($file_path);
	
	my $file_name = basename( $file_path );
	
	return $file_name =~ m{^TestSuite\.pm$};
}

# hum.... what if we have a TestSuite for Foo in blib?
# do we need a get_resource_from_INC() method?
sub path_to_data_dir_from {
    my ($path ) = @_;
    $path =~ s{/t/.*}{/t/};
    $path = File::Spec->join( $path, 'test_data' );
    return $path;
}

sub path_to_data_dir {
	return path_to_data_dir_from($Bin);
}

#------------------------------------------------------------------------------

1;

__END__

=pod

=head1 NAME

Wetware::Test::Uilities -  Utility Functions for testing

=head1 SYNOPSIS

  use base Wetware::Test::Uilities;

=head1 DESCRIPTION

Simple functions for helping build test code.

None of them are exported by default.

=head2 is_testsuite_module( $file )

Returns true if the file name matches TestSuite.pm

=head2 path_to_data_dir_from($dir)

returns the path to t/test_data.

=head2 path_to_data_dir()

Uses Findbin's $Bin, to C<call path_to_data_dir_from()>.

=head2 readable_file_path($file_path)

tests that there is a string there, and that it is readable.

=head1 SEE ALSO

FindBin

=head1 AUTHOR

"drieux", C<< <"drieux [AT]  at wetware.com"> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 "drieux", all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# the end 
