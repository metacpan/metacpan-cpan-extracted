##----------------------------------------------------------------------------
## PO Files Manipulation - ~/lib/Text/PO.pm
## Version v0.2.4
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2018/06/21
## Modified 2022/11/23
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Text::PO;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( Module::Generic );
    use vars qw( $VERSION @META $DEF_META );
    use open ':std' => ':utf8';
    use Class::Struct;
    use DateTime;
    use DateTime::TimeZone;
    use Encode ();
    use Fcntl qw( :DEFAULT );
    use JSON ();
    use Nice::Try;
    use Scalar::Util;
    use Text::PO::Element;
    use constant HAS_LOCAL_TZ => ( eval( qq{DateTime::TimeZone->new( name => 'local' );} ) ? 1 : 0 );
    our $VERSION = 'v0.2.4';
};

use strict;
use warnings;

struct 'Text::PO::Comment' => 
{
'text'  => '@',
};
our @META = qw(
Project-Id-Version
Report-Msgid-Bugs-To
POT-Creation-Date
PO-Revision-Date
Last-Translator
Language-Team
Language
Plural-Forms
MIME-Version
Content-Type
Content-Transfer-Encoding
);
our $DEF_META =
{
'Project-Id-Version'    => 'Project 0.1',
'Report-Msgid-Bugs-To'  => 'bugs@example.com',
# 2011-07-02 20:53+0900
'POT-Creation-Date'     => DateTime->from_epoch( 'epoch' => time(), 'time_zone' => ( HAS_LOCAL_TZ ? 'local' : 'UTC' ) )->strftime( '%Y-%m-%d %H:%M%z' ),
'PO-Revision-Date'      => DateTime->from_epoch( 'epoch' => time(), 'time_zone' => ( HAS_LOCAL_TZ ? 'local' : 'UTC' ) )->strftime( '%Y-%m-%d %H:%M%z' ),
'Last-Translator'       => 'Unknown <hello@example.com>',
'Language-Team'         => 'Unknown <hello@example.com>',
'Language'              => '',
'Plural-Forms'          => 'nplurals=1; plural=0;',
'MIME-Version'          => '1.0',
'Content-Type'          => 'text/plain; charset=utf-8',
'Content-Transfer-Encoding' => '8bit',
};

sub init
{
    my $self = shift( @_ );
    $self->{domain}     = '';
    $self->{header}     = [];
    ## utf8
    $self->{encoding}   = '';
    $self->{meta}       = {};
    $self->{meta_keys}  = [];
    ## Default to using po json file if it exists
    $self->{use_json}   = 1;
    $self->{remove_duplicates} = 1;
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ );
    $self->{elements}   = [];
    $self->{added}      = [];
    $self->{removed}    = [];
    $self->{source}     = {};
    return( $self );
}

sub add_element
{
    my $self = shift( @_ );
    my $id;
    my $opt = {};
    my $e;
    if( $self->_is_a( $_[0] => 'Text::PO::Element' ) )
    {
        $e = shift( @_ );
        $id = $e->msgid;
    }
    elsif( scalar( @_ ) == 1 && ref( $_[0] ) eq 'HASH' )
    {
        $opt = shift( @_ );
        $id = $opt->{msgid} || return( $self->error( "No msgid was provided" ) );
        $e = Text::PO::Element->new( %$opt );
    }
    elsif( !( @_ % 2 ) )
    {
        $opt = { @_ };
        $id = $opt->{msgid} || return( $self->error( "No msgid was provided" ) );
        $e = Text::PO::Element->new( %$opt );
    }
    else
    {
        $id = shift( @_ );
        $opt = { @_ } if( !( @_ % 2 ) );
        $opt->{msgid} = $id;
        $e = Text::PO::Element->new( %$opt );
    }
    return( $self->error( "No msgid was provided." ) ) if( !length( $id ) );
    my $elem = $self->elements;
    foreach my $e2 ( @$elem )
    {
        my $msgid = $e2->msgid;
        my $thisId = ref( $msgid ) ? join( '', @$msgid ) : $msgid;
        if( $thisId eq $id )
        {
            # return( $self->error( "There already is an id '$id' in the po file" ) );
            return( $e2 );
        }
    }
    $e->po( $self );
    push( @{$self->{elements}}, $e );
    return( $e );
}

sub added { return( shift->_set_get_array_as_object( 'added', @_ ) ); }

sub as_hash { return( shift->hash( @_ ) ); }

sub as_json
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $metaKeys = $self->{meta_keys};
    my $hash = {};
    $hash->{domain} = $self->domain;
    $hash->{meta} = {};
    $hash->{meta_keys} = [];
    $hash->{elements}  = [];
    foreach my $k ( @$metaKeys )
    {
        my $key = $self->normalise_meta( $k );
        my $val = $self->meta( $k );
        $hash->{meta}->{ $key } = $val;
        push( @{$hash->{meta_keys}}, $key );
    }
    my $elem = $self->elements;
    foreach my $e ( @$elem )
    {
        my $msgid = $e->msgid;
        my $msgstr = $e->msgstr;
        next if( $e->is_meta || !CORE::length( $e->msgid ) );
        my $k = ref( $msgid ) ? join( '', @$msgid ) : $msgid;
        # my $v = ref( $msgstr ) ? join( '', @$msgstr ) : $msgstr;
        my $v;
        if( $e->plural )
        {
            my $res = [];
            for( my $i = 0; $i < scalar( @$msgstr ); $i++ )
            {
                push( @$res, ref( $msgstr->[$i] ) ? join( '', @{$msgstr->[$i]} ) : $msgstr->[$i] );
            }
            $v = $res;
        }
        else
        {
            $v = ref( $msgstr ) ? join( '', @$msgstr ) : $msgstr;
        }
        
        my $ref =
        {
            msgid => $k,
            msgstr => $v,
        };
        $ref->{msgid_plural} = $e->msgid_plural if( $e->plural && $e->msgid_plural );
        if( !scalar( @{$ref->{comment} = $e->comment} ) )
        {
            delete( $ref->{comment} );
        }
        if( !length( $ref->{context} = $e->context ) )
        {
            delete( $ref->{context} );
        }
        if( !scalar( @{$ref->{flags} = $e->flags} ) )
        {
            delete( $ref->{flags} );
        }
        if( !length( $ref->{reference} = $e->reference ) )
        {
            delete( $ref->{reference} );
        }
        push( @{$hash->{elements}}, $ref );
    }
    my $j = JSON->new->relaxed->allow_blessed->convert_blessed;
    # canonical = sorting hash keys
    foreach my $t ( qw( pretty utf8 indent canonical ) )
    {
        $j->$t( $opts->{ $t } ) if( exists( $opts->{ $t } ) );
    }
    $j->canonical( $opts->{sort} ) if( exists( $opts->{sort} ) );
    try
    {
        my $json = $j->encode( $hash );
        return( $json );
    }
    catch( $e )
    {
        return( $self->error( "Unable to json encode the hash data created: $e" ) );
    }
}

