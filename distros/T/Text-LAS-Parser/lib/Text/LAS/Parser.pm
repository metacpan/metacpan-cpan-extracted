package Text::LAS::Parser;

use 5;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(
get_info_in_non_A_sections
read_Section_A
);

our $VERSION = '0.01';

use IO::Handle;
use Scalar::Util qw( looks_like_number );
use Carp;

sub new {
    my ( $class, $source ) = @_;
    $source or croak 'Null source';
    my $this = { 'source' => $source };
    bless $this;
    $this->_parse_downto_section_A_beginning_flag()
	and return $this;
}

sub _parse_downto_section_A_beginning_flag {
    my ( $this ) = @_;

    $$this{'source'}->opened()
	or croak "Not opened: ",$$this{'source'};

    while( my $line = $$this{'source'}->getline() ) {
	$line =~ s/[\r\n]*$//;
	if ( $line =~ /^\s*\#(.*)$/
	     && ( ! &_section_now_reading( $this ) || &_section_now_reading( $this ) !~ /^A/ ) ) {
	    &_process_comment( $this, $1 );
	    next;
	}
	if ( $line =~ /^\s*\~(.*)$/ ) {
	    if ( &_process_flag( $this, $1 ) ) {
		&_section_now_reading( $this ) =~ /^A/ and last;
	    }
	    next;
	}
	if ( &_section_now_reading( $this ) && &_section_now_reading( $this ) =~ /^[VWPC]/ ) {
	    $line =~ /^\s*([^\s\.\:]*)\s*\.([^\s\:]*)\s+(.*)\:([^\:]*)$/
		or croak 'Corrupt line in Section '.&_section_now_reading( $this ).": $line";
	    &_process_VWPC_line( $this, $1, $2, $3, $4 );
	    next;
	}
	print STDERR "Skipping Line: $line\n";
    }

    &_section_already_read( $this, 'W' ) or croak 'Section W is mandate';
    &_section_already_read( $this, 'C' ) or croak 'Section C is mandate';
    &_section_already_read( $this, 'A' ) or croak 'Section A is mandate';

    substr( &_section_now_reading( $this ), 0, 1 ) eq 'A'
	or die "Maybe a bug: should at the beginning of the Section A now";

    &_check_non_data( $this );

    return 1;
}

sub get_info_in_non_A_sections {
    my ( $this, $section ) = @_;
    foreach my $k ( keys %$this ) {
	$k =~ /^Section $section/ or next;
	return @{$$this{$k}};
    }
}

