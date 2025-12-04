##----------------------------------------------------------------------------
## PO Files Manipulation - ~/lib/Text/PO/Gettext.pm
## Version v0.3.2
## Copyright(c) 2023 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/07/12
## Modified 2025/11/29
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Text::PO::Gettext;
BEGIN
{
    use strict;
    use warnings;
    warnings::register_categories( 'Text::PO' );
    use parent qw( Module::Generic );
    use vars qw( $VERSION $L10N $DOMAIN_RE $LOCALE_RE );
    use I18N::Langinfo qw( langinfo );
    use Module::Generic::Global ':const';
    use POSIX ();
    use Text::PO;
    # l10n_id => lang => string => local string
    # our $L10N = {};
    # Since version v0.3.2, we now use Module::Generic::Global for thread safety
    our $DOMAIN_RE = qr/^[a-z]+(\.[a-zA-Z0-9\_\-]+)*$/;
    # Taken from Unicode BCP47 via Locale::Unicode
    our $LOCALE_RE = qr/
    (?<locale>
        (?<locale_lang>
            (?:
                # "root" is treated as a special Unicode language subtag in the LDML and required in the valid pattern
                (?<root>root)
                |
                (?<language>[a-z]{2})
                |
                (?<language3>[a-z]{3})
            )
            # "Up to three optional extended language subtags composed of three letters each, separated by hyphens"
            # "There is currently no extended language subtag registered in the Language Subtag Registry without an equivalent and preferred primary language subtag"
            (?:
                [_-]
                (?<extended>
                    [a-z]{3}
                    (?:\-[a-z]{3}){0,2}
                )
            )?
        )
        # ISO 15924 for scripts
        (?:
            [_-]
            (?:
                (?<script>[A-Z][a-z]{3})
                |
                (?<script>[a-z]{4})
            )
        )?
        (?:
            (?:
                [_-]
                (?<territory>
                    (?<country_code>[A-Z]{2})
                    |
                    # BCP47, section 2.2.4.4: the UN Standard Country or Area Codes for Statistical Use
                    # We are careful not to catch a following variant starting with a digit.
                    (?<region>\d{3}(?!\d))
                )
            )?
            # "Optional variant subtags, separated by hyphens, each composed of five to eight letters, or of four characters starting with a digit"
            # ca-ES-valencia
            # country code can be skipped if the variant is limited to a country
            # be-tarask
            (?:
                [_-]
                (?<variant>
                    (?:
                        (?:[[:alnum:]]{5,8})
                        |
                        (?:\d[[:alnum:]]{3})
                    )
                    (?:
                        [_-]
                        (?:
                            (?:[[:alnum:]]{5,8})
                            |
                            (?:\d[[:alnum:]]{3})
                        )
                    )*
                )
            )?
        )?
        (?:\.(?<locale_encoding>[\w-]+))?
    )
    /xi;
    our $VERSION = 'v0.3.2';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{category} = 'LC_MESSAGES';
    $self->{domain} = undef;
    # We also try LANGUAGE because GNU gettext actually only recognise LANGUAGE
    # For example: LANGUAGE=fr_FR.utf-8 TEXTDOMAINDIR=./t gettext -d "com.example.api" -s "Bad Request"
    $self->{locale} = $ENV{LANG} || $ENV{LANGUAGE};
    $self->{path}   = undef;
    $self->{plural} = [];
    $self->{use_json} = 1;
    $self->{_init_strict_use_sub} = 1;
    $self->{_init_params_order} = [qw( category path domain locale plural use_json )];
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    if( !defined( $self->{path} ) || !length( $self->{path} ) )
    {
        return( $self->error( "No directory path was provided for localisation" ) );
    }
    $self->textdomain( $self->{domain} ) || return( $self->pass_error );
    return( $self );
}

sub addItem
{
    my $self = shift( @_ );
    my( $locale, $key, $value ) = @_;
    my $hash = $self->getDomainHash();
    return( $self->error( "No locale was provided." ) ) if( !defined( $locale ) || !length( $locale ) );
    return( $self->error( "No msgid was provided." ) ) if( !defined( $key ) || !length( $key ) );
    $locale = $self->locale_unix( $locale );
    if( !$self->isSupportedLanguage( $locale ) )
    {
        return( $self->error( "Language requested \"${locale}\" to add item is not supported." ) );
    }
    $hash->{ $locale }->{ $key } = { msgid => $key, msgstr => $value };
    return( $hash->{ $locale }->{ $key } );
}

sub category { return( shift->_set_get_scalar_as_object( 'category', @_ ) ); }

sub charset { return( shift->_get_po->charset ); }

sub contentEncoding { return( shift->_get_po->content_encoding ); }

sub contentType { return( shift->_get_po->content_type ); }

sub currentLang { return( shift->_get_po->current_lang ); }

sub dgettext { return( shift->dngettext( @_ ) ); }

sub dngettext
{
    my $self = shift( @_ );
    my $opts = {};
    $opts = pop( @_ ) if( ref( $_[-1] ) eq 'HASH' );
    my( $domain, $msgid, $msgidPlural, $count ) = @_;
    my $default;
    my $index;
    if( !defined( $count ) || $count !~ /^\d+$/ )
    {
        $default = $msgidPlural || $msgid;
    }
    if( !exists( $opts->{locale} ) || !length( $opts->{locale} ) )
    {
        $opts->{locale} = $self->locale;
    }
    my $hash = $self->getDomainHash({ domain => $domain });
    my $plural = $self->plural;
    if( !exists( $hash->{ $opts->{locale} } ) )
    {
        warn( "No locale \"$opts->{locale}\" found for the domain \"${domain}\".\n" ) if( $self->_is_warnings_enabled( 'Text::PO' ) );
        return( Text::PO::String->new( $default ) );
    }
    my $l10n = $hash->{ $opts->{locale} };
    my $dict = $l10n->{ $msgid };
    if( $dict )
    {
        if( $plural->length == 0 )
        {
            $plural = $self->getPlural();
        }
        if( ref( $dict->{msgstr} ) eq 'ARRAY' )
        {
            if( $self->_is_number( $count ) &&
                int( $plural->[0] ) > 0 )
            {
                no warnings 'once';
                my $n = $count;
                my $expr = $plural->[1];
                $expr =~ s/(?:^|\b)(?<!\$)(n)(?:\b|$)/$n/g;
                $index = eval( $expr );
                if( $@ )
                {
                    warn( "Warning only: problem evaluating expression '$expr' for locale ", $opts->{locale}, ": $@" ) if( $self->_is_warnings_enabled( 'Text::PO' ) );
                }
                else
                {
                    $index = int( $index );
                }
            }
            else
            {
                $index = 0;
            }
            # return( join( '', @{$dict->{msgstr}->[ $index ]} ) || $default );
            my $locale_str = ref( $dict->{msgstr}->[ $index ] ) eq 'ARRAY' ? join( '', @{$dict->{msgstr}->[ $index ]} ) : $dict->{msgstr}->[ $index ];
            return( Text::PO::String->new( $locale_str => $opts->{locale} ) ) if( length( "$locale_str" ) );
            return( Text::PO::String->new( $default ) );
        }
        return( $dict->{msgstr} || $default );
    }
    else
    {
        warn( "No dictionary was found for msgid \"${msgid}\" and domain \"${domain}\"" ) if( $self->_is_warnings_enabled( 'Text::PO' ) );
    }
    return( $default );
}

