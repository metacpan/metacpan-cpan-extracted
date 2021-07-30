#!/usr/local/bin/perl
##----------------------------------------------------------------------------
## PO Files Manipulation - ~/scripts/po.pl
## Version v0.1.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/07/24
## Modified 2021/07/24
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use DateTime;
    use Getopt::Class;
    use IO::File;
    use Nice::Try;
    use Pod::Usage;
    use Text::PO;
    use Text::PO::MO;
    use Text::Wrap ();
    our $PLURALS = {};
    our $VERSION = 'v0.1.0';
};

{
    our $DEBUG   = 0;
    our $VERBOSE = 0;
    our $LOG_LEVEL = 0;
    our $PROG_NAME = 'po';
    
    our $out  = IO::File->new;
    $out->fdopen( fileno( STDOUT ), 'w' );
    $out->binmode( ':utf8' );
    $out->autoflush( 1 );
    
    our $err = IO::File->new;
    $err->autoflush( 1 );
    $err->fdopen( fileno( STDERR ), 'w' );
    $err->binmode( ":utf8" );
    
    &_load_plurals();
    
    my $dict =
    {
    # Actions
    as_json             => { type => 'boolean' },
    as_po               => { type => 'boolean' },
    add                 => { type => 'boolean' },
    compile             => { type => 'boolean' },
    dump                => { type => 'boolean' },
    init                => { type => 'boolean' },
    
    # Attributes
    bugs_to             => { type => 'string', class => [qw( init meta )] },
    charset             => { type => 'string', class => [qw( init meta )], default => 'utf-8' },
    created_on          => { type => 'datetime', class => [qw( init meta )] },
    domain              => { type => 'string' },
    encoding            => { type => 'string', class => [qw( init meta )], default => '8bit' },
    header              => { type => 'string' },
    lang                => { type => 'string', alias => [qw( language )], class => [qw( init meta )], re => qr/^[a-z]{2}(?:_[A-Z]{2})?$/ },
    msgid               => { type => 'string', class => [qw( edit )] },
    msgstr              => { type => 'string', class => [qw( edit )] },
    output              => { type => 'string' },
    output_dir          => { type => 'string' },
    overwrite           => { type => 'boolean', default => 0 },
    po_debug            => { type => 'integer', default => 0 },
    # Used as a template to create the po file with --init
    pot                 => { type => 'string', class => [qw( init )] },
    project             => { type => 'string', class => [qw( init meta )] },
    revised_on          => { type => 'datetime', class => [qw( init meta )] },
    team                => { type => 'string', class => [qw( init meta )] },
    settings            => { type => 'string' },
    translator          => { type => 'string', class => [qw( init meta )] },
    tz                  => { type => 'string', alias => [qw( time_zone timezone )], class => [qw( init meta )] },
    version             => { type => 'string', class => [qw( init meta )] },

    ## Generic options
    quiet               => { type => 'boolean', default => 0 },
    debug               => { type => 'integer', alias => [qw(d)], default => \$DEBUG },
    verbose             => { type => 'integer', default => \$VERBOSE },
    v                   => { type => 'code', code => sub{ printf( STDOUT "2f\n", $VERSION ); } },
    help                => { type => 'code', alias => [qw(?)], code => sub{ pod2usage(1); } },
    man                 => { type => 'code', code => sub{ pod2usage( -exitstatus => 0, -verbose => 2 ); } },
    };
    
    our $opt = Getopt::Class->new({ dictionary => $dict }) || die( "Error instantiating Getopt::Class object: ", Getopt::Class->error, "\n" );
    $opt->usage( sub{ pod2usage(2) } );
    our $opts = $opt->exec || die( "An error occurred executing Getopt::Class: ", $opt->error, "\n" );

    ## Unless the log level has been set directly with a command line option
    unless( $LOG_LEVEL )
    {
        $LOG_LEVEL = 1 if( $VERBOSE );
        $LOG_LEVEL = ( 1 + $DEBUG ) if( $DEBUG );
    }
    
    my @errors = ();
    my $opt_errors = $opt->configure_errors;
    push( @errors, @$opt_errors ) if( $opt_errors->length );
    if( $opts->{quiet} )
    {
        $DEBUG = $VERBOSE = 0;
    }
    
    $out->print( @errors ? " not ok\n" : " ok\n" ) if( $LOG_LEVEL );
    if( @errors )
    {
        my $error = join( "\n", map{ "\t* $_" } @errors );
        substr( $error, 0, 0, "\n\tThe following arguments are mandatory and missing.\n" );
        $out->print( <<EOT ) if( !$opts->{ 'quiet' } );
    $error
    Please, use option '-h' or '--help' to find out and properly call
    this program in interactive mode:
    
    $PROG_NAME -h
EOT
        exit(1);
    }
    
    if( $opts->{compile} && $opts->{output} )
    {
        my $f = shift( @ARGV ) || bailout( "No po file to read was provided.\n" );
        &compile( in => $f, out => $opts->{output} );
    }
    elsif( $opts->{init} )
    {
        my $out = $opts->{output} || shift( @ARGV ) || bailout( "No po file path was specified to initiate.\n" );
        &init_po( $out );
    }
    elsif( $opts->{as_json} && $opts->{output} )
    {
        my $f = shift( @ARGV ) || bailout( "No po file to read was provided.\n" );
        _message( 3, "Reading file \"$f\" and writing to \"$opts->{output}\"." );
        &to_json( in => $f, out => $opts->{output} );
    }
    elsif( $opts->{as_po} && $opts->{output} )
    {
        my $f = shift( @ARGV ) || bailout( "No (json) po file to read was provided.\n" );
        _message( 3, "Reading file \"$f\" and writing to \"$opts->{output}\"." );
        &to_po( in => $f, out => $opts->{output} );
    }
    elsif( $opts->{add} )
    {
        my $f = shift( @ARGV ) || bailout( "No po file to read was provided.\n" );
        &add( in => $f );
    }
    else
    {
        foreach my $f ( @ARGV )
        {
            $out->print( "Processing file \"$f\"\n" );
            my $po = Text::PO->new( debug => $opts->{po_debug} );
            # $po->debug( 3 );
            $po->parse( $f ) || bailout( $po->error, "\n" );
            if( $opts->{dump} )
            {
                _messagec( 3, "Dumping file <green>$f</>" );
                $po->dump( $out );
                next;
            }
            elsif( $opts->{as_json} )
            {
                my $new = $opt->new_file( $f );
                $new->extension( 'po.json' );
                &to_json( in => $f, out => $new );
            }
            elsif( $opts->{compile} && $opts->{output_dir} )
            {
                my $file = $opt->new_file( $f );
                my $parent = $file->parent;
                # my $domain = $opts->{domain} ? $opts->{domain} : $file->basename( qr/\.(.*?)$/ );
                my $domain = $po->domain || bailout( "Unable to get the domain from the po file \"$f\"\n" );
                my $out    = $file->join( $parent, "${domain}.mo" );
                &compile( in => $f, out => $out );
            }
        }
    }
    exit(0);
}

