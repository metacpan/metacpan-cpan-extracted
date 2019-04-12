#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011-2016 -- leonerd@leonerd.org.uk

package Tickit::Test;

use strict;
use warnings;

our $VERSION = '0.67';

use Carp;

use Exporter 'import';

our @EXPORT = qw(
   mk_term
   mk_window
   mk_term_and_window
   flush_tickit
   drain_termlog
   clear_term

   resize_term

   presskey
   pressmouse

   is_termlog
   is_display
   is_cursorpos

   TEXT
   BLANK
   BLANKLINE
   BLANKLINES

   CLEAR
   GOTO
   ERASECH
   INSERTCH
   DELETECH
   SCROLLRECT
   PRINT
   SETPEN
   SETBG
);

use Tickit::Test::MockTerm;
use Tickit::Pen;
use Tickit;

use Tickit::Utils qw( textwidth substrwidth );

use Test::Builder;

=head1 NAME

C<Tickit::Test> - unit testing for C<Tickit>-based code

=head1 SYNOPSIS

 use Test::More tests => 2;
 use Tickit::Test;

 use Tickit::Widget::Static;

 my $win = mk_window;

 my $widget = Tickit::Widget::Static->new( text => "Message" );

 $widget->set_window( $win );

 flush_tickit;

 is_termlog( [ SETPEN,
               CLEAR,
               GOTO(0,0),
               SETPEN,
               PRINT("Message"),
               SETBG(undef),
               ERASECH(73) ] );

 is_display( [ "Message" ] );

=head1 DESCRIPTION

This module helps write unit tests for L<Tickit>-based code, such as
L<Tickit::Widget> subclasses. Primarily, it provides a mock terminal
implementation, allowing the code under test to affect a virtual terminal,
whose state is inspectable by the unit test script.

This module is used by the C<Tickit> unit tests themselves, and provided as an
installable module, so that authors of widget subclasses can use it too.

=cut

=head1 FUNCTIONS

=cut

my $term;
my $tickit;

=head2 mk_term

   $term = mk_term

Constructs and returns the mock terminal to unit test with. This object will
be cached and returned if this function is called again. Most unit tests will
want a root window as well; for convenience see instead C<mk_term_and_window>.

The mock terminal usually starts with a size of 80 columns and 25 lines,
though can be overridden by passing named arguments.

 $term = mk_term lines => 30, cols => 100;

=cut

sub mk_term
{
   return $term ||= Tickit::Test::MockTerm->new( @_ );
}

=head2 mk_window

   $win = mk_window

Construct a root window using the mock terminal, to unit test with.

=cut

sub mk_window
{
   mk_term;

   $tickit = __PACKAGE__->new(
      term => $term
   );

   my $win = $tickit->rootwin;

   $tickit->setup_term;

   # Clear the method log from ->setup_term
   $term->get_methodlog;

   return $win;
}

=head2 mk_term_and_window

   ( $term, $win ) = mk_term_and_window

Constructs and returns the mock terminal and root window; equivalent to
calling each of C<mk_term> and C<mk_window> separately.

=cut

sub mk_term_and_window
{
   my $term = mk_term( @_ );
   my $win = mk_window;

   return ( $term, $win );
}

## Actual object implementation

use base qw( Tickit );

my @later;
sub later { push @later, $_[1] }

sub lines { return $term->lines }
sub cols  { return $term->cols  }

=head2 flush_tickit

   flush_tickit

Flushes any pending C<later> events in the testing C<Tickit> object. Because
the unit test script has no real event loop, this is required instead, to
flush any pending events.

=cut

sub flush_tickit
{
   while( @later ) {
      my @queue = @later; @later = ();
      $_->() for @queue;
   }

   $tickit->rootwin->flush if $tickit && $tickit->rootwin;
}

=head2 drain_termlog

   drain_termlog

Drains any pending events from the method log used by the C<is_termlog> test.
Useful to clear up non-tested events before running a test.

=cut

sub drain_termlog
{
   $term->get_methodlog;
}

=head2 clear_term

   clear_term

Clears the entire content form the mock terminal. Useful at the end of a
section of tests before starting another one. Don't forget to C<drain_termlog>
afterwards.

