package Tk::TextVi;

use strict;
use warnings;

our $VERSION = '0.015';

#use Data::Dump qw|dump|;

use Tk;
use Tk::TextUndo ();
use base qw'Tk::Derived Tk::TextUndo';

use Carp qw'carp croak';

Construct Tk::Widget 'TextVi';

# Constants for keys that Tk treats special
sub BKSP () { "\cH" }
sub TAB  () { "\cI" }
sub ESC  () { "\c[" }

# Constants used for exceptions
sub X_NO_KEYS   () { "VI_NO_KEYS\n" }
sub X_BAD_STATE () { "VI_BAD_STATE\n" }
sub X_NO_MOTION () { "VI_NO_MOTION\n" }

# Constants used for flags
sub F_STAT () { 1 }
sub F_MSG () { 2 }
sub F_ERR () { 4 }

# Indentifier-legal names for special characters
my %names = (
    '<' => '_lt',
    '>' => '_gt',
);

my %settings = (
    # name => [ value, default, type ]
    # name => \'longname'

    'softtabstop' => [ 4, 4, 'int' ],
    'sts' => \'softtabstop',
);

# Default command mappings and what file holds their test data
my %map = (
    n => {
        a => \&vi_n_a,                              # 30-insert
        b => \'B',
        d => \&vi_n_d,                              # 20-delete
        e => \'E',
        f => \&vi_n_f,                              # 13-findchar
        g => {
            a => \&vi_n_ga,                         # 60-info
            g => \&vi_n_gg,                         # 10-move
        },
        h => \&vi_n_h,                              # 10-move
        i => \&vi_n_i,                              # 30-insert
        j => \&vi_n_j,                              # 10-move
        k => \&vi_n_k,                              # 10-move
        l => \&vi_n_l,                              # 10-move
        m => \&vi_n_m,                              # 11-mark
        n => \&vi_n_n,                              # 15-search
        o => \&vi_n_o,                              # 30-insert
        p => \&vi_n_p,                              # 40-register
        q => \&vi_n_q,                              # 41-macro
        r => \&vi_n_r,                              # 21-replace
        t => \&vi_n_t,                              # 13-findchar
        u => \&vi_n_u,
        v => \&vi_n_v,                              # 32-vchar
        w => \'W',
        x => \'dl',                                 # 20-delete
        y => \&vi_n_y,                              # 40-register

        A => \'$a',
        B => \&vi_n_B,
        D => \'d$',                                 # 20-delete
        E => \&vi_n_E,                              # 12-word
        G => \&vi_n_G,                              # 10-move
        I => \&vi_n_I,
        O => \&vi_n_O,                              # 30-insert
        R => \&vi_n_R,
        V => \&vi_n_V,                              # 33-vline
        W => \&vi_n_W,                              # 12-word

        0 => [ 'insert linestart', 'char', 'inc' ], # 10-move

        '~' => \&vi_n_tilde,
        '`' => \&vi_n_backtick,                     # 11-mark
        '@' => \&vi_n_at,                           # 41-macro
        '$' => \&vi_n_dollar,                       # 10-move
        '%' => \&vi_n_percent,                      # 14-findline
        ':' => \&vi_n_colon,
        '/' => \&vi_n_fslash,                       # 15-search
    },
    c => {
        '' => \&vi_c_none,
        map => \&vi_c_map,
        noh => \&vi_c_nohlsearch,
        nohl => \&vi_c_nohlsearch,
        nohlsearch => \&vi_c_nohlsearch,
        set => \&vi_c_set,
        split => \&vi_c_split,
    },
    v => {
        d => \&vi_n_d,
        f => \&vi_n_f,
        e => \'E',
        g => {
            g => [ '1.0', 'line', 'inc' ],
        },
        h => \&vi_n_h,
        j => \&vi_n_j,
        k => \&vi_n_k,
        l => \&vi_n_l,
        t => \&vi_n_t,
        r => \&vi_n_r,
        w => \'W',
        y => \&vi_n_y,

        E => \&vi_n_E,
        G => \&vi_n_G,
        W => \&vi_n_W,

        0 => [ 'insert linestart', 'char', 'inc' ],

        '~' => \&vi_n_tilde,
        '`' => \&vi_n_backtick,
        '$' => \&vi_n_dollar,
        '%' => \&vi_n_percent,
        '"' => \&vi_n_quote,
        ':' => \&vi_n_colon,
    }
);

# Tk derived class initializer
sub ClassInit {
    my( $self, $mw ) = @_;

    $self->SUPER::ClassInit( $mw );

    # TODO: Kill default Tk::Text Bindings

    # Convert keys that Tk handles specially into normal keys
    # TODO: Add missing keys
    $mw->bind( $self, '<BackSpace>',    [ 'InsertKeypress', BKSP ] );
    $mw->bind( $self, '<Tab>',          [ 'InsertKeypress', TAB ] );
    $mw->bind( $self, '<Escape>',       [ 'InsertKeypress', ESC ] );
    $mw->bind( $self, '<Return>',       [ 'InsertKeypress', "\n" ] );

    # Rebind the control keys to give characters
    # TODO: Add remaining
    $mw->bind( $self, '<Control-o>',    [ 'InsertKeypress', "\cO" ] );

    return $self;
}

# Constructor
sub Populate {
    my ($w,$args) = @_;

    $w->SUPER::Populate( $args );

    $w->{VI_PENDING} = '';      # Pending command
    $w->{VI_MODE} = 'n';        # Start in normal mode
    $w->{VI_SUBMODE} = '';      # No submode
    $w->{VI_REGISTER} = { };    # Empty registers
    $w->{VI_SETTING} = { };     # No settings
    $w->{VI_ERROR} = [ ];       # Pending errors
    $w->{VI_MESSAGE} = [ ];     # Pending messages
    $w->{VI_FLAGS} = 0;         # Pending flags
    $w->{VI_COMMANDS} = { };    # External commands

    # XXX: There might be a legit reason in the future to have two
    # Tk::TextVi widgets with different mappings.
    $w->{VI_MAPS} = \%map;   # Command mapping

    $w->tagConfigure( 'VI_SEARCH', -background => '#FFFF00' );

    $w->ConfigSpecs(
        -statuscommand  =>['CALLBACK','statusCommand', 'StatusCommand', 'NoOp'],
        -messagecommand =>['CALLBACK','messageCommand','MessageCommand','NoOp'],
        -errorcommand =>  ['CALLBACK','errorCommand',  'ErrorCommand',  'NoOp'],
        -commands =>      ['METHOD',  'commands',      'Commands',      {} ],
    );
}

# Config commands
sub commands {
    my $w = shift;

    if( @_ >= 2 ) {
        if( @_ % 2 == 1 ) {
            croak "Tk::TextVi commands() received odd number of arguments."
        }

        my %commands = @_;

        for my $cmd ( keys %commands ) {
            my $sub = $commands{$cmd};

            if( 'CODE' eq ref $sub ) {
                $w->{VI_COMMANDS}{$cmd} = $sub;
            }
            elsif( not defined $sub ) {
                delete $w->{VI_COMMANDS}{$cmd};
            }
            else {
                croak "Tk::TextVi commands() expected coderef or undef, got '$sub'";
            }
        }
    }
    elsif( @_ == 1 ) {
        if( 'HASH' ne ref $_[0] ) {
            croak "Tk::TextVi commands() expected hashref or pairs, got '$_[0]'";
        }

        for my $sub ( values %{ $_[0] } ) {
            croak "Tk::TextVi commands() expected coderef, got '$sub'";
        }

        %{ $w->{VI_COMMANDS} } = %{ $_[0] };
    }

    return %{ $w->{VI_COMMANDS} };
}