sub charset
{
    my $self = shift( @_ );
    my $type = $self->content_type();
    my $def  = $self->parse_header_value( $type );
    if( @_ )
    {
        my $v = shift( @_ );
        $def->params->{charset} = $v;
        $self->meta( content_type => $def->as_string );
    }
    return( $def->params->{charset} );
}

sub content_encoding { return( shift->_set_get_meta_value( 'Content-Transfer-Encoding' ) ); }

sub content_type { return( shift->_set_get_meta_value( 'Content-Type' ) ); }

# <https://superuser.com/questions/392439/lang-and-language-environment-variable-in-debian-based-systems>
sub current_lang
{
    my $self = shift( @_ );
    return( '' ) if( !CORE::exists( $ENV{LANGUAGE} ) && !CORE::exists( $ENV{LANG} ) );
    return( ( $ENV{LANGUAGE} || $ENV{LANG} ) ? [split( /:/, ( $ENV{LANGUAGE} || $ENV{LANG} ) )]->[0] : '' );
}

sub decode
{
    my $self = shift( @_ );
    my $str  = shift( @_ );
    return( '' ) if( !length( $str ) );
    my $enc = $self->encoding;
    return( $str ) if( !$enc );
    try
    {
        return( Encode::decode_utf8( $str, Encode::FB_CROAK ) ) if( $enc eq 'utf8' );
        return( Encode::decode( $enc, $str, Encode::FB_CROAK ) );
    }
    catch( $e )
    {
        return( $self->error( "An error occurred while trying to decode a string using encoding '$enc': $e" ) );
    }
}

sub domain { return( shift->_set_get_scalar( 'domain', @_ ) ); }

sub dump
{
    my $self = shift( @_ );
    my $fh = IO::File->new;
    if( @_ )
    {
        $fh = shift( @_ );
        return( $self->error( "Filehandle provided '$fh' (", ref( $fh ), ") does not look like a filehandle" ) ) if( !Scalar::Util::openhandle( $fh ) );
        # $fh->fdopen( fileno( $fh ), 'w' );
    }
    else
    {
        $fh->fdopen( fileno( STDOUT ), 'w' );
    }
    my $enc = $self->encoding || 'utf8';
    $enc = 'utf8' if( lc( $enc ) eq 'utf-8' );
    $fh->binmode( ":${enc}" ) || return( $self->error( "Unable to set binmode on character encoding '$enc': $!" ) );
    $fh->autoflush(1);
    my $elem = $self->{elements};
    if( my $header = $self->header )
    {
        $fh->print( join( "\n", @$header ) ) || return( $self->error( "Unable to print po data to file handle: $!" ) );
    }
    my $domain = $self->domain;
    if( length( $domain ) )
    {
        $fh->print( "\n#\n# domain \"${domain}\"" ) || return( $self->error( "Unable to print po data to file handle: $!" ) );
    }
    $fh->print( "\n\n" ) || return( $self->error( "Unable to print po data to file handle: $!" ) );
    ## my $metaKeys = $self->meta_keys;
    my $metaKeys = [@META];
    if( scalar( @$metaKeys ) )
    {
        $fh->printf( "msgid \"\"\n" ) || return( $self->error( "Unable to print po data to file handle: $!" ) );
        $fh->printf( "msgstr \"\"\n" ) || return( $self->error( "Unable to print po data to file handle: $!" ) );
        foreach my $k ( @$metaKeys )
        {
            my $k2 = lc( $k );
            $k2 =~ tr/-/_/;
            if( !exists( $self->{meta}->{ $k2 } ) && 
                length( $DEF_META->{ $k } ) )
            {
                $self->{meta}->{ $k2 } = $DEF_META->{ $k };
            }
            $fh->printf( "\"%s: %s\\n\"\n", $self->normalise_meta( $k ), $self->meta( $k ) ) || return( $self->error( "Unable to print po data to file handle: $!" ) );
        }
        $fh->print( "\n" ) || return( $self->error( "Unable to print po data to file handle: $!" ) );
    }
    foreach my $e ( @$elem )
    {
        next if( $e->is_meta || !CORE::length( $e->msgid ) );
        if( $e->po ne $self )
        {
            warnings::warn( "This element '", $e->msgid, "' does not belong to us. Its po object is different than our current object.\n" ) if( warnings::enabled() );
        }
        $fh->print( $e->dump, "\n" ) || return( $self->error( "Unable to print po data to file handle: $!" ) );
        $fh->print( "\n" ) || return( $self->error( "Unable to print po data to file handle: $!" ) );
    }
    return( $self );
}

sub elements { return( shift->_set_get_array_as_object( 'elements', @_ ) ); }

sub encoding { return( shift->_set_get_scalar( 'encoding', @_ ) ); }

sub exists
{
    my $self = shift( @_ );
    my $elem = shift( @_ ) || return( $self->error( "No element to check existence was provided." ) );
    return( $self->error( "The element provided is not an Text::PO::Element object" ) ) if( !ref( $elem ) || ( ref( $elem ) && !$elem->isa( 'Text::PO::Element' ) ) );
    my $elems = $self->{elements};
    ## No need to go further if the object provided does not even have a msgid
    return(0) if( !length( $elem->msgid ) );
    foreach my $e ( @$elems )
    {
        if( $e->msgid eq $elem->msgid &&
            $e->msgstr eq $elem->msgstr )
        {
            if( length( $elem->context ) )
            {
                if( $elem->context eq $e->context )
                {
                    return(1);
                }
            }
            else
            {
                return(1);
            }
        }
    }
    return(0);
}

sub hash
{
    my $self = shift( @_ );
    my $elem = $self->elements;
    my $hash = {};
    foreach my $e ( @$elem )
    {
        my $msgid = $e->msgid;
        my $msgstr = $e->msgstr;
        my $k = ref( $msgid ) ? join( '', @$msgid ) : $msgid;
        my $v = ref( $msgstr ) ? join( '', @$msgstr ) : $msgstr;
        $hash->{ $k } = $v;
    }
    return( $self->new_hash( $hash ) );
}

sub header { return( shift->_set_get_array_as_object( 'header', @_ ) ); }

sub language { return( shift->_set_get_meta_value( 'Language' ) ); }

sub language_team { return( shift->_set_get_meta_value( 'Language-Team' ) ); }

sub last_translator { return( shift->_set_get_meta_value( 'Last-Translator' ) ); }

sub merge
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{merge} = 1;
    return( $self->sync( $opts ) );
}

