package Util::Medley::FileZip;
$Util::Medley::FileZip::VERSION = '0.007';
use Modern::Perl;
use Moose;
use Method::Signatures;
use namespace::autoclean;

use Data::Printer alias => 'pdump';
use Carp;
use Archive::Zip; # qw( :ERROR_CODES :CONSTANTS );

#with 'Util::Medley::Roles::Attributes::Spawn';
#with 'Util::Medley::Roles::Attributes::String';

=head1 NAME

Util::Medley::FileZip - utility zipfile methods

=head1 VERSION

version 0.007

=cut

#########################################################################################

=pod

use base 'Exporter';
our @EXPORT = qw();    # Symbols to autoexport (:DEFAULT tag)

our @EXPORT_OK = qw(
  chdir
  chmod
  file_type
  find_files
  ls_zip mkdir
  trim_file_ext
  splitpath
  unlink
  xmllint
  );                   # Symbols to export on request

our %EXPORT_TAGS = (   # Define names for sets of symbols
    all => \@EXPORT_OK,
);

=cut

#########################################################################################


#########################################################################################


#method ls (Str :$file!) {
#
#	my @ls;
#	my @cmd = ( 'unzip', '-l', $file );
#	my ($stdout, $stderr, $exit) = $self->Spawn->capture(cmd => \@cmd);
#
#	my $in_body = 0;
#	
#	foreach my $line (split(/\n/, $stdout)) {
#		
#		next if $self->String->is_blank($line);
#		chomp $line;
#			
#		if ( !$in_body and $line =~ /^\-\-\-/ ) {
#			$in_body = 1;
#		}
#		elsif ( $in_body and $line =~ /^\-\-\-/ ) {
#			$in_body = 0;
#		}
#		elsif ($in_body) {
#			my $copy = $line;
#			$copy =~ s/^\s+//;    # drop leading ws
#			my @parts = split( /\s+/, $copy );
#			shift @parts;         # drop length
#			shift @parts;         # drop date
#			shift @parts;         # drop time
#			my $filename = join ' ', @parts;
#			push @ls, $filename;
#		}
#	}
#
#	return @ls;
#}

method ls (Str :$file!) {

	my $zip = Archive::Zip->new;
	$zip->read($file) or confess "zip read error";
	
	return $zip->memberNames;
}
 
######################################################################


1;
