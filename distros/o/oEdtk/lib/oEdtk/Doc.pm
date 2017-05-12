package oEdtk::Doc;
our $VERSION = '0.05';

use Scalar::Util qw(blessed);
use overload '""' => \&dump;
use oEdtk::Config (config_read);
# The maximum number of characters to output before inserting
# a newline character.
my $LINE_CUTOFF = 120;


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
}


sub append {
	my ($self, $name, $value) = @_;

	if (blessed($name) && $name->isa('oEdtk::Doc')) {
		push(@{$self->{'taglist'}}, @{$name->{'taglist'}});
	} elsif (ref($name) eq 'HASH') {
		while (my ($key, $val) = each(%$name)) {
			$self->append($key, $val);
		}
	} else {
		my $tag = $self->mktag($name, $value);
		push(@{$self->{'taglist'}}, $tag);
	}
}


sub dump {
	my ($self) = @_;

	my $out = '';
	foreach (@{$self->{'taglist'}}) {
		my $tag = $_->emit;
		my $taglen = length $tag;
		if ($self->{'emitted'} + $taglen > $LINE_CUTOFF) {
			$out .= $self->line_break();
			$self->{'emitted'} = 0;
		}
		$self->{'emitted'} += $taglen;
		$out .= $tag;
	}
	return $out;
}


sub include {
	my ($self, $file, $path) = @_;

	if (defined $path){
		if ($path=~/^EDTK_DIR_/) {
			my $cfg	= config_read('ENVDESC');
			$path	= $cfg->{$path};
		}
	} else {
		$path = ".";
		warn "INFO : include param1 is $file, assuming param2 is $path \n";
	}

	my $link = $path ."/". $file;
	$link=~s/\\/\//g;
	if (-e $link){} else {die "ERROR: can't find include $link\n";}

	$self->append("_include_", $link);
}


# THE FOLLOWINGS METHODS SHOULD ONLY BE IMPLEMENTED BY
# THE SUBCLASSES (SEE C7DOC OR TEXDOC).
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
