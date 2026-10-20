package oEdtk::RecordParser;

use strict;
use warnings;
use Data::Dumper;
use Scalar::Util qw(blessed);
our $VERSION = 2.1129;

# FINE-TUNE PARAMETRIZATION
my $_denormalized_record = "OPTION";

# my $_denormalized_split_motif=;

sub dumper {
	my $self = shift;

	return Dumper(shift);
}

# Build the seek plan from the seek-key table: the keys in lexicographic order,
# each paired with its compiled match. next() iterates this instead of sorting
# and re-compiling the keys on every record. The pattern is identical to the
# one next() used to build inline (/^$key(.*)$/), so the captures ($1 the key --
# or its innermost group -- $2 the remainder) are unchanged.
sub _seek_plan {
	my ($seek_keys) = @_;
	return [ map { [ $_, qr/^$_(.*)$/ ] } sort keys %$seek_keys ];
}

sub new {
	my ( $class, $fh, %records ) = @_;
	defined($fh) or die "ERROR: not defined filhandle $fh : $!\n";
	my %seek_keys;

	#	foreach (values %records) {
	#		if (defined($_) && (!blessed($_) || !$_->isa('oEdtk::Record'))) {
	#			die "ERROR: oEdtk::RecordParser::new only accepts oEdtk::Record objects in the hash\n";
	#		}
	#		$seek_keys{$_->{'seek_key'}} .= $_->{'id_key'};
	#		$seek_keys{$_->{'seek_key'}} .= keys ($records->{$id});
	#		warn "INFO: seek_key = ". $_->{'seek_key'} ." = ".$seek_keys{$_->{'seek_key'}}."\n";
	#	}

	foreach my $key ( keys %records ) {
		my $object = $records{$key};
		if ( defined($object) && ( !blessed($object) || !$object->isa('oEdtk::Record') ) ) {
			die "ERROR: oEdtk::RecordParser::new only accepts oEdtk::Record objects in the hash\n";

		}
		elsif ( defined($object) ) {    # ignore undef records

#			warn "DEBUG: $key = ". $object->{'seek_key'} ." - isa('oEdtk::Record') ? ". $object->isa('oEdtk::Record') ." \n";
#			$seek_keys{$object->{'seek_key'}} .= $object->{'id_key'};
			$seek_keys{ $object->{'seek_key'} } .= $key;

  # INFO: seek_key = LIGNE.{153}(.{10}) = L5L6T3L7L4C1T6T4T7F5L3T5
  #			warn "INFO: seek_key = ". $object->{'seek_key'} ." = ".$seek_keys{$object->{'seek_key'}}."\n";
		}
	}

	my $self = {
		input                    => $fh,
		records                  => \%records,
		seek_keys                => \%seek_keys,
		seek_plan                => _seek_plan( \%seek_keys ),
		line                     => '',
		skip_line                => 'FLUX',
		mute_record              => 'ENTETE',
		mute_id                  => 'ENT',
		line_record              => 'LIGNE',
		key_offset               => 153,
		key_size                 => 10,
		denormalized             => 'OPTION',
		denormalized_option      => 'OPTION',
		denormalized_on          => 'ON',
		denormalized_split_motif => "\x{0}|\x{1}|\x{2}"
	};

	bless $self, $class;
	return $self;
}

sub set_skip_line {
	my ( $self, $value ) = @_;

	$self->{'skip_line'} .= $value;
}

sub set_mute_record {
	my ( $self, $value ) = @_;

	$self->{'mute_record'} .= $value;
}

sub set_mute_id {
	my ( $self, $value ) = @_;

	$self->{'mute_id'} .= $value;
}

sub set_line_record {
	my ( $self, $value ) = @_;

	$self->{'line_record'} .= $value;
}

sub set_key_offset {
	my ( $self, $value ) = @_;

	$self->{'key_offset'} .= $value;
}

sub set_key_size {
	my ( $self, $value ) = @_;

	$self->{'key_size'} .= $value;
}

# Set the denormalized-record options. The mainline keeps a single
# "denormalized" key that next() reads; the fork splits it into an
# "option" and an "on" key. set_denormalized_record feeds both fork
# keys so the mainline and fork nomenclatures stay equivalent.
sub set_denormalized_record {
	my ( $self, $value ) = @_;

	$self->{'denormalized'}        .= $value;
	$self->{'denormalized_option'} .= $value;
	$self->{'denormalized_on'}     .= $value;
}