sub domain
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $v = shift( @_ );
        if( !$v )
        {
            return( $self->error( "No domain was provided." ) );
        }
        elsif( $v !~ /^$DOMAIN_RE$/ )
        {
            return( $self->error( "Domain provided \"$v\" contains illegal characters." ) );
        }
        my $caller = [caller(1)]->[3];
        # We do not call textdomain upon init, because we need both domain and locale to be set first
        # textdomain() is called directly in init()
        $self->textdomain( $v ) unless( $caller eq 'Module::Generic::init' );
        $self->{domain} = $v;
    }
    return( $self->_set_get_scalar_as_object( 'domain' ) );
}

sub exists
{
    my $self = shift( @_ );
    my $lang = shift( @_ );
    if( !defined( $lang ) )
    {
        return( $self->error( "No language to check for existence was provided." ) );
    }
    elsif( !length( $lang ) )
    {
        return( $self->error( "Language provided to check for existence is null." ) );
    }
    elsif( $lang !~ /^$LOCALE_RE$/ )
    {
        return( $self->error( "Unsupported locale format \"${lang}\"." ) );
    }
    $lang = $self->locale_unix( $lang );
    my $hash = $self->getDomainHash();
    return( exists( $hash->{ $lang } ) );
}

sub fetchLocale
{
    my $self = shift( @_ );
    my $key  = shift( @_ );
    my $hash = $self->getDomainHash();
    my $spans = [];
    # Browsing through each available locale language
    # Make it predictable using sort()
    foreach my $k ( sort( keys( %$hash ) ) )
    {
        my $locWeb = $self->locale_web( $k );
        push( @$spans, "<span lang=\"${locWeb}\">" . $self->dngettext( $self->domain, $key, { locale => $k }) . '</span>' );
    }
    return( $self->new_array( $spans ) );
}

sub getDataPath { return( $ENV{TEXTDOMAINDIR} ); }

sub getDaysLong
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $ref  = $self->_get_days( $self->locale );
    my $days = $ref->[1];
    if( $opts->{monday_first} )
    {
        # Move Sunday at the end
        push( @$days, shift( @$days ) );
    }
    return( $days );
}

sub getDaysShort
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $ref  = $self->_get_days( $self->locale );
    my $days = $ref->[0];
    if( $opts->{monday_first} )
    {
        # Move Sunday at the end
        push( @$days, shift( @$days ) );
    }
    return( $days );
}

sub getDomainHash
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{domain} //= $self->domain;
    my $class = ref( $self ) || $self;

    my $repo = Module::Generic::Global->new( 'l10n' => $class );
    my $hash = $repo->get // {};
    if( !exists( $hash->{ $opts->{domain} } ) )
    {
        return( $self->error( "No locale data for domain \"$opts->{domain}\"." ) );
    }
    my $l10n = $hash->{ $opts->{domain} };
    if( exists( $opts->{locale} ) && 
        defined( $opts->{locale} ) )
    {
        $opts->{locale} = $self->locale_unix( $opts->{locale} );
        if( length( $opts->{locale} ) == 0 )
        {
            return( $self->error( "Locale was provided, but is empty." ) );
        }
        return( $l10n->{ $opts->{locale} } );
    }
    return( $l10n );
}

sub getLangDataPath { return( $ENV{TEXTLOCALEDIR} ); }

sub getLanguageDict
{
    my $self = shift( @_ );
    my $lang = shift( @_ ) || return( $self->error( "Language provided, to get its dictionary, is undefined or null." ) );
    if( $lang !~ /^$LOCALE_RE$/ )
    {
        return( $self->error( "Locale provided (${lang}) is in an unsupported format." ) );
    }
    $lang = $self->locale_unix( $lang );

    if( !$self->isSupportedLanguage( $lang ) )
    {
        return( $self->error( "Language provided (${lang}), to get its dictionary, is unsupported." ) );
    }
    my $hash = $self->getDomainHash();
    if( !exists( $hash->{ $lang } ) )
    {
        return( $self->error( "Language provided (${lang}), to get its dictionary, could not be found. This is weird. Most likely a configuration mistake." ) );
    }
    return( $hash->{ $lang } );
}

sub getLocale { return( shift->locale ); }

sub getLocales
{
    my $self = shift( @_ );
    my $key  = shift( @_ ) || return( $self->error( "No text provided to get its localised equivalent" ) );
    my $res = $self->fetchLocale( $key ) || return( $self->pass_error );
    if( scalar( @$res ) > 0 )
    {
        return( join( "\n", @$res ) );
    }
    else
    {
        return( $key );
    }
}

sub getLocalesf
{
    my $self = shift( @_ );
    my $key  = shift( @_ ) || return( $self->error( "No text provided to get its localised equivalent" ) );
    my $res = $self->fetchLocale( $key ) || return( $self->pass_error );
    if( scalar( @$res ) > 0 )
    {
        for( my $i = 0; $i < scalar( @$res ); $i++ )
        {
            $res->[$i] = sprintf( $res->[$i], @_ );
        }
        return( join( "\n", @$res ) );
    }
    else
    {
        return( sprintf( $key, @_ ) );
    }
}

sub getMetaKeys
{
    my $self = shift( @_ );
    my $hash = $self->getDomainHash({ locale => $self->locale });
    my $po = $hash->{_po} || return( $self->error( "Unable to get the po object in the locale data hash" ) );
    return( $po->meta_keys );
}

sub getMetaValue
{
    my $self = shift( @_ );
    my $field = shift( @_ ) || return( $self->error( "No meta field provided to get its value." ) );
    my $hash = $self->getDomainHash({ locale => $self->locale });
    my $po = $hash->{_po} || return( $self->error( "Unable to get the po object in the locale data hash" ) );
    return( $po->meta( $field ) );
}

sub getMonthsLong
{
    my $self = shift( @_ );
    my $ref  = $self->_get_months( $self->locale );
    return( $ref->[1] );
}

sub getMonthsShort
{
    my $self = shift( @_ );
    my $ref  = $self->_get_months( $self->locale );
    return( $ref->[0] );
}

