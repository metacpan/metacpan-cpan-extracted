package Tk::ObjScanner;

require 5.006;

use strict;
use warnings;
use Scalar::Util 1.01 qw(weaken isweak reftype);

# Version 1.1805 - patches proposed by Rudi Farkas rudif@lecroy.com
# 1: Use Adjuster so that the user can adjust the relative heights of the
# HList window and the dump window.
# 2: Provide 5 options for setting colors and images
# 3: Impose the same scrollbar style ('osoe') to HList and ROText.
# 4: Set -wideselection 0 for HList.
# The patches consist of code changes in sub Populate().

# Version 1.1803 - patch proposed by Rudi Farkas rudif@lecroy.com
# Purpose #1: fix the problem with call $scanner->configure();
#   dies with error
# unknown option "oldcursor" at C:/Perl/site/lib/Tk/Derived.pm line 223.
# The patch consists of
# - a modified ConfigSpecs line
#                     oldcursor => [$hlist, undef, undef, undef],
# Purpose #2: add 'open folder' image and display it when item has displayed children
# The patch consists of
# - a line in sub Populate
#    $cw->{openImg} = $cw->Photo(-file => Tk->findINC('open_folder.xbm'));
# - method _redisplayImage()
# - 2 calls to _redisplayImage inside displaySubItem()

# Patch proposed by Rudi Farkas rudif@lecroy.com
# Purpose: while executing displaySubItem() which may take a long time
# if getting data from disk, another package or another machine,
# the default arrow cursor is replaced by a 'watch' cursor.
# The patch consists of
# - ConfigSpecs item : oldcursor => undef
# - method _swapCursor()
# - 3 calls to _swapCursor inside displaySubItem(), at entry and at 2 exits

# Implementation note:
#
# The scanner deals with a tree representation of the user data. The
# scanner used to keep a copy of the data in its data tree that is
# embedded in the HList widget. Unfortunately this scheme fails when
# dealing with tied scalar: the copy stored within the HList is a copy
# of the value of the scalar. The tied object itself is lost.

# So to be able to use ObjScanner with tied scalar, one big change was
# necessary: The HList data must not hold a copy of the data, but just
# reference to the data. Hence it will hold a scalar ref, a ref to a
# hash ref or a ref to an array ref. Hence the item attribute of the
# itemcget data part of Hlist is changed to item_ref.

# Furthermore to avoid memory leak if the user modifies its data
# structure, the ref kept must be weakened (See Scalar::Util man page)

use Carp;
use warnings;
use Tk::Derived;
use Tk::Frame;
use Data::Dumper;

use base qw(Tk::Derived Tk::Frame);

Tk::Widget->Construct('ObjScanner');

sub scan_object {
    require Tk;
    import Tk;
    my $object = shift;
    my $animate = shift || 0;    # used by tests

    my $mw = MainWindow->new;
    $mw->geometry('+10+10');
    my $s = $mw->ObjScanner(
        '-caller'    => $object,
        -destroyable => 1,
        -title       => 'object scan'
    );

    $s->pack( -expand => 1, -fill => 'both' );
    $s->OnDestroy( sub { $mw->destroy; } );

    if ($animate) {
        $s->_scan('root');
    }
    else {
        &MainLoop;    # Tk's
    }
}

# used by test
sub _scan {
    my $cw      = shift;
    my $topName = shift;
    $cw->yview($topName);
    $cw->after(200);    # sleep 200ms

    foreach my $c ( $cw->infoChildren($topName) ) {
        $cw->displaySubItem($c);
        $cw->_scan($c);
    }
    $cw->idletasks;
}

