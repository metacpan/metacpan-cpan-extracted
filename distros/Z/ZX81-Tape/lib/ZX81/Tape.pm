package ZX81::Tape;

use Modern::Perl;
use Path::Tiny;
use ZX81::Tokenize qw( tokenize_basic encode_chars encode_float );

our $VERSION = '0.004';

use Exporter qw(import);

our @EXPORT_OK = qw(
  make_p
  dump_p
  list_p
);

#------------------------------------------------------------------------------
# Memory area
#------------------------------------------------------------------------------
{

    package ZX81::Tape::Memory;
    use Object::Tiny::RW qw( start data );

    sub new {
        my ( $class, $start, @data ) = @_;
        return $class->SUPER::new( start => $start, data => \@data );
    }

    sub peek {
        my ( $self, $addr ) = @_;
        my $p = $addr - $self->start;
        if ( $p < 0 || $p >= @{ $self->data } ) {
            return 0;
        }
        return $self->data->[$p];
    }

    sub dpeek {
        my ( $self, $addr ) = @_;
        return $self->peek($addr) | ( $self->peek( $addr + 1 ) << 8 );
    }

    sub dpeek_be {
        my ( $self, $addr ) = @_;
        return ( $self->peek($addr) << 8 ) | $self->peek( $addr + 1 );
    }
}

#------------------------------------------------------------------------------
# zx81 system variables and character mappings
#------------------------------------------------------------------------------
my %sysvars = (
    ERR_NO     => 0x4000,
    FLAGS      => 0x4001,
    ERR_SP     => 0x4002,
    RAMTOP     => 0x4004,
    MODE       => 0x4006,
    PPC        => 0x4007,
    VERSN      => 0x4009,
    E_PPC      => 0x400a,
    D_FILE     => 0x400c,
    DF_CC      => 0x400e,
    VARS       => 0x4010,
    DEST       => 0x4012,
    E_LINE     => 0x4014,
    CH_ADD     => 0x4016,
    X_PTR      => 0x4018,
    STKBOT     => 0x401a,
    STKEND     => 0x401c,
    BREG       => 0x401e,
    MEM        => 0x401f,
    FREE1      => 0x4021,
    DF_SZ      => 0x4022,
    S_TOP      => 0x4023,
    LAST_K     => 0x4025,
    DEBOUNCE   => 0x4027,
    MARGIN     => 0x4028,
    NXTLIN     => 0x4029,
    OLDPPC     => 0x402b,
    FLAGX      => 0x402d,
    STRLEN     => 0x402e,
    T_ADDR     => 0x4030,
    SEED       => 0x4032,
    FRAMES     => 0x4034,
    COORDS_X   => 0x4036,
    COORDS_Y   => 0x4037,
    PR_CC      => 0x4038,
    S_POSN_COL => 0x4039,
    S_POSN_ROW => 0x403a,
    CDFLAG     => 0x403b,
    PRBUFF     => 0x403c,
    MEMBOT     => 0x405d,
    FREE2      => 0x407b,
    PROG       => 0x407d,
);

my %zx81chars = (
    0x00 => ' ',
    0x0b => '"',
    0x0c => '#',
    0x0d => '$',
    0x0e => ':',
    0x0f => '?',
    0x10 => '(',
    0x11 => ')',
    0x12 => '>',
    0x13 => '<',
    0x14 => '=',
    0x15 => '+',
    0x16 => '-',
    0x17 => '*',
    0x18 => '/',
    0x19 => ';',
    0x1a => ',',
    0x1b => '.',
    0x1c => '0',
    0x1d => '1',
    0x1e => '2',
    0x1f => '3',
    0x20 => '4',
    0x21 => '5',
    0x22 => '6',
    0x23 => '7',
    0x24 => '8',
    0x25 => '9',
    0x26 => 'A',
    0x27 => 'B',
    0x28 => 'C',
    0x29 => 'D',
    0x2a => 'E',
    0x2b => 'F',
    0x2c => 'G',
    0x2d => 'H',
    0x2e => 'I',
    0x2f => 'J',
    0x30 => 'K',
    0x31 => 'L',
    0x32 => 'M',
    0x33 => 'N',
    0x34 => 'O',
    0x35 => 'P',
    0x36 => 'Q',
    0x37 => 'R',
    0x38 => 'S',
    0x39 => 'T',
    0x3a => 'U',
    0x3b => 'V',
    0x3c => 'W',
    0x3d => 'X',
    0x3e => 'Y',
    0x3f => 'Z',
    0x40 => 'RND',
    0x41 => 'INKEY$',
    0x42 => 'PI',
    0x80 => '% ',
    0x8b => '%"',
    0x8c => '%#',
    0x8d => '%$',
    0x8e => '%:',
    0x8f => '%?',
    0x90 => '%(',
    0x91 => '%)',
    0x92 => '%>',
    0x93 => '%<',
    0x94 => '%=',
    0x95 => '%+',
    0x96 => '%-',
    0x97 => '%*',
    0x98 => '%/',
    0x99 => '%;',
    0x9a => '%,',
    0x9b => '%.',
    0x9c => '%0',
    0x9d => '%1',
    0x9e => '%2',
    0x9f => '%3',
    0xa0 => '%4',
    0xa1 => '%5',
    0xa2 => '%6',
    0xa3 => '%7',
    0xa4 => '%8',
    0xa5 => '%9',
    0xa6 => '%A',
    0xa7 => '%B',
    0xa8 => '%C',
    0xa9 => '%D',
    0xaa => '%E',
    0xab => '%F',
    0xac => '%G',
    0xad => '%H',
    0xae => '%I',
    0xaf => '%J',
    0xb0 => '%K',
    0xb1 => '%L',
    0xb2 => '%M',
    0xb3 => '%N',
    0xb4 => '%O',
    0xb5 => '%P',
    0xb6 => '%Q',
    0xb7 => '%R',
    0xb8 => '%S',
    0xb9 => '%T',
    0xba => '%U',
    0xbb => '%V',
    0xbc => '%W',
    0xbd => '%X',
    0xbe => '%Y',
    0xbf => '%Z',
    0xc0 => '\\"',
    0xc1 => 'AT',
    0xc2 => 'TAB',
    0xc4 => 'CODE',
    0xc5 => 'VAL',
    0xc6 => 'LEN',
    0xc7 => 'SIN',
    0xc8 => 'COS',
    0xc9 => 'TAN',
    0xca => 'ASN',
    0xcb => 'ACS',
    0xcc => 'ATN',
    0xcd => 'LN',
    0xce => 'EXP',
    0xcf => 'INT',
    0xd0 => 'SQR',
    0xd1 => 'SGN',
    0xd2 => 'ABS',
    0xd3 => 'PEEK',
    0xd4 => 'USR',
    0xd5 => 'STR$',
    0xd6 => 'CHR$',
    0xd7 => 'NOT',
    0xd8 => '**',
    0xd9 => 'OR',
    0xda => 'AND',
    0xdb => '<=',
    0xdc => '>=',
    0xdd => '<>',
    0xde => 'THEN',
    0xdf => 'TO',
    0xe0 => 'STEP',
    0xe1 => 'LPRINT',
    0xe2 => 'LLIST',
    0xe3 => 'STOP',
    0xe4 => 'SLOW',
    0xe5 => 'FAST',
    0xe6 => 'NEW',
    0xe7 => 'SCROLL',
    0xe8 => 'CONT',
    0xe9 => 'DIM',
    0xea => 'REM',
    0xeb => 'FOR',
    0xec => 'GOTO',
    0xed => 'GOSUB',
    0xee => 'INPUT',
    0xef => 'LOAD',
    0xf0 => 'LIST',
    0xf1 => 'LET',
    0xf2 => 'PAUSE',
    0xf3 => 'NEXT',
    0xf4 => 'POKE',
    0xf5 => 'PRINT',
    0xf6 => 'PLOT',
    0xf7 => 'RUN',
    0xf8 => 'SAVE',
    0xf9 => 'RAND',
    0xfa => 'IF',
    0xfb => 'CLS',
    0xfc => 'UNPLOT',
    0xfd => 'CLEAR',
    0xfe => 'RETURN',
    0xff => 'COPY',
);