sub getNumericDict
{
    my $self = shift( @_ );
    my $ref  = $self->_get_numeric_dict( $self->locale );
    return( $ref->[0] );
}

sub getNumericPosixDict
{
    my $self = shift( @_ );
    my $ref  = $self->_get_numeric_dict( $self->locale );
    return( $ref->[1] );
}

sub getPlural
{
    my $self = shift( @_ );
    my $po = $self->_get_po || return( $self->error( "Unable to get the po object in the locale data hash" ) );
    return( $po->plural );
}

sub getText
{
    my $self = shift( @_ );
    my( $key, $lang ) = @_;
    return( $self->error( "No text to get its localised equivalent was provided." ) ) if( !defined( $key ) || !length( $key ) );
    return( $self->dngettext( $self->domain, $key, { locale => $lang }) );
}

sub getTextf
{
    my $self = shift( @_ );
    my $opts = {};
    $opts = pop( @_ ) if( ref( $_[-1] ) eq 'HASH' );
    $opts->{lang} = $self->locale || $self->currentLang();
    my $key  = shift( @_ );
    my $text = $self->getText( $key, $opts->{lang} );
    return( sprintf( $text, @_ ) );
}

sub gettext
{
    my $self = shift( @_ );
    return( $self->dngettext( $self->domain, shift( @_ ) ) );
}

sub gettextf { return( shift->getTextf( @_ ) ); }

sub isSupportedLanguage
{
    my $self  = shift( @_ );
    my $lang  = shift( @_ ) || return(0);
    my $class = ref( $self ) || $self;
    $lang = $self->locale_unix( $lang );
    my $dom  = $self->domain;
    my $repo = Module::Generic::Global->new( 'l10n' => $class );
    my $l10n = $repo->get // {};
    return( $self->error( "No domain \"$dom\" set!" ) ) if( !CORE::exists( $l10n->{ $dom } ) );
    my $dict = $l10n->{ $dom };
    if( CORE::exists( $dict->{ $lang } ) )
    {
        return(1);
    }
    else
    {
        return(0);
    }
}

sub language { return( shift->_get_po->language ); }

sub languageTeam { return( shift->_get_po->language_team ); }

sub lastTranslator { return( shift->_get_po->last_translator ); }

sub mimeVersion { return( shift->_get_po->mime_version ); }

sub locale
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $v = shift( @_ );
        if( !defined( $v ) || !length( $v ) )
        {
            return( $self->error( "No language was set." ) );
        }
        elsif( $v =~ /^$LOCALE_RE$/ )
        {
            # The user is responsible for the locale value s/he provides. We only checks s/he provides a valid locale.
            # We normalise it.
            my( $loc, $enc ) = split( /\./, $v, 2 );
            $loc =~ tr/-/_/;
            $v = $loc;
            $v .= '.' . $enc if( defined( $enc ) );
        }
        else
        {
            return( $self->error( "Language provided (\"$v\") is in an unsupported format. Use something like \"en_GB\", \"en-GB\" or simply \"en\" or even \"en_GB.utf-8\"." ) );
        }
        return( $self->error( "No domain is set or it has disappeared!" ) ) if( !$self->{domain} );
        $self->{locale} = $v;
        my $caller = [caller(1)]->[3];
        # We do not call textdomain upon init, because we need both domain and locale to be set first
        # textdomain() is called directly in init()
        $self->textdomain( $self->{domain} ) unless( $caller eq 'Module::Generic::init' );
    }
    return( $self->_set_get_scalar_as_object( 'locale' ) );
}

sub locale_unix
{
    my $self = shift( @_ );
    my $loc  = shift( @_ ) || $self->locale;
    # Only once
    if( $loc =~ /^$LOCALE_RE$/ )
    {
        ( $loc, my $enc ) = split( /\./, $loc, 2 );
        $loc =~ tr/-/_/;
        $loc .= '.' . $enc if( defined( $enc ) );
    }
    return( $loc );
}

sub locale_web
{
    my $self = shift( @_ );
    my $loc  = shift( @_ ) || $self->locale;
    # Only once
    if( $loc =~ /^$LOCALE_RE$/ )
    {
        ( $loc, my $enc ) = split( /\./, $loc, 2 );
        $loc =~ tr/_/-/;
        $loc .= '.' . $enc if( defined( $enc ) );
    }
    return( $loc );
}

sub ngettext
{
    my $self = shift( @_ );
    my( $msgid, $msgidPlural, $count ) = @_;
    return( $self->dngettext( $self->domain, $msgid, $msgidPlural, $count ) );
}

sub path { return( shift->_set_get_file( 'path', @_ ) ); }

sub plural
{
    my $self = shift( @_ );
    if( @_ )
    {
        return( $self->_set_get_array_as_object( 'plural', @_ ) );
    }
    else
    {
        if( !scalar( @{$self->{plural}} ) )
        {
            $self->{plural} = $self->getPlural();
        }
        return( $self->_set_get_array_as_object( 'plural' ) );
    }
}

sub pluralForms { return( shift->_get_po->plural_forms ); }

sub po_object { return( shift->_get_po ); }

sub poRevisionDate { return( shift->_get_po->po_revision_date ); }

sub potCreationDate { return( shift->_get_po->pot_creation_date ); }

sub projectIdVersion { return( shift->_get_po->project_id_version ); }

sub reportBugsTo { return( shift->_get_po->report_bugs_to ); }

sub textdomain
{
    my $self  = shift( @_ );
    my $dom   = shift( @_ ) || return( $self->error( "No domain was provided." ) );
    my $class = ref( $self ) || $self;
    my $base = $self->path;
    my $lang = $self->locale_unix;
    my $path_po   = $base->join( $base, $lang, ( $self->category ? $self->category : () ), "${dom}.po" );
    my $path_json = $base->join( $base, $lang, ( $self->category ? $self->category : () ), "${dom}.json" );
    my $path_mo   = $base->join( $base, $lang, ( $self->category ? $self->category : () ), "${dom}.mo" );
    my $file;
    my $po;

    if( $self->use_json && $path_json->exists )
    {
        $file = $path_json;
        $po = Text::PO->new( domain => $dom, use_json => 1, debug => $self->debug ) ||
            return( $self->pass_error( Text::PO->error ) );
        $po->parse2object( $file ) ||
            return( $self->pass_error( $po->error ) );
    }
    elsif( $path_po->exists )
    {
        $file = $path_po;
        $po = Text::PO->new( domain => $dom, debug => $self->debug ) ||
            return( $self->pass_error( Text::PO->error ) );
        $po->parse( $file ) ||
            return( $self->pass_error( $po->error ) );
    }
    elsif( $path_mo->exists )
    {
        $file = $path_mo;
        my $mo = Text::PO::MO->new( $file, { domain => $dom, debug => $self->debug }) ||
            return( $self->pass_error( Text::PO::MO->error ) );
        $po = $mo->as_object ||
            return( $self->pass_error( $po->error ) );
    }
    else
    {
        return( $self->error( "No data file could be found for \"$dom\" for either json, po, or mo file." ) );
    }
    my $repo = Module::Generic::Global->new( 'l10n' => $class );
    $repo->lock;
    my $l10n = $repo->get // {};
    $l10n->{ $dom } = {} if( ref( $l10n->{ $dom } ) ne 'HASH' );
    my $dict = $l10n->{ $dom }->{ $lang } = {} if( ref( $l10n->{ $dom }->{ $lang } ) ne 'HASH' );
    $dict->{_po} = $po;
    $po->elements->foreach(sub
    {
        my $ref = shift( @_ );
        $dict->{ $ref->{msgid} } = $ref;
    });
    $repo->set( $l10n );
    $repo->unlock;
    return( $self );
}

