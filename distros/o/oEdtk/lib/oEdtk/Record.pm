package oEdtk::Record;

use strict;
use warnings;

use Scalar::Util qw(blessed);
our $VERSION	= 0.7005;

sub debug {
	my ($self)= @_;
	$self->{'_DEBUG'} = 1;
}


# A RECORD IS A SEQUENCE OF FIELDS.
sub new {
	my ($class, @fields) = @_;

	my $template = '';
	foreach my $i (0 .. $#fields) {
		my $field = $fields[$i];
		if (!blessed($field) || !$field->isa('oEdtk::Field')) {
			die "ERROR: oEdtk::Record::new only accepts oEdtk::Field objects\n";
		}
		my $len = $field->get_len();
		if ($len eq '*' && $i < $#fields) {
			die "ERROR: oEdtk::Record::new: catch-all field must be the last\n";
		}
#		if ($i != 0) {
#			$template .= ' ';
#		}
		$template .= "A$len";
	}

	my $self = {
		seek_key		=> "LIGNE.{153}(.{10})",
		fields_offset	=> 10,
		fields		=> \@fields,
		template		=> $template,
		bound		=> {}
	};
	bless $self, $class;
	return $self;
}


sub set_seek_key{
	my ($self, $seek_key)= @_;
	
	$self->{'seek_key'} = $seek_key || "LIGNE.{153}(.{10})";
}


sub set_fields_offset {
	my ($self, $fields_offset)= @_;
	
	$self->{'fields_offset'} = $fields_offset || 10;
}


sub parse {
	my ($self, $line)	= @_;
	my @values;

	my $bound			= $self->{'bound'};
#	my $fields_offset	= $self->{'fields_offset'};
#	if ($line !~ /^.{$fields_offset}(.*)$/) {
#		die "ERROR: Line too short\n";
#	}
#	$line	= $1;

	my @vals	= unpack($self->{'template'}, $line);
	my %hvals	= ();
	foreach my $i (0 .. $#{$self->{'fields'}}) {
		my $field= $self->{'fields'}->[$i];
		my $name = $field->get_name();
		if (exists($bound->{$name})) {
			$hvals{$name} = $field->process($vals[$i]);
		}
	}
	return %hvals;
}


sub bind {
	my ($self, %map) = @_;

	my %bound;
	foreach my $field (@{$self->{'fields'}}) {
		my $name = $field->get_name();
		if (exists($map{$name})) {
			my $new = $map{$name};
			$field->set_name($new);
			$bound{$new} = 1;
		}
	}
	$self->{'bound'} = { %{$self->{'bound'}}, %bound };
}


sub bind_all {
	my ($self) = @_;

	my $count = 0;
	my $pos = 0;
	my %identifiers;
	foreach my $field (@{$self->{'fields'}}) {
		my $name = $field->get_name();
		$name =~ s/(?:-\d+)?$//;

		# Select the longest component.
		my @parts = split(/-/, $name);
		my $id = (reverse sort { length($a) <=> length($b) } @parts)[0];

		my $orig= $field->get_name();
		my $len = $field->get_len();
		warn "DEBUG: $id \tindex: $count \tpos: $pos \tlength: $len \tfrom $orig\n" if $self->{'_DEBUG'};
		$pos += $len if ($len ne '*');
		
		$field->set_name($id);
		$identifiers{$id} = 1;

		$self->{'bound'} = { %{$self->{'bound'}}, $id => 1 };
		$count++;
	}
}


# Bind all the fields in a record, following the old Compuset convention.
sub bind_all_c7 {
	my ($self) = @_;

	my $count = 0;
	my $pos = 0;
	my %identifiers;
	foreach my $field (@{$self->{'fields'}}) {
		my $name = $field->get_name();
		$name =~ s/(?:-\d+)?$//;

		# Select the longest component.
		my @parts = split(/-/, $name);
		my $id = (reverse sort { length($a) <=> length($b) } @parts)[0];
		$id = substr($id, 0, 7);
		$id .= 'x' x (7 - length($id));
		if (exists($identifiers{$id})) {
			$id = substr($id, 0, 4) . sprintf("%03d", $count);
			my $char = ord('a');
			while (exists($identifiers{$id})) {
				$id = substr($id, 0, 3) . $count . chr($char);
			}
		}

		my $orig= $field->get_name();
		my $len = $field->get_len();
		warn "DEBUG: $id \tindex: $count \tpos: $pos \tlength: $len \tfrom $orig\n" if $self->{'_DEBUG'};
		$pos += $len if ($len ne '*');
		
		$field->set_name($id);
		$identifiers{$id} = 1;

		$self->{'bound'} = { %{$self->{'bound'}}, $id => 1 };
		$count++;
	}
}


1;