sub add
{
    my $p = $opt->_get_args_as_hash( @_ );
    my $f = $p->{in} || bailout( "No po file to read was specified.\n" );
    $f = $opt->new_file( $f );
    if( $f->extension eq 'po' )
    {
        my $p = 
        {
        debug => $opts->{debug},
        };
        $p->{domain} = $opts->{domain} if( length( $opts->{domain} ) );
        $po = Text::PO->new( %$p ) || bailout( Text::PO->error );
        $po->parse( $f ) || bailout( $po->error );
    }
    elsif( $f->extension eq 'json' )
    {
        my $p = 
        {
        use_json => 1,
        debug => $opts->{debug},
        };
        $p->{domain} = $opts->{domain} if( length( $opts->{domain} ) );
        $po = Text::PO->new( %$p ) || bailout( Text::PO->error );
        $po->parse2object( $f ) || bailout( $po->error );
    }
    else
    {
        bailout( "Unknown source file \"$f\"" );
    }
    _messagec( 3, "Adding id \"<green>$opts->{msgid}</>\" -> \"<green>$opts->{msgstr}</>\"" );
    $po->add_element(
        msgid => "$opts->{msgid}",
        msgstr => "$opts->{msgstr}",
    ) || bailout( $po->error );
    _messagec( 3, "Synchronisation back to \"<green>$f</>\"" );
    $po->sync( $f ) || bailout( $po->error );
    _messagec( 3, "<green>Done.</>" );
    return(1);
}

