##----------------------------------------------------------------------------
## PO Files Manipulation - ~/lib/Text/PO/MO.pm
## Version v0.3.0
## Copyright(c) 2023 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/06/25
## Modified 2023/12/10
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Text::PO::MO;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( Module::Generic );
    use vars qw( $VERSION @META $DEF_META );
    use Encode ();
    use IO::File;
    use Text::PO;
    our $VERSION = 'v0.3.0';
};

use strict;
use warnings;

our @META = @Text::PO::META;
our $DEF_META = $Text::PO::DEF_META;

sub init
{
    my $self = shift( @_ );
    my $file;
    $file = shift( @_ );
    $self->{auto_decode} = 1;
    $self->{default_encoding} = 'utf-8';
    $self->{domain} = undef;
    $self->{encoding}    = undef;
    $self->{file} = $file;
    $self->{use_cache} = 1;
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ );
    $self->{revision} = 0;
    $self->{magic} = '0x950412de';
    $self->{_last_modified} = '';
    return( $self );
}

sub as_object
{
    my $self = shift( @_ );
    my( $ref, $order ) = $self->read;
    return( $self->pass_error ) if( !defined( $ref ) );
    # Get the raw meta element
    my $raw  = $ref->{ '' };
    my $arr  = [split( "\\n", $raw )];
    my $po   = Text::PO->new( debug => $self->debug, encoding => $self->encoding, domain => $self->domain );
    my $meta = {};
    my $meta_keys = [];
    foreach my $s ( @$arr )
    {
        if( $s =~ /^([^\x00-\x1f\x80-\xff :=]+):[[:blank:]]*(.*?)$/ )
        {
            my( $k, $v ) = ( lc( $1 ), $2 );
            $meta->{ $k } = $v;
            push( @$meta_keys, $k );
        }
    }
    my $rv = $po->meta( $meta );
    $po->meta_keys( $meta_keys );
    my $e = $po->new_element({
        is_meta => 1,
        msgid   => '',
        msgstr  => $arr,
    });
    push( @{$po->{elements}}, $e );
    foreach my $k ( @$order )
    {
        next if( !length( $k ) );
        my $e = $po->new_element({
            msgid => $k,
            msgstr => $ref->{ $k },
        });
        push( @{$po->{elements}}, $e );
    }
    return( $po );
}

sub auto_decode { return( shift->_set_get_boolean( 'auto_decode', @_ ) ); }

sub decode
{
    my $self = shift( @_ );
    my $hash = shift( @_ );
    my $enc  = shift( @_ ) || $self->encoding;
    return( $self->error( "Data provided is not an hash reference." ) ) if( ref( $hash ) ne 'HASH' );
    return( $self->error( "No character encoding was provided to decode the mo file data." ) ) if( !CORE::length( $enc ) );
    # try-catch
    local $@;
    eval
    {
        foreach my $k ( sort( keys( %$hash ) ) )
        {
            my $v = $hash->{ $k };
            my $k2 = Encode::decode( $enc, $k, Encode::FB_CROAK );
            my $v2 = Encode::decode( $enc, $v, Encode::FB_CROAK );
            CORE::delete( $hash->{ $k } ) if( CORE::length( $k ) );
            $hash->{ $k2 } = $v2;
        }
    };
    if( $@ )
    {
        return( $self->error( "An error occurred while trying to decode mo data using character encoding \"$enc\": $@" ) );
    }
    return( $hash );
}

sub default_encoding { return( shift->_set_get_scalar( 'default_encoding', @_ ) ); }

sub domain { return( shift->_set_get_scalar( 'domain', @_ ) ); }

sub encode
{
    my $self = shift( @_ );
    my $hash = shift( @_ );
    my $enc  = shift( @_ ) || $self->encoding;
    return( $self->error( "Data provided is not an hash reference." ) ) if( ref( $hash ) ne 'HASH' );
    return( $self->error( "No character encoding was provided to encode data." ) ) if( !CORE::length( $enc ) );
    # try-catch
    local $@;
    eval
    {
        foreach my $k ( keys( %$hash ) )
        {
            my $v = $hash->{ $k };
            if( $self->_is_array( $hash->{ $k } ) )
            {
                for( my $i = 0; $i < scalar( @{$hash->{ $k }} ); $i++ )
                {
                    $hash->{ $k }->[$i] = Encode::encode( $enc, $hash->{ $k }->[$i], Encode::FB_CROAK ) if( Encode::is_utf8( $hash->{ $k }->[$i] ) );
                }
            }
            elsif( !ref( $hash->{ $k } ) )
            {
                my $v2 = Encode::is_utf8( $v ) ? Encode::encode( $enc, $v, Encode::FB_CROAK ) : $v;
                $hash->{ $k } = $v2;
            }
        }
    };
    if( $@ )
    {
        return( $self->error( "An error occurred while trying to encode data using character encoding \"$enc\": $@" ) );
    }
    return( $hash );
}

