package XML::Filter::Mode;

$VERSION = 0.02;

=head1 NAME

XML::Filter::Mode - Filter out all chunks not in the current mode.

=head1 SYNOPSIS

    use XML::Filter::Mode;
    use strict;

    my $filter = XML::Filter::Mode->new( Modes => "a,b,c" );
    my $filter = XML::Filter::Mode->new( Modes => [qw( a b c )] );

    ## To inspect the modes:
    my @modes = $filter->modes;

    ## To change the modes:
    $h->modes( qw( d e ) );

=head1 DESCRIPTION

Filters portions of documents based on a C<mode=> attribute.

I use this to have XML documents that can be read in several modes, for
instance "test", "demo" and normal (ie not test or demo), or "C",
"Bytecraft_C", "Perl".

Mode names must contain only alphanumerics and "_" (ie match Perl's
\w regexp assertion).

The filter is given a comma separated list of modes.  Each element in
the XML document may have a mode="" attribute that gives a mode
expression.  If there is no mode attribute or it is empty or the mode
expression matches the list of modes, then the element is accepted.
Otherwise it and all of its children are cut from the document.

The mode expression is a boolean expression using the operators C<&>
(which unfortunately must be escaped as "&amp;"),
C<|>, C<,> to build mode matching expressions from a list
Parentheses may be used to group operations.  of words.  C<,> and <|>
are synonyms.

C<!> may be used as a prefix negation operator, so C<!a> means "unless
mode a".

Examples:

    Modes    mode="..." Action
    Enabled  Value
    =====    ========== ======
    (none)   ""         pass

    a        ""         pass
    a        "a"        pass
    a        "a"        pass
    a,b      "a"        pass
    a        "a,b"      pass
    b        "a,b"      pass
    a,b      "a,b"      pass
    b        "!a,b"     pass
    a,b      "a b"      pass

    (none)   "b"        cut
    a        "b"        cut
    a        "a&amp;b"  cut
    b        "a&amp;b"  cut
    a        "!a,b"     cut
    a        "!a"       cut

=head1 METHODS

=over

=cut

use XML::SAX::Base;
@ISA = qw( XML::SAX::Base );

use strict;
use XML::SAX::EventMethodMaker qw( compile_missing_methods sax_event_names );

=item new

    my $filter = XML::Filter::Mode->new( Modes => \@modes );

where $modes is a comma separated list of mode names and @modes is
a list of mode names.

=cut

sub new {
    my $class = ref $_[0] ? ref shift : shift;
    my $self = $class->SUPER::new( @_ );

    $self->modes( defined $self->{Modes} ? $self->{Modes} : "" );

    return $self;
}

=item modes

    $filter->modes( "test,debug" );
    $filter->modes( qw( test debug ) );
    my @modes = $filter->modes;

Sets/gets the modes to be active during parse.  Note that the comma
is the only separator allowed, although whitespace may surround it.
This is not the same comma as used in the mode="" attribute values,
this comma is just a list separator, that one is 

Pass in an undef to clear the list.

Returns a list of mode names.

=cut

sub modes {
    my $self = shift;
    $self->{Modes} =
        join( ",",
            grep length,
            map split( /\s*,\s*/ ),
            grep defined,
            map ref $_ ? @$_ : $_, @_
        ) if @_;
    return split /,/, $self->{Modes} if defined wantarray;
}


sub modes_string {
    return shift->{Modes};
}


sub start_document {
    my $self = shift;
    $self->{Cutting} = 0;
    $self->{CuttingStack} = [];

    $self->SUPER::start_document( @_ );
}

my %mode_subs;

sub start_element {
    my $self = shift;
    my ( $elt ) = @_;

    push @{$self->{CuttingStack}}, $self->{Cutting};
    return if $self->{Cutting};

    my $modes = $self->modes_string;
    $self->{Cutting} ||= do {
        exists $elt->{Attributes}->{"{}mode"}
        && length $elt->{Attributes}->{"{}mode"}->{Value}
            ? do {
                my $mode_attr = $elt->{Attributes}->{"{}mode"}->{Value};
                my $cutting_sub = $mode_subs{$mode_attr} ||= do {
                    ## TODO: use a real parser here to improve
                    ## error reporting and reject all invalid
                    ## mode expressions.  This is BALGE for now.
                    my $mode_expr = $mode_attr;
                    $mode_expr =~ s{&}{&&}g;
                    $mode_expr =~ s{[|,]}{||}g;
                    $mode_expr =~ s{(\w+)}{ /\\b$1\\b/ }g;
                    ## TODO: report line, column and element name?
                    eval "sub { local \$_ = \$_[0]; !( $mode_expr ) }"
                        or die qq{$@ compiling mode="$mode_attr"\n};
                };
                $cutting_sub->( $modes );
            }
            : 0;
    };

    $self->SUPER::start_element( @_ ) unless $self->{Cutting};
}

sub end_element {
    my $self = shift;

    $self->SUPER::end_element( @_ ) unless $self->{Cutting};
    $self->{Cutting} = pop @{$self->{CuttingStack}};
}

compile_missing_methods __PACKAGE__, <<'END_HANDLER', sax_event_names;
#line 0 XML::Filter::Mode::<EVENT>()
sub <EVENT> {
    my $self = shift;
    $self->SUPER::<EVENT>( @_ ) unless $self->{Cutting};
}
END_HANDLER

=back

=head1 LIMITATIONS

The modes passed in are a list and the attributes in the document are
an expression.  Some applications might prefer the reverse, so the
user could say "give me elements for ( A and B ) or C or something.  But
we can address that when we get there.

=head1 COPYRIGHT

Copyright 2003, R. Barrie Slaymaker, Jr., All Rights Reserved

=head1 LICENSE

You may use this module under the terms of the BSD, Artistic, or GPL licenses,
any version.

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=cut

1;