sub bailout
{
    $err->print( @_, "\n" );
    exit(1);
}

sub compile
{
    my $p = $opt->_get_args_as_hash( @_ );
    my $f = $p->{in} || bailout( "No po file to read was specified.\n" );
    my $o = $p->{out} || bailout( "No mo file to write to was specified.\n" );
    $f = $opt->new_file( $f );
    my $po;
    if( $f->extension() eq 'mo' )
    {
        &bailout( "The source file \"$f\" is already a mo file. You can simply copy it yourself." );
    }
    elsif( $f->extension eq 'po' )
    {
        my $p = 
        {
        debug => $opts->{po_debug},
        };
        $p->{domain} = $opts->{domain} if( length( $opts->{domain} ) );
        $po = Text::PO->new( $p ) || bailout( Text::PO->error );
        $po = $po->parse( $f );
        bailout( "This does not look like a po file" ) if( !$po->elements->length );
    }
    elsif( $f->extension eq 'json' )
    {
        my $p = 
        {
        use_json => 1,
        debug => $opts->{po_debug},
        };
        $p->{domain} = $opts->{domain} if( length( $opts->{domain} ) );
        $po = Text::PO->new( %$p ) || bailout( Text::PO->error );
        $po->parse2object( $f ) || bailout( $po->error );
    }
    else
    {
        bailout( "Unknown source file \"$f\"" );
    }
    # Exchange a string for a Module::Generic::File object
    $o = $opt->new_file( $o );
    _message( 3, "Saving data to mo file \"$o\"." );
    my $mo = Text::PO::MO->new( $o, debug => $opts->{debug} );
    $o->parent->mkpath;
    $mo->write( $po ) || bailout( "Unable to write to \"$o\": ", $mo->error, "\n" );
    return(1);
}

