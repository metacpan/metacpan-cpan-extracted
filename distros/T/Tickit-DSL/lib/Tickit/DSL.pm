package Tickit::DSL;
# ABSTRACT: shortcuts for writing Tickit apps
use strict;
use warnings;

use parent qw(Exporter);

our $VERSION = '0.033';

=head1 NAME

Tickit::DSL - domain-specific language for Tickit terminal apps

=head1 VERSION

version 0.032

=head1 SYNOPSIS

 use Tickit::DSL;
 vbox {
  hbox { static 'left' } expand => 1;
  hbox { static 'right' } expand => 1;
 }

=head1 DESCRIPTION

WARNING: This is an early version, has an experimental API, and is
subject to change in future. Please get in contact and/or wait for
1.0 if you want something stable.

Provides a simplified interface for writing Tickit applications. This is
mainly intended for prototyping:

 #!/usr/bin/env perl
 use strict;
 use warnings;
 use Tickit::DSL;
 
 vbox {
  # Single line menu at the top of the screen
  menubar {
   submenu File => sub {
    menuitem Open  => sub { warn 'open' };
    menuspacer;
    menuitem Exit  => sub { tickit->stop };
   };
   submenu Edit => sub {
    menuitem Copy  => sub { warn 'copy' };
    menuitem Cut   => sub { warn 'cut' };
    menuitem Paste => sub { warn 'paste' };
   };
   menuspacer;
   submenu Help => sub {
    menuitem About => sub { warn 'about' };
   };
  };
  # A 2-panel layout covers most of the rest of the display
  widget {
   # Left and right panes:
   vsplit {
    # A tree on the left, 1/4 total width
    widget {
     placeholder;
    } expand => 1;
    # and a tab widget on the right, 3/4 total width
    widget {
     tabbed {
      widget { placeholder } label => 'First thing';
 	};
    } expand => 3;
   } expand => 1;
  } expand => 1;
  # At the bottom of the screen we show the status bar
  # statusbar { } show => [qw(clock cpu memory debug)];
  # although it's not on CPAN yet so we don't
 };
 tickit->run;

=cut

use Tickit::Widget::Border;
use Tickit::Widget::Box;
use Tickit::Widget::Breadcrumb;
use Tickit::Widget::Button;
use Tickit::Widget::CheckButton;
use Tickit::Widget::Decoration;
use Tickit::Widget::Entry;
use Tickit::Widget::Figlet;
use Tickit::Widget::FileViewer;
use Tickit::Widget::Frame;
use Tickit::Widget::FloatBox;
use Tickit::Widget::GridBox;
use Tickit::Widget::HBox;
use Tickit::Widget::HSplit;
use Tickit::Widget::Layout::Desktop;
use Tickit::Widget::Layout::Relative;
use Tickit::Widget::LogAny;
use Tickit::Widget::Menu;
use Tickit::Widget::MenuBar;
use Tickit::Widget::Menu::Item;
use Tickit::Widget::Placegrid;
use Tickit::Widget::Progressbar;
use Tickit::Widget::RadioButton;
use Tickit::Widget::Scroller;
use Tickit::Widget::Scroller::Item::Text;
use Tickit::Widget::Scroller::Item::RichText;
use Tickit::Widget::ScrollBox;
use Tickit::Widget::SegmentDisplay;
use Tickit::Widget::SparkLine;
use Tickit::Widget::Spinner;
use Tickit::Widget::Static;
use Tickit::Widget::Statusbar;
use Tickit::Widget::Tabbed;
use Tickit::Widget::Table;
use Tickit::Widget::Term;
use Tickit::Widget::Tree;
use Tickit::Widget::VBox 0.46; # the hypothesis is that this may help catch old Tickit installs
use Tickit::Widget::VHBox;
use Tickit::Widget::VSplit;

use List::UtilsBy qw(extract_by);

our $MODE;
our $PARENT;
our $RADIOGROUP;
our @PENDING_CHILD;
our $TICKIT;
our $LOOP;
our @WIDGET_ARGS;
our $GRID_COL;
our $GRID_ROW;

our @EXPORT = our @EXPORT_OK = qw(
    tickit later timer loop
    widget customwidget
    add_widgets
    gridbox gridrow vbox hbox vsplit hsplit desktop relative pane frame
    floatbox float
    static entry checkbox button
    radiogroup radiobutton
    scroller scroller_text scroller_richtext scrollbox
    console term
    tabbed
    tree table breadcrumb
    placeholder placegrid decoration
    statusbar
    menubar submenu menuitem menuspacer
    fileviewer
    logpanel
    figlet
);

=head1 METHODS

=head2 import

By default we'll import all the known widget shortcuts. To override this, pass a list
(possibly empty) on import:

 use Tickit::DSL qw();

By default, the synchronous L<Tickit> class will be used. You can make L</tickit> refer
to a L<Tickit::Async> object instead by passing the C< :async > tag:

 use Tickit::DSL qw(:async);

the default is C< :sync >, but you can make this explicit:

 use Tickit::DSL qw(:sync);