# Fork accessors (S42): each writes only its own key, faithfully to F.
sub set_denormalized_option_record {
	my ( $self, $value ) = @_;

	$self->{'denormalized_option'} .= $value;
}

sub set_denormalized_on_record {
	my ( $self, $value ) = @_;

	$self->{'denormalized_on'} .= $value;
}

sub add_motif_to_denormalized_split {
	my ( $self, $motif ) = @_;

	$self->{'denormalized_split_motif'} .= "|" . $motif;
}

sub set_motif_to_denormalized_split {
	my ( $self, $motif ) = @_;

	$self->{'denormalized_split_motif'} = $motif;
}

# True when the configured cleanup of non-Latin-1 bytes (the DEL character and
# the C1 controls) is on. EDTK_RP_KILL_NON_LATIN is a COMPO key, off by
# default: the mainline assumes its input is sane. config_read() re-parses the
# ini on every call, so the switch is read once per process and cached; a
# missing or unreadable configuration leaves it off.
my $KILL_NON_LATIN;

sub _kill_non_latin_chars {
	my $cfg = shift;
	if ( !defined $cfg ) {
		unless ( defined $KILL_NON_LATIN ) {
			my $read = eval { require oEdtk::Config; oEdtk::Config::config_read('COMPO') } || {};
			$KILL_NON_LATIN = _kill_non_latin_chars($read);
		}
		return $KILL_NON_LATIN;
	}
	return ( ref $cfg && $cfg->{'EDTK_RP_KILL_NON_LATIN'} ) ? 1 : 0;
}

# Parse and return the next record in the stream.
sub next {
	my ($self) = @_;

	my $denormalized_split_motif = $self->{'denormalized_split_motif'};
	my $denormalized             = $self->{'denormalized'};
	my $records                  = $self->{'records'};
	my $seek_keys                = $self->{'seek_keys'};
	my $seek_plan                = $self->{'seek_plan'} // _seek_plan($seek_keys);
	my $skip_line                = $self->{'skip_line'};
	my $mute_record              = $self->{'mute_record'};
	my $line_record              = $self->{'line_record'};
	my $key_offset               = $self->{'key_offset'};
	my $key_size                 = $self->{'key_size'};
	my $fh                       = $self->{'input'};
	defined($fh) or die "ERROR: not defined filhandle $fh : $!\n";

	my ( $id, $data ) = ( "", "" );
	do {
		my $line = <$fh>;

		# Skip lines starting with FLUX.
		while ( defined($line) && $line =~ /^$skip_line/ ) {
			$line = <$fh>;
		}
		return () unless defined $line;

		# Strip the non-Latin-1 bytes a mis-encoded input may carry (the fork
		# does this unconditionally; the mainline gates it on a key, off by
		# default).
		if ( _kill_non_latin_chars() ) {
			require oEdtk::Utils;
			oEdtk::Utils::kill_non_latin_1_9_chars_in_place( \$line );
		}

		chomp $line;
		$self->{'line'} = $line;

	SEEK: {
			if ( $line =~ /^$denormalized(.*)$/ ) {
				$data = $1;
				$id   = $denormalized;

			}
			else {
				foreach my $entry ( @{$seek_plan} ) {

					#					warn "DEBUG: seek => $entry->[0] line $.\n";
					if ( $line =~ $entry->[1] ) {
						( $id, $data ) = ( $1, $2 );
						$id =~ s/\s*//g;

					 #						if (exists $records->{$key}){
					 #							($id, $data) = ($key, $right);
					 #							warn "DEBUG: success search_key = $entry->[0], for keys $id line $.\n";
						last SEEK;

						#						} else {

					}
				}

		#					warn "DEBUG: search_key = $entry->[0], for keys : ".  $seek_keys->{$entry->[0]} ."\n";
			}
			warn "INFO: UNKNOWN RECORD (line $.)=>$line\n";
			warn "INFO: IGNORING UNKNOWN RECORD (line $.)\n";

#				if ($line =~ /^$mute_record.(.*)/) {
#					($id, $data) = ($self->{'mute_id'}, "   ".$1);
#
#				} elsif ($line =~ /^$line_record.{$key_offset}(.{$key_size})(.*)$/) { 	# xxxxx to evolve here to take record keys on 2 chars / 4 chars or more + revisit the parametrizable length of headers and keys
#					# set the record identifier and pass the record, key included:
#					#  the fields_offset is handled in the record object
#					$data = $1.$2;
#					$id = $1;
#					$id =~s/\s*//g;
#					if (!exists $records->{$id}) {
#						die "ERROR: Unexpected record identifier: $id\n";
#					}
#
#				} else {
#					die "ERROR: Unexpected line format (line $.): $line\n";
#				}
#			}
		}
	} while ( $id ne $denormalized && !defined( $records->{$id} ) );

	# DENORMALIZED RECORD SHOULD BE AT THE END OF DATA STREAM
	# TO REVIEW

	if ( $id eq $denormalized ) {

		#		my @data = split(/(?:$denormalized_split_motif)+/, $data);
		my @data = split( /(?:$denormalized_split_motif)/, $data );

		#		my @data = split(/(?:\x{0}|\x{1}|\x{2})+/, $data);
		#		my @data = split(/(?:\x{0}|\x{1}|\x{2}|\x{20})+/, $data);
		# my @data = split(/(?:\(?:\x{0}|\x{20})+(?:\x{1}|\x{2})+/, $data);
		# my @data = split($_denormalized_split_motif, $data);
		return ( $id, \@data );
	}

	my $rec  = $records->{$id};
	my %vals = $rec->parse($data);
	return ( $id, \%vals );
}

