package oEdtk::Doc;
use strict;

our $VERSION = '2.1131';

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

=head1 NAME

oEdtk::Doc - abstract base class for emitted documents

=head1 SYNOPSIS

    use oEdtk::Doc;        # usually used through a subclass, e.g. oEdtk::TexDoc

    my $doc = oEdtk::TexDoc->new;
    $doc->append('NOM', 'value');
    print $doc;            # dump(), through the "" overload

=head1 DESCRIPTION

The base class for a document built as an ordered list of tags. It stores the
tags, dumps them as a string, inserting a line break once the running length
exceeds the line cutoff, and stringifies to C<dump> through the C<""> overload.
The tag factory and the escaping rules are provided by subclasses
(C<oEdtk::TexDoc>).

=head1 METHODS

=head2 new

    my $doc = oEdtk::Doc->new;

Create an empty document.

=head2 reset

    $doc->reset;

Clear the tag list and the emitted-length counter, and return the object.

=head2 append

    $doc->append($name, $value);

Append a tag. C<$name> may be an C<oEdtk::Doc> (its tags are appended), a hash
reference (each key is appended in turn), or a tag name paired with C<$value>
(built through L</mktag>). Returns the object.

=head2 dump

    my $out = $doc->dump;

Concatenate the emitted tags, inserting L</line_break> whenever the running
length would cross the line cutoff (default C<120>, overridable with the
C<EDTK_LINE_CUTOFF> key of the C<COMPO> section). This is also the C<"">
overload.

=head2 include

    $doc->include($file, $path);

Append an C<_include_> tag for C<$file> under C<$path>. A C<$path> naming an
C<EDTK_DIR_*> key is resolved through the C<ENVDESC> section; a missing file is
an error. Returns the object.

=head2 mktag

Abstract: build the tag object for C<$name> and C<$value>. Unimplemented here
(it C<die>s); a concrete subclass such as L<oEdtk::TexDoc> provides it.

=head2 append_table

Abstract: append a table under C<$name>. Unimplemented here (it C<die>s).

=head2 line_break

Abstract: return the string inserted at a line break. Unimplemented here (it
C<die>s).

=head2 escape

Abstract: escape a string for the target format. Unimplemented here (it
C<die>s).

The private helper C<_line_cutoff> resolves and caches the effective line
cutoff; it is not part of the public API.

=head1 AUTHOR

The oEdtk team.

=cut
