##----------------------------------------------------------------------------
## PO Files Manipulation - ~/lib/Text/PO/Element.pm
## Version v0.1.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/07/23
## Modified 2021/07/23
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
    use Text::Wrap ();
    our $VERSION = 'v0.1.0';
    use open ':std' => ':utf8';
};

INIT
{
    $Text::Wrap::columns = 80;
};

sub init
{
    my $self = shift( @_ );
    $self->{msgid}          = '';
    $self->{msgstr}         = '';
    $self->{msgid_plural}   = '';
    $self->{context}        = '';
    $self->{fuzzy}          = '';
    $self->{comment}        = [];
    $self->{auto_comment}   = [];
    ## e.g.: c-format
    $self->{flags}          = [];
    ## Is it plural?
    $self->{plural}         = 0;
    ## reference
    $self->{file}           = '';
    $self->{line}           = '';
    $self->{encoding}       = '';
    ## Parent po object
    $self->{po}             = '';
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
        $self->{file} = [$self->{file}] if( length( $self->{file} ) && !ref( $self->{file} ) );
        $self->{line} = [$self->{line}] if( length( $self->{line} ) && !ref( $self->{line} ) );
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
    push( @res, '# ' . join( "\n# ", @{$self->{comment}} ) ) if( scalar( @{$self->{comment}} ) );
    push( @res, '#. ' . join( "\n#. ", @{$self->{auto_comment}} ) ) if( scalar( @{$self->{auto_comment}} ) );
    my $ref = $self->reference;
    push( @res, "#: $ref" ) if( length( $ref ) );
    my $flags = $self->flags;
    if( scalar( @$flags ) )
    {
        push( @res, sprintf( '#, %s', join( ", ", @$flags ) ) );
    }
    push( @res, sprintf( 'msgctxt: "%s"', $self->po->quote( $self->{context} ) ) ) if( length( $self->{context} ) );
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

sub msgid_plural { return( shift->_set_get( 'msgid_plural', @_ ) ); }

sub msgid_plural_as_string 
{
    my $self = shift( @_ );
    # Important to return undef and not an empty string if there is no plural msgid
    # undef will not be added to the list, but empty string would
    return if( !CORE::length( $self->{msgid_plural} ) );
    return( $self->normalise( 'msgid_plural', $self->{msgid_plural} ) );
}

# sub msgstr { return( shift->_set_get( 'msgstr', @_ ) ); }
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

sub normalise
{
    my $self = shift( @_ );
    my $type = shift( @_ );
    my $text = shift( @_ );
    $self->message( 2, "Got type '$type' with string '$text'" );
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
            ## Multi references:
            ## colorscheme.cpp:79 skycomponents/equator.cpp:31
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
    return( '' ) if( !length( $self->{file} ) || !length( $self->{line} ) );
    return( '' ) if( ref( $self->{file} ) && !scalar( @{$self->{file}} ) );
    if( ref( $self->{file} ) )
    {
        my @temp = ();
        for( my $i = 0; $i < scalar( @{$self->{file}} ); $i++ )
        {
            push( @temp, join( ':', $self->{file}->[$i], $self->{line}->[$i] ) );
        }
        return( join( ' ', @temp ) );
    }
    else
    {
        return( join( ':', @$self{ qw( file line ) } ) );
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
    # $self->message( 4, "$what property now contains: ", sub{ $self->SUPER::dump( $self->{ $what } ) } );
    return( $self );
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

# XXX POD
__END__

=encoding utf-8

=head1 NAME

Text::PO::Element - PO Element

=head1 SYNOPSIS

    use Text::PO::Element;
	my $po = Text::PO::Element->new;
	$po->debug( 2 );
	$po->dump;

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This is the class for PO elements.

=head2 CONSTRUCTOR

=head2 new

Create a new Text::PO::Element object acting as an accessor.

=head2 ATTRIBUTES

A C<Text::PO::Element> object has the following fields :

=over 4

=item I<msgid>

The localisation id

=item I<msgstr>

The localised string

=item I<msgid_plural>

The optional localised string in plural

=item I<context>

The optional context.

=item I<fuzzy>

The fuzzy flag set when the entry has been created but not yet translated

=item I<comment>

The optional comment that can be added to provide some explanations to the translator

=item I<auto_comment>

The optional comment added automatically

=item I<flags>

An optional set of flags, stored as an array reference

=item I<plural>

Whether this has a plural form

=item I<encoding>

The character encoding

=item I<file>

The file in which this l10n string was found. This is set when automatic parsing was executed

=item I<line>

The line at which this l10n was found. This is set when automatic parsing was executed

=item I<po>

The parent C<Text::PO> object

=item I<is_meta>

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

=head2 flags

Set or return the flags as array reference

=head2 id

Return the value of L<msgid> as a string

=head2 is_meta

Set or gets the flag that this element represents the meta information for this PO (a.k.a portable object) file.

Meta information for a po file is stored in a unique msgid whose value is null.

=head2 merge( Text::PO::Element )

Given a C<Text::PO::Element> object, it merge its content with our element object.

The merge will not overwrite existing fields.

It returns the current object

=head2 msgstr

Set or return the msgstr as a value without surrounding quote and without escaping.

=head2 msgid_as_string

This returns the msgid escaped and with surrounding quotes, suitable for L</dump>

=head2 msgid_plural_as_string

Returns the C<msgid> property as a string when it has plural implemented.

=head2 msgstr_as_string

This returns the msgstr escaped and with surrounding quotes, suitable for L</dump>

=head2 normalise

L</normalise> will return a string properly formatted with double quotes, multi lines if necessary, suitable for L</dump>

=head2 po

Sets or gets the L<Text::PO> object associated with this element. Best that you know what you are doing if you change this.

=head2 reference

Given an array reference or a string separated by ':', it sets the file and line number for this element object.

=head2 wrap

Given a text, it returns an array reference of lines wrapped

=head2 wrap_line

Given a string, it returns an array reference of lines. This is called by L</wrap>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<https://www.gnu.org/software/gettext/manual/html_node/PO-Files.html>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020-2021 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated files under the same terms as Perl itself.

=cut