# bytes is a list of 5 bytes, representing a ZX81 floating point number
sub zx81_to_float {
    my (@bytes) = @_;

    # Zero special case
    if (   $bytes[0] == 0
        && $bytes[1] == 0
        && $bytes[2] == 0
        && $bytes[3] == 0
        && $bytes[4] == 0 )
    {

        return 0.0;
    }

    my $exp  = $bytes[0] - 128;
    my $sign = ( $bytes[1] & 0x80 ) ? -1.0 : 1.0;

    my $mant =
      ( ( $bytes[1] | 0x80 ) << 24 ) | ( $bytes[2] << 16 ) |
      ( $bytes[3] << 8 ) | ( $bytes[4] );

    my $value = $sign * $mant * ( 2**( $exp - 32 ) );
    return $value;
}

#------------------------------------------------------------------------------
# make_p driver
#------------------------------------------------------------------------------
sub make_p {
    my ( $basic_filename, $p_filename ) = @_;

    my $tape = ZX81::Tape->new();
    $tape->parse_file($basic_filename);
    $tape->compile();
    my $bytes = $tape->as_bytes();
    path($p_filename)->spew_raw($bytes);
    return;
}

#------------------------------------------------------------------------------
# dump_p
#------------------------------------------------------------------------------
sub dump_p {
    my ( $p_filename, $dump_filename ) = @_;
    my $dump_fh;
    if ( defined $dump_filename ) {
        open( $dump_fh, ">", $dump_filename )
          or die "error: open $dump_filename: $!\n";
    }
    else {
        $dump_fh = *STDOUT;
    }

    # load memory
    my @bytes = ( map { ord } split //, path($p_filename)->slurp_raw );
    my $mem   = ZX81::Tape::Memory->new( 0x4009, @bytes );

    # memory access helpers
    my $peek_text = sub {
        my ( $addr, $size ) = @_;
        my $text = "";
        for ( my $i = 0 ; $i < $size ; $i++ ) {
            my $byte = $mem->peek( $addr + $i );
            if ( $byte == 0x7E && $size > 1 ) {

                # floating point number
                my @bytes;
                for ( my $j = 1 ; $j < 6 ; $j++ ) {
                    push @bytes, $mem->peek( $addr + $i + $j );
                }
                my $float = zx81_to_float(@bytes);
                $text .= "{$float}";

                $i += 6 - 1;
            }
            elsif ( exists $zx81chars{$byte} ) {
                my $code = $zx81chars{$byte};
                if ( $code =~ /\w\w$/ ) {
                    $code .= " ";
                }
                $text .= $code;
            }
            else {
                $text .= sprintf( "\\%02X", $byte );
            }
        }
        return $text;
    };
    my $dump = sub {
        my ( $addr, $size, $text ) = @_;

        printf $dump_fh "%04X        %s\n", $addr, $text;
        for ( my $i = 0 ; $i < $size ; ) {
            my $bytes_dump  = "";
            my $text_dump   = "";
            my $num_dumpped = 0;
            for ( my $j = 0 ; $j < 8 && $i + $j < $size ; $j++ ) {
                my $byte = $mem->peek( $addr + $i + $j );
                $num_dumpped++;
                $bytes_dump .= sprintf( "%02X ", $byte );
                $text_dump  .= $peek_text->( $addr + $i + $j, 1 ) . " ";
                last if $byte == 0x76;
            }
            printf $dump_fh "%04X        %-26s  %s\n",
              $addr + $i, $bytes_dump, $text_dump;
            $i += $num_dumpped;
        }
    };

    my $prog   = $sysvars{PROG};
    my $d_file = $mem->dpeek( $sysvars{D_FILE} );
    my $vars   = $mem->dpeek( $sysvars{VARS} );
    my $e_line = $mem->dpeek( $sysvars{E_LINE} );

    # show system variables
    print $dump_fh "System Variables:\n";
    my %rev_sysvars;
    while ( my ( $name, $addr ) = each %sysvars ) {
        $rev_sysvars{$addr} = $name;
    }
    for ( my $addr = $sysvars{VERSN} ; $addr < $prog ; $addr++ ) {
        if ( $addr == $sysvars{PRBUFF} ) {

            # printer buffer
            $dump->( $addr, 33, "PRBUFF" );
            $addr += 33 - 1;
        }
        elsif ( $addr == $sysvars{MEMBOT} ) {

            # memory calculator area
            for ( my $i = 0 ; $i < 30 / 5 ; $i++ ) {
                my @bytes;
                for my $j ( 0 .. 4 ) {
                    push @bytes, $mem->peek( $addr + $i * 5 + $j );
                }
                my $float = zx81_to_float(@bytes);
                $dump->( $addr + 5 * $i, 5, "MEM[$i] = $float" );
            }

            $addr += 30 - 1;
        }
        elsif ( exists $rev_sysvars{ $addr + 1 } ) {

            # byte variable
            printf $dump_fh "%04X    %02X  %s\n", $addr, $mem->peek($addr),
              $rev_sysvars{$addr} // "";
        }
        else {
            # word variable
            printf $dump_fh "%04X  %04X  %s\n", $addr, $mem->dpeek($addr),
              $rev_sysvars{$addr} // "";
            $addr++;
        }
    }

    # show BASIC program
    print $dump_fh "\nBASIC Program:\n";
    for ( my $addr = $prog ; $addr < $d_file ; ) {
        my $line_num = $mem->dpeek_be($addr);
        my $size     = $mem->dpeek( $addr + 2 );
        $dump->(
            $addr, 4 + $size,
            "[$size] $line_num " . $peek_text->( $addr + 4, $size - 1 )
        );
        print $dump_fh "\n";

        # move to the next line (2 bytes for line number, 2 bytes for size)
        $addr += $size + 4;
    }

    # show D_FILE section
    print $dump_fh "\nD_FILE Section:\n";
    $dump->( $d_file, $vars - $d_file, "D_FILE" );

    # Show VARS section
    print $dump_fh "\nVARS Section:\n";
    my $addr = $vars;
    while ( $addr < $e_line ) {
        my ( $size, $text ) = decode_var( $mem, $addr );
        $dump->( $addr, $size, $text );
        $addr += $size;
    }
}

#------------------------------------------------------------------------------
# list basic program
#------------------------------------------------------------------------------
sub list_p {
    my ( $p_filename, $bas_filename ) = @_;

    my $bas_fh;
    if ( defined $bas_filename ) {
        open( $bas_fh, ">", $bas_filename )
          or die "error: open $bas_filename: $!\n";
    }
    else {
        $bas_fh = *STDOUT;
    }

    # load memory
    my @bytes = ( map { ord } split //, path($p_filename)->slurp_raw );
    my $mem   = ZX81::Tape::Memory->new( 0x4009, @bytes );

    # dump pragmas
    my $need_newline = 0;

    # dump AUTOSTART, AUTOSTART_LINE
    my $d_file = $mem->dpeek( $sysvars{D_FILE} );
    my $nxtlin = $mem->dpeek( $sysvars{NXTLIN} );
    if ( $nxtlin < $d_file ) {
        print $bas_fh "#AUTOSTART=1\n";
        print $bas_fh "#AUTOSTART_LINE=" . $mem->dpeek_be($nxtlin) . "\n";
        $need_newline = 1;
    }

    # dump FAST
    if ( ( $mem->peek( $sysvars{CDFLAG} ) & 0x40 ) == 0x00 ) {
        print $bas_fh "#FAST=1\n";
        $need_newline = 1;
    }

    # dump VARS
    my $vars   = $mem->dpeek( $sysvars{VARS} );
    my $e_line = $mem->dpeek( $sysvars{E_LINE} );
    my $addr   = $vars;
    while ( $addr < $e_line - 1 ) {
        my ( $size, $text ) = decode_var( $mem, $addr );
        print $bas_fh "#VARS $text\n";
        $addr += $size;
        $need_newline = 1;
    }

    # dump DFILE, DFILE_COLLAPSED
    my $dfile_collapsed = 0;
    if ( $vars - $d_file < 1 + 33 * 24 ) {
        print $bas_fh "#DFILE_COLLAPSED=1\n";
        $dfile_collapsed = 1;
        $need_newline    = 1;
    }
    my @dfile_lines = decode_dfile($mem);
    if ( !$dfile_collapsed ) {
        for (@dfile_lines) {
            s/\s+$//;    # trim trailing spaces
        }
        while ( @dfile_lines && $dfile_lines[-1] eq "" ) {
            pop @dfile_lines;
        }
    }
    for my $line (@dfile_lines) {
        print $bas_fh "#DFILE=\"$line\"\n";
        $need_newline = 1;
    }

    if ($need_newline) {
        print $bas_fh "\n";
    }

    # dump BASIC program
    my $prog = $sysvars{PROG};
    for ( my $addr = $prog ; $addr < $d_file ; ) {
        my $line_num = $mem->dpeek_be($addr);
        my $size     = $mem->dpeek( $addr + 2 );
        printf $bas_fh "%5d ", $line_num;

        # rem line with possible binary data
        if ( $mem->peek( $addr + 4 ) == 0xEA ) {    # REM
            my $has_binary_data = 0;
            for ( my $i = 1 ; $i < $size - 1 ; $i++ ) {
                if ( ( $mem->peek( $addr + 4 + $i ) & 0x40 ) == 0x40 ) {
                    $has_binary_data = 1;
                    last;
                }
            }
            if ($has_binary_data) {
                print $bas_fh " REM ";
                for ( my $i = 1 ; $i < $size - 1 ; $i++ ) {
                    printf $bas_fh "\\%02X", $mem->peek( $addr + 4 + $i );
                }
                print $bas_fh "\n";
            }
            else {
                print $bas_fh " REM ";
                for ( my $i = 1 ; $i < $size - 1 ; $i++ ) {
                    my $byte = $mem->peek( $addr + 4 + $i );
                    if ( ( $byte & 0x40 ) == 0 && exists $zx81chars{$byte} ) {
                        print $bas_fh $zx81chars{$byte};
                    }
                    else {
                        printf $bas_fh "\\%02X", $byte;
                    }
                }
                print $bas_fh "\n";
            }

            $addr += 4 + $size;
            next;
        }

        # BASIC text
        my $in_quote = 0;
        for ( my $i = 0 ; $i < $size - 1 ; $i++ ) {
            my $byte = $mem->peek( $addr + 4 + $i );
            if ( $byte == 0x0B ) {
                $in_quote = !$in_quote;
            }

            if ( $byte == 0xC0 ) {    # double quote
                print $bas_fh "\\\"";
            }
            elsif ( $byte == 0x7E ) {    # number
                $i += 5;
            }
            elsif ( $in_quote && ( $byte & 0x40 ) == 0x40 ) {
                printf $bas_fh "\\%02X", $byte;
            }
            elsif ( !$in_quote && $byte == 0 ) {
                printf $bas_fh "\\%02X", $byte;    # space
            }
            elsif ( exists $zx81chars{$byte} ) {
                my $code = $zx81chars{$byte};
                if ( $code =~ /^\w\w/ ) {
                    $code = " $code ";
                }
                printf $bas_fh $code;
            }
            else {
                printf $bas_fh "\\%02X", $byte;
            }
        }
        print $bas_fh "\n";

        $addr += 4 + $size;
        next;
    }
}

#------------------------------------------------------------------------------
# decode BASIC display
#------------------------------------------------------------------------------
sub decode_dfile {
    my ($mem)  = @_;
    my $d_file = $mem->dpeek( $sysvars{D_FILE} );
    my $vars   = $mem->dpeek( $sysvars{VARS} );

    # collect dfile lines
    my @dfile;
    for ( my $addr = $d_file + 1 ; $addr < $vars ; ) {
        my $line = "";
        for ( my $col = 0 ; $col < 33 ; $col++ ) {
            my $byte = $mem->peek( $addr++ );
            if ( $byte == 0x76 ) {    # end of line
                last;
            }
            elsif ( exists $zx81chars{$byte} ) {
                $line .= $zx81chars{$byte};
            }
            else {
                die "decode_dfile: unexpected byte $byte at $addr";
            }
        }
        push @dfile, $line;
    }

    # trim trailing empty lines
    while ( @dfile && $dfile[-1] eq "" ) {
        pop @dfile;
    }

    return @dfile;
}

#------------------------------------------------------------------------------
# decode BASIC vars
#------------------------------------------------------------------------------
sub decode_var {
    my ( $mem, $addr ) = @_;
    my $start_addr = $addr;

    my $byte = $mem->peek( $addr++ );
    if ( $byte == 0x80 ) {

        # end marker
        return ( 1, "end marker" );
    }

    if ( ( $byte & 0xE0 ) == 0x60 ) {

        # single letter variable
        $byte = ( $byte & 0x3F ) | 0x20;
        my $name = $zx81chars{$byte};

        my @bytes;
        for ( my $i = 0 ; $i < 5 ; $i++ ) {
            push @bytes, $mem->peek( $addr++ );
        }
        my $float = zx81_to_float(@bytes);
        return ( $addr - $start_addr, $name . "=$float" );
    }

    if ( ( $byte & 0xE0 ) == 0xA0 ) {

        # multiple letter variable
        $byte = ( $byte & 0x3F ) | 0x20;
        my $name = $zx81chars{$byte};    # first letter

        while ( ( $mem->peek($addr) & 0xC0 ) == 0x00 )
        {                                # second..before-last letters
            $byte = $mem->peek( $addr++ );
            $byte = ( $byte & 0x3F ) | 0x20;
            $name .= $zx81chars{$byte};    # second..before-last letters
        }

        $byte = $mem->peek( $addr++ );
        ( $byte & 0xC0 ) == 0x80
          or die "decode_var: unexpected byte $byte at $addr";
        $byte = ( $byte & 0x3F ) | 0x20;
        $name .= $zx81chars{$byte};    # last letter

        my @bytes;
        for ( my $i = 0 ; $i < 5 ; $i++ ) {
            push @bytes, $mem->peek( $addr++ );
        }
        my $float = zx81_to_float(@bytes);
        return ( $addr - $start_addr, $name . "=$float" );
    }

    if ( ( $byte & 0xE0 ) == 0x80 ) {

        # numeric array
        $byte = ( $byte & 0x3F ) | 0x20;
        my $name = $zx81chars{$byte};

        # array size
        my $size = $mem->dpeek($addr);
        $addr += 2;

        # number of dimensions
        my $num_dims = $mem->peek( $addr++ );

        # dimensions
        my $num_elements = 1;
        my @dims;
        for ( 1 .. $num_dims ) {
            my $dim = $mem->dpeek($addr);
            $addr += 2;
            push @dims, $dim;
            $num_elements *= $dim;
        }

        # values
        my @values;
        for ( 1 .. $num_elements ) {
            my @bytes;
            for ( my $i = 0 ; $i < 5 ; $i++ ) {
                push @bytes, $mem->peek( $addr++ );
            }
            my $float = zx81_to_float(@bytes);
            push @values, $float;
        }

        # text representation
        my $text =
          $name . "(" . join( ",", @dims ) . ")=" . join( ",", @values );
        return ( $addr - $start_addr, $text );
    }

    if ( ( $byte & 0xE0 ) == 0xE0 ) {

        # loop variable
        $byte = ( $byte & 0x3F ) | 0x20;
        my $name = $zx81chars{$byte};

        # value, limit, step
        my @values;
        for ( 1 .. 3 ) {
            my @bytes;
            for ( my $i = 0 ; $i < 5 ; $i++ ) {
                push @bytes, $mem->peek( $addr++ );
            }
            my $float = zx81_to_float(@bytes);
            push @values, $float;
        }

        # line number
        my $line_num = $mem->dpeek($addr);
        $addr += 2;
        push @values, $line_num;

        # text representation
        my $text = $name . "=" . join( ",", @values );

        return ( $addr - $start_addr, $text );
    }

    if ( ( $byte & 0xE0 ) == 0x40 ) {

        # string variable
        $byte = ( $byte & 0x3F ) | 0x20;
        my $name = $zx81chars{$byte};

        # string length
        my $length = $mem->dpeek($addr);
        $addr += 2;

        # string value
        my $value = '"';
        for ( my $i = 0 ; $i < $length ; $i++ ) {
            my $byte = $mem->peek( $addr++ );
            if ( exists $zx81chars{$byte} ) {
                $value .= $zx81chars{$byte};
            }
            else {
                die "decode_var: unexpected byte $byte at $addr";
            }
        }
        $value .= '"';

        # text representation
        my $text = $name . '$' . '=' . $value;
        return ( $addr - $start_addr, $text );
    }

    if ( ( $byte & 0xE0 ) == 0xC0 ) {

        # string array
        $byte = ( $byte & 0x3F ) | 0x20;
        my $name = $zx81chars{$byte};

        # array size
        my $size = $mem->dpeek($addr);
        $addr += 2;

        # number of dimensions
        my $num_dims = $mem->peek( $addr++ );

        # dimensions
        my $num_elements = 1;
        my @dims;
        for ( 1 .. $num_dims ) {
            my $dim = $mem->dpeek($addr);
            $addr += 2;
            push @dims, $dim;
            $num_elements *= $dim;
        }
        my $last_dim = $dims[-1];
        $num_elements /= $last_dim;

        # values
        my @values;
        for ( 1 .. $num_elements ) {
            my $value = '"';
            for ( my $i = 0 ; $i < $last_dim ; $i++ ) {
                my $byte = $mem->peek( $addr++ );
                if ( exists $zx81chars{$byte} ) {
                    $value .= $zx81chars{$byte};
                }
                else {
                    die "decode_var: unexpected byte $byte at $addr";
                }
            }
            $value .= '"';
            push @values, $value;
        }

        # text representation
        my $text =
          $name . '$' . "(" . join( ",", @dims ) . ")=" . join( ",", @values );

        return ( $addr - $start_addr, $text );
    }

    die "invalid byte $byte at ", $addr - 1;
}

#------------------------------------------------------------------------------
# input BASIC line
#------------------------------------------------------------------------------
{

    package ZX81::Tape::Line;
    use Object::Tiny::RW qw(
      src_file src_line_num
      line_num label text
      reminvert
      bytes
    );

    sub new {
        my ($class) = @_;
        return bless {
            src_file     => '',
            src_line_num =>  0,
            line_num     => -1,
            label        => '',
            text         => '',
            reminvert    => 0,
            bytes        => '',
        }, $class;
    }

    sub error {
        my ( $self, $message ) = @_;
        die $self->src_file, ":", $self->src_line_num, ": error: ",
          $message, "\n";
    }
}

#------------------------------------------------------------------------------
# BASIC variable
#------------------------------------------------------------------------------
{

    package ZX81::Tape::Var;
    use Object::Tiny::RW qw(
      name is_string is_array is_loop
      dims
      value limit step line_num
    );

    sub new {
        my ($class) = @_;
        return bless {
            name      => '',
            is_string => 0,
            is_array  => 0,
            is_loop   => 0,
            dims      => [],
            value     => [0],
            limit     =>  0,
            step      =>  0,
            line_num  => -1,
        }, $class;
    }
}

#------------------------------------------------------------------------------
# Tape class
#------------------------------------------------------------------------------
use Object::Tiny::RW qw(
  lines
  vars
  dfile
  dfile_collapsed
  last_line_num
  labels
  autostart autostart_line
  increment
  reminvert
  fast
);

sub new {
    my ($class) = @_;
    my $self = bless {
        lines           => [],
        vars            => [],
        dfile           => [],
        dfile_collapsed =>  0,
        last_line_num   => -1,
        labels          => {},
        autostart       => 0,
        autostart_line  => 0,
        increment       => 10,
        reminvert       => 0,
        fast            => 0,
    }, $class;
    return $self;
}

sub parse_file {
    my ( $self, $filename ) = @_;

    # read lines from file
    my @lines = path($filename)->lines( { chomp => 1 } );

    # add source line numbers
    for my $i ( 0 .. $#lines ) {
        my $line = ZX81::Tape::Line->new();
        $line->src_file($filename);
        $line->src_line_num( $i + 1 );
        $line->text( $lines[$i] );
        $lines[$i] = $line;
    }

    # join continuation lines
    for ( my $i = 0 ; $i < @lines ; $i++ ) {
        while ( $lines[$i]->{text} =~ s/\\$// && $i + 1 < @lines ) {
            $lines[$i]->text( $lines[$i]->text . $lines[ $i + 1 ]->text );
            splice( @lines, $i + 1, 1 );
        }
    }

    # parse labels and line numbers
    for my $line (@lines) {
        $self->parse_label_line_num($line);
    }

    # merge lines with only label or line number with next line
    for ( my $i = 0 ; $i < @lines - 1 ; $i++ ) {
        my $this = $lines[$i];
        my $next = $lines[ $i + 1 ];
        if ( $this->text =~ /^\s*$/ ) {
            my $num_labels =
              ( $this->label ne '' ? 1 : 0 ) + ( $next->label ne '' ? 1 : 0 );
            my $num_line_nums =
              ( $this->line_num >= 0 ? 1 : 0 ) +
              ( $next->line_num >= 0 ? 1 : 0 );
            if ( $num_labels <= 1 && $num_line_nums <= 1 ) {
                $this->label( $next->label )       if $next->label ne '';
                $this->line_num( $next->line_num ) if $next->line_num >= 0;
                $this->text( $next->text );
                splice( @lines, $i + 1, 1 );
                $i--;
            }
        }
    }

    # parse lines
    for ( my $i = 0 ; $i < @lines ; $i++ ) {
        my $line = $lines[$i];

        # skip blank lines
        if (   $line->text =~ /^\s*$/
            && $line->label eq ''
            && $line->line_num < 0 )
        {
            next;
        }

        # handle pragmas
        if ( $self->parse_pragma($line) ) {
            next;
        }

        # add reminvert tag
        $line->reminvert( $self->reminvert );

        # number the line
        if ( $line->line_num >= 0 ) {
            if ( $line->line_num <= $self->last_line_num ) {
                $line->error( "BASIC lines out of order: "
                      . $line->line_num
                      . " after "
                      . $self->last_line_num );
            }
            $self->last_line_num( $line->line_num );
        }
        else {
            my $new_line_num =
                $self->last_line_num < 0
              ? $self->increment
              : $self->last_line_num + $self->increment;
            $line->line_num($new_line_num);
            $self->last_line_num($new_line_num);
        }

        if ( $line->line_num > 9999 ) {
            $line->error(
                "BASIC line number exceeds 9999: " . $line->line_num );
        }

        # set the label if present
        if ( $line->label ne '' ) {
            if ( exists $self->labels->{ $line->label } ) {
                $line->error( "duplicate label: " . $line->label );
            }
            $self->labels->{ $line->label } = $line->line_num;
        }

        # add line to tape
        push @{ $self->lines }, $line;
    }
}

sub parse_pragma {
    my ( $self, $line ) = @_;

    if ( $line->text =~ /^\s*\#\s*AUTOSTART\s*=\s*(\d+)/ ) {
        $self->autostart( $1 == 0 ? 0 : 1 );
        return 1;
    }
    if ( $line->text =~ /^\s*\#\s*AUTOSTART_LINE\s*=\s*(\d+)/ ) {
        $self->autostart_line( 0 + $1 );
        return 1;
    }
    if ( $line->text =~ /^\s*\#\s*INCREMENT\s*=\s*(\d+)/ ) {
        $self->increment( 0 + $1 );
        return 1;
    }
    if ( $line->text =~ /^\s*\#\s*REMINVERT\s*=\s*(\d+)/ ) {
        $self->reminvert( $1 == 0 ? 0 : 1 );
        return 1;
    }
    if ( $line->text =~ /^\s*\#\s*FAST\s*=\s*(\d+)/ ) {
        $self->fast( $1 == 0 ? 0 : 1 );
        return 1;
    }
    if ( $line->text =~ /^\s*\#\s*VARS\s*(.*?)\s*=\s*(.*)/ ) {
        my $var = $self->parse_var( $line, $1, $2 );
        push @{ $self->vars }, $var if defined $var;
        return 1;
    }
    if ( $line->text =~ /^\s*\#\s*DFILE\s*=\s*\"(.*)\"/ ) {
        push @{ $self->dfile }, $1;
        return 1;
    }
    if ( $line->text =~ /^\s*\#\s*DFILE_COLLAPSED\s*=\s*(\d+)/ ) {
        $self->dfile_collapsed( $1 == 0 ? 0 : 1 );
        return 1;
    }
    if ( $line->text =~ /^\s*#/ ) {

        # unrecognized pragma, handle as comment
        return 1;
    }

    return 0;
}

sub parse_var {
    my ( $self, $line, $name, $value ) = @_;

    my $var = ZX81::Tape::Var->new();

    # collect variable name
    my $text = $name;
    $text =~ s/^\s*([a-z_]\w*)//i
      or $line->error( "invalid variable name: " . $name );
    $var->name($1);

    # collect '$' for string variable
    if ( $text =~ s/^\s*\$// ) {
        $var->is_string(1);
    }

    # collect array dimensions
    if ( $text =~ s/^\s*\((.*)\)// ) {
        $var->is_array(1);
        my @dims = split( /\s*,\s*/, $1 );
        for my $dim (@dims) {
            if ( $dim !~ /^\d+$/ ) {
                $line->error( "invalid array dimension: " . $dim );
            }
            push @{ $var->dims }, 0 + $dim;
        }
    }

    # check for any remaining text in the variable name
    if ( $text =~ /\S/ ) {
        $line->error( "invalid variable name: " . $name );
    }

    # check variable name length
    if ( $var->is_string || $var->is_array ) {
        if ( length( $var->name ) > 1 ) {
            $line->error( "invalid variable name: " . $name );
        }
    }

    # compute number of elements needed
    my $num_elements        = 1;
    my $size_string_element = 0;
    if ( $var->is_array ) {
        for my $dim ( @{ $var->dims } ) {
            $num_elements *= $dim;
        }
        if ( $var->is_string ) {
            $size_string_element = $var->dims->[-1];
            $num_elements /= $size_string_element;
        }
    }

    # collect variable values
    if ( !$var->is_string ) {
        my @values = split( /\s*,\s*/, $value );
        if ( @values == 4 && !$var->is_array ) {
            $var->is_loop(1);
        }
        elsif ( @values != $num_elements ) {
            $line->error(
                "number of values does not match array dimensions: " . $value );
        }
        for (@values) {
            if ( $_ !~ /^-?(\d+|\d*\.\d+|\d+\.\d*)(e[-+]?\d+)?$/i ) {
                $line->error( "invalid variable value: " . $_ );
            }
        }
        if ( $var->is_loop ) {
            $var->value( [ 0 + $values[0] ] );
            $var->limit( 0 + $values[1] );
            $var->step( 0 + $values[2] );
            $var->line_num( 0 + $values[3] );
        }
        else {
            $var->value( [ map { 0 + $_ } @values ] );
        }
    }
    else {
        $text = $value;
        my @values;
        while ( $text =~ s/^\s*("((?:[^"\\]|\\.)*)")\s*,?// ) {
            push @values, $2;
        }
        if ( @values != $num_elements ) {
            $line->error(
                "number of values does not match array dimensions: " . $value );
        }
        if ( $text =~ /\S/ ) {
            $line->error( "invalid string variable value: " . $text );
        }
        $var->value( [@values] );
    }

    return $var;
}

