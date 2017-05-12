package oEdtk::C7Tag;

our $VERSION = '0.05';

# A simple object that describes a Compuset tag.

my $TAG_OPEN	= '<';		# une ouverture de balise compuset (open)
my $TAG_CLOSE	= '>';		# une fermeture de balise compuset (close)
my $TAG_MARKER	= '#';		# un marqueur de début de balise compuset
my $TAG_ASSIGN	= '=';		# un marqueur d'attribution de valeur compuset
my $TAG_COMMENT= '<SK>';		# un commentaire compuset (rem)
my $COMMENT	= 'SK';		# un commentaire compuset (rem)
my $TAG_L_SET	= '<SET>';	# attribution de variable : partie gauche


sub new {
	my ($class, $name, $val) = @_;

	if (ref($val) ne '' && ref($val) ne 'HASH' && ref($val) ne 'oEdtk::C7Doc') {
		die "ERROR: Unexpected value type, must be a scalar or a hashref\n";
	}

	if (length($name) > 8) {
		warn "INFO : Tag name too long: $name\n";
	}

	my $self = {
		name   => $name,
		value  => $val
	};
	bless $self, $class;
	return $self;
}

sub emit {
	my ($self)= @_;
	my $out 	= $TAG_OPEN;

	if (ref($self->{'value'}) ne 'HASH') {
		if (defined $self->{'value'}) {
			if (ref($self->{'value'}) eq '') {
				# A 'simple' tag containing a textual value.
				$self->{'value'} =~ s/\s+/ /g;
			}
			
			if ($self->{'name'}=~/^_include_$/){
				$out .= 'include' . $TAG_CLOSE . $self->{'value'} . $TAG_OPEN . $COMMENT;
			} else {
				$out .= $TAG_MARKER . $self->{'name'} . '=' . $self->{'value'};
			}

		} else {
			$out .= $self->{'name'};
		}
	} else {
		# A super tag containing other tags.
		$out .= '#' . $self->{'name'} . "=";
		while (my ($key, $val) = each %{$self->{'value'}}) {
			my $tag = oEdtk::C7Tag->new($key, $val);
			$out .= $tag->emit();
		}
	}
	$out .= $TAG_CLOSE;
	return $out;
}

1;