sub use_json { return( shift->_set_get_boolean( 'use_json', @_ ) ); }

sub _get_days
{
    my $self = shift( @_ );
    my $locale = shift( @_ );
    my $oldlocale = POSIX::setlocale( &POSIX::LC_ALL );
    my $short = $self->new_array;
    my $long  = $self->new_array;

    POSIX::setlocale( &POSIX::LC_ALL, $locale ) if( defined( $locale ) );

    for (my $i = 1; $i <= 7; $i++)
    {
        # my $const = "I18N::Langinfo::ABDAY_${i}";
        my $const = I18N::Langinfo->can( "ABDAY_${i}" );
        # $short->[$i-1] = langinfo( &$const );
        $short->[$i-1] = langinfo( $const->() );
    }
    for (my $i = 1; $i <= 7; $i++)
    {
        # my $const = "I18N::Langinfo::DAY_${i}";
        my $const = I18N::Langinfo->can( "DAY_${i}" );
        # $long->[$i-1] = langinfo( &$const );
        $long->[$i-1] = langinfo( $const->() );
    }

    POSIX::setlocale( &POSIX::LC_ALL, $oldlocale) if( defined( $locale ) );

    return( [ $short, $long ] );
}

sub _get_months
{
    my $self   = shift( @_ );
    my $locale = shift( @_ );
    my $oldlocale = POSIX::setlocale( &POSIX::LC_ALL );
    my $short = $self->new_array;
    my $long  = $self->new_array;

    POSIX::setlocale( &POSIX::LC_ALL, $locale ) if( defined( $locale ) );

    for( my $i = 1; $i <= 12; $i++ )
    {
        # my $const = "I18N::Langinfo::ABMON_${i}";
        # $short->[$i-1] = langinfo( &$const );
        my $const = I18N::Langinfo->can( "ABMON_${i}" );
        $short->[$i-1] = langinfo( $const->() );
    }
    for( my $i = 1; $i <= 12; $i++ )
    {
        # my $const = "I18N::Langinfo::MON_${i}";
        # $long->[$i-1] = langinfo( &$const );
        my $const = I18N::Langinfo->can( "MON_${i}" );
        $long->[$i-1] = langinfo( $const->() );
    }

    POSIX::setlocale( &POSIX::LC_ALL, $oldlocale) if( defined( $locale ) );

    return( [ $short, $long ] );
}

sub _get_numeric_dict
{
    my $self   = shift( @_ );
    my $locale = shift( @_ );
    my $oldlocale = POSIX::setlocale( &POSIX::LC_ALL );
    POSIX::setlocale( &POSIX::LC_ALL, $locale) if( defined( $locale ) );
    my $lconv = POSIX::localeconv();
    POSIX::setlocale( &POSIX::LC_ALL, $oldlocale) if( defined( $locale ) );
    my $def = $self->new_hash;
    @$def{qw( currency decimal int_currency negative_sign thousand precision )} = 
    @$lconv{qw( currency_symbol decimal_point int_curr_symbol negative_sign thousands_sep frac_digits )};
    use utf8;
    $def->{currency} = '€' if( CORE::exists( $def->{currency} ) && defined( $def->{currency} ) && $def->{currency} eq 'EUR' );
    $lconv->{currency_symbol} = '€' if( CORE::exists( $lconv->{currency_symbol} ) && defined( $lconv->{currency_symbol} ) && $lconv->{currency_symbol} eq 'EUR' );
    $lconv->{grouping} = unpack( "C*", $lconv->{grouping} ) if( CORE::exists( $lconv->{grouping} ) && defined( $lconv->{grouping} ) );
    $lconv->{mon_grouping} = unpack( "C*", $lconv->{mon_grouping} ) if( CORE::exists( $lconv->{mon_grouping} ) && defined( $lconv->{mon_grouping} ) );
    $lconv = $self->new_hash( $lconv );
    return( [ $def, $lconv ] );
}

sub _get_po
{
    my $self = shift( @_ );
    my $hash = $self->getDomainHash({ locale => $self->locale });
    return( $hash->{_po} );
}