sub init_po
{
    my $out = shift( @_ );
    $out = $opt->new_file( $out );
    if( $out->exists && !$opts->{overwrite} )
    {
        bailout( "An output file with the same name \"$out\" already exists. If you want to overwrite it, please use the --overwrite option\n" );
    }
    if( !$opts->{lang} )
    {
        bailout( "No language code was specified.\n" );
    }
    elsif( !$opts->{domain} )
    {
        bailout( "No domain for the po file was provided." );
    }
    
    my $p = {};
    my $fields = [qw( bugs_to charset created_on encoding header lang project revised_on team translator tz version )];
    my $maps =
    {
    bugs_to => 'Report-Msgid-Bugs-To',
    created_on => 'POT-Creation-Date',
    revised_on => 'PO-Revision-Date',
    translator => 'Last-Translator',
    team => 'Language-Team',
    lang => 'Language',
    plural => 'Plural-Forms',
    content_Type => 'Content-Type',
    transfer_encoding => 'Content-Transfer-Encoding',
    };
    
    if( $opts->{settings} )
    {
        my $f = $opt->new_file( $opts->{settings} );
        bailout( "Settings json file specified \"$opts->{settings}\" does not exist.\n" ) if( !$f->exists );
        try
        {
            my $data = $f->load;
            my $j = JSON->new->utf8->relaxed;
            my $json = $j->decode( $data );
            foreach my $k ( @$fields )
            {
                # command line options take priority
                next if( defined( $opts->{ $k } ) && length( $opts->{ $k } ) );
                $opts->{ $k } = $json->{ $k } if( exists( $json->{ $k } ) );
            }
        }
        catch( $e )
        {
            warn( "An error occurred while trying to decode json data from file \"$opts->{settings}\": $e\n" );
            return;
        }
    }
    
    my $po = Text::PO->new( debug => $opts->{debug} );
    if( $opts->{pot} )
    {
        my $pot = $opt->new_file( $opts->{pot} );
        bailout( "The pot file specified \"$pot\" does not exist.\n" ) if( !$pot->exists );
        $po->parse( $pot ) ||
        bailout( "Error while reading pot file \"$pot\": ", $po->error, "\n" );
        
    }
    if( $opts->{header} )
    {
        local $Text::Wrap::columns = 80;
        my $lines = [split( /\n/, $opts->{header} )];
        for( my $i = 0; $i < scalar( @$lines ); $i++ )
        {
            if( length( $lines->[$i] ) > 80 )
            {
                my $new = Text::Wrap::wrap( '', '', $lines->[$i] );
                my $newLines = [split( /\n/, $new )];
                splice( @$lines, $i, 1, @$newLines );
                $i += scalar( @$newLines ) - 1;
            }
        }
        $po->header( $lines );
    }

    my $vers = $opts->{version} ? $opts->{version} : '1.0';
    $po->meta( 'Project-Id-Version' => sprintf( '%s %.1f', ( $opts->{project} || 'PROJECT' ), $vers ) );
    if( $opts->{charset} )
    {
        $po->meta( content_type => sprintf( 'text/plain; charset=%s', ( $opts->{charset} || 'utf-8' ) ) );
    }
    my $plur;
    if( exists( $PLURALS->{ $opts->{lang} } ) )
    {
        $plur = $PLURALS->{ $opts->{lang} };
    }
    elsif( exists( $PLURALS->{ substr( $opts->{lang}, 0, 2 ) } ) )
    {
        $plur = $PLURALS->{ substr( $opts->{lang}, 0, 2 ) };
    }
    else
    {
        warn( "Unknow language \"$opts->{lang}\" to find out about its plural form\n" );
    }
    $po->meta( $maps->{plural} => sprintf( 'nplurals=%d; plural=%s;', @$plur ) );
    $po->domain( $opts->{domain} ) if( $opts->{domain} );
    foreach my $t ( qw( created_on revised_on ) )
    {
        my $dt;
        if( $opts->{ $t } )
        {
            $dt = $opts->{ $t };
        }
        else
        {
            $dt = DateTime->now( time_zone => ( $opts->{tz} || 'local' ) );
        }
        $po->meta( $maps->{ $t } => $dt->strftime( '%F %T%z' ) );
    }
    
    foreach my $k ( @$fields )
    {
        next unless( length( $opts->{ $k } ) );
        if( !exists( $maps->{ $k } ) )
        {
            # warn( "Field \"$k\" does not exist in our map table. This is a bug.\n" );
            next;
        }
        $po->meta( $maps->{ $k } => $opts->{ $k } );
    }
    
    $po->dump if( $opts->{debug} );
    
    my $binmode = ( $opts->{charset} || 'utf-8' );
    $binmode = 'utf8' if( lc( $binmode ) eq 'utf-8' );
    my $fh = $out->open( '>', { binmode => $binmode } ) || bailout( "Unable to open the output file in write mode: ", $out->error, "\n" );
    $fh->autoflush(1);
    $po->dump( $fh );
    $fh->close;
    return(1);
}

sub to_json
{
    my $p = $opt->_get_args_as_hash( @_ );
    my $f = $p->{in} || bailout( "No po file to read was specified.\n" );
    my $o = $p->{out} || bailout( "No mo file to write to was specified.\n" );
    $f = $opt->new_file( $f );
    my $po;
    if( $f->extension() eq 'json' )
    {
        &bailout( "The source file \"$f\" is already a json file. You can simply copy it yourself." );
    }
    elsif( $f->extension eq 'mo' )
    {
        my $p = 
        {
        debug => $opts->{debug},
        };
        $p->{domain} = $opts->{domain} if( length( $opts->{domain} ) );
        my $mo = Text::PO::MO->new( $f, $p );
        $po = $mo->as_object;
    }
    elsif( $f->extension eq 'po' )
    {
        my $p = 
        {
        debug => $opts->{debug},
        };
        $p->{domain} = $opts->{domain} if( length( $opts->{domain} ) );
        $po = Text::PO->new( %$p ) || bailout( Text::PO->error );
        $po->parse( $f ) || bailout( $po->error );
    }
    else
    {
        bailout( "Unknown source file \"$f\"" );
    }
    
    my $json = $po->as_json({ pretty => 1, canonical => 1 });
    _messagec( 3, "<red>", $po->error, "</>" ) if( !$json );
    my $fh;
    if( $o eq '-' )
    {
        $fh = IO::File->new;
        $fh->fdopen( fileno( STDOUT ), 'w' );
        $fh->binmode( ":utf8" );
        $fh->autoflush(1);
    }
    else
    {
        _messagec( 3, "<green>", $po->elements->length, "</> elements found." );
        _messagec( 3, "Saving as json file to <green>${o}</>" );
        $o = $opt->new_file( $o );
        $o->parent->mkpath;
        $fh = $o->open( '>', { binmode => ':utf8' }) || bailout( "Unable to open output file \"$o\" in write mode: $!\n" );
        $fh->autoflush(1);
    }
    # _message( 3, "Saving json '$json'" );
    $fh->print( $json );
    $fh->close unless( $o eq '-' );
    return(1);
}

