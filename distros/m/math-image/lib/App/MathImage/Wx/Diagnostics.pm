# Copyright 2011, 2012, 2013 Kevin Ryde

# This file is part of Math-Image.
#
# Math-Image is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-Image is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-Image.  If not, see <http://www.gnu.org/licenses/>.

package App::MathImage::Wx::Diagnostics;
use 5.008;
use strict;
use warnings;
use List::Util 'max';
use Wx;
use Locale::TextDomain ('App-MathImage');

# uncomment this to run the ### lines
#use Smart::Comments;

use base qw(Wx::Dialog);
our $VERSION = 110;

sub new {
  my ($class, $parent, $id) = @_;
  ### Diagnostics new() ...

  my $self = $class->SUPER::new ($parent,
                                 $id || Wx::wxID_ANY(),
                                 __('Math-Image: Diagonstics'),
                                 Wx::wxDefaultPosition(),
                                 Wx::wxDefaultSize(),
                                 Wx::wxDEFAULT_DIALOG_STYLE()
                                 | Wx::wxRESIZE_BORDER()
                                );
  my $topsizer = Wx::BoxSizer->new(Wx::wxVERTICAL());

  my $str = $self->str;
  my $text = $self->{'text'}
    = Wx::TextCtrl->new ($self,
                         Wx::wxID_ANY(),
                         $str,
                         Wx::wxDefaultPosition(),
                         Wx::wxDefaultSize(),
                         Wx::wxTE_MULTILINE() | Wx::wxTE_READONLY());
  $topsizer->Add ($text,
                  1, # yes vertical stretch
                  Wx::wxEXPAND() | Wx::wxALL());

  my $buttonsizer = $self->CreateButtonSizer(Wx::wxOK());
  {
    my $button = Wx::Button->new ($self, Wx::wxID_REFRESH());
    Wx::Event::EVT_BUTTON ($self, Wx::wxID_REFRESH(), 'refresh');
    $buttonsizer->Add ($button, 0, Wx::wxALIGN_CENTER());
  }
  $topsizer->Add ($buttonsizer,
                  0,  # no vertical stretch
                  Wx::wxALIGN_CENTER());

  $buttonsizer->Realize;
  $topsizer->SetSizeHints($self);

  textctrl_set_size_chars ($text, 60, 30);
  # $topsizer->Fit($self);

  ### text size: $text->GetSize->GetWidth
  ### text best: $text->GetBestSize->GetWidth
  ### topsizer: $topsizer->GetSize->GetWidth
  ### self size: $self->GetSize->GetWidth
  ### self best: $self->GetBestSize->GetWidth

  $self->SetSize ($self->GetBestSize);
  # $self->SetSize ($topsizer->GetSize);
  $self->SetSizer($topsizer);
  $text->SetFocus;

  # {
  #   my $timer = Wx::Timer->new ($self);
  #   $timer->Start (500);
  #   Wx::Event::EVT_TIMER($self,$timer,sub {
  #                          print "refresh\n";
  #                          $self->refresh;
  #                        });
  # }

  return $self;
}

sub refresh {
  my ($self) = @_;
  ### Diagnostics refresh(): "$self"
  my $busy = Wx::BusyCursor->new;
  textctrl_replace_text ($self->{'text'}, $self->str);
}