sub parse_label_line_num {
    my ( $self, $line ) = @_;

    my $got_any;
    while (1) {
        if (   $line->label eq ''
            && $line->{text} =~ s/^\s*\@([a-z_]\w+)\s*:\s*//i )
        {
            $line->label($1);
            $got_any = 1;
        }
        elsif ( $line->line_num < 0 && $line->{text} =~ s/^\s*(\d+)\s*//i ) {
            $line->line_num($1);
            $got_any = 1;
        }
        else {
            last;
        }
    }
    $line->{text} =~ s/^\s+//;

    return $got_any;
}

sub compile {
    my ($self) = @_;

    # remove empty lines
    @{ $self->lines } = grep { $_->text !~ /^\s*$/ } @{ $self->lines };

    # replace all labels with line numbers
    for my $line ( @{ $self->lines } ) {
        while ( $line->{text} =~ /\@([a-z_]\w+)/ ) {
            my $label = $1;
            if ( !exists $self->labels->{$label} ) {
                $line->error( "undefined label: " . $label );
            }
            my $line_num = $self->labels->{$label};
            $line->{text} =~ s/\@$label/$line_num/g;
        }
    }

    # replace &label with line address
    my %line_addr;
    my $old_size = 0;
    for ( my $pass = 1 ; $pass <= 2 ; $pass++ ) {
        my $bin = '';
        for my $line ( @{ $self->lines } ) {

            # calculate the address of the line
            if ( $line->label ne '' ) {
                $line_addr{ $line->label } = 0x407D + length($bin);
            }

            # replace &label with line address
            my $text = $line->line_num . " " . $line->text;
            while ( $text =~ /\&([a-z_]\w+)/i ) {
                my $label = $1;
                if ( !exists $self->labels->{$label} ) {
                    $line->error( "undefined label: " . $label );
                }
                my $addr = $line_addr{$label} // 0;
                $text =~ s/\&$label/$addr/g;
            }

            # apply reminvert if requested
            if ( $line->reminvert ) {
                $text = $self->invert_rem($text);
            }

            my $line_bytes = tokenize_basic($text);
            $line->bytes($line_bytes);
            $bin .= $line_bytes;
        }

        my $new_size = length($bin);
        if ( $old_size != $new_size ) {
            $old_size = $new_size;
            $pass     = 0;           # repeat if size changed
        }
    }
}

sub invert_rem {
    my ( $self, $text ) = @_;
    if ( $text =~ /^(\s*\d+\s+REM ?)(.*)$/i ) {
        my ( $rem_statement, $rem_text ) = ( $1, $2 );
        if ( $rem_text =~ /\\/ ) {

            # don't invert if there are escape sequences
            return $text;
        }

        # invert (prepend %) to all not inverted characters
        my @chars = $rem_text =~ /(\%?[^\%])/g;
        for (@chars) { s/^([^\%])/\%$1/; }    # invert C to %C
        $rem_text = join( '', @chars );

        return $rem_statement . $rem_text;
    }
    return $text;
}

sub as_bytes {
    my ($self) = @_;

    # Convert the stored BASIC lines to a byte string
    my $prog = '';
    my @line_addr;
    for my $line ( @{ $self->lines } ) {
        push @line_addr, [ $line->line_num, $sysvars{PROG} + length($prog) ];
        $prog .= $line->bytes;
    }
    push @line_addr, [ 10000, $sysvars{PROG} + length($prog) ];

    my $prog_start = $sysvars{PROG};
    my $e_ppc      = $prog eq '' ? 0 : unpack( "n", substr( $prog, 0, 2 ) );

    # Create an empty display file
    my $dfile       = $self->dfile_as_bytes();
    my $dfile_start = $prog_start + length($prog);

    # Create an empty vars area
    my $vars       = $self->vars_as_bytes();
    my $vars_start = $dfile_start + length($dfile);
    my $mem_end    = $vars_start + length($vars);

    # define autostart
    my $nxtlin = $dfile_start;
    if ( $self->autostart ) {

        # get address of first line at or after autostart line
        my $autostart_line = $self->autostart_line;
        for my $line_addr (@line_addr) {
            if ( $line_addr->[0] >= $autostart_line ) {
                $nxtlin = $line_addr->[1];
                last;
            }
        }
    }

    # define fast mode
    my $cdflag = $self->fast ? 0x00 : 0x40;    # SLOW if not fast

    # Create the system variables
    my $bytes = '';
    $bytes .= pack( "C",            0 );                   # VERSN
    $bytes .= pack( "v",            $e_ppc );              # E_PPC
    $bytes .= pack( "v",            $dfile_start );        # D_FILE
    $bytes .= pack( "v",            $dfile_start + 1 );    # DF_CC
    $bytes .= pack( "v",            $vars_start );         # VARS
    $bytes .= pack( "v",            0 );                   # DEST
    $bytes .= pack( "v",            $mem_end );            # E_LINE
    $bytes .= pack( "v",            $mem_end + 1 );        # CH_ADD
    $bytes .= pack( "v",            0 );                   # X_PTR
    $bytes .= pack( "v",            $mem_end + 2 );        # STKBOT
    $bytes .= pack( "v",            $mem_end + 2 );        # STKEND
    $bytes .= pack( "C",            0 );                   # BREG
    $bytes .= pack( "v",            0x405d );              # MEM
    $bytes .= pack( "C",            0 );                   # not used
    $bytes .= pack( "C",            2 );                   # DF_SZ
    $bytes .= pack( "v",            0 );                   # S_TOP
    $bytes .= pack( "v",            0xFFFF );              # LAST_K
    $bytes .= pack( "C",            0x0F );                # DEBOUNCE
    $bytes .= pack( "C",            55 );                  # MARGIN
    $bytes .= pack( "v",            $nxtlin );             # NXTLIN
    $bytes .= pack( "v",            0 );                   # OLDPPC
    $bytes .= pack( "C",            0 );                   # FLAGX
    $bytes .= pack( "v",            0 );                   # STRLEN
    $bytes .= pack( "v",            0x0C6B );              # T_ADDR
    $bytes .= pack( "v",            0 );                   # SEED
    $bytes .= pack( "v",            0xFFFF );              # FRAMES
    $bytes .= pack( "C*",           0, 0 );                # COORDS
    $bytes .= pack( "C",            0xBC );                # PR_CC
    $bytes .= pack( "C*",           33, 24 );              # S_POSN
    $bytes .= pack( "C",            $cdflag );             # CDFLAG
    $bytes .= pack( "C*", (0) x 32, 0x76 );                # Print buffer
    $bytes .= pack( "C*", (0) x 30 );    # Calculator's memory area
    $bytes .= pack( "C*", (0) x 2 );     # not used

    # Pack the BASIC program, dfile and vars areas
    $bytes .= $prog;
    $bytes .= $dfile;
    $bytes .= $vars;

    return $bytes;
}

sub dfile_as_bytes {
    my ($self) = @_;

    my @lines = @{ $self->dfile };
    my $bytes = pack( "C", 0x76 );
    for ( 1 .. 24 ) {
        my $line = shift @lines // '';
        if ( $self->dfile_collapsed ) {
            $line =~ s/\s+$//;
        }
        else {
            $line .= ' ' x 32;
        }
        $line = substr( $line, 0, 32 );

        $bytes .= pack( "C*", map { ord } split //, encode_chars($line) );
        $bytes .= pack( "C", 0x76 );
    }

    return $bytes;
}

sub vars_as_bytes {
    my ($self) = @_;

    my $bytes = '';
    for my $var ( @{ $self->vars } ) {
        my @name_bytes = map { ord } split //, encode_chars( $var->name );
        if ( $var->is_loop ) {

            # loop variable
            # 111-letter
            $bytes .= pack( "C", ( $name_bytes[0] & 0x3F ) | 0xE0 );

            # value
            $bytes .= encode_float( $var->value->[0] );

            # limit
            $bytes .= encode_float( $var->limit );

            # step
            $bytes .= encode_float( $var->step );

            # line number
            $bytes .= pack( "v", $var->line_num );
        }
        elsif ( $var->is_string ) {
            if ( $var->is_array ) {

                # string array variable
                my $num_values = 1;
                for my $dim ( @{ $var->dims } ) {
                    $num_values *= $dim;
                }
                my $last_dim = $var->dims->[-1];
                $num_values /= $last_dim;

                # 110-letter
                $bytes .= pack( "C", ( $name_bytes[0] & 0x1F ) | 0xC0 );

                # total size of array in bytes
                $bytes .= pack( "v",
                    1 + 2 * scalar( @{ $var->dims } ) +
                      $last_dim * $num_values );

                # number of dimensions
                $bytes .= pack( "C", scalar( @{ $var->dims } ) );

                # dimensions
                for my $dim ( @{ $var->dims } ) {
                    $bytes .= pack( "v", $dim );
                }

                # values
                for ( 0 .. $num_values - 1 ) {
                    my $value = $var->value->[$_];

                    # make fixed length
                    $value .= ' ' x $last_dim;
                    $value = substr( $value, 0, $last_dim );

                    # convert to bytes
                    my @value_bytes = map { ord } split //,
                      encode_chars($value);
                    $bytes .= pack( "C*", @value_bytes );
                }
            }
            else {
                # string variable
                my @value_bytes = map { ord } split //,
                  encode_chars( $var->value->[0] );

                # 010-letter
                $bytes .= pack( "C", ( $name_bytes[0] & 0x1F ) | 0x40 );

                # length of string
                $bytes .= pack( "v", scalar(@value_bytes) );

                # string bytes
                $bytes .= pack( "C*", @value_bytes );
            }
        }
        else {
            if ( $var->is_array ) {

                # numeric array variable
                my $num_values = 1;
                for my $dim ( @{ $var->dims } ) {
                    $num_values *= $dim;
                }

                # 100-letter
                $bytes .= pack( "C", ( $name_bytes[0] & 0x1F ) | 0x80 );

                # total size of array in bytes
                $bytes .= pack( "v",
                    1 + 2 * scalar( @{ $var->dims } ) + 5 * $num_values );

                # number of dimensions
                $bytes .= pack( "C", scalar( @{ $var->dims } ) );

                # dimensions
                for my $dim ( @{ $var->dims } ) {
                    $bytes .= pack( "v", $dim );
                }

                # values
                for ( 0 .. $num_values - 1 ) {
                    $bytes .= encode_float( $var->value->[$_] );
                }
            }
            else {
                # numeric variable
                if ( @name_bytes == 1 ) {

                    # 011-letter
                    $bytes .= pack( "C", ( $name_bytes[0] & 0x3F ) | 0x60 );
                }
                else {
                    # 101-letter, 001-letter, 101-letter
                    $bytes .= pack( "C", ( $name_bytes[0] & 0x3F ) | 0xA0 );
                    for ( 1 .. $#name_bytes - 1 ) {
                        $bytes .= pack( "C", $name_bytes[$_] & 0x3F );
                    }
                    $bytes .= pack( "C", ( $name_bytes[-1] & 0x3F ) | 0x80 );
                }

                # pack value
                $bytes .= encode_float( $var->value->[0] );
            }
        }
    }

    $bytes .= pack( "C", 0x80 );    # end of vars
    return $bytes;
}

1;

__END__

#------------------------------------------------------------------------------

=pod

=head1 NAME

ZX81::Tape - Create ZX81 tape image files

=head1 SYNOPSIS

    use ZX81::Tape qw(make_p dump_p list_p);

    make_p($basic_filename, $p_filename);
    dump_p($p_filename[, $dump_filename]);
    list_p($p_filename[, $bas_filename]);

=head1 DESCRIPTION

This module converts a BASIC source file to a ZX81 .p tape file.

=head1 FUNCTIONS

=head2 make_p

    make_p($basic_filename, $p_filename);

Reads the given source BASIC file and builds a binary tape image file.p_filename 
with the given file name.

=head2 dump_p

    dump_p($p_filename[, $dump_filename]);

Reads the given binary tape image file and dumps its contents to the 
standard output or a specified file with the given file name.

=head2 list_p

    list_p($p_filename[, $bas_filename]);

Reads the given binary tape image file and generates a .bas text that 
can be compiled back to the same .p result.

=head1 BASIC SYNTAX

All ZX81 BASIC keywords are accepted. The escape sequences supported by 
L<https://freestuff.grok.co.uk/zxtext2p/index.html> are also accepted.

Line numbers are optional and the source program is numbered before conversion
to the tape format. The start line number is 10 by default and the increment
between consecutive lines is also 10 by default. A line with a line number
resets the numbering from there on. Line numbers from 0 to 9999 are accepted.

=head2 LABELS

Labels can be written before the BASIC statement as '@' NAME ':', and can be
referenced as '@' NAME, e.g.

    @LOOP: PRINT "HELLO"
           GOTO @LOOP

The address of the line can be referenced as '&' NAME, e.g.

    @MCODE: REM \C9
            PRINT USR &MCODE

=head2 PRAGMAS

=head3 #AUTOSTART

    #AUTOSTART=[0|1]

If set to 1, the BASIC program will start automatically when the tape is 
loaded.

=head3 #AUTOSTART_LINE

    #AUTOSTART=[LINE_NUMBER]

If AUTOSTART_LINE is set, sets the line number where the BASIC program
will start automatically when the tape is loaded, defaults to the first
line of the BASIC program.

=head3 #INCREMENT

    #INCREMENT=[INCREMENT]

If INCREMENT is set, specifies the line number increment between consecutive
lines in the BASIC program, defaults to 10. Can be entered multiple times in
the source file, and takes effect from the line where it is set.

=head3 #REMINVERT

    #REMINVERT=[0|1]

If set to 1, inverts the REM statements in the BASIC program. Only applies
to REM statements that do not contain binary data.

=head3 #FAST

    #FAST=[0|1]

If set to 1, sets the computer in FAST mode.

=head3 #VARS

    #VARS A=123
    #VARS I=0,10,1,20
    #VARS S$="HELLO"
    #VARS M(2,3)=11,12,13,21,22,23
    #VARS M$(2,3,2)="AA","AB","AC","BA","BB","BC"

Specifies the initial values of variables in the BASIC program. I in the
example above is a loop variable with value 0, limit 10, step 1 and line 
number 20.

=head3 #DFILE

    #DFILE="LINE 1"
    #DFILE="LINE 2"
    ...

Defines the initial contents of the display file. Each line of the display
file is defined by a separate #DFILE pragma.

=head3 #DFILE_COLLAPSED

    #DFILE_COLLAPSED=[0|1]

Saves the display file in collapsed form.

=head1 SEE ALSO

L<ZX81>
L<https://freestuff.grok.co.uk/zxtext2p/index.html>

=head1 AUTHOR

Paulo Custodio

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 Paulo Custodio.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