sub to_po
{
    my $p = $opt->_get_args_as_hash( @_ );
    my $f = $p->{in} || bailout( "No po file to read was specified.\n" );
    my $o = $p->{out} || bailout( "No mo file to write to was specified.\n" );
    $f = $opt->new_file( $f );
    my $po;
    if( $f->extension() eq 'po' )
    {
        &bailout( "The source file \"$f\" is already a po file. You can simply copy it yourself." );
    }
    elsif( $f->extension eq 'mo' )
    {
        my $p = {};
        $p->{domain} = $opts->{domain} if( length( $opts->{domain} ) );
        my $mo = Text::PO::MO->new( $f, $p );
        $po = $mo->as_object || _messagec( 3, "<red>", $mo->error, "</>" );
    }
    elsif( $f->extension eq 'json' )
    {
        my $p = 
        {
        use_json => 1,
        debug => $opts->{debug},
        };
        $p->{domain} = $opts->{domain} if( length( $opts->{domain} ) );
        $po = Text::PO->new( %$p ) || bailout( Text::PO->error );
        $po->parse2object( $f ) || bailout( $po->error );
    }
    else
    {
        bailout( "Unknown source file \"$f\"" );
    }
    my $fh;
    if( $o eq '-' )
    {
        $fh = IO::File->new;
        $fh->fdopen( fileno( STDOUT ), 'w' );
        $fh->binmode( ":utf8" );
        $fh->autoflush(1);
    }
    else
    {
        _messagec( 3, "Saving as json file to <green>${o}</>" );
        $o = $opt->new_file( $o );
        $o->parent->mkpath;
        $fh = $o->open( '>', { binmode => ':utf8' }) || bailout( "Unable to open output file \"$o\" in write mode: $!\n" );
    }
    $po->dump( $fh );
    $fh->close unless( $o eq '-' );
    return(1);
}

