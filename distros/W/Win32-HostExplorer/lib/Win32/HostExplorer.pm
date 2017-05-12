package Win32::HostExplorer;

use strict;
use warnings;
use Carp;
use Win32::OLE;
use IO::File;
our ( $VERSION );
$VERSION = '0.01';

sub new {
    my $class   = shift;
    my %options = @_;
    my $self    = bless( {}, $class );

    ( exists $options{debug} )
      ? ( $self->{debug} = $options{debug} )
      : ( $self->{debug} = 0 );

    $self->{who_called} =
      sub { "debug$self->{debug}> " . ( caller(1) )[3] . "()" };
    carp &{ $self->{who_called} } if $self->{debug};

    $self->{log_file} = ( exists $options{logfile} )
      ? $options{logfile}
      : '' ;

    if ( $self->{log_file} ) {
        $self->{fh} = IO::File->new("> $self->{log_file}");
        unless ( $self->{fh} ) { croak "can't open log file : $!" }
        $self->{fh}->print( "Started: " .
          localtime(time) . "  Process: " . $$ . "\n" );
    }

    $self->{hex} = Win32::OLE->new("HostExplorer")
      or croak "Can't start HostExplorer\n";
    return $self;
}

sub write_log {
    my ( $self, $message ) = @_;
    carp &{ $self->{who_called} } if $self->{debug};
    carp "debug$self->{debug}> args = $message"
      if $self->{debug} >= 2;

    unless ( $self->{fh} ) { croak "can't open $self->{log_file} : $!" }
    $self->{fh}->print( $message . "\n" );
}

sub show_row {
    my ( $self, $line ) = @_;
    carp &{ $self->{who_called} }              if $self->{debug};
    carp "debug$self->{debug}> args = '$line'" if $self->{debug} >= 2;

    my $ret_val = $self->{hex}->CurrentHost->Row($line);
    carp "debug$self->{debug}> ret_val = $ret_val"
      if $self->{debug} >= 3;
    return $ret_val;
}

sub show_lines {
    my ( $self, @lines ) = @_;
    carp &{ $self->{who_called} } if $self->{debug};
    my @array = ();

    unless (@lines) { @lines = ( 1 .. 24 ) }
    carp "debug$self->{debug}> args = @lines"
      if $self->{debug} >= 2;

    foreach (@lines) {
        push @array, $self->show_row($_);
    }
    wantarray ? return @array : return join '', @array;
}

sub title_row {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};

    my $ret_val = $self->show_row(1);
    carp "debug$self->{debug}> ret_val = $ret_val"
      if $self->{debug} >= 3;
    return $ret_val;
}

sub status_row {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};

    my $ret_val = $self->show_row(24);
    carp "debug$self->{debug}> ret_val = $ret_val"
      if $self->{debug} >= 3;
    return $ret_val;
}

sub cursor_pos {
    my ( $self, @rest ) = @_;
    carp &{ $self->{who_called} } if $self->{debug};

    if (@rest) {
        my ( $row, $col ) = @rest;
        carp "debug$self->{debug}> args = $row, $col"
          if $self->{debug} >= 2;
        $self->{hex}->CurrentHost->CursorRc( $row, $col );
    }

    my $position = $self->{hex}->CurrentHost->Cursor();
    my ( $row, $col ) = ( ( int $position / 80 ) + 1, $position % 80 );
    carp "debug$self->{debug}> ret_val = $row, $col"
      if $self->{debug} >= 3;
    return ( $row, $col );
}

sub match_pattern {
    my ( $self, $pattern, @lines ) = @_;
    carp &{ $self->{who_called} } if $self->{debug};
    carp "debug$self->{debug}> args = $pattern, " . join( ', ', @lines )
      if $self->{debug} >= 2;
    my %results = ();

    unless (@lines) { @lines = ( 1 .. 24 ) }

    foreach (@lines) {
        ( $self->show_row($_) =~ /$pattern/ )
          ? ( $1 ? ( $results{$_} = $1 ) : ( $results{$_} = $& ) )
          : next;
    }

    my %ret_val = %results ? %results : ();
    carp "debug$self->{debug}> ret_val = " . join( ', ', @{ [%ret_val] } )
      if $self->{debug} >= 3;
    return %ret_val;
}

