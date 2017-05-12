package XUL::Gui;
    use warnings;
    use strict;
    use Carp;
    use Storable     'dclone';
    use List::Util   'max';
    use MIME::Base64 'encode_base64';
    use Encode       'encode';
    use Scalar::Util qw/weaken isweak reftype blessed/;
    BEGIN {
        local $@;
        eval {
            require Hash::Util;
            Hash::Util->import('hv_store'); 1
        } or do {
            *hv_store = sub (\%$$) {
                $_[0]{$_[1]} = $_[2];
                weaken $_[0]{$_[1]} if ref $_[2]
            };
            warn "XUL::Gui> Hash::Util::hv_store not found, memory usage will be higher\n"
        }
    }
    our $VERSION = '0.63';
    our $THREADS = $INC{'threads.pm'};  # disables a number of optimizations that break under threads
    our $TESTING;
    our $DEBUG              = 0; # verbosity from 0 - 6
    our $MOZILLA            = 1; # enables mozilla specific XUL, otherwise only HTML tags will work (Web::Gui mode)
    our $AUTOBUFFER         = 1; # enable autobuffering of SET messages
    our $EXTENDED_OBJECTS   = 1; # enable inheritance for normal objects (does not apply to widgets)
    our $TIED_WIDGETS       = 0; # enable data inheritance instead of copying in widgets (10-20% slower, potentially less memory usage)
    our $FILL_GENID_OBJECTS = 1; # include objects without a user set ID in the widget namespace
                                   # MUST BE SET BEFORE WIDGETS ARE CREATED (ideally, right after "use XUL::Gui;")
                                   # disabling this option will save some time and memory, but will
                                   # require accessing the object's {W} key to get to widget members for unnamed objects

    $Carp::Internal{"XUL::Gui$_"}++ for '', '::Object', '::Server';

    sub import {
        splice @_ => 1, 1, ':all'
            if @_ == 2 and $_[1] =~ /^(\*|all|)$/;

        require Exporter and
        goto &{ Exporter->can('import') }
            if @_ == 1
            or 1  < (@_ = grep {not
                /^(?: ([\w:!]*) -> \*? ([\w:!]*)
                    | ([\w:!]+::!*)
                )$/x && XUL::Gui->oo( $3 or $2 or $1 )
            } @_)
    }

=head1 NAME

XUL::Gui - render cross platform gui applications with firefox from perl

=head1 VERSION

version 0.63

this module is under active development, interfaces may change.

this code is currently in beta, use in production environments at your own risk

=head1 SYNOPSIS

    use XUL::Gui;
    display Label 'hello, world!';

    # short enough?  remove "Label" for bonus points

    use XUL::Gui;
    display Window title => "XUL::Gui's long hello",
        GroupBox(
            Caption('XUL'),
            Button(
                label     => 'click me',
                oncommand => sub {$_->label = 'ouch'}
            ),
            Button(
                id        => 'btn',
                label     =>'automatic id registration',
                oncommand => sub {
                    ID(btn)->label = 'means no more variable clutter';
                    ID(txt)->value = 'and makes cross tag updates easy';
            }),
            Button(
                type  => 'menu',
                label => 'menu button',
                MenuPopup map
                    {MenuItem label => $_} qw/first second third/
            ),
            TextBox( id => 'txt', width => 300 ),
            ProgressMeter( mode => 'undetermined' ),
        ),
        GroupBox(
            Caption('HTML too'),
            TABLE( width => '100%',
                TR map {TD $_}
                    'one', I('two'), B('three'), U('four'), SUP('five')
            ),
            BR, HR,
            P('all the HTML tags are in CAPS'),
        );

=head1 DESCRIPTION

this module exposes the entire functionality of mozilla firefox's rendering
engine to perl by providing all of the C< XUL > and C< HTML > tags as functions
and allowing you to interact with those objects directly from perl. gui
applications created with this toolkit are cross platform, fully support CSS
styling, inherit firefox's rich assortment of web technologies (browser, canvas
and video tags, flash and other plugins), and are even easier to write than
C< HTML >.

=head2 how things work

gui's created with this module are event driven. an arbitrarily complex (and
runtime mutable) object tree is passed to C< display >, which then creates the
gui in firefox and starts the event loop. C< display > will wait for and respond
to events until the C< quit > function is called, or the user closes the window.

all of javascript's event handlers are available, and can be written in perl
(normally) or javascript (for handlers that need to be very fast such as image
rollovers with onmouseover or the like). this is not to say that perl side
handlers are slow, but with rollovers and fast mouse movements, sometimes there
is mild lag due to protocol overhead.

this module is written in pure perl, and only depends upon core modules, making
it easy to distribute your application. the goal of this module is to make all
steps of gui development as easy as possible. XUL's widgets and nested design
structure gets us most of the way there, and this module with its light weight
syntax, and 'do what i mean' nature hopefully finishes the job. everything has
sensible defaults with minimal boilerplate, and nested design means a logical
code flow that isn't littered with variables. please send feedback if you think
anything could be improved.

=head2 building blocks

just like in C< HTML>, you build up your gui using tags. all tags (C< XUL >
tags, C< HTML > tags, user defined widgets, and the C< display > function) are
parsed the same way, and can fit into one of four templates:

=over 8

=item * no arguments

    HR()
    <hr />

=item * one simple argument

    B('some bold text')
    <b>some bold text<b/>

in the special case of a tag with one argument, which is not another tag, that
argument is added to that tag as a text node. this is mostly useful for HTML
tags, but works with XUL as well. once parsed, the line C< B('...') > becomes
C<< B( TEXT => '...' ) >>. the special C< TEXT > attribute can be used directly
if other attributes need to be set: C<< FONT( color=>'blue', TEXT=>'...' ) >>.

=item * multiple attributes

    Label( value=>'some text', style=>'color: red' )
    <label value="some text"   style="color: red;" />

=item * attributes and children

    Hbox( id => 'mybox', pack => 'center',
        Label( value => 'hello' ),
        BR,
        B('world')
    )

    <hbox id="mybox" pack="center">
        <label value="hello" />
        <br />
        <b>world</b>
    </hbox>

=back

as you can see, the tag functions in perl nest and behave the same way as their
counterpart element constructors in C< HTML/XUL >.  just like in C< HTML >, you
access the elements in your gui by C< id >. but rather than using
C< document.getElementById(...) > all the time, setting the C< id > attribute
names an element in the global C< %ID > hash.  the same hash can be accessed
using the C< ID(some_id) > function.

    my $object = Button( id => 'btn', label => 'OK' );

    #  $ID{btn} == ID(btn) == $object

the ID hash also exists in javascript:

    ID.btn == document.getElementById('btn')

due to the way this module works, every element needs an C< id >, so if you
don't set one yourself, an auto generated C< id > matching C< /^xul_\d+$/ > is
used.  you can use any C< id > that matches C< /\w+/ >

Tk's attribute style with a leading dash is supported.
this is useful for readability when collapsing attribute lists with C< qw// >

    TextBox id=>'txt', width=>75, height=>20, type=>'number', decimalplaces=>4;
    TextBox qw/-id txt -width 75 -height 20 -type number -decimalplaces 4/;

multiple 'style' attributes are joined with ';' into a single attribute



=head3 xul documentation links

all C< XUL > and C< HTML > objects in perl are exact mirrors of their javascript
counterparts and can be acted on as such. for anything not written in this
document or L<XUL::Gui::Manual>, developer.mozilla.com is the official source of
documentation:

=over

=item * L<https://developer.mozilla.org/en/XUL>

=item * L<https://developer.mozilla.org/en/XUL_Reference>

=item * L<https://developer.mozilla.org/En/Documentation_hot_links>

=item * L<http://www.hevanet.com/acorbin/xul/top.xul> - XUL periodic table

=back

=head2 event handlers

any tag attribute name that matches C< /^on/ > is an event handler (onclick,
onfocus, ...), and expects a C< sub {...} > (perl event handler) or
C< function q{...} > (javascript event handler).

perl event handlers get passed a reference to their object and an event object

    Button( label=>'click me', oncommand=> sub {
        my ($self, $event) = @_;
        $self->label = $event->type;
    })

in the event handler, C< $_ == $_[0] > so a shorter version would be:

    oncommand => sub {$_->label = pop->type}

javascript event handlers have C< event > and C< this > set for you

    Button( label=>'click me', oncommand=> function q{
        this.label = event.type;
    })

any attribute with a name that doesn't match C< /^on/ > that has a code ref
value is added to the object as a method.  methods are explained in more detail
later on.

=head1 EXPORT

    use XUL::Gui;   # is the same as
    use XUL::Gui qw/:base :util :pragma :xul :html :const :image/;

    the following export tags are available:

    :base       %ID ID alert display quit widget
    :tools      function gui interval serve timeout toggle XUL
    :pragma     buffered cached delay doevents flush noevents now
    :const      BLUR FILL FIT FLEX MIDDLE SCROLL
    :widgets    ComboBox filepicker prompt
    :image      bitmap bitmap2src
    :util       apply mapn trace zip
    :internal   genid object realid tag

    :all     (all exports)
    :default (same as with 'use XUL::Gui;')

    :xul    (also exported as Titlecase)
      Action ArrowScrollBox Assign BBox Binding Bindings Box Broadcaster
      BroadcasterSet Browser Button Caption CheckBox ColorPicker Column Columns
      Command CommandSet Conditions Content DatePicker Deck Description Dialog
      DialogHeader DropMarker Editor Grid Grippy GroupBox HBox IFrame Image Key
      KeySet Label ListBox ListCell ListCol ListCols ListHead ListHeader
      ListItem Member Menu MenuBar MenuItem MenuList MenuPopup MenuSeparator
      Notification NotificationBox Observes Overlay Page Panel Param PopupSet
      PrefPane PrefWindow Preference Preferences ProgressMeter Query QuerySet
      Radio RadioGroup Resizer RichListBox RichListItem Row Rows Rule Scale
      Script ScrollBar ScrollBox ScrollCorner Separator Spacer SpinButtons
      Splitter Stack StatusBar StatusBarPanel StringBundle StringBundleSet Tab
      TabBox TabPanel TabPanels Tabs Template TextBox TextNode TimePicker
      TitleBar ToolBar ToolBarButton ToolBarGrippy ToolBarItem ToolBarPalette
      ToolBarSeparator ToolBarSet ToolBarSpacer ToolBarSpring ToolBox ToolTip
      Tree TreeCell TreeChildren TreeCol TreeCols TreeItem TreeRow TreeSeparator
      Triple VBox Where Window Wizard WizardPage

    :html   (also exported as html_lowercase)
      A ABBR ACRONYM ADDRESS APPLET AREA AUDIO B BASE BASEFONT BDO BGSOUND BIG
      BLINK BLOCKQUOTE BODY BR BUTTON CANVAS CAPTION CENTER CITE CODE COL
      COLGROUP COMMENT DD DEL DFN DIR DIV DL DT EM EMBED FIELDSET FONT FORM
      FRAME FRAMESET H1 H2 H3 H4 H5 H6 HEAD HR HTML I IFRAME ILAYER IMG INPUT
      INS ISINDEX KBD LABEL LAYER LEGEND LI LINK LISTING MAP MARQUEE MENU META
      MULTICOL NOBR NOEMBED NOFRAMES NOLAYER NOSCRIPT OBJECT OL OPTGROUP OPTION
      P PARAM PLAINTEXT PRE Q RB RBC RP RT RTC RUBY S SAMP SCRIPT SELECT SMALL
      SOURCE SPACER SPAN STRIKE STRONG STYLE SUB SUP TABLE TBODY TD TEXTAREA
      TFOOT TH THEAD TITLE TR TT U UL VAR VIDEO WBR XML XMP

