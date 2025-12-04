#!/usr/local/bin/perl
##----------------------------------------------------------------------------
## PO Files Manipulation - ~/lib//mnt/src/perl/Text-PO/scripts/po.pl
## Version v0.3.0
## Copyright(c) 2024 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/07/24
## Modified 2025/12/01
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
BEGIN
{
    use strict;
    use warnings;
    use lib './lib'; # REMOVE ME
    use DateTime;
    use Getopt::Class;
    use IO::File;
    use Pod::Usage;
    use Text::PO;
    use Text::PO::MO;
    use Text::Wrap ();
    our $PLURALS = {};
    our $VERSION = 'v0.3.0';
};

{
    our $DEBUG   = 0;
    our $VERBOSE = 0;
    our $LOG_LEVEL = 0;
    our $PROG_NAME = 'po';

    our $out  = IO::File->new;
    $out->fdopen( fileno( STDOUT ), 'w' );
    $out->binmode( ':utf8' );
    $out->autoflush(1);

    our $err = IO::File->new;
    $err->autoflush(1);
    $err->fdopen( fileno( STDERR ), 'w' );
    $err->binmode( ":utf8" );

    &_load_plurals();

    my $dict =
    {
        # Actions
        as_json             => { type => 'boolean' },
        as_po               => { type => 'boolean' },
        add                 => { type => 'boolean' },
        add_include         => { type => 'boolean' },
        compile             => { type => 'boolean' },
        dump                => { type => 'boolean' },
        init                => { type => 'boolean' },
        pp                  => { type => 'boolean', alias => [qw( pre-processing )] },
        sync                => { type => 'boolean' },

        # Attributes
        after               => { type => 'string' },
        before              => { type => 'string' },
        bugs_to             => { type => 'string', class => [qw( init meta )] },
        charset             => { type => 'string', class => [qw( init meta )], default => 'utf-8' },
        created_on          => { type => 'datetime', class => [qw( init meta )] },
        domain              => { type => 'string' },
        encoding            => { type => 'string', class => [qw( init meta )], default => '8bit' },
        # Used for includes
        file                => { type => 'string' },
        header              => { type => 'string' },
        include             => { type => 'boolean' },
        lang                => { type => 'string', alias => [qw( language )], class => [qw( init meta )], re => qr/^[a-z]{2}(?:_[A-Z]{2})?$/ },
        max_recurse         => { type => 'integer', default => 0 },
        msgid               => { type => 'string', class => [qw( edit )] },
        msgstr              => { type => 'string', class => [qw( edit )] },
        output              => { type => 'file' },
        output_dir          => { type => 'file' },
        overwrite           => { type => 'boolean', default => 0 },
        po_debug            => { type => 'integer', default => 0 },
        # Used as a template to create the po file with --init
        pot                 => { type => 'string', class => [qw( init )] },
        project             => { type => 'string', class => [qw( init meta )] },
        revised_on          => { type => 'datetime', class => [qw( init meta )] },
        settings            => { type => 'string' },
        team                => { type => 'string', class => [qw( init meta )], alias => [qw( language-team )] },
        translator          => { type => 'string', class => [qw( init meta )] },
        tz                  => { type => 'string', alias => [qw( time_zone timezone )], class => [qw( init meta )] },
        version             => { type => 'string', class => [qw( init meta )] },

        # Generic options
        quiet               => { type => 'boolean', default => 0 },
        debug               => { type => 'integer', alias => [qw(d)], default => \$DEBUG },
        verbose             => { type => 'integer', default => \$VERBOSE },
        v                   => { type => 'code', code => sub{ printf( STDOUT "2f\n", $VERSION ); } },
        help                => { type => 'code', alias => [qw(?)], code => sub{ pod2usage( -exitstatus => 1, -verbose => 99, -sections => [qw( NAME SYNOPSIS DESCRIPTION MODES OPTIONS AUTHOR COPYRIGHT )] ); }, action => 1 },
        man                 => { type => 'code', code => sub{ pod2usage( -exitstatus => 0, -verbose => 2 ); } },
    };

    our $opt = Getopt::Class->new({ dictionary => $dict }) || die( "Error instantiating Getopt::Class object: ", Getopt::Class->error, "\n" );
    $opt->usage( sub{ pod2usage(2) } );
    our $opts = $opt->exec || die( "An error occurred executing Getopt::Class: ", $opt->error, "\n" );

    # Unless the log level has been set directly with a command line option
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
        if( !$opts->{quiet} )
        {
            $out->print( <<EOT );
    $error
    Please, use option '-h' or '--help' to find out and properly call
    this program in interactive mode:

    $PROG_NAME -h
EOT
        }
        exit(1);
    }

    if( $opts->{compile} && $opts->{output} )
    {
        my $f = shift( @ARGV ) || bailout( "No po file to read was provided." );
        &compile( in => $f, out => $opts->{output} );
    }
    elsif( $opts->{init} )
    {
        my $out = $opts->{output} || shift( @ARGV ) || bailout( "No po file path was specified to initiate." );
        &init_po( $out );
    }
    elsif( $opts->{as_json} && $opts->{output} )
    {
        my $f = shift( @ARGV ) || bailout( "No po file to read was provided." );
        _message( 3, "Reading file \"$f\" and writing to \"$opts->{output}\"." );
        &to_json( in => $f, out => $opts->{output} );
    }
    elsif( $opts->{as_po} && $opts->{output} )
    {
        my $f = shift( @ARGV ) || bailout( "No (json) po file to read was provided." );
        _message( 3, "Reading file \"$f\" and writing to \"$opts->{output}\"." );
        &to_po( in => $f, out => $opts->{output} );
    }
    elsif( $opts->{add} )
    {
        my $f = shift( @ARGV ) || bailout( "No po file to read was provided." );
        &add( in => $f );
    }
    elsif( $opts->{sync} && $opts->{output} )
    {
        my $f = shift( @ARGV ) || bailout( "No (json) po file to read was provided." );
        _message( 3, "Reading file \"$f\" and writing to \"$opts->{output}\"." );
        &sync( in => $f, out => $opts->{output} );
    }
    # Pre-processing for one file with an output file provided
    elsif( $opts->{pp} && $opts->{output} )
    {
        my $f = shift( @ARGV ) || bailout( "No po file to pre-process was provided." );
        _message( 3, "Pre-processing file \"$f\" and writing to \"$opts->{output}\"." );
        &pp( in => $f, out => $opts->{output} );
    }
    elsif( $opts->{add_include} )
    {
        my $f = shift( @ARGV ) || bailout( "No po file to add the include to was provided." );
        _message( 3, "Adding include to file \"$f\"." );
        &add_include( in => $f, file => $opts->{file} );
    }
    else
    {
        my $is_multi = scalar( @ARGV ) > 1 ? 1 : 0;
        if( $opts->{pp} &&
            $is_multi && 
            !$opts->{overwrite} &&
            !$opts->{output_dir} )
        {
            bailout( "Error: Pre-processing request, but multiple input files provided, and neither --overwrite nor --output-dir was specified. Refusing to merge outputs into STDOUT." );
        }
        my $output_dir;
        $output_dir = $opt->new_file( $opts->{output_dir} ) if( $opts->{output_dir} );
        foreach my $f ( @ARGV )
        {
            $out->print( "Processing file \"$f\"\n" );
            # $po->debug( 3 );
            if( $opts->{dump} )
            {
                _messagec( 3, "Dumping file <green>$f</>" );
                my $file = $opt->new_file( $f );
                my $po;
                if( $file->extension eq 'mo' )
                {
                    my $mo = Text::PO::MO->new( file => $file, debug => $opts->{debug} );
                    $po = $mo->as_object || _messagec( 3, "<red>", $mo->error, "</>" );
                }
                elsif( $file->extension eq 'json' )
                {
                    $po = Text::PO->new(
                        ( defined( $opts->{include} ) ? ( include => $opts->{include} ) : () ),
                        ( $opts->{max_recurse} ? ( max_recurse => $opts->{max_recurse} ) : () ),
                        debug => $opts->{debug}
                    ) || bailout( Text::PO->error );
                    $po->parse2object( $file ) || bailout( $po->error );
                }
                else
                {
                    $po = Text::PO->new(
                        ( defined( $opts->{include} ) ? ( include => $opts->{include} ) : () ),
                        ( $opts->{max_recurse} ? ( max_recurse => $opts->{max_recurse} ) : () ),
                        debug => $opts->{debug}
                    ) || bailout( Text::PO->error );
                    $po->parse( $file ) || bailout( $po->error );
                }
                $po->dump( $out );
                next;
            }

            # Saving as JSON would imply processing all includes, but the user may very well use the option --noinclude, and then only the msgid within that specific file would be converted to JSON.
            if( $opts->{as_json} )
            {
                my $file = $opt->new_file( $f );
                my $base = $file->basename;
                my $out;
                if( $output_dir )
                {
                    $output_dir->mkpath if( !$output_dir->exists );
                    # my $domain = $po->domain || bailout( "Unable to get the domain from the po file \"$f\"" );
                    # $out  = $output_dir->child( "${domain}.mo" );
                    $out = $output_dir->child( $base )->extension( 'json' );
                }
                # If multiple files, their respective output is saved to the equivalent file with extension 'json'
                # If it is a lone file, its output will be printed to STDOUT
                elsif( $is_multi )
                {
                    $out = $file->extension( 'json' );
                }
                &to_json( in => $f, ( defined( $out ) ? ( out => $out ) : () ) );
            }
            elsif( $opts->{as_po} )
            {
                my $file = $opt->new_file( $f );
                my $base = $file->basename;
                my $out;
                if( $output_dir )
                {
                    $output_dir->mkpath if( !$output_dir->exists );
                    # my $domain = $po->domain || bailout( "Unable to get the domain from the po file \"$f\"" );
                    # $out  = $output_dir->child( "${domain}.mo" );
                    $out = $output_dir->child( $base )->extension( 'po' );
                }
                # If multiple files, their respective output is saved to the equivalent file with extension 'json'
                # If it is a lone file, its output will be printed to STDOUT
                elsif( $is_multi )
                {
                    $out = $file->extension( 'po' );
                }
                &to_po( in => $f, ( defined( $out ) ? ( out => $out ) : () ) );
            }
            elsif( $opts->{compile} )
            {
                my $file = $opt->new_file( $f );
                my $base = $file->basename;
                my $out;
                if( $output_dir )
                {
                    $output_dir->mkpath if( !$output_dir->exists );
                    # my $domain = $po->domain || bailout( "Unable to get the domain from the po file \"$f\"" );
                    # $out  = $output_dir->child( "${domain}.mo" );
                    $out = $output_dir->child( $base )->extension( 'mo' );
                }
                else
                {
                    $out = $file->extension( 'mo' );
                }
                &compile( in => $f, out => $out );
            }
            elsif( $opts->{pp} )
            {
                my $file = $opt->new_file( $f );
                my $base = $file->basename;
                my $out;
                if( $output_dir )
                {
                    $output_dir->mkpath if( !$output_dir->exists );
                    # my $domain = $po->domain || bailout( "Unable to get the domain from the po file \"$f\"" );
                    # $out  = $output_dir->child( "${domain}.mo" );
                    # Make sure the extension is 'po'
                    $out = $output_dir->child( $base )->extension( 'po' );
                }
                # If multiple files, their respective output is saved to the equivalent file with extension 'po', which may be the same as the original file, and if so pp() will bail out unless --overwrite is specified.
                # If it is a lone file, its output will be printed to STDOUT
                elsif( $is_multi )
                {
                    # We make sure the extension is 'po'
                    # pp() will bailout if this file already exists and --overwrite was not provided.
                    $out = $file->extension( 'po' );
                }
                &pp( in => $f, ( defined( $out ) ? ( out => $out ) : () ) );
            }
        }
    }
    exit(0);
}

