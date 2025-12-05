##----------------------------------------------------------------------------
## PO Files Manipulation - ~/lib/Text/PO.pm
## Version v0.9.1
## Copyright(c) 2025 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2018/06/21
## Modified 2025/12/05
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
    use Scalar::Util;
    use Text::PO::Element;
    use constant HAS_LOCAL_TZ => ( eval( qq{DateTime::TimeZone->new( name => 'local' );} ) ? 1 : 0 );
    our $VERSION = 'v0.9.1';
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
    $self->{domain}             = undef;
    $self->{header}             = [];
    # utf8
    $self->{encoding}           = undef;
    # Should we allow inclusion ?
    $self->{include}            = 1;
    # Maximum recursion allowed for the include option
    $self->{max_recurse}        = 32;
    $self->{meta}               = {};
    $self->{meta_keys}          = [];
    # Default to using po json file if it exists
    $self->{use_json}           = 1;
    $self->{remove_duplicates}  = 1;
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ );
    $self->{elements}   = [];
    $self->{added}      = [];
    $self->{removed}    = [];
    $self->{source}     = {};
    $self->{_parsed}    = 0;
    return( $self );
}

sub add_element
{
    my $self = shift( @_ );
    my( $msgid, $e, $opts );
    if( $self->_is_a( $_[0] => 'Text::PO::Element' ) )
    {
        $e = shift( @_ );
        $msgid = $e->msgid_as_text || return( $self->error( "No msgid was provided" ) );
        $opts = $self->_get_args_as_hash( @_ );
    }
    else
    {
        $opts = $self->_get_args_as_hash( @_ );
        $msgid = $opts->{msgid} || return( $self->error( "No msgid was provided" ) );
        $e = $self->new_element( %$opts ) || return( $self->pass_error );
    }
    return( $self->error( "No msgid was provided." ) ) if( !length( $msgid ) );
    my $elems = $self->elements;
    foreach my $e2 ( @$elems )
    {
        next if( $e2->is_meta || $e2->is_include );
        if( $e2->msgid_as_text eq $msgid )
        {
            # return( $self->error( "There already is an id '$msgid' in the po file" ) );
            return( $e2 );
        }
    }
    $e->po( $self );
    my $id = ( $opts->{before} || $opts->{after} );
    if( $id )
    {
        my $found = 0;
        for( my $i = 0; $i < scalar( @$elems ); $i++ )
        {
            my $elem = $elems->[$i];
            next if( $elem->is_meta );
            if( ( $elem->is_include && ( $elem->file // '' ) eq $id ) ||
                ( !$elem->is_include && ( $elem->id // '' ) eq $id ) )
            {
                if( $opts->{after} )
                {
                    splice( @$elems, $i + 1, 0, $e );
                }
                elsif( $opts->{before} )
                {
                    splice( @$elems, $i, 0, $e );
                }
                $found++;
                last;
            }
        }
        if( !$found )
        {
            return( $self->error( "No msgid/include '$id', to add ", ( $opts->{before} ? 'before' : 'after' ), ", was found, and thus the msgid '${msgid}' could not be added." ) );
        }
    }
    else
    {
        push( @{$self->{elements}}, $e );
    }
    return( $e );
}

sub add_include
{
    my $self = shift( @_ );
    my $e;
    my $opts;
    if( $self->_is_a( $_[0] => 'Text::PO::Element' ) )
    {
        $e = shift( @_ );
        if( !$e->file )
        {
            return( $self->error( "The Text::PO::Element object provided does not have any 'file' value set." ) );
        }
        $opts = $self->_get_args_as_hash( @_ );
    }
    else
    {
        $opts = $self->_get_args_as_hash( @_ );
        if( !$opts->{file} )
        {
            return( $self->error( "No 'file' property found in the hash of options provided." ) );
        }
        $e = $self->new_element( %$opts ) || return( $self->pass_error );
    }
    $e->is_include(1);
    my $file  = $e->file;
    my $elems = $self->elements;
    foreach my $elem ( @$elems )
    {
        next unless( $elem->is_include );
        if( ( $elem->file // '' ) eq $file )
        {
            return( $elem );
        }
    }

    $e->po( $self );
    my $id = ( $opts->{before} || $opts->{after} );
    if( $id )
    {
        my $found = 0;
        for( my $i = 0; $i < scalar( @$elems ); $i++ )
        {
            my $elem = $elems->[$i];
            next if( $elem->is_meta );
            if( ( $elem->is_include && ( $elem->file // '' ) eq $id ) ||
                ( !$elem->is_include && ( $elem->id // '' ) eq $id ) )
            {
                if( $opts->{after} )
                {
                    splice( @$elems, $i + 1, 0, $e );
                }
                elsif( $opts->{before} )
                {
                    splice( @$elems, $i, 0, $e );
                }
                $found++;
                last;
            }
        }
        if( !$found )
        {
            return( $self->error( "No msgid/include '$id', to add ", ( $opts->{before} ? 'before' : 'after' ), ", was found, and thus the include '${file}' could not be added." ) );
        }
    }
    else
    {
        push( @{$self->{elements}}, $e );
    }
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
        my $msgid  = $e->msgid_as_text;
        my $msgstr = $e->msgstr;
        next if( $e->is_meta || !CORE::length( $msgid // '' ) );
        my $k = $msgid;
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
    # try-catch
    local $@;
    my $json = eval
    {
        $j->encode( $hash );
    };
    if( $@ )
    {
        return( $self->error( "Unable to json encode the hash data created: $@" ) );
    }
    return( $json );
}

sub as_string
{
    my $self = shift( @_ );
    my $s = $self->new_scalar( '' );
    my $io = $s->open || return( $self->pass_error( $s->error ) );
    $self->dump( $io );
    return( "$s" );
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

sub content_encoding { return( shift->_set_get_meta_value( 'Content-Transfer-Encoding', @_ ) ); }

sub content_type { return( shift->_set_get_meta_value( 'Content-Type', @_ ) ); }

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
    # try-catch
    local $@;
    my $rv = eval
    {
        return( Encode::decode_utf8( $str, Encode::FB_CROAK ) ) if( $enc eq 'utf8' );
        return( Encode::decode( $enc, $str, Encode::FB_CROAK ) );
    };
    if( $@ )
    {
        return( $self->error( "An error occurred while trying to decode a string using encoding '$enc': $@" ) );
    }
    return( $rv );
}

sub domain { return( shift->_set_get_scalar( 'domain', @_ ) ); }

sub dump
{
    my $self = shift( @_ );
    require IO::File;
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

    # If this is a brain new instance whose data do not originate from parsing a file, and we do not have yet meta data, we set some default now
    if( !$self->{_parsed} && !scalar( keys( %{$self->{meta}} ) ) )
    {
        $self->set_default_meta;
    }

    my $elem = $self->{elements};
    if( my $header = $self->header )
    {
        $fh->print( join( "\n", @$header ) ) || return( $self->error( "Unable to print po data to file handle: $!" ) );
    }
    my $domain = '';
    $domain = $self->domain if( $self->domain );
    if( length( $domain ) )
    {
        $fh->print( "\n#\n# domain \"${domain}\"" ) || return( $self->error( "Unable to print po data to file handle: $!" ) );
    }
    $fh->print( "\n\n" ) || return( $self->error( "Unable to print po data to file handle: $!" ) );
    # my $metaKeys = $self->meta_keys;
    my $metaKeys = [@META];
    if( scalar( @$metaKeys ) )
    {
        $fh->printf( "msgid \"\"\n" ) || return( $self->error( "Unable to print po data to file handle: $!" ) );
        $fh->printf( "msgstr \"\"\n" ) || return( $self->error( "Unable to print po data to file handle: $!" ) );
        foreach my $k ( @$metaKeys )
        {
            my $k2 = lc( $k );
            $k2 =~ tr/-/_/;
            # No, we do not do this anymore. See set_default_meta()
            # if( !exists( $self->{meta}->{ $k2 } ) && 
            #     length( $DEF_META->{ $k } ) )
            # {
            #     $self->{meta}->{ $k2 } = $DEF_META->{ $k };
            # }
            next if( !exists( $self->{meta}->{ $k2 } ) );
            $fh->printf( "\"%s: %s\\n\"\n", $self->normalise_meta( $k ), $self->meta( $k ) ) || return( $self->error( "Unable to print po data to file handle: $!" ) );
        }
        $fh->print( "\n" ) || return( $self->error( "Unable to print po data to file handle: $!" ) );
    }
    foreach my $e ( @$elem )
    {
        my $msgid  = $e->msgid;
        if( $e->is_include )
        {
            $fh->print( $e->dump, "\n" ) || return( $self->error( "Unable to print po data to file handle: $!" ) );
        }
        else
        {
            next if( $e->is_meta || !CORE::length( $msgid ) || ( ref( $msgid // '' ) eq 'ARRAY' && !scalar( @$msgid ) ) );
            if( $e->po ne $self )
            {
                warn( "This element '", $e->msgid_as_text, "' does not belong to us. Its po object is different than our current object.\n" ) if( $self->_is_warnings_enabled );
            }
            $fh->print( $e->dump, "\n" ) || return( $self->error( "Unable to print po data to file handle: $!" ) );
        }
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
    return( $self->error( "The element provided is not an Text::PO::Element object" ) ) if( !$self->_is_a( $elem => 'Text::PO::Element' ) );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{msgid_only} //= 0;
    my $elems = $self->{elements};
    # No need to go further if the object provided does not even have a msgid
    return(0) if( !$elem->is_include && !length( $elem->msgid_as_text ) );
    foreach my $e ( @$elems )
    {
        if( $e->is_include )
        {
            if( ( $e->file // '' ) eq ( $elem->file // '' ) )
            {
                return(1);
            }
        }
        elsif( ( $opts->{msgid_only} && ( $e->msgid_as_text // '' ) eq ( $elem->msgid_as_text // '' ) ) ||
            ( ( $e->msgid_as_text // '' ) eq ( $elem->msgid_as_text // '' ) && ( $e->msgstr_as_text // '' ) eq ( $elem->msgstr_as_text // '' ) ) )
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
        my $msgid = $e->msgid_as_text;
        my $msgstr = $e->msgstr_as_text;
        $hash->{ $msgid } = $msgstr;
    }
    return( $self->new_hash( $hash ) );
}

sub header { return( shift->_set_get_array_as_object( 'header', @_ ) ); }

sub include { return( shift->_set_get_boolean( 'include', @_ ) ); }

sub language { return( shift->_set_get_meta_value( 'Language', @_ ) ); }

sub language_team { return( shift->_set_get_meta_value( 'Language-Team', @_ ) ); }

sub last_translator { return( shift->_set_get_meta_value( 'Last-Translator', @_ ) ); }

sub max_recurse { return( shift->_set_get_number({
    field => 'max_recurse',
    constraint => 'unsigned_int',
}, @_ ) ); }

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
                $self->{meta}->{ lc( $k2 ) } = CORE::delete( $self->{meta}->{ $k } );
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

sub mime_version { return( shift->_set_get_meta_value( 'MIME-Version', @_ ) ); }

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
    my $opts = $self->_get_args_as_hash( @_ );
    my $io;
    my $fh_was_open = 0;
    if( Scalar::Util::reftype( $this ) eq 'GLOB' )
    {
        $io = $this;
        return( $self->error( "Filehandle provided '$io' is not opened" ) ) if( !Scalar::Util::openhandle( $io ) );
        $fh_was_open++;
        $self->source({ handle => $this });
    }
    elsif( index( $this, "\n" ) != -1 )
    {
        return( $self->error( "Use parse_data() if you want to parse lines of data." ) );
    }
    else
    {
        # Use the inherited method 'new_file' from Module::Generic to get a Module::Generic::File object
        my $file = $self->new_file( $this ) ||
            return( $self->pass_error );
        $io = $file->open( '<' ) || return( $self->error( "Unable to open po file \"$this\" in read mode: $!" ) );
        # By default
        $self->source({ file => $file });
    }
    $io->binmode( ':utf8' );
    my $elem = [];
    $self->{elements} = $elem;
    my $header = '';
    my $ignoring_leading_blanks = 1;
    my $n = 0;

    my $include     = exists( $opts->{include} ) ? $opts->{include} : $self->include;
    # For include recursion
    my $seen_inc    = $opts->{seen}  // {};
    my $depth       = $opts->{depth} // 0;
    my $max_recurse = exists( $opts->{max_recurse} ) ? $opts->{max_recurse} : $self->max_recurse;
    my $lang;

    my $e = Text::PO::Element->new( po => $self );
    $e->debug( $self->debug );
    # What was the last seen element?
    # This is used for multi line buffer, so we know where to add it
    my $lastSeen = '';
    my $foundFirstLine = 0;
    # To keep track of the msgid found so we can skip duplicates
    my $seen = {};

    my $include_file = sub
    {
        my $inc_name = shift( @_ ) || return( $self->error( "No file to include was provided." ) );
        my $c = shift( @_ ); # The original line
        my $inc_file;
        # Resolve path relative to current source file, if any
        my $source = $self->source;
        if( $source && $source->file )
        {
            my $base_file = $self->new_file( $source->file ) ||
                return( $self->pass_error );
            $inc_file = $self->new_file( $inc_name, base_file => $base_file ) ||
                return( $self->pass_error );
        }
        else
        {
            $inc_file = $self->new_file( $inc_name );
        }

        if( !$inc_file->exists )
        {
            # Add it as a comment so the user sees it
            $e->add_comment( $c );
            my $msg = "Include file $inc_name ($inc_file) does not exist at line $n";
            warn( $msg ) if( $self->_is_warnings_enabled );
            # Add a comment so translators see the problem:
            $e->add_comment( "ERROR: $msg" );
            return(1);
        }

        # Cycle detection: avoid infinite mutual includes
        if( exists( $seen_inc->{ "$inc_file" } ) )
        {
            my $from = $seen_inc->{ "$inc_file" };
            my $msg  = "Include file \"$inc_file\" has already been included in \"$from\".";
            warn( $msg ) if( $self->_is_warnings_enabled );
            # Optionally annotate:
            $e->add_comment( "INFO: $msg" );
            return(1);
        }

        # Mark as seen from this file
        # $this might be a glob, but the point here is to mark this include as being already processed.
        $seen_inc->{ "$inc_file" } = ( $source && $source->file ) ? $source->file : "$this";

        if( ( $depth + 1 ) > $max_recurse )
        {
            warn( "Maximum include recursion depth ($max_recurse) exceeded (", ( $depth + 1 ), "). Not parsing $inc_file" ) if( $self->_is_warnings_enabled );
            return(1);
        }

        # Parse include in a fresh Text::PO object
        my $sub = $self->new;
        $sub->debug( $self->debug );

        my $me = $sub->parse(
            $inc_file,
            include     => $include,
            seen        => $seen_inc,
            depth       => ( $depth + 1 ),
            max_recurse => $max_recurse,
        );
        if( !$me )
        {
            return( $self->pass_error( $sub->error ) );
        }

        # If the include file has some meta information that include language and we do too, we check, and warn if they do not match
        my $sub_lang = $sub->language;
        if( defined( $lang ) && defined( $sub_lang ) && lc( $lang ) ne lc( $sub_lang ) )
        {
            warn( "Warning only: the language ($sub_lang) of the include file ($inc_file) is different than ours ($lang)" ) if( $self->_is_warnings_enabled );
        }

        my $sub_elems = $sub->elements;
        if( $sub_elems && @$sub_elems )
        {
            # Reuse the same %$seen as for top-level duplicates
            foreach my $se ( @$sub_elems )
            {
                my $id = $se->id // '';
                # Skip duplicate msgid/context combos
                next if( ++$seen->{ $id } > 1 );
                # Before we add it to our elements, we change ownership
                $se->po( $self );
                push( @$elem, $se );
            }
        }
        return( $sub );
    };

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
        if( /^\#+[[:blank:]]*(?:\.[[:blank:]]*)?\$include[[:blank:]]+(["'])(.+?)\1$/i )
        {
            my $inc_name = $2;
            if( $include )
            {
                $include_file->( $inc_name, $_, $n ) || return( $self->pass_error );
            }
            # otherwise, we don't do anything, and discard the line
        }
        elsif( /^\#+[[:blank:]\h]*domain[[:blank:]]+\"([^\"]+)\"/ )
        {
            $self->domain( $1 );
        }
        else
        {
            $header .= $_;
        }
    }
    # Remove trailing blank lines from header
    $header =~ s/(^[[:blank:]\h]*\#[[:blank:]\h]*\n$)+\Z//gms;
    # Make sure to position ourself after the initial blank line if any, since blank lines are used as separators
    # Actually, no we don't care. Blocks are: maybe some comments, msgid then msgstr. That's how we delimit them
    # $_ = $io->getline while( /^[[:blank:]]*$/ && defined( $_ ) );
    $self->header( [split( /\n/, $header )] ) if( length( $header ) );

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
                # Case where msgid and msgstr are separated by a blank line
                if( scalar( @$elem ) > 1 &&
                    !length( $e->msgid_as_text ) && 
                    length( $e->msgstr_as_text ) &&
                    length( $elem->[-1]->msgid_as_text ) &&
                    !length( $elem->[-1]->msgstr_as_text ) )
                {
                    $elem->[-1]->merge( $e );
                }
                elsif( $e->is_include )
                {
                    push( @$elem, $e );
                }
                else
                {
                    if( ++$seen->{ $e->id // '' } > 1 )
                    {
                        next;
                    }
                    elsif( !$e->id && !length( $e->msgstr // '' ) )
                    {
                        # Skipping empty first element. Probably from a bad file...
                    }
                    else
                    {
                        push( @$elem, $e );
                    }
                }
                $e = Text::PO::Element->new( po => $self );
                $e->{_po_line} = $n;
                $e->encoding( $self->encoding ) if( $self->encoding );
                $e->debug( $self->debug );
            }

            # special treatment for first item that contains the meta information
            if( scalar( @$elem ) == 1 )
            {
                my $this = $elem->[0];
                my $def = $this->msgstr || [];
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
                                # try-catch
                                local $@;
                                eval
                                {
                                    $io->binmode( $enc eq 'utf8' ? ":$enc" : ":encoding($enc)" );
                                };
                                if( $@ )
                                {
                                    return( $self->error( "Unable to set binmode to charset \"$enc\": $@" ) );
                                }
                            }
                        }
                    }
                }
                if( scalar( keys( %$meta ) ) )
                {
                    $lang = $meta->{language} if( exists( $meta->{language} ) && defined( $meta->{language} ) && length( $meta->{language} // '' ) );
                    $self->meta( $meta );
                    $this->is_meta(1);
                }
            }
        }
        # #. TRANSLATORS: A test phrase with all letters of the English alphabet.
        # #. Replace it with a sample text in your language, such that it is
        # #. representative of language's writing system.
        # We make sure this is not confused with a non-standard include directive
        elsif( /^\#\.[[:blank:]]*(?<text>(?!.*\$include[[:blank:]]+["'][^"']*["']).*?)$/i )
        {
            my $c = $1;
            $e->add_auto_comment( $c );
        }
        # #: finddialog.cpp:38
        # #: colorscheme.cpp:79 skycomponents/equator.cpp:31
        elsif( /^\#\:[[:blank:]]+(.*?)$/ )
        {
            my $c = $1;
            $e->reference( $c );
        }
        # #, c-format
        elsif( /^\#\,[[:blank:]]+(.*?)$/ )
        {
            my $c = $1;
            $e->flags( [ split( /[[:blank:]]*,[[:blank:]]*/, $c ) ] ) if( $c );
        }
        # Some other comments:
        # - domain declaration
        # - auto comment (extracted with xgettext from the code)
        # - $include directives
        elsif( /^\#+(.*?)$/ )
        {
            my $c = $1;

            # NOTE: Include directive:
            #   # $include "file.po"
            #   #. $include "file.po"
            #   #.$include "file.po"
            # case insensitive, and single or double quote is ok.
            if( $c =~ /^(?:(?:\.[[:blank:]]*)|[[:blank:]]+)\$include[[:blank:]]+(["'])(.+?)\1/i )
            {
                my $inc_name = $2;
                if( $include )
                {
                    $include_file->( $inc_name, $c ) || return( $self->pass_error );

                    # Since this line is an include directive, we do not treat it as a normal comment.
                    next;
                }
                # We just record it
                else
                {
                    $e->is_include(1);
                    $e->file( $inc_name );
                }
            }

            # Normal comment / domain handling as before
            if( !$self->meta->length && $c =~ /^domain[[:blank:]\h]+\"(.*?)\"/ )
            {
                $self->domain( $1 );
            }
            # It could be a blank auto comment, but we keep it to represent faithfully what we found.
            elsif( $c =~ /^\.[[:blank:]]*(.*?)$/ )
            {
                my $auto_comment = $1;
                # Trim leading and trailing spaces
                $auto_comment =~ s/^[[:blank:]]+|[[:blank:]]+$//g;
                $e->add_auto_comment( $auto_comment );
            }
            else
            {
                # Trim leading and trailing spaces
                $c =~ s/^[[:blank:]]+|[[:blank:]]+$//g;
                $e->add_comment( $c );
            }
        }
        elsif( /^msgid[[:blank:]]+"(.*?)"$/ )
        {
            $e->msgid( $self->unquote( $1 ) ) if( length( $1 ) );
            $lastSeen = 'msgid';
        }
        # #: mainwindow.cpp:127
        # #, kde-format
        # msgid "Time: %1 second"
        # msgid_plural "Time: %1 seconds"
        # msgstr[0] "Tiempo: %1 segundo"
        # msgstr[1] "Tiempo: %1 segundos"
        elsif( /^msgid_plural[[:blank:]]+"(.*?)"[[:blank:]]*$/ )
        {
            $e->msgid_plural( $self->unquote( $1 ) ) if( length( $1 ) );
            $e->plural(1);
            $lastSeen = 'msgid_plural';
        }
        # disambiguating context:
        # #: tools/observinglist.cpp:700
        # msgctxt "First letter in 'Scope'"
        # msgid "S"
        # msgstr ""
        # 
        # #: skycomponents/horizoncomponent.cpp:429
        # msgctxt "South"
        # msgid "S"
        # msgstr ""
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
        elsif( /^\#[[:blank:]\h]*$/ )
        {
            # Found some standalone comments; we just ignore
        }
        else
        {
            warn( "I do not understand the line \"$_\" at line $n\n" ) if( $self->_is_warnings_enabled );
        }
    }
    $io->close unless( $fh_was_open );
    if( scalar( @$elem ) )
    {
        if( $elem->[-1] ne $e && 
            CORE::length( $e->msgid_as_text ) && 
            ++$seen->{ $e->msgid_as_text } < 2 )
        {
            push( @$elem, $e );
        }
        shift( @$elem ) if( $elem->[0]->is_meta );
    }
    elsif( $e->msgid // '' )
    {
        push( @$elem, $e );
    }
    # Mark this instance as having parsed data (vs an instance where we build data programmatically)
    $self->{_parsed} = 1;
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
        # Check character string and length. Should not be more than 255 characters
        # http://tools.ietf.org/html/rfc1341
        # http://www.iana.org/assignments/media-types/media-types.xhtml
        # Won't complain if this does not meet our requirement, but will discard it silently
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
        # try-catch
        local $@;
        eval
        {
            $ref = $j->decode( $buff );
        };
        if( $@ )
        {
            return( $self->error( "An error occurred while json decoding data from \"${file}\": $@" ) );
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
        # try-catch
        local $@;
        eval
        {
            $ref = $j->decode( $buff );
        };
        if( $@ )
        {
            return( $self->error( "An error occurred while json decoding data from \"${file}\": $@" ) );
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
    # \t is a tab
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

sub set_default_meta
{
    my $self = shift( @_ );
    foreach my $k ( @META )
    {
        my $k2 = lc( $k );
        $k2 =~ tr/-/_/;
        if( !exists( $self->{meta}->{ $k2 } ) && 
            length( $DEF_META->{ $k } ) )
        {
            $self->{meta}->{ $k2 } = $DEF_META->{ $k };
        }
    }
    return( $self );
}

sub source { return( shift->_set_get_hash_as_object( 'source', @_ ) ); }

sub sync
{
    my $self = shift( @_ );
    # a filehandle, or a filename?
    # my $this = shift( @_ ) || return( $self->error( "No file or filehandle provided." ) );
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
    my $po = $self->new( include => 0 );
    $po->debug( $self->debug );
    # Load the target data file
    $po->parse( $fh );
    # Remove the ones that do not exist
    my $elems = $po->elements;
    my @removed = ();
    # Check the target elements against ours
    for( my $i = 0; $i < scalar( @$elems ); $i++ )
    {
        my $e = $elems->[$i];
        # Do we have the target element ? If not, it was removed
        if( !$self->exists( $e, { msgid_only => 1 } ) )
        {
            my $removedObj = splice( @$elems, $i, 1 );
            push( @removed, $removedObj ) if( $removedObj );
            $i--;
        }
        else
        {
            # Ok, already exists
        }
    }
    # Now check each one of ours against this parsed file and add our items if missing
    $elems = $self->elements;
    my @added = ();
    # Check our source elements against the target ones
    foreach my $e ( @$elems )
    {
        # Does the target file have our element ? If not, we add it.
        if( !$po->exists( $e, { msgid_only => 1 } ) )
        {
            if( $e->is_include )
            {
                $po->add_include( $e );
            }
            else
            {
                $po->add_element( $e );
            }
            push( @added, $e );
        }
        else
        {
            # Ok, already exists
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

# https://stackoverflow.com/questions/3807231/how-can-i-test-if-i-can-write-to-a-filehandle
# -> https://stackoverflow.com/a/3807381/4814971
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

    use strict;
    use warnings;

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

=encoding utf-8

=head1 NAME

Text::PO - Read and write PO files

=head1 SYNOPSIS

    use Text::PO;
    # Create a parser (include directives enabled by default)
    my $po = Text::PO->new;
    $po->debug(2);
    $po->parse( $poFile ) || die( $po->error );

    # Or disable include processing for this parsing
    $po->parse( $poFile, include => 0 );

    # Retrieve parsed elements
    my $hash = $po->as_hash;
    my $json = $po->as_json;

    # Serialize back to PO text
    my $str = $po->as_string;

    # Add data:
    my $e = $po->add_element(
        msgid  => 'Hello!',
        msgstr => 'Salut !',
    );
    my $e = $po->add_include(
        file  => 'include/me.po',
        after => 'Hello world!',
    );

    $po->remove_element( $e );

    # Iterate over elements
    $po->elements->foreach(sub
    {
        my $e = shift( @_ ); # $_ is also available
        if( $e->msgid_as_text eq 'Hello!' )
        {
            # do something
        }
    });

Or, maybe using the object overloading directly:

    $po->elements->foreach(sub
    {
        my $e = shift( @_ ); # $_ is also available
        if( $e eq $other )
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

    v0.9.1

=head1 DESCRIPTION

This module parse GNU PO (portable object) and POT (portable object template) files, making it possible to edit the localised text and write it back to a po file.

L<Text::PO::MO> reads and writes C<.mo> (machine object) binary files.

Thus, with those modules, you do not need to install C<msgfmt>, C<msginit> of GNU. It is better if you have them though.

Also, this distribution provides a way to export the C<po> files in json format to be used from within JavaScript and a JavaScript class to load and use those files is also provided along with some command line scripts. See the C<share> folder along with its own test units.

Also, there is a script in C<scripts> that can be used to transcode C<.po> or C<mo> files into json format and vice versa.

For more information on the format of a PO element, check L<Text::PO::Element>

=head1 CONSTRUCTOR

=head2 new

Create a new Text::PO object acting as an accessor.

One object should be created per po file, because it stores internally the po data for that file in the L<Text::PO> object instantiated.

Returns the object.

The following options can be provided:

=over 4

=item * C<domain>

The PO domain.

=item * C<header>

An array reference of PO file header string. Those are often lines of comments preceded by a pound sign (C<#>), possibly with some copyright information.

=item * C<encoding>

The content encoding of the file, such as C<utf-8>

=item * C<include>

Defaults to true.

A boolean value (C<1> or C<0>) to indicate whether the parser should recognise include directives or not.

=item * C<max_recurse>

Defaults to 32

An unsigned integer value representing the maximum recursion allowed when C<include> is enabled, and when the parser finds include directives.

=item * C<meta>

An hash reference of meta key-value pairs, with the keys in all lower case.

=item * C<meta_keys>

An array reference of meta keys found,

=item * C<use_json>

Defaults to true.

A boolean value (C<1> or C<0>) to indicate whether to use JSON format.

=back

=head2 METHODS

=head2 add_element

    my $elem = $po->add_element( $element_object,
        after => 'Some other text',
    );
    my $elem = $po->add_element(
        msgid   => 'Hello world!",
        msgstr  => 'Salut tout le monde !',
        comment => 'No comment',
        before  => 'Some other text',        # Add this new element before this msgid/include directive
    );

This takes either of the following parameters, and adds the new element, if it does not already exist, to the list of elements:

=over 4

=item 1. L<Text::PO::Element> object + C<%options>

A L<Text::PO::Element> object, possibly followed by an hash or hash reference of options.

=item 2. C<%options>

An hash or hash ref of options that will be passed to L<Text::PO::Element> to create a new object.

=back

It returns the newly created element if it did not already exist, or the existing one found. Thus if you try to add an element data that already exists, this will prevent it and return the existing element object found.

If an error occurred, it will set an L<error object|Module::Generic::Exception> and return C<undef> in scalar context, or an empty list in list context.

Supported options are:

=over 4

=item * all the ones used in L<Text::PO::Element>

=item * C<before> / C<after>

A C<msgid> or C<include> directive value to add this element before or after.

=back

=head2 add_include

    my $elem = $po->add_include( $element_object,
        after => 'Some other text',
    );
    my $elem = $po->add_include(
        file    => 'include/me.po",
        comment => 'No comment',
        before  => 'Some other text',   # Add this new element before this msgid/include directive
    );

This takes either of the following parameters, and adds the new include directive, if it does not already exist, to the list of elements:

=over 4

=item 1. L<Text::PO::Element> object + C<%options>

A L<Text::PO::Element> object, possibly followed by an hash or hash reference of options.

=item 2. C<%options>

An hash or hash ref of options that will be passed to L<Text::PO::Element> to create a new object.

=back

Note that the C<file> parameter must be set in the element passed, or provided among the options used to create a new element.

It returns the newly created element if it did not already exist, or the existing one found. Thus if you try to add an include directive that already exists, this will prevent it and return the existing element object found.

If an error occurred, it will set an L<error object|Module::Generic::Exception> and return C<undef> in scalar context, or an empty list in list context.

Supported options are:

=over 4

=item * all the ones used in L<Text::PO::Element>

=item * C<before> / C<after>

A C<msgid> or C<include> directive value to add this element before or after.

=back

=head2 added

Returns an array object (L<Module::Generic::Array>) of L<Text::PO::Element> objects added during synchronisation.

=head2 as_json

This takes an optional hash reference of option parameters and return a json formatted string.

All options take a boolean value. Possible options are:

=over 4

=item * C<indent>

If true, L<JSON> will indent the data.

Default to false.

=item * C<pretty>

If true, this will return a human-readable json data.

=item * C<sort>

If true, this will instruct L<JSON> to sort the keys. This makes it slower to generate.

It defaults to false, which will use a pseudo random order set by perl.

=item * C<utf8>

If true, L<JSON> will utf8 encode the data.

=back

=head2 as_hash

Return the data parsed as an hash reference.

=head2 as_string

Serializes the current PO object into a single string containing valid GNU C<.po> syntax. This is equivalent to calling L</dump> into an in-memory scalar, but more convenient for tests or further processing.

    my $string = $po->as_string;

This always returns a plain Perl string (not a blessed scalar or IO object) to avoid issues with string overloading.

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

Given a L<Text::PO::Element> object, it will check if this object exists in its current stack. To achieve this, it will check if both the C<msgid> and the C<msgstr> exists and match. If you only want to check if the C<msgid> exists, use the C<msgid_only> option as explained below.

It takes an optional hash or hash reference of options as follows:

=over 4

=item * C<msgid_only>

Boolean. If true, this will check only if the C<msgid> already exists, and not the corresponding C<msgstr>

=back

It returns true of false accordingly.

=head2 hash

Returns the data of the po file as an hash reference with each key representing a string and its value the localised version.

=head2 header

Access the headers data for this po file. The data is an array reference.

=head2 include

    $po->include(1);   # enable include directives
    $po->include(0);   # disable include directives
    my $bool = $po->include;

Controls whether C<$include "file.po"> directives are recognised during parsing.

Include support is enabled by default.

Include directives may appear in comments, using one of the following forms:

    # $include "other.po"
    #. $include 'relative/path.po'
    #   $include "shared/common.po"

When include processing is enabled, any referenced file is parsed recursively. Only valid PO entries (C<msgid>/C<msgstr>/C<msgid_plural>/C<msgctxt> blocks and special comments) from included files are merged into the caller’s namespace; header blocks and meta sections of include files are ignored.

This feature allows modular PO files, shared error message bundles, and structured localisation domains without a separate preprocessing step.

=head2 language

Sets or gets the meta field value for C<Language>

=head2 language_team

Sets or gets the meta field value for C<Language-Team>

=head2 last_translator

Sets or gets the meta field value for C<Last-Translator>

=head2 max_recurse

    $po->max_recurse(20);
    my $limit = $po->max_recurse;

Sets or gets the maximum recursion depth allowed when processing include directives.

The default is 32.

If the recursion limit is exceeded (for example because of accidental self-inclusion or a circular include chain), parsing will abort and L</error> will contain a descriptive message including the file path and line number where recursion overflow occurred.

This protects users from infinite loops and malicious PO input.

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

    $po->parse( $filepath );
    $po->parse( $filepath, include => 0 );
    $po->parse( $fh, max_recurse => 20 );

Parses a GNU C<.po> file or a filehandle and loads its entries into the current object. Returns the current L<Text::PO> instance on success. Upon error, it sets an L<error object|Module::Generic::Exception> and returns C<undef> in scalar context, and an empty list in list context.

=head3 Include processing

If include processing is enabled (see L</include>), the parser recognises the following non-standard directives:

    # $include "path.po"
    #.$include "relative.po"

Relative paths are resolved against the directory of the parent file.

When an include directive is seen:

=over 4

=item 1.

A new L<Text::PO> object is created for the included file.

=item 2.

The effective C<include> and C<max_recurse> settings are passed to the child parser.

=item 3.

Only PO elements (C<msgid>/C<msgstr>/C<msgctl>/C<msgid_plural> entries, and special comments) from the included file are merged into the parent’s C<elements> list. Header metadata from included files is ignored.

=item 4.

Circular references are detected. A descriptive error is attached to the directive line and parsing continues for the parent file.

=item 5.

If the included file has some header meta information containing the header C<Language> and if it does not match that of the parent, a warning is emitted if warnings are enabled.

=back

=head3 Options

parse() accepts the following options:

=over 4

=item * C<include> (boolean)

Override the parser’s include behaviour for this parse call.

=item * C<max_recurse> (unsigned integer)

Override the maximum include depth for this parse call.

=back

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

If you want to find out the proper plural form for a given C<locale>, you should refer to the L<Unicode CLDR|https://cldr.unicode.org/> data, which can be accessed and queries via the module L<Locale::Unicode::Data>:

    my $cldr = Locale::Unicode::Data->new;
    say $cldr->plural_forms( 'fr' ); # nplurals=2; plural=(n > 1);

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

=head2 set_default_meta

Applies a set of default meta information to the <.po> file, if missing.

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

=item * C<file>

File path

=item * C<handle>

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

=head1 THREAD-SAFETY

This module is thread-safe. All state is stored on a per-object basis, and the underlying file operations and data structures do not share mutable global state.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Text::PO::Element>, L<Text::PO::MO>, L<Text::PO::Gettext>

L<https://www.gnu.org/software/gettext/manual/html_node/PO-Files.html>,

L<https://en.wikipedia.org/wiki/Gettext>

L<GNU documentation on header format|https://www.gnu.org/software/gettext/manual/html_node/Header-Entry.html>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020-2025 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated files under the same terms as Perl itself.

=cut
