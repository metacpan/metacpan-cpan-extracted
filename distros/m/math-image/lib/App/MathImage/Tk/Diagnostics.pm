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

package App::MathImage::Tk::Diagnostics;
use 5.008;
use strict;
use warnings;
use List::Util 'max';
use Tk;
use Tk::Balloon;
use Locale::TextDomain 1.19 ('App-MathImage');

# uncomment this to run the ### lines
#use Smart::Comments;

use base 'Tk::Derived', 'Tk::DialogBox';
Tk::Widget->Construct('AppMathImageTkDiagonostics');

our $VERSION = 110;

sub Populate {
  my ($self, $args) = @_;
  ### Diagnostics Populate() ...

  my $balloon = $self->Balloon;

  my $cname = __('Close');
  my $rname = __('Refresh');
  %$args = (-title => __('Math-Image: Diagnostics'),
            -buttons => [ $cname, $rname ],
            -cancel_button => $cname,
            %$args);
  $self->SUPER::Populate($args);

  {
    my $rbutton = $self->Subwidget("B_$rname");
    $rbutton->configure (-command => [ $self, 'refresh' ]);
  }
  {
    my $cbutton = $self->Subwidget("B_$cname");
    $cbutton->configure (-command => [ $self, 'withdraw' ]);
  }

  $self->Component('Label','label',
                   -text => __('Diagnostics'))
    ->pack;

  my $text = $self->Scrolled('Text',
                              -wrap   => 'word',
                              -width  => 60,
                              -height => 40);
  $self->Advertise (text => $text);
  $text->pack(-fill => 'both');
  $text->focus;

  #   # limit to 80% screen height
  #   my ($width, $height) = $self->get_default_size;
  #   $height = min ($height, 0.8 * $self->get_screen->get_height);
  #   $self->set_default_size ($width, $height);

  $self->refresh;
}