sub str {
    my ($class_or_self) = @_;
    my $self = ref $class_or_self ? $class_or_self : undef;
    ### Diagnostics str(): "$self"

    # mallinfo and mstats before loading other stuff, mallinfo first since
    # mstats is quite likely not available, and mallinfo first then avoids
    # counting Devel::Peek
    my $mallinfo;
    if (eval { require Devel::Mallinfo; }) {
      $mallinfo = Devel::Mallinfo::mallinfo();
    }

    # mstats_fillhash() croaks if no perl malloc in the running perl
    my %mstats;
    require Devel::Peek;
    ## no critic (RequireCheckingReturnValueOfEval)
    eval { Devel::Peek::mstats_fillhash(\%mstats) };
    ## use critic

    my $str = '';
    {
      my $main;
      if (! $self || ! ($main = $self->GetParent)) {
        $str .= "No Main object.\n\n";
      } elsif (! (my $drawing = $main->{'draw'})) {
        $str .= "Oops, no drawing object in Main.\n\n";
      } elsif (! (my $gen_object = $drawing->gen_object_maybe)) {
        $str .= "No Generator object currently.\n\n";
      } else {
        $str .= $gen_object->diagnostic_str . "\n";
      }
    }

    # if BSD::Resource available, only selected info bits
    if (eval { require BSD::Resource; }) {
      my ($usertime, $systemtime,
          $maxrss, $ixrss, $idrss, $isrss, $minflt, $majflt, $nswap,
          $inblock, $oublock, $msgsnd, $msgrcv,
          $nsignals, $nvcsw, $nivcsw)
        = BSD::Resource::getrusage ();
      $str .= "getrusage (BSD::Resource)\n";
      $str .= "  user time:      $usertime (seconds)\n";
      $str .= "  system time:    $systemtime (seconds)\n";
      # linux kernel 2.6.22 doesn't give memory info
      if ($maxrss) { $str .= "  max resident:   $maxrss\n"; }
      if ($ixrss)  { $str .= "  shared mem:     $ixrss\n"; }
      if ($idrss)  { $str .= "  unshared mem:   $idrss\n"; }
      if ($isrss)  { $str .= "  unshared stack: $isrss\n"; }
      # linux kernel 2.4 didn't count context switches
      if ($nvcsw)  { $str .= "  voluntary yields:   $nvcsw\n"; }
      if ($nivcsw) { $str .= "  involuntary yields: $nivcsw\n"; }
    }
    $str .= "\n";

    if ($mallinfo) {
      $str .= "mallinfo (Devel::Mallinfo)\n" . hash_format ($mallinfo);
    } else {
      $str .= "(Devel::Mallinfo not available.)\n";
    }
    $str .= "\n";

    if (%mstats) {
      $str .= "mstat (Devel::Peek)\n" . hash_format (\%mstats);
    } else {
      $str .= "(Devel::Peek -- no mstat() in this perl)\n";
    }

    if (eval { require Devel::Arena; }) {
      $str .= "\n";
      my $stats = Devel::Arena::sv_stats();
      my $magic = $stats->{'magic'};
      $stats->{'magic'}  # mung to reduce verbosity
        = scalar(keys %$magic) . ' total '
          . List::Util::sum (map {$magic->{$_}->{'total'}} keys %$magic);
      $str .= "SV stats (Devel::Arena)\n" . hash_format ($stats);

      my $shared = Devel::Arena::shared_string_table_effectiveness();
      $str .= "Shared string effectiveness:\n" . hash_format ($shared);
    } else {
      $str .= "(Devel::Arena -- module not available)\n";
    }

    if (eval { require Devel::SawAmpersand; }) {
      $str .= 'PL_sawampersand is '
        . (Devel::SawAmpersand::sawampersand()
           ? "true, which is bad!"
           : "false, good")
          . " (Devel::SawAmpersand)\n";
    } else {
      $str .= "(Devel::SawAmpersand -- module not available.)\n";
    }
    $str .= "\n";

    $str .= "Modules loaded: " . (scalar keys %INC) . "\n";
    {
      $str .= "Module versions:\n";
      my @modulenames = ('Wx',
                         # 'Devel::Arena',
                         # 'Devel::Mallinfo',
                         # 'Devel::StackTrace',
                        );
      my $width = max (map {length} @modulenames);
      $str .= sprintf ("  %-*s%s\n", $width+2, 'Perl', $^V);
      foreach my $modulename (@modulenames) {
        my $funcname;
        if (ref($modulename)) {
          ($modulename,$funcname) = @$modulename;
        }
        my $version = $modulename->VERSION;
        if (defined $version && defined $funcname) {
          my $func = $modulename->can($funcname);
          $version .= "\n" . ($func
                              ? "    and $funcname " . $func->()
                              : "    (no $funcname)");
        }
        if (defined $version) {
          $str .= sprintf ("  %-*s%s\n", $width+2, $modulename, $version);
        } else {
          $version = '(not loaded)';
        }
      }
    }

    $str .= "\n";
    $str .= objects_report();

    # if ($self) {
    #   $str .= "\n";
    #   $str .= $self->Xresource_report;
    # }

    return $str;
  }

