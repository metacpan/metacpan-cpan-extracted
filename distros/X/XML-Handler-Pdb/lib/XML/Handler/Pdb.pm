# $Id: Pdb.pm,v 1.4 2003/04/06 21:17:47 cvsjohan Exp $

package XML::Handler::Pdb;
use strict;
use warnings;

our $VERSION = '0.2';

use base 'XML::Handler::Subs';

use Carp;
use Palm::PDB;
use Palm::Raw;
use File::Temp 'tempfile';

sub new {
	my ($proto, %arg) = @_;

	my $self = $proto->SUPER::new(%arg);

	$self->{_verbose} = $arg{Verbose} || 0; 

	print "Output to ", $self->{Output}, "\n" if $self->{_verbose};

	if (!defined($self->{Output})) {
		( $self->{_TempFH}, $self->{_Tempfile} ) = tempfile;
		$self->{_Output} = $self->{_Tempfile};
	} else {
		$self->{_Output} = $self->{Output};
	} 
	return $self;
}

sub s_pdb {
	my ($self, $el) = @_;

	print "start pdb\n" if $self->{_verbose};

	my $pdb = Palm::Raw->new;
	$pdb->{"name"} = $el->{Attributes}{"{}name"}{Value};
	$pdb->{"type"} = "DATA";
	$pdb->{"creator"} = $el->{Attributes}{"{}creator"}{Value};
	$self->{_pdb} = $pdb;
}

sub e_pdb {
	my ($self, $el) = @_;

	print "end pdb\n" if $self->{_verbose};

	$self->{_pdb}->Write($self->{_Output});
	if (defined $self->{_TempFH}) {
		my $fh = $self->{_TempFH};
		my $buf;
		while ($fh->read($buf, 2048)) { print $buf };
		$fh->close;	
	}
	$self->{_pdb} = undef;
}

sub s_record {
	my ($self, $el) = @_;

	print "start record\n" if $self->{_verbose};
	
	$self->{_actual_record} = $self->{_pdb}->new_Record;	
	$self->{_actual_record}->{"category"} 
		= $el->{Attributes}{"{}category"}{Value} || 0;
}

sub e_record {
	my ($self, $el) = @_;

	print "end record\n" if $self->{_verbose};

	$self->{_pdb}->append_Record($self->{_actual_record});
	$self->{actual_record} = undef;
}

sub s_field {
	my ($self, $el) = @_;

	print "start field\n" if $self->{_verbose};

	my $type = $el->{Attributes}{"{}type"}{Value};
	$self->{_field_type} = $type;

	if (exists($el->{Attributes}{"{}value"})) {
		$self->{_field_value} = $el->{Attributes}{"{}value"}{Value};
	}
}

sub e_field {
	my ($self, $element) = @_;

	my $data;
	my $type = $self->{_field_type};

	print "type := $type\n" if $self->{_verbose};
	if ($self->{_verbose} && defined $self->{_field_value}) {
		print "value := ", $self->{_field_value}, "\n";
	}
	if ($self->{_verbose} && defined $self->{_chars}) {
		print "value := ", $self->{_chars}, "\n";
	}

	# For each type, transform the type to the NSBasic equivalent ...
	#
	if 		($type eq 'text') {
		# Text does not need processing
		$data = $self->{_chars} . "\0";
	} elsif ($type eq 'int') {
		# Int is stored i/t attribute
		$data = pack("N", $self->{_field_value});
	} elsif ($type eq 'date') {
		# Date
		my $packed = pack("d", 
				$self->convert_date_to_nsbasic($self->{_field_value})); 
		$data = pack("C*", reverse unpack("C*", $packed));
	} elsif ($type eq 'time') {
		# Time
		my $packed = pack("d", 
				$self->convert_time_to_nsbasic($self->{_field_value}));
		$data = pack("C*", reverse unpack("C*", $packed));
	} elsif ($type eq 'byte') {
		# Byte
		$data = pack("C", $self->{_field_value});
	} elsif ($type eq 'float' || $type eq 'double') {
		# Float and double
		my $packed = pack("d", $self->{_field_value});
		$data = pack("C*", reverse unpack("C*", $packed));
	} elsif ($type eq 'short') {
		# 16 bit signed int
		$data = pack("n", $self->{_field_value});
	}
	$self->{_chars} = undef;	
	$self->{_field_type} = undef;
	$self->{_field_value} = undef;
	$self->{_actual_record}->{"data"} .= $data;

	print "end field\n" if $self->{_verbose};
}