sub _isa {
    #return UNIVERSAL::isa(@_);
    return (reftype($_[0]) // '') eq $_[1] ;
}

sub Populate {
    my ( $cw, $args ) = @_;

    require Tk::Menubutton;
    require Tk::HList;
    require Tk::ROText;
    require Tk::Adjuster;

    $cw->{show_menu} =
          defined $args->{'show_menu'}  ? delete $args->{'show_menu'}
        : defined $args->{'-show_menu'} ? delete $args->{'-show_menu'}
        :                                 0;

    my $display_show_tied_button = defined $args->{'-show_tied'}
        || defined $args->{show_tied} ? 0 : 1;

    $cw->{show_tied} =
          defined $args->{'-show_tied'} ? delete $args->{'-show_tied'}
        : defined $args->{show_tied}    ? delete $args->{show_tied}
        :                                 1;

    my $scanned_data = delete $args->{'caller'} || delete $args->{'-caller'};
    $cw->{chief} = \$scanned_data;

    my $destroyable =
          defined $args->{'-destroyable'} ? delete $args->{'-destroyable'}
        : defined $args->{'destroyable'}  ? delete $args->{'destroyable'}
        :                                   1;

    my $display_view_pseudo_button = defined $args->{'-view_pseudo'}
        || defined $args->{view_pseudo} ? 0 : 1;

    my $view_pseudo =
           delete $args->{'-view_pseudo'}
        || delete $args->{'view_pseudo'}
        || 0;

    # override option for feature not supported by Perl 5.09 and later
    if ( $] >= 5.009 ) {
        $view_pseudo = 0;
    }

    croak "Missing caller argument in ObjScanner\n"
        unless defined $cw->{chief};

    my $title =
           delete $args->{title}
        || delete $args->{-title}
        || ref( $cw->{chief} ) . ' scanner';

    my $background = delete $args->{'background'}
        || delete $args->{'-background'};
    my $selectbackground = delete $args->{'selectbackground'}
        || delete $args->{'-selectbackground'};

    $cw->{itemImg} =
           delete $args->{'itemImage'}
        || delete $args->{'-itemImage'}
        || $cw->Photo( -file => Tk->findINC('textfile.xpm') );
    $cw->{foldImg} =
           delete $args->{'foldImage'}
        || delete $args->{'-foldImage'}
        || $cw->Photo( -file => Tk->findINC('folder.xpm') );
    $cw->{openImg} =
           delete $args->{'openImage'}
        || delete $args->{'-openImage'}
        || $cw->Photo( -file => Tk->findINC('openfolder.xpm') );

    my $menuframe;
    my $menu;
    if ( $destroyable or $cw->{show_menu} ) {
        $menuframe =
            $cw->Frame( -relief => 'raised', -borderwidth => 1 )-> pack( -pady => 2, -fill => 'x' );

        $menu = $cw->{menu} = $menuframe->Menubutton( -text => $title . ' menu' )
            ->pack( -fill => 'x', -side => 'left' );

        $menu->command(
            -label   => 'reload',
            -command => sub { $cw->updateListBox; } );
    }

    my %hlist_args;
    map { $hlist_args{$_} = delete $args->{$_} if defined $args->{$_}; } qw/-columns -header/;

    my $hlist = $cw->Scrolled(
        qw\HList -selectmode single -indent 35 -separator |
            -itemtype imagetext -wideselection 0 \, %hlist_args
    )->pack(qw/-fill both -expand 1 /);

    # See Mastering Perl/Tk page 364 for details
    $hlist->bind(
        '<Double-B1-ButtonRelease>' => sub {
            my $y    = $Tk::event->y;
            my $name = $Tk::widget->nearest($y);
            $cw->displaySubItem( $name, 0 );
        } );

    $hlist->bind(
        '<Double-B2-ButtonRelease>' => sub {
            my $y    = $Tk::event->y;
            my $name = $Tk::widget->nearest($y);
            $cw->displaySubItem( $name, 1 );
        } ) if $cw->{show_tied};

    $cw->Advertise( hlist => $hlist );

    #my $adj1 = $cw->Adjuster()->packAfter($hlist);

    my $popup = $cw->{popup} = $cw->Toplevel;
    $popup->withdraw;
    $cw->{dumpLabel} = $popup->Label( -text => 'not yet ...' );
    $cw->{dumpLabel}->pack( -fill => 'x' );
    $cw->{dumpWindow} = $popup->Scrolled( 'ROText', -height => 10 );
    $cw->{dumpWindow}->pack( -fill => 'both', -expand => 1 );
    $popup->Button(
        -text    => 'OK',
        -command => sub { $popup->withdraw(); } )->pack;

    # add a destroy commend to the menu
    $menu->command(
        -label   => 'destroy',
        -command => sub { $cw->destroy; } ) if defined $cw->{menu} && $destroyable;

    $cw->ConfigSpecs(
        -scrollbars => [ 'DESCENDANTS', undef,        undef,        'osoe' ],
        -background => [ 'DESCENDANTS', 'background', 'Background', $background ],
        -selectbackground => [ $hlist, 'selectBackground', 'SelectBackground', $selectbackground ],
        -width            => [ $hlist, undef,              undef,              80 ],
        -height           => [ $hlist, undef,              undef,              25 ],
        -oldcursor        => [ $hlist, undef,              undef,              undef ],
        DEFAULT           => [$hlist] );

    $cw->Delegates( DEFAULT => $hlist );

    $cw->SUPER::Populate($args);

    $cw->{viewpseudohash} = $view_pseudo;

    if ( defined $menuframe ) {
        $menuframe->Checkbutton(
            -text     => 'view pseudo-hashes',
            -variable => \$cw->{viewpseudohash},
            -onvalue  => 1,
            -offvalue => 0,
            -command  => sub { $cw->updateListBox; }
            )->pack( -side => 'right' )
            if $display_view_pseudo_button;

        $menuframe->Checkbutton(
            -text     => 'show tied info',
            -variable => \$cw->{show_tied},
            -onvalue  => 1,
            -offvalue => 0,
            -command  => sub { $cw->updateListBox; }
            )->pack( -side => 'right' )
            if $display_show_tied_button;
    }

    $cw->updateListBox;

    return $cw;
}