# NOTE: Text::PO::String class
{
    package
        Text::PO::String;
    BEGIN
    {
        use strict;
        use warnings;
        use parent qw( Module::Generic );
        use vars qw( $VERSION );
        our $VERSION = 'v0.1.0';
        use overload (
            '""'    => 'as_string',
            'bool'  => sub{1},
            fallback => 1,
        );
    };

    use strict;
    use warnings;

    sub init
    {
        my $self = shift( @_ );
        my $value = shift( @_ );
        my $locale = shift( @_ );
        $self->{locale} = $locale;
        $self->{value}  = $value;
        $self->SUPER::init( @_ );
        return( $self );
    }

    sub as_string { return( shift->value->scalar ); }

    sub locale { return( shift->_set_get_scalar_as_object( 'locale', @_ ) ); }

    sub value { return( shift->_set_get_scalar_as_object( 'value', @_ ) ); }

    sub TO_JSON { return( shift->as_string ); }
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Text::PO::Gettext - Object-oriented GNU Gettext-style implementation

=head1 SYNOPSIS

    use Text::PO::Gettext;

    # Basic usage: one domain, one locale
    my $po = Text::PO::Gettext->new(
        path       => '/home/joe/locale', # path to where the list of locales directories are
        domain     => 'com.example.api',
        locale     => 'fr_FR',            # optional, falls back to environment; _ or - does not matter
        # use_json => 1,                  # if you use JSON exports from Text::PO
        # category => 'LC_MESSAGES',      # optional, defaults to LC_MESSAGES
    ) || die( Text::PO::Gettext->error );

    # Simple lookup
    my $hello = $po->gettext('Hello world');

    # Text::PO::String objects stringify to the translated text
    say $hello;          # "Bonjour le monde"
    say $hello->value;   # same
    say $hello->locale;  # "fr_FR"

    # Plural form lookup
    my $n = 3;
    my $apples = $po->ngettext(
        '%d apple',     # singular
        '%d apples',    # plural
        $n,
    );
    printf "$apples\n", $n;              # formatted with %d, still Text::PO::String

    # Typical web service / PSGI pattern
    my $msg = $po->gettext('Invalid parameter');

    my $body = { error => "$msg" };      # stringification
    my $res  = [
        200,
        [
            'Content-Type'     => 'application/json; charset=utf-8',
            'Content-Language' => $msg->locale,   # <- effective locale
        ],
        [ encode_json($body) ],
    ];

    # Plural forms
    my $count = 3;
    my $files = $po->ngettext('%d file', '%d files', $count);
    printf "$files\n", $count;    # "3 fichiers"

    # Per-object locale: two locales loaded simultaneously
    my $fr = Text::PO::Gettext->new(
        domain => 'com.example.api',
        locale => 'fr_FR',
        path   => '/some/where/locale',
    );

    my $en = Text::PO::Gettext->new(
        domain => 'com.example.api',
        locale => 'en_GB',
        path   => '/some/where/locale',
    );

    my $msg_fr = $fr->gettext( 'Welcome' );
    my $msg_en = $en->gettext( 'Welcome' );

    say "FR: $msg_fr";                   # "FR: Bienvenue"
    say "EN: $msg_en";                   # "EN: Welcome"

    # Using Text::PO::String to set Content-Language in a web service
    my $title = $po->gettext( 'Page title' );

    $res->header( 'Content-Language' => $title->locale );
    $res->body( $title->value );

    # Switching locale on an existing object
    $po->locale( 'fr_FR' );              # internally normalised
    my $bye = $po->gettext( 'Goodbye' );

    # JSON-based catalogues instead of PO/MO
    my $json_po = Text::PO::Gettext->new(
        domain   => 'com.example.api',
        locale   => 'ja_JP',
        path     => '/var/www/locale',
        use_json => 1,
    );

    my $label = $json_po->gettext( 'Log in' );

=head1 VERSION

    v0.3.2

=head1 DESCRIPTION

This module provides an object-oriented interface to gettext-style localisation data stored as C<.po>, C<.mo>, or C<.json> files.

The conventional way to use GNU gettext is to set the global environment variable C<LANGUAGE> (not C<LANG> by the way. GNU gettext only uses C<LANGUAGE>), then set the L<POSIX/setlocale> to the language such as:

    use Locale::gettext;
    use POSIX ();
    POSIX::setlocale( &POSIX::LC_ALL, 'ja_JP' );
    my $d = Locale::gettext->domain( 'com.example.api' );

And then in your application, you would write a statement like:

    print $d->get( 'Hello!' );

Or possibly using direct access to the C function:

    use Locale::gettext;
    use POSIX ();
    POSIX::setlocale( &POSIX::LC_ALL, 'ja_JP' );
    textdomain( 'com.example.api' );

And then:

    print gettext( 'Hello!' );

See L<Locale::gettext> for more on this.

This works fine, but has the inconvenience that it uses the global C<LANGUAGE> environment variable and makes it less than subpar as to the necessary flexibility when using multiple domains and flipping back and forth among locales.

Thus comes a more straightforward object-oriented interface offered by this module.

So, L<Text::PO::Gettext> allows you to create multiple independent localisation objects, each with its own domain, locale, and data directory. This makes it straightforward to:

=over 4

=item *

serve multiple users with different locales in the same process,

=item *

switch locale per request without touching global environment variables, and

=item *

work comfortably under threaded environments, mod_perl, daemons, etc.

=back

A typical directory layout might look like:

    /some/where/locale/
        en_GB/
            LC_MESSAGES/
                com.example.api.po
                com.example.api.mo
                com.example.api.json
        ja_JP/
            LC_MESSAGES/
                com.example.api.po
                com.example.api.json

Based on the options you pass (C<domain>, C<locale>, C<path>, C<use_json>), the module will look for a suitable localisation file in the order:

=over 4

=item *

JSON file (C<.json>) if C<use_json> is true and such a file exists,

=item *

PO file (C<.po>) if present,

=item *

MO file (C<.mo>) as a fallback.

=back

Thus, you instantiate an object, passing the domain, the locale and the filesystem path where the locale data resides.

    my $po = Text::PO::Gettext->new(
        domain => 'com.example.api',
        locale => 'ja_JP',
        path   => '/some/where/locale'
    );
    print $po->gettext( 'Hello!' );

This will load into memory the locale data whether they are stored as C<.po>, C<.mo> or even C<.json> file, thus making calls to L</gettext> super fast since they are in memory.

More than one locale can be loaded, each with its own L<Text::PO::Gettext> object

This distribution comes with its Javascript library equivalent. See the C<share> folder alone with its own test units.

Also, there is a script in C<scripts> that can be used to transcode C<.po> or C<.mo> files into json format and vice versa.

Still, it is better to convert the original C<.po> files to json using the C<po.pl> utility that comes in this L<Text::PO> distribution since it would allow the standalone JavaScript library to read json-based po files. For example:

    ./po.pl --as-json --output /home/joe/www/locale/ja_JP/LC_MESSAGES/com.example.api.json ./ja_JP.po

This api supports locale that use hyphens or underscore in them such as C<en-GB> or C<en_GB>. You can use either, it will be converted internally.

All translated strings returned by this module are instances of L<Text::PO::String>. L<Text::PO::String> objects are tiny wrappers around the translated value. They:

=over 4

=item *

Stringify transparently to the translated text.

=item *

Provide a C<locale> method returning the effective locale used for that lookup (for example C<en_GB> or C<fr_FR>).

=item *

Provide a C<value> method returning the translated text as a plain scalar.

=back

This is particularly handy for web services and APIs, where you may want to inspect the locale actually used for a given message and, for example, set the C<Content-Language> response header accordingly:

    my $msg = $po->gettext( 'Error: invalid input' );

    $res->header( 'Content-Language' => $msg->locale );
    $res->body( $msg->value );

You can safely treat C<Text::PO::String> objects as regular strings in most contexts; they are designed to be drop-in replacements for plain scalars from the caller’s point of view, while still carrying useful metadata.

=head1 CONSTRUCTOR

=head2 new

    my $po = Text::PO::Gettext->new(
        domain   => 'com.example.api',
        locale   => 'ja_JP',
        path     => '/some/where/locale',
        category => 'LC_MESSAGES',   # optional
        use_json => 1,               # optional
        plural   => [ $n, $expr ],   # optional
        debug    => 1,               # optional
    );

Creates a new C<Text::PO::Gettext> object.

Takes the following options and returns a Gettext object.

=over 4

=item * C<category>

This is optional.

If I<category> is defined, such as C<LC_MESSAGES> (by default), it will be used when building the I<path>.

Other possible category values are: C<LC_CTYPE>, C<LC_NUMERIC>, C<LC_TIME>, C<LC_COLLATE>, C<LC_MONETARY>

See L<GNU documentation for more information|https://www.gnu.org/software/gettext/manual/html_node/Locale-Environment-Variables.html> and L<perllocale/"LOCALE CATEGORIES">

On the web, using the path is questionable.

See the L<GNU documentation|https://www.gnu.org/software/libc/manual/html_node/Using-gettextized-soft
ware.html> for more information on this.

=item * C<domain>

This is required.

The portable object domain, such as C<com.example.api>

This typically corresponds to the base filename of your PO/MO/JSON files.

=item * C<locale>

This is required.

The locale, such as C<ja_JP>, or C<en>, or it could even contain a hyphen instead of an underscore, such as C<en-GB>. Internally, though, this will be converted to underscore.

=item * C<path>

This is required.

Base filesystem path where the localisation files are stored.

This is used to form a path along with the locale string. For example, with a locale of C<ja_JP> and a domain of C<com/example.api>, if the path were C</locale>, the data po json data would be fetched from C</locale/
ja_JP/LC_MESSAGES/com.example.api.json>

=item * C<plural>

This is optional.

An array reference C<[ $n, $expr ]> defining plural forms for the current domain and locale. This is normally derived from the PO metadata (C<Plural-Forms>) but can be overridden if needed.

=item * C<use_json>

Optional boolean value.

If true, PO data will be loaded from JSON files produced by L<Text::PO> instead of regular PO/MO files.

This is particularly useful when working with the JavaScript companion library provided by the L<Text::PO> distribution.

=back

The constructor does not immediately load the catalogue; data is pulled in when you first call L</textdomain> or any of the lookup methods, which internally ensure the domain has been loaded.

Returns the newly created L<Text::PO::Gettext> object or upon error, it sets an L<error object|Module::Generic::Exception>, and returns C<undef> in scalar context, or an empty list in list context.

=head1 METHODS

=head2 addItem

This takes a C<locale>, a message id and its localised version and it will add this to the current dictionary for the current domain.

    $po->addItem( 'ja_JP', 'Hello!' => "今日は！" );

=head2 category

The category to use. This defaults to C<LC_MESSAGES>, but if you prefer you can nix its use by making it undefined, or empty:

    my $po = Text::PO::Gettext->new(
        category => '',
        domain => 'com.example.api',
        locale => 'ja_JP',
        path   => '/some/where/locale'
    );
    # Setting category to empty string will have the module get the po data 
    # under C</some/where/locale/ja_JP/com.example.api.json> for example.
    print $po->gettext( 'Hello!' );

=head2 charset

Returns a string containing the value of the charset encoding as defined in the C<Content-Type> header.

    $po->charset()

=head2 contentEncoding

Returns a string containing the value of the header C<Content-Encoding>.

    $po->contentEncoding();

=head2 contentType

Returns a string containing the value of the header C<Content-Type>.

    $po->contentType(); # text/plain; charset=utf-8

=head2 currentLang

Return the current globally used locale. This is the value found in environment variables C<LANGUAGE> or C<LANG>. Note that GNU gettext only recognises C<LANGUAGE>

and thus, this is different from the C<locale> set in the Gettext class object using </setLocale> or upon class object instantiation.

=head2 dgettext

This is like L</gettext>, but takes a specific domain and a message ID and returns the equivalent localised string if any, otherwise the original message id.

    $po->dgettext( 'com.example.auth', 'Please enter your e-mail address' );
    # Assuming the locale currently set is ja_JP, this would return:
    # 電子メールアドレスをご入力下さい。

=head2 dngettext

Same as L</ngettext>, but takes also a domain as first argument. For example:

    $po->ngettext( 'com.example.auth', '%d comment awaiting moderation', '%d comments awaiting moderation', 12 );
    # Assuming the locale is ru_RU, this would return:
    # %d комментариев ожидают проверки

Note that as of version C<v0.5.0>, this returns a C<Text::PO::String>, which is lightweight and stringifies automatically. It provides the benefit of tagging the string with the locale attached to it.

Thus, in the example above, the resulting C<Text::PO::String> would have its method C<locale> value set to C<ru_RU>, and you could do:

    my $localised = $po->ngettext( 'com.example.auth', '%d comment awaiting moderation', '%d comments awaiting moderation', 12 );
    say "Locale for this string is: ", $localised->locale;

If no locale string was found, C<locale> would be undefined.

=head2 domain

Sets or gets the domain.

    $po->domain( 'com.example.api' );

By doing so, this will call L</textdomain> and load the associated data from file, if any are found.

=head2 exists

Provided with a locale, and this returns true if the locale exists in the current domain, or false otherwise.

=head2 fetchLocale

Given an original string (msgid), this returns an array of <span> html element each for one language and its related localised content. For example:

    my $array = $po->fetchLocale( "Hello!" );
    # Returns:
    <span lang="de-DE">Grüß Gott!</span>
    <span lang="fr-FR">Salut !</span>
    <span lang="ja-JP">今日は！</span>
    <span lang="ko-KR">안녕하세요!</span>

This is designed to be added to the html, and based on C<lang> attribute of the C<html> tag, and using the following css trick, this will automatically display the right localised data:

    [lang=de-DE] [lang=en-GB],
    [lang=de-DE] [lang=fr-FR],
    [lang=de-DE] [lang=ja-JP],
    [lang=de-DE] [lang=ko-KR],
    [lang=en-GB] [lang=de-DE],
    [lang=en-GB] [lang=fr-FR],
    [lang=en-GB] [lang=ja-JP],
    [lang=en-GB] [lang=ko-KR],
    [lang=fr-FR] [lang=de-DE],
    [lang=fr-FR] [lang=en-GB],
    [lang=fr-FR] [lang=ja-JP],
    [lang=fr-FR] [lang=ko-KR],
    [lang=ja-JP] [lang=de-DE],
    [lang=ja-JP] [lang=en-GB]
    [lang=ja-JP] [lang=fr-FR],
    [lang=ja-JP] [lang=ko-KR]
    {
        display: none !important;
        visibility: hidden !important;
    }

=head2 getDataPath

This takes no argument and will check for the environment variables C<TEXTDOMAINDIR>. If found, it will use this in lieu of the I<path> option used during object instantiation.

It returns the value found. This is just a helper method and does not affect the value of the I<path> property set during object instantiation.

=head2 getDaysLong

Returns an array reference containing the 7 days of the week in their long representation.

    my $ref = $po->getDaysLong();
    # Assuming the locale is fr_FR, this would yield
    print $ref->[0], "\n"; # dim.

=head2 getDaysShort

Returns an array reference containing the 7 days of the week in their short representation.

    my $ref = $po->getDaysShort();
    # Assuming the locale is fr_FR, this would yield
    print $ref->[0], "\n"; # dimanche

=head2 getDomainHash

This takes an optional hash of parameters and return the global hash dictionary used by this class to store the localised data.

    # Will use the default domain as set in po.domain
    my $data = $po->getDomainHash();
    # Explicitly specify another domain
    my $data = $po->getDomainHash( domain => "net.example.api" );
    # Specify a domain and a locale
    my $po = $po->getDomainHash( domain => "com.example.api", locale => "ja_JP" );

Possible options are:

=over 4

=item * C<domain> The domain for the data, such as C<com.example.api>

=item * C<locale> The locale to return the associated dictionary.

=back

=head2 getLangDataPath

Contrary to its JavaScript equivalent, this takes no parameter. It returns the value of the environment variable C<TEXTLOCALEDIR> if found.

This is used internally during object instantiation when the I<path> parameter is not provided.

=head2 getLanguageDict

Provided with a locale, such as C<ja_JP> and this will return the dictionary for the current domain and the given locale.

=head2 getLocale

Returns the locale set for the current object, such as C<fr_FR> or C<ja_JP>

Locale returned are always formatted for the server-side, which means having an underscore rather than an hyphen like in the web environment.

=head2 getLocales

Provided with a C<msgid> (i.e. an original text) and this will call L</fetchLocale> and return those C<span> tags as a string containing their respective localised content, joined by a new line

=head2 getLocalesf

This is similar to L</getLocale>, except that it does a sprintf internally before returning the resulting value.

=head2 getMetaKeys

Returns an array of the meta field names used.

=head2 getMetaValue

Provided with a meta field name and this returns its corresponding value.

=head2 getMonthsLong

Returns an array reference containing the 12 months in their long representation.

    my $ref = $po->getMonthsLong();
    # Assuming the locale is fr_FR, this would yield
    print $ref->[0], "\n"; # janvier

=head2 getMonthsShort

Returns an array reference containing the 12 months in their short representation.

    my $ref = $po->getMonthsShort();
    # Assuming the locale is fr_FR, this would yield
    print $ref->[0], "\n"; # janv.

=head2 getNumericDict

Returns an hash reference containing the following properties:

    my $ref = $po->getNumericDict();

=over 4

=item * C<currency> string

Contains the usual currency symbol, such as C<€>, or C<$>, or C<¥>

=item * C<decimal> string

Contains the character used to separate decimal. In English speaking countries, this would typically be a dot.

=item * C<int_currency> string

Contains the 3-letters international currency symbol, such as C<USD>, or C<EUR> or C<JPY>

=item * C<negative_sign> string

Contains the negative sign used for negative number

=item * C<precision> integer

An integer whose value represents the fractional precision allowed for monetary context.

For example, in Japanese, this value would be 0 while in many other countries, it would be 2.

=item * C<thousand> string

Contains the character used to group and separate thousands.

For example, in France, it would be a space, such as :

    1 000 000,00

While in English countries, including Japan, it would be a comma :

    1,000,000.00

=back

=head2 getNumericPosixDict

Returns the full hash reference returned by L<POSIX/lconv>. It contains the following properties:

Here the values shown as example are for the locale C<en_US>

=over 4

=item * C<currency_symbol> string

The local currency symbol: C<$>

=item * C<decimal_point> string

The decimal point character, except for currency values, cannot be an empty string: C<.>

=item * C<frac_digits> integer

The number of digits after the decimal point in the local style for currency value: 2

=item * C<grouping>

The sizes of the groups of digits, except for currency values. unpack( "C*", $grouping ) will give the number

=item * C<int_curr_symbol> string

The standardized international currency symbol: C<USD>

=item * C<int_frac_digits> integer

The number of digits after the decimal point in an international-style currency value: 2

=item * C<int_n_cs_precedes> integer

Same as n_cs_precedes, but for internationally formatted monetary quantities: 1

=item * C<int_n_sep_by_space> integer

Same as n_sep_by_space, but for internationally formatted monetary quantities: 1

=item * C<int_n_sign_posn> integer

Same as n_sign_posn, but for internationally formatted monetary quantities: 1

=item * C<int_p_cs_precedes> integer

Same as p_cs_precedes, but for internationally formatted monetary quantities: 1

=item * C<int_p_sep_by_space> integer

Same as p_sep_by_space, but for internationally formatted monetary quantities: 1

=item * C<int_p_sign_posn> integer

Same as p_sign_posn, but for internationally formatted monetary quantities: 1

=item * C<mon_decimal_point> string

The decimal point character for currency values: C<.>

=item * C<mon_grouping>

Like grouping but for currency values.

=item * C<mon_thousands_sep> string

The separator for digit groups in currency values: C<,>

=item * C<n_cs_precedes> integer

Like p_cs_precedes but for negative values: 1

=item * C<n_sep_by_space> integer

Like p_sep_by_space but for negative values: 0

=item * C<n_sign_posn> integer

Like p_sign_posn but for negative currency values: 1

=item * C<negative_sign> string

The character used to denote negative currency values, usually a minus sign: C<->

=item * C<p_cs_precedes> integer

1 if the currency symbol precedes the currency value for nonnegative values, 0 if it follows: 1

=item * C<p_sep_by_space> integer

1 if a space is inserted between the currency symbol and the currency value for nonnegative values, 0 otherwise: 0

=item * C<p_sign_posn> integer

The location of the positive_sign with respect to a nonnegative quantity and the currency_symbol, coded as follows:

    0    Parentheses around the entire string.
    1    Before the string.
    2    After the string.
    3    Just before currency_symbol.
    4    Just after currency_symbol.

=item * C<positive_sign> string

The character used to denote nonnegative currency values, usually the empty string

=item * C<thousands_sep> string

The separator between groups of digits before the decimal point, except for currency values: C<,>

=back

=head2 getPlural

    my $str = $po->getPlural( $singular, $plural, $count, [ $domain ] );

Calls L<Text::PO/plural> and returns an array object (L<Module::Generic::Array>) with 2 elements.

Internal helper used by L</ngettext> and L</dngettext>. It applies the plural expression associated with the current (or given) domain/locale, selects the correct form, and returns a C<Text::PO::String>.

See L<Text::PO/plural> for more details.

=head2 getText

    my $str = $po->getText( $msgid );

Internal workhorse used by L</gettext> and domain-aware variants. 

Provided with an original string, and this will return its localised equivalent if it exists, or by default, it will return the original string.

Returns a C<Text::PO::String> as described elsewhere.

=head2 getTextf

    my $str = $po->getTextf( $msgid, @args );

Provided with an original string, and this will get its localised equivalent that wil be used as a template for the sprintf function. The resulting formatted localised content will be returned.

=head2 gettext

Provided with a C<msgid> represented by a string, and this return a localised version of the string, under the current domain and locale, if any is found and is translated, otherwise returns the C<msgid> that was provided.

    $po->gettext( "Hello" );
    # With locale of fr_FR, this would return "Bonjour"

See the global function L</_> for more information.

Note that as of version C<v0.5.0> of L<Text::PO>, this returns a C<Text::PO::String>, which is lightweight and stringifies automatically. It provides the benefit of tagging the string with the locale attached to it.

Thus, in the example above, the resulting C<Text::PO::String> would have its method C<locale> value set to C<fr_FR>, and you could do:

    my $localised = $po->gettext( "Hello" );
    say "Locale for this string is: ", $localised->locale;

If no locale string was found, C<locale> would be undefined.

=head2 gettextf

    my $str = $po->gettextf( $format, @args );

This is an alias to L</getTextf>

Like L</gettext>, but intended for printf-style formatting. It looks up C<$format> as the message id, then applies C<sprintf> to fill in C<@args>.

The returned object is still a L<Text::PO::String>; formatting is performed on the underlying string.

=head2 isSupportedLanguage

    if( $po->isSupportedLanguage( 'ja_JP' ) )
    {
        # Do something
    }

Provided with a locale such as C<fr-FR> or C<ja_JP> no matter whether an underscore or a dash is used, and this will return true if the locale has already been loaded and thus is supported. False otherwise.

=head2 language

Returns a string containing the value of the GNU PO file header C<Language>.

    $po->language();

=head2 languageTeam

Returns a string containing the value of the GNU PO file header C<Language-Team>.

    $po->languageTeam();

=head2 lastTranslator

Returns a string containing the value of the GNU PO file header C<Last-Translator>.

    $po->lastTranslator();

=head2 locale

    $po->locale( 'fr-FR' ); # or 'fr_FR' either is the same
    my $locale = $po->locale;

Returns the locale set in the object as a L<scalar object|Module::Generic::Scalar>. if sets, this will trigger the (re)load of po data by calling L</textdomain>

Note that this does not modify global environment variables such as C<LANGUAGE> or any process-wide locale; the change is strictly per-object.

=head2 locale_unix

    my $unix_locale = $po->locale_unix; # en_GB
    my $norm        = $po->locale_unix( 'en-gb' ); # becomes en_GB

Provided with a locale, such as C<en-GB> and this will return its equivalent formatted for server-side such as C<en_GB>

=head2 locale_web

    my $unix_locale = $po->locale_web; # en-GB
    my $norm        = $po->locale_web( 'en_gb' ); # becomes en-GB

Provided with a locale, such as C<en_GB> and this will return its equivalent formatted for the web such as C<en-GB>

=head2 mimeVersion

Returns a string containing the value of the header C<MIME-Version>.

    $po->mimeVersion();

=head2 ngettext

This perform plural-aware lookup.

Takes an original string (a.k.a message id), the plural version of that string, and an unsigned integer representing the applicable count, and this selects the appropriate translation according to the plural rules for the current locale/domain. For example:

    $po->ngettext( '%d comment awaiting moderation', '%d comments awaiting moderation', 12 );
    # Assuming the locale is ru_RU, this would return:
    # %d комментариев ожидают проверки

As with L</gettext>, the result is a C<Text::PO::String> which you can print directly or pass to C<sprintf>:

    printf $po->ngettext(
        '%d apple',
        '%d apples',
        $count,
    ), $count;

=head2 path

Sets or gets the filesystem path to the base directory containing the locale data:

    $po->path( '/locale' ); # /locale contains en_GB/LC_MESSAGES/com.example.api.mo for example

=head2 plural

    my $plural_def = $po->plural;
    $po->plural( [ $n, $expr ] );

Sets or gets the definition for plural for the current domain and locale. Usually you do not need to set this manually; it is derived from the PO metadata (C<Plural-Forms>).

It takes and returns an array reference of 2 elements:

=over 4

=item 0. An integer representing the various plural forms available, starting from 1

=item 1. An expression to be evaluated resulting in an offset for the right plural form. For example:

    n>1

or more complex for Russian:

    (n==1) ? 0 : (n%10==1 && n%100!=11) ? 3 : ((n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20)) ? 1 : 2)