There is currently no support for mixing the two styles in a single application - if
C< :async > or C< :sync > have already been passed to a previous import, attempting
to apply the opposite one will cause an exception.

This is fine:

 use Tickit::DSL qw(:sync);
 use Tickit::DSL qw();
 use Tickit::DSL;

This is not:

 use Tickit::DSL qw(:sync);
 use Tickit::DSL qw(:async); # will raise an exception

=cut

sub import {
    my $class = shift;
    my ($mode) = extract_by { /^:a?sync$/ } @_;
    if($MODE && $mode && $mode ne $MODE) {
        die "Cannot mix sync/async - we are already $MODE and were requested to switch to $mode";
    } elsif($mode) {
        $MODE = $mode;
    }
    $MODE ||= ':sync';
    if($MODE eq ':sync') {
        require Tickit;
    } elsif($MODE eq ':async') {
        require IO::Async::Loop;
        require Tickit::Async;
    } else {
        die "Unknown mode: $MODE";
    }
    $class->export_to_level(1, $class, @_);
}

=head1 FUNCTIONS - Utility

All functions are exported, unless otherwise noted.

=cut

=head2 loop

Returns the L<IO::Async::Loop> instance if we're in C< :async > mode, throws an
exception if we're not. See L</import> for details.

=cut

sub loop {
    die "No loop available when running as $MODE" unless $MODE eq ':async';
    $LOOP = shift if @_;
    $LOOP ||= IO::Async::Loop->new
}

=head2 tickit

Returns (constructing if necessary) the L<Tickit> (or L<Tickit::Async>) instance.

=cut

sub tickit {
    $TICKIT = shift if @_;
    return $TICKIT if $TICKIT;

    if($MODE eq ':async') {
        $TICKIT = Tickit::Async->new;
        loop->add($TICKIT);
    } else {
        $TICKIT ||= Tickit->new;
    }
    $TICKIT
}

=head2 later

Defers a block of code.

 later {
  print "this happened later\n";
 };

Will run the code after the next round of I/O events.

=cut

sub later(&) {
    my $code = shift;
    tickit->later($code)
}

=head2 timer

Sets up a timer to run a block of code later.

 timer {
  print "about a second has passed\n";
 } after => 1;

 timer {
  print "about a minute has passed\n";
 } at => time + 60;

Takes a codeblock and either C<at> or C<after> definitions. Passing
anything other than a single definition will cause an exception.

=cut

sub timer(&@) {
    my $code = shift;
    my %args = @_;
    die 'when did you want to run the code?' unless 1 == grep exists $args{$_}, qw(at after);
    tickit->timer(%args, $code);
}

=head2 add_widgets

Adds some widgets under an existing widget.

 my $some_widget = vbox { };
 add_widgets {
  vbox { ... };
  hbox { ... };
 } under => $some_widget;

Returns the widget we added the new widgets under (i.e. the C< under > parameter).

=cut

sub add_widgets(&@) {
    my $code = shift;
    my %args = @_;
    local $PARENT = delete $args{under} or die 'expected add_widgets { ... } under => $some_widget;';
    local @WIDGET_ARGS = (@WIDGET_ARGS, %args);
    $code->($PARENT);
    $PARENT;
}

=head1 FUNCTIONS - Layout

The following functions create/manage widgets which are useful for layout purposes.

=head2 vbox

Creates a L<Tickit::Widget::VBox>. This is a container, so the first
parameter is a coderef which will switch the current parent to the new
vbox.

Any additional parameters will be passed to the new L<Tickit::Widget::VBox>
instance:

 vbox {
   ...
 } class => 'some_vbox';
 vbox {
   ...
 } classes => [qw(other vbox)], style => { fg => 'green' };

=cut

sub vbox(&@) {
    my ($code, %args) = @_;
    my %parent_args = map {; $_ => delete $args{'parent:' . $_} } map /^parent:(.*)/ ? $1 : (), keys %args;
    my $w = Tickit::Widget::VBox->new(%args);
    {
        local $PARENT = $w;
        $code->($w);
    }
    local @WIDGET_ARGS = (@WIDGET_ARGS, %parent_args);
    apply_widget($w);
}

=head2 vsplit

Creates a L<Tickit::Widget::VSplit>. This is a container, so the first
parameter is a coderef which will switch the current parent to the new
widget. Note that this widget expects 2 child widgets only.

Any additional parameters will be passed to the new L<Tickit::Widget::VSplit>
instance:

 vsplit {
   ...
 } class => 'some_vsplit';
 vsplit {
   ...
 } classes => [qw(other vsplit)], style => { fg => 'green' };

=cut

sub vsplit(&@) {
    my ($code, %args) = @_;
    my %parent_args = map {; $_ => delete $args{'parent:' . $_} } map /^parent:(.*)/ ? $1 : (), keys %args;
    my $w = do {
        local $PARENT = 'Tickit::Widget::VSplit';
        local @PENDING_CHILD;
        $code->();
        Tickit::Widget::VSplit->new(
            left_child  => $PENDING_CHILD[0],
            right_child => $PENDING_CHILD[1],
            %args,
        );
    };
    local @WIDGET_ARGS = (@WIDGET_ARGS, %parent_args);
    apply_widget($w);
}