sub _load_plurals
{
    # Ref: <http://www.gnu.org/software/gettext/manual/html_node/Plural-forms.html>
    # <https://www.fincher.org/Utilities/CountryLanguageList.shtml>
    # <http://docs.translatehouse.org/projects/localization-guide/en/latest/l10n/pluralforms.html>
    our $PLURALS = 
    {
    # Afrikaans
    af      => [2, "(n != 1)"],
    # Akan
    ak      => [2, "(n > 1)"],
    # Aragonese
    an      => [2, "(n != 1)"],
    # Arabic
    ar      => [6, "n==0 ? 0 : n==1 ? 1 : n==2 ? 2 : n%100>=3 && n%100<=10 ? 3 : n%100>=11 ? 4 : 5"],
    # Assamese
    as      => [2, "(n != 1)"],
    # Aymará
    ay      => [2, 0],
    # Azerbaijani
    az      => [2, "(n != 1)"],
    # Belarusian
    be      => [2, "(n%10==1 && n%100!=11 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2)"],
    # Belarusian
    be_BY   => [3, "n%10==1 && n%100!=11 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2"],
    # Bulgarian
    bg      => [2, "(n != 1)"],
    # Bengali
    bn      => [2, ""],
    # Tibetan
    bo      => [1,0],
    # Breton
    br      => [2, "(n > 1)"],
    # Bosnian
    bs      => [3, "(n%10==1 && n%100!=11 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2)"],
    # Catalan
    ca      => [2, "(n != 1)"],
    # Czech
    cs_CZ   => [3, "plural=(n==1) ? 0 : (n>=2 && n<=4) ? 1 : 2"],
    # Slavic Bulgarian
    cu_BG   => [2, "n != 1"],
    # Welsh
    cy      => [4, "(n==1) ? 0 : (n==2) ? 1 : (n != 8 && n != 11) ? 2 : 3"],
    # Danish
    da_DK   => [2, "n != 1"],
    de      => [2, "n != 1"],
    de_DE   => [2, "n != 1"],
    # Dzongkha
    dz      => [1,0],
    # Greece
    el_GR   => [2, "n != 1"],
    en      => [2, "n != 1"],
    en_GB   => [2, "n != 1"],
    en_US   => [2, "n != 1"],
    # Esperanto
    eo      => [2, "n != 1"],
    es      => [2, "n != 1"],
    es_ES   => [2, "n != 1"],
    # Estonian
    et_EE   => [2, "n != 1"],
    # Basque
    eu      => [2, "(n != 1)"],
    # Persian
    fa      => [2, "(n > 1)"],
    # Fulah
    ff      => [2, "(n != 1)"],
    # Finland
    fi_FI   => [2, "n != 1"],
    # Faroese
    fo_FO   => [2, "n != 1"],
    fr      => [2, "n>1"],
    fr_FR   => [2, "n>1"],
    # Frisian
    fy      => [2, "(n != 1)"],
    # Irish in UK
    ga_GB   => [3, "n==1 ? 0 : n==2 ? 1 : 2"],
    # Irish in Ireland
    ga_IE   => [3, "n==1 ? 0 : n==2 ? 1 : 2"],
    # Galician
    gl      => [2, "(n != 1)"],
    # Gujarati
    gu      => [2, "(n != 1)"],
    # Hausa
    ha      => [2, "(n != 1)"],
    he_IL   => [2, "n != 1"],
    # Hindi
    hi      => [2, "(n != 1)"],
    # Croatian
    hr_HR   => [3, "n%10==1 && n%100!=11 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2"],
    # Hungarian (Finno-Ugric family)
    hu_HU   => [2, "n != 1"],
    # Armenian
    hy      => [2, "(n != 1)"],
    # Interlingua
    ia      => [2, "(n != 1)"],
    # Bahasa Indonesian
    id_ID   => [2, "n != 1"],
    # Icelandic
    is      => [2, "(n%10!=1 || n%100==11)"],
    it      => [2, "n != 1"],
    it_IT   => [2, "n != 1"],
    ja_JP   => [1, 0],
    # Javanese
    jv      => [2, "(n != 0)"],
    # Kazakh
    kk      => [2, "(n != 1)"],
    # Greenlandic
    kl      => [2, "(n != 1)"],
    # Khmer
    km      => [1, 0],
    # Kannada
    kn      => [2, "(n != 1)"],
    ko_KR   => [1, 0],
    # Kurdish
    ku      => [2, "(n != 1)"],
    # Cornish
    kw      => [4, "(n==1) ? 0 : (n==2) ? 1 : (n == 3) ? 2 : 3"],
    # Kyrgyz
    ky      => [2, "(n != 1)"],
    # Letzeburgesch
    lb      => [2, "(n != 1)"],
    # Lingala
    ln      => [2, "(n > 1)"],
    # Lao
    lo      => [1, 0],
    # Lithuanian (Baltic family)
    lt_LT   => [3, "n%10==1 && n%100!=11 ? 0 : n%10>=2 && (n%100<10 || n%100>=20) ? 1 : 2"],
    # Latvia
    lv_LV   => [3, "n%10==1 && n%100!=11 ? 0 : n != 0 ? 1 : 2"],
    # Montenegro
    me      => [3, "n%10==1 && n%100!=11 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2"],
    # Malagasy
    mg      => [2, "(n > 1)"],
    # Maori
    mi      => [2, "(n > 1)"],
    # Macedonian
    mk      => [2, "n==1 || n%10==1 ? 0 : 1"],
    # Malayalam
    ml      => [2, "(n != 1)"],
    # Mongolian
    mn      => [2, "(n != 1)"],
    # Marathi
    mr      => [2, "(n != 1)"],
    # Malay
    ms      => [1, 0],
    # Maltese
    mt      => [4, "(n==1 ? 0 : n==0 || ( n%100>1 && n%100<11) ? 1 : (n%100>10 && n%100<20 ) ? 2 : 3)"],
    # Burmese
    my      => [1, 0],
    # Norwegian Bokmal
    nb      => [2, "(n != 1)"],
    # Nepali
    ne      => [2, "(n != 1)"],
    nl      => [2, "n != 1"],
    nl_NL   => [2, "n != 1"],
    # Norwegian Nynorsk
    nn      => [2, "(n != 1)"],
    # Norwegian
    no_NO   => [2, "n != 1"],
    # Occitan
    oc      => [2, "(n > 1)"],
    # Oriya
    or      => [2, "(n != 1)"],
    # Punjabi
    pa      => [2, "(n != 1)"],
    # Polish
    pl_PL   => [3, "n==1 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2"],
    # Pashto
    ps      => [2, "(n != 1)"],
    # Brazilian Portugese
    pt      => [2, "n != 1"],
    pt_BR   => [2, "n>1"],
    pt_PT   => [2, "n != 1"],
    # Romansh
    rm      => [2, "(n != 1)"],
    # Romanian
    ro_RO   => [3, "n==1 ? 0 : (n==0 || (n%100 > 0 && n%100 < 20)) ? 1 : 2"],
    # Russian
    ru      => [3, "n%10==1 && n%100!=11 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2"],
    ru_RU   => [3, "n%10==1 && n%100!=11 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2"],
    # Kinyarwanda
    rw      => [2, "(n != 1)"],
    # Sindhi
    sd      => [2, "(n != 1)"],
    # Northern Sami
    se      => [2, "(n != 1)"],
    # Sinhala
    si      => [2, "(n != 1)"],
    # Slovak
    sk_SK   => [3, "plural=(n==1) ? 0 : (n>=2 && n<=4) ? 1 : 2"],
    # Slovenian
    sl_SI   => [4, "n%100==1 ? 0 : n%100==2 ? 1 : n%100==3 || n%100==4 ? 2 : 3"],
    # Somali
    so      => [2, "(n != 1)"],
    # Albanian
    sq      => [2, "(n != 1)"],
    # Serbian
    sr_RS   => [3, "n%10==1 && n%100!=11 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2"],
    # Sundanese
    su      => [1, 0],
    # Sweden
    sv      => [2, "n != 1"],
    sv_SE   => [2, "n != 1"],
    # Swedish
    sw      => [2, "(n != 1)"],
    # Tamil
    ta      => [2, "(n != 1)"],
    # Telugu
    te      => [2, "(n != 1)"],
    # Tajik
    tg      => [2, "(n > 1);"],
    th_TH   => [1, 0],
    # Tigrinya
    ti      => [2, "(n > 1)"],
    # Turkmen
    tk      => [2, "(n != 1)"],
    # Turkey
    tr_TR   => [2, "n != 1"],
    # Tatar
    tt      => [1, 0],
    # Uyghur
    ug      => [1, 0],
    # Ukrainian
    uk_UA   => [3, "n%10==1 && n%100!=11 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2"],
    # Urdu
    ur      => [2, "(n != 1)"],
    # Uzbek
    uz      => [2, "(n > 1)"],
    # Vietnamese
    vi_VN   => [1, 0],
    # Walloon
    wa      => [2, "(n > 1)"],
    # Wolof
    wo      => [1, 0],
    # Yoruba
    yo      => [2, "(n != 1)"],
    # Chinese
    zh      => [1, 0],
    };
}