sub refresh {
  my ($self) = @_;
  ### Diagnostics refresh(): "$self"
  my $text = $self->Subwidget('text');

  $text->configure (-cursor => 'watch');
  $text->Contents ($self->str);
  $text->configure (-cursor => undef);
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

  if ($self) {
    my $main = $self->MainWindow;
    my $drawing = $main->Subwidget('drawing');
    if (my $gen_object = $drawing->{'gen_object'}) {
      $str .= $gen_object->diagnostic_str . "\n";
    } else {
      $str .= "No Generator object currently.\n\n";
    }
  } else {
    $str .= "No Main object.\n\n";
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
    my @modulenames = ('Tk',
                       'Tk::PNG',
                       'Tk::JPEG',
                       'Tk::TIFF',
                       'Devel::Arena',
                       # 'Devel::Mallinfo',
                       'Devel::StackTrace',
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

  # Full report is a bit too big:
  #   if (eval { require Module::Versions::Report; }) {
  #     $str .= Module::Versions::Report::report()
  #       . "\n";
  #   }

  if ($self) {
    my @images = $self->imageNames;
    $str .= "imageNames: count ".scalar(@images)."\n";
    @images = grep {! $_->image('inuse') } @images;
    $str .= "not in use: count ".scalar(@images);
    if (@images) {
      my %by_type;
      foreach my $image (@images) {
        $by_type{$image->type}++;
      }
      $str .= "  ("
        . join (', ', map {"$by_type{$_} $_"} sort keys %by_type)
          . ")";
    }
    $str .= "\n";
  }

  $str .= "\n";
  $str .= objects_report();

  if ($self) {
    $str .= "\n";
    $str .= $self->Xresource_report;
  }

  return $str;
}

sub objects_report {
  if (! eval { require Devel::FindBlessedRefs; 1 }) {
    return "(Devel::FindBlessedRefs -- module not available)\n";
  }
  my $str = "Tk widgets (Devel::FindBlessedRefs)\n";
  my %seen = ('Tk::Widget' => {},
             );
  Devel::FindBlessedRefs::find_refs_by_coderef
      (sub {
         my ($obj) = @_;
         my $class = Scalar::Util::blessed($obj) || return;
         ($obj->isa('Tk::Widget') || $obj->isa('Tk::Photo')) or return;
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

sub Xresource_report {
  my ($self) = @_;

  my $xid = $self->id
    || return "(X-Resource -- no window realized)\n";
  ### $xid
  $xid = oct($xid);  # undo leading hex "0x"
  ### $xid

  my $display_name = $self->screen
    || return "(X-Resource -- no \"screen()\" display)\n";
  ### $display_name
  eval { require X11::Protocol; 1 }
    || return "(X-Resource -- X11::Protocol module not available)\n";

  my $X = eval { X11::Protocol->new ($display_name) }
    || return "(X-Resource -- cannot connect to \"$display_name\": $@)\n";
  my $ret;
  if (! eval {
    if (! $X->init_extension ('X-Resource')) {
      $ret = "(X-Resource -- server doesn't have this extension\n";
    } else {
      $ret = "X-Resource server resources (X11::Protocol)\n";
      if (my @res = $X->XResourceQueryClientResources ($xid)) {
        my $count_width = 0;
        for (my $i = 1; $i <= $#res; $i++) {
          $count_width = max($count_width, length($res[$i]));
        }
        while (@res) {
          my $type_atom = shift @res;
          my $count = shift @res;
          $ret .= sprintf ("  %*d  %s\n",
                           $count_width,$count, $X->atom_name($type_atom));
        }
      } else {
        $ret = "  no resources in use\n";
      }
    }
    1;
  }) {
    (my $err = $@) =~ s/^/  /mg;
    $ret .= $err;
  }
  return $ret;
}

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

1;
__END__

# =for stopwords Ryde Tk
# 
# =head1 NAME
# 
# App::MathImage::Tk::Diagnostics -- math-image Tk diagnostics window
# 
# =head1 SYNOPSIS
# 
#  use App::MathImage::Tk::Diagnostics;
#  my $diagnostics = App::MathImage::Tk::Diagnostics->new ($parent_widget);
#  $diagnostics->Show;
# 
# =head1 CLASS HIERARCHY
# 
# C<App::MathImage::Tk::Diagnostics> is a subclass of C<Tk::Dialog>.
# 
#     Tk::Widget
#       Tk::Frame
#       Tk::Wm
#         Tk::TopLevel
#           Tk::DialogBox
#             Tk::Dialog
#               App::MathImage::Tk::Diagnostics
# 
# =head1 DESCRIPTION
# 
# This is the diagnostics dialog for the math-image program Tk interface.
# 
#     +---------------------------------------------+
#     |               Diagnostics                   |
#     +---------------------------------------------+
#     | +--+   Generator 1148x630                   |
#     | |  |   Values Math::NumSeq::Primes          |
#     | |--|   Path   Math::PlanePath::SquareSpiral |
#     | |  |   ...                                  |
#     | |  |                                        |
#     | |  |                                        |
#     | |  |                                        |
#     | +--+                                        |
#     +---------------------------------------------+
#     |           Close          Refresh            |
#     +---------------------------------------------+
# 
# =head1 FUNCTIONS
# 
# =over 4
# 
# =item C<< $main = App::MathImage::Tk::Diagnostics->new () >>
# 
# =item C<< $main = App::MathImage::Tk::Diagnostics->new ($parent) >>
# 
# Create and return a new diagnostics dialog.
# 
# The optional C<$parent> is per C<Tk::Dialog>.  Usually it should be the
# application main window.
# 
# =head1 SEE ALSO
# 
# L<App::MathImage::Tk::Main>,
# L<App::MathImage::Tk::About>
# L<math-image>,
# L<Tk>
# 
# =head1 HOME PAGE
# 
# L<http://user42.tuxfamily.org/math-image/index.html>
# 
# =head1 LICENSE
# 
# Copyright 2011, 2012, 2013 Kevin Ryde
# 
# Math-Image is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
# 
# Math-Image is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
# 
# You should have received a copy of the GNU General Public License along with
# Math-Image.  If not, see L<http://www.gnu.org/licenses/>.
# 
# =cut