=cut

sub clear_term
{
   $term->clear
}

=head2 resize_term

   resize_term( $lines, $cols )

Resize the virtual testing terminal to the size given

=cut

sub resize_term
{
   my ( $lines, $cols ) = @_;
   $term->resize( $lines, $cols );
}

=head2 presskey

   presskey( $type, $str, $mod )

Fire a key event

=cut

sub presskey
{
   my ( $type, $str, $mod ) = @_;

   $term->_emit_key( Tickit::Event::Key->_new( $type, $str, $mod || 0 ) );
}

=head2 pressmouse

   pressmouse( $type, $button, $line, $col, $mod )

Fire a mouse button event

=cut

sub pressmouse
{
   my ( $type, $button, $line, $col, $mod ) = @_;

   $term->_emit_mouse( Tickit::Event::Mouse->_new( $type, $button, $line, $col, $mod || 0 ) );
}

=head1 TEST FUNCTIONS

The following functions can be used like C<Test::More> primitives, in unit
test scripts.

=cut

sub _pen2string
{
   my $pen = shift;
   my %attrs = $pen ? %$pen : ();

   # Normalise requests to reset to default as undef
   defined $attrs{$_} and $attrs{$_} == -1 and undef $attrs{$_} for @Tickit::Pen::INT_ATTRS;
   !$attrs{$_}                             and undef $attrs{$_} for @Tickit::Pen::BOOL_ATTRS;

   # Remove undefs
   defined $attrs{$_} or delete $attrs{$_} for keys %attrs;

   return "{" . join( ",", map { defined $attrs{$_} ? "$_=" . ($attrs{$_} || 0) : "!$_" } sort keys %attrs ) . "}";
}

=head2 is_termlog

   is_termlog( [ @log ], $name )

Asserts that the mock terminal log contains exactly the given sequence of
methods. See also the helper functions below.

Because this test is quite fragile, relying on the exact nature and order of
drawing methods invoked on the terminal, it should only be used rarely. Most
normal cases of widget unit tests should instead only use C<is_display>.

   is_termlog( { $pos => \@log, ... }, $name )

The expectation HASH is keyed by strings giving a GOTO position, and the test
asserts that a sequence of GOTO and other operations were performed equivalent
to the expectations given in the HASH.

This differs from the simpler ARRAY reference form by being somewhat more
robust against rendering order. It checks that every expectation sequence
happens exactly once, but does not care which order the sections happen in.

 is_termlog( { "0,0" => [ PRINT("Hello") ],
               "0,6" => [ PRINT("World!") ] } );

=cut

sub _step_to_text
{
   my ( $step ) = @_;

   return "none" unless defined $step;

   my ( $op, @args ) = @$step;

   if( $op eq "setpen" ) {
      return "$op(" . _pen2string( $args[0] ) . ")";
   }
   else {
      return "$op(" . join( ",", map { defined $_ ? $_ =~ m/^-?\d+$/ ? $_ : qq("$_") : "undef" } @args ) . ")";
   }
}

sub _steps_ok
{
   my ( $tb, $want_log, $got_log, $stop_before_GOTO, $name ) = @_;

   my $prev_line;

   for( my $idx = 0; @$want_log or @$got_log; $idx++ ) {
      my $got_line;

      if( $stop_before_GOTO and @$got_log and $got_log->[0][0] eq "goto" ) {
         $got_line = undef;
      }
      else {
         $got_line = shift @$got_log;
      }

      my $want_line = shift @$want_log;

      if( $want_line and $want_line->[0] eq "setpen_bg" and
          $got_line  and $got_line->[0] eq "setpen" ) {
         $got_line = [ setpen_bg => $got_line->[1]->{bg} ];
      }

      $_ = _step_to_text($_) for $want_line, $got_line;

      if( $want_line eq $got_line ) {
         $prev_line = $want_line;

         return 1 if $stop_before_GOTO and @$got_log and $got_log->[0][0] eq "goto";
         next;
      }

      local $" = ",";
      my $ok = $tb->ok( 0, $name );
      $tb->diag( "Expected terminal operation $want_line, got $got_line at step $idx" );
      $tb->diag( "  after $prev_line" ) if defined $prev_line;
      return $ok;
   }

   return 1;
}