sub _message
{
    my $required_level;
    if( $_[0] =~ /^\d{1,2}$/ )
    {
        $required_level = shift( @_ );
    }
    else
    {
        $required_level = 0;
    }
    return if( !$LOG_LEVEL || $LOG_LEVEL < $required_level );
    my $msg = join( '', map( ref( $_ ) eq 'CODE' ? $_->() : $_, @_ ) );
    my $frame = 0;
    $frame++ if( (caller(1))[3] =~ /_messagec/ );
    my( $pkg, $file, $line ) = caller( $frame );
    my $sub = ( caller( $frame + 1 ) )[3];
    my $sub2 = substr( $sub, rindex( $sub, '::' ) + 2 );
    return( $err->print( "${pkg}::${sub2}() [$line]: $msg\n" ) );
}

sub _messagec
{
    my $required_level;
    if( $_[0] =~ /^\d{1,2}$/ )
    {
        $required_level = shift( @_ );
    }
    else
    {
        $required_level = 0;
    }
    return( _message( $required_level, $opt->colour_parse( @_ ) ) );
}

__END__

=encoding utf8

=head1 NAME

po - GNU PO file manager

=head1 SYNOPSIS

    po [ --debug|--nodebug, --verbose|--noverbose, -v, --help, --man]

    Options
    
    Basic options:
    --as-po                 Write the file as a po file
    --as-json               Write the po file as json on the STDOUT
    --compile               Create a machine object file (.mo)
    --domain                The po file domain
    --dump                  Dump the PO file in a format suitable for a .po file
    --init                  Create an initial po file such as .pot
    
    --bugs-to               Sets the value for the meta field C<Report-Msgid-Bugs-To>
    --charset               Sets the character encoding value in C<Content-Type>
    --created-on            Sets the value for the meta field C<POT-Creation-Date>
    --domain                The domain, such as C<com.example.api>
    --encoding              Sets the value for the meta field C<Content-Transfer-Encoding>
    --header                The string to be used as the header for the C<.po> file only.
    --lang                  The locale to use, such as en_US
    --output                The output file
    --output-dir            Output directory
    --overwrite             Boolean. If true, this will allow overwriting existing file
    --po-debug              Integer representing the debug value to be passed to L<Text::PO>
    --pot                   The C<.pot> file to be used as a template in conjonction with --init
    --project               Sets the value for the meta field C<Project-Id-Version>
    --revised-on            Sets the value for the meta field C<PO-Revision-Date>
    --settings              The settings json file containing default values
    --team                  Sets the value for the meta field C<Language-Team>
    --translator            Sets the value for the meta field C<Last-Translator>
    --tz, --time-zone, --timezone Sets the time zone to use for the date in C<PO-Revision-Date> and C<POT-Creation-Date>
    --version               Sets the version to be used in the meta field C<Project-Id-Version>
    
    Standard options:
    -h, --help              display this help and exit
    -v                      display version information and exit
    --debug                 Enable debug mode
    --nodebug               Disable debug mode
    --help, -?              Show this help
    --man                   Show this help as a man page
    --verbose               Enable verbose mode
    --noverbose             Disable verbose mode