sub add
{
    my $p = $opt->_get_args_as_hash( @_ );
    my $f = $p->{in} || bailout( "No po file to read was specified." );
    $f = $opt->new_file( $f );
    # We just re-use this variable
    $p =
    {
        debug   => $opts->{debug},
        # We do not want to process include; we just want to manipulate the PO file.
        include => 0,
    };
    $p->{domain} = $opts->{domain} if( length( $opts->{domain} ) );
    my $ext = $f->extension;
    if( $ext eq 'po' )
    {
        $po = Text::PO->new( %$p ) || bailout( Text::PO->error );
        $po->parse( $f ) || bailout( $po->error );
    }
    elsif( $ext eq 'json' )
    {
        $p->{use_json} = 1;
        $po = Text::PO->new( %$p ) || bailout( Text::PO->error );
        $po->parse2object( $f ) || bailout( $po->error );
    }
    elsif( $ext eq 'mo' )
    {
        # The option 'include' is not supported by Text::PO::MO
        delete( $p->{include} );
        $p->{file} = $f;
        my $mo = Text::PO::MO->new( %$p );
        $po = $mo->as_object || bailout( $mo->error );
    }
    else
    {
        bailout( "Unknown source file \"$f\"" );
    }
    _messagec( 3, "Adding id \"<green>$opts->{msgid}</>\" -> \"<green>$opts->{msgstr}</>\"" );
    $po->add_element(
        msgid => "$opts->{msgid}",
        msgstr => "$opts->{msgstr}",
        ( $opts->{after}  ? ( after  => $opts->{after} )  : () ),
        ( $opts->{before} ? ( before => $opts->{before} ) : () ),
    ) || bailout( $po->error );
    _messagec( 3, "Saving back to \"<green>$f</>\"" );

    if( $ext eq 'po' )
    {
        my $binmode = ( $opts->{charset} || 'utf-8' );
        $binmode = 'utf8' if( lc( $binmode ) eq 'utf-8' );
        my $fh = $f->open( '>', { binmode => $binmode, autoflush => 1 } ) || bailout( "Unable to open the output file in write mode: ", $out->error );
        $po->dump( $fh );
        $fh->close;
    }
    elsif( $ext eq 'json' )
    {
        my $json = $po->as_json({ pretty => 1, canonical => 1 });
        _messagec( 3, "<red>", $po->error, "</>" ) if( !$json );
        my $fh = $o->open( '>', { binmode => ':utf8', autoflush => 1 }) || bailout( "Unable to open output file \"$o\" in write mode: $!" );
        $fh->print( $json );
        $fh->close;
    }
    elsif( $ext eq 'mo' )
    {
        my $mo = Text::PO::MO->new(
            file => $f,
            debug => $opts->{debug},
        ) || bailout( Text::PO::MO->error );
        $mo->write( $po ) || bailout( "Unable to write to \"$o\": ", $mo->error );
    }
    _messagec( 3, "<green>Done.</>" );
    return(1);
}