sub meta
{
    my $self = shift( @_ );
    if( @_ )
    {
        if( $self->_is_hash( $_[0] ) )
        {
            $self->{meta} = shift( @_ );
        }
        elsif( scalar( @_ ) == 1 )
        {
            my $k = shift( @_ );
            $k =~ tr/-/_/;
            return( $self->{meta}->{ lc( $k ) } );
        }
        elsif( !( @_ % 2 ) )
        {
            my $this = { @_ };
            foreach my $k ( keys( %$this ) )
            {
                my $k2 = $k;
                $k2 =~ tr/-/_/;
                $self->{meta}->{ lc( $k2 ) } = $this->{ $k };
            }
        }
        else
        {
            return( $self->error( "Unknown data provided: '", join( "', '", @_ ), "'." ) );
        }
        
        foreach my $k ( keys( %{$self->{meta}} ) )
        {
            if( CORE::index( $k, '-' ) != -1 )
            {
                my $k2 = $k;
                $k2 =~ tr/-/_/;
                $self->{meta}->{ $k2 } = CORE::delete( $self->{meta}->{ $k } );
            }
        }
    }
    return( $self->_set_get_hash_as_mix_object( 'meta' ) );
}

sub meta_keys
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $ref = shift( @_ );
        return( $self->error( "Value provided is not an array reference." ) ) if( !$self->_is_array( $ref ) );
        my $copy = [@$ref];
        for( @$copy )
        {
            tr/-/_/;
            $_ = lc( $_ );
        }
        $self->{meta_keys} = $copy;
    }
    my $data = $self->{meta_keys};
    $data = [sort( keys( %{$self->{meta}} ) )] if( !scalar( @$data ) );
    my $new = [];
    for( @$data )
    {
        push( @$new, $self->normalise_meta( $_ ) );
    }
    return( $self->new_array( $new ) );
}

sub mime_version { return( shift->_set_get_meta_value( 'MIME-Version' ) ); }

sub new_element
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{po} = $self;
    my $e = Text::PO::Element->new( $opts );
    $e->encoding( $self->encoding ) if( !$opts->{encoding} && $self->encoding );
    $e->debug( $self->debug );
    return( $e );
}

sub normalise_meta
{
    my $self = shift( @_ );
    my $str  = shift( @_ ) || return( '' );
    $str =~ tr/_/-/;
    my @res = grep( /^$str$/i, @META );
    if( scalar( @res ) )
    {
        return( $res[0] );
    }
    return( '' );
}

