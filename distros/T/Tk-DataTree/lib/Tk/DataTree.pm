################################################################################
#
# MODULE: Tk::DataTree
#
################################################################################
#
# DESCRIPTION: Tk::DataTree Perl extension module
#
################################################################################
#
# $Project: /Tk-DataTree $
# $Author: mhx $
# $Date: 2008/01/11 00:18:49 +0100 $
# $Revision: 10 $
# $Snapshot: /Tk-DataTree/0.06 $
# $Source: /lib/Tk/DataTree.pm $
#
################################################################################
#
# Copyright (c) 2004-2008 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################

package Tk::DataTree;

use strict;
use vars qw($VERSION);

BEGIN {
  $VERSION = do { my @r = '$Snapshot: /Tk-DataTree/0.06 $' =~ /(\d+\.\d+(?:_\d+)?)/; @r ? $r[0] : '9.99' };
  eval {
    local $ENV{PERL_DL_NONLAZY} = 0 if $ENV{PERL_DL_NONLAZY};
    require DynaLoader;
    local @Tk::DataTree::ISA = qw(DynaLoader);
    bootstrap Tk::DataTree $VERSION;
  };

  # use a rather simple approximation if we don't have the XS...
  $@ and *_getval = sub { $_[0] };
}

use Tk;
use Tk::ItemStyle;
use Tk::widgets qw(Tree);
use base qw(Tk::Tree);
use constant ROOTTYPE => 'TYPE';

Construct Tk::Widget 'DataTree';

my %ICON = (
  file => <<'FILE',
/* XPM */
static char *file[] = {
/* width height num_colors chars_per_pixel */
"    17    18       17            1",
/* colors */
"  c None",
". c #000000",
"# c #808080",
"a c #800000",
"b c #808000",
"c c #008000",
"d c #008080",
"e c #000080",
"f c #800080",
"g c #ffffff",
"h c #c0c0c0",
"i c #ff0000",
"j c #ffff00",
"k c #00ff00",
"l c #00ffff",
"m c #0000ff",
"n c #ff00ff",
/* pixels */
"                 ",
"    . . . . .    ",
"   .g#g#g#g#g.   ",
"  #g.g.g.g.g.g.  ",
"  #ggggggggggh.  ",
"  #ggggggggggh.  ",
"  #gg...g..ggh.  ",
"  #ggggggggggh.  ",
"  #gg......ggh.  ",
"  #ggggggggggh.  ",
"  #gg......ggh.  ",
"  #ggggggggggh.  ",
"  #gg......ggh.  ",
"  #ggggggggggh.  ",
"  #ggggggggggh.  ",
"  #hhhhhhhhhhh.  ",
"   ...........   ",
"                 "
};
FILE

  folder => <<'FOLDER',
/* XPM */
static char *folder[] = {
/* width height num_colors chars_per_pixel */
"    17    15       17            1",
/* colors */
"  c none",
". c #000000",
"# c #808080",
"a c #800000",
"b c #808000",
"c c #008000",
"d c #008080",
"e c #000080",
"f c #800080",
"g c #ffffff",
"h c #c0c0c0",
"i c #ff0000",
"j c #ffff00",
"k c #00ff00",
"l c #00ffff",
"m c #0000ff",
"n c #ff00ff",
/* pixels */
"                 ",
"   #####         ",
"  #hjhjh#        ",
" #hjhjhjh######  ",
" #gggggggggggg#. ",
" #gjhjhjhjhjhj#. ",
" #ghjhjhjhjhjh#. ",
" #gjhjhjhjhjhj#. ",
" #ghjhjhjhjhjh#. ",
" #gjhjhjhjhjhj#. ",
" #ghjhjhjhjhjh#. ",
" #gjhjhjhjhjhj#. ",
" ##############. ",
"  .............. ",
"                 ",
};
FOLDER
);

sub ClassInit
{
  my($class, $mw) = @_;
  $class->SUPER::ClassInit($mw);
  $mw->bind($class, '<Destroy>', 'Destroyer');
  return $class;
}

