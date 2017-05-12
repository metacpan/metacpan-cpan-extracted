=head1 NAME

Test::Glade - a simple way to test Gtk2::GladeXML-based apps

=head1 SYNOPSIS

  use Test::Glade tests => 2;

  my $glade_xml = 'interface.glade';
  has_widget( $glade_xml, {
    name => 'main_window',
    type => 'GtkWindow',
    properties => {
      title => 'Test Application',
      type => 'GTK_WINDOW_TOPLEVEL',
      resizable => 1,
    },
  } );

  has_widget( $glade_xml, {
    type => 'GtkButton',
    properties => {label => 'Press me!'},
    signals => {clicked => 'button_pressed_handler'},
  } );

=head1 DESCRIPTION

GUIs are notoriously difficult to test.  Historically this was well deserved
as the available perl GUI toolkits did not encourage separation of the view
and controller layers.  The introduction of the Glade GUI designer and
Gtk2::GladeXML changed that by segregating user interface and logical
components (into GladeXML and Perl files respectively).

Users who avoid creating GUI elements from within their application logic can
now test each layer separately with appropriate tools.  The Perl logic can be
verified with standard unit tests and this module provides a way to inspect
and verify the GladeXML UI specification.  You can confirm that a given widget
exists, that it has the correct label and other attributes, that it will be
correctly placed in the interface and that it will respond to signals
as expected.

=head1 TEST METHODS

=over 4

=item has_widget($glade_file, $widget_desc, $test_name)

Search for a widget in a GladeXML file.  $widget is a hash reference of
widget attributes.  See L<WIDGET DESCRIPTION> for more information.

=back

=head1 OO METHODS

If you have large GladeXML files, or want to perform many tests on each one,
it might be faster to use the object oriented interface.  Files are only parsed
once, instead of once for each test.

=over 4

=item Test::Glade->new(file => $gladexml_file)

Create a new Test::Glade object, passing in an optional GladeXML file.

=item $test->load($gladexml_file)

Load in a new GladeXML file.

=item $test->widgets

Return a list of all widgets in the file.  See L<WIDGET METHODS> for more
information.

=item $test->find_widget($widget_desc)

Find and return widget.  Takes $widget_desc in the same format as has_widget().

=back

=head1 WIDGET DESCRIPTION

=over 4

=item name, type

Scalars

=item properties

A hashref containing other widget properties, name => value

=item signals

A hashref of registered signal handlers, signal name => handler

=item packing

A hashref of packing attributes, name => value

=item children

A listref of child widgets

=back

=head1 WIDGET METHODS

=over 4

=item name, type, properties, children, signals, packing

See the widget description section for return values.

=back

=head1 AUTHORS

Nate Mueller <nate@cs.wisc.edu>

=cut

package Test::Glade::Obj;

use strict;
use warnings;
use Data::Dumper;

sub new {
  my ($class, %args) = @_;

  my $self = bless {%args}, $class;
  $self->init if $self->can('init');
  return $self;
}
  
our $AUTOLOAD;
sub AUTOLOAD {
  my ($self) = @_;
  my ($method) = $AUTOLOAD =~ /([^:]+)$/;
  if ($method =~ /^_/ or not exists $self->{$method}) {
    my @caller = caller(0);
    die "No such method: $AUTOLOAD at $caller[1] line $caller[2]\n"
  } else {
    return $self->{$method};
  }
}

sub DESTROY { }

package Test::Glade;

our $VERSION = 1;

use strict;
use warnings;
use base qw(Test::Glade::Obj Exporter);

use XML::Parser;
use Test::Builder;

my $test = Test::Builder->new;
our @EXPORT = qw(has_widget);

sub import {
  my ($self, @plan) = @_;
  my $pack = caller;

  $test->exported_to($pack);
  $test->plan(@plan);

  $self->export_to_level(1, $self, @EXPORT);
}

sub init {
  my ($self) = @_;
  $self->load($self->{file}) if $self->{file};
}

sub load {
  my ($self, $file) = @_;
  $self->{file} = $file;
  my $parser = XML::Parser->new(Handlers => {
    Init => sub { $_[0]->{self} = $self },
    Start => \&_parse_start,
    End => \&_parse_end,
    Char => \&_parse_char,
  });
  $parser->parsefile($self->file);
}

sub widgets {
  my ($self) = @_;
  return values %{$self->{widgets}};
}

sub find_widget {
  my ($self, $args) = @_;

  foreach my $widget ($self->widgets) {
    return $widget if match($widget, $args);
  }
  return undef;
}

sub has_widget {
  my ($file, $args, $name) = @_;
  $name ||= "has $args->{name}" if $args->{name};

  my $t = Test::Glade->new(file => $file);
  $test->ok($t->find_widget($args), $name);
}

sub match {
  my ($a, $b) = @_;

  if (ref $b eq 'ARRAY') {
    return 0 unless ref $a eq 'ARRAY';
    foreach my $element (@$b) {
      return 0 unless grep { match($_, $element) } @$a;
    }
  } elsif (ref $b eq 'HASH') {
    return 0 unless ref $a eq 'HASH' || ref $a eq 'Test::Glade::Obj';
    foreach my $key (keys %$b) {
      return 0 unless exists $a->{$key};
      return 0 unless match($a->{$key}, $b->{$key});
    }
  } else {
    return 0 unless $a eq $b;
  }
  return 1;
}
  
sub _parse_start {
  my ($expat, $tag, %args) = @_;
  my $self = $expat->{self};

  if ($tag eq 'widget') {
    $self->{widgets}{$args{id}} = Test::Glade::Obj->new(
      type => $args{class},
      name => $args{id},
      properties => {},
      children => [],
      packing => {},
      signals => {},
    );
    push @{$self->{_active_widgets}}, $args{id};
  } elsif ($tag eq 'property') {
    $self->{_active_property} = $args{name};
  } elsif ($tag eq 'packing') {
    $self->{_packing} = 1;
  } elsif ($tag eq 'signal') {
    $self->{widgets}{$self->{_active_widgets}[-1]}{signals}{$args{name}} =
      $args{handler};
  }
}

sub _parse_end {
  my ($expat, $tag) = @_;
  my $self = $expat->{self};

  if ($tag eq 'property') {
    delete $self->{_active_property};
  } elsif ($tag eq 'child') {
    my $widget = $self->{widgets}{$self->{_active_widgets}[-1]};
    my $parent = $self->{widgets}{$self->{_active_widgets}[-2]};
    push @{$parent->{children}}, $widget;
    pop @{$self->{_active_widgets}}; 
  } elsif ($tag eq 'packing') {
    delete $self->{_packing};
  }
}

sub _parse_char {
  my ($expat, $char) = @_;
  my $self = $expat->{self};
  return unless $char =~ /\S/;
  return unless $self->{_active_property};
  return unless $self->{_active_widgets}[-1];

  if ($char eq 'False') { $char = 0 }
  elsif ($char eq 'True') { $char = 1 }

  $self->{widgets}
    {$self->{_active_widgets}[-1]}
      {$self->{_packing} ? 'packing' : 'properties'}
        {$self->{_active_property}} = $char;
}

1;
