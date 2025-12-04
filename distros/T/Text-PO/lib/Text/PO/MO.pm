##----------------------------------------------------------------------------
## PO Files Manipulation - ~/lib/Text/PO/MO.pm
## Version v0.4.0
## Copyright(c) 2023 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/06/25
## Modified 2025/12/02
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
    warnings::register_categories( 'Text::PO' );
    use parent qw( Module::Generic );
    use vars qw( $VERSION @META $DEF_META );
    use Encode ();
    use Text::PO;
    our $VERSION = 'v0.4.0';
};

use strict;
use warnings;

our @META = @Text::PO::META;
our $DEF_META = $Text::PO::DEF_META;

sub init
{
    my $self = shift( @_ );
    $self->{auto_decode}      = 1;
    $self->{default_encoding} = 'utf-8';
    $self->{domain}           = undef;
    $self->{encoding}         = undef;
    $self->{file}             = undef;
    $self->{use_cache}        = 1;
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ );
    $self->{revision}       = 0;
    $self->{magic}          = '0x950412de';
    $self->{_last_modified} = '';
    return( $self );
}

sub as_object
{
    my $self = shift( @_ );
    # Pass through any argument we received over to read()
    my( $ref, $order ) = $self->read( ( @_ ? @_ : () ) );
    return( $self->pass_error ) if( !defined( $ref ) );
    # Get the raw meta element
    my $raw  = $ref->{ '' } // '';
    # Split on actual \n, filter non-empty
    my $arr  = [grep{ length( $_ ) } split( /\n/, $raw )];
    my $po   = Text::PO->new( debug => $self->debug, encoding => $self->encoding, domain => $self->domain );

    my $meta = {};
    my $meta_keys = [];
    foreach my $s ( @$arr )
    {
        chomp( $s );
        $s =~ s/^[[:blank:]]*"//;  # Strip leading spaces and optional "
        $s =~ s/"[[:blank:]]*$//;  # Strip trailing " and spaces
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

    # Process order to handle contexts and plurals (from previous fix—keep if you applied)
    foreach my $k ( @$order )
    {
        next if( !length( $k ) );  # Skip meta
        my $orig = $k;
        my $ctx = '';
        my $msgid_plural = '';
        if( $orig =~ /^(.*?)\x04(.*)$/s )
        {
            $ctx = $1;
            $orig = $2;
        }
        my @msgid_parts = split( /\x00/, $orig );
        my $msgid = shift( @msgid_parts );
        $msgid_plural = shift( @msgid_parts ) if( @msgid_parts );

        my $v = $ref->{ $k };
        my @msgstr_parts = split( /\x00/, $v );

        my $e = $po->new_element({
            msgid => $msgid,
        });
        $e->context( $ctx ) if( length( $ctx ) );
        if( length( $msgid_plural ) )
        {
            $e->msgid_plural( $msgid_plural );
            $e->plural(1);
            for( my $i = 0; $i < @msgstr_parts; $i++ )
            {
                $e->msgstr( $i, $msgstr_parts[$i] );
            }
        }
        else
        {
            $e->msgstr( $msgstr_parts[0] );
        }
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
    my $opts = $self->_get_args_as_hash( @_ );
    my $file = $opts->{file} || $self->file;
    # Caching mechanism
    if( !$self->{use_cache} && 
        !$opts->{no_cache} && 
        -e( $file ) && 
        ref( $self->{_cache} ) eq 'ARRAY' && 
        $self->{_last_modified} &&
        [CORE::stat( $file )]->[9] <= $self->{_last_modified} )
    {
        return( wantarray() ? @{$self->{_cache}} : $self->{_cache}->[0] );
    }
    return( $self->error( "mo file \"$file\" does not exist." ) ) if( !-e( $file ) );
    return( $self->error( "mo file \"$file\" is not readable." ) ) if( !-r( $file ) );
    my $f = $self->new_file( $file ) ||
        return( $self->error( "Unable to open mo file \"$file\": ", $self->error ) );
    my $io = $f->open( '<' ) || return( $self->pass_error( $f->error ) );
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
            if( defined( $hash->{ '' } ) &&
                $hash->{ '' } =~ /Content-Type:[[:blank:]\h]*text\/plain;[[:blank:]\h]*charset[[:blank:]\h]*=[[:blank:]\h]*(?<quote>["'])?(?<encoding>[\w\-]+)\g{quote}?/is )
            {
                $enc = $+{encoding};
                $self->encoding( $enc ) || return( $self->pass_error );
            }
            # Default to US-ASCII
            else
            {
                $enc = $self->default_encoding || $opts->{default_encoding};
            }
            $self->decode( $hash, $enc ) || return( $self->pass_error );
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

    if( !defined( $po ) )
    {
        return( $self->error( "I was expecting a Text::PO object, and got nothing." ) );
    }

    if( !$self->_is_object( $po ) || !$po->isa( 'Text::PO' ) )
    {
        return( $self->error( "I was expecting a Text::PO object, and got an object of class \"" . ref( $po ) . "\" instead." ) );
    }

    $opts->{encoding} //= '';
    my $enc = $opts->{encoding} || $self->encoding || $self->default_encoding || 'utf-8';

    # Build the hash of entries to write to the mo file.
    # Keys are msgid (possibly including context and plural markers),
    # values are msgstr (for plurals, concatenated with NUL separators).
    my %entries;
    my @keys;

    # Header / meta entry (msgid == "")
    my $meta_keys = $po->meta_keys;
    if( $meta_keys && !$meta_keys->is_empty )
    {
        my $header = '';

        foreach my $k ( @$meta_keys )
        {
            my $v = $po->meta( $k );
            next if( !defined( $v ) || !length( $v ) );
            # "Key: Value\n" – this is what gettext stores in the header string
            $header .= sprintf( "%s: %s\n", $k, $v );
        }

        if( length( $header ) )
        {
            my $h = $self->encode( { msgid => '', msgstr => $header } => $enc ) || return( $self->pass_error );

            $entries{ $h->{msgid} } = $h->{msgstr};
            # usually the empty string
            push( @keys, $h->{msgid} );
        }
    }

    # Regular entries
    my $elems = $po->elements;

    if( $elems && ref( $elems ) )
    {
        foreach my $e ( @$elems )
        {
            next if( !$e );
            # Header already handled via meta above
            next if( $e->can( 'is_meta' )    && $e->is_meta );
            # $include markers themselves should not become entries
            next if( $e->can( 'is_include' ) && $e->is_include );

            my $msgid = $e->msgid_as_text;
            next if( !defined( $msgid ) );

            my $ctx          = $e->can( 'context' ) ? ( $e->context || '' ) : '';
            my $msgid_plural = $e->msgid_plural_as_string;

            # Build the msgid key as used inside the mo file:
            #   [ctx + EOT] + msgid [+ NUL + msgid_plural]
            my $key = $msgid;
            if( defined( $msgid_plural ) && length( $msgid_plural ) )
            {
                # singular and plural msgid separated by NUL
                $key = join( null(), $msgid, $msgid_plural );
            }

            if( defined( $ctx ) && length( $ctx ) )
            {
                # context is prefixed and separated by EOT (0x04)
                $key = join( eot(), $ctx, $key );
            }

            # Build msgstr (or msgstr[0]..[n] for plural forms)
            my $val;
            if( $e->plural )
            {
                my $multi = $e->msgstr // '';
                my @parts;

                # $multi is an arrayref; each element is either a string
                # or an arrayref of continuation lines
                if( ref( $multi ) eq 'ARRAY' )
                {
                    foreach my $variant ( @$multi )
                    {
                        my $s = '';
                        if( ref( $variant ) eq 'ARRAY' )
                        {
                            # Multi-line plural - concatenate lines, no extra NUL
                            $s = join( '', @$variant );
                        }
                        else
                        {
                            $s = defined( $variant ) ? $variant : '';
                        }
                        push( @parts, $s );
                    }
                }
                # Plural forms are separated by a single NUL
                $val = join( null(), @parts );
            }
            else
            {
                my $m = $e->msgstr;
                if( ref( $m ) eq 'ARRAY' )
                {
                    # Multi-line singular - concatenate lines, no extra NUL
                    $val = join( '', @$m );
                }
                else
                {
                    $val = defined( $m ) ? $m : '';
                }
            }

            my $h = $self->encode( { msgid => $key, msgstr => $val } => $enc ) || return( $self->pass_error );
            # Later entries override earlier ones for the same msgid, like msgfmt.
            $entries{ $h->{msgid} } = $h->{msgstr};
        }

        # Deterministic order:
        # - header first (if present, already in @keys),
        # - then all other keys sorted lexicographically (like msgfmt)
        @keys = do
        {
            my %seen;
            grep{ !$seen{ $_ }++ } @keys, sort( keys( %entries ) );
        };
    }

    # Serialise to the mo format.
    my $cnt  = scalar( @keys );
    my $mem  = 28 + ( $cnt * 16 );
    my $l10n = [map( $entries{ $_ }, @keys )];

    my $file = $opts->{file} || $self->file;
    if( !defined( $file ) || !length( "$file" ) )
    {
        return( $self->error( "No file has been set to write mo data to." ) );
    }

    my $f = $self->new_file( $file ) || return( $self->pass_error );
    my $fh = $f->open( '>', { binmode => 'raw', autoflush => 1 } ) ||
        return( $self->pass_error( $f->error ) );

    # Magic (big-endian), revision, number of strings,
    # offset of original table, offset of translation table,
    # hash size and hash offset (unused).
    $fh->print(
        pack( "N", 0x950412de ),      # magic
        pack( "N", 0 ),               # revision
        pack( "N", $cnt ),            # number of strings
        pack( "N", 28 ),              # offset of original strings index
        pack( "N", 28 + $cnt * 8 ),   # offset of translated strings index
        pack( "N", 0 ),               # hash table size (unused)
        pack( "N", 0 ),               # hash table offset (unused)
    ) || return( $self->error( "Unable to write mo header to \"$f\": $!" ) );

    # Original strings index
    my $cursor = $mem;

    foreach my $k ( @keys )
    {
        my $len = length( $k );
        $fh->print( pack( "N", $len ), pack( "N", $cursor ) ) ||
            return( $self->error( "Unable to write original index for msgid \"$k\" to \"$f\": $!" ) );
        $cursor += $len + 1;          # account for terminating NUL
    }

    # Translated strings index
    foreach my $v ( @{$l10n} )
    {
        my $len = length( $v );
        $fh->print( pack( "N", $len ), pack( "N", $cursor ) ) ||
            return( $self->error( "Unable to write translated index to \"$f\": $!" ) );
        $cursor += $len + 1;          # account for terminating NUL
    }

    # Original strings
    foreach my $k ( @keys )
    {
        $fh->print( $k, "\0" ) ||
            return( $self->error( "Unable to write original string for msgid \"$k\" to \"$f\": $!" ) );
    }

    # Translated strings
    foreach my $v ( @{$l10n} )
    {
        $fh->print( $v, "\0" ) ||
            return( $self->error( "Unable to write translated string to \"$f\": $!" ) );
    }

    $fh->close;
    # We could do this, but it would return a Module::Generic::DateTime object, and we just need a simple unix timestamp.
    # $self->{_last_modified} = $f->last_modified;
    $self->{_last_modified} = [CORE::stat( "$f" )]->[9];
    $self->{_cache}         = [];
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

=encoding utf-8

=head1 NAME

Text::PO::MO - Read and write GNU gettext C<.mo> (Machine Object) files

=head1 SYNOPSIS

    use Text::PO::MO;
    my $mo = Text::PO::MO->new(
        file             => '/home/joe/locale/ja_JP/LC_MESSAGES/com.example.mo',
        auto_decode      => 1,
        encoding         => 'utf-8',
        default_encoding => 'utf-8',
    );
	my $hash = $mo->read;
	my $hash = $mo->read(
	    file             => '/home/joe/locale/ja_JP/LC_MESSAGES/com.example.api.mo',
	    no_cache         => 1,
	    auto_decode      => 1,
	    default_encoding => 'utf8',
	);

    my $po = $mo->as_object;
    # Using the same possible options as read()
    my $po = $mo->as_object(
	    file             => '/home/joe/locale/ja_JP/LC_MESSAGES/com.example.api.mo',
	    no_cache         => 1,
	    auto_decode      => 1,
	    default_encoding => 'utf8',
    );

    # Writing a .mo file from a Text::PO object
    my $po = Text::PO->new->parse( 'messages.po' );
    $mo->write( $po, {
        file     => 'messages.mo', # or, if not provided, use initial one set in the object.
        encoding => 'utf8',
    }) || die( $mo->error );

    $mo->auto_decode(1);
    $mo->default_encoding( 'utf8' );
    $mo->domain( 'com.example.api' );
    $mo->encoding( 'utf8' );
    $mo->file( '/some/where/locale/en_US/LC_MESSAGES/com.example.api.mo' );
    $mo->revision( '0.1' );
    $mo->use_cache(1);

    $mo->decode( $hash_ref );            # use previously declared encoding
    $mo->decode( $hash_ref => 'utf8' );
    $mo->encode( $hash_ref );            # use previously declared encoding
    $mo->encode( $hash_ref => 'utf8' );

    # Reset cache and last modified timestamp
    $mo->reset;

=head1 VERSION

    v0.4.0

=head1 DESCRIPTION

C<Text::PO::MO> provides an interface for reading from and writing to GNU gettext binary C<.mo> (machine object) files.

The module complements L<Text::PO> by allowing conversion between C<.po> text files and their portable binary representation used at runtime by gettext-enabled applications.

It supports:

=over 4

=item * Automatic character decoding

=item * Detection of encoding from the meta-information header

=item * Caching of decoded key/value pairs

=item * Full writing of C<.mo> files, including:

=over 4

=item * Proper synthesis of the header entry (msgid C<"">)

=item * Context keys (msgctxt)

=item * Singular and plural forms

=item * Deterministic ordering compatible with L<msgfmt(1)>

=back

=back

=head1 CONSTRUCTOR

=head2 new

    my $mo = Text::PO::MO->new( $file, %options );

Creates a new C<Text::PO::MO> object.

It accepts the following options:

=over 4

=item * C<auto_decode>

Boolean. If true, values returned by L</read> are automatically decoded according to L</encoding> or the meta-information of the file.

=item * C<default_encoding>

Encoding to fall back to when auto-decoding is enabled and no encoding could be determined from the C<Content-Type> header.

=item * C<encoding>

Explicit character encoding to use when decoding. Has priority over C<default_encoding>.

=item * C<file>

The C<.mo> file to read from or write to. May be given as a path or any C<Module::Generic::File>-compatible object.

=item * C<use_cache>

Boolean. If true (default), results of L</read> are cached and reused as long as the modification timestamp of the underlying file does not change.

=back

=head1 METHODS

=head2 as_object

    my $po = $mo->as_object;

Returns the result of L</read> as a L<Text::PO> object, allowing direct manipulation of PO elements.

=head2 auto_decode

Takes a boolean value and enables or disables auto decode of data read from C<.mo> file.

This is used in L</read>

=head2 decode

    my $ref = $mo->decode( \%hash, $encoding );

Provided with an hash reference of key-value pairs and a string representing an optional encoding and this will decode all its keys and values.

If no encoding is provided, it will use the value set with L</encoding>

It returns the same hash reference, although being a reference, this is not necessary.

=head2 default_encoding

Sets the default encoding to revert to if no encoding is set with L</encoding> and L</auto_decode> is enabled.

Otherwise, L</read> will attempt to find out the encoding used by looking at the meta information C<Content-type> inside the binary file.

=head2 domain

Sets or gets the po file domain associated with the translation catalogue, such as C<com.example.api>

=head2 encoding

Sets or gets the encoding used for decoding the data read from the C<.mo> file.

=head2 file

    my $file = $mo->file( '/some/where/locale/en_US/LC_MESSAGES/com.example.api.mo' );

Sets or gets the gnu C<.mo> file path to be read from or written to.

Returns a L<file object|Module::Generic::File>

=head2 read

    my $translations = $mo->read(
	    file             => '/home/joe/locale/ja_JP/LC_MESSAGES/com.example.api.mo',
	    no_cache         => 1,
	    auto_decode      => 1,
	    default_encoding => 'utf8',
    );

Reads the GNU C<.mo> file and returns a hash reference mapping C<msgid> strings to their translated C<msgstr> values.

The empty string key C<""> corresponds to the special header entry and its meta-information (e.g. C<Project-Id-Version>, C<Language>, C<Content-Type>, etc.).

Recognised options:

=over 4

=item * C<auto_decode>

Boolean value. If true, the data will be automatically decoded using either the character encoding specified with L</encoding> or the one found in the C<Content-type> field in the file meta information.

=item * C<default_encoding>

The default encoding to use if no encoding was set using L</encoding> and none could be found in the C<.mo> file meta information.

=item * C<file>

The C<.mo> file to read from.

If not provided, this will default to using the value set upon object instantiation or with L</file>.

=item * C<no_cache>

Boolean value. If true, this will ignore any cached data and re-read the C<.mo> file.

=back

If caching is enabled with L</use_cache>, then L</read> will return the cache content instead of actually reading the C<.mo> unless the last modification time has changed and increased.

Note that the <.mo> files store the elements in lexicographical order, and thus when reading from it, the order of the elements might not be the same as the one in the original C<.po> file.

Upon error, this sets an L<error object|Module::Generic::Exception>, and returns C<undef> in scalar context, and an empty list in list context.

=head2 reset

    $mo->reset;

Resets the cached data. This will have the effect of reading the C<.mo> file next time L</read> is called.

Returns the current object.

=head2 revision

Sets or gets the C<.mo> file format revision number. This should not be changed, or you might break things.

It defaults to C<0>

=head2 use_cache

Takes a boolean value.

If true, this will enable caching based on the C<.mo> file last modification timestamp.

Default to true.

=head2 write

    $mo->write( $po, \%options );

Writes a binary C<.mo> file from a L<Text::PO> object, adding all the elements lexicographically, as required by GNU machine object format.

Supported options are:

=over 4

=item * C<file>

The output file to write the data to.

Defaults to the object's C<file> attribute.

=back

The method:

=over 4

=item * Synthesises the header entry from C<< $po->meta >> (msgid C<"">)

=item * Supports context (msgctxt) and plural forms

=item * Concatenates plural translations using NUL separators

=item * Writes deterministic index tables as required by GNU gettext

=back

=head1 THREAD-SAFETY

This module is thread-safe. All state is stored on a per-object basis, and the underlying file operations and data structures do not share mutable global state.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Text::PO>, L<Text::PO::Element>

L<https://www.gnu.org/software/gettext/manual/html_node/PO-Files.html>

L<http://www.gnu.org/software/gettext/manual/html_node/MO-Files.html#MO-Files>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020-2025 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated files under the same terms as Perl itself.

=cut