=back

=head2 pluralForms

Returns a string containing the value of the header C<Plural-Forms>.

    $po->pluralForms();

=head2 po_object

Returns the L<Text::PO> object used.

=head2 poRevisionDate

Returns a string containing the value of the header C<PO-Revision-Date>.

    $po->poRevisionDate();

=head2 potCreationDate

Returns a string containing the value of the header C<POT-Creation-Date>.

    $po->potCreationDate();

=head2 projectIdVersion

Returns a string containing the value of the header C<Project-Id-Version>.

    $po->projectIdVersion();

=head2 reportBugsTo

Returns a string containing the value of the header C<Report-Msgid-Bugs-To>.

    $po->reportBugsTo();

=head2 textdomain

    $po->textdomain( $domain );

Given a string representing a domain, such as C<com.example.api> and this will load (or reload) the C<.json> (if the L</use_json> option is enabled), C<.po> or C<.mo> file found in that order.

Normally you do not need to call this directly; lookups such as L</gettext> will ensure the relevant domain is available.

Internally, domain data is cached in a per-class repository (using L<Module::Generic::Global>) so that repeated lookups for the same domain and locale are efficient and thread-safe.

=head2 use_json

    my $flag = $po->use_json; # 1
    $po->use_json(1);

Takes a boolean and if set, L<Text::PO::Gettext> will use a json po data if it exists, otherwise it will use a C<.po> file or a C<.mo> file in that order of preference.

=head2 _get_po

Returns the L<Text::PO> object used.

=head1 JAVASCRIPT COMPANION

This distribution provides a JavaScript companion library (see the C<share> directory in the L<Text::PO> distribution) that can read JSON-based PO data generated from your C<.po> or C<.mo> files. This makes it straightforward to share the same localisation data between Perl and browser-side code.

=head1 THREAD & PROCESS SAFETY

L<Text::PO::Gettext> is designed to be fully thread-safe and process-safe, ensuring data integrity across Perl ithreads and mod_perl’s threaded Multi-Processing Modules (MPMs) such as Worker or Event. It combines system-level file locking (C<flock>) with Perl-level synchronisation via L<Module::Generic::Global> to provide robust, system-wide thread-safe, and process-safe file operations.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Text::PO>, L<Text::PO::String>, L<Text::PO::Element>, L<Text::PO::MO>

L<https://www.gnu.org/software/gettext/manual/html_node/PO-Files.html>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021-2025 DEGUEST Pte. Ltd. DEGUEST Pte. Ltd.

=cut