sub characters {
	my ($self,$chars) = @_;

	print "characters ...\n" if $self->{_verbose};

	return unless $self->in_element('field');
	
	print "characters in field ...\n" if $self->{_verbose};

	$self->{_chars} .= $chars->{Data};
}

sub convert_date_to_nsbasic {
	my ($self, $rawdate) = @_;
	
	my ($year, $month, $day) = ( $rawdate =~ /(\d+)-(\d+)-(\d+)/ );
	return ($year-1900)*10000+$month*100+$day;
}

sub convert_time_to_nsbasic {
	my ($self, $rawdate) = @_;

	my ($hour, $minute, $second) = ( $rawdate =~ /(\d+):(\d+):(\d+)/ );
	return $hour*10000+$minute*100+$second;
}

1;

__END__

=head1 NAME

XML::Handler::Pdb - Generate a Palm PDB from XML data

=head1 SYNOPSIS

Using SAX::Machines:

 use XML::SAX::Machines qw(Pipeline);
 use XML::Handler::Pdb;
 
 Pipeline( XML::Handler::Pdb->new( Output => $outfile )->parse_uri("pdb.xml") ); 

Using directly:

 use XML::SAX;
 use XML::Handler::Pdb;

 XML::SAX::ParserFactory->parser(
	Handler => XML::Handler::Pdb->new(
		Verbose => 0,
		Output => $output
		)
	)->parse_uri($source);

=head1 DESCRIPTION

With this module one can generate a Palm database (.pdb file) from an XML description. The datatypes supported by this module are targetted towards NSBasic. The NSBasic IDE is a superb way of creating PalmOS applications, more can be found on http://www.nsbasic.com.  Supported datatypes are: int, short, byte, float, double, date, time and text. 

=head1 SYNTAX

=head2 <pdb>

This is the root element and must always be present. The element also has 3 mandatory attributes. The C<type> attribute must alwas be C<DATA>, because this module can only generate data oriented databases and no resource databases like a prc file. The C<name> attribute contains the name of the database, used to open the database from PalmOS. The C<creator> attribute must match the creator id of the Palm application that uses this database.

=head2 <record>

A record is a row in a Palm database. The only attribute a record can have is the C<category> it belongs to. The attribute C<category> can accepts a vlaue from 0 to 15. A record in a Palm database can contain an arbitrary amount of C<fields>.

=head2 <field>

The C<field> is a data item in the Palm database. It can be one of the next types: int, date, time, byte, float, double, short and text. One record can have as many fields as necessary. Records can also have different types and a different number of fields. Offcourse, your application will need to deal with this.

The next section talks about the defined datatypes and how to apply them.

=over 4

=item int

 <field type="int" value="42" />

An integer occupies 4 bytes when serialized.

=item short

 <field type="short" value="7" />

A short occupies 2 bytes on IO.

=item byte

 <field type="byte" value="1" />

A byte occupies 1 byte on IO.

=item float, double

 <field type="float" value="3.14" />
 <field type="double" value="2.7" />

A float and double occupy 8 bytes when serialized.

=item text

 <field type="text">Blah Blah blah </field>

When serialized, a text string is closed by a /0 character.

=item time

 <field type="time" value"13:20:01" />

NSBasic uses the next formula to represent a time:

 hours*10000+minutes*100+seconds

This is serialized as a float, occupying 8 bytes of IO. 

=item date

 <field type="date" value="2003-02-19" />

NSBasic uses the next formula to represent a date:

 (years-1900)*10000+months*100*days

This is serialized as a float, occupying 8 bytes of IO. 

=back

=head1 BUGS

Please use http://rt.cpan.org/ for reporting bugs.

=head1 AUTHOR

Johan Van den Brande <johan@vandenbrande.com>

=head1 LICENSE

This is free software, distributed underthe same terms as Perl itself.

=cut
