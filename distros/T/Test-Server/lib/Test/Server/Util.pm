package # hide from CPAN indexer
	Test::Server::Util;

=head1 NAME

Test::Server::Util - some usefull functions for Test::Server files 

=head1 SYNOPSIS

	use Test::Server::Util qw(parse_size format_size);
	
	print parse_size('5G'), "\n";
	print format_size(5*1024*1024*1024), "\n";

=head1 DESCRIPTION

Some usefull functions for Test::Server files. See FUNCTION section.

=cut

use warnings;
use strict;

our $VERSION = '0.06';

use base 'Exporter';
our @EXPORT_OK = qw(format_size parse_size);


=head1 FUNCTIONS

=head2 parse_size($size)

$size can be a number with optional sufix one of [GMK]. Returns
size in bytes.

=cut

sub parse_size {
	my $size = shift;
	
	return
		if not defined $size;
	
	die 'failed to parse size: '.$size
		if ($size !~ m/\b([0-9]+)\s*([MKG]?)\s*$/);
	
	$size    = $1;
	my $unit = $2;
	
	if ($unit) {
		  $unit eq 'G' ? $size *= 1024*1024*1024
		: $unit eq 'M' ? $size *= 1024*1024
		: $unit eq 'K' ? $size *= 1024
		: die 'shoud never happend... but if enjoy! ;)';
	}
	
	return $size;
}


=head2 format_size($size)

$size should be number of bytes. Returns number of kilo/mega/giga
bytes value formated with sufix (one of [KMG]).

=cut

sub format_size {
	my $size = shift;
	
	my $unit = '';
	
	if ($size > 1024*2) {
		$size = int($size/1024);
		$unit = 'K';
	}
	if ($size > 1024*2) {
		$size = int($size/1024);
		$unit = 'M';
	}
	if ($size > 1024*2) {
		$size = int($size/1024);
		$unit = 'G';
	}
	
	return $size.$unit;
}

'V nasej obci - Jaro Filip';


__END__

=head1 AUTHOR

Jozef Kutej

=cut