sub send_keys {
    my ( $self, $keys ) = @_;
    carp &{ $self->{who_called} } if $self->{debug};
    carp "debug$self->{debug}> args = $keys"
      if $self->{debug} >= 2;

    $self->{hex}->CurrentHost->Keys("$keys");
}

sub field_input {
    my ( $self, $row, $col, $keys ) = @_;
    carp &{ $self->{who_called} } if $self->{debug};
    carp "debug$self->{debug}> args = $row, $col, $keys"
      if $self->{debug} >= 2;

    $self->cursor_pos( $row, $col );
    $self->erase_eof();
    $self->send_keys("$keys");
}

sub f1 {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    $self->{hex}->CurrentHost->RunCmd("Pf1");
}

sub f2 {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    $self->{hex}->CurrentHost->RunCmd("Pf2");
}

sub f3 {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    $self->{hex}->CurrentHost->RunCmd("Pf3");
}

sub f4 {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    $self->{hex}->CurrentHost->RunCmd("Pf4");
}

sub f5 {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    $self->{hex}->CurrentHost->RunCmd("Pf5");
}

sub f6 {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    $self->{hex}->CurrentHost->RunCmd("Pf6");
}

sub f7 {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    $self->{hex}->CurrentHost->RunCmd("Pf7");
}

sub f8 {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    $self->{hex}->CurrentHost->RunCmd("Pf8");
}

sub f9 {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    $self->{hex}->CurrentHost->RunCmd("Pf9");
}

sub f10 {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    $self->{hex}->CurrentHost->RunCmd("Pf10");
}

sub f11 {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    $self->{hex}->CurrentHost->RunCmd("Pf11");
}

sub f12 {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    $self->{hex}->CurrentHost->RunCmd("Pf12");
}

sub pa1 {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    $self->{hex}->CurrentHost->RunCmd("Pa1");
}

sub pa2 {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    $self->{hex}->CurrentHost->RunCmd("Pa2");
}

sub pa3 {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    $self->{hex}->CurrentHost->RunCmd("Pa3");
}

sub reset {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    $self->{hex}->CurrentHost->RunCmd("Reset");
}

sub erase_eof {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    $self->{hex}->CurrentHost->RunCmd("Erase-EOF");
}

sub erase_eol {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    $self->{hex}->CurrentHost->RunCmd("Erase-EOL");
}

sub erase_line {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    $self->{hex}->CurrentHost->RunCmd("Erase-Line");
}

sub erase_input {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    $self->{hex}->CurrentHost->RunCmd("Erase-Input");
}

sub disconnect {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    $self->{hex}->CurrentHost->RunCmd("Disconnect");
}

sub connect {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    $self->{hex}->CurrentHost->RunCmd("Connect");
}

sub clear {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    $self->{hex}->CurrentHost->RunCmd("Clear");
}

sub enter {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    $self->{hex}->CurrentHost->RunCmd("Enter");
}

sub newline {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    $self->{hex}->CurrentHost->RunCmd("NewLine");
}

sub tab {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    $self->{hex}->CurrentHost->RunCmd("Tab");
}

sub back_tab {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    $self->{hex}->CurrentHost->RunCmd("Back-Tab");
}

sub back_space {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    $self->{hex}->CurrentHost->RunCmd("Backspace");
}

sub left {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    $self->{hex}->CurrentHost->RunCmd("Left");
}

sub right {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    $self->{hex}->CurrentHost->RunCmd("Right");
}

sub up {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    $self->{hex}->CurrentHost->RunCmd("Up");
}

sub down {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    $self->{hex}->CurrentHost->RunCmd("Down");
}

sub selectall {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    $self->{hex}->CurrentHost->RunCmd("Edit-SelectAll");
}

sub copy {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    $self->{hex}->CurrentHost->RunCmd("Edit-Copy");
}

sub selectall_copy {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    $self->selectall();
    $self->copy();
}

sub paste {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    $self->{hex}->CurrentHost->RunCmd("Edit-Paste");
}

sub paste_wordwrap {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    $self->{hex}->CurrentHost->RunCmd("Edit-Paste-StreamWordWrap");
}