sub objects_report {
  if (! eval { require Devel::FindBlessedRefs; 1 }) {
    return "(Devel::FindBlessedRefs -- module not available)\n";
  }
  my $str = "Wx widgets (Devel::FindBlessedRefs)\n";
  my %seen = ('Wx::Window' => {},
             );
  Devel::FindBlessedRefs::find_refs_by_coderef
      (sub {
         my ($obj) = @_;
         my $class = Scalar::Util::blessed($obj) || return;
         ($obj->isa('Wx::Widget')) or return;
         my $addr = Scalar::Util::refaddr ($obj);
         $seen{$class}->{$addr} = 1;
       });
  my @classes = sort keys %seen;
  my $traverse;
  $traverse = sub {
    my ($depth, $class_list) = @_;
    my @toplevels = grep {is_toplevel_class ($_,$class_list)} @$class_list;
    foreach my $class (@toplevels) {
      my $count = scalar keys %{$seen{$class}};
      $str .= sprintf "%*s%s %d\n", 2*$depth, '', $class, $count;
      my @subclasses = grep {$_ ne $class && $_->isa($class)} @$class_list;
      $traverse->($depth+1, \@subclasses);
    }
  };
  $traverse->(1, \@classes);
  return $str;
}

# sub Xresource_report {
#   my ($self) = @_;
# 
#   my $xid = $self->id
#     || return "(X-Resource -- no window realized)\n";
#   ### $xid
#   $xid = oct($xid);  # undo leading hex "0x"
#   ### $xid
# 
#   my $display_name = $self->screen
#     || return "(X-Resource -- no \"screen()\" display)\n";
#   ### $display_name
#   eval { require X11::Protocol; 1 }
#     || return "(X-Resource -- X11::Protocol module not available)\n";
# 
#   my $X = eval { X11::Protocol->new ($display_name) }
#     || return "(X-Resource -- cannot connect to \"$display_name\": $@)\n";
#   my $ret;
#   if (! eval {
#     if (! $X->init_extension ('X-Resource')) {
#       $ret = "(X-Resource -- server doesn't have this extension\n";
#     } else {
#       $ret = "X-Resource server resources (X11::Protocol)\n";
#       if (my @res = $X->XResourceQueryClientResources ($xid)) {
#         my $count_width = 0;
#         for (my $i = 1; $i <= $#res; $i++) {
#           $count_width = max($count_width, length($res[$i]));
#         }
#         while (@res) {
#           my $type_atom = shift @res;
#           my $count = shift @res;
#           $ret .= sprintf ("  %*d  %s\n",
#                            $count_width,$count, $X->atom_name($type_atom));
#         }
#       } else {
#         $ret = "  no resources in use\n";
#       }
#     }
#     1;
#   }) {
#     (my $err = $@) =~ s/^/  /mg;
#     $ret .= $err;
#   }
#   return $ret;
# }

#------------------------------------------------------------------------------
# generic helpers

# return true if $class is not a subclass of anything in $class_list (an
# arrayref)
sub is_toplevel_class {
  my ($class, $class_list) = @_;
  return ! List::Util::first {$class ne $_ && $class->isa($_)} @$class_list;
}