=head2 frame

Uses L<Tickit::Widget::Frame> to draw a frame around a single widget. This is a container, so the first
parameter is a coderef which will switch the current parent to the new frame.

Any additional parameters will be passed to the new L<Tickit::Widget::Frame>
instance:

 frame {
   ...
 } title => 'some frame', title_align => 0.5;

=cut

sub frame(&@) {
    my ($code, %args) = @_;
    my %parent_args = map {; $_ => delete $args{'parent:' . $_} } map /^parent:(.*)/ ? $1 : (), keys %args;
    my $w = Tickit::Widget::Frame->new(%args);
    {
        local $PARENT = $w;
        $code->($w);
    }
    local @WIDGET_ARGS = (@WIDGET_ARGS, %parent_args);
    apply_widget($w);
}

=head2 gridbox

Creates a L<Tickit::Widget::GridBox>. This is a container, so the first
parameter is a coderef which will switch the current parent to the new
widget.

Although any widget is allowed here, you'll probably want all the immediate
children to be L</gridrow>s.

Any additional parameters will be passed to the new L<Tickit::Widget::GridBox>
instance:

 gridbox {
   gridrow { static 'left'; static 'right' };
   gridrow { static 'BL'; static 'BR' };
 } style => { col_spacing => 1, row_spacing => 1 };

=cut

sub gridbox(&@) {
    my ($code, %args) = @_;
    my %parent_args = map {; $_ => delete $args{'parent:' . $_} } map /^parent:(.*)/ ? $1 : (), keys %args;
    my $w = Tickit::Widget::GridBox->new(%args);
    {
        local $PARENT = $w;
        local $GRID_COL = 0;
        local $GRID_ROW = 0;
        $code->($w);
    }
    local @WIDGET_ARGS = (@WIDGET_ARGS, %parent_args);
    apply_widget($w);
}

=head2 gridrow

Marks a separate row in an existing L<Tickit::Widget::GridBox>. This behaves
something like a container, see L</gridbox> for details.

=cut

sub gridrow(&@) {
    my ($code) = @_;
    die "Grid rows must be in a gridbox" unless $PARENT->isa('Tickit::Widget::GridBox');
    $code->($PARENT);
    $GRID_COL = 0;
    ++$GRID_ROW;
}

=head2 hbox

Creates a L<Tickit::Widget::HBox>. This is a container, so the first
parameter is a coderef which will switch the current parent to the new
hbox.

Any additional parameters will be passed to the new L<Tickit::Widget::HBox>
instance:

 hbox {
   ...
 } class => 'some_hbox';
 hbox {
   ...
 } classes => [qw(other hbox)], style => { fg => 'green' };

=cut

sub hbox(&@) {
    my ($code, %args) = @_;
    my %parent_args = map {; $_ => delete $args{'parent:' . $_} } map /^parent:(.*)/ ? $1 : (), keys %args;
    my $w = Tickit::Widget::HBox->new(%args);
    {
        local $PARENT = $w;
        $code->($w);
    }
    local @WIDGET_ARGS = (@WIDGET_ARGS, %parent_args);
    apply_widget($w);
}

=head2 hsplit

Creates a L<Tickit::Widget::HSplit>. This is a container, so the first
parameter is a coderef which will switch the current parent to the new
widget. Note that this widget expects 2 child widgets only.

Any additional parameters will be passed to the new L<Tickit::Widget::HSplit>
instance:

 hsplit {
   ...
 } class => 'some_hsplit';
 hsplit {
   ...
 } classes => [qw(other hsplit)], style => { fg => 'green' };

=cut

sub hsplit(&@) {
    my ($code, %args) = @_;
    my %parent_args = map {; $_ => delete $args{'parent:' . $_} } map /^parent:(.*)/ ? $1 : (), keys %args;
    my $w = do {
        local $PARENT = 'Tickit::Widget::HSplit';
        local @PENDING_CHILD;
        $code->();
        Tickit::Widget::HSplit->new(
            top_child    => $PENDING_CHILD[0],
            bottom_child => $PENDING_CHILD[1],
            %args
        );
    };
    local @WIDGET_ARGS = (@WIDGET_ARGS, %parent_args);
    apply_widget($w);
}

=head2 desktop

Desktop layout. Pretty much like any other container,
but with the ability to specify window positions and
then move them around interactively.

 desktop {
  my $txt = static 'a static widget', 'parent:label' => 'static';
  entry {
   $txt->set_text($_[1])
  } 'parent:label' => 'entry widget',
    'parent:left' => 1,
    'parent:top' => 1;
 };

=cut

sub desktop(&@) {
    my ($code, %args) = @_;
    my %parent_args = map {; $_ => delete $args{'parent:' . $_} } map /^parent:(.*)/ ? $1 : (), keys %args;
    my $w = Tickit::Widget::Layout::Desktop->new(%args);
    {
        tickit->later(sub {
            local @WIDGET_ARGS;
            local $PARENT = $w;
            $code->($w);
        });
    }
    {
        local @WIDGET_ARGS = (@WIDGET_ARGS, %parent_args);
        apply_widget($w);
    }
}

