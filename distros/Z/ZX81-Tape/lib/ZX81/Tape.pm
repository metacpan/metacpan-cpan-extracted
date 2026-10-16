package ZX81::Tape;

use Modern::Perl;
use Path::Tiny;
use ZX81::Tokenize qw( tokenize_basic );

our $VERSION = '0.001';

use Exporter qw(import);

our @EXPORT_OK = qw(
  make_p
  dump_p
);

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

#------------------------------------------------------------------------------
# driver
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
    my @mem = ( map { ord } split //, path($p_filename)->slurp_raw );

    # memory access helpers
    my $peek = sub {
        my ($addr) = @_;
        return $mem[ $addr - 0x4009 ];
    };
    my $dpeek = sub {
        my ($addr) = @_;
        return $mem[ $addr - 0x4009 ] | ( $mem[ $addr + 1 - 0x4009 ] << 8 );
    };
    my $dpeek_be = sub {
        my ($addr) = @_;
        return ( $mem[ $addr - 0x4009 ] << 8 ) | $mem[ $addr + 1 - 0x4009 ];
    };
    my $peek_text = sub {
        my ( $addr, $size ) = @_;
        my $text = "";
        for ( my $i = 0 ; $i < $size ; $i++ ) {
            my $byte = $peek->( $addr + $i );
            if ( $byte == 0x7E ) {

                # floating point number
                for ( my $j = 0 ; $j < 6 ; $j++ ) {
                    $text .= sprintf( "\\%02X", $peek->( $addr + $i + $j ) );
                }
                $i += 6 - 1;
            }
            elsif ( exists $zx81chars{$byte} ) {
                my $code = $zx81chars{$byte};
                if ( length($code) > 1 && $code =~ /\w$/ ) {
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

    my $prog   = $sysvars{PROG};
    my $d_file = $dpeek->( $sysvars{D_FILE} );
    my $vars   = $dpeek->( $sysvars{VARS} );
    my $e_line = $dpeek->( $sysvars{E_LINE} );

    # show system variables
    print $dump_fh "System Variables:\n";
    my %rev_sysvars;
    while ( my ( $name, $addr ) = each %sysvars ) {
        $rev_sysvars{$addr} = $name;
    }
    for ( my $addr = $sysvars{VERSN} ; $addr < $prog ; $addr++ ) {
        if ( $addr == $sysvars{PRBUFF} ) {

            # printer buffer
            printf $dump_fh "%04X        %s\n", $addr,
              $rev_sysvars{$addr} // "";
            printf $dump_fh "      ";
            for ( my $i = 0 ; $i < 33 ; $i++ ) {
                printf $dump_fh "%02X ", $peek->( $addr + $i );
            }
            print $dump_fh "\n";
            $addr += 33 - 1;
        }
        elsif ( $addr == $sysvars{MEMBOT} ) {

            # calculator memory bottom
            printf $dump_fh "%04X        %s\n", $addr,
              $rev_sysvars{$addr} // "";
            printf $dump_fh "      ";
            for ( my $i = 0 ; $i < 30 ; $i++ ) {
                printf $dump_fh "%02X ", $peek->( $addr + $i );
            }
            print $dump_fh "\n";
            $addr += 30 - 1;
        }
        elsif ( exists $rev_sysvars{ $addr + 1 } ) {

            # byte variable
            printf $dump_fh "%04X    %02X  %s\n", $addr, $peek->($addr),
              $rev_sysvars{$addr} // "";
        }
        else {
            # word variable
            printf $dump_fh "%04X  %04X  %s\n", $addr, $dpeek->($addr),
              $rev_sysvars{$addr} // "";
            $addr++;
        }
    }

    # show BASIC program
    print $dump_fh "\nBASIC Program:\n";
    for ( my $addr = $prog ; $addr < $d_file ; ) {
        my $line_num = $dpeek_be->($addr);
        my $size     = $dpeek->( $addr + 2 );
        printf $dump_fh "%04X  %4d %s\n", $addr, $line_num,
          $peek_text->( $addr + 4, $size - 1 );
        $addr += $size +
          4; # move to the next line (2 bytes for line number, 2 bytes for size)
    }

    # show D_FILE section
    print $dump_fh "\nD_FILE Section:\n";
    for ( my $addr = $d_file ; $addr < $vars ; ) {
        printf $dump_fh "%04X  ", $addr;
        for ( ; $addr < $vars ; $addr++ ) {
            printf $dump_fh "%02X ", $peek->($addr);
            if ( $peek->($addr) == 0x76 ) {
                last;
            }
        }
        print $dump_fh "\n";
        $addr++;
    }

    # Show VARS section
    print $dump_fh "\nVARS Section:\n";
    for ( my $addr = $vars ; $addr < $e_line ; $addr++ ) {
        printf $dump_fh "%04X    %02X  \n", $addr, $peek->($addr);
    }
}

#------------------------------------------------------------------------------
# input BASIC line
#------------------------------------------------------------------------------
{

    package ZX81::Tape::Line;
    use Object::Tiny::RW qw(
      src_file src_line_num
      line_num label text
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
# Tape class
#------------------------------------------------------------------------------
use Object::Tiny::RW qw(
  lines
  last_line_num increment
);

sub new {
    my ($class) = @_;
    my $self = bless {
        lines         => [],
        last_line_num => -1,
        increment     => 10,
    }, $class;
    return $self;
}

sub parse_file {
    my ( $self, $filename ) = @_;

    open( my $fh, "<", $filename ) or die "error: open $filename: $!\n";
    my $src_line_num = 0;
    my $getline      = sub {
        my $text = <$fh>;
        return undef unless defined $text;
        chomp $text;
        $src_line_num++;
        return $text;
    };

    while ( defined( my $text = $getline->() ) ) {

        # join continuation lines
        while ( $text =~ s/\\$// && defined( my $cont = $getline->() ) ) {
            $text .= $cont;
        }

        # skip blank lines
        if ( $text =~ /^\s*$/ ) {
            next;
        }

        # create line
        my $line = ZX81::Tape::Line->new();
        $line->src_file($filename);
        $line->src_line_num($src_line_num);
        $line->text($text);

        # handle pragmas
        if ( $self->parse_pragma($line) ) {
            next;
        }

        # parse label and line number
        if ( $self->parse_label_line_num($line) ) {

            # if text is now empty, read next line
            if ( $line->text =~ /^\s*$/ ) {
                $text = $getline->();
                while ( $text =~ s/\\$// && defined( my $cont = $getline->() ) )
                {
                    $text .= $cont;
                }
            }
            $line->text($text);
        }

        # encode line into tape bytes
        my $bytes = tokenize_basic( $line->text );
        $line->bytes($bytes);

        # add line to tape
        push @{ $self->lines }, $line;
    }
}

sub parse_pragma {
    my ( $self, $line ) = @_;

    if ( $line->text =~ /^\s*\#\s*INCREMENT\s*=\s*(\d+)/ ) {
        $self->increment($1);
        return 1;
    }
    if ( $line->text =~ /^\s*#/ ) {

        # unrecognized pragma, handle as comment
        return 1;
    }

    return 0;
}

sub parse_label_line_num {
    my ( $self, $line ) = @_;

    my $got_label;
    my $got_line_num;
    my $got_any;
    while (1) {
        if ( !$got_label && $line->{text} =~ s/^\s*\@([a-z_]\w+)\s*:\s*//i ) {
            $line->label($1);
            $got_label = $got_any = 1;
        }
        elsif ( !$got_line_num && $line->{text} =~ s/^\s*(\d+)\s*//i ) {
            $line->line_num($1);
            $got_line_num = $got_any = 1;
        }
        else {
            last;
        }
    }
    $line->{text} =~ s/^\s+//;

    return $got_any;
}

sub compile { }

sub add_basic_line {
    my ( $self, $text ) = @_;

    if ( $text =~ /^\s*\#\s*INCREMENT\s*=\s*(\d+)/ ) {
        $self->increment($1);
    }
    elsif ( $text =~ /^\s*\#/ ) {

        # comment
    }
    elsif ( $text =~ /^\s*$/ ) {

        # blank line
    }
    else {
        my $line = ZX81::Tape::Line->new();

        # parse label and line number
        $text = $self->parse_label_line_num( $text, $line );

        # assign line number
        if ( $line->line_num < 0 ) {
            my $new_line_num = $self->last_line_num + $self->increment;
            $line->line_num($new_line_num);
            $self->last_line_num($new_line_num);
        }
        elsif ( $line->line_num <= $self->last_line_num ) {
            die "BASIC lines out of order: ",
              $line->line_num, " after ", $self->last_line_num;
        }
        else {
            $self->last_line_num( $line->line_num );
        }

        # tokenize text
        my $bytes = tokenize_basic( $line->line_num . " " . $text );
        $line->text($text);
        $line->bytes($bytes);

        # append to program
        push @{ $self->basic }, $line;
    }
}

sub add_basic {
    my ( $self, $basic ) = @_;
    $basic =~ s/\\\n/ /g;    # join continuation lines
    for my $text ( split( /\n/, $basic ) ) {
        $self->add_basic_line($text);
    }
}

sub as_bytes {
    my ($self) = @_;

    # Convert the stored BASIC lines to a byte string
    my $prog = '';
    for my $line ( @{ $self->lines } ) {
        $prog .= $line->bytes;
    }
    my $prog_start = 0x407D;
    my $e_ppc      = $prog eq '' ? 0 : unpack( "n", substr( $prog, 0, 2 ) );

    # Create an empty display file
    my $dfile = pack( "C", 0x76 );
    for ( 1 .. 24 ) {
        $dfile .= ( pack( "C", 0 ) x 32 ) . pack( "C", 0x76 );
    }
    my $dfile_start = $prog_start + length($prog);

    # Create an empty vars area
    my $vars       = pack( "C", 0x80 );
    my $vars_start = $dfile_start + length($dfile);
    my $mem_end    = $vars_start + length($vars);

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
    $bytes .= pack( "v",            $dfile_start );        # NXTLIN
    $bytes .= pack( "v",            0 );                   # OLDPPC
    $bytes .= pack( "C",            0 );                   # FLAGX
    $bytes .= pack( "v",            0 );                   # STRLEN
    $bytes .= pack( "v",            0x0C6B );              # T_ADDR
    $bytes .= pack( "v",            0 );                   # SEED
    $bytes .= pack( "v",            0xFFFF );              # FRAMES
    $bytes .= pack( "C*",           0, 0 );                # COORDS
    $bytes .= pack( "C",            0xBC );                # PR_CC
    $bytes .= pack( "C*",           33, 24 );              # S_POSN
    $bytes .= pack( "C",            0x40 );                # CDFLAG - SLOW
    $bytes .= pack( "C*", (0) x 32, 0x76 );                # Print buffer
    $bytes .= pack( "C*", (0) x 30 );    # Calculator's memory area
    $bytes .= pack( "C*", (0) x 2 );     # not used

    # Pack the BASIC program, dfile and vars areas
    $bytes .= $prog;
    $bytes .= $dfile;
    $bytes .= $vars;

    return $bytes;
}

1;

__END__

#------------------------------------------------------------------------------

=pod

=head1 NAME

ZX81::Tape - Create ZX81 tape image files

=head1 SYNOPSIS

    use ZX81::Tape qw(make_p);
    make_p($basic_filename, $p_filename);
	dump_p($p_filename[, $dump_filename]);

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