1;

=head1 NAME

oEdtk::RecordParser - stream reader and dispatcher over an Infinite flux

=head1 SYNOPSIS

    use oEdtk::RecordParser;

    my $p = oEdtk::RecordParser->new($fh, %records);
    while ( my ($id, $vals) = $p->next ) {
        # $id is the record identifier, $vals a hashref (or an arrayref
        # for the denormalized record)
    }

=head1 DESCRIPTION

Reads records from an Infinite flux and dispatches each line to the matching
C<oEdtk::Record>. A compiled seek plan (the keys in lexicographic order, each
paired with its compiled match) is built once in L</new>, so L</next> does not
re-sort or re-compile the keys on every record.

=head1 METHODS

=head2 new

    my $p = oEdtk::RecordParser->new($fh, %records);

Build a parser over the file handle C<$fh> and the C<%records> table
(identifier to C<oEdtk::Record>). Undef records are ignored; a non-record value
is an error.

=head2 next

    my ($id, $vals) = $p->next;

Read and dispatch the next record. C<FLUX> lines are skipped; the denormalized
record returns an array reference of split fields, any other record returns a
hash reference of parsed values. An exhausted stream returns an empty list.

=head2 dumper

    my $text = $p->dumper($value);

Return C<Data::Dumper::Dumper> of C<$value> (debug helper).

=head2 set_skip_line

    $p->set_skip_line($value);

Append C<$value> to the prefix that marks a line to skip.

=head2 set_mute_record

    $p->set_mute_record($value);

Append C<$value> to the muted-record name.

=head2 set_mute_id

    $p->set_mute_id($value);

Append C<$value> to the muted-record identifier.

=head2 set_line_record

    $p->set_line_record($value);

Append C<$value> to the line-record name.

=head2 set_key_offset

    $p->set_key_offset($value);

Append C<$value> to the key offset.

=head2 set_key_size

    $p->set_key_size($value);

Append C<$value> to the key size.

=head2 set_denormalized_record

    $p->set_denormalized_record($value);

Set the denormalized-record name on both the mainline and the fork keys.

=head2 set_denormalized_option_record

    $p->set_denormalized_option_record($value);

Set the fork's denormalized-option key only.

=head2 set_denormalized_on_record

    $p->set_denormalized_on_record($value);

Set the fork's denormalized-on key only.

=head2 add_motif_to_denormalized_split

    $p->add_motif_to_denormalized_split($motif);

Append C<$motif> to the split pattern used for the denormalized record.

=head2 set_motif_to_denormalized_split

    $p->set_motif_to_denormalized_split($motif);

Replace the split pattern used for the denormalized record.

The private helpers C<_seek_plan> and C<_kill_non_latin_chars> build the seek
plan and gate the non-Latin-1 cleanup; they are not part of the public API.

=head1 AUTHOR

The oEdtk team.

=cut