sub is_termlog
{
   my ( $log, $name ) = @_;

   my $tb = Test::Builder->new;

   my @got_log = $term->get_methodlog;

   if( ref $log eq "ARRAY" ) {
      local $Test::Builder::Level = $Test::Builder::Level + 1;
      return unless _steps_ok( $tb, $log, \@got_log, 0, $name );
   }
   elsif( ref $log eq "HASH" ) {
      my %regions = %$log;

      while( keys %regions and @got_log ) {
         if( !$got_log[0]->[0] eq "goto" ) {
            my $ok = $tb->ok( 0, $name );
            $tb->diag( "Expected a goto terminal operation, got " . _step_to_text( $got_log[0] ) );
            return $ok;
         }

         my $pos = sprintf "%d,%d", @{ shift @got_log }[1,2];
         my $want_log = delete $regions{$pos};
         unless( $want_log ) {
            my $ok = $tb->ok( 0, $name );
            $tb->diag( "Did not expect goto($pos)" );
            return $ok;
         }

         local $Test::Builder::Level = $Test::Builder::Level + 1;
         return unless _steps_ok( $tb, $want_log, \@got_log, 1, $name );
      }

      if( keys %regions ) {
         my $ok = $tb->ok( 0, $name );
         $tb->diag( "Expected a goto(" . ( keys %regions )[0] . ", got none" );
         return $ok;
      }
      if( @got_log ) {
         my $ok = $tb->ok( 0, $name );
         $tb->diag( "Expected none, got " . _step_to_text( $got_log[0] ) );
         return $ok;
      }
   }

   return $tb->ok( 1, $name );
}

=head2 is_display

   is_display( $lines, $name )

Asserts that the mock terminal display is exactly that as given by the content
of C<$lines>, which must be an ARRAY reference containing one value for each
line of the display. Each item may either be a plain string, or an ARRAY
reference.

If a plain string is given, it asserts that the characters on display are
those as given by the string (trailing blanks may be omitted). The pen
attributes of the characters do not matter in this case.

 is_display( [ "some lines of",
               "content here" ] );

If an ARRAY reference is given, it should contain chunks of content from the
C<TEXT> function. Each chunk represents content on display for the
corresponding columns.

 is_display( [ [TEXT("some"), TEXT(" lines of")],
               "content here" ] );

The C<TEXT> function accepts pen attributes, to assert that the displayed
characters have exactly the attributes given. In character cells containing
spaces, only the C<bg> attribute is tested.

 is_display( [ [TEXT("This is ",fg=>2), TEXT("bold",fg=>2,b=>1) ] ] );

The C<BLANK> function is a shortcut to providing a number of blank cells

 BLANK(20,bg=>1)  is   TEXT("                    ",bg=>1)

The C<BLANKLINE> and C<BLANKLINES> functions are a shortcut to providing an
entire line, or several lines, of blank content. They yield an array reference
or list of array references directly.

 BLANKLINE      is   [TEXT("")]
 BLANKLINES(3)  is   [TEXT("")], [TEXT("")], [TEXT("")]



=cut

