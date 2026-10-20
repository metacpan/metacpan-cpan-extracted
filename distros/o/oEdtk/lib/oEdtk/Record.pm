package oEdtk::Record;

use strict;
use warnings;

use Scalar::Util qw(blessed);
our $VERSION = 2.1129;

sub debug {
	my ($self) = @_;
	$self->{'_DEBUG'} = 1;
}

# A RECORD IS A SEQUENCE OF FIELDS.
sub new {
	my ( $class, @fields ) = @_;

	my $template = '';
	foreach my $i ( 0 .. $#fields ) {
		my $field = $fields[$i];
		if ( !blessed($field) || !$field->isa('oEdtk::Field') ) {
			die "ERROR: oEdtk::Record::new only accepts oEdtk::Field objects\n";
		}
		my $len = $field->get_len();
		if ( $len eq '*' && $i < $#fields ) {
			die "ERROR: oEdtk::Record::new: catch-all field must be the last\n";
		}

		#		if ($i != 0) {
		#			$template .= ' ';
		#		}
		$template .= "A$len";
	}

	my $self = {
		seek_key      => "LIGNE.{153}(.{10})",
		fields_offset => 10,
		fields        => \@fields,
		template      => $template,
		bound         => {}
	};
	bless $self, $class;
	return $self;
}

sub set_seek_key {
	my ( $self, $seek_key ) = @_;

	$self->{'seek_key'} = $seek_key || "LIGNE.{153}(.{10})";
}

sub set_fields_offset {
	my ( $self, $fields_offset ) = @_;

	$self->{'fields_offset'} = $fields_offset || 10;
}

sub parse {
	my ( $self, $line ) = @_;
	my @values;

	my $bound = $self->{'bound'};

	#	my $fields_offset	= $self->{'fields_offset'};
	#	if ($line !~ /^.{$fields_offset}(.*)$/) {
	#		die "ERROR: Line too short\n";
	#	}
	#	$line	= $1;

	my @vals  = unpack( $self->{'template'}, $line );
	my %hvals = ();
	foreach my $i ( 0 .. $#{ $self->{'fields'} } ) {
		my $field = $self->{'fields'}->[$i];
		my $name  = $field->get_name();
		if ( exists( $bound->{$name} ) ) {
			$hvals{$name} = $field->process( $vals[$i] );
		}
	}
	return %hvals;
}

# Bind fields onto the record. With a name => new-name map, rename
# the matching fields; with no argument (the fork form used by
# oEUser::Descriptor) bind every field under its current name, so
# that parse() returns them all. Returns the record.
sub bind {
	my $self = shift;
	my %map  = @_;

	my %bound;
	foreach my $field ( @{ $self->{'fields'} } ) {
		my $name = $field->get_name();
		if (@_) {
			next unless exists( $map{$name} );
			my $new = $map{$name};
			$field->set_name($new);
			$bound{$new} = 1;
		}
		else {
			$bound{$name} = 1;
		}
	}
	$self->{'bound'} = { %{ $self->{'bound'} }, %bound };
	return $self;
}

sub bind_all {
	my ($self) = @_;

	my $count = 0;
	my $pos   = 0;
	my %identifiers;
	foreach my $field ( @{ $self->{'fields'} } ) {
		my $name = $field->get_name();
		$name =~ s/(?:-\d+)?$//;

		# Select the longest component.
		my @parts = split( /-/, $name );
		my $id    = ( reverse sort { length($a) <=> length($b) } @parts )[0];

		my $orig = $field->get_name();
		my $len  = $field->get_len();
		warn "DEBUG: $id \tindex: $count \tpos: $pos \tlength: $len \tfrom $orig\n"
			if $self->{'_DEBUG'};
		$pos += $len if ( $len ne '*' );

		$field->set_name($id);
		$identifiers{$id} = 1;

		$self->{'bound'} = { %{ $self->{'bound'} }, $id => 1 };
		$count++;
	}
}

1;

=head1 NAME

oEdtk::Record - a fixed-width record made of typed fields

=head1 SYNOPSIS

    use oEdtk::Record;

    my $rec = oEdtk::Record->new(@fields);   # oEdtk::Field objects
    $rec->bind_all;
    my %vals = $rec->parse($line);

=head1 DESCRIPTION

A record is an ordered sequence of typed fields (L<oEdtk::Field> objects). It
builds an C<unpack> template from the field lengths, unpacks a raw line, and
runs each bound field's C<process> to produce a name-to-value hash.

=head1 METHODS

=head2 new

    my $rec = oEdtk::Record->new(@fields);

Build a record from C<@fields>. Every argument must be an C<oEdtk::Field>, and a
catch-all field (length C<*>) must come last.

=head2 debug

    $rec->debug;

Turn on the verbose C<bind_all> output.

=head2 set_seek_key

    $rec->set_seek_key($seek_key);

Set the regex used to find this record in the stream; defaults to the
C<LIGNE...> form.

=head2 set_fields_offset

    $rec->set_fields_offset($offset);

Set the offset at which the fields start.

=head2 parse

    my %values = $rec->parse($line);

Unpack C<$line> and run each bound field's C<process>, returning a hash of
name-to-value pairs.

=head2 bind

    $rec->bind(%rename);
    $rec->bind;              # bind every field under its current name

Bind fields onto the record. With a name-to-new-name map, rename the matching
fields; with no argument, bind every field so L</parse> returns them all.
Returns the record.

=head2 bind_all

    $rec->bind_all;

Name each field after its longest C<->-separated component and bind all of
them.

=head1 AUTHOR

The oEdtk team.

=cut
