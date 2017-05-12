#!/usr/bin/perl -w

# Copyright 2012, 2013, 2014 Kevin Ryde

# This file is part of Wx-Perl-PodBrowser.
#
# Wx-Perl-PodBrowser is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Wx-Perl-PodBrowser is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Wx-Perl-PodBrowser.  If not, see <http://www.gnu.org/licenses/>.


use 5.008;
use strict;
use Wx;
use Wx::Perl::PodRichText;

# uncomment this to run the ### lines
# use Smart::Comments;



{
  my $app = Wx::SimpleApp->new;
  my $frame = Wx::Dialog->new (undef,  # parent
                               Wx::wxID_ANY(),
                               'Index',
                               Wx::wxDefaultPosition(),
                               Wx::wxDefaultSize(),
                               (Wx::wxRESIZE_BORDER()
                                | Wx::wxSYSTEM_MENU()
                                | Wx::wxCLOSE_BOX())
                              );

  my $vert_sizer = Wx::BoxSizer->new (Wx::wxVERTICAL());

  my $list = Wx::ListView->new($frame,
                               Wx::wxID_ANY(),
                               Wx::wxDefaultPosition(),
                               Wx::wxDefaultSize(),
                               (Wx::wxLC_REPORT() | Wx::wxLC_SINGLE_SEL()));
  Wx::Event::EVT_LIST_ITEM_ACTIVATED($list, $list, sub {
                                       my ($list, $event) = @_;
                                       my $index = $event->GetIndex;
                                       print "activate index=$index\n";
                                     });
  $vert_sizer->Add ($list, 1, Wx::wxGROW(), 0);

  my @names = ( "Cheese", "apples 10", "Apples 1", "Oranges" );

  my @index;
  foreach my $i ( 0 .. 50 ) {
    my $t = (rand() * 100) % scalar(@names);
    my $position = int( rand() * 1000 );
    my $name = $names[$t];
    push @index, { name        => $name,
                   line_number => int($position / 10),
                   position    => $position,
                 };
  }

  $list->InsertColumn(0, 'Index');
  $list->InsertColumn(1, 'Line', Wx::wxLIST_FORMAT_RIGHT() | Wx::wxGROW());

  my $fill = sub {
    my ($by_position) = @_;
    if ($by_position) {
      @index = sort {$a->{'position'} <=> $b->{'position'} } @index;
    } else {
      my $cmp = eval { require Sort::Naturally; 1 }
        ? \&Sort::Naturally::ncmp
          : sub { $_[0] cmp $_[1] };
      @index = sort {$cmp->($a->{'name'}, $b->{'name'})
                       || $a->{'position'} <=> $b->{'position'}
                     } @index;
    }

    my $prev_name = '';
    my $pos = 0;
    foreach my $entry (@index) {
      {
        my $item = Wx::ListItem->new;
        $item->SetText($entry->{'name'} eq $prev_name ? '' : $entry->{'name'});
        $item->SetId($pos);
        $item->SetColumn(0);
        $list->InsertItem ($item);
      }
      {
        my $item = Wx::ListItem->new;
        $item->SetText($entry->{'line_number'});
        $item->SetId($pos);
        $item->SetColumn(1);
        $list->SetItem ($item);
      }
      # $list->SetItemData ($pos, $entry);

      $prev_name = $entry->{'name'};
      $pos++;
    }
  };
  $fill->(0);

  # my $prev_name = '';
  # foreach my $i ( 0 .. 50 ) {
  #   my $t = ( rand() * 100 ) % 3;
  #   my $q = int( rand() * 100 );
  #   my $name = $names[$t];
  #   my $idx = $list->InsertImageStringItem($i,
  #                                          ($name eq $prev_name ? '' : $name),
  #                                          0);
  #   $list->SetItemData( $idx, $i );
  #   $list->SetItem( $idx, 1, $q );
  #   $prev_name = $name;
  # }

  $list->SetColumnWidth(0, Wx::wxLIST_AUTOSIZE());
  $list->SetColumnWidth(1, Wx::wxLIST_AUTOSIZE());

  # CreateSeparatedButtonSizer
  my $button_sizer = $frame->CreateStdDialogButtonSizer (Wx::wxOK());
  $vert_sizer->Add ($button_sizer, 0, 0, 0);

  {
    my $choice = Wx::Choice->new ($frame,
                                  Wx::wxID_ANY(),
                                  Wx::wxDefaultPosition(),
                                  Wx::wxDefaultSize(),
                                  [ 'Alphabetical', 'Position' ]);
    Wx::Event::EVT_CHOICE($choice, $choice, sub {
                            my ($choice, $event) = @_;
                            my $value = $choice->GetCurrentSelection;
                            print "choice $value\n";
                            $fill->($value);
                          });
    $button_sizer->Insert (0, $choice);
  }

  $frame->SetSizer($vert_sizer);
  # $frame->SetSizerAndFit($vert_sizer);

  my $bestsize = $frame->GetBestSize;
  ### best height: $bestsize->GetHeight
  $frame->SetSize ($bestsize);
  $list->SetFocus;

  $frame->Show;
  $app->MainLoop;
  exit 0;
}
{
  # grep for X<> index markup

  unshift @INC, '../el/devel';
  require MyLocatePerl;
  require MyStuff;

  my $verbose = 0;

  sub zap_to_first_pod {
    my ($str) = @_;

    if ($str =~ /^=/) {
      return $str;
    }

    my $pos = index ($str, "\n\n=");
    if ($pos < 0) {
      return $str;
    }
    my $pre = substr($str,0,$pos);
    my $post = substr($str,$pos);
    $pre =~ tr/\n//cd;

    ### $pre
    return $pre.$post;
  }
  ### zap: zap_to_first_pod("blah\nblah\n\n\n=pod")

  sub zap_pod_verbatim {
    my ($str) = @_;
    $str =~ s/^ .*//mg;
    return $str;
  }

  my $X_re = qr/X<+([^>]|E<[^>]*>)*?>/;  # $1=contained text

  sub grep_X_index_entry {
    my ($filename, $str) = @_;
    $str = zap_to_first_pod($str);
    $str = zap_pod_verbatim($str);
    ### $str
    if ($str =~ $X_re) {
      my $pos = $-[0];
      my ($linenum, $colnum) = MyStuff::pos_to_line_and_column($str,$pos);
      my $linestr = MyStuff::line_at_pos($str, $pos);
      print "$filename:$linenum:$colnum: $linestr",
    }
  }

  my $l = MyLocatePerl->new (include_pod => 1,
                             exclude_t => 1);
  while (my ($filename, $str) = $l->next) {
    #  next if $filename =~ m{/perltoc\.pod$};
    if ($verbose) { print "look at $filename\n"; }
    grep_X_index_entry($filename,$str);
  }

  exit 0;

  #  X<Y

=head1 SEE ALSO

X<Foo,
Bar>,
X<Foo>

=cut
}