constants:

    FLEX    flex => 1
    FILL    flex => 1, align =>'stretch'
    FIT     sizeToContent => 1
    SCROLL  style => 'overflow: auto'
    MIDDLE  align => 'center', pack => 'center'
    BLUR    onfocus => 'this.blur()'

    each is a function that returns its constant, prepended to its arguments,
    thus the following are both valid:

    Box FILL pack=>'end';
    Box FILL, pack=>'end';

=cut

    sub FLEX   {flex => 1,                      @_}
    sub FILL   {qw/-flex 1 -align stretch/,     @_}
    sub FIT    {sizeToContent => 1,             @_}
    sub SCROLL {style => 'overflow: auto',      @_}
    sub MIDDLE {qw/-align center -pack center/, @_}
    sub BLUR   {qw/-onfocus this.blur()/,       @_}

    our @Xul = map {$_, (ucfirst lc) x /.[A-Z]/} qw {
        Action ArrowScrollBox Assign BBox Binding Bindings Box Broadcaster
        BroadcasterSet Browser Button Caption CheckBox ColorPicker Column
        Columns Command CommandSet Conditions Content DatePicker Deck
        Description Dialog DialogHeader DropMarker Editor Grid Grippy GroupBox
        HBox IFrame Image Key KeySet Label ListBox ListCell ListCol ListCols
        ListHead ListHeader ListItem Member Menu MenuBar MenuItem MenuList
        MenuPopup MenuSeparator Notification NotificationBox Observes Overlay
        Page Panel Param PopupSet PrefPane PrefWindow Preference Preferences
        ProgressMeter Query QuerySet Radio RadioGroup Resizer RichListBox
        RichListItem Row Rows Rule Scale Script ScrollBar ScrollBox ScrollCorner
        Separator Spacer SpinButtons Splitter Stack StatusBar StatusBarPanel
        StringBundle StringBundleSet Tab TabBox TabPanel TabPanels Tabs Template
        TextBox TextNode TimePicker TitleBar ToolBar ToolBarButton ToolBarGrippy
        ToolBarItem ToolBarPalette ToolBarSeparator ToolBarSet ToolBarSpacer
        ToolBarSpring ToolBox ToolTip Tree TreeCell TreeChildren TreeCol
        TreeCols TreeItem TreeRow TreeSeparator Triple VBox Where Window Wizard
        WizardPage
    };
    our %HTML = map {("html_$_" => "html:$_", uc $_ => "html:$_")} qw {
        a abbr acronym address applet area audio b base basefont bdo bgsound big
        blink blockquote body br button canvas caption center cite code col
        colgroup comment dd del dfn dir div dl dt em embed fieldset font form
        frame frameset h1 h2 h3 h4 h5 h6 head hr html i iframe ilayer img input
        ins isindex kbd label layer legend li link listing map marquee menu meta
        multicol nobr noembed noframes nolayer noscript object ol optgroup
        option p param plaintext pre q rb rbc rp rt rtc ruby s samp script
        select small source spacer span strike strong style sub sup table tbody
        td textarea tfoot th thead title tr tt u ul var video wbr xml xmp
    };
    our %EXPORT_TAGS = (
        util     => [qw/zip mapn apply trace/],
        base     => [qw/%ID ID display quit alert widget/],
        widgets  => [qw/filepicker ComboBox prompt/],
        tools    => [qw/gui interval timeout toggle function serve XUL/],
        pragma   => [qw/buffered now cached noevents delay doevents flush/],
        xul      => [@Xul],
        html     => [keys %HTML],
        const    => [qw/FLEX FIT FILL SCROLL MIDDLE BLUR/],
        image    => [qw/bitmap bitmap2src/],
        internal => [qw/tag object genid realid/],
    );
    our @EXPORT_OK = map @$_ => values %EXPORT_TAGS;
    our @EXPORT    = map @{ $EXPORT_TAGS{$_} } =>
                         qw/util base tools pragma xul html const image/;
    @EXPORT_TAGS{qw/default all/} = (\@EXPORT, \@EXPORT_OK);

    #for (qw/base tools pragma const widgets image util internal/) {
    #   printf "    :%-10s %s\n", $_, join ' '=> sort {
    #       lc $a cmp lc $b
    #   } @{ $EXPORT_TAGS{$_} }
    #}

    our %defaults = (
        window      => ['xmlns:html' => 'http://www.w3.org/1999/xhtml',
                         xmlns       => 'http://www.mozilla.org/keymaster/gatekeeper/there.is.only.xul',
                         onclose     => sub {quit(); 0},
                         resizeTo    => sub {gui("window.resizeTo($_[1],$_[2]);")},
                    ],
        textbox     => [ value       => sub :lvalue {tie my $ret, 'XUL::Gui::Scalar', shift, '_value'; $ret},
                        _value       => sub :lvalue {tie my $ret, 'XUL::Gui::Scalar', shift,  'value'; $ret}
                    ],
    );
    our $server = XUL::Gui::Server->new;
    our (%ID, %dialogs);
    my ($preprocess, $toJS, $toXML);

    {*ID = my $id = {};
        sub realid :lvalue {
            @_ ? $$id{$_[0]} : (my $id = $id)
        }
    }

    {my $id; sub genid () {'xul_' . ++$id}}

    sub isa_object {
        no warnings;
        blessed(@_ ? $_[0] : $_) eq 'XUL::Gui::Object'
    }

    my $weaken = sub {weaken $_[0] if ref $_[0] and not isweak $_[0]};

    my $weak_set = sub {
        my ($obj, $key) = @_;
        my $type   = reftype $obj or return warn "weak_set @_";
        my $strong = defined $key
            ? $type eq 'HASH'
                ? do {
                    if ($TIED_WIDGETS and my $tied = tied %$obj) {
                        $obj = $tied->hash
                    }
                    \$$obj{$key}
                }
                : $type eq 'ARRAY'
                    ? \$$obj[$key]
                    : return warn "weak_set @_"
            : $type eq 'SCALAR'
                ? $obj
                : return warn "weak_set @_";

        $$strong = $_[2] if @_ > 2;

        weaken $$strong if ref $$strong
                and not isweak $$strong;
        return
    };

    sub mapn (&$@);
    sub CLONE_SKIP {1}

    sub parse {
        my (@C, %A, %M);
        while (@_) {
            my $x = shift;
            if (isa_object $x) {push @C, $x; next}
            grep {not defined and $_ = '???'} $x, $_[0]
                  and croak "parse failure: [ $x => $_[0] ] @_[1..$#_],";
            $x =~ s/^-//;
            if ($x =~ /^_?on/ or ref $_[0] ne 'CODE') {
                $x eq 'style' and $A{$x} .= (shift).';'
                               or $A{$x}  =  shift}
            else                 {$M{$x}  =  shift}
        }
        C => \@C, A => \%A, M => \%M
    }


=head2 object oriented interface

if you prefer an OO interface, there are a few ways to get one:

    use XUL::Gui 'g->*';  # DYOI: draw your own interface

C< g > (which could be any empty package name) now has all of XUL::Gui's
functions as methods.  since draw your own interface does what you mean
(C< dyoidwym > ), each of the following graphic styles are equivalent:
C<< g->*, g->, ->g, install_into->g >>.

normally, installing methods into an existing package will cause a fatal error,
however you can add C<!> to force installation into an existing package

no functions are imported into your namespace by default, but you can request
any you do want as usual:

    use XUL::Gui qw( g->* :base :pragma );

to use the OO interface:

    g->display( g->Label('hello world') );
    # is the same as
    XUL::Gui::display( XUL::Gui::Label('hello world') );

    use g->id('someid') or g->ID('someid') to access the %ID hash

    the XUL tags are also available in lc and lcfirst:
        g->label       == XUI::Gui::Label
        g->colorpicker == XUL::Gui::ColorPicker
        g->colorPicker == XUL::Gui::ColorPicker

    the HTML tags are also available in lc, unless an XUL tag
    of the same name exists

if you prefer an object (which behaves exactly the same as the package 'g'):

    use XUL::Gui ();        # or anything you do want
    my $g = XUL::Gui->oo;   # $g now has XUL::Gui's functions as methods

if you like B<all> the OO lowercase names, but want functions, draw that:

    use XUL::Gui qw( ->main:: );  # ->:: will also export to main::
                                  #  '::' implies '!'
    display label 'hello, world';


=cut
    {my %loaded;
    sub oo {
        no strict 'refs';
        my $target  = $_[1] || 'XUL::Gui::OO';
        my $force   =     $target =~ s/!//g;
        my $methods = not $target =~ s/::$//;

        $target ||= 'main';
        $force  ||= !$methods;
        my $pkg   = "$target\::";

        if (%$pkg and not $force)
            {return $loaded{$pkg} || croak "package '$pkg' not empty"}
        mapn {
            my $sub = \&{$_[1]};
            *{$pkg.$_} = $methods ? sub {shift; goto &$sub} : $sub;
        } 2 => %{{
            (map {lc, $_} grep {not /_/} keys %HTML, @{$EXPORT_TAGS{const}}),
            $MOZILLA ? (map {lcfirst, $_} @Xul) : (),
            (map {$_, $_} grep {not /\W|^self$/} @EXPORT_OK),
            (map {lc, $_, lcfirst, $_} @{$EXPORT_TAGS{widgets}})
        }};
        *{$pkg.'id'} = $methods ? sub :lvalue {$XUL::Gui::ID{$_[1]}}
                                : \&ID;
        bless $loaded{$pkg} = {} => substr $pkg, 0, -2
    }}


=head1 FUNCTIONS

=head2 gui functions

=over 8

=item C< display LIST >

C< display > starts the http server, launches firefox, and waits for events.

it takes a list of gui objects, and several optional parameters:

    debug     (0) .. 6  adjust verbosity to stderr
    silent    (0) 1     disables all stderr status messages
    trusted    0 (1)    starts firefox with '-app' (requires firefox 3+)
    launch     0 (1)    launches firefox, if 0 connect to http://localhost:port
    skin       0 (1)    use the default 'chrome://global/skin' skin
    chrome     0 (1)    chrome mode disables all normal firefox gui elements,
                            setting this to 0 will turn those elements back on.
    xml       (0) 1     returns the object tree as xml, the gui is not launched
                 perl       includes deparsed perl event handlers
    delay  milliseconds delays each gui update cycle (for debugging)
    port                first port to start the server on, port++ after that
                            otherwise a random 5 digit port is used
    mozilla    0 (1)    setting this to 0 disables all mozilla specific features
                            including all XUL tags, the filepicker, and any
                            trusted mode features. (used to implement Web::Gui)

if the first object is a C< Window >, that window is created, otherwise a
default one is added. the remaining objects are then added to the window.

C< display > will not return until the the gui quits

see C< SYNOPSIS >, L<XUL::Gui::Manual>, L<XUL::Gui::Tutorial>, and the
C< examples > folder in this distribution for more details

=cut
    sub display {
        for (my $i = 0; $i < @_; $i++) {
            next if isa_object $_[$i];
            ref $_[$i] eq 'CODE'
                ? delay ((splice @_, $i--, 1), $$server{root})
                : $i++
        }
        if (@_ == 1 and not isa_object $_[0]) {
            @_ = PRE(shift)
        }
        my $args = { &parse };
        if ($$args{A}{xml}) {
            return join "\n" =>
                map $_->$toXML( 0, $$args{A}{xml} )
                =>  @{$$args{C}}
        }
        $server->start( $args )
    }


=item C< quit >

shuts down the server (causes a call to C< display > to return at the end of the
current event cycle)

C< quit > will shut down the server, but it can only shut down the client in
trusted mode.

=cut
    sub quit {
        gui('setTimeout("quit()", 5); 0');
        $$server{run} = 0;
    }