sub Populate
{
  my($self, $args) = @_;

  $args->{-selectmode} ||= 'none';
  $args->{-itemtype}   ||= 'imagetext';
  $args->{-separator}  ||= '/';

  $self->SUPER::Populate($args);

  for my $pix (keys %ICON) {
    $self->Pixmap($pix, data => $ICON{$pix});
  }

  for my $style (qw(node normal active undef)) {
    $self->{"_s$style"} = $self->ItemStyle('imagetext');
    $self->Advertise("${style}style" => $self->{"_s$style"});
  }

  $self->ConfigSpecs(
    '-data'        => ['METHOD', undef, undef, undef],
    '-typename'    => ['METHOD', undef, undef, undef],
    '-activecolor' => ['METHOD', undef, undef, '#FF0000'],
    '-undefcolor'  => ['METHOD', undef, undef, '#0080FF'],
  );
}

sub Destroyer
{
  my $self = shift;
  for my $style (qw(node normal active undef)) {
    $self->{"_s$style"}->delete;
  }
}

sub typename
{
  my($self, $val) = @_;
  if (@_ > 1) {
    if ($self->info('exists', ROOTTYPE) &&
        $self->itemCget(ROOTTYPE, 0, '-text') eq $self->{_oldtype}) {
      $self->itemConfigure(ROOTTYPE, 0, -text => $val);
    }
    $self->{_typename} = $val;
  }
  $self->{_typename};
}

sub activecolor
{
  my($self, $val) = @_;
  if (@_ > 1) {
    $self->{_sactive}->configure(-fg => $val);
  }
  $self->{_sactive}->cget('-fg');
}

sub undefcolor
{
  my($self, $val) = @_;
  if (@_ > 1) {
    $self->{_sundef}->configure(-fg => $val);
  }
  $self->{_sundef}->cget('-fg');
}

sub data
{
  my($self, $data) = @_;

  if (@_ > 1) {
    my $t = $self->{_typename} || (ref $data ? "$data" : ROOTTYPE);

    if (exists $self->{_old}) {
      $self->{_old} = $self->_cleanup(ROOTTYPE, $data, $self->{_old});
    }

    my $isnode = ref($data) =~ /^(?:ARRAY|HASH)$/;

    $self->info('exists', ROOTTYPE) or $self->add(ROOTTYPE);
    $self->itemConfigure(ROOTTYPE, 0, -text  => $t,
                                      -image => $isnode ? 'folder' : 'file',
                                      -style => $isnode ? $self->{_snode} : $self->{_snormal});

    $self->{_data}    = $data;
    $self->{_old}     = $self->_refresh(ROOTTYPE, $data, $self->{_old});
    $self->{_oldtype} = $t;
  }
  $self->{_data};
}

sub _cleanup
{
  my($self, $pre, $val, $old) = @_;

  my $r = ref $old;
  my $useval = $val && $r eq ref $val;

  if ($r eq 'HASH') {
    for my $k (keys %$old) {
      my $path = "$pre/$k";
      if ($useval && exists $val->{$k}) {
        if (ref $val->{$k} or ref $old->{$k}) {
          $old->{$k} = $self->_cleanup($path, $val->{$k}, $old->{$k});
        }
      }
      else {
        $self->delete('entry', $path);
        delete $old->{$k};
      }
    }
  }
  elsif ($r eq 'ARRAY') {
    for my $k (0 .. $#$old) {
      my $path = "$pre/$k";
      if ($useval && $k < @$val) {
        if (ref $val->[$k] or ref $old->[$k]) {
          $old->[$k] = $self->_cleanup($path, $val->[$k], $old->[$k]);
        }
      }
      else {
        $self->delete('entry', $path);
      }
    }
    if ($useval && @$val < @$old) {
      $#$old = $#$val;
    }
  }

  unless ($useval) {
    $self->delete( 'entry', $pre );
    return undef;
  }

  return $old;
}    
     
