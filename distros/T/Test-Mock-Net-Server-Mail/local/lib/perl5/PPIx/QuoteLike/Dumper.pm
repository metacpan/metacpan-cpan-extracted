package PPIx::QuoteLike::Dumper;

use 5.006;

use strict;
use warnings;

use Carp;
use PPI::Document;
use PPI::Dumper;
use PPIx::QuoteLike;
use PPIx::QuoteLike::Constant qw{ @CARP_NOT };
use Scalar::Util ();

our $VERSION = '0.006';

use constant SCALAR_REF	=> ref \0;

{
    my $default = {
	encoding	=> undef,
	file		=> undef,
	indent		=> 2,
	margin		=> 0,
	perl_version	=> 0,
	ppi		=> 0,
	significant	=> 0,
	tokens		=> 0,
	variables	=> 0,
    };

    sub new {
	my ( $class, $source, %arg ) = @_;

	my $self = {
	    %{ $default },
	    object	=> undef,
	    source	=> $source,
	};

	foreach my $key ( keys %{ $default } ) {
	    defined $arg{$key}
		and $self->{$key} = $arg{$key};
	}

	$self->{object} = _isa( $source, 'PPIx::QuoteLike' ) ? $source :
	    PPIx::QuoteLike->new( $source,
		map { $_ => $arg{$_} } qw{ encoding postderef },
	    )
	    or return;

	return bless $self, ref $class || $class;
    }
}

sub dump : method {	## no critic (ProhibitBuiltinHomonyms)
    my ( $class, $source, %arg ) = @_;
    my $rslt;
    my $margin = ' ' x ( $arg{margin} || 0 );
    my $none = delete $arg{none};
    foreach my $obj ( $class->_source_to_dumpers( $source, %arg ) ) {
	my $src = $obj->{object}->source();
	$rslt .= "\n$margin$src";
	if ( _isa( $src, 'PPI::Element' ) and my $loc = $src->location() ) {
	    $rslt .= sprintf ' %s line %d column %d',
		_dor( $loc->[4], $obj->{file}, '?' ),
		$loc->[0], $loc->[1];
	}
	$rslt .= "\n" . $obj->string();
    }
    defined $rslt
	and return $rslt;
    defined $none
	or return;
    $none =~ s/ (?: \A | (?<! \n ) ) \z /\n/smx;
    return $none;
}

sub list {
    my ( $self, $split ) = @_;
    __PACKAGE__ eq caller	# Only this package is allowed to
	or $split = undef;	# set the $split argument.
    my $indent;
    my $obj = $self->{object};
    my @rslt;
    my $selector;
    if ( $self->{tokens} ) {
	$indent = '';
	$selector = sub { return @{
	    $obj->find( 'PPIx::QuoteLike::Token' ) || [] };
	};
    } else {
	$indent = ' ' x $self->{indent};
	my $string = sprintf '%s%s...%s',
	    map { _format_content( $obj, $_ ) }
	    qw{ type start finish };
	push @rslt,
	    join "\t", ref $obj, $string,
	    _format_attr( $obj, qw{ encoding failures interpolates } ),
	    $self->_perl_version( $obj ),
	    $self->_variables( $obj ),
	    ;
	$selector = sub { return $obj->children() };
    }
    foreach my $elem ( $selector->() ) {
	$self->{significant}
	    and not $elem->significant()
	    and next;
	my @line = (
	    ref $elem,
	    _quote( $elem->content() ),
	    $self->_perl_version( $elem ),
	    $self->_variables( $elem ),
	);
	my @ppi;
	@ppi = $self->_ppi( $elem, $split )
	    and push @line, shift @ppi;
	push @rslt, map { "$indent$_" } join( "\t", @line ), @ppi;
    }
    return @rslt;
}

sub print : method {	## no critic (ProhibitBuiltinHomonyms)
    my ( $self ) = @_;
    print $self->string();
    return;
}

sub string {
    my ( $self ) = @_;
    my $margin = ' ' x $self->{margin};
    return join '', map { "$margin$_\n" } $self->list( 1 );
}