=item C< serve PATH MIMETYPE DATA >

add a virtual file to the server

    serve '/myfile.jpg', 'text/jpeg', $jpegdata;

the paths C< qw( / /client.js /event /ping /exit /perl ) > are reserved

=cut
    sub serve {$server->serve(@_)}


=item C< object TAGNAME LIST >

creates a gui proxy object, allows run time addition of custom tags

    object('Label', value=>'hello') is the same as Label( value=>'hello' )

the C< object > function is the constructor of all proxied gui objects, and all
these objects inherit from C< [object] > which provides the following methods.

=cut
    bless my $object = {
        WIDGET  => 0,
        NOPROXY => 1,
        ISA     => [],
        ID      => '[object]',
        M       => {
            attr       => sub :lvalue {$_[0]{A}{ $_[1] }},
            child      => sub :lvalue {$_[0]{C}[ $_[1] ]},
            can        => sub :lvalue {$_[0]{M}{ $_[1] }},
            attributes => sub      {%{ $_[0]{A} }},
            children   => sub      {@{ $_[0]{C} }},
            methods    => sub      {%{ $_[0]{M} }},
            has        => sub {
                my $self    = shift;
                my ($A, $M) = @$self{qw/A M/};
                my @found   = map {
                    my $required   = index($_, '!' ) == -1 ? 0        : s/!//g;
                    my ($key, $as) = index($_, '->') == -1 ? ($_, $_) : /(.+)->(.+)/;

                    exists $$A{ $key }
                         ? ($as => $$A{ $key }) :
                    exists $$M{ $key }
                         ? ($as => $$M{ $key }) :
                    $required ? do {
                        local $Carp::CarpLevel = 1;
                        croak "widget requires attribute/method '$key'";
                    } : ()
                } split /\s+/ => @_ > 1 ? "@_" : $_[0];
                wantarray ? @found
                    : @found == 2 ? $found[1] : @found / 2
            },
            id      => sub {$_[0]{ID}},
            parent  => sub {$_[0]{P }},
            widget  => sub {$_[0]{W }},
            super   => sub {$_[0]{ISA}[$_[1] or 0]},
            proto   => sub :lvalue {$_[0]{ISA}},
            extends => sub {
                my $self   = shift;
                my $target = (\%ID == realid) ? $self : \%ID;
                my $base   = $_[0]{W} or croak 'extends takes a widget';
                if ($TIED_WIDGETS) {
                    XUL::Gui::Hash->new($target, $base)
                } else {
                    $$target{$_} = $$base{$_} for grep {/[a-z]/} keys %$base;
                }
                unshift @{$$self{ISA}}, $base;
                @_
            },
        }
    } => 'XUL::Gui::Object';

    my $setup_object = sub {
        my $self = shift;
        for (@{$$self{C}}) {
            $_->$weak_set(P => $self)
        }
    };
    my $install_widget = sub {
        my ($self, $widget) = @_;

        my $w = \$$self{W};
        if ($$w) {
            if ($$w != $widget and not $$$w{W}) {
                $$$w{W} = $widget;
            }
        } else {
            $$w = $widget;
        }
    };

=item object introspection

objects and widgets inherit from a base class C< [object] > that provides the
following object inspection / extension methods. these methods operate on the
current data that XUL::Gui is holding in perl, none of them will ever call out
to the gui

    ->has('item!')      returns attributes or methods (see widget for details)
    ->attr('rows')      lvalue access to $$self{A} attributes
    ->child(2)          lvalue access to $$self{C} children
                          it only makes sense to use attr or child to set
                          values on objects before they are written to the gui
    ->can('update')     lvalue access to $$self{M} methods
    ->attributes        returns %{ $$self{A} }
    ->children          returns @{ $$self{C} }
    ->methods           returns %{ $$self{M} }
    ->widget            returns $$self{W}
    ->id                returns $$self{ID}
    ->parent            returns $$self{P}
    ->super             returns $$self{ISA}[0]
    ->super(2)          returns $$self{ISA}[2]
    ->extends(...)      sets inheritance (see widget for details)

these methods are always available for widgets, and if they end up getting in
the way of any javascript methods you want to call for gui objects:

    $object->extends(...)   # calls the perl introspection function
    $object->extends_(...)  # calls 'object.extends(...)' in the gui
    $x = $object->_extends; # fetches the 'object.extends' property
    $object->setAtribute('extends', ...); # and setting an attribute

or at runtime:

    local $XUL::Gui::EXTENDED_OBJECTS = 0; # which prevents object inheritance
                                           # in the current lexical scope
    $object->extends(...);
        # calls the real javascript 'extends' method assuming that it exists

=cut

    sub object {
        my $tag = lc (shift or '');
        if (my $defaults = $defaults{$tag}) {
            unshift @_, @$defaults
        }
        bless my $self = {
            ISA => [$object],
            $tag ? (
                TAG   => $tag,
                DIRTY => $tag,
            ) : (),
            &parse
        } => 'XUL::Gui::Object';

        if (my $id = $$self{A}{id}) {
            ($$self{ID} = $id)
                =~ /\W/ and do {
                    $$self{ID} = 'invalid'; # for DESTROY
                    croak "id '$id' contains non-word character"
                }
        } else {
            $$self{ID} = $$self{A}{id} = genid
        }
        if ($tag) {
            $self->$setup_object;
            $ID{$$self{ID}} = $self;
        }
        $self
    }


=item C< tag NAME >

returns a code ref that generates proxy objects, allows for user defined tag
functions

    *mylabel = tag 'label';
    \&mylabel == \&Label

=cut

    sub tag {
        my @args = @_;
        sub {
            object @args,
                (@_ == 1 and not isa_object $_[0])
                    ? 'TEXT' : (),
                @_
        }
    }
    {no strict 'refs';
        *$_ = tag $_        for @Xul;
        *$_ = tag $HTML{$_} for keys %HTML;
    }


=item C< ID OBJECTID >

returns the gui object with the id C< OBJECTID >.
it is exactly the same as C< $ID{OBJECTID} > and has C< (*) > glob context so
you don't need to quote the id.

    Label( id => 'myid' )
    ...
    $ID{myid}->value = 5;
    ID(myid)->value = 5;  # same

=cut
    sub ID (*):lvalue {$ID{$_[0]}}


=item C< widget {CODE} HASH >

widgets are containers used to group tags together into common patterns.
in addition to grouping, widgets can have methods, attached data, and can
inherit from other widgets

    *MyWidget = widget {
        Hbox(
            Label( $_->has('label->value') ),
            Button( label => 'OK', $_->has('oncommand') ),
            $_->children
        )
    }   method  => sub{ ... },
        method2 => sub{ ... },
        some_data =>  [ ... ];  # unless the value is a CODE ref, each widget
                                # instance gets a new deep copy of the data

    $ID{someobject}->appendChild(
        MyWidget( label=>'widget', oncommand=>\&event_handler )
    );

inside the widget's code block, several variables are defined:

    variable   contains the passed in
       $_{A} = { attributes }
       $_{C} = [ children   ]
       $_{M} = { methods    }
       $_    = a reference to the current widget (also as $_{W})
       @_    = the unchanged runtime argument list

widgets have the following predefined (and overridable) methods that are
synonyms / syntactic sugar for the widget variables:

    $_->has('label')        ~~ exists $_{A}{label} ? (label=>$_{A}{label}) : ()
    $_->has('label->value') ~~ exists $_{A}{label} ? (value=>$_{A}{label}) : ()

    $_->has('!label !command->oncommand style')

    ->has(...) splits its arguments on whitespace and will search $_{A}, then
    $_{M} for the attribute. if an ! is attached (anywhere) to an attribute,
    it is required, and the widget will croak without it.
    in scalar context, if only one key => value pair is found, ->has() will
    return the value.  otherwise, the number of found pairs is returned

    $_->attr( STRING )     $_{A}{STRING} # lvalue
    $_->attributes         %{ $_{A} }
    $_->child( NUMBER )    $_{C}[NUMBER] # lvalue
    $_->children           @{ $_{C} }
    $_->can( STRING )      $_{M}{STRING} # lvalue
    $_->methods            %{ $_{M} }

most everything that you would want to access is available as a method of the
widget (attributes, children, instance data, methods). since there may be
namespace collisions, here is the namespace construction order:

    %widget_methods = (
        passed in attributes,
        predefined widget methods,
        widget methods and instance data,
        passed in methods
    );

widgets can inherit from other widgets using the ->extends() method:

    *MySubWidget = widget {$_->extends( &MyWidget )}
        submethod => sub {...};

more detail in L<XUL::Gui::Manual>

