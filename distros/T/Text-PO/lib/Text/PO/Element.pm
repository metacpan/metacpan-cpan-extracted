##----------------------------------------------------------------------------
## PO Files Manipulation - ~/lib/Text/PO/Element.pm
## Version v0.4.2
## Copyright(c) 2025 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/07/23
## Modified 2025/12/05
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Text::PO::Element;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    use vars qw( $VERSION );
    use overload (
        '=='  => sub { _obj_eq(@_) },
        '!='  => sub { !_obj_eq(@_) },
        'eq'  => sub { _obj_eq(@_) },
        'ne'  => sub { !_obj_eq(@_) },
        fallback => 1,
    );
    use Text::Wrap ();
    our $VERSION = 'v0.4.2';
    use open ':std' => ':utf8';
};

use strict;
use warnings;

$Text::Wrap::columns = 80;

sub init
{
    my $self = shift( @_ );
    $self->{msgid}          = undef;
    $self->{msgstr}         = undef;
    $self->{msgid_plural}   = undef;
    $self->{context}        = undef;
    $self->{fuzzy}          = undef;
    $self->{comment}        = [];
    $self->{auto_comment}   = [];
    # e.g.: c-format
    $self->{flags}          = [];
    # Is it plural?
    $self->{plural}         = 0;
    # reference
    $self->{file}           = undef;
    $self->{line}           = undef;
    $self->{encoding}       = undef;
    # Parent po object
    $self->{po}             = undef;
    # Whether this element is actually just an include directive
    # If it is, the include file value is stored in the comment
    $self->{is_include}     = 0;
    $self->{is_meta}        = 0;
    $self->{_po_line}       = 0;
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ );
    return( $self );
}

sub add_auto_comment { return( shift->_add( 'auto_comment', @_ ) ); }

sub add_comment { return( shift->_add( 'comment', @_ ) ); }

sub add_msgid { return( shift->_add( 'msgid', @_ ) ); }

sub add_msgid_plural { return( shift->_add( 'msgid_plural', @_ ) ); }

sub add_msgstr { return( shift->_add( 'msgstr', @_ ) ); }

sub add_reference 
{
    my $self = shift( @_ );
    if( @_ )
    {
        ## If there is any existing value, convert it to array
        $self->{file} = [$self->{file}] if( length( $self->{file} ) && $self->_is_array( $self->{file} ) );
        $self->{line} = [$self->{line}] if( length( $self->{line} ) && $self->_is_array( $self->{line} ) );
        if( $self->_is_array( $_[0] ) )
        {
            push( @{$self->{file}}, $_[0]->[0] );
            push( @{$self->{line}}, $_[0]->[1] );
        }
        else
        {
            push( @{$self->{file}}, shift( @_ ) );
            push( @{$self->{line}}, shift( @_ ) );
        }
    }
    return( $self );
}

sub auto_comment { return( shift->_set_get_array( 'auto_comment', @_ ) ); }

sub comment { return( shift->_set_get_array( 'comment', @_ ) ); }

sub context { return( shift->_set_get_scalar( 'context', @_ ) ); }

sub delete
{
    my $self = shift( @_ );
    my $po = $self->po;
    return( $self->error( "No Text::PO object set." ) ) if( !$po );
    return( $po->remove_element( $self ) );
}

