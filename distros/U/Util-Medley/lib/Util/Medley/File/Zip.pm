package Util::Medley::File::Zip;
$Util::Medley::File::Zip::VERSION = '0.013';
use Modern::Perl;
use Moose;
use namespace::autoclean;
use Kavorka '-all';
use Data::Printer alias => 'pdump';
use Carp;
use Archive::Zip; # qw( :ERROR_CODES :CONSTANTS );

=head1 NAME

Util::Medley::File::Zip - utility methods for working with zipfiles.

=head1 VERSION

version 0.013

=cut

=head1 SYNOPSIS

 my $fz = Util::Medley::File::Zip->new;

 my @list = $fz->ls('my.zip');
 
=cut

=head2 DESCRIPTION

Provides frequently used zipfile operation methods.  

=cut

#########################################################################################

=head1 METHODS

=over

=item usage:

 @list = $util->ls($file);

 @list = $util->ls(file => $file);
  
=item args:

=over

=item file [Str]

The path of the zipfile.

=back

=back

=cut

multi method ls (Str :$file!) {

	return $self->ls($file);
}

multi method ls (Str $file) {

	my $zip = Archive::Zip->new;
	$zip->read($file) or confess "zip read error";
	
	return $zip->memberNames;
}
 
######################################################################


1;