sub toggle_insert {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    $self->{hex}->CurrentHost->RunCmd("Toggle-Insert");
}

sub home {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    $self->{hex}->CurrentHost->RunCmd("Home");
}

sub end {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    $self->{hex}->CurrentHost->RunCmd("Cursor-EOL");
}

sub toggle_capture {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    $self->{hex}->CurrentHost->RunCmd("Toggle-Capture");
}

sub hide {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    $self->{hex}->CurrentHost->Hide();
}

sub show {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    $self->{hex}->CurrentHost->Show();
}

sub maximize {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    $self->{hex}->CurrentHost->Maximize();
}

sub minimize {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    $self->{hex}->CurrentHost->Minimize();
}

sub restore {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    $self->{hex}->CurrentHost->Restore();
}

sub hide_toolbar {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    $self->{hex}->CurrentHost->HideToolbar();
}

sub show_toolbar {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    $self->{hex}->CurrentHost->ShowToolbar();
}

sub keyboard {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    my $ret_val = $self->{hex}->CurrentHost->Keyboard();
    carp "debug$self->{debug}> ret_val = $ret_val"
      if $self->{debug} >= 3;
    return $ret_val;
}

sub activate {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    my $ret_val = $self->{hex}->CurrentHost->Activate();
    return $ret_val;
}

sub capture_mode {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    my $ret_val = $self->{hex}->CurrentHost->Capture();
    return $ret_val;
}

sub start_capture {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};

    if ( $self->capture_mode() == 0 ) {
        $self->toggle_capture();
    }
    my $ret_val = $self->capture_mode();
    carp "debug$self->{debug}> ret_val = $ret_val"
      if $self->{debug} >= 3;
    return $ret_val;
}

sub stop_capture {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};

    if ( $self->capture_mode() == 1 ) {
        $self->toggle_capture();
    }
    my $ret_val = $self->capture_mode();
    carp "debug$self->{debug}> ret_val = $ret_val"
      if $self->{debug} >= 3;
    return $ret_val;
}

sub close {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    $self->{hex}->CurrentHost->Close;
}

sub columns {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    my $ret_val = $self->{hex}->CurrentHost->Columns;
    carp "debug$self->{debug}> ret_val = $ret_val"
      if $self->{debug} >= 3;
    return $ret_val;
}

sub rows {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    my $ret_val = $self->{hex}->CurrentHost->Rows;
    carp "debug$self->{debug}> ret_val = $ret_val"
      if $self->{debug} >= 3;
    return $ret_val;
}

sub font_larger {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    $self->{hex}->CurrentHost->FontLarger;
}

sub font_smaller {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    $self->{hex}->CurrentHost->FontSmaller;
}

sub insert_mode {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    my $ret_val = $self->{hex}->CurrentHost->InsertMode();
    carp "debug$self->{debug}> ret_val = $ret_val"
      if $self->{debug} >= 3;
    return $ret_val;
}

sub set_insert {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};

    if ( $self->insert_mode() == 0 ) {
        $self->toggle_insert();
    }
    my $ret_val = $self->insert_mode();
    carp "debug$self->{debug}> ret_val = $ret_val"
      if $self->{debug} >= 3;
    return $ret_val;
}

sub unset_insert {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};

    if ( $self->insert_mode() == 1 ) {
        $self->toggle_insert();
    }
    my $ret_val = $self->insert_mode();
    carp "debug$self->{debug}> ret_val = $ret_val"
      if $self->{debug} >= 3;
    return $ret_val;
}

sub connect_status {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};

    if ( $self->{hex}->CurrentHost->IsConnected() == 1 ) {
        carp "debug$self->{debug}> ret_val = 1"
          if $self->{debug} >= 3;
        return 1;
    }
    carp "debug$self->{debug}> ret_val = 0"
      if $self->{debug} >= 3;
    return 0;
}

sub print_screen {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    $self->{hex}->CurrentHost->PrintScreen();
}

sub put_text {
    my ( $self, $text, $row, $col ) = @_;
    carp &{ $self->{who_called} } if $self->{debug};
    $self->{hex}->CurrentHost->PutText( $text, $row, $col );
}

