package TkUtil::Gui;

use warnings;
use strict;
use Perl6::Attributes;

=head1 NAME

TkUtil::Gui - Easy access to a Perl/Tk GUI state

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

    use TkUtil::Gui;

    my $gui = TkUtil::Gui->new(top => $mw);
    $gui->Listbox(name => 'List')->pack;
    $gui->Button(-text => 'Push Me')->pack;

=head1 DESCRIPTION

GUI's can be difficult to set up, but I have found that a lot of
code is required to merely get information out of a GUI to pass
to another application. This module attempts to rectify this.

It does it's magic by acknowledging that all Tk widget creation
switches begin with a "-" and that most widgets have a I<-text>
or I<-textvariable> option (or both). In general, this module
assigns those for you. And remembers them.

To create widgets, you do it like this:

  $frame = $mw->Frame->pack;
  $gui = TkUtil::Gui->new(top => $frame);
  $widget = $gui->Checkbutton(name => 'utm', -text => 'UTM')->pack;

What magically happens is that $gui assigns a variable reference
for you to the Checkbutton, and there are methods to allow
you to set it or fetch it.

If your GUI has an "OK" button (or something similar), you can (with
a single call) figure out the contents of the entire GUI, returned as
a hash.

See eg/Gui.t for an example.

More below.

=head1 METHODS

=cut

use strict;
use warnings;
use Perl6::Attributes;
use Data::Dumper;

=head2 B<new>

  $gui = TkUtil::Gui->new(top => $top);

I<$top> is the widget you want to create widgets in. You can change
the meaning of I<$top> at any time with the B<top> method. But please,
only create one instance of TkUtil::Gui. You can create more, but
they don't know about each other, so dumping the state of a GUI won't
work like you expect.

=cut

sub new {
    my $Class = shift;
    my (%opts) = @_;
    my $self = \%opts;
    bless $self, $Class;
    $.Class = $Class;
    ./_require("top");
    return $self;
}

sub _require {
    my ($self, $name) = @_;
    die "$.Class - $name is required\n" unless defined $self->{$name};
}

sub _specs {
    my ($self, $widget) = @_;
    return $widget->ConfigSpecs if defined $widget;
}

sub _setvar {
    my ($self, $widget, $default) = @_;
    my %specs;
    #print "_setvar got ", ref($widget), "\n";
    %specs = ./_specs($widget) if (!ref($widget->ConfigSpecs));
    my $var;
    if (defined $specs{-variable}) {
        my $vref = $widget->cget(-variable);
        if (!defined $vref) {
            $widget->configure(-variable => \$var);
            $.vars{$widget} = \$var;
            print "vref = $vref\n";
        }
        else {
            $.vars{$widget} = $widget->cget(-variable);
        }
        ${$.vars{$widget}} = $default;
    }
    my $textvar;
    if (defined $specs{-textvariable}) {
        my $text;
        $text = $widget->cget(-text) if defined $specs{-text};
        if (!defined $widget->{-textvariable}) {
            $widget->configure(-textvariable => \$textvar);
            $.textvars{$widget} = \$textvar;
        }
        else {
            $.textvars{$widget} = $widget->cget(-textvariable);
        }
        $textvar = $text if defined $text;
        ${$.textvars{$widget}} = $default if ref($widget) eq 'Tk::Entry';
        #print "text = $text\n";
    }
}

=head2 B<AUTOLOAD>

This is method that intercepts any undefined entry points. You don't
I<call> AUTOLOAD, it is Perl magic that intercepts any non-specified
function.

Special options, all of which are optional.

    name     [1]
    vfrom    [2]
    packOpts [3]
    onoff    [4]
    default  [5]

[1] this is the symbolic name by which this widget is referred. If this
is a widget you want to get information out of, then it should be named.
Buttons, which generally cause actions to happen, and don't have a lasting
state don't need this.

[2] useful for Radiobuttons, where a variable reference is shared. This
points to the name of a Radiobutton to share with. See example in
eg/Gui.t

[3] this is packing options, as an array reference

[4] useful for Checkbuttons, the test to use to indicate the on and off
state. Specified like "on|off" or "true|false" or something similar.

[5] a default value for this widget; only appropriate where a value
is meaningful. Currently, not Listboxes, though.

=cut

