package Wx::Perl::DataWalker::CurrentLevel;
use 5.008001;
use strict;
use warnings;

use Scalar::Util qw(blessed reftype weaken);
use Wx;

our $VERSION = '0.01';
our @ISA = qw(Wx::ListCtrl);

use constant {
  DISPLAY_UNINITIALIZED => 0,
  DISPLAY_SCALAR        => 1,
  DISPLAY_ARRAY         => 2,
  DISPLAY_HASH          => 3,
  DISPLAY_GLOB          => 4,
};

use constant GLOB_THINGS => [qw(NAME PACKAGE SCALAR ARRAY HASH CODE IO GLOB FORMAT)];

use Class::XSAccessor
  getters => {
    parent => 'parent',
  },
  accessors => {
    show_size       => 'show_size',
    show_recur_size => 'show_recur_size',
  };

require overload;

sub new {
  my $class = shift;
  my ($parent, $id, $pos, $size) = @_;
  my $self = $class->SUPER::new(
    $parent, $id, $pos||Wx::wxDefaultPosition, $size||Wx::wxDefaultSize, Wx::wxLC_REPORT|Wx::wxLC_VIRTUAL
  );
  $self->{parent} = $parent;
  weaken($self->{parent});

  # Double-click a function name
  Wx::Event::EVT_LIST_ITEM_ACTIVATED( $self, $self,
    sub {
      $self->on_list_item_activated($_[1]);
    }
  );
 
  my $imglist = $self->get_icon_list();
  $self->AssignImageList($imglist, Wx::wxIMAGE_LIST_SMALL);

  $self->{show_size} = 0;
  $self->{show_recur_size} = 0;
  $self->{display_mode} = DISPLAY_UNINITIALIZED;
  $self->set_data('');

  return $self;
}

sub refresh {
  my $self = shift;
  $self->set_data($self->{data});
}

sub set_data {
  my $self = shift;
  my $data = shift;

  my $reftype = reftype($data);
  return() if defined $reftype and $reftype eq 'CODE';
  
  $self->{data} = $data;
  delete $self->{hash_cache};

  if (!$reftype) {
    $self->_set_scalar();
  }
  elsif ($reftype eq 'HASH') {
    $self->_set_hash();
  }
  elsif ($reftype eq 'ARRAY') {
    $self->_set_array();
  }
  elsif ($reftype eq 'GLOB') {
    $self->_set_glob();
  }
  else {
    $self->_set_scalar();
  }

  $self->_set_width;
  return(1);
}

#####################################
# display methods

sub OnGetItemText {
  my $self = shift;
  my $itemno = shift;
  my $colno  = shift;
  my $data = $self->{data};

  if ($self->{display_mode} == DISPLAY_SCALAR) {
    $colno == 0 and return reftype($data)||'';
    $colno == 1 and return blessed($data)||'';
    $colno == 2 and $self->show_size() and return $self->calc_size($$data);
    return defined($$data) ? overload::StrVal($$data) : 'undef';
  }
  elsif ($self->{display_mode} == DISPLAY_ARRAY) {
    $colno == 0 and return $itemno;
    my $item = $data->[$itemno];
    $colno == 1 and return reftype($item)||'';
    $colno == 2 and return blessed($item)||'';
    $colno == 3 and $self->show_size() and return $self->calc_size($item);
    return defined($item) ? overload::StrVal($item) : 'undef';
  }
  elsif ($self->{display_mode} == DISPLAY_HASH) {
    my $key = $self->{hash_cache}[$itemno];
    $colno == 0 and return $key;
    my $item = $data->{$key};
    $colno == 1 and return reftype($item)||'';
    $colno == 2 and return blessed($item)||'';
    $colno == 3 and $self->show_size() and return $self->calc_size($item);
    return defined($item) ? overload::StrVal($item) : 'undef';
  }
  elsif ($self->{display_mode} == DISPLAY_GLOB) {
    $colno == 0 and return GLOB_THINGS->[$itemno];
    my $item = *{$data}{GLOB_THINGS->[$itemno]};
    $colno == 1 and return reftype($item)||'';
    $colno == 2 and return blessed($item)||'';
    $colno == 3 and $self->show_size() and return $self->calc_size($item);
    return defined($item) ? overload::StrVal($item) : 'undef';
  }

}