=head1 OPTIONS

=head2 --as-json

Takes a po file and transcode it as a json po file

    po --as-json --output fr_FR/LC_MESSAGES/com.example.api.json fr_FR.po

=head2 --as-po

Takes a C<.mo> or C<.json> file and transcode it to a po file

    po --as-po --output fr_FR.po ./fr_FR/com.example.api.json

=head2 --dump

Dump the data contained as a GNU PO file to the STDOUT

    po --dump /some/file.po >new_file.po
    # Maybe?
    diff /some/file.po new_file.po

=head2 --output-dir

The output directory. For example to read multiple po file and create their related mo files under a given directory:

    po --compile --output-dir ./en_GB/LC_MESSAGES en_GB.*.po

This will read all the po files for language en_GB as selected in write their related mo files under C<./en_GB/LC_MESSAGES>. This directory will be created if it does not exist. The domain will be derived from the po file.

=head2 --help

Print a short help message.

=head2 --debug

Enable debug mode with considerable verbosity

=head2 --nodebug

Disable debug mode.

=head2 --verbose

Enable verbose mode.

=head2 --noverbose

Disable verbose mode.

=head2 --man

Print this help as man page.

=head1 DESCRIPTION

B<This program> takes optional parameters and process GNU PO files.

GNU PO files are localisation or l10n files. They can be used as binary after been compiled, or they can be converted to json using this utility which then can read the json data instead of parsing the po files, making it faster to load.

=head1 EXAMPLE

    po [--dump, --debug|--nodebug, --verbose|--noverbose, -v, --help, --man] /some/file.po

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT

Copyright (c) 2020-2021 DEGUEST Pte. Ltd.

=cut