=cut

    sub widget (&%) {
        my ($code, %methods, $sub) = @_;
        my $caller = caller;
        $sub = sub {
            my %data;
            my $id    = realid;
            my $inner = \%ID != $id;
            my $self  = $TIED_WIDGETS
                        ? XUL::Gui::Hash->new({parse @_})
                        : {parse @_};
            my $wid   = $inner ? genid : $$self{A}{id} || genid;

            my $_self = $TIED_WIDGETS ? tied(%$self)->hash : $self;

            @$_self{qw/ID WIDGET CALLER NOPROXY/} = ($wid, $sub, $caller, 1);

            for (keys %methods) {
                my ($k, $v) = ($_, $methods{$_});
                if (ref $v ne 'CODE') {
                    $data{$k} = ref $v ? dclone $v : $v;
                    $v = sub :lvalue {$data{$k}};
                }
                $$_self{M}{$k} ||= $v
            }

            hv_store %$_self, $_ => $data{$_} for keys %data;

            $$id{$wid} = bless $self => 'XUL::Gui::Object';

            weaken $$id{$wid} unless $THREADS; # crashes with threads

            $ID{$$_self{A}{id} or genid} = $self if $inner;

            no strict 'refs';
            my     $callid = "$caller\::ID";
            my     $setcid = %$callid && \%$callid == \%ID;
            local  %ID;
            local *$callid = \%ID if $setcid;
            use strict 'refs';

            local ($_, *_) = ($self) x 2;
            local  $_{W}   =  $self;

            $$_self{ISA} = [ $object ];
            my $objects  = [ &$code  ];

            my @named_objects;
            mapn {
                isa_object my $obj = $_[1]
                    or return warn "not an object: $_";

                if ($TIED_WIDGETS) {
                    if (my $tied = tied %{$_[1]}) {
                        $tied->unshift($self, $$_self{A});
                    } else {
                        XUL::Gui::Hash->new($_[1], $self, $$_self{A});
                    }
                }
                $$id{ my $gid = genid } = $obj;

                if (exists $$obj{WIDGET}) {
                    weaken $$id{$gid}
                }

                if ($FILL_GENID_OBJECTS
                or $$obj{A}{id} && $$obj{A}{id} !~ /^xul_\d+$/) {

                    isweak $obj or weaken $obj;
                    hv_store %$_self, $_ => $obj;

                    if (exists $$obj{W}) {
                        $$obj{EXTENDED_FROM} = $$obj{W}
                    }
                    $$obj{NAME} = $$obj{A}{id};

                    push @named_objects, $obj;
                }
                $$obj{W}  = $self;
                $$obj{ID} = $$obj{A}{id} = $gid;

            } 2 => %ID;

            unless ($TIED_WIDGETS) {
                my @keys_self = grep /[a-z]/ => keys %$_self;
                my @keys_A    = keys %{$$_self{A}};

                for my $obj (@named_objects) {
                    exists $$obj{$_} or hv_store %$obj, $_, $$_self{$_}    for @keys_self;
                    exists $$obj{$_} or hv_store %$obj, $_, $$_self{A}{$_} for @keys_A;
                }
            }
            @$objects[0 .. $#$objects]
        }
    }


=item C< alert STRING >

open an alert message box

=cut
    sub alert {
        gui( "alert('".&escape."')" );
        wantarray ? @_ : pop
    }


=item C< prompt STRING >

open an prompt message box

=cut
    sub prompt {
        gui( "prompt('".&escape."')" )
    }


=item C< filepicker MODE FILTER_PAIRS >

opens a filepicker dialog. modes are 'open', 'dir', or 'save'. returns the path
or undef on failure. if mode is 'open' and C< filepicker > is called in list
context, the picker can select multiple files.  the filepicker is only available
when the gui is running in 'trusted' mode.

    my @files = filepicker open =>
                    Text   => '*.txt; *.rtf',
                    Images => '*.jpg; *.gif; *.png';

=cut
    sub filepicker {
        $MOZILLA or croak "filepicker not available (XUL disabled)";
        my $type = shift || 'open';
        my $mode = {
            open => wantarray
                    ? [modeOpenMultiple => 'Select Files'   ]
                    : [modeOpen         => 'Select a File'  ],
            save =>   [modeSave         => 'Save as'        ],
            dir  =>   [modeGetFolder    => 'Select a Folder'],
        }->{$type};

        my $res = gui(qq ~
            (function () {
                xul_gui.deadman_pause();
                var nsIFilePicker = Components.interfaces.nsIFilePicker;
                var fp = Components.classes["\@mozilla.org/filepicker;1"]
                                   .createInstance(nsIFilePicker);
                fp.init(window, "$$mode[1]", nsIFilePicker.$$mode[0]);
             @{[mapn {qq{
                fp.appendFilter("$_[0]", "$_[1]");
             }} 2 => @_ ]}
                var res =  fp.show();
                xul_gui.deadman_resume();
                if (res == nsIFilePicker.returnCancel) return;~ .
            ($type eq 'open' && wantarray ? q {
                var files = fp.files;
                var paths = [];
                while (files.hasMoreElements()) {
                    var arg = files.getNext().QueryInterface(
                          Components.interfaces.nsILocalFile ).path;
                    paths.push(arg);
                }
                return paths.join("\n")
            } : q {return fp.file.path;}
        ) . '})()');
        defined $res
            ? wantarray
                ? split /\n/ => $res
                : $res
            : ()
    }


=item C< trace LIST >

carps C< LIST > with object details, and then returns C< LIST > unchanged

=cut
    sub trace {
        my $caller = caller;
        carp 'trace: ', join ', ' => map {
            (isa_object) ? lookup($_, $caller) : $_
        } @_;
        wantarray ? @_ : pop
    }

    {my %cache;
     my $last_caller;
    sub lookup {
        no strict 'refs';
        my $self  = shift;
        my $proto = $$self{WIDGET} || $$self{W}{WIDGET}
          or return $$self{ID} ||  $self;

        if   (@_) {$last_caller = $_[0]}
        else {@_ = $last_caller ||= caller}

        my $name = $cache{$proto};
        unless ($name) {
            our   %space;
            local *space = \%{"$_[0]\::"};
            local $@;
            keys  %space;
            while (my ($key, $glob) = each %space) {
                no warnings;
                if (eval {*$glob{CODE} == $proto}) {
                    $cache{$proto} = $name = $key;
                    last
                }
            }
        }
        $name and return
            $name . ($$self{WIDGET} ? '{'
                               : '{'.($$self{W}{A}{id} or $$self{W}{ID}).'}->{')
                  . ($$self{NAME} or $$self{ID}).'}';

        $$self{ID} or $self
    }}


=item C< function JAVASCRIPT >

create a javascript event handler, useful for mouse events that need to be very
fast, such as onmousemove or onmouseover

    Button( label=>'click me', oncommand=> function q{
        this.label = 'ouch';
        alert('hello from javascript');
        if (some_condition) {
            perl("print 'hello from perl'");
        }
    })

    $ID{myid} in perl is ID.myid in javascript

to access widget siblings by id, wrap the id with C< W{...} >

=cut
    sub function ($) {
        my $js = shift;
        bless [sub {
            my $self = shift;
            my $func = 'ID.' . genid;
            delay( sub {
                $js =~ s[\$?W{\s*(\w+)\s*}] [ID.$$self{W}{$1}{ID}]g;
                gui(
                    qq{SET;$func = function (event) {
                        try {return (function(){ $js }).call( ID.$$self{ID} )}
                        catch (e) {alert( e.name + "\\n" + e.message )}
                }})
            });
            "$func(event)"
        }] => 'XUL::Gui::Function'
    }


=item C< interval {CODE} TIME LIST >

perl interface to javascript's C< setInterval() >. interval returns a code ref
which when called will cancel the interval. C< TIME > is in milliseconds.
C< @_ > will be set to C< LIST > when the code block is executed.

=cut
    sub interval (&$@) {
        my ($code, $time) = splice @_, 0, 2;
        my $list = \@_;
        my $id = genid;
        realid($id)= sub {$code->(@$list)};
                   # = sub {local *_ = $list; goto &$code};
        gui( qq{SET;ID.$id = setInterval( "pevt('XUL::Gui::realid(q|$id|)->()')", $time)} );
        sub {gui(qq{SET;clearInterval(ID.$id)})}
    }


=item C< timeout {CODE} TIME LIST >

perl interface to javascript's C< setTimeout() >. timeout returns a code ref
which when called will cancel the timeout. C< TIME > is in milliseconds. C< @_ >
will be set to C< LIST > when the code block is executed.

=cut
    sub timeout (&$@) {
        my ($code, $time) = splice @_, 0, 2;
        my $list = \@_;
        my $id = genid;
        realid($id) = sub {$code->(@$list)};
        gui( qq{SET;ID.$id = setTimeout( "pevt('XUL::Gui::realid(q|$id|)->()')", $time)} );
        sub {gui(qq{SET;cancelTimeout(ID.$id)})}
    }

    sub escape {
        my $str = $_[0];

        return $str if $str !~ /[\\\n\r']|[^[:ascii:]]/;

        $str =~ s/\\/\\\\/g;
        $str =~ s/\n/\\n/g;
        $str =~ s/\r/\\r/g;
        $str =~ s/'/\\'/g;
        $str =~ /[^[:ascii:]]/
            ? encode ascii => $str
                => sub {sprintf '\u%04X', $_[0]}
            : $str
    }


=item C< XUL STRING >

converts an XML XUL string to C< XUL::Gui > objects.  experimental.

this function is provided to facilitate drag and drop of XML based XUL from
tutorials for testing. the perl functional syntax for tags should be used in all
other cases

=cut
    {my %xul; @xul{map lc, @Xul} = @Xul;
    sub XUL {
        $MOZILLA or croak "XUL disabled";
        local $@;
        for ("@_") {
            s {<(\w+)(.+?)}       "XUL::Gui::$xul{lc $1}($2"g;
            s {/>}                '),'g;
            s {</\w+>}            '),'g;
            s {>}                 ''g;
            s {(\w+)\s*=\s*(\S+)} "'$1'=>$2"g;
            s <([^\\](}|"|'))\s+> "$1,"g;
            return eval 'package '.caller().";$_"
                or carp "content skipped due to parse failure: $@\n\n$_"
        }
    }}


=item C< gui JAVASCRIPT >

executes C< JAVASCRIPT > in the gui, returns the result

=back

=cut
    {my ($buffered, @buffer, @setbuf, $cached, %cache, $now);
        sub gui :lvalue {
            my $msg  = "@_\n";
            my $type = '';
            if (substr($msg, 1, 2) eq 'ET') {
                my $first = substr $msg, 0, 1;
                if ($first eq 'S' or $first eq 'G') {
                    if ((my $check = substr $msg, 3, 1) eq '(') {
                        $type = $first . 'ET';
                    }
                    elsif ($check eq ';') {
                        $type = $first . 'ET';
                        $msg = substr $msg, 4;
                    }
                }
            }
            unless ($now) {
               push @buffer, $msg and return if $buffered;
               push @setbuf, $msg and return if $AUTOBUFFER
                                             and $type eq 'SET'
                                             and not $cached;
               return $cache{$msg} if exists $cache{$msg};
            }
            if (@setbuf) {
                $msg = join '' => @setbuf, $msg;
                @setbuf = ();
            }
            defined wantarray or $msg .= ';true'
                unless $cached;

            $server->write('text/plain', $msg);
            my $res = $server->read_until('/res');

            if (defined wantarray or $cached) {
                ($res = $$res{CONTENT}) =~ /^(...) (.*)/s
                     or croak "invalid response: $res";

                $res = $1 eq 'OBJ'
                          ? ($ID{$2} || object undef, id=>$2)
                          : $1 eq 'UND'
                               ? undef
                               : $2;
                if ($cached) {
                    if ($type eq 'SET') {
                        $type =  'GET';
                        $msg  =~ s/.[^,]+(?=\).*?$)//;
                        substr $msg, 0, 3, 'GET';
                    }
                    $cache{$msg} = $res if $type eq 'GET'
                }
            }
            $res
        }

=head2 data binding

=over 8

passing a reference to a scalar or coderef as a value in an object constructor
will create a data binding between the perl variable and its corresponding
value in the gui.

    use XUL::Gui;

    my $title = 'initial title';

    display Window title => \$title,
        Button(
            label => 'update title',
            oncommand => sub {
                $title = 'title updated via data binding';
            }
        );

a property on a previously declared object can also be bound by taking a
reference to it:

    display
        Label( id => 'lbl', value => 'initial value'),
        Button(
            label => 'update',
            oncommand => sub {
                my $label = \ID(lbl)->value;

                $$label = 'new value';
            }
        )

this is just an application of the normal bidirectional behavior of gui
accessors:

    for (ID(lbl)->value) {
        print "$_\n";  # gets the current value from the gui

        $_ = 'new';    # sets the value in the gui

        print "$_\n";  # gets the value from the gui again
    }

=back

=head2 pragmatic blocks

the following functions all apply pragmas to their CODE blocks. in some cases,
they also take a list. this list will be C< @_ > when the CODE block executes.
this is useful for sending in values from the gui, if you don't want to use a
C< now {block} >

=head3 autobuffering

this module will automatically buffer certain actions within event handlers.
autobuffering will queue setting of values in the gui until there is a get, the
event handler ends, or C< doevents > is called.  this eliminates the need for
many common applications of the C< buffered > pragma.

=over 8

=item C< flush >

flush the autobuffer

=cut
        sub flush {
            if (@setbuf) {
                $server->write('text/plain', join '' => @setbuf);
                @setbuf = ();
                $server->read_until('/res');
            }
        }

=item C< buffered {CODE} LIST >

delays sending all messages to the gui. partially deprecated (see autobuffering)

    buffered {
        $ID{$_}->value = '' for qw/a bunch of labels/
    }; # all labels are cleared at once

=cut
        sub buffered (&@) {
            $buffered++;
            &{+shift};
            unless (--$buffered) {
                gui "SET;@buffer";
                @buffer = ();
            }
            return
        }


=item C< cached {CODE} >

turns on caching of gets from the gui

=cut
        sub cached (&) {
            $cached++;
            my $ret = shift->();
            %cache  = () unless --$cached;
            $ret
        }


=item C< now {CODE} >

execute immediately, from inside a buffered or cached block, without causing a
buffer flush or cache reset. buffered and cached will not work inside a now
block.

=cut
        sub now (&) {
            my ($want, @ret) = wantarray;
            $now++;
            $want ? @ret     = shift->()
                  : $ret[0]  = shift->();
            $now--;
            $want ? @ret : $ret[0]
        }
    }


=item C< delay {CODE} LIST >

delays executing its CODE until the next gui refresh

useful for triggering widget initialization code that needs to run after the gui
objects are rendered.  the first element of C< LIST > will be in C< $_ > when
the code block is executed

=cut
    sub delay (&@) {
        my $code = shift;
        my $args = \@_;
        push @{$$server{queue}}, sub {@$args and local *_ = \$$args[0]; $code->(@$args)};
        return
    }


=item C< noevents {CODE} LIST >

disable event handling

=cut
    sub noevents (&@) {
        gui 'xul_gui.cacheEvents(false);';
        my @ret = &{+shift};
        gui 'xul_gui.cacheEvents(true);';
        @ret
    }


=item C< doevents >

force a gui update cycle before an event handler finishes

=cut
    sub doevents () {
        $server->{dispatch}{'/ping'}();
        $server->read_until('/ping');
        return
    }


=back

=head2 utility functions

=over 8

=item C< mapn {CODE} NUMBER LIST >

map over n elements at a time in C< @_ > with C< $_ == $_[0] >

    print mapn {$_ % 2 ? "@_" : " [@_] "} 3 => 1..20;
    > 1 2 3 [4 5 6] 7 8 9 [10 11 12] 13 14 15 [16 17 18] 19 20

=cut
    sub mapn (&$@) {
        my ($sub, $n, @ret) = splice @_, 0, 2;
        croak '$_[1] must be >= 1' unless $n >= 1;

        return map $sub->($_) => @_ if $n == 1;

        my $want = defined wantarray;
        while (@_) {
            local *_ = \$_[0];
            if ($want) {push @ret =>
                  $sub->(splice @_, 0, $n)}
            else {$sub->(splice @_, 0, $n)}
        }
        @ret
    }


=item C< zip LIST of ARRAYREF >

    %hash = zip [qw/a b c/], [1..3];

=cut
    sub zip {
        map {my $i = $_;
            map $$_[$i] => @_
        } 0 .. max map $#$_ => @_
    }


=item C< apply {CODE} LIST >

apply a function to a copy of C< LIST > and return the copy

    print join ", " => apply {s/$/ one/} "this", "and that";
    > this one, and that one

=cut
    sub apply (&@) {
        my ($sub, @ret) = @_;
        $sub->() for @ret;
        wantarray ? @ret : pop @ret
    }


=item C< toggle TARGET OPT1 OPT2 >

alternate a variable between two states

    toggle $state;          # opts default to 0, 1
    toggle $state => 'red', 'blue';

=cut
    sub toggle {
        no warnings;
        my @opt = (splice(@_, 1), 0, 1);
        $_[0] = $opt[ $_[0] eq $opt[0] or $_[0] ne $opt[1] ]
    }


=item C< bitmap WIDTH HEIGHT OCTETS >

returns a binary .bmp bitmap image. C< OCTETS > is a list of C< BGR > values

    bitmap 2, 2, qw(255 0 0 255 0 0 255 0 0 255 0 0); # 2px blue square

for efficiency, rather than a list of C< OCTETS >, you can send in a single
array reference. each element of the array reference can either be an array
reference of octets, or a packed string C<< pack "C*" => OCTETS >>

=cut
    sub bitmap {
        my ($width, $height) = splice @_, 0, 2;

        my @pad = map {(0) x ($_ and 4 - $_)} ($width*3) % 4;

        my $size = $height * ($width * 3 + @pad);

        pack 'n V n n (N)2 (V)2 n n N V (N)4 (a*)*' =>
            0x42_4D,         # "BM"         # file format thanks to Wikipedia
            (54 + $size),    # file size
            0x00_00,         # not used
            0x00_00,         # not used
            0x36_00_00_00,   # offset of bitmap data
            0x28_00_00_00,   # remaining bytes in header
            $width,
            $height,
            0x01_00,         # color planes
            0x18_00,         # bits/pixel (24)
            0x00_00_00_00,   # no compression
            $size,           # size of raw BMP data (after header)
            0x13_0B_00_00,   # horizontal res
            0x13_0B_00_00,   # vertical res
            0x00_00_00_00,   # not used
            0x00_00_00_00,   # not used
            reverse
              @_ > 1
                ? map {pack 'C*' => splice(@_, 0, $width*3), @pad} 1 .. $height
                : map {ref $_
                     ? pack 'C*'    => @$_, @pad
                     : pack 'a* C*' =>  $_, @pad
                } @{$_[0]}
    }


=item C< bitmap2src WIDTH HEIGHT OCTETS >

returns a packaged bitmap image that can be directly assigned to an image tag's
src attribute. arguments are the same as C< bitmap() >

    $ID{myimage}->src = bitmap2src 320, 180, @image_data;

=back

=cut
    sub bitmap2src {'data:image/bitmap;base64,' . encode_base64 &bitmap}


=head1 METHODS

    # access attributes and properties

        $object->value = 5;                   # sets the value in the gui
        print $object->value;                 # gets the value from the gui

    # the attribute is set if it exists, otherwise the property is set

        $object->_value = 7;                  # sets the property directly

    # method calls

        $object->focus;                       # void context or
        $object->appendChild( H2('title') );  # any arguments are always methods
        print $object->someAccessorMethod_;   # append _ to force interpretation
                                              # as a JS method call

in addition to mirroring all of an object's existing javascript methods /
attributes / and properties to perl (with identical spelling / capitalization),
several default methods have been added to all objects

=over 8

=cut

package
    XUL::Gui::Object;
    my $can; $can = sub {
        my ($self, $method) = @_;

        $server->status('    ' . XUL::Gui::lookup($self) . "->can( $method ) ?")
            if ($DEBUG > 4
             or $DEBUG > 3 and $method !~ /^~/)
            and $self != $object;

        $$self{M}{$method}
            or do {
                return if $self == $object;
                if ($$self{WIDGET}) {
                    if (exists $$self{$method}) {
                        return ref $$self{$method} eq 'CODE'
                                 ? $$self{$method}
                                 : sub:lvalue {$$self{$method}}
                    }
                    if (exists $$self{A}{$method}) {
                        return sub:lvalue {$$self{A}{$method}}
                    }
                } else {
                    return unless $EXTENDED_OBJECTS
                }
                for (@{$$self{ISA}})
                    {return $_->$can($method) || next}
            }
    };
    sub can   :lvalue;
    sub attr  :lvalue;
    sub child :lvalue;

    use overload fallback => 1, '@{}' => sub {
        tie my @ret => 'XUL::Gui::Array', shift;
        \@ret
    };

    {
        my $debug_perl_method_call = sub {
            my ($self, $name) = splice @_, 0, 3;
            my $caller = caller 1;
            $server->status('perl:  '. XUL::Gui::lookup($self, $caller) . "->$name(" .
                (join ', ' => map {(XUL::Gui::isa_object)
                    ? XUL::Gui::lookup($_, $caller) : "'$_'"} @_). ")")
        };

        my $debug_js_method_call = sub {
            my ($self, $name) = splice @_, 0, 2;
            $server->status( "gui:   ID.$$self{ID}.$name(" .
                (join ', ' => map {(XUL::Gui::isa_object)
                    ? "ID.$$_{ID}" : "'$_'"} @_). ")" )
        };

        sub AUTOLOAD :lvalue {
             my $self  = $_[0];
             my $name = substr our $AUTOLOAD, 1 + rindex $AUTOLOAD, ':'
                or Carp::croak "invalid autoload: $AUTOLOAD";

            if (my $method = $self->$can($name)) {
                $debug_perl_method_call->($self, $name, @_) if $DEBUG;
                goto &$method
            }
            if ($$self{NOPROXY} or not shift->{ID}) {
                Carp::croak "no method '$name' on ". XUL::Gui::lookup($self, scalar caller)
            }
            my $void = not defined wantarray;

            if (substr($name, -1) eq '_' && chop $name or @_ or $void) {

                $debug_js_method_call->($self, $name, @_) if $DEBUG > 1;

                {($$self{uc $name} or next)
                    -> (local $_ = $self)
                    => return}
                my @pre;
                my $arg = join ',' => map {not defined and 'null' or
                    XUL::Gui::isa_object and do {
                        push @pre, $_->$toJS(undef, $self) if $$_{DIRTY};
                        "ID.$$_{ID}"
                    } or "'" . XUL::Gui::escape($_) . "'"
                } @_;
                local $" = '';
                return XUL::Gui::gui 'SET;' x $void, "@pre; ID.$$self{ID}.$name($arg);"
            }
            $server->status("proxy: ID.$$self{ID}.$name") if $DEBUG > 2;

            tie my $ret, 'XUL::Gui::Scalar', $self, $name; # proxy
            $ret
        }
    }

    {my @queue;
     my $rid = XUL::Gui::realid;
    sub DESTROY {
        return unless @_
                  and Scalar::Util::reftype $_[0] eq 'HASH'
                  and $_[0]{ID};
        delete $rid->{$_[0]{ID}};
        push @queue, "delete ID.$_[0]{ID};";
        if (@queue == 1) {
            XUL::Gui::delay {
                local $" = '';
                XUL::Gui::gui "SET;@queue";
                @queue = ();
                for (keys %$rid) {
                    unless (defined $$rid{$_}) {
                        delete $$rid{$_}
                    }
                }
            }
        }
        untie %{$_[0]} if tied %{$_[0]};
    }}
    sub CLONE_SKIP {1}

    {my $deparser;
    $toXML = sub {
        my $self = shift;
        my $tab  = shift || 0;
        my (@xml, @perl);
        my $text = '';

        my $deparse = (shift||'') eq 'perl' ? do {
           $deparser ||= do {
                require B::Deparse;
                my $d = B::Deparse->new('-sC');
                $d->ambient_pragmas(qw/strict all warnings all/);
                $d
            }} : 0;

        $self->$preprocess unless $deparse;
        for ($$self{CODE}) {
            if (defined) {
                my $tabs = "\t" x $tab;
                s/^/$tabs/mg;
                return substr $_, $tab;
            }
        }
        my $tag = $$self{TAG};

        $MOZILLA or $tag =~ s/^html://;

        push @xml, "<$tag ";
        for (keys %{$$self{A}}) {
            if ($deparse and ref (my $code = $$self{A}{$_}) eq 'CODE') {
                push @xml, qq{$_="alert('handled by perl')" };
                push @perl, bless {CODE => "<!-- \n$_ => sub "
                                   . $deparse->coderef2text($code)."\n-->\n"};
                next
            }
            my $val = XUL::Gui::escape $$self{A}{$_};
            if ($_ eq 'TEXT') {
                $val =~ s/\\n/\n/g;
                $text = $val;
                next
            }
            push @xml, qq{$_="$val" };
        }
        if (@{$$self{C}} or $text or @perl) {
            push @xml, ">$text\n";
            push @xml, "\t" x ($tab+1), $_->$toXML($tab+1, $deparse ? 'perl' : ())
                for @perl, @{$$self{C}};
            push @xml, "\t" x $tab, "</$tag>\n";
        } else {
            if ($MOZILLA) {
                push @xml, "/>\n"
            } else {
                push @xml, "></$tag>\n"
            }
        }
        join '' => @xml
    }}

    {my $id = XUL::Gui::realid;
    $preprocess = sub {
        my $self = $_[0];
        die 'processed again' unless $$self{DIRTY};
        $$self{DIRTY} = 0;
        my $attr = $$self{A};
        for my $key (keys %$attr) {
            my $val = \$$attr{$key};
            if (ref $$val eq 'XUL::Gui::Function') {
                    $$val = $$$val[0]( $self )
            }
            my $ref = ref $$val;
            if ($ref eq 'SCALAR' or $ref eq 'REF') {
                my $bound = $$val;
                $$val = $$bound;
                tie $$bound => 'XUL::Gui::Scalar', $self, $key;
            }
            if (substr($key, 0, 1) eq '_') {
                substr $key, 0, 1, '';
            }
            next unless index($key, 'on') == 0 and ref $$val eq 'CODE';
            $$self{uc $key} = $$val;
            $$val = "EVT(event,'$$self{ID}');";
        }
    }}

    $toJS = sub {
        my ($root, $final, $parent) = @_;
        my @queue = $root;
        my (@pre, @post);
        my $realid = XUL::Gui::realid;

        if ($parent) {
            $root->$weak_set( P => $parent );
            push @{$$parent{C}}, $root;

            if (my $widget = $$parent{W}) {
                $root->$install_widget($widget)
            }
        }
        while (my $node = shift @queue) {
            $node->$preprocess;
            if (my $code = $$node{CODE}) {
                push @pre, $code;
                next
            }
            my $id = "ID.$$node{ID}";
            my ($attribute, $children, $tag) = @$node{qw/A C TAG/};

            my $widget = $$node{W};
            for my $child (@$children) {
                push @queue, $child;
                push @post, qq{$id.appendChild(ID.$$child{ID});} if $$child{TAG};
                $child->$weak_set( P => $node );
                $child->$install_widget($widget) if $widget;
            }
            $weaken->($$realid{$$node{ID}}) unless $THREADS;

            push @pre, qq{$id=document.createElement} .
                ($MOZILLA
                    ? index ($tag, ':') == -1
                        ? qq{('$tag');}
                        : qq{NS('http://www.w3.org/1999/xhtml','$tag');}
                    : $tag =~ /^html:(.+)/
                        ? qq{('$1');}
                        : Carp::croak "$tag is not an HTML tag");

            keys %$attribute;
            while (my ($key, $val) = each %$attribute) {
                my $clean = XUL::Gui::escape $val;
                if ($key eq 'TEXT') {
                    push @pre,  qq{$id.appendChild(document.createTextNode('$clean'));}
                } elsif (substr($key, 0, 1) eq '_') {
                    if (substr($key, 1, 2) eq 'on') {
                        push @post, qq{$id.} . (substr $key, 1) . qq{=function(event){if(!event){event=window.event}$val};}
                    } else {
                        push @post, qq{$id\['}. (substr $key, 1). qq{']='$clean';}
                    }
                } else {
                    push @pre,  qq{$id.setAttribute('\L$key\E','$clean');}
                }
            }
        }
        push @post, "$final.appendChild(ID.$$root{ID});" if $final;

        local $" = $DEBUG ? "\n" : '';
        "@pre@post"
    };


=item C<< ->removeChildren( LIST ) >>

removes the children in C< LIST >, or all children if none are given

=cut

    my $remove_children = sub {
        my $self = shift;
        if (@_) {
            my %remove = map {$_ => 1} @_;
            @{$$self{C}} = grep {not $remove{$_}} @{$$self{C}};
        } else {
            @{$$self{C}} = ()
        }
    };


    sub removeChildren {
        my $self = shift;
        @_  ? XUL::Gui::buffered {$self->removeChild_($_) for @_} @_
            : XUL::Gui::gui "SET;ID.$$self{ID}.removeChildren();";

        $self->$remove_children(@_);
        $self
    }


=item C<< ->removeItems( LIST ) >>

removes the items in C< LIST >, or all items if none are given

=cut
    sub removeItems {
        my $self = shift;
        @_  ? XUL::Gui::buffered {$self->removeItem_($_) for @_} @_
            : XUL::Gui::gui "SET;ID.$$self{ID}.removeItems();";

        $self->$remove_children(@_ ? @_ : grep {$$_{TAG} =~ /item/i} @{ $$self{C} });
        $self
    }


=item C<< ->appendChildren( LIST ) >>

appends the children in C< LIST >

=cut

    sub appendChild {
        my ($self, $child) = @_;
        push @{ $$self{C} }, $child;
        $self->appendChild_( $child );
    }

    sub removeChild {
        my ($self, $child) = @_;
        $self->removeChild_($child);
        my $children = $$self{C};
        for (0 .. $#$children) {
            if ($$children[$_] == $child) {
                return splice @$children, $_, 1
            }
        }
    }

    sub appendChildren {
        my $self = shift;
        XUL::Gui::buffered {$self->appendChild($_) for @_} @_;
        $self
    }


=item C<< ->prependChild( CHILD, [INDEX] ) >>

inserts C< CHILD > at C< INDEX > (defaults to 0) in the parent's child list

=cut
    sub prependChild {
        my ($self, $child, $count, $first) = @_;
        if ($$self{TAG} eq 'tabs') {
            $first = $self->getItemAtIndex( $count || 0 )
        } else {
            $first = $self->firstChild;
            while ($count-- > 0) {
                last unless $first;
                $first = $first->nextSibling;
            }
        }
        $first ? $self->insertBefore( $child, $first )
               : $self->appendChild ( $child );
        push @{$$self{C}}, $child;
        $self
    }

=item C<< ->replaceChildren( LIST ) >>

removes all children, then appends C< LIST>

=cut
    sub replaceChildren {
        my ($self, @children) = @_;
        XUL::Gui::buffered {
        XUL::Gui::noevents {
            $self->removeChildren
                 ->appendChildren( @children )
        }};
        $self
    }

=item C<< ->appendItems( LIST ) >>

append a list of items

=cut
    sub appendItems {
        my ($self, @items) = @_;
        XUL::Gui::buffered {
            (XUL::Gui::isa_object)
                ? $self->appendChild($_)
                : $self->appendItem( ref eq 'ARRAY' ? @$_ : $_ )
            for @items
        };
        $self
    }


=item C<< ->replaceItems( LIST ) >>

removes all items, then appends C< LIST>

=back

=cut
    sub replaceItems {
        my ($self, @items) = @_;
        XUL::Gui::buffered {
        XUL::Gui::noevents {
            $self->removeItems
                 ->appendItems( @items )
        }};
        $self
    }


package
    XUL::Gui::Scalar;
    use Carp;

    sub TIESCALAR  {bless [ @_[1..$#_] ] => $_[0]}
    sub DESTROY    { }
    sub CLONE_SKIP {1}

    sub FETCH {
        my ($self, $AL) = @{+shift};
        return $$self{uc $AL} if $AL =~ /^on/;
        XUL::Gui::gui $AL =~ /^_(.+)/
            ? "GET;ID.$$self{ID}\['$1'];"
            : "GET(ID.$$self{ID}, '$AL');"
    }

    sub STORE {
        my ($self, $AL, $new) = (@{+shift}, @_);
        if ($AL =~ /^on/) {
            if (ref $new eq 'XUL::Gui::Function') {
                $new = $$new[0]($self);
            } else {
                not defined $new or ref $new eq 'CODE'
                    or croak "assignment to event handler must be CODE ref, 'function q{...}', or undef";
                $new = $new ? do {$$self{uc $AL} = $new; "EVT(event, '$$self{ID}')"} : '';
            }
        }
        $new = defined $new ? "'" . XUL::Gui::escape($new) . "'" : 'null';

        XUL::Gui::gui $AL =~ /^_(.+)/
            ? "SET;ID.$$self{ID}\['$1'] = $new;"
            : "SET(ID.$$self{ID}, '$AL', $new);"
    }


{my ($fetch, $store) = (\&FETCH, \&STORE);
package
    XUL::Gui::Array;
    sub TIEARRAY  {bless \pop}
    sub FETCH     {@_ =  [${$_[0]}, '_'.$_[1]];         goto &$fetch}
    sub FETCHSIZE {@_ =  [${$_[0]}, '_length'];         goto &$fetch}
    sub STORE     {@_ = ([${$_[0]}, '_'.$_[1]], $_[2]); goto &$store}
    sub STORESIZE {@_ = ([${$_[0]}, '_length'], $_[1]); goto &$store}
    BEGIN {*EXTEND = \&STORESIZE}
    sub EXISTS    {${$_[0] }->hasOwnProperty($_[1])}
    sub POP       {${$_[0] }->pop        }
    sub SHIFT     {${$_[0] }->shift      }
    sub CLEAR     {${$_[0] }->splice (0 )}
    sub PUSH      {${shift;}->push   (@_)}
    sub UNSHIFT   {${shift;}->unshift(@_)}
    sub SPLICE  {@{${shift;}->splice (@_)}}
    sub DELETE    {XUL::Gui::gui "delete ID.$${$_[0]}{ID}\[$_[1]]"}
}

package
    XUL::Gui::Server;
    use Carp;
    use IO::Socket;
    use File::Find;
    use Scalar::Util qw/openhandle/;
    our ($req, $active, @cleanup);

    sub new {bless {}}

    sub status {print STDERR "XUL::Gui> @_\n" unless shift->{silent}; 1}

    sub start {
        my $self        = shift;
        $$self{args}    = shift;
        $$self{content} = $$self{args}{C};
        $$self{content} = [XUL::Gui::META()] unless @{$$self{content}};
        $weaken->($$self{args}{C});
        $$self{caller}  = caller 1;
        $active         = $self;
        $$self{$_}      = $$self{args}{A}{$_}
            for qw(debug silent trusted launch skin chrome port delay mozilla default_browser serve_files);

        defined $$self{$_} or $$self{$_} = 1
            for qw(launch chrome skin);

        $self->status("version $VERSION") if
            local $DEBUG = $$self{debug} || $DEBUG;

        push @cleanup, $self;

        local $MOZILLA = defined $$self{mozilla} ? $$self{mozilla} : $MOZILLA
            or $DEBUG && $self->status('XUL enhancements disabled. using HTML only mode');

        $$self{silent}++ if $TESTING;

        local $| = 1 if $DEBUG;

        require Time::HiRes if $$self{delay};

        $$self{port} ||= int (10000 + rand 45000);
        $$self{port}++ until
            $$self{server} = IO::Socket::INET->new(
                Proto     => 'tcp',
                PeerAddr  => 'localhost',
                LocalAddr => "localhost:$$self{port}",
                Listen    => 1,
            );

        $self->build_dispatch;
        $$self{run} = 1;
        $self->status("display server started on http://localhost:$$self{port}");

        $self->launch if $$self{launch} or $$self{trusted};
        $$self{client} = $$self{server}->accept;
        $$self{client}->autoflush(1);

        $self->status('opening window');

        local $@;
        my $error = eval {$self->read_until('main loop:'); 1}
                  ? 0 : $@ || 'something bad happened'; #?

        if ($$self{firefox}) {
            kill HUP => -$$self{ffpid};
            kill HUP =>  $$self{ffpid};
            close $$self{firefox};
        }

        {($$self{dir} or last)->unlink_on_destroy(1)}

        die $error if $error
              and ref $error ne 'XUL::Gui server stopped';

        $self->stop('display stopped');
        $self->cleanup;
    }

    sub abort {die bless [] => 'XUL::Gui server stopped'}

    sub read_until {
        my ($self, $stop) = @_;
        my $run      = \$$self{run};
        my $dispatch =  $$self{dispatch};

        while (local $req = $self->read) {
            my $url = $$req{URL};

            $self->status(($stop =~ /:/ ? '' : 'read until ')."$stop got $url")
                if $DEBUG > 4 and $url ne '/ping';

            return $req if $url eq $stop;

            if (my $handler = $$dispatch{$url}) {
                $handler->();
            } elsif (my $prefix = $$self{serve_files}) {
                $url = ($prefix =~ m{ [\\\/] $ }x ? $prefix : '.') . $url;

                if (open my $file, '<', $url) {
                    $self->write('text/plain', do {local $/; <$file>})
                } else {
                    $self->status("file: $url not found");
                    $self->write('text/plain', '')
                }
            }
            $$run or abort;
        }
    }

    sub assert {
        return if openhandle pop;
        my $name = ((caller 2)[3] =~ /([^:]+)$/ ? "$1 " : '') . shift;
        croak "XUL::Gui> $name error: client not connected,"
    }

    sub read {
        my ($self, $client) = ($_[0], $_[0]{client});
        my ($length, %req);
        local $/ = "\015\012";
        local *_;
        assert read=> $client;
        my $header = <$client>;
        $header and ($req{URL}) = $header =~ /^\s*\w+\s*(\S+)\s*HTTP/
            or do {
                $self->status(
                    $header
                        ? "broken message received: $header"
                        : 'firefox seems to be closed'
                );
                abort
            };

        {chomp ($_ = <$client>);
            $length ||= /^\s*content-length\D+(\d+)/i ? $1 : 0;
            $_ and redo}

        read $client => $req{CONTENT}, $length;

        $self->status( "read: $req{URL} $req{CONTENT}" )
            if $DEBUG > 3 and $req{URL} ne '/ping';
        if ($$self{delay} and $req{URL} ne '/ping') {
            Time::HiRes::usleep(1000*$$self{delay})
        }
        \%req
    }

    sub write {
        my ($self, $type, $msg) = @_;
        assert write => my $client = $$self{client};

        XUL::Gui::flush if $msg eq 'NOOP';
        if ($DEBUG > 3) {
            (my $msg = "$type $msg") =~ s/[\x80-\xFF]+/ ... /g;
            $self->status(
                $DEBUG > 4
                    ? "write $msg"
                    : (substr "write $msg", 0, 115)
                    . (' ...' x (length $msg > 115))
            )
        }
        print $client join "\015\012" =>
            'HTTP/1.1 200 OK',
            'Expires: -1',
            'Keep-Alive: 300',
            'Content-type: '   . $type,
            'Content-length: ' . length $msg,
            '',
            $msg
    }

    sub stop {
        my $self = shift;
        local $SIG{HUP} = 'IGNORE';
        kill HUP => -$$;
        $self->status(@_);
    }

    sub serve {
        my ($self, $path, $type, $data) = @_;
        $path =~ m[^/(?:client.js|event|ping|exit|perl)?$]
            and croak "reserved path: $path";
        $self->status("serve $path $type") if $DEBUG;
        $$self{dispatch}{$path} = sub {
            $self->write($type, $data);
        };
        $path
    }

    sub build_dispatch {
        my $self = shift;
        my $root;
        $$self{dispatch} = {
            exists $$self{dispatch} ? %{$$self{dispatch}} : (),
            '/' => sub {
                my ($meta, $html);
                if ($MOZILLA) {
                    $meta = qq{<?xml version="1.0" encoding="UTF-8"?>\n} .
                           (qq{<?xml-stylesheet href="chrome://global/skin" type="text/css"?>\n} x!! $$self{skin});
                    $root = $$self{content}[0]{TAG} eq 'window'
                            ? shift @{$$self{content}}
                            : XUL::Gui::Window()
                } else {
                    $meta = qq{<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">\n};
                    $html = $$self{content}[0]{TAG} eq 'html:html'
                            ? shift @{$$self{content}}
                            : XUL::Gui::HTML();

                    for (@{$$html{C}}) {
                        if ($$_{TAG} eq 'html:body') {
                            $root = $_;
                            last;
                        }
                    }
                    unless ($root) {
                        for (0 .. $#{$$self{content}}) {
                            if ($$self{content}[$_]{TAG} eq 'html:body') {
                                $root = splice @{$$self{content}}, $_, 1;
                                last;
                            }
                        }
                        push @{$$html{C}}, $root ||= XUL::Gui::BODY();
                    }
                }
                for (qw/onunload onclose/) {
                    $$self{$_}  ||= $$root{A}{$_};
                    $$root{A}{$_} = 'return xul_gui.shutdown();';
                }
                unshift @{$$self{content}}, @{ $$root{C} };
                $$self{root} = $root;
                $$root{C} = [ XUL::Gui::Script(src=>"http://localhost:$$self{port}/client.js") ];
                $self->write(
                    $MOZILLA ? 'application/vnd.mozilla.xul+xml'
                             : 'text/html',
                    $meta . (
                        $MOZILLA ? $root->$toXML
                                 : $html->$toXML
                    )
                )
            },
            '/client.js' => sub {
                $self->write( 'text/javascript',
                    join ";\n" => $self->client_js,
                        qq {xul_gui.root = ID.$$root{ID} = document.getElementById('$$root{ID}')},
                        (map {$_->$toJS("ID.$$root{ID}")} @{$$self{content}}),
                        'xul_gui.start()'
                );
                push @{$$root{C}}, splice @{$$self{content}};
            },
            '/event' => sub {
                $self->status("event $$req{CONTENT}") if $DEBUG > 1;
                my ($code, $id, $evt, $obj) = split ' ', $$req{CONTENT};
                for ($ID{$id}) {
                    my $handler = $$_{"ON\U$evt"};
                    if (ref $handler eq 'CODE') {
                        $handler->( $_, XUL::Gui::object(undef, id=>$obj) );
                    } else {$self->status("no event handler found: $$req{CONTENT}")}
                }
                $self->write('text/plain', 'NOOP');
            },
            '/perl' => sub {
                $self->status("perl $$req{CONTENT}") if $DEBUG > 1;
                local $@;
                my $return;
                eval "no strict; package $$self{caller}; \$return = do {$$req{CONTENT}}; 1"
                    or warn "perl( $$req{CONTENT} ) error: $@\n";
                $self->write( 'text/plain', "RETURN " . ($return || ''));
            },
            '/ping' => sub {
                if (my @delay = splice @{$$self{queue}}) {
                    $self->status('/ping clearing delay queue') if $DEBUG > 1;
                    $_->() for @delay;
                    XUL::Gui::flush;
                }
                local $DEBUG = 0;
                $self->write('text/plain', 'NOOP');
            },
            '/favicon.ico' => sub {
                $self->write('text/plain', '');
            },
            '/close' => sub {
                my $shutdown = 1;
                for (grep defined, @$self{qw/onclose onunload/}) {
                    $shutdown = ref eq 'CODE' ? $_->() : XUL::Gui::gui $_;
                }
                $self->write('text/plain', 'RETURN ' . ($shutdown ? 'true' : 'false'));
                $$self{run} = ! $shutdown if $$self{run};
            }
        }
    }

    {my @firefox;
    sub launch {
        my $self = shift;

        if ($$self{default_browser} or not $MOZILLA) {
            my $cmd = ($^O =~ /MSWin/  ? 'start' :
                       $^O =~ /darwin/ ? 'open'  : 'xdg-open')
                . qq{ http://localhost:$$self{port}};

            $self->status('launching default browser' . ($DEBUG ? ": $cmd" : ''));
            system $cmd and die $!;
            return
        }
        unless (@firefox) {
            find sub {push @firefox, [length, $File::Find::name]
                       if /^(:?firefox|iceweasel|xulrunner.*)(?:-bin|\.exe)?$/i and -f} => $_
            for grep {/mozilla|firefox|iceweasel|xulrunner/i }
                map {
                    if (opendir my $dir => my $path = $_)
                       {map "$path/$_"  => readdir $dir} else {}
                }
                    $^O =~ /MSWin/  ? @ENV{qw/ProgramFiles ProgramFiles(x86)/} :
                    $^O =~ /darwin/ ? '/Applications' :
                    split  /[:;]/  => $ENV{PATH};
            @firefox = sort {$$a[0] < $$b[0]} @firefox
        }
        if (@firefox) {
            my $app;
            for ($$self{trusted}) {
                defined and !$_ or $_ =
                    `"$firefox[0][1]" -v 2>&1` =~
                        / (?: firefox | iceweasel ) \s+ [34]
                            | xulrunner             \s+ (?: 1\.[5-9] | 2\.[0-3] )
                        /ix
            }
            if ($$self{trusted}) {
                local $@;
                eval {
                    require File::Spec;
                    require File::Temp;
                    $$self{dir} = File::Temp->newdir('xulgui_XXXXXX', TMPDIR => 1);

                    $$self{dir}->unlink_on_destroy(0); # for threads
                    my $dirname = $$self{dir}->dirname;
                    my $base    = (File::Spec->splitdir($dirname))[-1];

                    my ($file, $dir) = map {my $method = $_;
                        sub {File::Spec->$method( $dirname, split /\s+/ => "@_" )}
                    } qw( catfile catdir );

                    mkdir $dir->($_) or die $!
                        for qw(chrome defaults), "chrome $base", 'defaults preferences';

                    open my $manifest, '>', $file->('chrome chrome.manifest') or die $!;
                    print $manifest "content $base file:$base/";

                    open my $boot, '>', $file->('chrome', $base, 'boot.xul') or die $!; {
                        no warnings 'redefine';
                        local *write = sub {
                            my $self = shift;
                            my $code = pop;
                            $self->status("write \n\t". join "\n\t", split /\n/, $code) if $DEBUG > 3;
                            $code
                        };
                        print $boot $$self{dispatch}{'/'}();
                    }

                    open my $prefs, '>', $file->('defaults preferences prefs.js') or die $!;
                    print $prefs qq {pref("toolkit.defaultChromeURI", "chrome://$base/content/boot.xul");};

                    open my $ini, '>', $app = $file->('application.ini') or die $!;
                    print $ini split /[\t ]+/ => qq {
                        [App]
                        Name=$base
                        Version=$XUL::Gui::VERSION
                        BuildID=$base

                        [Gecko]
                        MinVersion=1.6
                        MaxVersion=2.3
                    };
                    $self->status("trusted: $app") if $DEBUG > 2;
                    1
                } or do {
                    chomp (my $err = ($@ or $!));
                    $self->status("trusted mode failed: $err");
                    $$self{trusted} = 0;
                    undef $app;
                }
            } else {
                while ($firefox[0][1] =~ /xulrunner[^\/\\]$/i) {
                    shift @firefox;
                    unless (@firefox) {
                        status {}, 'firefox not found: xulrunner was found but trusted mode is disabled';
                        return
                    }
                }
            }

            my $firefox = $firefox[0][1];
            $firefox =~ tr./.\\. if $^O =~ /MSWin/;
            my $cmd = qq{"$firefox" }
                    . ($app
                        ? "-app $app"
                        : ($$self{chrome} ? '-chrome ' : '')
                            . qq{"http://localhost:$$self{port}"}
                    ) . (q{ 1>&2 2>/dev/null} x ($^O !~ /MSWin/));
            if ($$self{launch}) {
                $self->status('launching firefox' . ($DEBUG ? ": $cmd" : ''));

                if (not $$self{trusted} and $^O =~ /darwin/) {
                    system qq[osascript -e 'tell application "Firefox" to OpenURL "http://localhost:$$self{port}"']
                } else {
                    $$self{ffpid} = open $$self{firefox} => "$cmd |";
                }
            } else {
                status {}, "launch gui with:\n\t$cmd"
            }
        }
        else {status {}, 'firefox not found: start manually'}
    }}

    sub CLONE {
        local $@;
        eval {$$active{client}->close};
        eval {$$active{server}->close};
    }
    BEGIN {*cleanup = \&CLONE}
    END {
        local $@;
        for (@cleanup) {
            eval {$_->cleanup};
            eval {
                $$_{dir}->unlink_on_destroy(1);
                $$_{dir}->DESTROY;
            };
        }
        eval {File::Temp::cleanup()};
    }

    sub client_js {
        my $self = shift;
        XUL::Gui::apply {
            s/<port>/$$self{port}/g;
            unless ($MOZILLA) {
                s/\bconst\b/var/g;
                s/^/if (!window.Element) window.Element = function(){};/;
            }
        } <<'</script>' }

const xul_gui = (function () {
    var $jsid        = 0;
    var $ID          = {};
    var $noEvents    = {};
    var $cacheEvents = true;
    var $ping        = 50;
    var $host        = 'http://localhost:<port>/';
    var $port        = <port>;
    var $queue       = [];
    var $mutex       = false;
    var $delayqueue  = [];
    var $server      = new XMLHttpRequest();
    var $lives       = 5;
    var $interval;
    var $deadman;
    function deadman () {
        if (--$lives <= 0) quit();
        $deadman = setTimeout(deadman, 50);
    }
    function deadman_pause  () {clearTimeout($deadman)}
    function deadman_resume () {$lives++; deadman()}

    function pinger () {
        if ($mutex || !$cacheEvents) return;
        while ($delayqueue.length > 0)
               $delayqueue.shift().call();
        EVT( null, null );
    }

    function start () {
        $interval = setInterval( pinger, $ping );
        deadman();
    }

    function shutdown () {return send('close','')}

    function send ($to, $val) {
        var $url    = $host + $to;
        var $resurl = $host + 'res';
        var $type;
        var $realval;
        while (1) {
            deadman_pause();
            $server.open( 'POST', $url, false );
            $server.send( $val );
            $lives = 5;
            deadman_resume();
            $val = $server.responseText;

            if ($val == 'NOOP')                 return $realval;
            if ($val.substr(0, 7) == 'RETURN ') return eval( $val.substr(7) );

            try {$realval = eval( $val )}
            catch ($err) {
                if ($err == 'quit') return $server = null;
                alert (
                    typeof $err == 'object'
                        ? [$err.name, $val, $err.message].join("\n\n")
                        : $err
                );
                $realval = null;
            }
            $url  =  $resurl;
            $val  =  $realval;
            $type =  typeof $val;
                 if ($val === true                       ) $val = 'RES 1'
            else if ($val === false || $val === 0        ) $val = 'RES 0'
            else if ($val === null  || $val === undefined) $val = 'UND EF'
            else if ($type == 'object')
                 if ($val.hasAttribute && $val.hasAttribute('id'))
                     $val  =     'OBJ ' + $val.getAttribute('id')
                 else
                     xul_gui.ID[ 'xul_js_' + $jsid ] = $val,
                     $val  =  'OBJ xul_js_' + $jsid++
            else     $val  =  'RES ' + $val
        }
    }

    function EVT ($event, $id) {
        if ($noEvents.__count__ > 0
            && $id in $noEvents) return;
        if ($mutex) {
            if($cacheEvents && $event)
                $queue.push([$event, $id]);
            return
        }
        $mutex = true;
        var $ret;
        var $evt;
        do {
            if ($evt) {
                $event = $evt[0];
                $id    = $evt[1];
            }
            if ($event) {
                if ($event.type == 'perl') {
                    $ret = send('perl', $event.code);
                    break;
                } else {
                    $ID['xul_js_' + $jsid] = $event;
                    send('event', 'EVT ' + $id +
                         ' ' + $event.type + ' ' + ('xul_js_' + $jsid++));
                }
            } else {
                send('ping', null)
            }
        } while ($evt = $queue.shift());
        $mutex = false;
        if ($event) setTimeout(pinger, 10);
        return $ret;
    }

    function GET ($self, $k) {
        if (typeof $self.hasAttribute == 'function' && $self.hasAttribute($k))
            return $self.getAttribute($k);

        if (typeof $self[$k] == 'function')
            return $self[$k]();

        return $self[$k];
    }

    function SET ($self, $k, $v) {
        if (typeof $self.hasAttribute == 'function'
                && $self.hasAttribute($k) ) {
             $self.setAttribute($k, $v);
             return $v;
        }
        return $self[$k] = $v;
    }

    function quit () {
        clearInterval($interval);
        EVT = function(){};
        try {
            var $appStartup = Components.classes[
                    '@mozilla.org/toolkit/app-startup;1'
                ].getService(Components.interfaces.nsIAppStartup);
            $appStartup.quit(Components.interfaces.nsIAppStartup.eForceQuit);
        } catch ($e) {}
        try {
            window.close();
        } catch ($e) {}
        throw 'quit';
    }

    function pevt ($code) {
        EVT({ type: 'perl', code: $code }, null)
    }

    function perl ($code) {
        return ($mutex ? send('perl', $code) : pevt($code))
    }

    function delay ($code) {
        $delayqueue.push(
            typeof $code == 'function'
                ? $code
                : function(){eval($code)}
        )
    }

    Element.prototype.noEvents = function ($value) {
        return $value
            ? $noEvents[this] = true
            : delete $noEvents[this]
    };

    return {
        ID:       $ID,
        noEvents: $noEvents,
        start:    start,
        shutdown: shutdown,
        send:     send,
        EVT:      EVT,
        GET:      GET,
        SET:      SET,
        quit:     quit,
        pevt:     pevt,
        perl:     perl,
        delay:    delay,
        cacheEvents:    function ($val) {$cacheEvents = $val},
        deadman_pause:  deadman_pause,
        deadman_resume: deadman_resume
    }
})();

for (var $name in xul_gui)
  window[$name] = xul_gui[$name];

const ID = xul_gui.ID;

(function ($proto) {
    for (var $name in $proto)
        Element.prototype[$name] = $proto[$name]
})({
    removeChildren: function () {
        while (this.firstChild)
            this.removeChild( this.firstChild )
    },
    removeItems: function () {
        while (this.lastChild
            && this.lastChild.nodeName == 'listitem')
            this.removeChild( this.lastChild )
    },
    computed: function ($style) {
        return document.defaultView
            .getComputedStyle( this, null )
            .getPropertyValue( $style )
    },
    scrollTo: function ($x, $y) {
        try {
            this.boxObject
                .QueryInterface( Components.interfaces.nsIScrollBoxObject )
                .scrollTo($x, $y)
        } catch ($e)
            { alert('error: ' + this.tagName + ' does not scroll') }
    }
});

</script>


package
    XUL::Gui;
    no warnings 'once';

=head2 widgets

=over 4

=item ComboBox

create dropdown list boxes

    items => [
        ['displayed label' => 'value'],
        'label is same as value'
        ...
    ]
    default => 'item selected if this matches its value'

    also takes: label, oncommand, editable, flex
    styles:     liststyle, popupstyle, itemstyle
    getter:     value

=cut

*ComboBox = widget {
    my $sel = $_->has('default') || '';
    my $in = grep /^$sel/ =>
             map {ref $_ ? $$_[1] : $_}
             @{ $_->has('items!') };

    my $menu = MenuList(
        id => 'list',
        $_ -> has('oncommand editable flex liststyle->style'),
        MenuPopup(
            id => 'popup',
            $_ -> has('popupstyle->style'),
            map {MenuItem(
                $_{W}->has('itemstyle->style'),
                zip [qw/label tooltiptext value selected/] =>
                    apply {$$_[3] = ($sel and $$_[2] =~ /^$sel/) ? 'true' : 'false'}
                        ref $_ eq 'ARRAY'
                            ? [@$_[0, 0, 1]]
                            : [($_) x 3]
            )} ($_{A}{editable} && $sel && !$in ? $sel : ()),
               @{ $_->has('items!') }
        )
    );
    $_->has('label')
        ? Hbox( align => 'center', Label( $_->has('label->value') ), $menu )
        : $menu
}
    value => sub {
        my $self = shift;
        my $item = $$self{list}->selectedItem;

        $item ? $item->value
              : $$self{list}->inputField->_value
    };

=back

=head1 CAVEATS

too many changes to count.  if anything is broken, please send in a bug report.

some options for display have been reworked from 0.36 to remove double negatives

widgets have changed quite a bit from version 0.36. they are the same under the
covers, but the external interface is cleaner. for the most part, the following
substitutions are all you need:

    $W       -->  $_ or $_{W}
    $A{...}  -->  $_{A}{...} or $_->attr(...)
    $C[...]  -->  $_{C}[...] or $_->child(...)
    $M{...}  -->  $_{M}{...} or $_->can(...)

    attribute 'label onclick'  -->  $_->has('label onclick')
    widget {extends ...}       -->  widget {$_->extends(...)}

export tags were changed a little bit from 0.36

thread safety should be better than in 0.36

currently it is not possible to open more than one window, hopefully this will
be fixed soon

the code that attempts to find firefox may not work in all cases, patches
welcome

for the TextBox object, the behaviors of the "value" and "_value" methods are
reversed. it works better that way and is more consistent with the behavior of
other tags.

=head1 AUTHOR

Eric Strom, C<< <asg at cpan.org> >>

=head1 BUGS

please report any bugs or feature requests to C< bug-xul-gui at rt.cpan.org >,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XUL-Gui>. I will be notified,
and then you'll automatically be notified of progress on your bug as I make
changes.

=head1 ACKNOWLEDGMENTS

the mozilla development team

=head1 COPYRIGHT & LICENSE

copyright 2009-2010 Eric Strom.

this program is free software; you can redistribute it and/or modify it under
the terms of either: the GNU General Public License as published by the Free
Software Foundation; or the Artistic License.

see http://dev.perl.org/licenses/ for more information.

=cut


{package
    XUL::Gui::Hash;
    use Scalar::Util qw/blessed weaken isweak/;
    sub new {
        if (not defined wantarray) {
            my %base = %{$_[1]};
            tie %{$_[1]} => $_[0], \%base, @_[2 .. $#_];
            return;
        }
        my ($class, $self) = splice @_, 0, 2;
        tie my %hash => $class, $self, @_;
        blessed ($self)
            ? bless \%hash => ref $self
            : \%hash
    }
    sub unshift {
        my $self = shift;
        unshift @{$$self{isa}}, @_;

        isweak $_ or weaken $_ for @{$$self{isa}};
    }
    sub hasOwn {exists $_[0]{hash}{$_[1]}}
    sub hash :lvalue {$_[0]{hash}}
    sub TIEHASH {
        my $class = shift;
        bless my $self  = {
            hash => shift || {},
            isa  => [ @_ ]
        } => $class;

        weaken $_ for @{$$self{isa}};
        $self
    }
    sub FETCH {
        my ($self, $key) = @_;

        if (exists $$self{hash}{$key}) {
            return $$self{hash}{$key}
        }
        return if $key eq uc $key;

        for (@{$$self{isa}}) {
            return $$_{$key} if $_ and %$_ and exists $$_{$key}
        }
        return
    }
    sub STORE {$_[0]{hash}{$_[1]} = $_[2]}
    sub DELETE {delete $_[0]{hash}{$_[1]}}
    sub CLEAR  {$_[0]{hash} = {}}
    sub EXISTS {
        my ($self, $key) = @_;
        return 1 if exists $$self{hash}{$key};
        return if $key eq uc $key;
        for (@{$$self{isa}}) {
            return 1 if $_ and %$_ and exists $$_{$key}
        }
        return
    }
    sub FIRSTKEY {
        my ($self) = @_;
        my @each = ($$self{hash}, @{$$self{isa}});
        keys %$_ for @each;
        my %seen;
        my $count = @each;

        goto &{
            $$self{nextkey} = sub {
                my $want = wantarray;
                while (@each) {
                    if ($want) {
                        if (my ($k, $v) = each %{$each[0]}) {
                            redo if $seen{$k}++;
                            redo if $k eq uc $k and $count != @each;
                            return $k, $v
                        }
                    } else {
                        if (defined (my $k = each %{$each[0]})) {
                            redo if $seen{$k}++;
                            redo if $k eq uc $k and $count != @each;
                            return $k;
                        }
                    }
                    shift @each
                }
                return
            }
        }
    }
    sub NEXTKEY {$_[0]{nextkey}()}

    sub SCALAR {
        my $self = shift;
        for ($$self{hash}, @{$$self{isa}}) {
            return scalar (%$_) || next
        }
        return
    }
    sub UNTIE {
        my $self = shift;
        delete $$self{$_} for keys %$self;
    }
}


__PACKAGE__ if 'first require'