{
  # this is an optimization explicitly allowed according to the wx docs.
  my $undef_attr = Wx::ListItemAttr->new();
  $undef_attr->SetTextColour(Wx::Colour->new("gray"));

  sub OnGetItemAttr {
    my $self = shift;
    my $itemno = shift;
    my $data = $self->{data};

    # colour the undef's gray!
    if ($self->{display_mode} == DISPLAY_SCALAR) {
      return defined($$data) ? undef : $undef_attr;
    }
    elsif ($self->{display_mode} == DISPLAY_ARRAY) {
      my $item = $data->[$itemno];
      return defined($item) ? undef : $undef_attr;
    }
    elsif ($self->{display_mode} == DISPLAY_HASH) {
      my $key = $self->{hash_cache}[$itemno];
      my $item = $data->{$key};
      return defined($item) ? undef : $undef_attr;
    }
    elsif ($self->{display_mode} == DISPLAY_GLOB) {
      my $item = *{$data}{GLOB_THINGS->[$itemno]};
      return defined($item) ? undef : $undef_attr;
    }
  }
}


sub OnGetItemImage {
  my $self = shift;
  my $itemno = shift;
  my $data = $self->{data};

  if ($self->{display_mode} == DISPLAY_SCALAR) {
    return $self->ref_to_icon(reftype($$data));
  }
  elsif ($self->{display_mode} == DISPLAY_ARRAY) {
    my $item = $data->[$itemno];
    return $self->ref_to_icon(reftype($item));
  }
  elsif ($self->{display_mode} == DISPLAY_HASH) {
    my $key = $self->{hash_cache}[$itemno];
    my $item = $data->{$key};
    return $self->ref_to_icon(reftype($item));
  }
  elsif ($self->{display_mode} == DISPLAY_GLOB) {
    my $item = *{$data}{GLOB_THINGS->[$itemno]};
    return $self->ref_to_icon(reftype($item));
  }
  return(-1);
}


sub calc_size {
  my $self = shift;
  my $data = shift;

  return(
    $self->show_recur_size() ? Devel::Size::total_size(\$data) : Devel::Size::size($data)
  );
}

######################
# setup the display data type

sub _set_scalar {
  my $self = shift;
  $self->{display_mode} = DISPLAY_SCALAR;
  $self->ClearAll();
  $self->SetItemCount(1);

  # reverse insert for extensibility
  $self->InsertColumn(0, "Value");
  $self->InsertColumn(0, "Size") if $self->show_size();
  $self->InsertColumn(0, "Class");
  $self->InsertColumn(0, "RefType");
  return();
}

sub _set_hash {
  my $self = shift;
  
  $self->{display_mode} = DISPLAY_HASH;
  $self->ClearAll();
  $self->SetItemCount(scalar keys %{$self->{data}});
  $self->{hash_cache} = [sort keys %{$self->{data}}];
  $self->InsertColumn(0, "Value");
  $self->InsertColumn(0, "Size") if $self->show_size();
  $self->InsertColumn(0, "Class");
  $self->InsertColumn(0, "RefType");
  $self->InsertColumn(0, "Key");
  return();
}

sub _set_array {
  my $self = shift;

  $self->{display_mode} = DISPLAY_ARRAY;
  $self->ClearAll();
  $self->SetItemCount(scalar @{$self->{data}});
  $self->InsertColumn(0, "Value");
  $self->InsertColumn(0, "Size") if $self->show_size();
  $self->InsertColumn(0, "Class");
  $self->InsertColumn(0, "RefType");
  $self->InsertColumn(0, "Index");
  return();
}


sub _set_glob {
  my $self = shift;
  $self->{display_mode} = DISPLAY_GLOB;
  $self->ClearAll();
  $self->SetItemCount(scalar @{GLOB_THINGS()});
  $self->InsertColumn(0, "Value");
  $self->InsertColumn(0, "Size") if $self->show_size();
  $self->InsertColumn(0, "Class");
  $self->InsertColumn(0, "RefType");
  $self->InsertColumn(0, "THING");
  return();
}