# function to find whether a reference is a pseudo hash
# return the nb of elements of the pseudo hash
sub isPseudoHash {
    my $cw   = shift;
    my $item = shift;

    return 0
        unless ( defined $item
        && $cw->{viewpseudohash}
        && _isa( $item, 'ARRAY' )
        && scalar @$item
        && ref( $item->[0] ) =~ /^(HASH|pseudohash)$/ );

    my @indexes   = values %{ $item->[0] };
    my $nb_of_elt = scalar keys %{ $item->[0] };

    # check that all indexes are numbers and within the range
    return 0 if scalar grep( /\D/ || $_ < 1 || $_ > $nb_of_elt, @indexes );

    # check that not more array items than in the range are defined
    return 0 unless $nb_of_elt >= scalar @$item - 1;

    return $nb_of_elt;
}

sub updateListBox {
    my $cw = shift;

    my $h    = $cw->Subwidget('hlist');
    my $root = 'root';

    #print "root adding $root \n";
    if ( $h->infoExists($root) ) {

        #print "deleting root children\n";
        $h->deleteOffsprings($root);

        # set new text of root
        $h->entryconfigure( $root, -text => $cw->element( $cw->{chief} ) );
    }
    else {
        $h->add( $root, -data => { tied_display => 0, item_ref => $cw->{chief} } );
        $h->itemCreate(
            $root, 0,
            -image => $cw->{foldImg},
            -text  => $cw->element( $cw->{chief} ) );
    }

    $cw->displaySubItem( $root, 0 );
}

sub displaySubItem {
    my $cw     = shift;
    my $name   = shift;
    my $do_tie = shift || 0;

    $do_tie = 0 unless $cw->{show_tied};

    my $h = $cw->Subwidget('hlist');
    $h->selectionClear();
    $h->selectionSet($name);

    ###
    my $hash         = $h->info( 'data', $name );
    my $tied_display = $hash->{tied_display};
    my $ref          = $hash->{item_ref};

    #print "pressed ",$Tk::event->b,',',
    #  $Tk::event->x,' ',$y," for $Tk::widget\n";

    # test for tied_display objects
    my $tied_object;
    if    ( _isa( $$ref, 'ARRAY' ) ) { $tied_object = tied @$$ref; }
    elsif ( _isa( $$ref, 'HASH' ) )  { $tied_object = tied %$$ref; }
    elsif ( _isa( $$ref, 'REF' ) )   { $tied_object = tied $$$ref; }
    else                            { $tied_object = tied $$ref; }

    my $is_tied = $do_tie && defined $tied_object ? 1 : 0;
    my $delete = $is_tied ^ $tied_display;

    #print "Button clicked for $name (do_tie $do_tie, item $$ref, ",
    #  "tied object $tied_object)\n";

    if ($delete) {
        $hash->{tied_display} = $is_tied;
        $h->deleteOffsprings($name);
    }

    $cw->toggle_display($name);

    # return if the children are already represented in the hlist
    return if scalar( $h->infoChildren($name) );

    my $ref_to_display = $is_tied ? \$tied_object : $ref;

    $cw->_swapCursor('watch');
    $cw->displayObject( $name, $ref_to_display );
    $cw->_swapCursor();
    $cw->_redisplayImage($name);
}