=head2 relative

See L</pane> for the details.

=cut

sub relative(&@) {
    my ($code, %args) = @_;
    my %parent_args = map {; $_ => delete $args{'parent:' . $_} } map /^parent:(.*)/ ? $1 : (), keys %args;
    my $w = Tickit::Widget::Layout::Relative->new(%args);
    {
        local @WIDGET_ARGS;
        local $PARENT = $w;
        $code->($w);
    }
    {
        local @WIDGET_ARGS = (@WIDGET_ARGS, %parent_args);
        apply_widget($w);
    }
}

=head2 pane

A pane in a L</relative> layout.

=cut

sub pane(&@) {
    my ($code, %args) = @_;
    die "pane should be used within a relative { ... } item" unless $PARENT->isa('Tickit::Widget::Layout::Relative');
    {
        local @WIDGET_ARGS = (@WIDGET_ARGS, %args);
        $code->($PARENT);
    }
}

=head1 FUNCTIONS - Scrolling

The following functions create/manage widgets which deal with data that wouldn't
normally fit in the available terminal space.

=head2 scrollbox

Creates a L<Tickit::Widget::ScrollBox>. This is a container, so the first
parameter is a coderef which will switch the current parent to the new
widget. Note that this widget expects a single child widget only.

Any additional parameters will be passed to the new L<Tickit::Widget::ScrollBox>
instance:

 scrollbox {
   ...
 } class => 'some_hsplit';

=cut

sub scrollbox(&@) {
    my ($code, %args) = @_;
    my %parent_args = map {; $_ => delete $args{'parent:' . $_} } map /^parent:(.*)/ ? $1 : (), keys %args;
    my $w = do {
        local $PARENT = 'Tickit::Widget::ScrollBox';
        local @PENDING_CHILD;
        $code->();

        Tickit::Widget::ScrollBox->new(
            child => $PENDING_CHILD[0],
            %args
        );
    };
    local @WIDGET_ARGS = (@WIDGET_ARGS, %parent_args);
    apply_widget($w);
}

=head2 scroller

Adds a L<Tickit::Widget::Scroller>. Contents are probably going to be L</scroller_text>
for now.

 scroller {
   scroller_text 'line ' . $_ for 1..500;
 };

Passes any additional args to the constructor:

 scroller {
   scroller_text 'line ' . $_ for 1..100;
 } gravity => 'bottom';

=cut

sub scroller(&@) {
    my ($code, %args) = @_;
    my %parent_args = map {; $_ => delete $args{'parent:' . $_} } map /^parent:(.*)/ ? $1 : (), keys %args;
    my $w = Tickit::Widget::Scroller->new(%args);
    {
        local $PARENT = $w;
        $code->($w);
    }
    local @WIDGET_ARGS = (@WIDGET_ARGS, %parent_args);
    apply_widget($w);
}

=head2 scroller_text

A text item, expects to be added to a L</scroller>.

=cut