# We don't want to lose the selection.
# Movement commands extend visual selection
sub SetCursor {
    my($w,$pos) = @_;
    $pos = 'end -1c' if $w->compare($pos,'==','end');
    $w->markSet('insert',$pos);
    $w->see('insert');

    if( $w->{VI_MODE} eq 'v' ) {
        $w->tagRemove( 'sel', '1.0', 'end' );
        
        my ($s,$e) = ($w->{VI_VISUAL_START}, 'insert');

        if( $w->compare( $e, '<', $s ) ) {
            ($s,$e) = ($e,$s);
        }

        $w->tagAdd( 'sel', $s, $e );

        $w->markSet( 'VI_MARK__lt', $s );
        $w->markSet( 'VI_MARK__gt', $e );
    }
    elsif( $w->{VI_MODE} eq 'V' ) {
        $w->tagRemove( 'sel', '1.0', 'end' );
        
        my ($s,$e) = ($w->{VI_VISUAL_START}, 'insert');
        if( $w->compare( $e, '<', $s ) ) {
            ($s,$e) = ($e,$s);
        }

        $w->tagAdd( 'sel', "$s linestart", "$e lineend" );

        $w->markSet( 'VI_MARK__lt', $s );
        $w->markSet( 'VI_MARK__gt', $e );
    }
}

# Deep Experimental Magic
# 
# Only invoke the special split-variant functions when we're using
# :split
my @split_func = qw| delete insert tagAdd tagConfigure tagRemove |;

{
    no strict;
    for my $func ( @split_func ) {
        *{ "split_$func" } = sub {
            my ($w,@args) = @_;

            if( defined $w->{VI_SPLIT_SHARE} ) {
                for my $win ( @{ $w->{VI_SPLIT_SHARE} } ) {
                    "Tk::TextUndo::$func"->( $win, @args );
                }
            }
            else {
                "Tk::TextUndo::$func"->( $w, @args );
            }
        }
    }
}

sub vi_split {
    my ($w,$newwin) = @_;

    # First time replace all the functions with the magical split versions
    if( not defined $w->{VI_SPLIT_SHARE} ) {
        $w->{VI_SPLIT_SHARE} = [ $w ];

        no strict;
        for my $func (@split_func) {
            *{"Tk::TextVi::$func"} = \&{"split_$func"};
        }
    }

    $newwin->Contents( $w->Contents );
    $newwin->SetCursor( $w->index('insert') );
    $newwin->yviewMoveto( ($w->yview)[0] );

    push @{$w->{VI_SPLIT_SHARE}}, $newwin;
    $newwin->{VI_SPLIT_SHARE} = $w->{VI_SPLIT_SHARE}
}

# Public Methods #####################################################

sub viMode {
    my ($w, $mode) = @_;
    my $rv = $w->{VI_SUBMODE} . $w->{VI_MODE};
    $rv .= 'q' if defined $w->{VI_RECORD_REGISTER};

    if( defined $mode ) {
        croak "Tk::TextVi received invalid mode '$mode'"
            if $mode !~ m[ ^ [nicvVR/] $ ]x;
        $w->{VI_MODE} = $mode;
        $w->{VI_SUBMODE} = '';
        $w->{VI_PENDING} = '';
        $w->{VI_REPLACE_CHARS} = '';
        $w->tagRemove( 'sel', '1.0', 'end' );

        # XXX: Hack
        if( (caller)[0] eq 'Tk::TextVi' ) {
            $w->{VI_FLAGS} |= F_STAT;
        }
        else {
            # TODO: this is broken
            $w->Callback( '-statuscommand', $w->{VI_MODE}, $w->{VI_PENDING} );
        }
    }

    return $rv;
}

sub viPending {
    my ($w) = @_;
    return $w->{VI_PENDING};
}

sub viError {
    my ($w) = @_;
    return shift @{ $w->{VI_ERROR} };
}

sub viMessage {
    my ($w) = @_;
    return shift @{ $w->{VI_MESSAGE} };
}

sub viMap {
    my ( $w, $mode, $sequence, $ref, $force ) = @_;

    # TODO: nmap,imap,vmap etc. support
    my @mapmodes = map { $w->{MAPS}{$_} } split //, $mode;

    while( length( $sequence ) > 1 ) {
        # Get the next character in the sequence
        my $c = substr $sequence, 0, 1, '';

        # Advance the mapping locations
        for my $map ( @mapmodes ) {

            # Nothing at this location yet, add a hash
            if( not defined $map->{$c} ) {
                $map->{$c} = { };
            }
            # Something is already mapped here
            elsif( 'HASH' ne ref $map->{$c} ) {
                return unless $force;
                # If $force was defined, nuke the previous entry
                $map->{$c} = { };
            }

            $map = $map->{$c};
        }
    }

    # Check that a mapping can be placed here
    for my $map ( @mapmodes ) {
        if( defined $map->{$sequence} and       # Something is here
            'HASH' eq ref $map->{$sequence} and # it's a longer mapping
            scalar keys %{ $map->{$sequence}} ) # and its in use
        {
            return unless $force;
            delete $map->{$sequence};           # wipe out existing maps
        }
    }

    for my $map ( @mapmodes ) {
        $map->{$sequence} = $ref;
    }

    # TODO: return the mappings that were replaced in a format that
    # would permit them to be restored
    return 1;
}

# 'Private' Methods ##################################################