sub toggle_display {
    my $cw   = shift;
    my $name = shift;

    my $h = $cw->Subwidget('hlist');
    foreach my $child ( $h->infoChildren($name) ) {
        if ( $h->info( 'hidden', $child ) ) { $h->show( 'entry', $child ); }
        else                                { $h->hide( 'entry', $child ); }
    }
    $cw->_redisplayImage($name);
}

sub displayObject {
    my $cw   = shift;
    my $name = shift;
    my $ref  = shift;

    my $h            = $cw->Subwidget('hlist');
    my $isPseudoHash = $cw->isPseudoHash($$ref);

    if ( _isa( $$ref, 'ARRAY' ) and not $isPseudoHash ) {
        foreach my $i ( 0 .. $#$$ref ) {

            #print "adding array item $i: $_,",ref($_),"\n";
            my $img = ref $$ref->[$i] ? $cw->{foldImg} : $cw->{itemImg};
            my $npath = $h->addchild( $name,
                -data => { tied_display => 0, index => $i, item_ref => \$$ref->[$i] } );
            $h->itemCreate(
                $npath, 0,
                -image => $img,
                -text  => $cw->describe_element( $ref, $i ) );
        }
    }
    elsif ( _isa( $$ref, 'REF' ) or _isa( $$ref, 'SCALAR' ) ) {
        my $npath = $h->addchild(
            $name,
            -data => {
                tied_display => 0,
                item_ref     => $$ref
            } );
        $h->itemCreate(
            $npath, 0,
            -image => _isa( $$ref, 'REF' ) ? $cw->{foldImg} : $cw->{itemImg},
            -text => $cw->describe_element($ref) );
    }
    elsif ( _isa( $$ref, 'CODE' ) ) {
        require B::Deparse;
        my $deparse = B::Deparse->new( "-p", "-sC" );
        my $body = $deparse->coderef2text($$ref);
        $cw->popup_text( "B::Deparse code dump", $body );
    }
    elsif ( _isa( $$ref, 'GLOB' ) ) {
        if ( _isa( $$ref, 'UNIVERSAL' ) ) {
            my ($what) = ( $$ref =~ /\b([A-Z]+)\b/ );
            $cw->popup_text( 'Error', "Sorry, can't display a $what based $$ref object" );
        }
        else {
            $cw->popup_text( 'Error', "Sorry, can't display " . $$ref . " reference" );
        }
    }
    elsif ( _isa( $$ref, 'HASH' ) or $isPseudoHash ) {

        # hash or object
        foreach my $k ( sort keys %$$ref ) {

            #print "adding hash key $name|$k ", ref($$ref->{$k}),"\n";

            my $img = ref( $$ref->{$k} ) ? $cw->{foldImg} : $cw->{itemImg};
            my $npath = $h->addchild(
                $name,
                -data => {
                    tied_display => 0,
                    index        => $k,
                    item_ref     => \$$ref->{$k} } );
            $h->itemCreate(
                $npath, 0,
                -text  => $cw->describe_element( $ref, $k ),
                -image => $img
            );
        }
    }
    elsif ( defined $$ref ) {

        #print "adding scalar $name , $$ref is a scalar\n";
        $cw->popup_text( 'scalar dump', $$ref ) if $$ref =~ /\n/;
    }
}

sub describe_element {
    my ( $cw, $ref, $index ) = @_;
    my $isPseudoHash = $cw->isPseudoHash($$ref);

    if ( _isa( $$ref, 'ARRAY' ) and not $isPseudoHash ) {
        return "[$index]-> " . $cw->element( \$$ref->[$index] );
    }
    elsif ( _isa( $$ref, 'REF' ) or _isa( $$ref, 'SCALAR' ) ) {
        return $cw->element($$ref);
    }
    elsif ( _isa( $$ref, 'HASH' ) or $isPseudoHash ) {
        return ( "{$index}-> " . $cw->element( \$$ref->{$index} ) );
    }
    else {
        die "describe_element: unexpected type $$ref, index $index";
    }
}

sub popup_text {
    my ( $cw, $title, $text ) = @_;
    $cw->{popup}->title($title);
    $cw->{dumpLabel}->configure( -text => $title );
    $cw->{dumpWindow}->delete( '1.0', 'end' );
    $cw->{dumpWindow}->insert( 'end', $text );
    $cw->{popup}->deiconify;
    $cw->{popup}->raise;
}

