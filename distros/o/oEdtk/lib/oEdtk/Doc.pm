package oEdtk::Doc;
use strict;

our $VERSION = '2.1109';

use Scalar::Util qw(blessed);
use overload '""' => \&dump;
use oEdtk::Config qw(config_read);

# The maximum number of characters to output before inserting a newline
# character. The mainline value is 120; the EDTK_LINE_CUTOFF key of the COMPO
# section overrides it (the fork emits one tag per line). config_read()
# re-parses the ini on every call, so the switch is read once and cached.
use constant DEFAULT_LINE_CUTOFF => 120;

my $LINE_CUTOFF;

sub _line_cutoff {
	unless ( defined $LINE_CUTOFF ) {
		my $cfg = eval { config_read('COMPO') } || {};
		my $val = ref $cfg ? $cfg->{'EDTK_LINE_CUTOFF'} : undef;
		$LINE_CUTOFF = ( defined $val && $val =~ /\S/ ) ? $val : DEFAULT_LINE_CUTOFF;
	}
	return $LINE_CUTOFF;
}

sub new {
	my ($class) = @_;

	my $self = {};
	bless $self, $class;
	$self->reset();
	return $self;
}

sub reset {
	my ($self) = @_;

	$self->{'taglist'} = [];
	$self->{'emitted'} = 0;
	return $self;
}

sub append {
	my ( $self, $name, $value ) = @_;

	if ( blessed($name) && $name->isa('oEdtk::Doc') ) {
		push( @{ $self->{'taglist'} }, @{ $name->{'taglist'} } );
	}
	elsif ( ref($name) eq 'HASH' ) {
		while ( my ( $key, $val ) = each(%$name) ) {
			$self->append( $key, $val );
		}
	}
	else {
		my $tag = $self->mktag( $name, $value );
		push( @{ $self->{'taglist'} }, $tag );
	}
	return $self;
}

sub dump {
	my ($self) = @_;

	my $out = '';
	foreach ( @{ $self->{'taglist'} } ) {
		my $tag    = $_->emit;
		my $taglen = length $tag;
		if ( $self->{'emitted'} + $taglen > _line_cutoff() ) {
			$out .= $self->line_break();
			$self->{'emitted'} = 0;
		}
		$self->{'emitted'} += $taglen;
		$out .= $tag;
	}
	return $out;
}

sub include {
	my ( $self, $file, $path ) = @_;

	if ( defined $path ) {
		if ( $path =~ /^EDTK_DIR_/ ) {
			my $cfg = config_read('ENVDESC');
			$path = $cfg->{$path};
		}
	}
	else {
		$path = ".";
		warn "INFO: include param1 is $file, assuming param2 is $path \n";
	}

	my $link = $path . "/" . $file;
	$link =~ s/\\/\//g;
	if   ( -e $link ) { }
	else              { die "ERROR: can't find include $link\n"; }

	$self->append( "_include_", $link );
	return $self;
}

# THE FOLLOWING METHODS SHOULD ONLY BE IMPLEMENTED BY
# THE SUBCLASSES (SEE TEXDOC).
sub mktag {
	die "ERROR: oEdtk::Doc::mktag unimplemented method\n";
}

sub append_table {
	die "ERROR: oEdtk::Doc::append_table unimplemented method\n";
}

sub line_break {
	die "ERROR: oEdtk::Doc::line_break unimplemented method\n";
}

sub escape {
	die "ERROR: oEdtk::Doc::escape unimplemented method\n";
}

1;