sub save_screen {
    my ( $self, $rest ) = @_;
    carp &{ $self->{who_called} } if $self->{debug};
    $self->{hex}->CurrentHost->SaveScreen($rest);
}

sub search {
    my ( $self, $string, $case, $row, $col ) = @_;
    carp &{ $self->{who_called} } if $self->{debug};
    carp "debug$self->{debug}> args = $string, $case, $row, $col"
      if $self->{debug} >= 2;

    unless ( $string ) {
      carp "debug$self->{debug}> (caller(0))[3] requires arg1";
    }

    unless ($case) { $case = 'FALSE' }
    if ( $case eq '0' ) { $case = 'FALSE' }
    if ( $case eq '1' ) { $case = 'TRUE' }
    unless ($row) { $row = 1 }
    unless ($col) { $col = 1 }

    my $position =
      $self->{hex}->CurrentHost->Search( $string, $case, $row, $col );

    if ( $position == 0 ) {
        return 0;
    }
    else {
        ( $row, $col ) = ( ( int $position / 80 ) + 1, $position % 80 );
    }

    carp "debug$self->{debug}> ret_val = $row, $col"
      if $self->{debug} >= 3;
    return ( $row, $col );
}

sub set_font {
    my ( $self, $name, $width, $height ) = @_;
    carp &{ $self->{who_called} } if $self->{debug};
    carp "debug$self->{debug}> args = $name, $width, $height"
      if $self->{debug} >= 2;
    $self->{hex}->CurrentHost->SetFont( $name, $width, $height );
}

sub text {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    my $ret_val = $self->{hex}->CurrentHost->Text();
    carp "debug$self->{debug}> ret_val = $ret_val"
      if $self->{debug} >= 3;
    return $ret_val;
}

sub text_rc {
    my ( $self, $row, $col, $leng ) = @_;
    carp &{ $self->{who_called} } if $self->{debug};
    carp "debug$self->{debug}> args = $row, $col, $leng"
      if $self->{debug} >= 2;
    $self->{hex}->CurrentHost->TextRC( $row, $col, $leng );
}

sub update {
    my ($self) = shift;
    carp &{ $self->{who_called} } if $self->{debug};
    $self->{hex}->CurrentHost->Update();
}

1;

__END__

=head1 NAME

Win32::HostExplorer - Automate telnet using Hummingbird HostExplorer and interact with the presentation space.

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Win32::HostExplorer;

    # Create new instance of HostExplorer
    my $obj = Win32::HostExplorer->new( debug => 3, logfile => $log_file );

    # Print the first line, last line
    print $obj->title_row(),  "\n";
    print $obj->status_row(), "\n";

    # Retrieve lines 2 and 7 through 12
    my @array = $obj->show_lines( 2, 7..12 );

    # Search lines 7 through 9 for the pattern
    $obj->match_pattern( '.*money\s+(\S+)', 7..9 );

    # Position cursor on row 7, column 11
    my ( $row, $col ) = $obj->cursor_pos( 7, 11 );

    # Send text to row/column 7,1
    $obj->field_input( 7, 1, 'Thelonius Monk' );

    # Execute function key 'F1' within terminal
    $obj->f1();


=head1 DESCRIPTION

The Win32::HostExplorer module provides an object-oriented interface and
methods to interact with the HostExplorer presentation space.

=head1 METHODS

=head2 CONSTRUCTION AND METHODS

=over 4

=item * Win32::HostExplorer->new();

The constructor returning the object for a new HostExplorer instance using Win32::OLE. Two options are supported with this method in hash format. All are optional.

debug

Setting the debug level to 1 will cause each to method to announce itself and its caller. Setting debug to 2 will add the arguments passed to the method.  Setting debug to 3 will add the return value of the method.

logfile

This designates a log file to be used in conjunction with the write_log() method.

=item * show_lines( 3, 8..14 )

Reads lines from the presentation space using line numbers as arguments. They are returned in list or scalar context. The default action, with no arguments, returns lines 1-24. Ranges are expressed as (start)..(end).

=item * title_row()

Reads the first row of the presentation space, which can often contain the page title.

=item * status_row()

Reads the last row of the presentation space, which can often contain the results of a command sequence.

=item * cursor_pos( 7, 11 )