sub analyse_element {
    my $cw  = shift;
    my $ref = shift;

    my %info = ( description => '' );
    confess "ref error" unless ref($ref);

    my $pseudo = $info{pseudo_hash} = $cw->isPseudoHash($$ref);
    $info{element_ref} = $ref;

    my $str_ref = ref($$ref);
    $info{tied} =
          $str_ref eq 'HASH'   ? tied %$$ref
        : $str_ref eq 'ARRAY'  ? tied @$$ref
        : $str_ref eq 'SCALAR' ? tied $$$ref
        : $str_ref eq 'REF'    ? tied $$$ref
        : $str_ref             ? undef
        :                        tied $$ref;

    if ( not defined $$ref ) {
        $info{description} = 'undefined';
    }
    elsif ( $str_ref and _isa( $$ref, 'UNIVERSAL' ) ) {
        $info{class} = $str_ref;
        $info{base} =
              $pseudo ? 'PSEUDO-HASH'
            : _isa( $$ref, 'SCALAR' ) ? 'SCALAR'
            : ( $$ref =~ /=([A-Z]+)\(/ ) ? $1
            :                              "some magic with $$ref";    # desperate measure

        $info{description} = "$str_ref OBJECT based on $info{base}";
    }
    elsif ($pseudo) {
        $info{description} = 'PSEUDO-HASH';
    }
    elsif ($str_ref) {

        # a ref but not an object
        $info{description} = $str_ref;
    }
    elsif ( $$ref =~ /\n/ ) {

        # multi-line string
        $info{description} = 'double click here to display value';
    }
    else {
        # plain scalar
        $info{value} = $$ref;
    }

    if ( defined $$ref ) {
        $info{nb} =
              $pseudo ? $pseudo
            : _isa( $$ref, 'ARRAY' ) ? scalar(@$$ref)
            : _isa( $$ref, 'HASH' )  ? scalar keys(%$$ref)
            :                         undef;
    }

    if ( $str_ref and isweak($$ref) ) {
        $info{description} .= ' (weak ref)';
    }

    return \%info;
}

sub element {
    my $cw  = shift;
    my $ref = shift;

    my $info = $cw->analyse_element($ref);

    my $what = $info->{description} || "'$info->{value}'";
    my $nb   = $info->{nb};
    my $tied = $info->{tied};
    $what .= " ($nb)" if defined $nb;
    $what .= " (tied with " . ref($tied) . ")"
        if defined $tied
        and $cw->{show_tied};
    return $what;
}

sub _swapCursor {
    my ( $cw, $cursor ) = @_;
    my $parent = $cw->parent;
    if ( defined($cursor) ) {
        $cw->{oldcursor} = $parent->cget('-cursor');    # save
        $parent->configure( -cursor => $cursor );       # replace
    }
    else {
        $parent->configure( -cursor => $cw->{oldcursor} );    # restore
    }
    $parent->update;    # does not seem to be absolutely necessary
}

sub _redisplayImage {
    my ( $cw, $name ) = @_;
    my $h        = $cw->Subwidget('hlist');
    my @children = $h->infoChildren($name);
    return if @children == 0;
    my $image = $h->info( 'hidden', $children[0] ) ? $cw->{foldImg} : $cw->{openImg};
    $h->entryconfigure( $name, '-image' => $image );
}

1;

__END__


=head1 NAME

Tk::ObjScanner - 'A scanner to view an object\'s attribute

=head1 SYNOPSIS

  # regular use
  use Tk::ObjScanner;

  my $scanner = $mw->ObjScanner( -caller => $object, 
                                 -title=>"windows") -> pack ;

  my $mw -> ObjScanner
  (
   -caller 	    => $object,
   -title 	    => 'demo setting the scanner options',
   -background 	    => 'white',
   -selectbackground => 'beige',
   -foldImage 	    => $mw->Photo(-file => Tk->findINC('folder.xpm')),
   -openImage 	    => $mw->Photo(-file => Tk->findINC('openfolder.xpm')),
   -itemImage 	    => $mw->Photo(-file => Tk->findINC('textfile.xpm')),
  )
  -> pack(-expand => 1, -fill => 'both') ;

  # non-intrusive scan style

  # user code to produce data
  Tk::ObjScanner::scan_object($mydata) ;
  # resume user code

=head1 DESCRIPTION

The scanner provides a GUI to scan the attributes of an object. It can
also be used to scan the elements of a hash or an array.

This widget can be used as a regular widget in a Tk application or can
be used as an autonomous popup widget that will display the content of
a data structure. The latter is like a call to a graphical
L<Data::Dumper>. The scanner can be used in an autonomous way with the
C<scan_object> function.

The scanner is a composite widget made of a menubar and L<Tk::HList>.
This widget acts as a scanner to the object (or hash ref) passed with
the 'caller' parameter. The scanner will retrieve all keys of the
hash/object and insert them in the HList.

When the user double clicks on a key, the corresponding value will be added
in the HList.

If the value is a multi-line scalar, the scalar will be displayed in a
popup text window. Code ref will be deparsed and shown also in the
pop-up window.

Tied scalar, hash or array internal can also be scanned by clicking on
the I<middle> button to open them.

Weak references are recognized (See L<WeakRef> for details)

=head1 Autonomous widget

=head2 scan_object( data )

This function is not exported and must be called this way:

  Tk::ObjScanner::scan_object($data);

This function will load Tk and pop up a scanner widget. When the user
destroy the widget (with C<File -> destroy> menu), the user code is
resumed.

=head1 Constructor parameters

=over 4

=item C<caller>

The ref of the object or hash or array to scan (mandatory). (you can
also use 'C<-caller>')

=item C<-title>

The title of the menu created by the scanner (optional)

=item C<-background>

The background color for subwidgets (optional)

=item C<-selectbackground>

The select background color for HList (optional)

=item C<-itemImage>

The image for a scalar item (optional, default 'file.xbm')

=item C<-foldImage>

The image for a composite item (array or hash) when closed
(optional, default 'folder.xbm')

=item C<-openImage>

The image for a composite item (array or hash) when open
(optional, default 'openfolder.xbm')

=item C<-show_menu>

ObjScanner can feature a menu with 'reload' button, 'show tied info',
'view pseudo-hash' check box. (optional default 0).

=item C<-destroyable>

If set, a menu entry will allow the user to destroy the scanner
widget. (optional, default 1) . You may want to set this parameter to
0 if the destroy can be managed by a higher level object. This
parameter is ignored if show_menu is unset.

=item C<-view_pseudo>

If set, will interpret pseudo hashes as hash (default 0). This option
is disabled for Perl 5.09 and later.

=item C<-show_tied>

If set, will indicate if a variable is a tied variable. You can see
the internal data of the tied variable by double clicking on the
middle button. (default 1)

=back

=head1 WIDGET-SPECIFIC METHODS

=head2 updateListBox

Update the keys of the listbox. This method may be handy if the
scanned object wants to update the listbox of the scanner
when the scanned object gets new attributes.

=head1 CAVEATS

The name of the widget is misleading as any data (not only object) may
be scanned. This widget is in fact a DataScanner.

ObjScanner may fail if an object involves a lot of internal perl
magic.  In this case, I'd be glad to hear about and I'll try to fix
the problem.

ObjScanner does not detect recursive data structures. It will just
keep on displaying the tree until the user gets tired of clicking on
the HList items.

There's no sure way to detect if a reference is a pseudo-hash or
not. When a reference is believed to be a pseudo-hash, ObjScanner will
display the content of the reference like a hash. If the reference is
should not be displayed like a pseudo-hash, you can turn off the
pseudo-hash view with the check button on the top right of the widget.

Aynway, pseudo-hashes are deprecated from perl 5.8.0. Hence they are
also deprecated in ObjScanner.

The icon used for tied scalar changes from scalar icon to folder icon
when opening the object hidden behind the tied scalar (using the
middle button). I sure could use a better icon for tied items. (hint
hint)

=head1 THANKS

To Rudi Farkas for all the improvements provided to ObjScanner.

To Slaven Rezic for:

=over

=item *

The propotype code of the pseudo-hash viewer.

=item *

The idea to use B::Deparse to view code ref.

=back

=head1 AUTHOR

Dominique Dumont, ddumont@cpan.org

Copyright (c) 1997-2004,2007 Dominique Dumont. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<perl>, L<Tk>, L<Tk::HList>, L<B::Deparse>

=cut

