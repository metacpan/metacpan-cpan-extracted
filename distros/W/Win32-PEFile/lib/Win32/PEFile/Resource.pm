=head1 NAME

Win32::PEFile::Resource - PEFile resource objects

=head1 OVERVIEW

This module provides a resource class used to facilitate the management of
resource entries in PE files.

=cut

use strict;
use warnings;
use Carp qw();


package Win32::PEFile::Resource;

sub new {
    my ($class, %params) = @_;

    # Default language to US English
    $params{lang} = 0x0409 if ! defined $params{lang};

    return bless \%params, $class;
}


package Win32::PEFile::VersionResource;

push @Win32::PEFile::VersionResource::ISA, 'Win32::PEFile::Resource';


1;