sub is_display
{
   my ( $lines, $name ) = @_;

   my $tb = Test::Builder->new;

   foreach my $line ( 0 .. $term->lines - 1 ) {
      my $want = $lines->[$line];
      if( ref $want ) {
         my @chunks = @$want;

         my $col = 0;
         while( $col < $term->cols ) {
            my $chunk = shift @chunks;
            my ( $want_text ) = ref $chunk ? @$chunk : ( $chunk );

            $want_text .= " " x ( $term->cols - $col ) unless defined $want_text and length $want_text;

            my $got_text = $term->get_display_text( $line, $col, textwidth $want_text );
            if( $got_text ne $want_text ) {
               my $ok = $tb->ok( 0, $name );
               $tb->diag( "Display differs on line $line at column $col" );
               $tb->diag( "Got:      '$got_text'" );
               $tb->diag( "Expected: '$want_text'" );
               return $ok;
            }

            my $want_pen = _pen2string( $chunk->[1] );
            my $idx = 0;
            while( $idx < textwidth $want_text ) {
               if( substrwidth( $want_text, $idx, 1 ) eq " " ) {
                  my $want_bg = $chunk->[1]->{bg} // "undef";
                  my $got_bg = $term->get_display_pen( $line, $col )->{bg} // "undef";
                  if( $got_bg ne $want_bg ) {
                     my $ok = $tb->ok( 0, $name );
                     $tb->diag( "Display differs on line $line at column $col" );
                     $tb->diag( "Got pen bg:      $got_bg" );
                     $tb->diag( "Expected pen bg: $want_bg" );
                     return $ok;
                  }
               }
               else {
                  my $got_pen = _pen2string( $term->get_display_pen( $line, $col ) );
                  if( $got_pen ne $want_pen ) {
                     my $ok = $tb->ok( 0, $name );
                     $tb->diag( "Display differs on line $line at column $col" );
                     $tb->diag( "Got pen:      $got_pen" );
                     $tb->diag( "Expected pen: $want_pen" );
                     return $ok;
                  }
               }
               $idx++;
               $col++;
            }
         }
      }
      elsif( defined $want ) {
         my $display_line = $term->get_display_text( $line, 0, $term->cols );
         # pad blanks
         $want = sprintf "% -*s", $term->cols, $want;

         $want eq $display_line and next;

         my $ok = $tb->ok( 0, $name );
         $tb->diag( "Display differs on line $line" );
         $tb->diag( "Got:      '$display_line'" );
         $tb->diag( "Expected: '$want'" );
         return $ok;
      }
      else {
         my $display_line = $term->get_display_text( $line, 0, $term->cols );
         $display_line eq " " x $term->cols and next;

         my $ok = $tb->ok( 0, $name );
         $tb->diag( "Display differs on line $line" );
         $tb->diag( "Got:      '$display_line'" );
         $tb->diag( "Expected: blank" );
         return $ok;
      }
   }

   return $tb->ok( 1, $name );
}

=head2 is_cursorpos

   is_cursorpos( $line, $col, $name )

Asserts that the mock terminal cursor is at the given position.

=cut

sub is_cursorpos
{
   my ( $line, $col, $name ) = @_;

   my $tb = Test::Builder->new;

   my $at_line = $term->line;
   my $at_col  = $term->col;

   my $ok = $tb->ok( $line == $at_line && $col == $at_col, $name );

   $tb->diag( "Expected to be on line $line, actually on line $at_line"   ) if $line != $at_line;
   $tb->diag( "Expected to be on column $col, actually on column $at_col" ) if $col != $at_col;

   return $ok;
}

sub TEXT
{
   my $text = shift;
   my %attrs = @_;
   return [ $text, \%attrs ];
}

sub BLANK
{
   my $count = shift;
   TEXT(" "x$count, @_);
}

sub BLANKLINE
{
   [ TEXT("", @_) ];
}

sub BLANKLINES
{
   my $count = shift;
   ( BLANKLINE(@_) ) x $count;
}

use constant DEFAULTPEN => map { $_ => undef } @Tickit::Pen::ALL_ATTRS;

=head1 METHOD LOG HELPER FUNCTIONS

The following functions can be used to help write the expected log for a call
to C<is_termlog>.

 CLEAR
 GOTO($line,$col)
 ERASECH($count,$move_to_end)
 SCROLLRECT($top,$left,$lines,$cols,$downward,$rightward)
 PRINT($string)
 SETPEN(%attrs)
 SETBG($bg_attr)

=cut

sub CLEAR      { [ clear => ] }
sub GOTO       { [ goto => $_[0], $_[1] ] }
sub ERASECH    { [ erasech => $_[0], $_[1] || 0 ] }
sub SCROLLRECT { [ scrollrect => @_[0..5] ] }
sub PRINT      { [ print => $_[0] ] }
sub SETPEN     { [ setpen => { DEFAULTPEN, @_ } ] }
sub SETBG      { [ setpen_bg => $_[0] ] }

# Deprecated, will never match now
sub INSERTCH   { carp "INSERTCH() is no longer used by MockTerm";
                 [ insertch => $_[0] ] }
sub DELETECH   { carp "DELETECH() is no longer used by MockTerm";
                 [ deletech => $_[0] ] }

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