sub _refresh
{
  my($self, $pre, $val, $old, $key) = @_;

  my $r   = ref $val;
  my $req = $r eq ref $old;

  if ($r eq 'HASH') {
    while (my($k,$v) = each %$val) {
      my $o = $req ? $old->{$k} : undef;
      my $path = "$pre/$k";
      if (ref $v) {
        $self->info('exists', $path)
            or $self->add($path, -text => $k, -image => 'folder', -style => $self->{_snode});
      }
      $old->{$k} = $self->_refresh($path, $v, $o, $k);
    }
  }
  elsif ($r eq 'ARRAY') {
    for my $k (0 .. $#$val) {
      my $path = "$pre/$k";
      if (ref $val->[$k]) {
        $self->info('exists', $path)
            or $self->add($path, -text => "[$k]", -image => 'folder', -style => $self->{_snode});
      }
      $old->[$k] = $self->_refresh($path, $val->[$k], $req ? $old->[$k] : undef, "[$k]");
    }
  }
  else {
    my($v, $style);
    if (defined $val) {
      $v = _getval($val);
      $style = defined($old) && $v eq $old ? $self->{_snormal} : $self->{_sactive};
    }
    else {
      $v = '[undef]';
      $style = $self->{_sundef};
    }
    unless ($self->info('exists', $pre)) {
      $self->add($pre, -image => 'file');
    }
    $self->itemConfigure($pre, 0, -text => defined $key ? "$key: $v" : $v,
                                  -style => $style);
    $old = $v;
  }

  return $old;
}

1;

__END__

=head1 NAME

Tk::DataTree - A tree widget for arbitrary data structures

=head1 SYNOPSIS

  use Tk;
  use Tk::DataTree;
  
  $mw = new MainWindow;
  $dt = $mw->DataTree;
  
  $dt->data( { foo => 1, bar => [2, 3] } );

=head1 DESCRIPTION

The Tk::DataTree class is a derivate of L<Tk::Tree> intended
for displaying arbitrary data structures.
It's a bit like having L<Data::Dumper> as a Tk widget.

=head1 WIDGET-SPECIFIC OPTIONS

=over 4

=item B<-typename>

If the data structure is an array or hash, this is the
label of the root node.

=item B<-data>

Configuring this option is equivalent to calling
the C<data> method.

=item B<-activecolor>

The color that is used for changing (active) items. An item
is considered active if it is new or it has changed its
value since the last C<data> call.

=item B<-undefcolor>

The color that is used for items whose value is C<undef>.

=back

=head1 ADVERTISED WIDGETS

=over 4

=item B<nodestyle>

A C<Tk::ItemStyle> object that allows you to configure the
appearance of the node tree items.

=item B<normalstyle>

A C<Tk::ItemStyle> object that allows you to configure the
appearance of the normal tree items.

=item B<activestyle>

A C<Tk::ItemStyle> object that allows you to configure the
appearance of the active tree items.

=item B<undefstyle>

A C<Tk::ItemStyle> object that allows you to configure the
appearance of the undefined tree items.

=back

=head1 METHODS

=head2 data

The C<data> method is the core part of the class. Just
pass it any kind of perl data structure, and it will be
visualized in the tree. You can call C<data> multiple
times, and the tree will always be updated according to
the new data structure. Changing (active) values will be
highlighted with each C<data> call.

=head1 BUGS

I'm sure there are still lots of bugs in the code for this
module. If you find any bugs, Tk::DataTree doesn't seem to
build on your system or any of its tests fail, please
use the CPAN Request Tracker at L<http://rt.cpan.org/> to
create a ticket for the module. Alternatively, just send a
mail to E<lt>mhx@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright (c) 2004-2008 Marcus Holland-Moritz. All rights reserved.
This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

See L<Tk>, L<Tk::Tree>, L<Tk::DItem> and L<Data::Dumper>.

=cut