sub AUTOLOAD {
    my ($self) = CORE::shift;
    my @opts = @_;
    #print "Opts = ", Dumper(\@opts);
    my $name = our $AUTOLOAD;
    $name =~ s/.*://;
    return if $name eq 'DESTROY';
    my %opts;
    my %Opts;
    my $leadarg;

    # special handling for Scrolled widget
    $leadarg = shift(@opts) if $name eq 'Scrolled';
    %opts = @opts unless @opts % 2;

    # Separate Tk from "Special" switches
    my %Special;
    my %Tk;
    map {
        $Special{$_} = $opts{$_} unless $_ =~ /^-/;
        $Tk{$_} = $opts{$_}      if     $_ =~ /^-/;
    } keys(%opts);

    # this is our magic variable 
    my $var;

    # handle special on/off switch for Checkboxes
    if (defined $Special{onoff}) {
        my ($on, $off) = split(/\|/, $Special{onoff});
        $Tk{-onvalue} = $on   unless defined $Tk{-onvalue};
        $Tk{-offvalue} = $off unless defined $Tk{-offvalue};
        $Special{default} = $off if defined $off && !defined $Special{default};
    }
    #print Dumper(\%Tk);
    my @Tk = %Tk;
    unshift(@Tk, $leadarg) if defined $leadarg;
    my $w = $.top->$name(@Tk);
    #print ref($w), Dumper(\%Special);

    # Ow = original widget
    my $Ow = $w;
    my $reffer = ref($w);
    if ($reffer eq 'Tk::LabEntry' || $reffer eq 'Tk::BrowseEntry') {
        $w = $w->Subwidget('entry');
        $w = $w->Subwidget('entry') if ref($w) eq 'Tk::LabEntry';
    }

    my $packOpts = $.packOpts;
    $packOpts = $Special{packOpts} if defined $Special{packOpts};
    if (defined $packOpts && ref($packOpts) eq 'ARRAY') {
        $w->pack(@{$packOpts});
    }

    #print ref($w), "\n";
    if (defined $Special{vfrom}) {
        my $fw = ./_widget_from_name($Special{vfrom});
        $.vars{$w} = $.vars{$fw} if defined $fw;
        ./_setvar($w, $Special{default}) unless defined $fw;
    }
    else {
        ./_setvar($w, $Special{default});
        #print "setting ", ref($w), " to $Special{default}\n";
    }
    $.name{$Special{name}} = $w if defined $Special{name};

    # return original widget
    return $Ow;
}

=head2 B<top>

  $old = $gui->top($top);

Changes parent widget for widget creation. Returns the current
definition of "top" before it was changed. This way, you can
safely change it in a function, then change it back before you
return.

No argument means fetch and return the current value of I<top>.

=cut

sub top {
    my ($self, $top) = @_;
    return $.top unless defined $top;
    my $oldtop = $.top;
    $.top = $top if defined $top;
    return $oldtop;
}

=head2 B<names>

  @names = $gui->names();

All of the names maintained by this instance of the class.

=cut

sub names {
    my ($self) = @_;
    return keys(%{$.name});
}

=head2 B<vref>

  $vRef = $gui->vref($widget);

Get the variable reference associated with this widget.

=cut

sub vref {
    my ($self, $w) = @_;
    return $.textvars{$w} if ref($w) eq 'Tk::Entry';
    return $.vars{$w};
}

=head2 B<set>

  $gui->set($name, $value);

Set the named widget to the specified value.

=cut

sub set {
    my ($self, $name, $value) = @_;
    return unless defined $name;
    my $w = ./_widget_from_name($name);
    if (!defined $w) {
        print STDERR "$.Class - set called with unknown name ($name)\n";
        return;
    }
    my $vref = ./vref($w);
    $$vref = $value if defined $vref;
    unless (ref($w) eq 'Tk::Radiobutton' || ref($w) eq 'Tk::Checkbutton') {
        $vref = $.textvars{$w};
        $$vref = $value if defined $vref;
    }
}

sub _widget_from_name {
    my ($self, $name) = @_;
    return $.name{$name};
}

=head2 B<widget>

  $widget = $gui->widget($name);

Access the widget equated with the specified name.

=cut

sub widget {
    my ($self, $name) = @_;
    return ./_widget_from_name($name);
}

=head2 B<query_by_name>

  $result = $gui->query_by_name($name, %opts);

%opts can be:

  as_indices - if named widget being queried is Listbox, return
               selected entries as indices vs. selected text

$result will be an array reference for a Listbox. Even if only a single
entry is selected in your list.

=cut

sub query_by_name {
    my ($self, $name, %opts) = @_;
    my $w = $.name{$name};
    #print ref($w), "\n";
    my $as_indices = $opts{as_indices};
    if (ref($w) eq 'Tk::Listbox') {
        my @sel = $w->curselection;
        return \@sel if defined $as_indices && $as_indices != 0;
        map {
            $_ = $w->get($_);
        } @sel;
        return \@sel;
    }
    my $vref;
    $vref = $.vars{$w};
    $vref = $.textvars{$w} unless defined $vref;
    return defined $vref ? $$vref : undef;
}

=head2 B<as_hash>

  %hash = $gui->as_hash(%opts);

Fetch the entire contents of the GUI as a hash. This is your
specified name as the key, and the value is the dereferenced
variable reference maintained internally. For a Listbox, the
setting would be an array reference to the textual entries from
the Listbox (not indices) by default.

%opts can be:

  as_indices - return Listbox contents as indices, not text

=cut

sub as_hash {
    my ($self, %opts) = @_;
    my @names = ./names();
    my %result;
    map {
        my $result = ./query_by_name($_, %opts);
        $result{$_} = $result;
    } @names;
    return %result;
}

1;
=head1 AUTHOR

X Cramps, C<< <cramps.the at gmail.com> >>

=head1 BUGS

There are undoubtedly widgets I am not dealing with properly
here. Let me know what they are, and I'll see about adding code
to handle them properly (if possible).

Please report any bugs or feature requests to 
C<bug-tkutil-gui at rt.cpan.org>, or through
the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=TkUtil-Gui>.  
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc TkUtil::Gui


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=TkUtil-Gui>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/TkUtil-Gui>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/TkUtil-Gui>

=item * Search CPAN

L<http://search.cpan.org/dist/TkUtil-Gui/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 X Cramps, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of TkUtil::Gui