With row/col arguments, positions the cursor in the presentation space, else returns the cursor position only.

Row and column indexes begin with 1;

=item * field_input( 7, 1, 'bang a gong' )

Combines three methods to position the cursor on a given row/column, clear the field, and insert keys.

=item * match_pattern( '.*free money\s+(\S+)', 7..9 )

Applies a regex pattern against the specified lines in the presentation space.

This returns, either the entire pattern matched or the parenthesized group.  Only one group is allowed.

=back


=head2 GENERIC METHODS

=head3 System Commands

=over 4

=item * activate()

Brings the window to the foreground.

=item * close()

This will close the session immediately.

=item * connect()

Connect the client to a host system.

=item * connect_status()

Tests the connection to your host.
0 = not connected, 1 = connected

=item * clear()

Clears all data from the terminal.

=item * disconnect()

Disconnects the client from a host system.

=item * hide() show()

Hide or display the screen whether it is minimized, normal, or maximized.
A hidden screen no longer shows in the taskbar.

=item * maximize() minimize() restore()

Methods to size the window.

=item * hide_toolbar() show_toolbar()

Use these methods to hide or show the session toolbar.

=item * start_capture() stop_capture()

Starts/stops capture mode.

=item * set_font()

A method to change the font.

$obj->set_font( 'Courier New', 0, 12 ); # ( $fontname, $width, $height )

=item * font_larger() font_smaller()

Resize the font.

=item * print_screen()

Print the current host session to the Windows printer specified in the profile for the session                   

=item * save_screen()

Save the current screen to a file.

$obj->save_screen( 'C:\saved.txt' );

=item * search()

Search the presentation space for a string.  Returns (row,col) — found or 0 — not found. Parameters - 'string', case( def. 0 = no case or 1 = case sensitive ), start_row( def. 1 ), start_col( def. 1 ).

$obj->search( "elvis", 0 ,1 ,1 );

=item * set_font()

Set the session font.

$obj->set_font( 'Courier New',$w, $h );

=item * text()

Use to retrieve the entire screen as a string.

my $text = $obj->text();

=item * text_rc()

Used to retrieve part of the screen as a string. Values for length include: 0 = Copy to EOF,   -1 = Copy to EOL,   -2 = Copy to EOW, -3 = Copy to EOScr, >0 = Exact length.

my $text = $obj->text_rc($row,$column,$length);

=item * update()
This method forces a repaint of the session window.

$obj->update();



=back





=head3 Action Keys

=over 4

=item * enter()

Sends the 'enter' key sequence.

=item * f1() .. f12()   pa1() .. pa3()

Function keys within the session.

=back


=head3 Editing

=over 4

=item * back_space()

Sends the 'backspace' key.

=item * send_keys( 'Thelonius Monk' )

Used to insert a key sequence into the presentation space at the current cursor position.

=item * erase_eof()

Clears text from the cursor position to the end of the field.

=item * erase_eol()

Clears text from the cursor position to the end of the line.

=item * erase_input()

Clears all editable text from the presentation space.

=item * selectall() copy() selectall_copy() paste() paste_wordwrap()

Copy/paste commands.

=item * set_insert() unset_insert()

These toggle the insert mode and return the state of the mode.
0 = reset, 1 = set

=item * newline()

Sends the 'newline' key sequence moving the cursor to the first editable position on the next line.

=item * tab() back_tab()

These methods are used to send the 'tab' or 'back-tab' key sequences, moving the cursor tab-wise through the input fields.

=item * left() right() up() down() home() end()

Cursor movement.

=item * put_text()

Like the send_keys() method but it allows you to specify the location to write the text.                   $obj->put_text( "Donna Lee", 2, 10 )        

=back


=head1 AUTHOR

George Kevin Hathorn, C<< <gekeha at gmail dot com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-win32-hostexplorer at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Win32-HostExplorer>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Win32::HostExplorer

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Win32-HostExplorer>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Win32-HostExplorer>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Win32-HostExplorer>

=item * Search CPAN

L<http://search.cpan.org/dist/Win32-HostExplorer>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2007 George Kevin Hathorn, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut



# vim:fdm=marker:ft=perl:ff=unix:nowrap:tw=0:ts=4:sw=4