# Store text in a register
#
# Caller is responsible for determining when text should also be
# written to the unnamed register or the small delete register at the
# moment (XXX: This should be handled here in the future)
sub registerStore {
    my ( $w, $register, $text ) = @_;

    # Registers are all single characters or unnamed
    die X_BAD_STATE if length($register) > 1;

    # Read-only registers and blackhole are never written to
    return if $register =~ /[_:.%#0-9]/;

    # Always store in the unnamed register
    $w->{VI_REGISTER}{''} = $text;

    # * is the clipboard
    if( $register eq '*' ) {
        $w->clipboardClear;
        $w->clipboardAppend( '--', $text );
    }
    else {
        if( $register =~ tr/A-Z/a-z/ ) {
            $w->{VI_REGISTER}{$register} .= $text;
        }
        else {
            $w->{VI_REGISTER}{$register} = $text;
        }
    }
}

# Fetch the contents of a register
sub registerGet {
    my ( $w, $register ) = @_;

    # Registers are single characters or unnamed
    die X_BAD_STATE if length($register) > 1;

    # Nothing comes out of a black hole
    return '' if $register eq '_';

    # TODO: other special registers

    # Register contains nothing
    return '' unless defined $w->{VI_REGISTER}{$register};

    return $w->{VI_REGISTER}{$register};
}

sub setMessage {
    my ($w,$msg) = @_;

    push @{ $w->{VI_MESSAGE} }, $msg;
    $w->{VI_FLAGS} |= F_MSG;
}

sub setError {
    my ($w,$msg) = @_;

    push @{ $w->{VI_ERROR} }, $msg;
    $w->{VI_FLAGS} |= F_ERR;
}

sub settingGet {
    my ($w,$key) = @_;

    # TODO: decide what to do about widget-specific vs class settings
    # possibly something like Vim's b: vs g:

    $key = ${ $settings{$key} } if 'SCALAR' eq ref $settings{$key};
    return $settings{$key}[0];
}

# Handle keyboard input
#
# Replaces method in Tk::Text
sub InsertKeypress {
    my ($w,$key) = @_;
    my $res;

    return if $key eq '';       # Ignore shift, control, etc.

    $w->{VI_RECORD_KEYS} .= $key if defined $w->{VI_RECORD_REGISTER};

    # Normal mode
    if( $w->{VI_MODE} eq 'n' ) {
        # Escape cancels any command in progress
        if( $key eq ESC ) {
            $w->viMode( $w->{VI_SUBMODE} || 'n' );
        }
        else {
            $res = $w->InsertKeypressNormal( $key );

            # Array ref is returned by motion commands
            if( 'ARRAY' eq ref $res ) {
                $w->SetCursor( $res->[0] );
            }
        }
    }
    # Visual character mode
    elsif( $w->{VI_MODE} eq 'v' ) {
        if( $key eq ESC ) {
            $w->viMode('n');
        }
        else {
            $res = $w->InsertKeypressNormal( $key );

            if( 'ARRAY' eq ref $res ) {
                $w->SetCursor( $res->[0] );
            }
        }
    }
    # Visual line mode
    elsif( $w->{VI_MODE} eq 'V' ) {
        if( $key eq ESC ) {
            $w->viMode('n');
        }
        else {
            $res = $w->InsertKeypressNormal( $key );

            if( 'ARRAY' eq ref $res ) {
                $w->SetCursor( $res->[0] );
            }
        }
    }
    # Command mode
    elsif( $w->{VI_MODE} eq 'c' ) {
        if( $key eq BKSP ) {
            if( $w->{VI_PENDING} eq '' ) {
                $w->viMode('n');
            }
            else {
                chop $w->{VI_PENDING};
            }
        }
        elsif( $key eq "\n" ) {
            $w->EvalCommand();
            $w->viMode('n');
        }
        elsif( $key eq ESC ) {
            $w->viMode('n');
        }
        else {
            $w->{VI_PENDING} .= $key;
        }
        $w->{VI_FLAGS} |= F_STAT;
    }
    # Incremental search mode
    elsif( $w->{VI_MODE} eq '/' ) {
        if( $key eq BKSP ) {
            if( $w->{VI_PENDING} eq '' ) {
                $w->viMode('n');
            }
            else {
                chop $w->{VI_PENDING};
            }
            $w->SetCursor( $w->vi_fslash() );
        }
        elsif( $key eq "\n" ) {
            $w->vi_fslash_end;
            $w->viMode('n');
        }
        elsif( $key eq ESC ) {
            $w->viMode('n');
            $w->SetCursor( $w->vi_fslash() );
        }
        else {
            $w->{VI_PENDING} .= $key;
            $w->SetCursor( $w->vi_fslash() );
        }
        $w->{VI_FLAGS} |= F_STAT;
    }
    # Insert mode
    elsif( $w->{VI_MODE} eq 'i' ) {
        if( $key eq ESC ) {
            $w->addGlobEnd;
            $w->viMode('n');
            $w->SetCursor( 'insert -1c' )
                if( $w->compare( 'insert', '!=', 'insert linestart' ) );
        }
        elsif( $key eq BKSP ) {
            my $sts = $w->settingGet( 'softtabstop' );
            if( $sts > 1 && ' ' eq $w->get( 'insert -1c' ) ) {
                my $col = $w->index('insert');
                (undef,$col) = split /\./, $col;
                
                if( $col > 0 ) {
                    $col = $col % $sts || $sts;
                    my $txt = $w->get( "insert - $col c", "insert" );
                    $txt =~ /(\s*)$/;
                    $col = length($1) || 1;
                }
                else {
                    $col = 1;
                }
                $w->delete( "insert - $col c", 'insert' );
            }
            else {
                $w->delete( "insert -1c" );
            }
        }
        elsif( $key eq TAB ) {
            my $sts = $w->settingGet( 'softtabstop' );

            if( $sts > 0 ) {
                my $col = $w->index('insert');
                (undef,$col) = split /\./, $col;
                # Perl's modulus is well behaved so this works fine
                $col = (-$col % $sts) || $sts;
                $w->insert( 'insert', ' ' x $col );
            }
            else {
                $w->insert( 'insert', "\t" );
            }
        }
        elsif( $key eq "\cO" ) {
            $w->viMode('n');
            $w->{VI_SUBMODE} = 'i';
        }
        else {
            $w->insert( 'insert', $key );
            $w->see( 'insert' );
        }
    }
    elsif( $w->{VI_MODE} eq 'R') {
        if( $key eq ESC ) {
            $w->addGlobEnd;
            $w->viMode('n');
            $w->SetCursor( 'insert -1c' )
                if( $w->compare( 'insert', '!=', 'insert linestart' ) );
        }
        elsif( $key eq BKSP ) {
            my $r = chop $w->{VI_REPLACE_CHARS};
            if( $r ne '' ) {
                $w->delete( "insert -1c" );
                if( $r ne "\0" ) {
                    $w->insert( 'insert', $r );
                    $w->SetCursor( 'insert -1c' );
                }
            }
            else {
                $w->SetCursor( 'insert -1c' );
            }
        }
        elsif( $w->get( 'insert' ) ne "\n" ) {
            $w->{VI_REPLACE_CHARS} .= $w->get( 'insert' );
            $w->delete( 'insert' );
            $w->insert( 'insert', $key );
        }
        else {
            $w->{VI_REPLACE_CHARS} .= "\0";
            $w->insert( 'insert', $key );
        }
    }
    else {
        die "Tk::TextVi internal state corrupted";
    }

    # Does the UI need to update?
    # XXX: HACK
    if( (caller)[0] ne 'Tk::TextVi' ) {
        $w->Callback( '-statuscommand',
            $w->viMode,
            $w->{VI_PENDING} ) if( $w->{VI_FLAGS} & F_STAT );
        $w->Callback( '-messagecommand' ) if $w->{VI_FLAGS} & F_MSG ;
        $w->Callback( '-errorcommand' ) if $w->{VI_FLAGS} & F_ERR ;

        $w->{VI_FLAGS} = 0;
    }

    # Command may have moved insert cursor out of window
    $w->see('insert');
}

# Handles the command processing shared between Normal
# and visual mode commands
sub InsertKeypressNormal {
    my ($w,$key) = @_;
    my $res;

    my $keys = $w->{VI_PENDING} . $key;
    $w->{VI_PENDING} = '';              # Assume command will work

    eval { $res = $w->EvalKeys($keys); };# try to process as a command

    if( $@ ) {
        die $@ if $@ !~ /^VI_/;         # wasn't our exception

        if( $@ eq X_NO_KEYS ) {         # Restore pending keys
            $w->{VI_PENDING} = $keys;
        }
    }
    elsif ( lc $w->{VI_MODE} eq 'v' ) {
        # hack, clear visual mode after command
        ref $res or $w->viMode('n');
    }
    else {
        # Restore mode
        $w->viMode( $w->{VI_SUBMODE} ) if $w->{VI_SUBMODE};
    }

    $w->{VI_FLAGS} |= F_STAT;
    return $res;
}

# Takes a string of keypresses and dispatches it to the right command
sub EvalKeys {
    my ($w, $keys, $count, $register, $motion) = @_;
    my $res;
    my $mode = lc substr $w->{VI_MODE}, 0, 1;       # V and v use the same maps

    $count = 0 unless defined $count;

    # Use the currently pending keys by default
    $keys = $w->{VI_PENDING} unless defined $keys;

    # Extract the count
    if( $keys =~ s/^([1-9]\d*)// ) {
        $count ||= 1;
        $count *= $1;
    }

    # Extract the register
    if( $keys =~ s/^"(.?)// ) {
        $register = $1;
    }

    die X_NO_KEYS if $keys eq '';   # No command here

    # What does this map too
    $res = $w->{VI_MAPS}{$mode}{substr $keys, 0, 1, ''};

    # a hash ref is a multichar mapping, go deeper
    while( 'HASH' eq ref $res ) {
        die X_NO_KEYS if $keys eq '';
        $res = $res->{substr $keys, 0, 1, ''};
    }

    # If left with a function, call it
    $res = $res->( $w, $keys, $count, $register, $motion )
        if 'CODE' eq ref $res;

    # A stringy return means to use these keypresses instead
    if( defined $res and 'SCALAR' eq ref $res ) {
        $w->{VI_PENDING} = '';
        
        for my $key ( split //, $$res . $keys ) {
            $w->InsertKeypress( $key );
        }

        # The above call took care of everything
        return;
    }

    die X_BAD_STATE if $motion and 'ARRAY' ne ref $res;

    return $res;
}

sub EvalCommand {
    my ($w) = @_;

    my ($cmd,$force,$arg);

    local $_ = $w->{VI_PENDING};
    my @range;

    # First attempt to extract a range
    while (1) {
        if( s/^\.// ) { push @range, 'insert' }
        elsif( s/^\$// ) { push @range, 'end' }
        elsif( s/^\%// ) { push @range, '1.0'; push @range, 'end' }
        elsif( s/^(\d+)// ) { push @range, "$1.0"; }
        elsif( s/^\'(.)// ) { push @range, "VI_MARK_" . ($names{$1}||$1) }
        else { last }

        while( s/^([+-]\d+)// ) { $range[$#range] .= " $1 lines" }

        if( s/^[,;]// ) { redo }
    };

    if( not m/
        ^           # colon is not in the buffer
        (\w*)       # followed by the name of the command
        (!?)        # optional ! to force the command
        (?:
            \s*     # space between command and argument
            (.*)    # everything else is the argument
        )?          # argument is optional
        $
        /x )
    {
       return;      # Something's really screwed up 
    }

    $cmd = $1;
    $force = 1 if $2;
    $arg = $3;

    # Built-in command
    if( exists $w->{VI_MAPS}{c}{$cmd} ) {
        $w->{VI_MAPS}{c}{$cmd}( $w, $force, $arg, \@range );
    }
    # External command
    else {
        $w->vi_c( $cmd, $force, $arg, \@range );
    }
}

sub vi_c {
    my ($w,$cmd,@args) = @_;

    if( exists $w->{VI_COMMANDS}{$cmd} ) {
        return $w->{VI_COMMANDS}{$cmd}( $w, @args );
    }
    elsif( exists $w->{VI_COMMANDS}{NOT_SUPPORTED} ) {
        return $w->{VI_COMMANDS}{NOT_SUPPORTED}( $w, $cmd, @args );
    }
    return;
}

# All the normal-mode commands ######################################

=begin comment

sub vi_n_d {
    my ($w,$k,$n,$r,$m) = @_;
    die X_BAD_STATE if $m;
}

=end comment

=cut

sub vi_n_a {
    my ($w,$k,$n,$r,$m) = @_;
    die X_BAD_STATE if $m;

    $w->SetCursor( 'insert +1c' )
        unless $w->compare( 'insert', '==', 'insert lineend' );
    $w->viMode('i');
}

sub vi_n_d {
    my ($w,$k,$n,$r,$m) = @_;
    my ($start,$end,$wise,$type);
    die X_BAD_STATE if $m;

    # In a visual mode we just need the selection
    if( $w->{VI_MODE} eq 'v' ) {
        $start = 'sel.first';
        $end = 'sel.last';
        $wise = 'char';
        $type = 'exc';
    }
    elsif( $w->{VI_MODE} eq 'V' ) {
        $start = 'sel.first';
        $end = 'sel.last';
        $wise = 'line';
    }
    # In normal mode there's more work
    else {
        # Special case, dd = delete line
        if( $k eq 'd' ) {
            # If not enough lines, don't delete anything
            return if $n > int $w->index('end') - int $w->index('insert');

            $start = 'insert';
            $end = 'insert';
            $end .= '+' . ($n-1) . 'l' if $n > 1;
            $wise = 'line';
        }
        else {
            my $res = EvalKeys( @_[0 .. 3], 1 );

            $start = 'insert';
            ($end,$wise,$type) = @$res;
        }
    }

    # Swap start and end if the motion was backwards
    if( $w->compare( $start, '>', $end ) ) {
        ($start,$end) = ($end,$start);
        $type = 'exc';                      # XXX: hack
    }

    if( $wise eq 'line' ) {

        $start .= ' linestart';     # From start of line
        $end .= ' lineend +1c';     # Including the \n of the final line
    }
    else {
        $end .= ' +1c' if $type eq 'inc';
    }

    my $text = $w->get( $start, $end );
    $w->delete( $start, $end );

    if( not defined $r ) {
        # With default register, d shifts
        # XXX: can you not get a hash slice with references?
        for my $idx ( 2 .. 9 ) {
            $w->{VI_REGISTER}{ $idx } = $w->{VI_REGISTER}{ $idx-1 };
        }

        # Stores in "1 by default
        $r = '1';

        # If under 1 line, store in small delete register too
        $w->registerStore( '-', $text ) if $text !~ /\n/;
    }

    $w->registerStore( $r, $text );
}

sub vi_n_f {
    my ($w,$k,$n,$r,$m) = @_;

    die X_NO_KEYS if $k eq '';

    my $line = $w->get( 'insert', 'insert lineend' );
    my $ofst = index $line, $k, 1;
    for (2 .. $n) {
        return if $ofst == -1;
        $ofst = index $line, $k, $ofst+1;
    }

    return if $ofst == -1;
    return [ "insert +$ofst c", 'char', 'inc' ];
}

sub vi_n_ga {
    my ($w,$k,$n,$r,$m) = @_;
    die X_BAD_STATE if $m;

    my $c = $w->get( 'insert' );
    my $sc = $c;
    if( ord($c) < 0x20 ) {
        $sc = '^' . chr( ord($c) + 64 );
    }

    $w->setMessage(sprintf '<%s>  %d,  Hex %02x,  Oct %03o', $sc, (ord($c)) x 3 );
}

sub vi_n_gg {
    my ($w,$k,$n,$r,$m) = @_;

    return [ "$n.0", 'line' ];
}

sub vi_n_h {
    my ($w,$k,$n,$r,$m) = @_;
    $n ||= 1;

    my $ind = ( split /\./, $w->index('insert') )[1];
    return [ 'insert linestart', 'char', 'exc' ] if $ind <= $n;
    return [ "insert -$n c", 'char', 'exc' ];
}

sub vi_n_i {
    my ($w,$k,$n,$r,$m) = @_;
    $w->viMode('i');
    $w->addGlobStart;
}

sub vi_n_j {
    my ($w,$k,$n,$r,$m) = @_;
    $n ||= 1;
    
    # Screwy, Setcursor('end') doesn't make index('insert') == index('end')??
    my $max = int $w->index('end') - 1 - int $w->index('insert');
    $n = $max if $n > $max;

    return if $n == 0;
    [ "insert +$n l", 'line', 'inc' ];
}

sub vi_n_k {
    my ($w,$k,$n,$r,$m) = @_;
    $n ||= 1;

    my $max = int $w->index('insert') - 1;
    $n = $max if $n > $max;

    return if $n == 0;
    [ "insert -$n l", 'line', 'inc' ];
}

sub vi_n_l {
    my ($w,$k,$n,$r,$m) = @_;

    $n ||= 1;
    my $ln = $w->index('insert lineend');
    my $ln_1 = $w->index('insert lineend -1c');
    my $eol = (split /\./, $ln_1)[1];
    my $ins = $w->index('insert');
    my $at = (split /\./, $ins)[1];

    # If the cursor is at TK's end of line or VI end of line, leave it alone
    return ['insert','char','exc'] if $ln eq $ins or $ln_1 eq $ins;
    # If the count would go past lineend - 1, stop at lineend - 1
    return ['insert lineend -1c','char','inc'] if $n + $at >= $eol;
    # Otherwise advance n characters
    return ["insert +$n c",'char','exc'];
}

sub vi_n_m {
    my ($w,$k,$n,$r,$m) = @_;
    die X_BAD_STATE if $m;
    die X_NO_KEYS if $k eq '';

    $w->markSet( "VI_MARK_$k", 'insert' );
}

sub vi_n_n {
    my ($w,$k,$n,$r,$m) = @_;
    
    my $re = $w->{VI_SEARCH_LAST};

    if( not defined $re ) {
        $w->setError('No pattern');
        die X_BAD_STATE;
    }

    my $text = $w->get( 'insert +1c', 'end' );

    if( $text =~ $re ) {
        return [ "insert +1c +$-[0]c", 'char', 'exc' ];
    }
}

sub vi_n_o {
    my ($w,$k,$n,$r,$m) = @_;
    die X_NO_MOTION if $m;

    # Work around for some weird behavior in Tk::TextUndo
    # If I just open the line and advance the cursor, I lose
    # test case 6
    my ($l) = 1 + int $w->index('insert');
    $w->insert('insert lineend',"\n");
    $w->SetCursor("$l.0");
    $w->viMode('i');
}

sub vi_n_p {
    my ($w,$k,$n,$r,$m) = @_;
    die X_BAD_STATE if $m;

    $r = "" if not defined $r;
    $n ||= 1;

    my $txt = $w->registerGet($r);

    if( index( $txt, "\n" ) == -1 ) {
        # Charwise insert
        $w->insert( 'insert +1c', $txt x $n );
        $n *= length($txt);
        $n += 1;
        $w->SetCursor( "insert +$n c" );
    }
    else {
        # Linewise insert
        $w->insert( 'insert +1l linestart', $txt x $n );
        $w->SetCursor( 'insert +1l linestart' );
    }
}

sub vi_n_q {
    my ($w,$k,$n,$r,$m) = @_;
    die X_NO_MOTION if $m;

    # Completed a mapping
    if( defined $w->{VI_RECORD_REGISTER} ) {
        # Remove this 'q'
        chop $w->{VI_RECORD_KEYS};
        $w->{VI_REGISTER}{ $w->{VI_RECORD_REGISTER} } = $w->{VI_RECORD_KEYS};
        $w->{VI_RECORD_REGISTER} = undef;
    }
    else {
        die X_NO_KEYS if $k eq '';
        die X_BAD_STATE if $k =~ /[_:.%#]/;

        $w->{VI_RECORD_KEYS} = '';
        $w->{VI_RECORD_REGISTER} = $k;
    }
}

sub vi_n_r {
    my ($w,$k,$n,$r,$m) = @_;
    die X_NO_MOTION if $m;
    die X_NO_KEYS if $k eq '';

    $n ||= 1;
    die X_BAD_STATE if $w->compare("insert +$n c",'>','insert lineend');

    if( uc $w->{VI_MODE} eq 'V' ) {
        my $start = $w->index('sel.first');
        my $text = $w->get( $start, 'sel.last' );
        $text =~ s/./$k/g;  # no /s newlines stay intact!

        # Save idx, about to delete the selection
        my $idx = $w->index( 'sel.first' );

        $w->delete( $start, 'sel.last' );
        $w->insert( $start, $text );
        $w->SetCursor( $idx );
    }
    else {
        # Grrr.  Tk::Text moves the mark when I want to insert after it.
        my $pos = $w->index('insert');
        $w->delete('insert', "insert +$n c");
        $w->insert('insert',$k x $n);
        $w->SetCursor( $pos );
    }
}

sub vi_n_t {
    my ($w,$k,$n,$r,$m) = @_;

    die X_NO_KEYS if $k eq '';

    my $line = $w->get( 'insert', 'insert lineend' );
    my $ofst = index $line, $k, 1;
    for (2 .. $n) {
        return if $ofst == -1;
        $ofst = index $line, $k, $ofst+1;
    }

    return if $ofst == -1;
    return [ "insert +$ofst c -1c", 'char', 'inc' ];
}

sub vi_n_u {
    my ($w,$k,$n,$r,$m) = @_;
    $w->undo;
}

sub vi_n_v {
    my ($w,$k,$n,$r,$m) = @_;
    die X_BAD_STATE if $m;
    $w->viMode('v');
    $w->{VI_VISUAL_START} = $w->index('insert');
    return ['insert','char','inc'];
}

sub vi_n_y {
    my ($w,$k,$n,$r,$m) = @_;
    my($start,$end,$wise,$type);
    die X_BAD_STATE if $m;

    # In a visual mode we just need the selection
    if( $w->{VI_MODE} eq 'v' ) {
        $start = 'sel.first';
        $end = 'sel.last';
        $wise = 'char';
        $type = 'exc';
    }
    elsif( $w->{VI_MODE} eq 'V' ) {
        $start = 'sel.first';
        $end = 'sel.last';
        $wise = 'line';
    }
    # In normal mode there's more work
    else {
        # Special case, dd = delete line
        if( $k eq 'y' ) {
            $start = 'insert';
            $end = 'insert';
            $end .= '+' . ($n-1) . 'l' if $n > 1;
            $wise = 'line';
        }
        else {
            my $res = EvalKeys( @_[0 .. 3], 1 );

            $start = 'insert';
            ($end,$wise,$type) = @$res;
        }
    }

    # Swap start and end if the motion was backwards
    if( $w->compare( $start, '>', $end ) ) {
        ($start,$end) = ($end,$start);
        $type = 'exc';                      # XXX: hack
    }

    if( $wise eq 'line' ) {

        $start .= ' linestart';     # From start of line
        $end .= ' lineend +1c';     # Including the \n of the final line
    }
    else {
        $end .= ' +1c' if $type eq 'inc';
    }

    my $text = $w->get( $start, $end );

    if( not defined $r ) {
        $r = '';
    }

    $w->registerStore( $r, $text );
}

sub vi_n_B {
    my ($w,$k,$n,$r,$m) = @_;
    $n ||= 1;

    my ($row,$col) = split /\./, $w->index('insert');
    my $line = $w->get( 'insert linestart', 'insert lineend' );
    while( $n > 0 ) {
        # Check for back one word on this line
        if( substr($line,0,$col) =~ /\S+\s*$/ ) {
            $n--;
            $col = $-[0];
        }
        else {
            return [ '1.0', 'char', 'inc' ] if $row == 1;
            $row--;
            $line = $w->get( "$row.0", "$row.0 lineend" );
        }
    }
    return [ "$row.$col", 'char', 'inc' ];
}

sub vi_n_E {
    my ($w,$k,$n,$reg,$m) = @_;
    my $l;
    $n ||= 1;

    my $ofst = 0;
    my ($r,$c) = split /\./, $w->index('insert');
    my ($maxr,$maxc) = split /\./, $w->index('end');

    my $line = $w->get( 'insert linestart', 'insert lineend' );
    pos($line) = $c;
    while( $n > 0 ) {
        # |  abc
        # a|bc
        # |c def
        if( $line =~ /\G.\s*\S*(?=\S)/gc ) { $n--; next; }

        $r++;

        # Can't go past end
        if( $r > $maxr ) {
            $r = $maxr;
            $c = $maxc;
            last;
        }

        $line = $w->get( "$r.0", "$r.0 lineend" );

        # Catches cases of 1-letter word at start of line
        if( $line =~ /^\s*\S*(?=\S)/gc ) { $n--; }
    }

    $c = pos($line) || 0;
    return [ "$r.$c", "char", "exc" ];
}

sub vi_n_G {
    my ($w,$k,$n,$r,$m) = @_;

    return [ "$n.0", 'line' ] if $n;
    return [ 'end -1l linestart', 'line' ];
}

sub vi_n_I {
    my ($w,$k,$n,$r,$m) = @_;
    die X_BAD_STATE if $m;

    # Skip cursor over initial blanks
    my $line = $w->get( 'insert linestart', 'insert lineend' );
    $line =~ /^(\s*)/;
    $w->SetCursor( "insert +" . length($1) . "c" );

    $w->viMode('i');
}

sub vi_n_O {
    my ($w,$k,$n,$r,$m) = @_;
    die X_NO_MOTION if $m;
    $w->insert('insert linestart',"\n");
    $w->SetCursor('insert -1l');
    $w->viMode('i');
}

sub vi_n_R {
    my ($w,$k,$n,$r,$m) = @_;
    die X_NO_MOTION if $m;
    $w->viMode('R');
}

sub vi_n_V {
    my ($w,$k,$n,$r,$m) = @_;
    die X_BAD_STATE if $m;

    $w->viMode('V');
    $w->{VI_VISUAL_START} = $w->index('insert');
    #$w->tagAdd( 'sel', 'insert linestart', 'insert lineend' );
    return ['insert'];
}

sub vi_n_W {
    my ($w,$k,$n,$reg,$m) = @_;
    my $l;
    $n ||= 1;

    my $ofst = 0;
    my ($r,$c) = split /\./, $w->index('insert');
    my ($maxr,$maxc) = split /\./, $w->index('end');

    my $line = $w->get( 'insert linestart', 'insert lineend' );
    pos($line) = $c;
    while( $n > 0 ) {
        # If there is another word on this line
        if( $line =~ /\G\S*\s+(?=\S)/gc ) { $n--; next; }

        # Get the next line
        $r++;

        # Can't go past end
        if( $r > $maxr ) {
            $r = $maxr;
            $c = $maxc;
            last;
        }

        $line = $w->get( "$r.0", "$r.0 lineend" );
        # Skip leading whitespace
        if( $line =~ /^\s+/gc ) {
            # Only counts as a word if there is a non-whitespace letter
            $n-- if $line =~ /\G\S/gc;
        }
        else {
            # No leading whitespace, either empty line or start of word
            # Both count as a word
            $n--;
        }
    }

    $c = pos($line) || 0;
    return [ "$r.$c", "char", "exc" ];
}

sub vi_n_tilde {
    my ($w,$k,$n,$r,$m) = @_;

    die X_BAD_STATE if $m;

    my ($start,$end,$chars);

    if( $w->{VI_MODE} =~ /v/i ) {
        $start = 'sel.first';
        $end = 'sel.last';
    }
    else {
        $start = 'insert';
        $end = 'insert +1c';
    }

    $start = $w->index( $start );       # save absolute position of start
    $end = $w->index( $end );

    $chars = $w->get( $start, $end );
    $w->delete( $start, $end );

    # The world was a whole lot simpler before unicode...
    $chars =~ s/([[:upper:]])|([[:lower:]])/defined $1 ? lc $1 : uc $2/ge;

    $w->insert( $start, $chars );
}

sub vi_n_backtick {
    my ($w,$k,$n,$r,$m) = @_;

    die X_NO_KEYS if $k eq '';

    $k = $names{$k} || $k;
    return unless $w->markExists( "VI_MARK_$k" );

    return [ "VI_MARK_$k", 'char', 'exc' ];
}

sub vi_n_at {
    my ($w,$k,$n,$r,$m) = @_;
    $n ||= 1;

    die X_NO_MOTION if $m;
    die X_NO_KEYS if $k eq '';

    my $keys = $w->registerGet( $k );
    die X_BAD_STATE unless defined $keys;

    my @keys = split //, $keys;

    $w->{VI_PENDING} = '';
    local $_;
    while( $n > 0 ) {
        $n--;
        $w->InsertKeypress($_) for @keys;
    }
}

sub vi_n_dollar {
    my ($w,$k,$n,$r,$m) = @_;

    $n ||= 1;
    $n--;

    my $i0 = $w->index( "insert +$n l lineend" );
    # Special case, blank line
    return [ "insert +$n l", 'char', 'exc' ] if $i0 =~ /\.0$/;
    return [ "insert +$n l lineend -1c", 'char', 'inc' ];
}

# All the things a % can match
my %brace_left = qw" ( ) { } [ ] ";
my %brace_right = qw" ) ( } { ] [ ";
my $brace_re = join '|', map quotemeta, %brace_left;
$brace_re = qr/($brace_re)/;

sub vi_n_percent {
    my ($w,$k,$n,$r,$m) = @_;
    
    # If passed a count, goes to % in file instead
    if( $n != 0 ) {
        return if $n > 100;
        my $line = int $w->index('end');
        $line *= $n / 100.0;
        $line = (int $line) || 1;
        return [ "$line.0", 'line' ];
    }

    # Find the first bracket-like char on the line after the cursor
    my $line = $w->get( 'insert', 'insert lineend' );
    return unless( $line =~ $brace_re );
    my $brace = $1;
    my $ofst = "insert + $-[0] c";

    # Only care about matching up this brace pair
    # Don't worry about constructs like ( { )
    my $match;
    my $dir;
    my $count = 0;
    my $open = 1;
    if( exists $brace_left{$brace} ) {
        $match = $brace_left{$brace};
        $dir = '+';
    }
    else {
        $match = $brace_right{$brace};
        $dir = '-';
    }
    
    while( $open ) {
        $count++;
        my $char = $w->get( "$ofst $dir $count c" );
        $open++ if( $char eq $brace );
        $open-- if( $char eq $match );

        # XXX: Yuck.  Tk::Text doesn't give us an undef or an error if
        # the index is outside the body of the text, it just gives the first
        # or last index.  This algorithm should really be changed to
        # a linewise one because this is #### inefficient.
        return if $open && $w->compare( "$ofst $dir $count c", '==', '1.0' );
        return if $open && $char eq '' ;
    }

    # XXX: I think % becomes linewise if we crossed a \n    
    return [ "$ofst $dir $count c", "char", "inc" ];
}


sub vi_n_colon {
    my ($w,$k,$n,$r,$m) = @_;
    die X_BAD_STATE if $m;

    my $old = $w->viMode('c');
    if( 'v' eq lc $old ) {
        $w->{VI_PENDING} = "'<,'>";
    }
    elsif( $n ) {
        $n--;
        $w->{VI_PENDING} = $n ? ".,.+$n" : '.';
    }

    return ['insert'];
}

sub vi_n_fslash {
    my ($w,$k,$n,$r,$m) = @_;

    # Remember the current location.
    $w->{VI_SAVE_CURSOR} = $w->index('insert');

    # Switch to incremental search mode
    $w->viMode('/');
}

sub vi_fslash {
    my ($w) = @_;

    $w->tagRemove( 'VI_SEARCH', '1.0', 'end' );

    my $re = eval { qr/$w->{VI_PENDING}/ };

    # Regex is incomplete
    return [ $w->{VI_SAVE_CURSOR} ] if $@;

    # XXX: OUCH!  maybe we could scan the regex for \n and
    # (?s) sequences and scan line by line instead?
    my $text = $w->get( $w->{VI_SAVE_CURSOR}, 'end' );
    if( $text =~ $re ) {
        $w->tagAdd( 'VI_SEARCH', "$w->{VI_SAVE_CURSOR} + $-[0] c", "$w->{VI_SAVE_CURSOR} + $+[0] c" );
        return [ "$w->{VI_SAVE_CURSOR} + $-[0] c" ];
    }
    else {
        return [ $w->{VI_SAVE_CURSOR} ];
    }
}

sub vi_fslash_end {
    my ($w) = @_;

    $w->tagRemove( 'VI_SEARCH', '1.0', 'end' );

    my $re = eval { qr/$w->{VI_PENDING}/ };

    # Regex is incomplete
    return if $@;

    # XXX: OUCH!  maybe we could scan the regex for \n and
    # (?s) sequences and scan line by line instead?
    my $text = $w->get( '1.0', 'end' );
    while( $text =~ /$re/g ) {
        $w->tagAdd( 'VI_SEARCH', "1.0 + $-[0] c", "1.0 + $+[0] c" );
    }

    $w->{VI_SEARCH_LAST} = $re;
}

# COMMAND MODE ###########################################################

=begin comment

sub vi_c_ {
    my ($w,$force,$arg) = @_;
}

=end comment

=cut

sub vi_c_none {
    my ($w,$force,$arg,$range) = @_;

    if( $force ) {
        return unless 2 == scalar @$range;

        my $s = $w->index($range->[0] . ' linestart');
        my $e = $w->index($range->[1] . ' lineend' );

        my $res = $w->vi_c( '!', 1, $arg, [ $s, $e ] );
        return unless defined $res;

        $w->delete( $s, $e );
        $w->insert( $s, $res );
    }
    else {
        return unless @$range;
        $w->SetCursor( pop @$range );
    }
}

sub vi_c_map {
    my ($w,$force,$arg) = @_;

    my ($seq,$cmd) = split / +/, $arg, 2;

    $w->viMap( 'nv', $seq, \$cmd ) or $w->setError( 'Ambiguous mapping' );
}

sub vi_c_nohlsearch {
    my ($w,$force,$arg) = @_;

    $w->tagRemove( 'VI_SEARCH', '1.0', 'end' );
}

sub vi_c_set {
    my ($w,$force,$arg) = @_;

    if( $arg =~ /^\s*(\w+)\?$/ ) {
        my $key = $1;
        my $value = $w->settingGet( $key );
        $w->setMessage( "$key=$value" );
    }
    elsif( $arg =~ /^\s*(\w+)[=:](.*)/ ) {
        my ($key,$value) = ($1,$2);
        if( not exists $settings{$key} ) {
            $w->setError( "Setting '$key' does not exist." );
            return;
        }
        
        $key = ${$settings{$key}} if 'SCALAR' eq ref $settings{$key};

        $value += 0 if $settings{$key}[2] eq 'int';
        $settings{$key}[0] = $value;
    }
}

sub vi_c_split {
    my ($w,$force,$arg) = @_;

    my $newwin = $w->vi_c( 'split' );
    return if not defined $newwin;

    if( ref $newwin ) {
        $w->vi_split( $newwin );
    }
    else {
        $w->setError( $newwin );
    }
}

1;

=head1 NAME

Tk::TextVi - Tk::Text widget with Vi-like commands

=head1 SYNOPSIS

    use Tk::TextVi;

    $textvi = $window->TextVi( -option => value, ... );

=head1 DESCRIPTION

Tk::TextVi is a Tk::TextUndo widget that replaces InsertKeypress() to handle user input similar to vi.  All other methods remain the same (and most code should be using $text->insert( ... ) rather than $text->InsertKeypress()).  This only implements the text widget and key press logic; the status bar must be drawn by the application (see TextViDemo.pl for an example of this).

To use Tk::TextVi as a drop-in replacement for other text widgets, see Tk::EditorVi which encapsulates Tk::TextVi and the status bar into a composite widget.  (This module is included in the Tk::TextVi distribution, but is not installed.)

Functions in Vi that require interaction with the system (such as reading or writing files) are not (currently) handled by this module (This is a feature since you probably don't want :quit to do exactly that).  Instead a callback is provided so that the application using the Tk::TextVi widget may decide how to act on them.

The cursor in a Tk::Text widget is a mark placed between two characters.  Vi's idea of a cursor is placed on a non-newline character or a blank line.  Tk::TextVi treats the cursor as on (in the Vi-sense) the characters following the cursor (in the Tk::Text sense).  This means that $ will place the cursor just before the final character on the line.

=head2 Options

=over 4

=item -statuscommand

Callback invoked when the mode or the keys in the pending command change.  The current mode and pending keys will be passed to this function.

=item -messagecommand

Callback invoked when messages need to be displayed.

=item -errorcommand

Callback invoked when error messages need to be displayed.

=item -commands

Stores callbacks to handle command-mode commands which require external action.  See the commands() method below for more details.

=back

=head2 Methods

All methods present in Tk::Text and Tk::TextUndo are inherited by Tk::TextVi.  Additional or overridden methods are as follows:

=over 4

=item $text->InsertKeypress( $char );

This replaces InsertKeypress() in Tk::Text to recognise vi commands.

=item $text->SetCursor( $index );

This replaces SetCursor() in Tk::Text with one that is aware of the visual selection.

=item $text->viMode( $mode );

Returns the current mode of the widget:

    'i'     # insert
    'n'     # normal
    'c'     # command
    'R'     # replace
    'v'     # visual character
    'V'     # visual line

There is also a fake mode:

    '/'     # Incremental search

If the 'q' command (record macro) is currently active, a q will be appended to the mode.

The insert-XXX modes (entered by Control-O from insert mode) are indicated by a two-character sequence, 'i' followed by the character of the mode that is active.  (e.g. 'in' is insert-normal).

If the $mode parameter is supplied, it will set the mode as well.  Any pending keystrokes will be cleared (this brings the widget to a known state).  Macro-recording or incremental search cannot be enabled from this function.

=item $text->viPending;

Returns the current buffer of pending keystrokes.  In normal or visual mode this is the pending command, in command mode this is the partial command line.

=item $text->viError;

Returns a list of all pending error messages.

=item $text->viMessage;

Returns a list of all pending non-error messages (for example the result of normal-ga)

=item $text->viMap( $mode, $sequence, $ref, $force )

$mode should be one of qw( n c v ) for normal, command and visual mode respectively.  Mappings are shared between the different visual modes.  $sequence is the keypress sequence to map the action to.  To map another sequence of keys to be interpreted by Tk::TextVi as keystrokes, pass a scalar reference.  A code reference will be called by Tk::Text (the signature of the function is described below).  A hash reference can be used to restore several mappings (as described below).  If $ref is the empty string the current mapping is deleted.

The function may fail--returning undef--in two cases:

=over 4

=item *

You attempt to map to a sequence that begins another command (for example you cannot map to 'g' since there is a 'ga' command).  Setting $force to a true value will force the mapping and will remove all other mappings that begin with that sequence.

=item *

You attempt to map to a sequence that starts with an existing command (for example, you cannot map to 'aa' since there is an 'a' command).  Setting $force to a true value will remove the mapping that conflicts with the requested sequence.

=back

=item $w->commands( $key => $sub, $key2 => $sub2 )
=item $w->commands( { $key => $sub } )

Sets the commands configuration setting.  In the first form, the given commands are updated with the listed commands.  Passing 'undef' for a subroutine will remove that entry.  In the second form, the passed hashref replaces the current command list.  The subroutine associated with the key 'NOT_SUPPORTED' is called when a typed command is not found in the hash.

Each callback receives arguments of the form:

    my ( $textvi, $force, $args, $range ) = @_;

Where $textvi is the Tk::TextVi instance, $force is a true value if the command was followed by an exclaimation point, $args is any text following the command and $range is an arrayref giving any lines entered before the command.  The elements of this array are valid input to the Tk::Text->index() method.

The NOT_SUPPORTED callback takes an additional argument containing the typed command:

    my ( $textvi, $cmd, $force, $args, $range ) = @_;

The following commands are defined by TextVi and may take different arguments than the above:

=over

=item split

Called for the :split command.  The callback should return a Tk::TextVi instance to use as the newly created window.  See EXPERIMENTAL FEATURES below for more details.  None of the arguments are currently meaningful.

=item !

Called for the :! (filter) command.  $args is the command line and $range gives the lines to process ($textvi->get( @$range ) will return the text to be filtered).  The $force argument is not meaningful.

The callback should return the text filtered through the given program specified, or undef if the text should not be modified (either due to an error executing the command, or the callback has updated the widget itself).

=back

All commands listed in the implemented commands that are not listed above are implemented internally and ignore these callbacks.

=back

=head2 Bindings

The bindings present in Tk::Text are inherited by Tk::TextVi, however it is not safe to rely on the control key bindings since many of these are used by vi.

=head1 SETTINGS

=over

=item softtabstop

=item sts

This setting is a combination of the softtabstop and expandtab found in Vi/Vim.  Setting it to a non-zero value has the following effects:  The backspace key will delete spaces to reach a column number that is an even multiple of the softtabstop value; the tab key will insert places to reach the next column that is an even multiple of the softtabstop value.  When set to zero, backspace always deletes one character and tab inserts a literal tab.  (default value is 4)

=back

=head1 COMMANDS

=head2 Supported Commands

=head3 Insert Mode

Keypresses in insert mode are added to the text literally except for the
following special keys.

    Tab         Insert spaces up to the next softtabstop
    Backspace   Delete a character or spaces back to the last softtabstop
    Control-O   Enter a single normal-mode command

=head3 Normal Mode

    a - enter insert mode after the current character
    d - delete over 'motion' and store in 'register'
        dd - delete a line
    f - find next occurrence of 'character' on this line
    g - one of the two-character commands below
        ga - print ASCII code of character at cursor
        gg - go to the 'count' line
    h - left one character on this line
    i - enter insert mode
    j - down one line
    k - up one line
    l - right one character on this line
    m - set 'mark' at cursor location
    n - next occurrance of last match
    o - open a line below cursor 
    p - insert contents of 'register'
    q - record keystrokes
    r - replace character
    t - move one character before the next occurrence of 'character'
    u - undo
    v - enter visual mode
    w - advance one word [1]
    x - delete character
    y - yank over 'motion' into 'register'
        yy - yank a line

    D - delete until end of line
    G - jump to 'count' line
    O - open line above cursor
    R - enter replace mode
    V - enter visual line mode
    W - advance one word

    ` - move cursor to 'mark'
    ~ - toggle case of next character
    @ - execute keys from register
    $ - go to last character of current line
    % - find matching bracketing character
    0 - go to start of current line
    : - enter command mode
    / - search using a regex [2]

    [1] The w command is currently mapped to W
    [2] The / command uses a perl regex not the vi or vim syntax

=head3 Visual Mode

Normal-mode motion commands will move the end of the visual area.  Normal-mode commands that operate over a motion will use the visual selection.

There are currently no commands defined specific to visual mode.

=head3 Command Mode

    :
        - places the cursor at the last item in range
    :map sequence commands
        - maps sequence to commands
    :noh
    :nohl
    :nohlsearch
        - clear the highlighting from the last search
    :set setting?
        - prints the value of a setting [1]
    :set setting=value
        - set the value of a setting
    :split
        - split the window
    :!program
        - filter text through program

    [1] :set does not display a setting's value as a result of the command
        :set non-bool-setting.  The final ? must be supplied.

Commands may have a ! suffix to force completion (e.g. :map! with map a command even if it will overwrite existing mappings).  They may also be prefixed with a range of text to operate on:

    .           # The current line number
    $           # The final line
    %           # The entire text, same as 1,$
    NUM         # Line number NUM
    'x          # The line containing mark x
    RANGE+NUM   # NUM lines after RANGE

Multiple values may be separated with , or ; (Tk::TextVi does not currently distinguish between the delimiters).

=head2 EXPERIMENTAL COMMANDS

=head3 :split

First, :split is only included as a "look at this cool feature" do not count on it to work the same way in the future, or work at all now.  It doesn't even support the ":split file" syntax.  The current implementation is a bit memory-intensive and slows many basic methods of the Tk::Text widget (don't use :split and you won't get penalized).

Second, none of the supporting commands are implemented.  :quit will not close only one window, and there are no Normal-^W commands.

The split callback should return a new Tk::TextVi widget to the caller or a string to be used as an error message.  The module will copy the contents and make sure all changes in the text are visible in both widgets.

=head2 WRITING COMMANDS

Perl subroutines can be mapped to keystrokes using the viMap() method described above.  Normal and visual mode commands receive arguments like:

    my ( $widget, $keys, $count, $register, $wantmotion ) = @_;

Where $widget is the Tk::TextVi object, $keys are any key presses entered after those that triggered the function.  Unless you've raised X_NO_KEYS this should be an empty string.  $count is the current count, zero if none has been set.  $register contains the name of the entered register.  $wantmotion will be a true value if this command is being called in a context that requires a cursor motion (such as from a d command).

Commands receive arguments in the following format:

    my ( $widget, $forced, $argument, $range ) = @_;

$forced is set to a true value if the command ended with an exclamation point.  $argument is set to anything that comes after the command.  $range is an array reference that contains any line numbers removed from the front of the command.  The elements are valid input to Tk::Text::index.

To move the cursor a normal-mode command should return an array reference.  The first parameter is a string representing the new character position in a format suitable to Tk::Text.  The second is either 'line' or 'char' to specify line-wise or character-wise motion.  Character-wise motion should also specify 'inc' or 'exc' for inclusive or exclusive motion as the third parameter.

Scalar references will be treated as a sequence of keys to process.  All other return values will be ignored, but avoid returning references (any future expansion will use leave plain scalar returns alone).

=head3 Exceptions

=over 4

=item X_NO_MOTION

If a true value is passed for $wantmotion and the function is not a motion command, die with this value.

=item X_NO_KEYS

Use when additional key presses are required to complete the command.

=item X_BAD_STATE

For when the command can't complete and panic is more appropriate than doing nothing.

=back

=head3 Methods

=over 4

=item $text->EvalKeys( $keys, $count, $register, $wantmotion )

Uses keys to determine the function to call passing it the count, register and wantmotion parameters specified.  The return value will be whatever that function returns.  If wantmotion is a true value the return value will always be an array reference as described above.

Normally you want to call this function like this, passing in the set of keystrokes after the command, the current count, the current register and setting wantmotion to true:

    $w->EvalKeys( @_[1..3], 1 )

=item $text->setMessage( $msg )

Queue a message to be displayed and generate the associated event.

=item $text->setError( $msg )

Same as setMessage, but the message is added to the error list and the error message event is generated.

=item $text->registerStore( $register, $text )

Store the contents of $text into the specified register.  The text will also be stored in the unnamed register.  If the '*' register is specified, the clipboard will be used.  If the black-hole or a read-only register is specified nothing will happen.

=item $text->registerGet( $register )

Returns the text stored in a register

=item $text->settingGet( $setting )

Returns the value of the specified setting.

=back

=head1 BUGS AND CAVEATS

If you find a bug in the handling of a vi-command, please try to produce an example that looks something like this:

    $text->Contents( <<END );
    Some
    Initial
    State
    END

    $text->InsertKeypress( $_ ) for split //, 'commands in error';

Along with the expected final state of the widget (contents, cursor location, register contents etc).

If the bug relates to the location of the cursor after the command, note the difference between Tk::Text cursor positions and vi cursor positions described above.  The command may be correct, but the cursor location looks wrong due to this difference.

=head2 Known Bugs

=over 4

=item *

Using the mouse or $text->SetCursor you may illegally place the cursor after the last character in the line.

=item *

Similarly, movement with the mouse or arrow keys can cause problems when a the state of the widget depends on cursor location.

=item *

Counts are not implemented on insert commands like normal-i or normal-o.

=item *

Commands that use mappings internally (D and x) do not correctly use the count or registers.

=item *

Normal-/ should behave like a motion, but doesn't.

=item *

Normal-/ and normal-n will not wrap after hitting end of file.

=item *

Normal-u undoes individual Tk::Text actions rather than vi-commands.

=item *

Insert-Control-O does not work with visual-mode

=item *

Keypresses that map to a movement command do not work as motions.

=item *

This modules makes it much easier to commit the programmer's third deadly sin.

=back

=head1 SEE ALSO

Tk::TextUndo and Tk::Text for details on the inherited functionality.

:help index (in vim) for details on the commands emulated.

=head1 AUTHOR

Joseph Strom, C<< <j-strom@verizon.net> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Joseph Strom, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