sub _set_width {
  my $self = shift;
# Can't work in virtual mode...
#  foreach my $col (0..$cols-1) {
#    $self->SetColumnWidth( $col, Wx::wxLIST_AUTOSIZE );
#    $self->SetColumnWidth( $col, 70 ) if $self->GetColumnWidth( $col ) < 70;
#  }
  
  my $widths;
  my $size = $self->show_size();
  for ($self->{display_mode}) {
    if ($_ == DISPLAY_SCALAR) {
      $widths = [80, 90, $size?(100):(), 200];
    }
    elsif ($_ == DISPLAY_ARRAY) {
      my $chars = length(scalar(@{$self->{data}}));
      $chars = 6 if $chars < 6;
      $widths = [$chars*11, 80, 90, $size?(100):(), 200];
    }
    elsif ($_ == DISPLAY_HASH) {
      $widths = [100, 80, 90, $size?(100):(), 200];
    }
    elsif ($_ == DISPLAY_GLOB) {
      $widths = [100, 80, 90, $size?(100):(), 200];
    }
  }
  return() unless $widths;

  my $cols = $self->GetColumnCount();
  foreach my $col (0..$cols-1) {
    $self->SetColumnWidth( $col, $widths->[$col] );
  }
  
}



###################################
# event handlers

sub on_list_item_activated {
  my $self = shift;
  my $event = shift;

  my $row  = $event->GetIndex();
  #my $col  = $event->GetColumn();

  my $key;
  for ($self->{display_mode}) {
    $_ == DISPLAY_SCALAR and $key = undef, last;
    $_ == DISPLAY_ARRAY  and $key = $row, last;
    $_ == DISPLAY_HASH   and $key = $self->{hash_cache}[$row], last;
    $_ == DISPLAY_GLOB   and $key = GLOB_THINGS->[$row], last;
  }

  $self->parent->go_down($key);
}


###################################
# icon storage