{
    # We have to hold a reference to the PPI document until we're done
    # with all its elements, otherwise they evaporate. Holding it here
    # works as long as we actually format the dump for all elements
    # before calling this again.
    my $doc;

    sub _doc_to_dumper {
	my ( $class, $path, %arg ) = @_;
	$doc = PPI::Document->new( $path )
	    or return;
	ref $path
	    or $arg{file} = $path;
	$doc->index_locations();
	return map { $class->new( $_, %arg ) }
	    @{ $doc->find( 'PPI::Token' ) || [] };
    }
}

sub _dor {
    my @arg = @_;
    foreach my $a ( @arg ) {
	defined $a
	    and return $a;
    }
    return;
}

sub _format_attr {
    my ( $obj, @arg ) = @_;
    my @rslt;
    foreach my $attr ( @arg ) {
	defined( my $val = $obj->$attr() )
	    or next;
	push @rslt, sprintf '%s=%s', $attr, _quote( $val );
    }
    return @rslt;
}

sub _format_content {
    my ( $obj, $method, @arg ) = @_;
    my $val = $obj->$method( @arg );
    ref $val
	and $val = $val->content();
    return defined $val ? $val : '?';
}

sub _isa {
    my ( $arg, $class ) = @_;
    Scalar::Util::blessed( $arg )
	or return 0;
    return $arg->isa( $class );
}

sub _perl_version {
    my ( $self, $elem ) = @_;
    $self->{perl_version}
	or return;
    my $intro = $elem->perl_version_introduced();
    my $remov = $elem->perl_version_removed();
    return defined $remov ? "$intro <= \$] < $remov" : "$intro <= \$]";
}

sub _ppi {
    my ( $self, $elem, $split ) = @_;

    $self->{ppi}
	and $elem->can( 'ppi' )
	or return;

    my $dumper = PPI::Dumper->new( $elem->ppi(),
	map { $_ => $self->{$_} } qw{ indent },
    );

    my $str = $dumper->string();
    chomp $str;

    $split
	and return split qr{ \n }smx, $str;

    return $str;
}

