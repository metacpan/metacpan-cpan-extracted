# $Id: Pdb.pm,v 1.1.1.1 2003/04/06 21:20:57 cvsjohan Exp $

package XML::Generator::Pdb;
use strict;
use warnings;

our $VERSION = '0.1';

use Palm::Raw;
use Palm::PDB;

sub new {
	my ($proto, %arg) = @_;
	my $class = ref($proto) || $proto;
	my $self = { %arg };
	bless $self, $class;
	
	$self->{PDBFile} || die "Please provide a 'PDBFile'";
	$self->{Layout} || die "I need a 'Layout'";
	
	return $self;
}

sub parse {
	my $self = shift;

	# Open PDB
	my $pdb = Palm::PDB->new;
	$pdb->Load( $self->{PDBFile} ) || croak( "Couldn't open PDB: $!" );
	my @records = @{$pdb->{"records"}};

	# Produce header and pdb start tag
	$self->{Handler}->start_document();
	$self->{Handler}->start_element(
				{
					Name => 'pdb',
					Attributes =>
						{
							type => $pdb->{"type"},
							name => $pdb->{"name"},
							creator => $pdb->{"creator"}
						}
				});				
			
	# For each element, try to parse and generate
	for my $record (@records) {
		$self->{Handler}->start_element(
					{
						Name => 'record',
						Attributes =>
							{
								category => $record->{"category"}
							}
					});

		my $data = $record->{"data"};
		my $offset = 0;
		for my $field (@{$self->{Layout}}) {
			if 		($field eq 'int') {
				my $value = unpack("N", substr($data, $offset, 4));	
				$offset += 4;
				$self->field($field, $value, undef);	
			} elsif	($field eq 'date') {
				my $raw = pack("C*",reverse unpack("C*",substr($data,$offset,8)));
				my $unpacked = unpack("d", $raw);
				my $value = $self->convert_date_from_nsbasic( $unpacked );
				$offset += 8;
				$self->field($field, $value, undef);	
			} elsif ($field eq 'time') {
				my $raw = pack("C*",reverse unpack("C*",substr($data,$offset,8)));
				my $unpacked = unpack("d", $raw);
				my $value = $self->convert_time_from_nsbasic( $unpacked );
				$offset += 8;
				$self->field($field, $value, undef);	
			} elsif ($field eq 'byte') {
				my $value = unpack("C", substr($data, $offset, 1));
				$offset += 1;
				$self->field($field, $value, undef);
			} elsif ($field eq 'float' || $field eq 'double') {
				my $raw = pack("C*",reverse unpack("C*",substr($data,$offset,8)));
				my $value = unpack("d", $raw);
				$offset += 8;
			} elsif ($field eq 'short') {
				my $value = unpack("n", substr($data, $offset, 2));
				$offset += 2;
				$self->field($field, $value, undef); 
			} elsif ($field eq 'text') {
				my ($content) = ( substr($data, $offset) =~ /^(.+?)\0/ );	
				$offset += length($content) + 1;
				$self->field($field, undef, $content);
			} else {
				warn "Unsupported field type: $field";
			}
		}

		$self->{Handler}->end_element(
					{
						Name => 'record'
					});		
	}

	$self->{Handler}->end_element(
			{
				Name => 'pdb'
			});
	$self->{Handler}->end_document();	
}

sub field {
	my ($self, $field, $value, $content) = @_;

	my $el = { 
				Name => 'field',
				Attributes =>
					{
						type => $field
					} 
			 };
	$el->{Attributes}->{value} = $value if $value;
	$self->{Handler}->start_element( $el );
	
	$self->{Handler}->characters({ Data => $content }) if $content;
	
	$self->{Handler}->end_element(
				{
					Name => 'field'
				});
}

sub convert_date_from_nsbasic {
	my ($self, $raw) = @_;

	my $year = int($raw / 10000) + 1900;
	my $month = int(($raw - ($year-1900)*10000) / 100);
	my $day = $raw - ($year-1900)*10000 - $month*100;

	return sprintf("%04d-%02d-%02d", $year, $month, $day);	
}

sub convert_time_from_nsbasic {
	my ($self, $raw) = @_;

	my $hour = int($raw / 10000);
	my $minute = int(($raw - $hour*10000) / 100);
	my $second = $raw - $hour*10000 - $minute*100;

	return sprintf("%02d:%02d:%02d", $hour, $minute, $second);
}

1;

__END__

=head1 NAME

XML::Generator::Pdb - Generate SAX events from a Palm PDB

=head1 SYNOPSIS

 use XML::Handler::YAWriter;
 use XML::Generator::Pdb;
 use IO::File;

 my $writer = XML::Handler::YAWriter->new(
                  Output => IO::File->new( ">-" ),
                  Pretty => {
                    PrettyWhiteIndent => 1,
                    PrettyWhiteNewline => 1
                  }
               );

 my $driver = XML::Generator::Pdb->new(
                  Handler => $writer,
                  PDBFile => $file,
                  Layout => [
                    'int',
                    'date',
                    'time',
                    'text',
                    'text',
                    'text'
                  ]
              );

 $driver->parse;

=head1 DESCRIPTION

This module generates SAX1 events from a palm PDB database. In combination with an XML writer, this module can be used to convert a PDB to an XML description. If you plug this generator in a SAX pipeline (e.g. AxKit) you can manipulate a PDB just as you could do with any other XML source.

=head1 SYNTAX 

More information about the syntax of the generated XML - or SAX events - can be found in L<XML::Handler::Pdb>.

The next datatypes are supported:

=over 4

=item	int

=item	date

=item 	time

=item	byte

=item	float, double

=item	short

=item	text

=back

You specify the layout of the database records in the constructor of XML::Generator::Pdb, using the C<Layout> anonymous array.

=head1 BUGS

Please use http://rt.cpan.org/ for reporting bugs.

=head1 AUTHOR

Johan Van den Brande <johan@vandenbrande.com>

=head1 LICENSE

This is free software, distributed underthe same terms as Perl itself.

=cut