sub dump
{
    my $self = shift( @_ );
    my @res = ();
    if( $self->is_include )
    {
        push( @res, '# ' . join( "\n# ", @{$self->{comment}} ) ) if( scalar( @{$self->{comment}} ) );
        push( @res, '#. $include "' . $self->{file} . '"' ) if( length( $self->{file} // '' ) );
    }
    else
    {
        push( @res, '# ' . join( "\n# ", @{$self->{comment}} ) ) if( scalar( @{$self->{comment}} ) );
        push( @res, '#. ' . join( "\n#. ", @{$self->{auto_comment}} ) ) if( scalar( @{$self->{auto_comment}} ) );
        my $ref = $self->reference;
        push( @res, "#: $ref" ) if( length( $ref ) );
        my $flags = $self->flags;
        if( scalar( @$flags ) )
        {
            push( @res, sprintf( '#, %s', join( ", ", @$flags ) ) );
        }
        push( @res, sprintf( 'msgctxt "%s"', $self->po->quote( $self->{context} ) ) ) if( length( $self->{context} ) );
        foreach my $k ( qw( msgid msgid_plural ) )
        {
            if( $self->can( "${k}_as_string" ) )
            {
                my $sub = "${k}_as_string";
                push( @res, $self->$sub() );
            }
            else
            {
                if( ref( $self->{ $k } ) && scalar( @{$self->{ $k }} ) )
                {
                    push( @res, sprintf( '%s ""', $k ) );
                    push( @res, map( sprintf( '"%s"', $self->po->quote( $_ ) ), @{$self->{ $k }} ) );
                }
                elsif( !ref( $self->{ $k } ) && length( $self->{ $k } ) )
                {
                    push( @res, sprintf( '%s "%s"', $k, $self->po->quote( $self->{ $k } ) ) );
                }
            }
        }
        push( @res, $self->msgstr_as_string );
    }
    return( join( "\n", @res ) );
}

sub encoding { return( shift->_set_get_scalar( 'encoding', @_ ) ); }

sub file { return( shift->_set_get_scalar( 'file', @_ ) ); }

sub flags { return( shift->_set_get_array( 'flags', @_ ) ); }

sub fuzzy { return( shift->_set_get_boolean( 'fuzzy', @_ ) ); }

sub id
{
    my $self = shift( @_ );
    my $msgid = $self->msgid;
    if( ref( $msgid ) )
    {
        return( CORE::join( '', @$msgid ) );
    }
    else
    {
        return( $msgid );
    }
}

sub is_include { return( shift->_set_get_boolean( 'is_include', @_ ) ); }

sub is_meta { return( shift->_set_get_boolean( 'is_meta', @_ ) ); }

sub line { return( shift->_set_get_number( 'line', @_ ) ); }

sub merge
{
    my $self = shift( @_ );
    my $elem = shift( @_ ) || return( $self->error( "No element object was provided." ) );
    return( $self->error( "Object provided ($elem) is not an Text::PO::Element object" ) ) if( !$self->_is_object( $elem ) || !$elem->isa( 'Text::PO::Element' ) );
    my @k = grep( !/^po$/, keys( %$elem ) );
    foreach( @k )
    {
        $self->{ $_ } = $elem->{ $_ } if( !length( $self->{ $_ } ) );
    }
    return( $self );
}

sub msgid { return( shift->_set_get( 'msgid', @_ ) ); }

sub msgid_as_string 
{
    my $self = shift( @_ );
    return( $self->normalise( 'msgid', $self->{msgid} ) );
}

sub msgid_as_text
{
    my $self = shift( @_ );
    my $msgid = $self->_is_array( $self->{msgid} ) ? join( '', @{$self->{msgid}} ) : $self->{msgid};
    return( $msgid );
}

sub msgid_plural { return( shift->_set_get( 'msgid_plural', @_ ) ); }

sub msgid_plural_as_string 
{
    my $self = shift( @_ );
    # Important to return undef and not an empty string if there is no plural msgid
    # undef will not be added to the list, but empty string would
    return if( !CORE::length( $self->{msgid_plural} ) );
    return( $self->normalise( 'msgid_plural', $self->{msgid_plural} ) );
}

sub msgstr
{
    my $self = shift( @_ );
    if( @_ )
    {
        if( @_ == 2 )
        {
            my( $pos, $str ) = @_;
            return( $self->error( "msgstr plural offset \"$pos\" is not an integer." ) ) if( $pos !~ /^\d+$/ );
            $pos = int( $pos );
            $self->{msgstr} = [] if( ref( $self->{msgstr} ) ne 'ARRAY' );
            $self->{msgstr}->[ $pos ] = [] if( ref( $self->{msgstr}->[ $pos ] ) ne 'ARRAY' );
            push( @{$self->{msgstr}->[ $pos ]}, $str );
        }
        else
        {
            if( !ref( $_[0] ) )
            {
                chomp( @_ );
            }
            $self->{msgstr} = shift( @_ );
        }
    }
    return( $self->{msgstr} );
}

sub msgstr_as_string
{
    my $self = shift( @_ );
    my @res = ();
    if( $self->plural )
    {
        for( my $i = 0; $i < scalar( @{$self->{msgstr}} ); $i++ )
        {
            my $ref = $self->{msgstr}->[$i];
            # Is this a multiline plural localised text?
            # msgstr[0] ""
            # "some long line text"
            # "2nd line of localised text"
            if( scalar( @$ref ) > 1 )
            {
                push( @res, sprintf( 'msgstr[%d] ""', $i ) );
                push( @res, map( sprintf( '"%s"', $self->po->quote( $_ ) ), @$ref ) );
            }
            # Regular plural localised text msgstr[0] "some text"
            else
            {
                push( @res, sprintf( 'msgstr[%d] "%s"', $i, $self->po->quote( $ref->[0] ) ) ) if( length( $ref->[0] ) );
            }
        }
        return( join( "\n", @res ) );
    }
    else
    {
        return( $self->normalise( 'msgstr', $self->{msgstr} ) );
    }
}

sub msgstr_as_text
{
    my $self = shift( @_ );
    my $msgstr = $self->_is_array( $self->{msgstr} ) ? join( '', @{$self->{msgstr}} ) : $self->{msgstr};
    return( $msgstr );
}

sub normalise
{
    my $self = shift( @_ );
    my $type = shift( @_ );
    my $text = shift( @_ );
    my @res  = ();
    my $lines;
    if( ref( $text ) && scalar( @$text ) )
    {
        $lines = $self->wrap( join( '', @$text ) );
    }
    elsif( !ref( $text ) && length( $text ) )
    {
        $lines = $self->wrap( $text );
    }
    
    if( scalar( @$lines ) > 1 )
    {
        push( @res, sprintf( '%s ""', $type ) );
        push( @res, map( sprintf( '"%s"', $_ ), @$lines ) );
    }
    else
    {
        push( @res, sprintf( '%s "%s"', $type, $lines->[0] ) );
    }
    return( join( "\n", @res ) );
}

sub plural { return( shift->_set_get_boolean( 'plural', @_ ) ); }

sub po { return( shift->_set_get_object( 'po', 'Text::PO', @_ ) ); }# 

sub reference
{
    my $self = shift( @_ );
    if( @_ )
    {
        if( $self->_is_array( $_[0] ) )
        {
            # Multi references:
            # colorscheme.cpp:79 skycomponents/equator.cpp:31
            if( $self->_is_array( $_[0]->[0] ) )
            {
                $self->{file} = [];
                $self->{line} = [];
                foreach my $a ( @{$_[0]} )
                {
                    push( @{$self->{file}}, $a->[0] );
                    push( @{$self->{line}}, $a->[1] );
                }
            }
            else
            {
                @$self{ qw( file line ) } = @{$_[0]};
            }
        }
        else
        {
            @$self{ qw( file line ) } = split( /:/, shift( @_ ), 2 );
        }
    }
    return( '' ) if( !length( $self->{file} ) );
    return( '' ) if( $self->_is_array( $self->{file} ) && !scalar( @{$self->{file}} ) );
    if( $self->_is_array( $self->{file} ) )
    {
        my @temp = ();
        for( my $i = 0; $i < scalar( @{$self->{file}} ); $i++ )
        {
            push( @temp, join( ':', $self->{file}->[$i], ( $self->_is_array( $self->{line} ) ? ( $self->{line}->[$i] // '' ) : '' ) ) );
        }
        return( join( ' ', @temp ) );
    }
    else
    {
        return( join( ':', $self->{file}, ( $self->{line} // '' ) ) );
    }
}

sub wrap
{
    my $self = shift( @_ );
    my $text = shift( @_ );
    my $max = 80;
    if( length( $text ) > $max )
    {
        my $lines = [split( /\n/, $text )];
        for( my $i = 0; $i < scalar( @$lines ); $i++ )
        {
            if( length( $lines->[$i] ) > $max )
            {
                my $newLines = $self->wrap_line( $lines->[$i] );
                splice( @$lines, $i, 1, @$newLines );
                $i += scalar( @$newLines ) - 1;
            }
            else
            {
                $lines->[$i] = $self->po->quote( $lines->[$i] . "\n" );
            }
        }
        return( $lines );
    }
    else
    {
        return( [ $self->po->quote( $text ) ] );
    }
}

sub wrap_line
{
    my $self = shift( @_ );
    my $text = shift( @_ );
    return( [] ) if( !length( $text ) );
    my $new = Text::Wrap::wrap( '', '', $text );
    my $newLines = [split( /\n/, $new )];
    for( my $j = 0; $j < scalar( @$newLines ); $j++ )
    {
        $newLines->[$j] .= ' ' unless( $j == $#${newLines} );
        $newLines->[$j] = $self->po->quote( $newLines->[$j] );
    }
    #$newLines->[ $#${newLines} ] = $self->po->quote( $newLines->[ $#${newLines} ] );
    return( $newLines );
}

sub _add
{
    my $self = shift( @_ );
    my $what = shift( @_ );
    #chomp( @_ );
    $self->{ $what } = [] if( !ref( $self->{ $what } ) );
    push( @{$self->{ $what }}, @_ );
    return( $self );
}

sub _obj_eq
{
    no overloading;
    my $self = shift( @_ );
    my $other = shift( @_ );
    my $msgid = $self->_is_array( $self->{msgid} ) ? join( '', @{$self->{msgid}} ) : $self->{msgid};
    if( $self->_is_a( $other => 'Text::PO::Element' ) )
    {
        my $msgstr = $self->_is_array( $self->{msgstr} ) ? join( '', @{$self->{msgstr}} ) : $self->{msgstr};
        my $other_msgid = $self->_is_array( $other->{msgid} ) ? join( '', @{$other->{msgid}} ) : $other->{msgid};
        my $other_msgstr = $self->_is_array( $other->{msgstr} ) ? join( '', @{$other->{msgstr}} ) : $other->{msgstr};
        return( ( ( $msgid // '' ) eq ( $other_msgid // '' ) && ( $msgstr // '' ) eq ( $other_msgstr // '' ) ) ? 1 : 0 );
    }
    # Comparing an undefined value would trigger a Perl warning
    elsif( !defined( $other ) )
    {
        return( !defined( $msgid ) ? 1 : 0 );
    }
    else
    {
        return( ( $msgid // '' ) eq $other ? 1 : 0 );
    }
}

sub _set_get
{
    my $self = shift( @_ );
    my $name = shift( @_ );
    if( @_ )
    {
        if( !ref( $_[0] ) && length( $_[0] ) )
        {
            chomp( @_ );
        }
        $self->plural(1) if( $name eq 'msgid_plural' );
        return( $self->SUPER::_set_get( $name, @_ ) );
    }
    return( $self->SUPER::_set_get( $name ) );
}

sub _set_get_msg_property
{
    my $self = shift( @_ );
    my $prop = shift( @_ );
    $self->_set_get( $prop, @_ ) if( @_ );
    if( ref( $self->{ $prop } ) )
    {
        return( wantarray() ? ( @{$self->{ $prop }} ) : join( '', @{$self->{ $prop }} ) );
    }
    else
    {
        return( wantarray() ? ( $self->{ $prop } ) : $self->{ $prop } );
    }
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Text::PO::Element - PO Element

=head1 SYNOPSIS

    use Text::PO::Element;
	my $po = Text::PO::Element->new;
	$po->debug(2);
	$po->dump;

=head1 VERSION

    v0.4.2

=head1 DESCRIPTION

This is the class for PO elements.

A typical PO element might look like this:

    white-space
    #  translator-comments
    #. extracted-comments
    #: reference...
    #, flag...
    #| msgid previous-untranslated-string
    msgid untranslated-string
    msgstr translated-string

See more information fromt he L<GNU documentation|https://www.gnu.org/software/gettext/manual/html_node/PO-File-Entries.html>

=head2 CONSTRUCTOR

=head2 new

Create a new Text::PO::Element object acting as an accessor.

You can pass it an hash or hash reference of the following keys. For more information on those, see their corresponding method:

=over 4

=item * C<msgid>

=item * C<msgstr>

=item * C<msgid_plural>

=item * C<auto_comment>

=item * C<comment>

=item * C<context>

=item * C<encoding>

=item * C<file>

=item * C<flags>

=item * C<is_meta>

=item * C<line>

=item * C<fuzzy>

=item * C<plural>

=item * C<po>

=back

=head2 ATTRIBUTES

A C<Text::PO::Element> object has the following fields :

=over 4

=item * C<msgid>

The localisation id

=item * C<msgstr>

The localised string

=item * C<msgid_plural>

The optional localised string in plural

=item * C<context>

The optional context.

The context serves to disambiguate messages with the same untranslated-string. It is possible to have several entries with the same untranslated-string in a PO file, provided that they each have a different context. Note that an empty context string and an absent msgctxt line do not mean the same thing.

L<https://www.gnu.org/software/gettext/manual/html_node/Entries-with-Context.html>

=item * C<fuzzy>

The fuzzy flag set when the entry has been created but not yet translated

See also the L<GNU PO documentation|https://www.gnu.org/software/gettext/manual/html_node/PO-Files.html#index-fuzzy-flag>

=item * C<comment>

    #  translator-comments

The optional comment that can be added to provide some explanations to the translator

=item * C<auto_comment>

    #. extracted-comments

The optional comment added automatically

=item * C<flags>

    #, flag...

An optional set of flags, stored as an array reference

For example:

    #: src/msgcmp.c:338 src/po-lex.c:699
    #, c-format
    msgid "found %d fatal error"
    msgid_plural "found %d fatal errors"
    msgstr[0] "s'ha trobat %d error fatal"
    msgstr[1] "s'han trobat %d errors fatals"

Here the flag would be C<c-format>

See also the L<GNU PO documentation|https://www.gnu.org/software/gettext/manual/html_node/c_002dformat-Flag.html> and L<here|https://www.gnu.org/software/gettext/manual/html_node/PO-Files.html#index-no_002dc_002dformat-flag>, and the L<list of flags|https://www.gnu.org/software/gettext/manual/html_node/Sticky-flags.html>

Known flags are:

=over 8

=item * C<c-format> or C<no-c-format>

The C<c-format> flag indicates that the untranslated string and the translation are supposed to be C format strings. The C<no-c-format> flag indicates that they are not C format strings, even though the untranslated string happens to look like a C format string (with ‘%’ directives). 

=item * C<objc-format> or C<no-objc-format>

Likewise for L<Objective C|https://www.gnu.org/software/gettext/manual/html_node/objc_002dformat.html>

=item * C<c++-format> or C<no-c++-format>

Likewise for L<C++|https://www.gnu.org/software/gettext/manual/html_node/c_002b_002b_002dformat.html>

=item * C<python-format> or C<no-python-format>

Likewise for L<Python|https://www.gnu.org/software/gettext/manual/html_node/python_002dformat.html>

=item * C<python-brace-format> or C<no-python-brace-format>

Likewise for L<Python brace|https://www.gnu.org/software/gettext/manual/html_node/python_002dformat.html>

=item * C<java-format> or C<no-java-format>

Likewise for L<Java MessageFormat format strings|https://www.gnu.org/software/gettext/manual/html_node/java_002dformat.html>

=item * C<java-printf-format> or C<no-java-printf-format>

Likewise for L<Java printf format strings|https://www.gnu.org/software/gettext/manual/html_node/java_002dformat.html>

=item * C<csharp-format> or C<no-csharp-format>

Likewise for L<C# Format Strings|https://www.gnu.org/software/gettext/manual/html_node/csharp_002dformat.html>

=item * C<javascript-format> or C<no-javascript-format>

Likewise for L<JavaScript Format Strings|https://www.gnu.org/software/gettext/manual/html_node/javascript_002dformat.html>

=item * C<scheme-format> or C<no-scheme-format>

Likewise for L<Scheme Format Strings|https://www.gnu.org/software/gettext/manual/html_node/scheme_002dformat.html>

=item * C<lisp-format> or C<no-lisp-format>

Likewise for L<Lisp Format Strings|https://www.gnu.org/software/gettext/manual/html_node/lisp_002dformat.html>

=item * C<lisp-format> or C<no-lisp-format>

Likewise for L<Lisp Format Strings|https://www.gnu.org/software/gettext/manual/html_node/lisp_002dformat.html>

=item * C<elisp-format> or C<no-elisp-format>

Likewise for L<Emacs Lisp Format Strings|https://www.gnu.org/software/gettext/manual/html_node/elisp_002dformat.html>

=item * C<librep-format> or C<no-librep-format>

Likewise for L<librep Format Strings|https://www.gnu.org/software/gettext/manual/html_node/librep_002dformat.html>

=item * C<rust-format> or C<no-rust-format>

Likewise for L<Rust Format Strings|https://www.gnu.org/software/gettext/manual/html_node/rust_002dformat.html>

=item * C<go-format> or C<no-go-format>

Likewise for L<Go Format Strings|https://www.gnu.org/software/gettext/manual/html_node/go_002dformat.html>

=item * C<sh-format> or C<no-sh-format>

Likewise for L<Shell Format Strings|https://www.gnu.org/software/gettext/manual/html_node/sh_002dformat.html>

=item * C<sh-printf-format> or C<no-sh-printf-format>

Likewise for L<Shell Format Strings|https://www.gnu.org/software/gettext/manual/html_node/sh_002dformat.html>

=item * C<awk-format> C<no-awk-format>

Likewise for L<awk Format Strings|https://www.gnu.org/software/gettext/manual/html_node/awk_002dformat.html>

=item * C<lua-format> or C<no-lua-format>

Likewise for L<Lua Format Strings|https://www.gnu.org/software/gettext/manual/html_node/lua_002dformat.html>

=item * C<object-pascal-format> or C<no-object-pascal-format>

Likewise for L<Object Pascal Format Strings|https://www.gnu.org/software/gettext/manual/html_node/object_002dpascal_002dformat.html>

=item * C<modula2-format> or C<no-modula2-format>

Likewise for L<Modula-2 Format Strings|https://www.gnu.org/software/gettext/manual/html_node/modula2_002dformat.html>

=item * C<d-format> or C<no-d-format>

Likewise for L<D Format Strings|https://www.gnu.org/software/gettext/manual/html_node/d_002dformat.html>

=item * C<smalltalk-format> or C<no-smalltalk-format>

Likewise for L<Smalltalk Format Strings|https://www.gnu.org/software/gettext/manual/html_node/smalltalk_002dformat.html>

=item * C<qt-format> or C<no-qt-format>

Likewise for L<Qt Format Strings|https://www.gnu.org/software/gettext/manual/html_node/qt_002dformat.html>

=item * C<qt-plural-format> or C<no-qt-plural-format>

Likewise for L<Qt plural forms Format Strings|https://www.gnu.org/software/gettext/manual/html_node/qt_002dplural_002dformat.html>

=item * C<kde-format> or C<no-kde-format>

Likewise for L<KDE Format Strings|https://www.gnu.org/software/gettext/manual/html_node/kde_002dformat.html>

=item * C<boost-format> or C<no-boost-format>

Likewise for L<Boost Format Strings|https://www.gnu.org/software/gettext/manual/html_node/boost_002dformat.html>

=item * C<tcl-format> or C<no-tcl-format>

Likewise for L<Tcl Format Strings|https://www.gnu.org/software/gettext/manual/html_node/tcl_002dformat.html>

=item * C<perl-format> or C<no-perl-format>

Likewise for L<Perl Format Strings|https://www.gnu.org/software/gettext/manual/html_node/perl_002dformat.html>

=item * C<perl-brace-format> or C<no-perl-brace-format>

Likewise for L<Perl brace Format Strings|https://www.gnu.org/software/gettext/manual/html_node/perl_002dformat.html>

=item * C<php-format> or C<no-php-format>

Likewise for L<PHP Format Strings|https://www.gnu.org/software/gettext/manual/html_node/php_002dformat.html>

=item * C<gcc-internal-format> or C<no-gcc-internal-format>

Likewise for the L<GCC internal Format Strings|https://www.gnu.org/software/gettext/manual/html_node/gcc_002dinternal_002dformat.html>

=item * C<gfc-internal-format> or C<no-gfc-internal-format>

Likewise for the L<GNU Fortran Compiler internal Format Strings|https://www.gnu.org/software/gettext/manual/html_node/gfc_002dinternal_002dformat.html> in sources up to GCC 14.x. These flags are deprecated.

=item * C<ycp-format> or C<no-ycp-format>

Likewise for L<YCP Format Strings|https://www.gnu.org/software/gettext/manual/html_node/ycp_002dformat.html>

Other flags, assigned by the programmer, are:

=item * C<no-wrap>

This flag influences the presentation of the entry in the PO file. By default, when a PO file is output by a GNU gettext program and the option ‘--no-wrap’ is not specified, message lines that exceed the output page width are split into several lines. This flag inhibits this line breaking for the entry. This is useful for entries whose lines are close to 80 columns wide.

=back

=item * C<plural>

Whether this has a plural form

=item * C<encoding>

The character encoding

=item * C<file>

The file in which this l10n string was found. This is set when automatic parsing was executed

For example:

    #: lib/error.c:116
    msgid "Unknown system error"
    msgstr "Error desconegut del sistema"

This would specify a file C<lib/error.c> and a line number C<116>

=item * C<line>

The line at which this l10n was found. This is set when automatic parsing was executed

=item * C<po>

The parent C<Text::PO> object

=item * C<is_meta>

An optional boolean value provided if this element represents a meta information

=back

=head1 METHODS

=head2 add_auto_comment

Add an auto comment

=head2 add_comment

Add a comment

=head2 add_msgid

Add a msgid

=head2 add_msgid_plural

Add a plural version of a msgid

=head2 add_msgstr

Add a msgstr

=head2 add_reference

Add a reference, which is a file and line number

=head2 auto_comment

Set or return the auto_comment field

=head2 comment

Set or return the comment field

=head2 context

Set or return the context field

=head2 delete

Remove the element from the list of elements in L<Text::PO>

This only works if the element was added via L<Text::PO>, or else you need to have set yourself the L<Text::PO> object with the L</po> method.

=head2 dump

Return the element as a string formatted for a po file.

=head2 encoding

Set or get the encoding for this element. This defaults to an empty string

=head2 file

Set or get the file path where this PO element was initially be found.

=head2 flags

Set or return the flags as array reference

=head2 fuzzy

Set or  gets whether this element has the C<fuzzy> flag. Default to false.

=head2 id

Return the value of L<msgid> as a string

=head2 is_include

Sets or gets the boolean value whether this is a include directive or not. Defaults to false.

=head2 is_meta

Set or gets the flag that this element represents the meta information for this PO (a.k.a portable object) file.

Meta information for a po file is stored in a unique msgid whose value is null.

=head2 line

Set or get the line number at which this PO element was initially be found.

=head2 merge( Text::PO::Element )

Given a C<Text::PO::Element> object, it merge its content with our element object.

The merge will not overwrite existing fields.

It returns the current object

=head2 msgid

Sets or gets the C<msgid> for this element.

In list context, this return the element as an array. Thus. if this element has multiple lines, it will return an array of lines. In scalar context, it returns this element as a string, or if it is a multi line element, it will return an array reference.

=head2 msgid_plural

Sets or gets the C<msgid> version for plural. This is typically a 2-elements array. The first one singular and the second one plural.

=head2 msgid_as_string

This returns the msgid escaped and with surrounding quotes, suitable for L</dump>

=head2 msgid_as_text

This returns a simple text representation of the C<msgid>. It differs from L<msgid_as_string|/msgid_as_string> in that this is simply the string representation of the C<msgid>, but would not be suitable for a PO file.

=head2 msgid_plural_as_string

Returns the C<msgid> property as a string when it has plural implemented.

=head2 msgstr

Set or return the msgstr as a value without surrounding quote and without escaping.

=head2 msgstr_as_string

This returns the msgstr escaped and with surrounding quotes, suitable for L</dump>

=head2 msgstr_as_text

This returns a simple text representation of the C<msgstr>. It differs from L<msgstr_as_string|/msgstr_as_string> in that this is simply the string representation of the C<msgstr>, but would not be suitable for a PO file.

=head2 normalise

L</normalise> will return a string properly formatted with double quotes, multi lines if necessary, suitable for L</dump>

=head2 plural

Boolean. Sets or gets whether this element is an element with plural version of its C<msgid>

=head2 po

Sets or gets the L<Text::PO> object associated with this element. Best that you know what you are doing if you change this.

=head2 reference

    #: lib/error.c:116

Given an array reference or a string separated by ':', it sets the file and line number for this element object.

=head2 wrap

Given a text, it returns an array reference of lines wrapped

=head2 wrap_line

Given a string, it returns an array reference of lines. This is called by L</wrap>

=head1 THREAD-SAFETY

This module is thread-safe. All state is stored on a per-object basis, and the underlying file operations and data structures do not share mutable global state.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<https://www.gnu.org/software/gettext/manual/html_node/PO-Files.html>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020-2023 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated files under the same terms as Perl itself.

=cut