sub _quote {
    my ( $val ) = @_;
    ref $val
	and $val = $val->content();
    defined $val
	or return 'undef';
    Scalar::Util::looks_like_number( $val )
	and return $val;
    if ( $val =~ m/ \A << /smx ) {
	chomp $val;
	return "<<'__END_OF_HERE_DOCUMENT'
$val
__END_OF_HERE_DOCUMENT
";
    }

=begin comment

    $val =~ m/ [{}] /smx
	or return "q{$val}";
    $val =~ m{ / }smx
	or return "q/$val/";

=end comment

=cut

    $val =~ s/ (?= [\\'] )/\\/smxg;
    return "'$val'";
}

sub _source_to_dumpers {
    my ( $class, $path, %arg ) = @_;
    if ( Scalar::Util::blessed( $path ) ) {
	if ( _isa( $path, 'PPI::Node' ) ) {
	    return map {
		PPIx::QuoteLike->handles( $_ ) ?
		    $class->new( $_, %arg ) : () }
		@{ $path->find( 'PPI::Token' ) || [] };
	} elsif ( _isa( $path, 'PPI::Element' ) ) {
	    PPIx::QuoteLike->handles( $path )
		and return $class->new( $path, %arg );
	}
    } elsif ( my $ref = ref $path ) {
	SCALAR_REF eq $ref
	    or return;
	return $class->_doc_to_dumper( $path, %arg );
    } else {
	-f $path
	    or return $class->new( $path, %arg );
	-T _
	    or return;
	unless ( $path =~ m/ [.] (?: (?i: pl ) | pm | t ) \z /smx ) {
	    open my $fh, '<', $path
		or return;
	    defined( local $_ = <$fh> )
		or return;
	    close $fh;
	    m/ perl /smx
		or return;
	}
	return $class->_doc_to_dumper( $path, %arg );
    }
    return;
}

sub _variables {
    my ( $self, $elem ) = @_;

    $self->{variables}
	and $elem->can( 'variables' )
	or return;

    return join ',', sort $elem->variables();
}

1;

__END__

=head1 NAME

PPIx::QuoteLike::Dumper - Dump the results of parsing quotelike things

=head1 SYNOPSIS

 use PPIx::QuoteLike::Dumper;
 PPIx::QuoteLike::Dumper->new( '"foo$bar baz"' )
   ->print();

=head1 DESCRIPTION

This class generates a formatted dump of a
L<PPIx::QuoteLike|PPIx::QuoteLike> object, or a string that can be made
into such an object.

=head1 METHODS

This class supports the following public methods. Methods not documented
here are private, and unsupported in the sense that the author reserves
the right to change or remove them without notice.

=head2 new

 my $dumper = PPIx::QuoteLike::Dumper->new(
     '"foo$bar baz"',
     variables	=> 1,
 );

This static method instantiates the dumper. It takes the string or
L<PPIx::QuoteLike|PPIx::QuoteLike> object to be dumped as the first
argument. Optional further arguments may be passed as name/value pairs.

The following optional arguments are recognized:

=over

=item encoding name

This argument is the encoding of the object to be dumped. It is passed
through to L<PPIx::QuoteLike|PPIx::QuoteLike>
L<new()|PPIx::QuoteLike/new> unless the first argument was a
L<PPIx::QuoteLike|PPIx::QuoteLike> object, in which case it is ignored.

=item indent number

This argument specifies the number of additional spaces to indent each
level of the parse hierarchy. This is ignored if the C<tokens> argument
is true.

The default is C<2>.

=item margin number

This argument is the number of additional spaces to indent the parse
hierarchy, over those specified by the margin.

The default is C<0>.

=item perl_version Boolean

This argument specifies whether or not the perl versions introduced and
removed are included in the dump.

The default is C<0> (i.e. false).

=item postderef Boolean

This argument specifies whether or not postfix dereferences are
recognized in interpolations. It is passed through to
L<PPIx::QuoteLike|PPIx::QuoteLike> L<new()|PPIx::QuoteLike/new> unless
the first argument was a L<PPIx::QuoteLike|PPIx::QuoteLike> object, in
which case it is ignored.

=item ppi Boolean

This argument specifies whether or not a PPI dump is provided for
interpolations.

The default is C<0> (i.e. false).

=item tokens boolean

If true, this argument causes an unstructured dump of tokens found in
the parse.

The default is C<0> (i.e. false).

=item variables Boolean

If true, this argument causes all variables actually interpolated by any
interpolations to be dumped.

The default is C<0> (i.e. false).

=back

=head2 dump

 print PPIx::Regexp::Dumper->dump( 'foo/bar.pl',
     variables => 1,
 );

This static method returns a string that represents a dump of its first
argument. It takes the same optional arguments as L<new()|/new>. This
method differs from L<new()|/new> in its interpretation of the first
argument.

=over

=item * If the first argument is the name of a file, or is a SCALAR
reference, it is made into a L<PPI::Document|PPI::Document> and all
strings in the document are dumped.

=item * If the first argument is a L<PPI::Node|PPI::Node> all strings in
the node are dumped. Note that a L<PPI::Document|PPI::Document> is a
L<PPI::Node|PPI::Node>.

=back

Otherwise the first argument is handled just like L<new()|/new> would
handle it.

The return is the string representation of the dump.

In addition to the optional arguments accepted by L<new()|/new>, the
following can be specified:

=over

=item none

This argument specifies a string to return if no dump can be produced
(typically because the first argument is neither a file name nor text
that is recognized by this package). If unspecified, or specified as
C<undef>, nothing is returned in this case.

=back 

The output for an individual quote-like object differs from the
L<string()|/string> output on the same object in that it is preceded by
the literal sting being dumped, and file and location information if
that can be determined.

=head2 list

 print map { "$_\n" } $dumper->list();

This method returns an array containing the dump output. one line per
element. The output has no left margin applied, and no trailing
newlines. Embedded newlines are probable if the C<ppi> argument was
specified when the dumper was instantiated.

=head2 print

 $dumper->print();

This method simply prints the result of L</string> to standard out.

=cut

sub print : method {	## no critic (ProhibitBuiltinHomonyms)
    my ( $self ) = @_;
    print $self->string();
    return;
}

=head2 string

 print $dumper->string();

This method adds left margin and newlines to the output of L</list>,
concatenates the result into a single string, and returns that string.

=cut

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<http://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016-2018 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