sub scroller_text {
    my $w = Tickit::Widget::Scroller::Item::Text->new(shift // '');
    apply_widget($w);
}

=head2 scroller_richtext

A text item, expects to be added to a L</scroller>. The item itself should be
a L<String::Tagged> instance, like this:

 my $str = String::Tagged->new( "An important message" );
 $str->apply_tag( 3, 9, b => 1 );
 scroller_richtext $str;


=cut

sub scroller_richtext {
    my $w = Tickit::Widget::Scroller::Item::RichText->new(shift);
    apply_widget($w);
}

=head2 console

Console widget. Current just supports creating the
console and setting an on_line callback:

 my $con = console {
  warn "Had a line: @_";
 };
 $con->add_tab(
  name => 'test',
  on_line => sub { warn "test line: @_" }
 );

although a future version may provide C< console_tab >
as a helper function for adding tabs to an existing
console.

Note that this will attempt to load L<Tickit::Console>
at runtime, so it may throw an exception if it is not
already installed.

=cut

sub console(&@) {
    require Tickit::Console;
    my %args = (on_line => @_);
    my %parent_args = map {; $_ => delete $args{'parent:' . $_} } map /^parent:(.*)/ ? $1 : (), keys %args;
    my $w = Tickit::Console->new(
        %args
    );
    local @WIDGET_ARGS = (@WIDGET_ARGS, %parent_args);
    apply_widget($w);
    $w
}

=head2 term

Terminal widget.

 term command => '/bin/bash';

=cut

sub term(@) {
    my %args = @_;
    my %parent_args = map {; $_ => delete $args{'parent:' . $_} } map /^parent:(.*)/ ? $1 : (), keys %args;
    my $w = Tickit::Widget::Term->new(
        %args
    );
    local @WIDGET_ARGS = (@WIDGET_ARGS, %parent_args);
    apply_widget($w);
    $w
}

=head2 logpanel

Displays any log messages raised by L<Log::Any> or, optionally, through STDERR.

 logpanel stderr => 1;

=cut

sub logpanel(@) {
    my %args = @_;
    my %parent_args = map {; $_ => delete $args{'parent:' . $_} } map /^parent:(.*)/ ? $1 : (), keys %args;
    my $w = Tickit::Widget::LogAny->new(
        %args
    );
    local @WIDGET_ARGS = (@WIDGET_ARGS, %parent_args);
    apply_widget($w);
    $w
}

=head1 FUNCTIONS - Miscellaneous container

These act as containers.

=head2 tabbed

Creates a L<Tickit::Widget::Tabbed> instance. Use the L</widget> wrapper
to set the label when adding new tabs, or provide the
label as a parent: attribute:

 tabbed {
   widget { static 'some text' } label => 'first tab';
   static 'other text' 'parent:label' => 'second tab';
 };

If you want a different ribbon, pass it like so:

 tabbed {
   static 'some text' 'parent:label' => 'first tab';
   static 'other text' 'parent:label' => 'second tab';
 } ribbon_class => 'Some::Ribbon::Class', tab_position => 'top';

The C<ribbon_class> parameter may be undocumented.

=cut

sub tabbed(&@) {
    my ($code, %args) = @_;
    my %parent_args = map {; $_ => delete $args{'parent:' . $_} } map /^parent:(.*)/ ? $1 : (), keys %args;
    my $w = Tickit::Widget::Tabbed->new(%args);
    {
        local $PARENT = $w;
        $code->($w);
    }
    local @WIDGET_ARGS = (@WIDGET_ARGS, %parent_args);
    apply_widget($w);
}

=head2 floatbox

A container which normally has no visible effect, but provides the ability to contain L</float>s.
These are floating windows which can be located anywhere within the container, usually for the purpose
of providing dynamic windows such as popups and dropdowns.

 floatbox {
  vbox {
   button {
    float {
     static 'this is a float'
    } lines => 3, top => -1, left => '-50%';
   } 'Show';
  }
 }

=cut

sub floatbox(&@) {
    my ($code, %args) = @_;
    my %parent_args = map {; $_ => delete $args{'parent:' . $_} } map /^parent:(.*)/ ? $1 : (), keys %args;
    my $w = Tickit::Widget::FloatBox->new(%args);
    {
        local $PARENT = $w;
        $code->($w);
    }
    local @WIDGET_ARGS = (@WIDGET_ARGS, %parent_args);
    apply_widget($w);
}

=head2 float

A L</float> provides a floating window within a L</floatbox> container - note that the L</floatbox>
does not need to be an immediate parent.

 floatbox {
  vbox {
   button {
    float {
     static 'this is a float'
    } lines => 3, top => -1, left => '-50%';
   } 'Show';
  }
 }

=cut

sub float(&@) {
    my ($code, %args) = @_;
    my %parent_args = map {; $_ => delete $args{'parent:' . $_} } map /^parent:(.*)/ ? $1 : (), keys %args;

    # Work out which container to use - either the least-distant ancestor,
    # or a specific floatbox if one was provided
    my $floatbox = delete($args{container}) || $PARENT;
    while($floatbox && !$floatbox->isa('Tickit::Widget::FloatBox')) {
        $floatbox = $floatbox->parent;
    }
    die "No floatbox found for this float" unless $floatbox;

    my $w = Tickit::Widget::VBox->new;
    my $float = $floatbox->add_float(
        child => $w,
        %args
    );
    # The new float won't be visible yet, defer this code until the
    # window is ready.
    later {
        local $PARENT = $w;
        $code->($float);
    };
}

=head2 statusbar

A L<Tickit::Widget::Statusbar>. Not very exciting.

=cut

sub statusbar(&@) {
    my ($code, %args) = @_;
    my %parent_args = map {; $_ => delete $args{'parent:' . $_} } map /^parent:(.*)/ ? $1 : (), keys %args;
    my $w = Tickit::Widget::Statusbar->new(%args);
    {
        local $PARENT = $w;
        $code->($w);
    }
    local @WIDGET_ARGS = (@WIDGET_ARGS, %parent_args);
    apply_widget($w);
}

=head1 FUNCTIONS - General widgets

=head2 static

Static text. Very simple:

 static 'some text';

You can be more specific if you want:

 static 'some text', align => 'center';

=cut

sub static {
    my %args = (text => @_);
    $args{text} //= '';
    my %parent_args = map {; $_ => delete $args{'parent:' . $_} } map /^parent:(.*)/ ? $1 : (), keys %args;
    my $w = Tickit::Widget::Static->new(
        %args
    );
    local @WIDGET_ARGS = (@WIDGET_ARGS, %parent_args);
    apply_widget($w);
}

=head2 figlet

Fancier text, generated by L<Text::FIGlet>. Same as static:

 figlet 'some text';

but you can specify a font as well:

 figlet 'some text', font => 'slant';

=cut

sub figlet {
    my %args = (text => @_);
    $args{text} //= '';
    my %parent_args = map {; $_ => delete $args{'parent:' . $_} } map /^parent:(.*)/ ? $1 : (), keys %args;
    my $w = Tickit::Widget::Figlet->new(
        %args
    );
    local @WIDGET_ARGS = (@WIDGET_ARGS, %parent_args);
    apply_widget($w);
}

=head2 entry

A L<Tickit::Widget::Entry> input field. Takes a coderef as the first parameter
since the C<on_enter> handler seems like an important feature.

 my $rslt = static 'result here';
 entry { shift; $rslt->set_text(eval shift) } text => '1 + 3';

=cut

sub entry(&@) {
    my %args = (on_enter => @_);
    my %parent_args = map {; $_ => delete $args{'parent:' . $_} } map /^parent:(.*)/ ? $1 : (), keys %args;
    my $w = Tickit::Widget::Entry->new(
        %args
    );
    local @WIDGET_ARGS = (@WIDGET_ARGS, %parent_args);
    apply_widget($w);
}

=head2 checkbox

Checkbox (or checkbutton).

=cut

sub checkbox(&@) {
    my %args = (on_toggle => @_);
    my %parent_args = map {; $_ => delete $args{'parent:' . $_} } map /^parent:(.*)/ ? $1 : (), keys %args;
    my $w = Tickit::Widget::CheckButton->new(
        %args
    );
    local @WIDGET_ARGS = (@WIDGET_ARGS, %parent_args);
    apply_widget($w);
}

=head2 radiobutton

 radiogroup {
  radiobutton { } 'one';
  radiobutton { } 'two';
  radiobutton { } 'three';
 };

=cut

sub radiobutton(&@) {
    my $code = shift;
    die "need a radiogroup" unless $RADIOGROUP;
    my %args = (
        group => $RADIOGROUP,
        label => @_
    );
    my %parent_args = map {; $_ => delete $args{'parent:' . $_} } map /^parent:(.*)/ ? $1 : (), keys %args;
    my $w = Tickit::Widget::RadioButton->new(%args);
    $w->set_on_toggle($code);
    {
        local @WIDGET_ARGS = %parent_args;
        apply_widget($w);
    }
}

=head2 radiogroup

See L</radiobutton>.

=cut

sub radiogroup(&@) {
    my $code = shift;
    my %args = @_;
    # my %parent_args = map {; $_ => delete $args{'parent:' . $_} } map /^parent:(.*)/ ? $1 : (), keys %args;
    my $group = Tickit::Widget::RadioButton::Group->new;
    $group->set_on_changed(delete $args{on_changed}) if exists $args{on_changed};
    {
        local $RADIOGROUP = $group;
        $code->();
    }
}

=head2 button

A button. First parameter is the code to run when activated,
second parameter is the label:

 button { warn "Activated" } 'OK';

=cut

sub button(&@) {
    my $code = shift;
    my %args = (
        label => @_
    );
    my %parent_args = map {; $_ => delete $args{'parent:' . $_} } map /^parent:(.*)/ ? $1 : (), keys %args;
    my $w = Tickit::Widget::Button->new(
        %args
    );
    $w->set_on_click(sub {
        local $PARENT = $w->parent;
        $code->($w->parent);
    });
    {
        local @WIDGET_ARGS = (@WIDGET_ARGS, %parent_args);
        apply_widget($w);
    }
}

=head2 tree

A L<Tickit::Widget::Tree>. It only partially works, but you're welcome to try it.

 tree {
    warn "activated: @_\n";
 } data => [
    node1 => [
        qw(some nodes here)
    ],
    node2 => [
        qw(more nodes in this one),
        and => [
            qw(this has a few child nodes too)
        ]
    ],
 ];

=cut

sub tree(&@) {
    my %args = (on_activate => @_);
    my %parent_args = map {; $_ => delete $args{'parent:' . $_} } map /^parent:(.*)/ ? $1 : (), keys %args;

    my $w = Tickit::Widget::Tree->new(
        %args
    );
    local @WIDGET_ARGS = (@WIDGET_ARGS, %parent_args);
    apply_widget($w);
    $w
}

=head2 table

Tabular rendering.

 table {
  warn "activated one or more items";
 } data => [
  [ 1, 'first line' ],
  [ 2, 'second line' ],
 ], columns => [
  { label => 'ID', width => 9, align => 'right' },
  { label => 'Description' },
 ];

=cut

sub table(&@) {
    my %args = (on_activate => @_);
    my %parent_args = map {; $_ => delete $args{'parent:' . $_} } map /^parent:(.*)/ ? $1 : (), keys %args;
    my $w = Tickit::Widget::Table->new(
        %args
    );
    local @WIDGET_ARGS = (@WIDGET_ARGS, %parent_args);
    apply_widget($w);
    $w
}

=head2 breadcrumb

Provides a "breadcrumb trail".

 my $bc = breadcrumb {
  warn "crumb selected: @_";
 };
 $bc->adapter->push([qw(some path here)]);

=cut

sub breadcrumb(&@) {
    my %args = (on_activate => @_);
    my %parent_args = map {; $_ => delete $args{'parent:' . $_} } map /^parent:(.*)/ ? $1 : (), keys %args;
    my $w = Tickit::Widget::Breadcrumb->new(
        %args
    );
    local @WIDGET_ARGS = (@WIDGET_ARGS, %parent_args);
    apply_widget($w);
    $w
}

=head2 placeholder

Use this if you're not sure which widget you want yet. It's a L<Tickit::Widget::Placegrid>,
so there aren't many options.

 placeholder;
 vbox {
   widget { placeholder } expand => 3;
   placeholder 'parent:expand' => 5;
 };

This is also available under the alias C<placegrid>.

=cut

sub placeholder(@) {
    my %args = @_;
    my %parent_args = map {; $_ => delete $args{'parent:' . $_} } map /^parent:(.*)/ ? $1 : (), keys %args;
    local @WIDGET_ARGS = (@WIDGET_ARGS, %parent_args);
    apply_widget(Tickit::Widget::Placegrid->new(%args));
}

=head2 placegrid

An alias for L</placeholder>.

=cut

sub placegrid(@) { goto \&placeholder }

=head2 decoration

Purely decorative. A L<Tickit::Widget::Decoration>, controlled entirely through styles.

 decoration;
 vbox {
   widget { decoration } expand => 3;
   decoration class => 'deco1', 'parent:expand' => 5;
 };

=cut

sub decoration(@) {
    my %args = @_;
    my %parent_args = map {; $_ => delete $args{'parent:' . $_} } map /^parent:(.*)/ ? $1 : (), keys %args;
    local @WIDGET_ARGS = (@WIDGET_ARGS, %parent_args);
    apply_widget(Tickit::Widget::Decoration->new(%args));
}

=head2 fileviewer

File viewer. Takes a code block and a file name. The code block is currently unused,
but eventually will be called when the current line is activated in the widget.

 fileviewer { } 'somefile.txt';

=cut

sub fileviewer(&;@) {
    my ($code, $file) = splice @_, 0, 2;
    my %args = (
        @_,
        file => $file
    );
    my %parent_args = map {; $_ => delete $args{'parent:' . $_} } map /^parent:(.*)/ ? $1 : (), keys %args;

    my $w = Tickit::Widget::FileViewer->new(
        %args
    );
    {
        local @WIDGET_ARGS = (@WIDGET_ARGS, %parent_args);
        apply_widget($w);
    }
}

=head2 FUNCTIONS - Menu-related

Things for menus

=head2 menubar

Menubar courtesy of L<Tickit::Widget::MenuBar>. Every self-respecting app wants
one of these.

 menubar {
  submenu File => sub {
   menuitem Exit  => sub { tickit->stop };
  };
  menuspacer;
  submenu Help => sub {
   menuitem About => sub { warn 'about' };
  };
 };

You'll probably want to show popup menus at some
point. Try this:

 floatbox {
  vbox {
   menubar {
    submenu Help => sub {
     menuitem About => sub {
      float {
       static 'this is a popup message'
      }
    };
   };
   static 'plain text under the menubar';
  }
 };

=cut

# haxx. A menubar has no link back to the container.
our $MENU_PARENT;
sub menubar(&@) {
    my ($code, %args) = @_;
    my %parent_args = map {; $_ => delete $args{'parent:' . $_} } map /^parent:(.*)/ ? $1 : (), keys %args;
    my $w = Tickit::Widget::MenuBar->new(%args);
    local $MENU_PARENT = $PARENT;
    {
        local $PARENT = $w;
        $code->($w);
    }
    local @WIDGET_ARGS = (@WIDGET_ARGS, %parent_args);
    apply_widget($w);
}

=head2 submenu

A menu entry in a L</menubar>. First parameter is used as the label,
second is the coderef to populate the widgets (will be called immediately).

See L</menubar>.

=cut

sub submenu {
    my ($text, $code) = splice @_, 0, 2;
    my %args = @_;
    my %parent_args = map {; $_ => delete $args{'parent:' . $_} } map /^parent:(.*)/ ? $1 : (), keys %args;
    my $w = Tickit::Widget::Menu->new(name => $text);
    {
        local $PARENT = $w;
        $code->($w);
    }
    local @WIDGET_ARGS = (@WIDGET_ARGS, %parent_args);
    apply_widget($w);
}

=head2 menuspacer

Adds a spacer if you're in a menu. No idea what it'd do if you're not in a menu.

=cut

sub menuspacer() {
    my $w = Tickit::Widget::Menu->separator;
    apply_widget($w);
}

=head2 menuitem

A menu is not much use without something in it. See L</menubar>.

=cut

sub menuitem {
    my ($text, $code) = splice @_, 0, 2;
    my $parent = $MENU_PARENT;
    my $w = Tickit::Widget::Menu::Item->new(
        name        => $text,
        on_activate => sub {
            local $PARENT = $parent;
            $code->($PARENT);
        },
        @_
    );
    apply_widget($w);
}

=head2 FUNCTIONS - Generic or internal use

Things that don't really fit into the other categories.

=head2 customwidget

A generic function for adding 'custom' widgets - i.e. anything that's not already
supported by this module.

This will call the coderef, expecting to get back a L<Tickit::Widget>, then it'll
apply that widget to whatever the current parent is. Any options will be passed
as widget arguments, see L</widget> for details.

 customwidget {
  my $tbl = Tickit::Widget::Table::Paged->new;
  $tbl->add_column(...);
  $tbl;
 } expand => 1;

=cut

sub customwidget(&@) {
    my ($code, @args) = @_;
    my %args = @args;
    local $PARENT = delete($args{parent}) || $PARENT;
    my $w = $code->($PARENT);
    {
        local @WIDGET_ARGS = (@WIDGET_ARGS, %args);
        apply_widget($w);
    }
}

=head2 widget

Many container widgets provide support for additional options when adding child widgets.
For example, a L<Tickit::Widget::VBox> can take an C<expand> parameter which determines
how space should be allocated between children.

This function provides a way to pass those options - use it as a wrapper around another
widget-generating function, like so:

 widget { static 'this is text' } expand => 1;

in context, this would be:

 vbox {
   widget { static => '33%' } expand => 1;
   widget { static => '66%' } expand => 2;
 };

Note that this functionality can also be applied
by passing attributes with the C<parent:> prefix
o the widgets themselves - the above example would
thus be:

 vbox {
   static => '33%' 'parent:expand' => 1;
   static => '66%' 'parent:expand' => 2;
 };

=cut

sub widget(&@) {
    my ($code, %args) = @_;
    local $PARENT = delete($args{parent}) || $PARENT;
    {
        local @WIDGET_ARGS = (@WIDGET_ARGS, %args);
        $code->($PARENT);
    }
}

=head2 apply_widget

Internal function used for applying the given widget.

Not exported.

=cut

sub apply_widget {
    my $w = shift;
    if($PARENT) {
        if($PARENT->isa('Tickit::Widget::Scroller')) {
            $PARENT->push($w);
        } elsif($PARENT->isa('Tickit::Widget::Menu')) {
            $PARENT->push_item($w, @WIDGET_ARGS);
        } elsif($PARENT->isa('Tickit::Widget::MenuBar')) {
            $PARENT->push_item($w, @WIDGET_ARGS);
        } elsif($PARENT->isa('Tickit::Widget::HSplit')) {
            push @PENDING_CHILD, $w;
        } elsif($PARENT->isa('Tickit::Widget::VSplit')) {
            push @PENDING_CHILD, $w;
        } elsif($PARENT->isa('Tickit::Widget::ScrollBox')) {
            push @PENDING_CHILD, $w;
        } elsif($PARENT->isa('Tickit::Widget::Tabbed')) {
            $PARENT->add_tab($w, @WIDGET_ARGS);
        } elsif($PARENT->isa('Tickit::Widget::GridBox')) {
            $PARENT->add($GRID_ROW, $GRID_COL++, $w, @WIDGET_ARGS);
        } elsif($PARENT->isa('Tickit::Widget::FloatBox')) {
            # Needs 0.02+ to ensure parent is set correctly
            $PARENT->set_base_child($w);
        } elsif($PARENT->isa('Tickit::Widget::Layout::Desktop')) {
            my %args = @WIDGET_ARGS;
            $PARENT->create_panel(
                label  => 'New window',
                %args,
            )->add($w);
        } else {
            $PARENT->add($w, @WIDGET_ARGS);
        }
    } else {
        tickit->set_root_widget($w);
    }
    $w
}

1;

__END__

=head1 SEE ALSO

=over 4

=item * L<Tickit::Widget::Border>

=item * L<Tickit::Widget::Box>

=item * L<Tickit::Widget::Button>

=item * L<Tickit::Widget::CheckButton>

=item * L<Tickit::Widget::Console>

=item * L<Tickit::Widget::Decoration>

=item * L<Tickit::Widget::Entry>

=item * L<Tickit::Widget::FloatBox>

=item * L<Tickit::Widget::Frame>

=item * L<Tickit::Widget::GridBox>

=item * L<Tickit::Widget::HBox>

=item * L<Tickit::Widget::HSplit>

=item * L<Tickit::Widget::Layout::Desktop>

=item * L<Tickit::Widget::Layout::Relative>

=item * L<Tickit::Widget::Menu>

=item * L<Tickit::Widget::Placegrid>

=item * L<Tickit::Widget::Progressbar>

=item * L<Tickit::Widget::RadioButton>

=item * L<Tickit::Widget::Scroller>

=item * L<Tickit::Widget::Scroller::Item::Text>

=item * L<Tickit::Widget::ScrollBox>

=item * L<Tickit::Widget::SegmentDisplay>

=item * L<Tickit::Widget::SparkLine>

=item * L<Tickit::Widget::Static>

=item * L<Tickit::Widget::Statusbar>

=item * L<Tickit::Widget::Tabbed>

=item * L<Tickit::Widget::Table>

=item * L<Tickit::Widget::Tree>

=item * L<Tickit::Widget::VBox>

=item * L<Tickit::Widget::VSplit>

=back

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2012-2015. Licensed under the same terms as Perl itself.