sub add_include
{
    my $p = $opt->_get_args_as_hash( @_ );
    my $f = $p->{in} || bailout( "No po file to read was specified." );
    my $inc = $p->{file} || bailout( "No include file to add was specificed." );
    $f = $opt->new_file( $f );
    # We just re-use this variable
    $p =
    {
        debug   => $opts->{debug},
        # We do not want to process include; we just want to manipulate the PO file.
        include => 0,
    };
    $p->{domain} = $opts->{domain} if( length( $opts->{domain} ) );
    if( $f->extension eq 'po' )
    {
        $po = Text::PO->new( %$p ) || bailout( Text::PO->error );
        $po->parse( $f ) || bailout( $po->error );
    }
    elsif( $f->extension eq 'json' )
    {
        bailout( "Cannot add an include directive to a JSON file." );
    }
    elsif( $f->extension eq 'mo' )
    {
        bailout( "Cannot add an include directive to a .mo file." );
    }
    else
    {
        bailout( "Unknown source file \"$f\"" );
    }
    _messagec( 3, "Adding include directive for file '<green>$inc</>'" );
    $po->add_include(
        file => $inc,
        ( $opts->{after}  ? ( after  => $opts->{after} )  : () ),
        ( $opts->{before} ? ( before => $opts->{before} ) : () ),
    ) || bailout( $po->error );
    _messagec( 3, "Saving back to \"<green>$f</>\"" );
    my $binmode = ( $opts->{charset} || 'utf-8' );
    $binmode = 'utf8' if( lc( $binmode ) eq 'utf-8' );
    my $fh = $f->open( '>', { binmode => $binmode, autoflush => 1 } ) || bailout( "Unable to open the output file in write mode: ", $out->error );
    $po->dump( $fh );
    $fh->close;
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
    my $f = $p->{in} || bailout( "No po file to read was specified." );
    # AN output file is required. We cannot just print to STDOUT
    my $o = $p->{out} || bailout( "No mo file to write to was specified." );
    $f = $opt->new_file( $f );
    my $po;
    if( $f->extension() eq 'mo' )
    {
        &bailout( "The source file \"$f\" is already a mo file. You can simply copy it yourself." );
    }

    $p =
    {
        debug   => $opts->{debug},
        # Since we are saving as compiled data, we need to resolve all include directives
        include => 1,
        ( $opts->{max_recurse} ? ( max_recurse => $opts->{max_recurse} ) : () ),
    };
    $p->{domain} = $opts->{domain} if( length( $opts->{domain} ) );

    if( $f->extension eq 'po' )
    {
        $po = Text::PO->new( $p ) || bailout( Text::PO->error );
        $po = $po->parse( $f );
        bailout( "This does not look like a po file" ) if( !$po->elements->length );
    }
    elsif( $f->extension eq 'json' )
    {
        $p->{use_json} = 1;
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
    my $mo = Text::PO::MO->new( file => $o, debug => $opts->{debug} );
    $o->parent->mkpath;
    $mo->write( $po ) || bailout( "Unable to write to \"$o\": ", $mo->error );
    return(1);
}

sub init_po
{
    my $out = shift( @_ );
    # If no output has been specified, we print to STDOUT
    $out = $opt->new_file( $out ) if( defined( $out ) );
    if( defined( $out ) &&
        $out->exists &&
        !$opts->{overwrite} )
    {
        bailout( "An output file with the same name \"$out\" already exists. If you want to overwrite it, please use the --overwrite option" );
    }
    if( !$opts->{lang} )
    {
        bailout( "No language code was specified." );
    }
    elsif( !$opts->{domain} )
    {
        bailout( "No domain for the po file was provided." );
    }

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
        bailout( "Settings json file specified \"$opts->{settings}\" does not exist." ) if( !$f->exists );
        local $@;
        # try-catch
        my $json = eval
        {
            my $data = $f->load;
            my $j = JSON->new->utf8->relaxed;
            $j->decode( $data );
        };
        if( $@ )
        {
            warn( "An error occurred while trying to decode json data from file \"$opts->{settings}\": $@\n" );
            return;
        }
        # Make sure all fields are normalised
        foreach my $k ( keys( %$json ) )
        {
            ( my $k2 = $k ) =~ tr/-/_/;
            $json->{ $k2 } = CORE::delete( $json->{ $k } );
        }

        foreach my $k ( @$fields )
        {
            # command line options take priority
            next if( defined( $opts->{ $k } ) && length( $opts->{ $k } ) );
            $opts->{ $k } = $json->{ $k } if( exists( $json->{ $k } ) );
        }
    }

    my $po = Text::PO->new(
        debug   => $opts->{debug},
        # We just want to instantiate a PO, so since we may read from a POT, we do not want to process include directives.
        include => 0,
    );
    if( $opts->{pot} )
    {
        my $pot = $opt->new_file( $opts->{pot} );
        bailout( "The pot file specified \"$pot\" does not exist." ) if( !$pot->exists );
        $po->parse( $pot ) ||
        bailout( "Error while reading pot file \"$pot\": ", $po->error );

    }
    if( $opts->{header} )
    {
        local $Text::Wrap::columns = 80;
        my $lines = [split( /\n/, $opts->{header} )];
        for( my $i = 0; $i < scalar( @$lines ); $i++ )
        {
            substr( $lines->[$i], 0, 0, '# ' ) unless( substr( $lines->[$i], 0, 1 ) eq '#' );
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
    my $plur = &_get_plural_rule( $opts->{lang} );
    if( defined( $plur ) &&
        ref( $plur ) eq 'ARRAY' &&
        scalar( @$plur ) )
    {
        $po->meta( $maps->{plural} => sprintf( 'nplurals=%d; plural=%s;', @$plur ) );
    }
    # Should we fallback, or simply not add any 'Plural-Forms' header at all ?
    else
    {
        # Fallback to 'und'
        $po->meta( $maps->{plural} => q{nplurals=1; plural=0;} );
    }
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
    my $fh;
    if( defined( $out ) )
    {
        $fh = $out->open( '>', { binmode => $binmode } ) || bailout( "Unable to open the output file in write mode: ", $out->error );
    }
    else
    {
        $fh = IO::File->new;
        $fh->fdopen( fileno( STDOUT ), 'w' );
        $fh->binmode( ":utf8" );
    }
    $fh->autoflush(1);
    $po->dump( $fh );
    $fh->close if( defined( $out ) );
    return(1);
}

# po.pl --pp input.po > normalised.po
# po.pl --pp --output normalised.po input.po
# po.pl --pp --overwrite input.po
# We take a file in and save it with all its include directives resolved
sub pp
{
    my $p = $opt->_get_args_as_hash( @_ );
    my $f = $p->{in} || bailout( "No po file to pre-process was specified." );
    # If no output is specified, we print to STDOUT
    my $o = $p->{out};
    $o = $opt->new_file( $o ) if( defined( $o ) );
    if( defined( $o ) &&
        $o->exists &&
        !$opts->{overwrite} )
    {
        bailout( "An output file with the same name \"$o\" already exists. If you want to overwrite it, please use the --overwrite option" );
    }
    $f = $opt->new_file( $f );
    $p =
    {
        debug   => $opts->{debug},
        # Since we need to pre-process the include directives, we need to enable it.
        include => 1,
        ( $opts->{max_recurse} ? ( max_recurse => $opts->{max_recurse} ) : () ),
    };
    $p->{domain}  = $opts->{domain} if( length( $opts->{domain} ) );
    if( $f->extension() ne 'po' )
    {
        &bailout( "The source file \"$f\" is not a po file. Pre-processing only works on PO files." );
    }
    my $po = Text::PO->new( %$p ) || bailout( Text::PO->error );
    _messagec( 3, "Pre-processing po file <green>$f</>" );
    $po->parse( $f ) || bailout( $po->error );

    my $fh;
    if( defined( $o ) )
    {
        _messagec( 3, "Saving as PO file to <green>${o}</>" );
        $o->parent->mkpath if( !$o->parent->exists );
        $fh = $o->open( '>', { binmode => 'utf8' } ) || bailout( "Unable to open the output file in write mode: ", $o->error );
        $po->dump( $fh );
        $fh->close;
    }
    else
    {
        $fh = IO::File->new;
        $fh->fdopen( fileno( STDOUT ), 'w' );
        $fh->binmode( ":utf8" );
    }
    $fh->autoflush(1);
    $po->dump( $fh );
    $fh->close if( defined( $o ) );
    return(1);
}

sub sync
{
    my $p = $opt->_get_args_as_hash( @_ );
    my $f = $p->{in} || bailout( "No po file to read was specified." );
    my $o = $p->{out} || bailout( "No mo file to write to was specified." );
    $f = $opt->new_file( $f );
    my $po;
    $p =
    {
        debug   => $opts->{debug},
        # By synchronising PO files, we are in effect merely editing them, so we do not need to process includes.
        include => 0,
    };
    $p->{domain} = $opts->{domain} if( length( $opts->{domain} ) );
    if( $f->extension eq 'po' )
    {
        $po = Text::PO->new( %$p ) || bailout( Text::PO->error );
        _messagec( 3, "Reading po file <green>$f</>" );
        $po->parse( $f ) || bailout( $po->error );
    }
    elsif( $f->extension eq 'mo' )
    {
        # The option 'include' is not supported by Text::PO::MO
        delete( $p->{include} );
        $p->{file} = $f;
        my $mo = Text::PO::MO->new( %$p );
        _messagec( 3, "Reading mo file <green>$f</>" );
        $po = $mo->as_object;
    }
    elsif( $f->extension eq 'json' )
    {
        $p->{use_json} = 1;
        $po = Text::PO->new( %$p ) || bailout( Text::PO->error );
        _messagec( 3, "Reading json po file <green>$f</>" );
        $po->parse2object( $f ) || bailout( $po->error );
    }
    _messagec( 3, "Synchronising against po file <green>$o</>" );
    $po->sync( $o ) || bailout( $po->error );
    if( $po->debug )
    {
        my $added = $po->added;
        my $removed = $po->removed;
        if( scalar( @$added ) )
        {
            _message( 3, "The following ", scalar( @$added ), " element(s) were added:\n", join( "\n\n", @$added ) );
        }
        else
        {
            _message( 3, "No element were added." );
        }

        if( scalar( @$removed ) )
        {
            _message( 3, "The following ", scalar( @$removed ), " element(s) were removed:\n", join( "\n\n", @$removed ) );
        }
        else
        {
            _message( 3, "No element were removed." );
        }
    }
}

sub to_json
{
    my $p = $opt->_get_args_as_hash( @_ );
    my $f = $p->{in} || bailout( "No po file to read was specified." );
    # If no output is specified, we print to STDOUT
    my $o = $p->{out};
    $o = $opt->new_file( $o ) if( defined( $o ) );
    if( defined( $o ) &&
        $o->exists &&
        !$opts->{overwrite} )
    {
        bailout( "An output file with the same name \"$o\" already exists. If you want to overwrite it, please use the --overwrite option" );
    }
    $f = $opt->new_file( $f );
    my $po;
    $p =
    {
        debug   => $opts->{debug},
        # Because we are saving as JSON, and there are no special include directives in JSON, we must enable processing of include directives in PO file.
        include => 1,
        ( $opts->{max_recurse} ? ( max_recurse => $opts->{max_recurse} ) : () ),
    };
    $p->{domain} = $opts->{domain} if( length( $opts->{domain} ) );
    if( $f->extension() eq 'json' )
    {
        &bailout( "The source file \"$f\" is already a json file. You can simply copy it yourself." );
    }
    elsif( $f->extension eq 'mo' )
    {
        # There is no 'include' option in Text::PO::MO
        delete( $p->{include} );
        $p->{file} = $f;
        my $mo = Text::PO::MO->new( %$p );
        $po = $mo->as_object;
    }
    elsif( $f->extension eq 'po' )
    {
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
    if( defined( $o ) )
    {
        _messagec( 3, "<green>", $po->elements->length, "</> elements found." );
        _messagec( 3, "Saving as json file to <green>${o}</>" );
        $o->parent->mkpath if( !$o->parent->exists );
        $fh = $o->open( '>', { binmode => ':utf8' }) || bailout( "Unable to open output file \"$o\" in write mode: $!" );
    }
    else
    {
        $fh = IO::File->new;
        $fh->fdopen( fileno( STDOUT ), 'w' );
        $fh->binmode( ":utf8" );
    }
    $fh->autoflush(1);
    # _message( 3, "Saving json '$json'" );
    $fh->print( $json );
    $fh->close if( defined( $o ) );
    return(1);
}

sub to_po
{
    my $p = $opt->_get_args_as_hash( @_ );
    my $f = $p->{in} || bailout( "No po file to read was specified." );
    # If no output is specified, we print to STDOUT
    my $o = $p->{out};
    $o = $opt->new_file( $o ) if( defined( $o ) );
    if( defined( $o ) &&
        $o->exists &&
        !$opts->{overwrite} )
    {
        bailout( "An output file with the same name \"$o\" already exists. If you want to overwrite it, please use the --overwrite option" );
    }
    $f = $opt->new_file( $f );
    my $po;
    $p = 
    {
        debug   => $opts->{debug},
        include => 0,
    };
    $p->{domain} = $opts->{domain} if( length( $opts->{domain} ) );
    if( $f->extension() eq 'po' )
    {
        &bailout( "The source file \"$f\" is already a po file. You can simply copy it yourself." );
    }
    elsif( $f->extension eq 'mo' )
    {
        # The option 'include' is not supported by Text::PO::MO
        delete( $p->{include} );
        $p->{file} = $f;
        my $mo = Text::PO::MO->new( %$p );
        $po = $mo->as_object || _messagec( 3, "<red>", $mo->error, "</>" );
    }
    elsif( $f->extension eq 'json' )
    {
        $p->{use_json} = 1;
        $po = Text::PO->new( %$p ) || bailout( Text::PO->error );
        $po->parse2object( $f ) || bailout( $po->error );
    }
    else
    {
        bailout( "Unknown source file \"$f\"" );
    }

    my $fh;
    if( defined( $o ) )
    {
        _messagec( 3, "<green>", $po->elements->length, "</> elements found." );
        _messagec( 3, "Saving as PO data file to <green>${o}</>" );
        $o->parent->mkpath if( !$o->parent->exists );
        $fh = $o->open( '>', { binmode => ':utf8' }) || bailout( "Unable to open output file \"$o\" in write mode: $!" );
    }
    else
    {
        $fh = IO::File->new;
        $fh->fdopen( fileno( STDOUT ), 'w' );
        $fh->binmode( ":utf8" );
    }
    $fh->autoflush(1);
    $po->dump( $fh );
    $fh->close if( defined( $o ) );
    return(1);
}

sub _get_plural_rule
{
    my( $locale ) = @_;
    # Try to use Locale::Unicode::Data if it is available
    local $@;
    # try-catch
    eval
    {
        require Locale::Unicode::Data;
    };
    if( $@ )
    {
        my $ref;
        if( exists( $PLURALS->{ $locale } ) )
        {
            $ref = $PLURALS->{ $locale };
        }
        elsif( exists( $PLURALS->{ substr( $locale, 0, 2 ) } ) )
        {
            $ref = $PLURALS->{ substr( $locale, 0, 2 ) };
        }
        else
        {
            warn( "Unknow locale \"$locale\" to find out about its plural form\n" );
            return;
        }
        return( $ref );
    }
    else
    {
        my $cldr = Locale::Unicode::Data->new || bailout( Locale::Unicode::Data->error );
        my $rule = $cldr->plural_forms( $locale ) || bailout( $cldr->error );
        # e.g.: nplurals=6; plural=(n==0 ? 0 : n==1 ? 1 : n==2 ? 2 : n%100>=3 && n%100<=10 ? 3 : n%100>=11 ? 4 : 5);
        my( $n, $expr ) = split( /[[:blank:]]*\;[[:blank:]]*/, $rule, 2 );
        my $token;
        ( $token, $n ) = split( /[[:blank:]]*=[[:blank:]]*/, $n, 2 );
        ( $token, $expr ) = split( /[[:blank:]]*=[[:blank:]]*/, $expr, 2 );
        return( [$n, $expr] );
    }
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
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

po - GNU PO file manager

=head1 SYNOPSIS

    po [ --debug|--nodebug, --verbose|--noverbose, -v, --help, --man]

    # Show help
    po --help

    # Initialise a PO file
    po --init --domain com.example.api --settings settings.json messages.po

    po --init --domain com.example.api --lang fr_FR --settings settings.json \
       --pot template.pot --header "$(cat header.txt)" --version 0.2 --charset utf-8

    po --sync --output file-to-be-synced.po source-file.po
    po --sync --output file-to-be-synced.po source-file.mo
    po --sync --output file-to-be-synced.po source-file.json

    # Convert a PO file to JSON
    po --as-json --output messages.json messages.po

    # Convert JSON back to PO
    po --as-po --output messages.po messages.json

    # Dump the content of the file as a PO to the STDOUT
    po --dump messages.po
    po --dump messages.json
    po --dump messages.mo

    # Pre-process a PO file (resolve $include directives) and write to STDOUT
    po --pp messages.po > messages.normalised.po

    # Pre-process a PO file in place (requires --overwrite)
    po --pp --overwrite messages.po

    # Pre-process a PO file and write to a separate destination
    po --pp --output /some/where/messages.normalised.po messages.po

    # Add a msgid
    po --add --msgid "Hello world!" --msgstr "Salut tout le monde !" messages.po

    # Add an include directive to a .po file
    po --add-include --file "some/file/to/include.po" messages.po

    Options

    Basic options:
    --add                   Add an msgsid/msgstr entry in the po file
    --add-include           Add an include directive to the po file
    --as-po                 Write the file as a po file
    --as-json               Write the po file as json on the STDOUT
    --compile               Create a machine object file (.mo)
    --domain                The po file domain
    --dump                  Dump the PO file in a format suitable for a .po file
    --init                  Create an initial po file such as .pot
    --pre-process or --pp   Pre-process all possible include directive
    --sync                  Synchronise a GNU PO file with another one

    --after                 Specify the msgid to add the include directive after
    --before                Specify the msgid to add the include directive before
    --bugs-to               Sets the value for the meta field C<Report-Msgid-Bugs-To>
    --charset               Sets the character encoding value in C<Content-Type>
    --created-on            Sets the value for the meta field C<POT-Creation-Date>
    --domain                The domain, such as C<com.example.api>
    --encoding              Sets the value for the meta field C<Content-Transfer-Encoding>
    --file                  Specify the file to include with C<--add-include>
    --header                The string to be used as the header for the C<.po> file only.
    --include               Enable the processing of include directives in the PO files
    --noinclude             Disable the processing of include directives in the PO files
    --lang                  The locale to use, such as en_US
    --max-recurse           An unsigned integer to define the maximum recursion allowed when resolving include directives
    --msgid                 The C<msgid> to add
    --msgstr                The localised text to add for the given C<msgid>
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

=head1 VERSION

    v0.3.0

=head1 DESCRIPTION

B<This program>, C<po>, takes optional parameters and process GNU PO files.

GNU PO files are localisation or C<l10n> files. They can be used as binary after been compiled, or they can be converted to C<JSON> using this utility which then can read the C<JSON> data instead of parsing the PO files, making it faster to load.

It can:

=over 4

=item *

Convert C<.po> files to and from JSON.

    po --as-json --output com.example.api.json com.example.api.po
    po --as-json com.example.api.po # print to STDOUT
    # Reading from a .mo file
    po --as-json com.example.api.mo # print to STDOUT

    po --as-po --output com.example.api.po com.example.api.json
    po --as-po com.example.api.json # print to STDOUT
    # Reading from a .mo file
    po --as-po com.example.api.mo # print to STDOUT

=item *

Optionally read C<.mo> files and export their content.

=item *

Pre-process PO files by resolving C<$include> directives and rewriting a single, normalised PO file.

    po --pp com.example.api.po # print to STDOUT
    po --pp --output com.example.api.po com.example.api.popp
    # Normalise the PO file, and rewrite it in-place
    po --pp --overwrite com.example.api.po

=item *

Compile a PO file to machine object (C<.mo>) format.

    po --compile --output com.example.api.mo com.example.api.po
    po --compile --output com.example.api.mo com.example.api.json

=item *

Add new localisation string to a C<.po>, C<.json>, or C<.mo> file:

    po --add --msgid "Hello world!" --msgstr "Salut tout le monde !" com.example.api.po
    po --add --msgid "Hello world!" --msgstr "Salut tout le monde !" com.example.api.json
    po --add --msgid "Hello world!" --msgstr "Salut tout le monde !" com.example.api.mo

You can specify at what position to add the new element with the C<--before> and C<--after> options. However, note that the elements are automatically sorted lexicographically for C<.mo> files in line with GNU machine object requirements.

=item *

Add include directive to a C<.po> file:

    po --add-include --file "some/file/to/include.po" target.po
    po --add-include --file "some/file/to/include.po" --before "Some msgid" target.po
    po --add-include --file "some/file/to/include.po" --after "Some msgid" target.po

You can specify at what position to add the new element with the C<--before> and C<--after> options

=item *

Synchronise a PO file with another:

    po --sync --output file-to-be-synced.po source-file.po
    po --sync --output file-to-be-synced.po source-file.mo
    po --sync --output file-to-be-synced.po source-file.json

=item *

Initialise a PO file:

    po --init --domain com.example.api --output com.example.api.po
    # print to STDOUT
    po --init --domain com.example.api
    # Loading default values from settings.json and template file template.pot
    po --init --domain com.example.api --lang fr_FR --settings settings.json \
       --pot template.pot --header "$(cat header.txt)" --version 0.2 --charset utf-8

=item *

Dump the content of PO file

    po --dump com.example.api.po

Any include directive will be resolved automatically unless C<--noinclude> is used.

=back

By default, C<po.pl> reads from a single input file and writes either to a file specified with C<--output> or to C<STDOUT>. Some operations, such as pre-processing, may allow in-place rewriting when C<--overwrite> is explicitly provided.

=head1 MODES

The tool operates in one of several modes. Only one main mode should be specified at a time.

=over 4

=item B<--as-json>

Read a PO (or MO) file and write its content as JSON.

=item B<--from-json>

Read JSON produced by this tool and write a PO file.

=item B<--pp>, B<--pre-process>

Pre-process a PO file. This mode loads the PO file through L<Text::PO>, processes any C<$include> directives according to the C<include> and C<max_recurse> logic in L<Text::PO>, and then writes back a single, flattened PO file.

When C<--pp> is used:

=over 4

=item *

If C<--output FILE> is provided, the pre-processed result is written to C<FILE>.

=item *

If C<--overwrite> is provided and no C<--output> is given, the input file is rewritten in place.

=item *

If neither C<--output> nor C<--overwrite> is given, the pre-processed result is written to C<STDOUT>.

=back

This makes C<--pp> useful as a normalisation step in build pipelines or before handing PO files to third-party tools that do not understand C<$include> directives.

=back

=head1 OPTIONS

=head2 --add

Adds an C<msgid> and C<msgstr> pair to the po file

    po --add --msgid "Hello!" --msgstr "Salut !" --output fr_FR/LC_MESSAGES/com.example.api.po

=head2 --as-json

Takes a po file and transcode it as a json po file

    po --as-json --output fr_FR/LC_MESSAGES/com.example.api.json fr_FR.po

=head2 --as-po

Takes a C<.mo> or C<.json> file and transcode it to a po file

    po --as-po --output fr_FR.po ./fr_FR/com.example.api.json

=head2 --bugs-to

The string to be used for the PO file header field C<Bugs-To>

=head2 --charset

The PO file character set. This should be C<utf-8>

=head2 --compile

Takes a po file and compiles it into a binary file wth extension C<mo>

    po --compile ./fr_FR/com.example.api.json
    # Will create ./fr_FR/com.example.api.mo

=head2 --create-on

The PO file creation date. This can be an ISO 8601 date, or a unix timestamp, or even a relative date such as C<+1D>. See L<Module::Generic/_set_get_datetime> for more information

=head2 --domain

The PO file domain

    po --init --domain com.example.api ./fr_FR/com.example.api.po

=head2 --dump

Dump the data contained as a GNU PO file to the STDOUT

    po --dump /some/file.po >new_file.po
    # Maybe?
    diff /some/file.po new_file.po

=head2 --encoding

The PO file encoding. This defaults to C<8bit>. There is no reason to change this.

=head2 --header

The PO file meta information header

=head2 --include

Enable the processing of include directives in the PO files.

=head2 --noinclude

Disable the processing of include directives in the PO files.

=head2 --init

Init a new PO file

    po --init --domain com.example.api --lang fr_FR ./fr_FR/com.example.api.po
    # then you can convert it as a json file
    po --as-json --output ./fr_FR/com.example.api.json ./fr_FR/com.example.api.po

=head2 --lang

The PO file locale language

    po --init --domain com.example.api --lang fr_FR ./fr_FR/com.example.api.po

=head2 --max-recurse

    po --pp --max-recurse N com.example.api.po

An unsigned integer, used along with C<--pp>, to define the maximum recursion allowed when resolving include directives.

If omitted, L<Text::PO>'s default C<max_recurse> is used.

=head2 --msgid

The localised string original text.

=head2 --msgstr

The localised string

=head2 --output

    po --pp --output FILE original.po

Write the result to I<FILE> instead of C<STDOUT>. For C<--pp>, this controls where the pre-processed PO is saved.

=head2 --output-dir

The output directory. For example to read multiple po file and create their related mo files under a given directory:

    po --compile --output-dir ./en_GB/LC_MESSAGES en_GB.*.po

This will read all the po files for language en_GB as selected in write their related mo files under C<./en_GB/LC_MESSAGES>. This directory will be created if it does not exist. The domain will be derived from the po file.

=head2 --overwrite

Boolean. If true, this will allow overwriting existing file. Default is false

=head2 --po-debug

An integer value to set the level of debugging. Default is o (no debugging enabled)

=head2 --pot

The PO template file to use

=head2 --project

The PO file project name

=head2 --revised-on

The PO file revision date. This can be an ISO 8601 date, or a unix timestamp, or even a relative date such as C<+1D>. See L<Module::Generic/_set_get_datetime> for more information

=head2 --settings

The file path to the C<settings.json> json file containing all the default values

This is convenient to set various default values rather than specifying each of of them as option

    po --init --settings /some/where/settings.json --domain com.example.api --lang fr_FR ./fr_FR/com.example.api.po

=head2 --sync

Synchronise a PO file based on another (the source), adding any missing C<msgid> and C<msgstr> resources it finds in the source file.

For example, to synchronise a Japanese PO file based on its English equivalent:

    po --sync --output ./locale/ja_JP/LC_MESSAGES/com.example.api.json ./locale/en_GB/LC_MESSAGES/com.example.api.json

=head2 --team

The team in charge of this PO file maintenance

=head2 --translator

The PO file C<Translator> field containing the name of the person or group in charge of the translation for this file.

=head2 --tz, --time-zone, --timezone

The time zone to use in the PO file meta information header

=head2 --version

Displays this utility version number and quits.

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

=head1 EXAMPLE

    po [--dump, --debug|--nodebug, --verbose|--noverbose, -v, --help, --man] /some/file.po

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT

Copyright (c) 2020-2025 DEGUEST Pte. Ltd.

=cut