# return a string of the contents of a hash (passed as a hashref)
sub hash_format {
  my ($h) = @_;
  my $nf = number_formatter();
  ### nf: "$nf"

  require Scalar::Util;
  my %mung;
  foreach my $key (keys %$h) {
    my $value = $h->{$key};
    if (Scalar::Util::looks_like_number ($value)) {
      $mung{$key} = ($nf ?  $nf->format_number ($value) : $value);
    } elsif (ref ($_) && ref($_) eq 'HASH') {
      $mung{$key} = "subhash, " . scalar(keys %{$_}) . " keys";
    } else {
      $mung{$key} = $value;
    }
  }

  my $field_width = max (map {length} keys   %mung);
  my $value_width = max (map {length} values %mung);

  return join ('', map { sprintf ("  %-*s  %*s\n",
                                  $field_width, $_,
                                  $value_width, $mung{$_})
                       } sort keys %mung);
}

# force LC_NUMERIC to the locale, whereas perl normally runs with "C"
use constant::defer number_formatter => sub {
  ### number_formatter() ...
  eval { require Number::Format; 1 } || return undef;
  require POSIX;
  my $oldlocale = POSIX::setlocale(POSIX::LC_NUMERIC());
  POSIX::setlocale (POSIX::LC_NUMERIC(), "");
  my $nf = Number::Format->new;
  POSIX::setlocale (POSIX::LC_NUMERIC(), $oldlocale);
  return $nf;
};


#------------------------------------------------------------------------------
# Wx generic

# Set the size of $textctrl as a size in characters.

# Character size is reckoned by GetDefaultStyle if the platform has that
# method, or GetStyle at the end of the text otherwise.
sub textctrl_set_size_chars {
  my ($textctrl, $width, $height) = @_;
  $textctrl->SetSize (textctrl_calc_size_chars ($textctrl, $width, $height));

}
sub textctrl_calc_size_chars {
  my ($textctrl, $width, $height) = @_;

  my $attrs = ($textctrl->GetStyle($textctrl->GetLastPosition)
               || $textctrl->GetDefaultStyle);
  my $font = $attrs->GetFont;
  my $font_mm = $font->GetPointSize * (1/72 * 25.4);

  ### $font_mm
  ### xpixels: window_x_mm_to_pixels ($textctrl, $width * $font_mm * .8)
  ### ypixels: window_y_mm_to_pixels ($textctrl, $height * $font_mm)

  return (window_x_mm_to_pixels ($textctrl, $width * $font_mm * .8),
          window_y_mm_to_pixels ($textctrl, $height * $font_mm));
}

# Convert from millimetres to pixels in the X or Y direction.
# The size of a pixel is based on GetDisplaySizeMM() and GetDisplaySize().
sub window_x_mm_to_pixels {
  my ($window, $mm) = @_;
  my $size_pixels = Wx::GetDisplaySize();
  my $size_mm = Wx::GetDisplaySizeMM();
  return $mm * $size_pixels->GetWidth / $size_mm->GetWidth;
}
sub window_y_mm_to_pixels {
  my ($window, $mm) = @_;
  my $size_pixels = Wx::GetDisplaySize();
  my $size_mm = Wx::GetDisplaySizeMM();
  return $mm * $size_pixels->GetHeight / $size_mm->GetHeight;
}

# Replace the contents of $textctrl with $str.
# The position of the insertion point and the window scroll position are
# saved by row+column.
sub textctrl_replace_text {
  my ($textctrl, $str) = @_;

  my ($result, $win_x,$win_y)
    = ($textctrl->can('HitTest') && $textctrl->HitTest(Wx::Point->new(0,0)));
  ### $result
  ### $win_x
  ### $win_y
  # cf $result == Wx::wxTE_HT_UNKNOWN() if HitTest not implemented

  my ($ins_x, $ins_y) = $textctrl->PositionToXY ($textctrl->GetInsertionPoint);
  $textctrl->SetValue ($str);

  if ($win_y) {
    $textctrl->ShowPosition ($textctrl->GetLastPosition);
    $textctrl->ShowPosition ($textctrl->XYToPosition($win_x,$win_y));
  }
  $textctrl->SetInsertionPoint ($textctrl->XYToPosition($ins_x,$ins_y))
}

1;
__END__