{
  my %icons = (
    'array' => <<'HERE',
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAAZiS0dEAP8A
/wD/oL2nkwAAAU1JREFUOMud0z1IllEYxvGfJPU2CE2FVENEFKQRGURbW7MEOjs1RGs01iBRi63R
GO2tJUpTS1FDGBGCS5EfQ4RU9qFXy20d5PUtvOAM5zrX+Z/7fs552KJwLNwJL8Nq+BWWwnS4GgZ0
U9gT7taG9BjL4dLWzZ0wU4Gf4X64EPaF3eFQGA+zDehyC7hX5ocwoofCRFX5IwwJZ8JGWAun/IfC
jTrwQXv6VBM4HubCSji/WXazfrC8ReFdTUaawOOm1xddAJ3yvgnfa9JpAl/LOxvOdQGMl/eqH33l
79qm5fVm436M4VZZt4WFop1ugtNNC8+7vIUv4cpm+GGZkw3gRHgTFusjroX3Bb4eBtsruViA1XDU
ThSeFORtOLITwIEwX5DP4WYYDntrDIVr4XU4uR1kMDz9x4/0LBzuVUlfGA2PwsewHj7VwxrL3yv/
o99l+f7MpBeL2gAAAABJRU5ErkJggg==
HERE
    'scalar' => <<'HERE',
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAAZiS0dEAP8A
/wD/oL2nkwAAAMlJREFUOMulkysOwkAURU+LxIADjWMBSBy2LAAP1SwAywZIMKwC2SBI2AACNB9P
QoIAEpKLeU0qWmZKJ3mZN5m5531mBhxDoF/7IRVHWBB1KNgI7rZ+CNaCAR4pxwIVmQ/gaodXgrb5
TUEkSHwAbxM1fJqYB9ga4CiYm98VBL6AjmCfU/9ZMPaFBIK+YGbiUwY0LVuSbJ6kmfwLqBvg4xLs
BCNBKwXYdS7NvzgjZuyV08zYBegJFoKD4GmimyARRGXrr1X9jc5X+AVi1ZMjWoXKsgAAAABJRU5E
rkJggg==
HERE
    'hash' => <<'HERE',
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAAZiS0dEAP8A
/wD/oL2nkwAAAOtJREFUOMvNk7FqAlEQRU8iWW20sEm37NcIgn+hEfINC1aBZbEUY8g/CP6OiE3U
TohbJ3DT3MBj2V0tfdV9M+8OM4d5cBdHEAneBRfBt2AheCq9GQm2gqiqQCaQ4EXwav0W5DuCvWBQ
18HBpr7g2foryM8E66YRfm16ELSsf5xLBGdB3FTgFHTQtz46txGk1yDObRoLJta5YCjYCbqCpQFf
DDyiBOlTUPjBStCzeViCPLXOrnWVCjYVkP9HPDSZY4NLKiA/hpDrCqwFs+B+vLkDwcBL0wlieRXk
upXeCkaleFvwYciFdfs+PuIfzS2y8qBa0XcAAAAASUVORK5CYII=
HERE
    'code' => <<'HERE',
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAAZiS0dEAP8A
/wD/oL2nkwAAAOlJREFUOMvNk61OQ0EYRE8ABalAFIcAUxJwON4ARQIKAQ7NO+BBIkgwBFLZpL7B
oRBIRA0IDA0YuOEvHMyImyb3plR13Tc7czY72YWJW8K8cC4MhE/hRtj6D6ArKBwJc8KO8DFqeEb4
CmC2pO+NClhKWGF73A4eAngRVsYpsBD6gTwKi0Oeb+GpCnCS4HKpzHuhmf0p4Ue4rAIMEppOoe3M
t0JDWM28UQUoYmiUTjyLdi1cCFd1HfRi3h3Sj6MXwkIdYF14F56FzVyjKRxG/xXuhFYdZE3oCK95
VH3hVGgJB4G8CfuT8fn+ANlvk1fzzFNCAAAAAElFTkSuQmCC
HERE
    'glob' => <<'HERE',
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAAZiS0dEAP8A
/wD/oL2nkwAAAKFJREFUOMvN0k1OAlEQBODvifE+spnhOh7DxJXEJazhRKBbuAPhCMaZcvMWhAw/
xgX0rrrS3VWV5u4r5Bz/8N8Dj0fXpvjBR+F7QM0TXjEqvA3JXYY+bEJzaCE0td+H5TnPk/AVujAL
CfOKP0N7TXAlvIRdXbCruPwlxFzAJ6faKrWr0q+3cCHENmwrvzhlYY93jAvrQ6KwwnPl9/fzibev
X+/lWAPE64K3AAAAAElFTkSuQmCC
HERE
    'empty' => <<'HERE',
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAAZiS0dEAP8A
/wD/oL2nkwAAABJJREFUOMtjYBgFo2AUjAIIAAAEEAABhT+qcgAAAABJRU5ErkJggg==
HERE
  );

  my %ref_to_icon = (
    qw(
      SCALAR 1
      ARRAY 2
      HASH 3
      CODE 4
      GLOB 5
      REF 1
    )
  );

  sub get_icon_list {
    my $self = shift;
    _icons_to_objects();

    my $imglist = Wx::ImageList->new(16, 16, 0, 0);

    $imglist->Add( $icons{$_} ) foreach qw(empty scalar array hash code glob);

    return $imglist;
  }

  sub ref_to_icon {
    my $self = shift;
    my $reftype = shift;
    return(0) if not $reftype;
    my $icon_no = $ref_to_icon{$reftype};
    return defined($icon_no) ? $icon_no : 0;
  }
  
  sub _icons_to_objects {
    return if !values(%icons) or ref((values %icons)[0]);

    require MIME::Base64;
    my $handler = Wx::PNGHandler->new();
    Wx::Image::AddHandler($handler);
    foreach my $icon_name (keys %icons) {
      my $str = MIME::Base64::decode_base64($icons{$icon_name});
      open my $fh, '<', \$str or die $!;
      my $img = Wx::Image->new($fh, Wx::wxBITMAP_TYPE_PNG);
      close $fh;
      $icons{$icon_name} = Wx::Bitmap->new($img);
    }
  }
}

1;
__END__