sub encoding { return( shift->_set_get_scalar( 'encoding', @_ ) ); }

sub file { return( shift->_set_get_file( 'file', @_ ) ); }

sub read
{
    my $self = shift( @_ );
    my $file = $self->file;
    my $opts = $self->_get_args_as_hash( @_ );
    # Caching mechanism
    if( !$self->{use_cache} && 
        !$opts->{no_cache} && 
        -e( $file ) && 
        ref( $self->{_cache} ) eq 'ARRAY' && 
        $self->{_last_modified} &&
        [CORE::stat( $file )]->[9] > $self->{_last_modified} )
    {
        return( wantarray() ? @{$self->{_cache}} : $self->{_cache}->[0] );
    }
    return( $self->error( "mo file \"$file\" does not exist." ) ) if( !-e( $file ) );
    return( $self->error( "mo file \"$file\" is not readable." ) ) if( !-r( $file ) );
    my $io = IO::File->new( "<$file" ) || return( $self->error( "Unable to open mo file \"$file\": $!" ) );
    $io->binmode;
    my $data;
    $io->read( $data, -s( $file ) );
    $io->close;
    my $byte_order = substr( $data, 0, 4 );
    my $tmpl;
    # Little endian
    if( $byte_order eq "\xde\x12\x04\x95" )
    {
        $tmpl = "V";
    }
    # Big endian
    elsif( $byte_order eq "\x95\x04\x12\xde" )
    {
        $tmpl = "N";
    }
    else
    {
        return( $self->error( "Provided file \"$file\" is not a valid mo file." ) );
    }
    # Check the MO format revision number
    my $rev_num = unpack( $tmpl, substr( $data, 4, 4 ) );
    # There is only one revision now: revision 0.
    return if( $rev_num > 0 );
    $self->{revision} = $rev_num;

    # Total messages
    my $total = unpack( $tmpl, substr( $data, 8, 4 ) );
    # Offset to the beginning of the original messages
    my $off_msgid = unpack( $tmpl, substr( $data, 12, 4 ) );
    # Offset to the beginning of the translated messages
    my $off_msgstr = unpack( $tmpl, substr( $data, 16, 4 ) );
    my $hash = {};
    my $order = [];
    for( my $i = 0; $i < $total; $i++ )
    {
        my( $len, $off, $msgid, $msgstr );
        # The first word is the length of the message
        $len = unpack( $tmpl, substr( $data, $off_msgid + $i * 8, 4 ) );
        # The second word is the offset of the message
        $off = unpack( $tmpl, substr( $data, $off_msgid + $i * 8 + 4, 4 ) );
        # Original message
        $msgid = substr( $data, $off, $len );
        
        # The first word is the length of the message
        $len = unpack( $tmpl, substr( $data, $off_msgstr + $i * 8, 4 ) );
        # The second word is the offset of the message
        $off = unpack( $tmpl, substr( $data, $off_msgstr + $i * 8 + 4, 4 ) );
        # Translated message
        $msgstr = substr( $data, $off, $len );
        
        $hash->{ $msgid } = $msgstr;
        push( @$order, $msgid );
    }
    
    if( $self->auto_decode || $opts->{auto_decode} )
    {
        unless( my $enc = $self->encoding )
        {
            # Find the encoding of that MO file
            if( $hash->{ '' } =~ /Content-Type:[[:blank:]\h]*text\/plain;[[:blank:]\h]*charset[[:blank:]\h]*=[[:blank:]\h]*(?<quote>["'])?(?<encoding>[\w\-]+)\g{quote}?/is )
            {
                $enc = $+{encoding};
                $self->encoding( $enc );
            }
            # Default to US-ASCII
            else
            {
                $enc = $self->default_encoding || $opts->{default_encoding};
            }
            $self->encoding( $enc );
        }
        $self->decode( $hash );
    }
    $self->{_last_modified} = [CORE::stat( $file )]->[9];
    $self->{_cache} = [ $hash, $order ];
    return( wantarray() ? ( $hash, $order ) : $hash );
}

sub reset
{
    my $self = shift( @_ );
    $self->{_cache} = [];
    $self->{_last_modified} = '';
    return( $self );
}

sub revision { return( shift->_set_get_scalar( 'revision', @_ ) ); }

sub use_cache { return( shift->_set_get_boolean( 'use_cache', @_ ) ); }

sub write
{
    my $self = shift( @_ );
    my $po   = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    return( $self->error( "I was expecting a Text::PO object, and instead got '$po'." ) ) if( !$self->_is_object( $po ) || !$po->isa( 'Text::PO' ) );
    my $ref = {};
    my $keys = [];
    $opts->{encoding} //= '';
    my $enc  = $opts->{encoding} || $self->encoding || $self->default_encoding || 'utf-8';
    my $add = sub
    {
        my $this = shift( @_ );
        $self->encode( $this => $enc ) || do
        {
            warn( "An error occurred trying to encode value for key '${this}': ", $self->error, "\n" ) if( $self->_is_warnings_enabled( 'Text::PO' ) );
        };
        my $msgstr;
        if( $this->{msgid_plural} )
        {
            my $res = [];
            my $multi = $this->{msgstr};
            for( my $i = 0; $i < scalar( @$multi ); $i++ )
            {
                push( @$res, join( null(), @{$multi->[$i]} ) );
            }
            $msgstr = join( null(), @$res );
        }
        else
        {
            $msgstr = $self->_is_array( $this->{msgstr} ) ? join( null(), @{$this->{msgstr}} ) : $this->{msgstr};
        }
        return if( !length( $msgstr ) );
        my $ctx = '';
        my $plural = '';
        if( $this->{context} )
        {
            $ctx = $this->{context} . eot();
        }
        if( $this->{msgid_plural} )
        {
            $plural = null() . $this->{msgid_plural};
        }
        $ref->{ $ctx . $this->{msgid} . $plural } = $msgstr;
        push( @$keys, $ctx . $this->{msgid} . $plural );
    };

    my $elems = $po->elements;
    my $metaKeys = [@Text::PO::META];
    my $metas = [];
    my $meta = $po->meta;
    if( scalar( @$metaKeys ) )
    {
        foreach my $k ( @$metaKeys )
        {
            my $k2 = lc( $k );
            $k2 =~ tr/-/_/;
            next if( !CORE::exists( $meta->{ $k2 } ) );
            my $v2 = $po->meta( $k );
            push( @$metas, sprintf( "\"%s: %s\\n\"\n", $po->normalise_meta( $k ), $v2 ) );
        }
        $add->({
            context => '',
            msgid => '',
            msgid_plural => '',
            msgstr => $metas,
        });
    }
    
    foreach my $e ( @$elems )
    {
        next if( $e->is_meta );
        $add->({
            context => $e->context,
            msgid   => $e->msgid,
            msgid_plural => $e->msgid_plural,
            msgstr  => $e->msgstr,
        });
    }
    
    my $cnt = scalar( keys( %$ref ) );
    my $mem = 28 + ( $cnt * 16 );
    my $l10n = [map( $ref->{ $_ }, @$keys )];

    my $fh;
    my $file = ( CORE::exists( $opts->{file} ) && length( $opts->{file} ) )
        ? $opts->{file}
        : $self->file;
    if( $file eq '-' )
    {
        $fh = IO::File->new;
        $fh->fdopen( fileno( STDOUT ), 'w' );
    }
    else
    {
        my $mode = length( $opts->{mode} ) ? $opts->{mode} : '>';
        $fh = IO::File->new( $file, $mode ) || 
            return( $self->error( "Unable to open file \"$file\" in write mode: $!" ) );
    }
    $fh->binmode;
    $fh->autoflush(1);
    $fh->print( from_hex( $self->{magic} ) );
    $fh->print( character( $self->{revision} ) );
    $fh->print( character( $cnt ) );
    $fh->print( character(28) );
    $fh->print( character( 28 + ( $cnt * 8 ) ) );
    $fh->print( character(0) );
    $fh->print( character(0) );
    foreach my $k ( @$keys )
    {
        my $len = length( $k );
        $fh->print( character( $len ) );
        $fh->print( character( $mem ) );
        $mem += $len + 1;
    }
    foreach my $v ( @$l10n )
    {
        my $len = length( $v );
        $fh->print( character( $len ) );
        $fh->print( character( $mem ) );
        $mem += $len + 1;
    }
    foreach my $k ( @$keys )
    {
        $fh->print( null_terminate( $k ) );
    }
    foreach my $v ( @$l10n )
    {
        $fh->print( null_terminate( $v ) );
    }

    $fh->close unless( CORE::exists( $opts->{file} ) && defined( $opts->{file} ) && $opts->{file} eq '-' );
    return( $self );
}

# NOTE: helper functions
# Credits to Ryan Niebur
sub character
{
	return( map{ pack( "N*", $_ ) } @_ );
}

sub eot
{
	return( chr(4) );
}

sub from_character
{
	return( character( _from_character( @_ ) ) );
}

sub from_hex
{
	return( character( _from_hex( @_ ) ) );
}

sub from_string
{
	return( join_string( from_character( _from_string( @_ ) ) ) );
}

sub join_string
{
	return( join( '', @_ ) );
}

sub null
{
	return( null_terminate( '' ) );
}

sub null_terminate
{
	return( pack( "Z*", shift( @_ ) ) );
}

sub number_to_s
{
	return( sprintf( "%d", shift( @_ ) ) );
}

sub _from_character
{
	return( map( ord( $_ ), @_ ) );
}

sub _from_hex
{
	return( map( hex( $_ ), @_ ) );
}

sub _from_string
{
	return( split( //, join( '', @_ ) ) );
}

1;
# NOTE: POD
__END__

=head1 NAME

Text::PO::MO - Machine Object File Read, Write

=head1 SYNOPSIS

    use Text::PO::MO;
	my $mo = Text::PO::MO->new( '/home/joe/locale/com.example.mo',
	{
	    auto_decode => 1,
	    encoding => 'utf-8',
	    default_encoding => 'utf-8',
	});
	my $mo = Text::PO::MO->new(
	    file => '/home/joe/locale/com.example.mo',
	    auto_decode => 1,
	    encoding => 'utf-8',
	    default_encoding => 'utf-8',
	);
	my $hash = $mo->read;

=head1 VERSION

    v0.3.0

=head1 DESCRIPTION

This is the class for read from and writing to GNU C<.mo> (machine object) files.

=head2 CONSTRUCTOR

=head2 new

Create a new Text::PO::MO object.

It accepts the following options:

=over 4

=item * C<auto_decode>

Takes a boolean value and enables or disables auto decoding of data.

=item * C<default_encoding>

Sets the default encoding. This is used when I<auto_decode> is enabled.

=item * C<encoding>

Sets the value of the encoding to use when I<auto_decode> is enabled.

=item * C<file>

Sets or gets the C<.mo> file to read.

=item * C<use_cache>

Takes a boolean value. If true, this will cache the data read by L</read>

=back

=head1 METHODS

=head2 as_object

Returns the data read from the machine object file as a L<Text::PO> object.

=head2 auto_decode

Takes a boolean value and enables or disables auto decode of data read from C<.mo> file.

This is used in L</read>

=head2 decode

Provided with an hash reference of key-value pairs and a string representing an encoding and this will decode all its keys and values.

It returns the hash reference, although being a reference, this is not necessary.

=head2 default_encoding

Sets the default encoding to revert to if no encoding is set with L</encoding> and L</auto_decode> is enabled.

Otherwise, L</read> will attempt to find out the encoding used by looking at the meta information C<Content-type>

=head2 domain

Sets or gets the po file domain, such as C<com.example.api>

=head2 encoding

Sets or gets the encoding to use for decoding the data read from the C<.mo> file.

=head2 file

Sets or gets the gnu C<.mo> file to be read from or written to.

=head2 read

Provided with a file path to a gnu C<.mo> file and this returns an hash reference of key-value pairs corresponding to the msgid to msgstr or original text to localised text.

Note that there is one blank key corresponding to the meta informations.

It takes the following optional parameters:

=over 4

=item * C<auto_decode>

Boolean value. If true, the data will be automatically decoded using either the character encoding specified with L</encoding> or the one found in the C<Content-type> field in the file meta information.

=item * C<default_encoding>

The default encoding to use if no encoding was set using L</encoding> and none could be found in the C<.mo> file meta information.

=item * C<no_cache>

Boolean value. If true, this will ignore any cached data and re-read the C<.mo> file.

=back

If caching is enabled with L</use_cache>, then L</read> will return the cache instead of actually reading the C<.mo> unless the last modification time has changed and increased.

=head2 reset

Resets the cached data. This will have the effect of reading the C<.mo> file next time L</read> is called.

Returns the current object.

=head2 revision

Sets or gets the revision number. This should not be changed, or you might break things.

It defaults to 0

=head2 use_cache

Takes a boolean value.

If true, this will enable caching based on the C<.mo> file last modification timestamp.

Default to true.

=head2 write

Provided with a L<Text::PO> object and this will write the C<.mo> file.

It takes an hash reference of parameters:

=over 4

=item * C<file>

The output file to write the data to.

This should be a file path, or C<-> if you want to write to STDOUT.

=back

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Text::PO>, L<Text::PO::Element>

L<https://www.gnu.org/software/gettext/manual/html_node/PO-Files.html>

L<http://www.gnu.org/software/gettext/manual/html_node/MO-Files.html#MO-Files>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020-2021 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated files under the same terms as Perl itself.

=cut