sub parse
{
    my $self = shift( @_ );
    my $this = shift( @_ ) || return( $self->error( "No file or glob was provided to parse po file." ) );
    my $io;
    my $fh_was_open = 0;
    if( Scalar::Util::reftype( $this ) eq 'GLOB' )
    {
        $io = $this;
        return( $self->error( "Filehandle provided '$io' is not opened" ) ) if( !Scalar::Util::openhandle( $io ) );
        $fh_was_open++;
        $self->source({ handle => $this });
    }
    else
    {
        $io = IO::File->new( "<$this" ) || return( $self->error( "Unable to open po file \"$this\" in read mode: $!" ) );
        ## By default
        $self->source({ file => $this });
    }
    $io->binmode( ':utf8' );
    my $elem = [];
    $self->{elements} = $elem;
    my $header = '';
    my $ignoring_leading_blanks = 1;
    my $n = 0;
    # Ignore / remove possible leading blank lines
    while( defined( $_ = $io->getline ) )
    {
        $n++;
        if( /^\S+/ )
        {
            $ignoring_leading_blanks = 0;
        }
        elsif( $ignoring_leading_blanks && /^[[:blank:]\h]*$/ )
        {
            next;
        }
        #( 1 .. /^[^\#]+$/ ) or last;
        /^\#+/ || last;
        if( /^\#+[[:blank:]\h]*domain[[:blank:]]+\"([^\"]+)\"/ )
        {
            $self->domain( $1 );
            $self->message_colour( 3, "Setting domain to <green>$1</>" );
        }
        else
        {
            $header .= $_;
        }
    }
    ## Make sure to position ourself after the initial blank line if any, since blank lines are used as separators
    ## Actually, no we don't care. Blocks are: maybe some comments, msgid then msgstr. That's how we delimit them
    ## $_ = $io->getline while( /^[[:blank:]]*$/ && defined( $_ ) );
    $self->header( [ split( /\n/, $header ) ] ) if( length( $header ) );
    my $e = Text::PO::Element->new( po => $self );
    $e->debug( $self->debug );
    ## What was the last seen element?
    ## This is used for multi line buffer, so we know where to add it
    my $lastSeen = '';
    my $foundFirstLine = 0;
    ## To keep track of the msgid found so we can skip duplicates
    my $seen = {};
    while( defined( $_ = $io->getline ) )
    {
        $n++;
        chomp( $_ );
        if( !$foundFirstLine && /^\S/ )
        {
            $foundFirstLine++;
        }
        if( /^[[:blank:]]*$/ )
        {
            if( $foundFirstLine )
            {
                ## Case where msgid and msgstr are separated by a blank line
                if( scalar( @$elem ) > 1 &&
                    !length( $e->msgid ) && 
                    length( $e->msgstr ) &&
                    length( $elem->[-1]->msgid ) &&
                    !length( $elem->[-1]->msgstr ) )
                {
                    $elem->[-1]->merge( $e );
                }
                else
                {
                    if( ++$seen->{ $e->id } > 1 )
                    {
                        next;
                    }
                    push( @$elem, $e );
                }
                $e = Text::PO::Element->new( po => $self );
                $e->{_po_line} = $n;
                $e->encoding( $self->encoding ) if( $self->encoding );
                $e->debug( $self->debug );
            }
            ## special treatment for first item that contains the meta information
            if( scalar( @$elem ) == 1 )
            {
                my $this = $elem->[0];
                my $def = $this->msgstr;
                $def = [split( /\n/, join( '', @$def ) )];
                
                my $meta = {};
                foreach my $s ( @$def )
                {
                    chomp( $s );
                    if( $s =~ /^([^\x00-\x1f\x80-\xff :=]+):[[:blank:]]*(.*?)$/ )
                    {
                        my( $k, $v ) = ( lc( $1 ), $2 );
                        $meta->{ $k } = $v;
                        push( @{$self->{meta_keys}}, $k );
                        if( $k eq 'content-type' )
                        {
                            if( $v =~ /\bcharset=\s*([-\w]+)/i )
                            {
                                # my $enc = lc( $1 );
                                my $enc = $1;
                                ## See PerlIO::encoding man page
                                $enc = 'utf8' if( lc( $enc ) eq 'utf-8' );
                                $self->encoding( $enc );
                                try
                                {
                                    $io->binmode( $enc eq 'utf8' ? ":$enc" : ":encoding($enc)" );
                                }
                                catch( $e )
                                {
                                    return( $self->error( "Unable to set binmode to charset \"$enc\": $e" ) );
                                }
                            }
                        }
                    }
                }
                if( scalar( keys( %$meta ) ) )
                {
                    $self->meta( $meta );
                    $this->is_meta( 1 );
                }
            }
        }
        ## #. TRANSLATORS: A test phrase with all letters of the English alphabet.
        ## #. Replace it with a sample text in your language, such that it is
        ## #. representative of language's writing system.
        elsif( /^\#\.[[:blank:]]*(.*?)$/ )
        {
            my $c = $1;
            $e->add_auto_comment( $c );
        }
        ## #: finddialog.cpp:38
        ## #: colorscheme.cpp:79 skycomponents/equator.cpp:31
        elsif( /^\#\:[[:blank:]]+(.*?)$/ )
        {
            my $c = $1;
            $e->reference( $c );
        }
        ## #, c-format
        elsif( /^\#\,[[:blank:]]+(.*?)$/ )
        {
            my $c = $1;
            $e->flags( [ split( /[[:blank:]]*,[[:blank:]]*/, $c ) ] ) if( $c );
        }
        elsif( /^\#+[[:blank:]]+(.*?)$/ )
        {
            my $c = $1;
            if( !$self->meta->length && $c =~ /^domain[[:blank:]\h]+\"(.*?)\"/ )
            {
                $self->domain( $1 );
            }
            else
            {
                $e->add_comment( $c);
            }
        }
        elsif( /^msgid[[:blank:]]+"(.*?)"$/ )
        {
            $e->msgid( $self->unquote( $1 ) ) if( length( $1 ) );
            $lastSeen = 'msgid';
        }
        ## #: mainwindow.cpp:127
        ## #, kde-format
        ## msgid "Time: %1 second"
        ## msgid_plural "Time: %1 seconds"
        ## msgstr[0] "Tiempo: %1 segundo"
        ## msgstr[1] "Tiempo: %1 segundos"
        elsif( /^msgid_plural[[:blank:]]+"(.*?)"[[:blank:]]*$/ )
        {
            $e->msgid_plural( $self->unquote( $1 ) ) if( length( $1 ) );
            $e->plural(1);
            $lastSeen = 'msgid_plural';
        }
        ## disambiguating context:
        ## #: tools/observinglist.cpp:700
        ## msgctxt "First letter in 'Scope'"
        ## msgid "S"
        ## msgstr ""
        ## 
        ## #: skycomponents/horizoncomponent.cpp:429
        ## msgctxt "South"
        ## msgid "S"
        ## msgstr ""
        elsif( /^msgctxt[[:blank:]]+"(.*?)"[[:blank:]]*$/ )
        {
            $e->context( $self->unquote( $1 ) ) if( length( $1 ) );
            $lastSeen = 'msgctxt';
        }
        elsif( /^msgstr[[:blank:]]+"(.*?)"[[:blank:]]*$/ )
        {
            $e->msgstr( $self->unquote( $1 ) ) if( length( $1 ) );
            $lastSeen = 'msgstr';
        }
        elsif( /^msgstr\[(\d+)\][[:blank:]]+"(.*?)"[[:blank:]]*$/ )
        {
            if( length( $2 ) )
            {
                $e->msgstr( $1, $self->unquote( $2 ) );
                $e->plural(1);
            }
            $lastSeen = 'msgstr';
        }
        elsif( /^[[:blank:]]*"(.*?)"[[:blank:]]*$/ )
        {
            my $sub = "add_${lastSeen}";
            if( $e->can( $sub ) )
            {
                $e->$sub( $self->unquote( $1 ) ) if( length( $1 ) );
            }
            else
            {
                warn( "Unable to find method \"${sub}\" in class \"", ref( $e ), "\" for line parsed \"$_\"\n" );
            }
        }
        else
        {
            warnings::warn( "I do not understand the line \"$_\" at line $n\n" ) if( warnings::enabled() );
        }
    }
    $io->close unless( $fh_was_open );
    push( @$elem, $e ) if( $elem->[-1] ne $e && CORE::length( $e->msgid ) && ++$seen->{ $e->msgid } < 2 );
    shift( @$elem ) if( scalar( @$elem ) && $elem->[0]->is_meta );
    return( $self );
}

sub parse_date_to_object
{
    my $self = shift( @_ );
    my $str  = shift( @_ );
    my $d = $self->_parse_timestamp( $str ) || 
        return( $self->error( "Date time string provided is unsupported: \"${str}\"." ) );
    my $strp = $d->formatter;
    unless( $strp )
    {
        $strp = DateTime::Format::Strptime->new(
            pattern   => '%Y-%m-%d %H:%M%z',
            locale    => 'en_GB',
            time_zone => $d->time_zone,
        );
        $d->set_formatter( $strp );
    }
    return( $d );
}

sub parse_header_value
{
    my $self = shift( @_ );
    my $s    = shift( @_ );
    return( $self->error( 'Argument string is required' ) ) if( !defined( $s ) || !length( $s ) );
    my $sep  = @_ ? shift( @_ ) : ';';
    my @parts = ();
    my $i = 0;
    foreach( split( /(\\.)|$sep/, $s ) ) 
    {
        defined( $_ ) ? do{ $parts[$i] .= $_ } : do{ $i++ };
    }
    my $header_val = shift( @parts );
    my $obj = Text::PO::HeaderValue->new( $header_val );
    
    my $param = {};
    foreach my $frag ( @parts )
    {
        $frag =~ s/^[[:blank:]]+|[[:blank:]]+$//g;
        my( $attribute, $value ) = split( /[[:blank:]]*\=[[:blank:]]*/, $frag, 2 );
        $value =~ s/^\"|\"$//g;
        ## Check character string and length. Should not be more than 255 characters
        ## http://tools.ietf.org/html/rfc1341
        ## http://www.iana.org/assignments/media-types/media-types.xhtml
        ## Won't complain if this does not meet our requirement, but will discard it silently
        if( $attribute =~ /^[a-zA-Z][a-zA-Z0-9\_\-]+$/ && CORE::length( $attribute ) <= 255 )
        {
            if( $value =~ /^[a-zA-Z][a-zA-Z0-9\_\-]+$/ && CORE::length( $value ) <= 255 )
            {
                $obj->param( lc( $attribute ) => $value );
            }
        }
    }
    return( $obj );
}

sub parse2hash
{
    my $self = shift( @_ );
    my $this = shift( @_ ) || return( $self->error( "No file or glob was provided to parse po file." ) );
    my $buff = '';
    if( $self->{use_json} && ( -e( "${this}.json" ) || $this =~ /\.json$/ ) )
    {
        my $file =  -e( "${this}.json" ) ? "${this}.json" : $this;
        my $io = IO::File->new( "$file" ) || return( $self->error( "Unable to open json po file \"${file}\" in read mode: $!" ) );
        $io->binmode( ':utf8' );
        $io->read( $buff, -s( $file ) );
        $io->close;
        my $j = JSON->new->relaxed;
        my $ref = {};
        try
        {
            $ref = $j->decode( $buff );
        }
        catch( $e )
        {
            return( $self->error( "An error occurred while json decoding data from \"${file}\": $e" ) );
        }
        my $hash = {};
        foreach my $elem ( @{$ref->{elements}} )
        {
            $hash->{ $elem->{msgid} } = $elem->{msgstr};
        }
        return( $self->new_hash( $hash ) );
    }
    else
    {
        $self->parse( $this ) || return( $self->pass_error );
        return( $self->hash );
    }
}

sub parse2object
{
    my $self = shift( @_ );
    my $this = shift( @_ ) || return( $self->error( "No file or glob was provided to parse po file." ) );
    my $buff = '';
    if( $self->{use_json} && ( -e( "${this}.json" ) || $this =~ /\.json$/ ) )
    {
        my $file =  -e( "${this}.json" ) ? "${this}.json" : $this;
        my $io = IO::File->new( $file ) || return( $self->error( "Unable to open json po file \"${file}\" in read mode: $!" ) );
        $io->binmode( ':utf8' );
        $io->read( $buff, -s( $file ) );
        $io->close;
        my $j = JSON->new->relaxed;
        my $ref = {};
        try
        {
            $ref = $j->decode( $buff );
        }
        catch( $e )
        {
            return( $self->error( "An error occurred while json decoding data from \"${file}\": $e" ) );
        }
        
        $self->domain( $ref->{domain} ) if( length( $ref->{domain} ) && !length( $self->domain ) );
        my $meta_keys = [];
        if( $ref->{meta_keys} )
        {
            $meta_keys = $ref->{meta_keys};
        }
        elsif( $ref->{meta} )
        {
            $meta_keys = [sort( keys( %{$ref->{meta}} ) )];
        }
        
        if( $ref->{meta} )
        {
            $self->{meta} = {};
            foreach my $k ( keys( %{$ref->{meta}} ) )
            {
                my $k2 = lc( $k );
                $k2 =~ tr/-/_/;
                $self->{meta}->{ $k2 } = $ref->{meta}->{ $k };
            }
        }
        $self->{meta_keys} = $meta_keys;
        
        if( scalar( @$meta_keys ) )
        {
            my $e = Text::PO::Element->new( 'po' => $self );
            $e->debug( $self->debug );
            $e->msgid( '' );
            $e->msgstr(
                [map( sprintf( '%s: %s', $_, $ref->{meta}->{ $_ } ), @$meta_keys )]
            );
            $e->is_meta(1);
            push( @{$self->{elements}}, $e );
        }
        
        foreach my $def ( @{$ref->{elements}} )
        {
            my $e = Text::PO::Element->new( 'po' => $self );
            $e->debug( $self->debug );
            $e->msgid( $def->{msgid} );
            if( $def->{msgid_plural} )
            {
                $e->msgid_plural( $def->{msgid_plural} );
            }
            if( ref( $def->{msgstr} ) eq 'ARRAY' )
            {
                for( my $i = 0; $i < scalar( @{$def->{msgstr}} ); $i++ )
                {
                    $e->msgstr( $i => $def->{msgstr}->[$i] );
                }
            }
            else
            {
                $e->msgstr( $def->{msgstr} );
            }
            $e->comment( $def->{comment} ) if( $def->{comment} );
            $e->context( $def->{context} ) if( $def->{context} );
            $e->flags( $def->{flags} ) if( $def->{flags} );
            $e->reference( $def->{reference} ) if( $def->{reference} );
            $e->encoding( $self->encoding ) if( $self->encoding );
            push( @{$self->{elements}}, $e );
        }
        return( $self );
    }
    else
    {
        return( $self->parse( $this ) );
    }
}

sub plural
{
    my $self = shift( @_ );
    if( @_ )
    {
        my( $nplurals, $expr ) = @_;
        $self->{plural} = [ $nplurals, $expr ];
        return( [ @{$self->{plural}} ] );
    }
    else
    {
        return( [@{$self->{plural}}] ) if( $self->{plural} && scalar( @{$self->{plural}} ) );
        my $meta = $self->meta;
        my $pluralDef = $self->meta( 'Plural-Forms' );
        if( $pluralDef )
        {
            if( $pluralDef =~ /^[[:blank:]\h]*nplurals[[:blank:]\h]*=[[:blank:]\h]*(\d+)[[:blank:]\h]*\;[[:blank:]\h]*plural[[:blank:]\h]*=[[:blank:]\h]*(.*?)\;?$/i )
            {
                $self->{plural} = [ $1, $2 ];
                return( $self->{plural} );
            }
            else
            {
                return( $self->error( "Malformed plural definition found in po data in meta field \"Plural-Forms\": " . $pluralDef ) );
            }
        }
        return( [] );
    }
}

sub plural_forms { return( shift->_set_get_meta_value( 'Plural-Forms', @_ ) ); }

sub po_revision_date { return( shift->_set_get_meta_date( 'PO-Revision-Date', @_ ) ); }

sub pot_creation_date { return( shift->_set_get_meta_date( 'POT-Creation-Date', @_ ) ); }

sub project_id_version { return( shift->_set_get_meta_value( 'Project-Id-Version', @_ ) ); }

sub report_bugs_to { return( shift->_set_get_meta_value( 'Report-Msgid-Bugs-To', @_ ) ); }

sub quote 
{
    my $self = shift( @_ );
    my $str  = shift( @_ );
    return( '' ) if( !length( $str ) );
    ## \t is a tab
    $str =~ s/(?<!\\)\\(?!t)/\\\\/g;
    $str =~ s/(?<!\\)"/\\"/g;
    $str =~ s/(?<!\\)\n/\\n/g;
    return( sprintf( '%s', $str ) );
}

sub remove_duplicates { return( shift->_set_get_boolean( 'remove_duplicates', @_ ) ); }

sub remove_element
{
    my $self = shift( @_ );
    my $elem = shift( @_ );
    my $rv = $self->exists( $elem );
    return if( !defined( $rv ) );
    return(0) if( !$rv );
    my $elems = $self->elements;
    my $found = 0;
    for( my $i = 0; $i < scalar( @$elems ); $i++ )
    {
        if( $elems->[$i] eq $elem )
        {
            splice( @$elems, $i, 1 );
            $i--;
            $found++;
        }
    }
    return( $found );
}

sub removed { return( shift->_set_get_array_as_object( 'removed', @_ ) ); }

sub source { return( shift->_set_get_hash_as_object( 'source', @_ ) ); }

sub sync
{
    my $self = shift( @_ );
    ## a filehandle, or a filename?
    ## my $this = shift( @_ ) || return( $self->error( "No file or filehandle provided." ) );
    my $this;
    $this = shift( @_ ) if( scalar( @_ ) && ( ( @_ % 2 ) || ( !( @_ % 2 ) && ref( $_[1] ) eq 'HASH' ) ) );
    my $opts = $self->_get_args_as_hash( @_ );
    $this = ( $opts->{handle} || $opts->{file} ) if( !CORE::length( $this ) );
    if( !$this )
    {
        my $fh;
        if( $fh = $self->source->handle )
        {
            $this = $fh if( $self->_can_write_fh( $fh ) );
        }
        elsif( my $file = $self->source->file )
        {
            $this = $file if( -e( $file ) && -w( $file ) );
            $fh = IO::File->new( ">$file" ) || return( $self->error( "Unable to open file \"$file\" in write mode: $!" ) );
        }
        return( $self->error( "No writable file handle or file set to sync our data against." ) ) if( !$this );
        $fh->binmode( ':utf8' );
        $self->dump( $fh ) || return( $self->pass_error );
        $fh->close;
        return( $self );
    }
    
    if( Scalar::Util::reftype( $this ) eq 'GLOB' )
    {
        return( $self->error( "Filehandle provided is not opened" ) ) if( !Scalar::Util::openhandle( $this ) );
        return( $self->error( "Filehandle provided is not writable" ) ) if( !$self->_can_write_fh( $this ) );
        return( $self->sync_fh( $this, $opts ) );
    }
    elsif( -l( $this ) )
    {
        return( $self->error( "File provided is actually a symbolic link. Do not want to write to a symbolic link." ) );
    }
    elsif( -e( $this ) )
    {
        if( !-f( $this ) )
        {
            return( $self->error( "File '$this' is not a file." ) );
        }
        my $fh = IO::File->new( "+<$this" ) || return( $self->error( "Unable to open file '$this' in read/write mode: $!" ) );
        my $po = $self->sync_fh( $fh, $opts );
        $fh->close;
        return( $po );
    }
    # Does not exist yet
    else
    {
        my $fh = IO::File->new( ">$this" ) || return( $self->error( "Unable to write to file '$this': $!" ) );
        $self->dump( $fh ) || return( $self->pass_error );
        $fh->close;
    }
    return( $self );
}

sub sync_fh
{
    my $self = shift( @_ );
    my $fh   = shift( @_ );
    return( $self->error( "Filehandle provided $fh is not a valid file handle" ) ) if( !Scalar::Util::openhandle( $fh ) );
    my $opts = $self->_get_args_as_hash( @_ );
    # Parse file
    my $po = $self->new;
    $po->debug( $self->debug );
    $po->parse( $fh );
    # Remove the ones that do not exist
    my $elems = $po->elements;
    my @removed = ();
    for( my $i = 0; $i < scalar( @$elems ); $i++ )
    {
        my $e = $elems->[$i];
        if( !$self->exists( $e ) )
        {
            my $removedObj = splice( @$elems, $i, 1 );
            push( @removed, $removedObj ) if( $removedObj );
        }
    }
    # Now check each one of ours against this parsed file and add our items if missing
    $elems = $self->elements;
    my @added = ();
    foreach my $e ( @$elems )
    {
        if( !$po->exists( $e ) )
        {
            $po->add_element( $e );
            push( @added, $e );
        }
    }
    # Now, rewind and rewrite the file
    $fh->seek(0,0) || return( $self->error( "Unable to seek file handle!: $!" ) );
    # $fh->print( $po->dump );
    $po->dump( $fh ) || return( $self->pass_error );
    $fh->truncate( $fh->tell );
    $po->added( \@added );
    $po->removed( \@removed );
    return( $po );
}

sub unquote 
{
    my $self = shift( @_ );
    my $str  = shift( @_ );
    return( '' ) if( !length( $str ) );
    $str =~ s/^"(.*)"/$1/;
    $str =~ s/\\"/"/g;
    ## newline
    $str =~ s/(?<!(\\))\\n/\n/g;
    ## inline newline
    $str =~ s/(?<!(\\))\\{2}n/\\n/g;
    ## \ followed by newline
    $str =~ s/(?<!(\\))\\{3}n/\\\n/g;
    ## \ followed by inline newline
    $str =~ s/\\{4}n/\\\\n/g;
    ## all slashes not related to a newline
    $str =~ s/\\\\(?!n)/\\/g;
    return( $str );
}

sub use_json { return( shift->_set_get_boolean( 'use_json', @_ ) ); }

## https://stackoverflow.com/questions/3807231/how-can-i-test-if-i-can-write-to-a-filehandle
## -> https://stackoverflow.com/a/3807381/4814971
sub _can_write_fh
{
    my $self = shift( @_ );
    my $fh = shift( @_ );
    my $flags = fcntl( $fh, F_GETFL, 0 );
    if( ( $flags & O_ACCMODE ) & ( O_WRONLY|O_RDWR ) )
    {
        return(1);
    }
    return(0);
}

sub _set_get_meta_date
{
    my $self = shift( @_ );
    my $field = shift( @_ ) || return( $self->error( "No field was provided to get its DateTime object equivalent." ) );
    if( @_ )
    {
        my $v = shift( @_ );
        if( ref( $v ) && $self->_is_a( $v => 'DateTime' ) )
        {
            my $strp = DateTime::Format::Strptime->new(
                pattern => '%F %H:%M%z',
                locale  => 'en_GB',
                time_zone => ( HAS_LOCAL_TZ ? 'local' : 'UTC' ),
            );
            $v->set_formatter( $strp );
        }
        $self->meta( $field => $v );
        return( $v );
    }
    else
    {
        my $meta = $self->meta( $field );
        if( !defined( $meta ) || !length( $meta ) )
        {
            return;
        }
        return( $self->parse_date_to_object( $meta ) );
    }
}

sub _set_get_meta_value
{
    my $self = shift( @_ );
    my $field = shift( @_ ) || return( $self->error( "No field was provided to get its DateTime object equivalent." ) );
    if( @_ )
    {
        my $v = shift( @_ );
        $self->meta( $field => $v );
    }
    return( $self->meta( $field ) );
}

# NOTE: Text::PO::HeaderValue class
{
    package
        Text::PO::HeaderValue;
    BEGIN
    {
        use strict;
        use warnings;
        use parent qw( Module::Generic );
        use vars qw( $VERSION $QUOTE_REGEXP $TYPE_REGEXP $TOKEN_REGEXP $TEXT_REGEXP );
        our $VERSION = 'v0.1.0';
        use overload (
            '""' => 'as_string',
            fallback => 1,
        );
        our $QUOTE_REGEXP = qr/([\\"])/;
        #
        # RegExp to match type in RFC 7231 sec 3.1.1.1
        #
        # media-type = type "/" subtype
        # type       = token
        # subtype    = token
        #
        our $TYPE_REGEXP  = qr/^[!#$%&'*+.^_`|~0-9A-Za-z-]+\/[!#$%&'*+.^_`|~0-9A-Za-z-]+$/;
        our $TOKEN_REGEXP = qr/^[!#$%&'*+.^_`|~0-9A-Za-z-]+$/;
        our $TEXT_REGEXP  = qr/^[\u000b\u0020-\u007e\u0080-\u00ff]+$/;
    };
    
    sub init
    {
        my $self = shift( @_ );
        my $value = shift( @_ );
        return( $self->error( "No value provided." ) ) if( !length( $value ) );
        $self->{original} = '';
        $self->{value} = $value;
        $self->SUPER::init( @_ );
        $self->{params} = {};
        return( $self );
    }
    
    sub as_string
    {
        my $self = shift( @_ );
        if( !defined( $self->{original} ) || !length( $self->{original} ) )
        {
            my $string = '';
            if( defined( $self->{value} ) && length( $self->{value} ) )
            {
                if( $self->{value} !~ /^$TYPE_REGEXP$/ )
                {
                    return( $self->error( "Invalid value \"$self->{value}\"" ) );
                }
                $string = $self->{value};
            }

            # Append parameters
            if( $self->{params} && ref( $self->{params} ) eq 'HASH' )
            {
                my $params = [ sort( keys( %{$self->{params}} ) ) ];
                for( my $i = 0; $i < scalar( @$params ); $i++ )
                {
                    if( $params->[$i] !~ /^$TOKEN_REGEXP$/ )
                    {
                        return( $self->error( "Invalid parameter name: \"" . $params->[$i] . "\"" ) );
                    }
                    if( length( $string ) > 0 )
                    {
                        $string .= '; ';
                    }
                    $string .= $params->[$i] . '=' . $self->qstring( $self->{params}->{ $params->[$i] } );
                }
            }
            $self->{original} = $string;
        }
        return( $self->{original} );
    }
    
    sub original { return( shift->_set_get_scalar_as_object( 'original', @_ ) ); }
    
    sub param
    {
        my $self = shift( @_ );
        my $name = shift( @_ ) || return( $self->error( "No parameter name was provided." ) );
        if( @_ )
        {
            my $v = shift( @_ );
            $self->{params}->{ $name } = $v;
        }
        return( $self->{params}->{ $name } );
    }
    
    sub qstring
    {
        my $self = shift( @_ );
        my $str  = shift( @_ );

        # no need to quote tokens
        if( $str =~ /^$TOKEN_REGEXP$/ )
        {
            return( $str );
        }

        if( length( $str ) > 0 && $str !~ /^$TEXT_REGEXP$/ )
        {
            return( $self->error( 'Invalid parameter value' ) );
        }
        
        $str =~ s/$QUOTE_REGEXP/\\$1/g;
        return( '"' . $str . '"' );
    }
    
    sub value { return( shift->_set_get_scalar_as_object( 'value', @_ ) ); }
}

1;
# NOTE: POD
__END__

=head1 NAME

Text::PO - Read and write PO files

=head1 SYNOPSIS

    use Text::PO;
    my $po = Text::PO->new;
    $po->debug( 2 );
    $po->parse( $poFile ) || die( $po->error, "\n" );
    my $hash = $po->as_hash;
    my $json = $po->as_json;
    # Add data:
    my $e = $po->add_element(
        msgid => 'Hello!',
        msgstr => 'Salut !',
    );
    $po->remove_element( $e );
    $po->elements->foreach(sub
    {
        my $e = shift( @_ ); # $_ is also available
        if( $e->msgid eq $other->msgid )
        {
            # do something
        }
    });
    
    # Write in a PO format to STDOUT
    $po->dump;
    # or to a file handle
    $po->dump( $io );
    # Synchronise data
    $po->sync( '/some/where/com.example.api.po' );
    $po->sync( $file_handle );
    # or merge
    $po->merge( '/some/where/com.example.api.po' );
    $po->merge( $file_handle );

=head1 VERSION

    v0.2.4

=head1 DESCRIPTION

This module parse GNU PO (portable object) and POT (portable object template) files, making it possible to edit the localised text and write it back to a po file.

L<Text::PO::MO> reads and writes C<.mo> (machine object) binary files.

Thus, with those modules, you do not need to install C<msgfmt>, C<msginit> of GNU. It is better if you have them though.

Also, this distribution provides a way to export the C<po> files in json format to be used from within JavaScript and a JavaScript class to load and use those files is also provided along with some command line scripts. See the C<share> folder along with its own test units.

Also, there is a script in C<scripts> that can be used to transcode C<.po> or C<mo> files into json format and vice versa.

=head1 CONSTRUCTOR

=head2 new

Create a new Text::PO object acting as an accessor.

One object should be created per po file, because it stores internally the po data for that file in the L<Text::PO> object instantiated.

Returns the object.

=head2 METHODS

=head2 add_element

Given either a L<Text::PO::Element> object, or an hash ref with keys like C<msgid> and C<msgstr>, or given a C<msgid> followed by an optional hash ref, L</add_element> will add this to the stack of elements.

It returns the newly created element if it did not already exist, or the existing one found. Thus if you try to add an element data that already exists, this will prevent it and return the existing element object found.

=head2 added

Returns an array object (L<Module::Generic::Array>) of L<Text::PO::Element> objects added during synchronisation.

=head2 as_json

This takes an optional hash reference of option parameters and return a json formatted string.

All options take a boolean value. Possible options are:

=over 4

=item I<indent>

If true, L<JSON> will indent the data.

Default to false.

=item I<pretty>

If true, this will return a human-readable json data.

=item I<sort>

If true, this will instruct L<JSON> to sort the keys. This makes it slower to generate.

It defaults to false, which will use a pseudo random order set by perl.

=item I<utf8>

If true, L<JSON> will utf8 encode the data.

=back

=head2 as_hash

Return the data parsed as an hash reference.

=head2 as_json

Return the PO data parsed as json data.

=head2 charset

Sets or gets the character encoding for the po data. This will affect the C<charset> parameter in C<Content-Type> meta information.

=head2 content_encoding

Sets or gets the meta field value for C<Content-Encoding>

=head2 content_type

Sets or gets the meta field value for C<Content-Type>

=head2 current_lang

Returns the current language environment variable set, trying C<LANGUAGE> and C<LANG>

=head2 decode

Given a string, this will decode it using the character set specified with L</encoding>

=head2 domain

Sets or gets the domain (or namespace) for this PO. Something like C<com.example.api>

=head2 dump

Given an optional filehandle, or STDOUT by default, it will print to that filehandle in a format suitable to the po file.

Thus, one could create a perl script, read a po file, then redirect the output of the dump back to another po file like

    ./po_script.pl en_GB.po > new_en_GB.po

It returns the L<Text::PO> object used.

=head2 elements

Returns the array reference of all the L<Text::PO::Element> objects

=head2 encoding

Sets or gets the character set encoding for the GNU PO file. Typically this should be C<utf-8>

=head2 exists

Given a L<Text::PO::Element> object, it will check if this object exists in its current stack.

It returns true of false accordingly.

=head2 hash

Returns the data of the po file as an hash reference with each key representing a string and its value the localised version.

=head2 header

Access the headers data for this po file. The data is an array reference.

=head2 language

Sets or gets the meta field value for C<Language>

=head2 language_team

Sets or gets the meta field value for C<Language-Team>

=head2 last_translator

Sets or gets the meta field value for C<Last-Translator>

=head2 merge

This takes the same parameters as L</sync> and will merge the current data with the target data and return the newly created L<Text::PO> object

=head2 meta

This sets or return the given meta information. The meta field name provided is case insensitive and you can replace dashes (C<->) with underscore (<_>)

    $po->meta( 'Project-Id-Version' => 'MyProject 1.0' );
    # or this will also work
    $po->meta( project_id_version => 'MyProject 1.0' );

It can take a hash ref, a hash, or a single element. If a single element is provided, it return its corresponding value.

This returns its internal hash of meta information.

=head2 meta_keys

This is an hash reference of meta information.

=head2 mime_version

Sets or gets the meta field value for C<MIME-Version>

=head2 new_element

Provided with an hash or hash reference of property-value pairs, and this will pass those information to L<Text::PO::Element> and return the new object.

=head2 normalise_meta

Given a meta field, this will return a normalised version of it, ie a field name with the right case and dash instead of underscore characters.

=head2 parse

Given a filepath to a po file or a file handle, this will parse the po file and return a new L<Text::PO> object.

For each new entry that L</parse> find, it creates a L<Text::PO::Element> object.

The list of all elements found can then be accessed using L</elements>

It returns the current L<Text::PO> object

=head2 parse_date_to_object

Provided with a date string and this returns a L<DateTime> object

=head2 parse_header_value

Takes a header value such as C<text/plain; charset="utf-8"> and this returns a C<Text::PO::HeaderValue> object

=head2 parse2hash

Whether the pod file is stored as standard GNU po data or as json data, this method will read its data and return an hash reference of it.     

=head2 parse2object

Takes a file path, parse the po file and loads its data onto the current object. It returns the current object.

=head2 plural

Sets or gets the plurality definition for this domain and locale used in the current object.

If set, this will expect 2 parameters: 1) an integer representing the possible plurality for the given locale and 2) the expression that will be evaluated to assess which plural form to use.

It returns an array reference representing those 2 values.

=head2 plural_forms

Sets or gets the meta field value for C<Plural-Forms>

=head2 po_revision_date

Sets or gets the meta field value for C<PO-Revision-Date>

=head2 pot_creation_date

Sets or gets the meta field value for C<POT-Creation-Date>

=head2 project_id_version

Sets or gets the meta field value for C<Project-Id-Version>

=head2 quote

Given a string, it will escape carriage return, double quote and return it,

=head2 remove_duplicates

Takes a boolean value to enable or disable the removal of duplicates in the po file.

=head2 remove_element

Given a L<Text::PO::Element> and this will remove it from the object elements list.

If the value provided is not an L<Text::PO::Element> object it will return an error.

It returns a true value representing the number of elements removed or 0 if none could be found.

=head2 removed

Sets or gets this boolean value.

=head2 report_bugs_to

Sets or gets the meta field value for C<Report-Msgid-Bugs-To>

=head2 quote

Takes a string and escape the characters that needs to be and returns it.

=head2 remove_duplicates

Takes a boolean value and if true, this will remove duplicate msgid.

=head2 removed

Returns an array object (L<Module::Generic::Array>) of L<Text::PO::Element> removed during synchronisation.

=head2 source

Sets or gets an hash reference of parameters providing information about the source of the data.

It could have an attribute C<handle> with a glob as value or an attribute C<file> with a filepath as value.

=head2 sync

    $po->sync( '/some/where/com.example.api.po' );
    # or
    $po->sync({ file => '/some/where/com.example.api.po' });
    # or
    $po->sync({ handle => $file_handle });
    # or, if source of data has been set previously by parse()
    $po->parse( '/some/where/com.example.api.po' );
    # Do some change to the data, then:
    $po->sync;

Given a file or a file handle, it will read the po file, and our current object will synchronise against it.

It takes an hash or hash reference passed as argument, as optional parameters with the following properties:

=over 4

=item I<file>

File path

=item I<handle>

Opened file handle

=back

This means that our object is the source and the file or filehandle representing the target po file is the recipient of the synchronisation.

This method will return an error a file is provided, already exists, but is either a symbolic link or not a regular file (C<-f> test), or a file handle is provided, but not currently opened.

If a file path is provided, and the file does not yet exist, it will attempt to create it or return an error if it cannot. In this case, it will use L</dump> to write all its data to file.

If the target file was created, it will return the current object, otherwise it returns the newly created L<Text::PO> representing the data synchronised.

=head2 sync_fh

Takes a file handle as its unique argument and synchronise the object data with the file handle. This means, the file handle provided must be opened in both read and write mode.

What it does is that, after creating a new L<Text::PO> object, it will first call L</parse> on the file handle to load its data, and then add all of the current object data to the newly created object, and finally dump all back to the file handle using L</dump>

It will set two array of data: one for the elements that did not exist in the recipient data and thus were added and one for those elements in the target data that did not exist in the source object and thus were removed.

If the option I<append> is specified, however, it will not remove those elements in the target that doe not exist in the source one. You can get the same result by calling the method L</merge> instead of L</sync>

You can get the data of each of those 2 arrays by calling the methods L</added> and L</removed> respectively.

It returns the newly created L<Text::PO> object containing the synchronised data.

=head2 unquote

Takes a string, unescape it and returns it.

=head2 use_json

Takes a boolean value and if true, this will save the data as json instead of regular po format.

Saving data as json makes it quicker to load, but also enable the data to be used by JavaScript.

=head1 PRIVATE METHODS

=head2 _can_write_fh

Given a filehandle, returns true if it can be written to it or false otherwise.

=head2 _set_get_meta_date

Takes a meta field name for a date-type field and sets its value, if one is provided, or returns a L<DateTime> object.

If a value is provided, even a string, it will be converted to a L<DateTime> object and a L<DateTime::Format::Strptime> will be attached to it as a formatter so the stringification of the object produces a date compliant with PO format.

=head2 _set_get_meta_value

Takes a meta field name and sets or gets its value.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Text::PO::Element>, L<Text::PO::MO>, L<Text::PO::Gettext>

L<https://www.gnu.org/software/gettext/manual/html_node/PO-Files.html>,

L<https://en.wikipedia.org/wiki/Gettext>

L<GNU documentation on header format|https://www.gnu.org/software/gettext/manual/html_node/Header-Entry.html>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020-2021 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated files under the same terms as Perl itself.

=cut