sub _section_now_reading {
    my $this = shift;
    $#{$$this{'sections_read'}} < 0 and return;
    return ${$$this{'sections_read'}}[$#{$$this{'sections_read'}}];
}

sub _section_already_read {
    my ( $this, $section ) = @_;
    $section = substr( $section, 0, 1 );
    foreach my $s (@{$$this{'sections_read'}}) {
	substr( $s, 0, 1 ) eq $section
	    and return 1;
    }
    return;
}

sub _process_comment {
    my ( $this, $comment ) = @_;
    print STDERR "Skipping Comment: $comment\n"; #
}

sub _process_flag {
    my ( $this, $flag ) = @_;
#    print STDERR "Flag: $flag\n"; #
    if ( $flag !~ /^[VWPCOA]/ ) {
	&_process_comment( $this, $flag );
	return 0;
    }
    ! &_section_now_reading( $this ) && substr( $flag, 0, 1 ) ne 'V'
	and croak "The first section must be V: $flag";
    &_section_already_read( $this, 'A' )
	and croak "Another section after Section A: $flag";
    &_section_now_reading( $this ) && &_section_already_read( $this, substr( $flag, 0, 1 ) )
	and croak "Section must present only once: $flag";
    push( @{$$this{'sections_read'}}, $flag );
    print STDERR 'Entered Section: ',&_section_now_reading( $this ),"\n"; #
    return 1;
}

sub _process_VWPC_line {
    my ( $this, $mnem, $units, $data, $description ) = @_;
    push( @{$$this{'Section '.substr( &_section_now_reading( $this ), 0, 1)}},
	  [ $mnem, $units, $data, $description ] );
}

sub _check_non_data {
    my $this = shift;

    foreach my $v ( @{$$this{'Section V'}} ) {
	$$v[0] eq 'VERS'
	    and &_check_LAS_version( $this, $$v[1], $$v[2], $$v[3] );
	$$v[0] eq 'WRAP'
	    and &_check_wrap_around_mode( $this, $$v[1], $$v[2], $$v[3] );
    }
    $$this{'LAS VERSION'} or croak 'LAS version is not specified';
    $$this{'WRAP AROUND MODE'} or croak 'Wrap around mode is not specified';

    foreach my $w ( @{$$this{'Section W'}} ) {
	$$w[0] eq 'NULL'
	    and &_check_null_values( $this, $$w[1], $$w[2], $$w[3] );
    }
    $$this{'NULL VALUE'} or croak 'NULL value is not specified';

    my $not_first = 0;
    foreach my $c ( @{$$this{'Section C'}} ) {
	! $not_first && $$c[0] ne 'DEPT' && $$c[0] ne 'DEPTH' && $$c[0] ne 'TIME'
	    and croak 'The first channel must be either DEPT, DEPTH or TIME: ',$$c[0];
	$not_first = 1;
	$$c[3] eq '' and croak 'No curve description';
    }
}

sub _check_LAS_version {
    my ( $this, $units, $data, $description ) = @_;
    $data =~ /2\.0\s*/
	or croak "Can read LAS Version 2.0 only: $data";
    $$this{'LAS VERSION'} = $data;
}

sub _check_wrap_around_mode {
    my ( $this, $units, $data, $description ) = @_;
    $data =~ /YES\s*/ || $data =~ /NO\s*/ 
	or croak "Unknown wrap around mode: $data :$description";
    $data =~ /YES\s*/
	and croak "Can read one line per depth step only";
    $$this{'WRAP AROUND MODE'} = $data;
}

sub _check_null_values {
    my ( $this, $units, $data, $description ) = @_;
    $$this{'NULL VALUE'} = $data;
}

sub read_Section_A {
    my ( $this, $null_replacement ) = @_;
    my $line = $$this{'source'}->getline() or return 0;
    $line =~ s/[\r\n]*$//;
    $line =~ /^\s*\~(.*)$/ and &_process_flag( $this, $1 ) and return 0;
    return &_process_A_line( $this, $null_replacement, $line );
}

sub _process_A_line {
    my ( $this, $null_replacement, $line ) = @_;
    my @columns = split( /\s+/, $line );
    $columns[0] eq '' and shift( @columns );
    $#columns < 0 and croak 'Blank line in Section A';
    $#columns == $#{$$this{'Section C'}}
	or croak 'Less columns than channels';
    for( my $i = 0; $i <= $#columns; $i++ ) {
	looks_like_number( $columns[$i] ) && $columns[$i] == $$this{'NULL VALUE'}
	    and $columns[$i] = $null_replacement;
    }
    return \@columns;
}

1;
__END__

=head1 NAME

Text::LAS::Parser - Perl extension to parse Log ASCII Standard (LAS) Version 2.0 format.

=head1 SYNOPSIS

  use Text::LAS::Parser;
  my $las = Text::LAS::Parser->new( new IO::File( 'data.las' ) ) or die;
  foreach my $curve ( $las->get_info_in_non_A_sections( 'C' ) ) {
    my ( $mnem, $unit, $data, $desc ) = @$curve;
    print "$desc [$unit],";
  }
  print "\n";
  while( my $record = $las->read_Section_A( '' ) ) {
    print join( ',', @$record ),"\n";
  }

=head1 DESCRIPTION

This module is in order to parse Log ASCII Standard (LAS) Version 2.0. This module can read `one line per depth step' mode only and does not support `multiple lines per depth step' mode.
To write this, I read the following references.

  LAS Version 2.0 Updated: July 2009
    A Digital Standard for Logs
    Canadian Well Logging Society (www.cwls.org)
    http://www.cwls.org/las_info.php

=head1 EXPORT

=head2 new

Constructs with the following parameter.

  IO object to be read by this object.

By constructing, the object parses the LAS file down to the line of the beginning of Section `A' (ASCII Log Data).

The constructor may not return anything in case of bad input. Caller should check the returned value.

=head2 get_info_in_non_A_sections

Returns information in sections other than Section A. The following parameter is required.

  Text string of a upper-case alphabet represents a section to request.

Sections `V', `W', `C', and `P' may available. Section `O' is not read by this module even if the input contains.

This method returns an array contains references for arrays. Each array consists of (mnemonic, units, data, description). This method may not return anything if argued section was not found.

=head2 read_Section_A

Read one line from Section `A' in the input and returns the data. The following parameter is optional.

  Value to represent null value in returning values

This method returns a reference for an array containing the data. Value false will be returned when the object reaches to the end of the input.

=head1 AUTHOR

Kyoma Takahashi

=head1 COPYRIGHT

Copyright (C) 2010 by Kyoma Takahashi

=head1 LICENSE

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
