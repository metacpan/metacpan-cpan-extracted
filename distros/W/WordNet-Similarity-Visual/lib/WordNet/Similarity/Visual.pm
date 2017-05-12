package WordNet::Similarity::Visual;

=head1 NAME

WordNet::Similarity::Visual - Perl extension for providing visualization tools
for WordNet::Similarity

=head1 SYNOPSIS

=head2 Basic Usage Example

  use WordNet::Similarity::Visual;

  $gui = WordNet::Similarity::Visual->new;

  $gui->initialize;

=head1 DESCRIPTION

This package provides a graphical extension for WordNet::Similarity.
It provides a gui for WordNet::Similarity and visualization tools for
the various edge counting measures like path, wup, lch and hso.

=head2 Methods

The following methods are defined in this package:

=head3 Public methods

=over

=cut

use 5.008004;
use WordNet::Similarity::Visual::QueryDataInterface;
use WordNet::Similarity::Visual::GUI_Window;
use WordNet::Similarity::Visual::SimilarityInterface;
use Gtk2 '-init';
use strict;
use warnings;
use constant TRUE  => 1;
use constant FALSE => 0;
my $main_window;
my $querydata_vbox;
my $similarity_vbox;
my $similarity_interface;
my $querydata_interface;
my $trace_result_box;
my $values_result_box;
my $querydata_result_box;
my $progbar;
my $initial_flag;
my $start_window;
my $tooltip;
my $toolflag;
my $tooltip_label;
my $vpaned;
my $main_statusbar;
my $canvas;
our $VERSION = '0.07';

=item  $obj->new

The constructor for WordNet::Similarity::Visual objects.

Return value: the new blessed object

=cut


sub new
{
  my ($class) = @_;
  my $self = {};
  bless $self, $class;
}

=item  $obj->initialize

To initialize the Graphical User Interface and pass the control to it.

=cut

sub initialize
{
  my ($self)=@_;
  $self->configure;
  $self->{ initial_flag }=0;

#################################################################################

  $self->{ tooltip_label } = Gtk2::Label->new;
  $self->{ tooltip } = Gtk2::Window->new('popup');
  $self->{ tooltip }->set_decorated(FALSE);
  $self->{ tooltip }->set_destroy_with_parent(TRUE);
  $self->{ tooltip }->set_position('mouse');
  $self->{ tooltip }->modify_bg ('normal', Gtk2::Gdk::Color->parse('yellow'));
  $self->{ tooltip }->add($self->{ tooltip_label });
  $self->{ toolflag }=0;

#################################################################################

  $self->{ querydata_interface } = WordNet::Similarity::Visual::QueryDataInterface->new;
  $self->{ similarity_interface } = WordNet::Similarity::Visual::SimilarityInterface->new;
  $self->{ start_window }= Gtk2::Window->new("toplevel");
  $self->{ start_window }->set_resizable(FALSE);
  $self->{ start_window }->set_position("GTK_WIN_POS_CENTER");
  $self->{ start_window }->set_skip_taskbar_hint(TRUE);
  $self->{ start_window }->set_destroy_with_parent(TRUE);
  $self->{ start_window }->set_size_request(300,300);
  $self->{ start_window }->set_decorated(FALSE);
  $self->{ start_window }->stick;
  my $start_vbox = Gtk2::VBox->new;
  $self->{ progbar } = Gtk2::ProgressBar->new;
  $self->{ progbar }->set_text("Initializing WordNet::Similarity....");
  $self->{ progbar }->set_fraction(0);
  $self->{ progbar }->set_pulse_step(0.05);
  my $start_canvas = Gnome2::Canvas->new;
  $start_canvas->set_size_request(300,250);
  $start_vbox->add($start_canvas);
  $start_vbox->add($self->{ progbar });
  $self->{ start_window }->add($start_vbox);
  my $timer = Glib::Timeout->add(100,\&update_progressbar,$self);
  $self->{ start_window }->signal_connect(destroy=> sub {
                                                          my($self)=@_;
                                                          Gtk2->main_quit;
                                                        });
  $self->{ start_window }->show_all;
  Gtk2->main;

###########################################################################################

  $self->{ main_window } = WordNet::Similarity::Visual::GUI_Window->new;
  $self->{ main_window }->initialize("WordNet::Similarity GUI",0, 800,600);
    $self->{ main_statusbar } = Gtk2::Statusbar->new;
    my $main_menu = Gtk2::MenuBar->new();
  $self->{ main_window }->pack_start($main_menu,FALSE, FALSE, 0);
    my $tabbedwindow = Gtk2::Notebook->new;
    $tabbedwindow->set_show_border(0);
      my $querydata_scrollwindow = Gtk2::ScrolledWindow->new;
      my $similarity_scrollwindow = Gtk2::ScrolledWindow->new;

###########################################################################################

  $self->{ similarity_vbox } =  Gtk2::VBox->new(FALSE, 6);
  $self->{ similarity_vbox }->set_border_width(6);
    my $similarity_entry_align = Gtk2::Alignment->new(0.0,0.0,0.3,0.0);
      my $similarity_entry_hbox = Gtk2::HBox->new(FALSE,6);
        my $word1_similarity_entry = Gtk2::Entry->new;
        my $word2_similarity_entry = Gtk2::Entry->new;
        my $measure_touse = Gtk2::ComboBox->new_text;
          $measure_touse->append_text("All Measures");
          $measure_touse->append_text("Hist & St-Onge");
          $measure_touse->append_text("Leacock & Chodorow");
          $measure_touse->append_text("Adapted Lesk");
          $measure_touse->append_text("Lin");
          $measure_touse->append_text("Jiang & Conrath");
          $measure_touse->append_text("Path length");
          $measure_touse->append_text("Random numbers");
          $measure_touse->append_text("Resnik");
          $measure_touse->append_text("Context vector");
          $measure_touse->append_text("Wu & Palmer");
          $measure_touse->set_active(0);
        my $compute_button = Gtk2::Button->new('_Compute');
        my $stop_button = Gtk2::Button->new('_Stop');
#         my $save_button = Gtk2::Button->new('_Save');
      $similarity_entry_hbox->pack_start($word1_similarity_entry, TRUE, TRUE, 0);
      $similarity_entry_hbox->pack_start($word2_similarity_entry, TRUE, TRUE, 0);
      $similarity_entry_hbox->pack_start($measure_touse, TRUE, TRUE, 0);
      $similarity_entry_hbox->pack_start($compute_button,FALSE, FALSE, 0);
        $compute_button->signal_connect(clicked=>sub {
                                                        my ($self, $gui)=@_;
                                                        $gui->{ similarity_interface }->{ STOPPED }=0;
                                                        $gui->set_statusmessage("Similarity", "Computing the Similarity Scores");
                                                        my $word1 = $word1_similarity_entry->get_text();
                                                        my $word2 = $word2_similarity_entry->get_text();
                                                        my $measure = $measure_touse->get_active();
                                                        my ($result,$errors,$traces)=$gui->{ similarity_interface }->compute_similarity($word1, $word2,$measure);
                                                        $gui->display_similarity_results($result,$errors,$traces,$measure);
                                                      }, $self);
        $stop_button->signal_connect(clicked=>sub {
                                                    my ($self,$gui)=@_;
                                                    $gui->{ similarity_interface }->{ STOPPED }=1;
                                                    }, $self);
      $similarity_entry_hbox->pack_start($stop_button,FALSE, FALSE, 0);
# ############################################################################################
# # ##Change
#         $save_button->signal_connect(clicked=>sub {
#                                                     my ($self,$gui)=@_;
#                                                     my $file_selector = Gtk2::FileSelection->new("Save File as...");
#                                                     $file_selector->set_select_multiple(FALSE);
#                                                     $file_selector->ok_button->set_label("Save");
#                                                     my @data = ($file_selector, $gui);
#                                                     $file_selector->ok_button->signal_connect(clicked=>sub {
#                                                                       my ($self,$data)=@_;
#                                                                       my $file_selector = $data->[0];
#                                                                       my $gui = $data->[1];
#                                                                       my $file_name=$file_selector->get_filename();
#                                                                       print $file_name;
#                                                                       $gui->save_file($file_name);
#                                                                       $file_selector->destroy;
#                                                                     },\@data);
#                                                     $file_selector->ok_button->signal_connect(clicked=>sub {
#                                                                                   my ($self,$file_selector)=@_;
#                                                                                   $file_selector->destroy;
#                                                                                 },$file_selector);
#
#                                                     $file_selector->show_all;
#                                                     }, $self);
# ###########################################################################################
#       $similarity_entry_hbox->pack_start($save_button,FALSE, FALSE, 0);
    $similarity_entry_align->add($similarity_entry_hbox);
  $self->{ similarity_vbox }->pack_start($similarity_entry_align, FALSE, FALSE, 0);
    my $hseparator = Gtk2::HSeparator->new;
  $self->{ similarity_vbox }->pack_start($hseparator, FALSE, FALSE, 0);
  $self->{ trace_result_box }=Gtk2::VBox->new(FALSE,4);
  $self->{ values_result_box }=Gtk2::VBox->new(FALSE,4);
    my $hpaned = Gtk2::HPaned->new;
      $self->{ vpaned } = Gtk2::VPaned->new;
      my $trace_scrollwindow = Gtk2::ScrolledWindow->new;
      $trace_scrollwindow->add_with_viewport($self->{ trace_result_box });
      $trace_scrollwindow->set_policy("GTK_POLICY_AUTOMATIC", "GTK_POLICY_AUTOMATIC");
      my $values_scrollwindow = Gtk2::ScrolledWindow->new;
      $values_scrollwindow->add_with_viewport($self->{ values_result_box });
      $values_scrollwindow->set_policy("GTK_POLICY_AUTOMATIC", "GTK_POLICY_AUTOMATIC");
     $hpaned->add1($values_scrollwindow);
      $self->{ vpaned }->add1($trace_scrollwindow);
     $hpaned->add2($self->{ vpaned });
     $hpaned->set_position(320);
  $self->{ similarity_vbox }->pack_start($hpaned, TRUE, TRUE, 0);

#####################################################################################################################333

  $self->{ querydata_vbox }= Gtk2::VBox->new(FALSE, 6);
  $self->{ querydata_vbox }->set_border_width(6);
  my $querydata_entry_align = Gtk2::Alignment->new(0.0,0.0,0.3,0.0);
    my $querydata_entry_hbox = Gtk2::HBox->new(FALSE,6);
#       my $back_button = Gtk2::Button->new('<< _Back');
#       my $forward_button = Gtk2::Button->new('_Forward >>');
      my $searchword_entry = Gtk2::Entry->new;
      my $querydata_search_button = Gtk2::Button->new('_Search');
      my $print_button = Gtk2::Button->new('_Print');
#       $querydata_entry_hbox->pack_start($back_button,FALSE, FALSE, 0);
#       $querydata_entry_hbox->pack_start($forward_button,FALSE, FALSE, 0);
      $querydata_entry_hbox->pack_start($searchword_entry, TRUE, TRUE, 0);
      $querydata_entry_hbox->pack_start($querydata_search_button,FALSE, FALSE, 0);
      $querydata_entry_hbox->pack_start($print_button,FALSE, FALSE, 0);
      $querydata_search_button->signal_connect(clicked=>sub {
                                                              my ($self, $gui)=@_;
                                                              $gui->set_statusmessage("QueryData", "Crawling Through WordNet for Senses!");
                                                              my $word = $searchword_entry->get_text();
                                                              my $result_wps = $gui->{ querydata_interface }->search_senses($word);
                                                              $gui->display_querydata_results($result_wps);
                                                            }, $self);
    $querydata_entry_align->add($querydata_entry_hbox);
  $self->{ querydata_vbox }->pack_start($querydata_entry_align, FALSE, FALSE, 0);
     my $querydata_hseparator = Gtk2::HSeparator->new;
  $self->{ querydata_vbox }->pack_start($querydata_hseparator, FALSE, FALSE, 0);
  $self->{ querydata_result_box }=Gtk2::VBox->new(FALSE,4);
  $self->{ querydata_vbox }->pack_start($self->{ querydata_result_box }, TRUE, TRUE, 0);


###########################################################################################

      $similarity_scrollwindow->add_with_viewport($self->{ similarity_vbox });
      $similarity_scrollwindow->set_policy("GTK_POLICY_NEVER", "GTK_POLICY_AUTOMATIC");
      $querydata_scrollwindow->add_with_viewport($self->{ querydata_vbox });
      $querydata_scrollwindow->set_policy("GTK_POLICY_NEVER", "GTK_POLICY_AUTOMATIC");
    $tabbedwindow->append_page($querydata_scrollwindow, "WordNet::QueryData");
    $tabbedwindow->append_page($similarity_scrollwindow, "WordNet::Similarity");
  $self->{ main_window }->pack_start($tabbedwindow,TRUE, TRUE,0);
  $self->{ main_window }->pack_end($self->{ main_statusbar },FALSE, FALSE, 0);
  $self->{ main_window }->display;

###############################################################################################3
}

sub update_progressbar
{
  my ($gui)=@_;
  if($gui->{ initial_flag }<2)
  {
    if($gui->{ initial_flag }==0)
    {
      while (Gtk2->events_pending)
      {
        Gtk2->main_iteration;
      }
      $gui->{ querydata_interface }->initialize;
      $gui->{ progbar }->set_fraction($gui->{ progbar }->get_fraction+0.1);
      while (Gtk2->events_pending)
      {
        Gtk2->main_iteration;
      }
      $gui->{ similarity_interface }->initialize;
      $gui->{ initial_flag }=1;
    }
    if($gui->{ progbar }->get_fraction >= 1)
    {
      $gui->{ start_window }->destroy;
      $gui->{ initial_flag }=2;
      return TRUE;
    }
    else
    {
      $gui->{ progbar }->set_fraction($gui->{ progbar }->get_fraction+0.1);
      $gui->{ start_window }->show_all;
    }
  }
  return TRUE;
}





sub display_querydata_results
{
  my ($self, $result)=@_;
  my $wps;
  my %labels;
  my %hbox;
  my %txtview;
  my %txtbuffer;
  my $children;
  my @prev_results = $self->{ querydata_result_box }->get_children();
  foreach $children (@prev_results)
  {
    $self->{ querydata_result_box }->remove($children);
  }
  foreach $wps (sort keys %$result)
  {
    $labels{$wps}=Gtk2::Label->new($wps);
    $hbox{$wps}=Gtk2::HBox->new();
    $txtbuffer{$wps}=Gtk2::TextBuffer->new();
    $txtbuffer{$wps}->set_text($result->{$wps});
    $txtview{$wps}=Gtk2::TextView->new;
    $txtview{$wps}->set_editable(FALSE);
    $txtview{$wps}->set_cursor_visible(FALSE);
    $txtview{$wps}->set_wrap_mode("word");
    $txtview{$wps}->set_buffer($txtbuffer{$wps});
    $hbox{$wps}->pack_start($labels{$wps},FALSE,FALSE,0);
    $hbox{$wps}->pack_start($txtview{$wps},TRUE, TRUE, 0);
    $self->{ querydata_result_box}->pack_start($hbox{$wps},FALSE, FALSE, 4);
  }
  $self->{ querydata_result_box}->show_all;
  $self->update_ui;
}






# This function writes the initial configuration files for the various measures.
sub configure
{
  if (!chdir($ENV{ HOME } . "/.wordnet-similarity"))
  {
    mkdir ($ENV{ HOME } . "/.wordnet-similarity");
    open CONFIG, "+>".$ENV{ HOME } . "/.wordnet-similarity/config-path.conf";
    print CONFIG "WordNet::Similarity::path\ntrace::1\ncache::0\nmaxCacheSize::5000\nrootNode::1";
    close CONFIG;
    open CONFIG, "+>".$ENV{ HOME } . "/.wordnet-similarity/config-wup.conf";
    print CONFIG "WordNet::Similarity::wup\ntrace::1\ncache::0\nmaxCacheSize::5000\nrootNode::1";
    close CONFIG;
    open CONFIG, "+>".$ENV{ HOME } . "/.wordnet-similarity/config-hso.conf";
    print CONFIG "WordNet::Similarity::hso\ntrace::1\ncache::0\nmaxCacheSize::5000";
    close CONFIG;
    open CONFIG, "+>".$ENV{ HOME } . "/.wordnet-similarity/config-lch.conf";
    print CONFIG "WordNet::Similarity::lch\ntrace::1\ncache::0\nmaxCacheSize::5000\nrootNode::1";
    close CONFIG;
  }
}


sub update_ui
{
  my ($self) = @_;
  $self->{ main_window }->update_ui();
}


sub set_statusmessage
{
  my ($self, $context, $message) = @_;
  my $status_context_id = $self->{ main_statusbar }->get_context_id("MainStatusBar");
  $self->{ main_statusbar }->push($status_context_id,$message);
  $self->{ main_window }->update_ui();
}


sub display_similarity_results
{
  my ($self, $values, $errors, $traces, $measure_index) = @_;
  my @allmeasures = ("hso","lch","lesk","lin","jcn","path","random","res","vector_pairs","wup");
  my $measure;
  my $synset1;
  my $synset2;
  my $button;
  my $str;
  my $children;
  my @prev_results = $self->{ values_result_box }->get_children();
  foreach $children (@prev_results)
  {
    $self->{ values_result_box }->remove($children);
  }
  if($measure_index!=0)
  {
    $measure = $allmeasures[$measure_index-1];
    foreach $synset1 (keys %$values)
    {
      foreach $synset2 (keys %{$values->{$synset1}})
      {
        if($values->{$synset1}{$synset2}!=-1)
        {
          $str = sprintf("The Relatedness of %s and %s is %.4f",$synset1, $synset2, $values->{$synset1}{$synset2});
          $button=Gtk2::Button->new_with_label($str);
          $button->signal_connect(clicked=>sub {
                                                  my ($self,$gui)=@_;
                                                  my $word1;
                                                  my $word2;
                                                  my @splitlabel;
                                                  my $measure;
                                                  my $string = $self->get_label();
                                                  @splitlabel=split " ",$string;
                                                  $measure = $allmeasures[$measure_index-1];
                                                  $word1 = $splitlabel[3];
                                                  $word2 = $splitlabel[5];
                                                  $gui->trace_results($word1,$word2,$measure,$traces);
                                                  $gui->update_ui;
                                              }, $self);
          $button->set_relief("none");
          $self->{ values_result_box }->pack_start($button,FALSE, FALSE, 4);
        }
      }
    }
  }
  else
  {
    foreach $synset1 (keys %$values)
    {
      foreach $synset2 (keys %{$values->{$synset1}})
      {
        for $measure (keys %{$values->{$synset1}{$synset2}})
        {
          if($errors->{$synset1}{$synset2}{$measure})
          {
          }
          else
          {
            $str = sprintf("The Relatedness of %s and %s using %s is %.4f",$synset1, $synset2, $measure, $values->{$synset1}{$synset2}{$measure});
            $button=Gtk2::Button->new_with_label($str);
            $button->signal_connect(clicked=>sub {
                                                my ($self,$gui)=@_;
                                                my $word1;
                                                my $word2;
                                                my $measure;
                                                my @splitlabel;
                                                my $string = $self->get_label();
                                                @splitlabel=split " ",$string;
                                                $word1 = $splitlabel[3];
                                                $word2 = $splitlabel[5];
                                                $measure = $splitlabel[7];
                                                $gui->trace_results($word1,$word2,$measure,$traces);
                                                $gui->update_ui;
                                             }, $self);
            $button->set_relief("none");
            $self->{ values_result_box }->pack_start($button,FALSE, FALSE, 4);
          }
        }
      }
    }
  }
  $self->{ values_result_box }->show_all;
  $self->update_ui;
}


sub trace_results
{
  my ($self, $word1, $word2, $measure, $traces)=@_;
  my $meta;
  my $children;
  my @prev_results = $self->{ trace_result_box }->get_children();
  foreach $children (@prev_results)
  {
    $self->{ trace_result_box }->remove($children);
  }
  if($measure=~/path/)
  {
    $meta = $self->{ similarity_interface }->convert_to_meta($word1,$word2,$traces->{$word1}{$word2}{$measure},$measure);
    my $canvas = $self->display_tree($meta,450,450);
    $self->{ trace_result_box }->pack_start($canvas, TRUE, TRUE, 0);
  }
  elsif($measure=~/wup/)
  {
    $meta = $self->{ similarity_interface }->convert_to_meta($word1,$word2,$traces->{$word1}{$word2}{$measure},$measure);
    my $canvas = $self->display_tree($meta,450,450);
    $self->{ trace_result_box }->pack_start($canvas, TRUE, TRUE, 0);
  }
  elsif($measure=~/lch/)
  {
    $meta = $self->{ similarity_interface }->convert_to_meta($word1,$word2,$traces->{$word1}{$word2}{$measure},$measure);
    my $canvas = $self->display_tree($meta,450,450);
    $self->{ trace_result_box }->pack_start($canvas, TRUE, TRUE, 0);
  }
  elsif($measure=~/hso/)
  {
    if($traces->{$word1}{$word2}{$measure}=~/MedStrong\srelation\spath\.\.\./)
    {
      $meta = $self->{ similarity_interface }->convert_to_meta($word1,$word2,$traces->{$word1}{$word2}{$measure},$measure);
      my $canvas = $self->display_tree($meta,450,450);
      $self->{ trace_result_box }->pack_start($canvas, TRUE, TRUE, 0);
    }
    elsif($traces->{$word1}{$word2}{$measure}=~/Strong\sRel\s\(Synset\sMatch\)/)
    {
      $meta = $self->{ similarity_interface }->convert_to_meta($word1,$word2,$traces->{$word1}{$word2}{$measure},$measure);
      my $canvas = $self->display_tree($meta,450,450);
      $self->{ trace_result_box }->pack_start($canvas, TRUE, TRUE, 0);
    }
    else
    {
      $meta = $traces->{$word1}{$word2}{$measure}."\nNo strong relation path found!!";
      my $txtbuffer = Gtk2::TextBuffer->new();
      $txtbuffer->set_text($meta);
      my $txtview = Gtk2::TextView->new;
      $txtview->set_editable(FALSE);
      $txtview->set_cursor_visible(FALSE);
      $txtview->set_wrap_mode("word");
      $txtview->set_buffer($txtbuffer);
      $self->{ trace_result_box }->pack_start($txtview, TRUE, TRUE, 0);
    }
  }
  else
  {
    $meta = $traces->{$word1}{$word2}{$measure};
    my $txtbuffer = Gtk2::TextBuffer->new();
    $txtbuffer->set_text($meta);
    my $txtview = Gtk2::TextView->new;
    $txtview->set_editable(FALSE);
    $txtview->set_cursor_visible(FALSE);
    $txtview->set_wrap_mode("word");
    $txtview->set_buffer($txtbuffer);
    $self->{ trace_result_box }->pack_start($txtview, TRUE, TRUE, 0);
  }
  $self->{ trace_result_box }->show_all;
}


sub display_tree
{
  my ($self, $string, $width, $height)=@_;
  my @trace_strings = split "\n",$string;
  my $i;
  my @wps;
  my $diffx;
  my $diffy;
  my $x = 0;
  my $y = $height;
  my $word;
  my %wpspos = ();
  my $prevx;
  my $prevy;
  my $maxx=0;
  my $maxy=0;
  my $minx=0;
  my $miny=0;
  my $hx;
  my $hy;
  my @vbox;
  my $j;
  my $center;
  my %text;
  my %line;
  my $rflag=0;
  my $jflag=0;
  my $mpflag=0;
  my @connectedto;
  my $connect;
  my @roots;
  my @mult_wps1_path;
  my @mult_wps2_path;
  my $wps1_path;
  my $wps2_path;
  my $notebook;
  my $color;
  my $k=0;
  my @colorpos;
  my @canvas;
  my $lcs_x;
  my $lcs_y;
  my @canvas_root;
  my @shortest_path_group;
  my @root_group;
  my @shortest_path_group_wps1;
  my @shortest_path_group_wps2;
  if($trace_strings[0]=~/path/)
  {
    @mult_wps1_path = split /\sOR\s/, $trace_strings[1];
    @mult_wps2_path = split /\sOR\s/, $trace_strings[2];
    if($#mult_wps1_path+$#mult_wps2_path+1>1)
    {
      $notebook = Gtk2::Notebook->new;
#       $notebook->signal_connect(switch_page=>sub {
#                                                     my ($self,$gui) = @_;
#                                                     my $child=$self->get_current_page;
#                                                     print $child;
#                                                     my @children = $self->get_children;
#                                                     $gui->{ canvas }= $children[$child];
#                                 },$self);
      $mpflag = 1;
    }
    else
    {
      $notebook = Gtk2::VBox->new;
    }
    foreach $wps1_path (@mult_wps1_path)
    {
      foreach $wps2_path (@mult_wps2_path)
      {
        $canvas[$k] = Gnome2::Canvas->new;
        $canvas_root[$k] = $canvas[$k]->root;
        $shortest_path_group[$k] = Gnome2::Canvas::Item->new($canvas_root[$k], "Gnome2::Canvas::Group");
        $root_group[$k] = Gnome2::Canvas::Item->new($shortest_path_group[$k], "Gnome2::Canvas::Group");
        $shortest_path_group_wps1[$k] = Gnome2::Canvas::Item->new($shortest_path_group[$k], "Gnome2::Canvas::Group");
        $shortest_path_group_wps2[$k] = Gnome2::Canvas::Item->new($shortest_path_group[$k], "Gnome2::Canvas::Group");
        %text=();
        %line=();
        $diffy = 40;
        $diffx = 0;
        $x=0;
        $y=0;
        $maxx=0;
        $maxy=0;
        $minx=0;
        $miny=0;
        @roots = grep /Root\b/, @trace_strings;
        if(length($roots[0]) == length($trace_strings[1]) or length($roots[0]) == length($trace_strings[2]))
        {
          @wps= split /\shypernym\s/, $roots[0];
          $word = $wps[$#wps];
          $y = $y-$diffy;
          if($miny>$y)
          {
            $miny = $y;
          }
          if($maxy<$y)
          {
            $maxy = $y;
          }
          if($minx>$x)
          {
            $minx = $x;
          }
          if($maxx<$x)
          {
            $maxx = $x;
          }
          $wpspos{$word}{"x"}=$x;
          $wpspos{$word}{"y"}=$y;
          $lcs_x=$x;
          $lcs_y=$y;
          @colorpos = split '#', $word;
          if($colorpos[1]=~ 'v')
          {
            $color = 'red';
          }
          elsif($colorpos[1]=~ 'n')
          {
            $color = 'dark green';
          }
          else
          {
            $color = 'purple';
          }
          $text{$word} = Gnome2::Canvas::Item->new($root_group[$k], "Gnome2::Canvas::Text",
                                            x => $x,
                                            y => $y,
                                            font => 'Sans 10',
                                            anchor => 'GTK_ANCHOR_CENTER',
                                            fill_color => $color,
                                            text => $word);
          if($word !~ /Root/)
          {
            $text{$word}->signal_connect (event => sub {
                                                          my ($self,$event,$gui) = @_;
                                                          $gui->display_tooltip($self,$event);
                                                        },$self);
          }
        }
        else
        {
          $jflag=0;
          @wps= split /\shypernym\s/, $roots[0];
          foreach $j (0...$#wps)
          {
            $word = $wps[$j];
            $y = $y-$diffy;
            if($miny>$y)
            {
              $miny = $y;
            }
            if($maxy<$y)
            {
              $maxy = $y;
            }
            if($minx>$x)
            {
              $minx = $x;
            }
            if($maxx<$x)
            {
              $maxx = $x;
            }
            if($j==0)
            {
              $lcs_x=$x;
              $lcs_y=$y;
            }
            $wpspos{$word}{"x"}=$x;
            $wpspos{$word}{"y"}=$y;
            @colorpos = split '#', $word;
            if($colorpos[1]=~ 'v')
            {
              $color = 'red';
            }
            elsif($colorpos[1]=~ 'n')
            {
              $color = 'dark green';
            }
            else
            {
              $color = 'purple';
            }
            $text{$word} = Gnome2::Canvas::Item->new($root_group[$k], "Gnome2::Canvas::Text",
                                              x => $x,
                                              y => $y,
                                              font => 'Sans 10',
                                              anchor => 'GTK_ANCHOR_CENTER',
                                              fill_color => $color,
                                              text => $word);
            if($word !~ /Root/)
            {
              $text{$word}->signal_connect (event => sub {
                                                          my ($self,$event,$gui) = @_;
                                                          $gui->display_tooltip($self,$event);
                                                          },$self);
            }
            if($j>0)
            {
              if($roots[0] =~ /$trace_strings[1]/ or $roots[0] =~ /$trace_strings[2]/)
              {
                $line{$wps[$j-1]}{$word} = Gnome2::Canvas::Item->new($root_group[$k], "Gnome2::Canvas::Line",
                                                                      points => [$prevx,$prevy-$diffy/5,$x,$y+$diffy/5],
                                                                      width_pixels => 1,
                                                                      last_arrowhead => 1,
                                                                      arrow_shape_a => 3.57,
                                                                      arrow_shape_b => 6.93,
                                                                      arrow_shape_c => 4,
                                                                      fill_color => 'blue',
                                                                      );
              }
              else
              {
                $line{$wps[$j-1]}{$word} = Gnome2::Canvas::Item->new($root_group[$k], "Gnome2::Canvas::Line",
                                                                      points => [$prevx,$prevy-$diffy/5,$x,$y+$diffy/5],
                                                                      width_pixels => 1,
                                                                      last_arrowhead => 1,
                                                                      arrow_shape_a => 3.57,
                                                                      arrow_shape_b => 6.93,
                                                                      arrow_shape_c => 4,
                                                                      fill_color => 'blue',
                                                                      line_style => 'on-off-dash'
                                                                      );
              }
            }
            $prevx = $x;
            $prevy = $y;
          }
          $diffx=0;
        }
        $x=$lcs_x;
        $y=$lcs_y;
        $prevx=$lcs_x;
        $prevy=$lcs_y;
        @wps= split /\shypernym\s/,$wps2_path;
        foreach $i (reverse 0...$#wps)
        {
          $word = $wps[$i];
          if(!exists $text{$word})
          {
            $x = $x+$diffx;
            $y = $y+$diffy;
            if($miny>$y)
            {
              $miny = $y;
            }
            if($maxy<$y)
            {
              $maxy = $y;
            }
            if($minx>$x)
            {
              $minx = $x;
            }
            if($maxx<$x)
            {
              $maxx = $x;
            }
            @colorpos = split '#', $word;
            if($colorpos[1]=~ 'v')
            {
              $color = 'red';
            }
            elsif($colorpos[1]=~ 'n')
            {
              $color = 'dark green';
            }
            else
            {
              $color = 'purple';
            }
            $text{$word} = Gnome2::Canvas::Item->new($shortest_path_group_wps2[$k], "Gnome2::Canvas::Text",
                                                      x => $x,
                                                      y => $y,
                                                      fill_color => $color,
                                                      font => 'Sans 10',
                                                      anchor => 'GTK_ANCHOR_CENTER',
                                                      text => $word);
            $text{$word}->signal_connect (event => sub {
                                                         my ($self,$event,$gui) = @_;
                                                         $gui->display_tooltip($self,$event);
                                                        },$self);
            $wpspos{$word}{"x"}=$x;
            $wpspos{$word}{"y"}=$y;
            $line{$word}{$wps[$i+1]} = Gnome2::Canvas::Item->new($shortest_path_group_wps2[$k], "Gnome2::Canvas::Line",
                                                points => [$prevx,$prevy+$diffy/5,$x,$y-$diffy/5],
                                                width_pixels => 1,
                                                first_arrowhead => 1,
                                                arrow_shape_a => 3.57,
                                                arrow_shape_b => 6.93,
                                                arrow_shape_c => 4,
                                                fill_color => 'blue'
                                                );
            $prevx = $x;
            $prevy = $y;
          }
          else
          {
            my ($x1,$y1,$x2,$y2)=$text{$word}->get_bounds;
            $x = $x1 - 5;
            $y = $y2;
            $prevx = $x;
            $prevy = $y;
            $x = $x-60;
            $y = $y+10;
            next;
          }
        }
        $x=$lcs_x;
        $y=$lcs_y;
        $prevx=$lcs_x;
        $prevy=$lcs_y;
        $diffx=0;
        @wps= split /\shypernym\s/,$wps1_path;
        foreach $i (reverse 0...$#wps)
        {
          $word = $wps[$i];
          if(!exists $text{$word})
          {
            $x = $x+$diffx;
            $y = $y+$diffy;
            if($miny>$y)
            {
              $miny = $y;
            }
            if($maxy<$y)
            {
              $maxy = $y;
            }
            if($minx>$x)
            {
              $minx = $x;
            }
            if($maxx<$x)
            {
              $maxx = $x;
            }
            @colorpos = split '#', $word;
            if($colorpos[1]=~ 'v')
            {
              $color = 'red';
            }
            elsif($colorpos[1]=~ 'n')
            {
              $color = 'dark green';
            }
            else
            {
              $color = 'purple';
            }
            $text{$word} = Gnome2::Canvas::Item->new($shortest_path_group_wps1[$k], "Gnome2::Canvas::Text",
                                                x => $x,
                                                y => $y,
                                                fill_color => $color,
                                                font => 'Sans 10',
                                                anchor => 'GTK_ANCHOR_CENTER',
                                                text => $word);
            $text{$word}->signal_connect (event => sub {
                                                         my ($self,$event,$gui) = @_;
                                                         $gui->display_tooltip($self,$event);
                                                        },$self);
            $wpspos{$word}{"x"}=$x;
            $wpspos{$word}{"y"}=$y;
            $line{$word}{$wps[$i+1]} = Gnome2::Canvas::Item->new($shortest_path_group_wps1[$k], "Gnome2::Canvas::Line",
                                                points => [$prevx,$prevy+$diffy/5,$x,$y-$diffy/5],
                                                width_pixels => 1,
                                                first_arrowhead => 1,
                                                arrow_shape_a => 3.57,
                                                arrow_shape_b => 6.93,
                                                arrow_shape_c => 4,
                                                fill_color => 'blue'
                                                );
            $prevx = $x;
            $prevy = $y;
          }
          else
          {
            my ($x1,$y1,$x2,$y2)=$text{$word}->get_bounds;
            $x = $x2 + 5;
            $y = $y2;
            $prevx = $x;
            $prevy = $y;
            $x = $x+60;
            $y = $y+10;
            next;
          }
        }
        $hx = abs($maxx-$minx)+100;
        $hy = abs($maxy-$miny)+80;
        $canvas[$k]->set_size_request($hx,$hy);
        $canvas[$k]->set_scroll_region (0, 0, $hx, $hy);
        $shortest_path_group[$k]->set(x=>abs($minx)+60);
        $shortest_path_group[$k]->set(y=>abs($miny)+10);
        $minx = $k+1;
        if($mpflag)
        {
          $notebook->append_page($canvas[$k], "Path ".$minx);
        }
        else
        {
          $notebook->add($canvas[0]);
        }
        $k++;
      }
    }
    $self->{ canvas } = $canvas[0];
  }
  elsif($trace_strings[0]=~/wup/)
  {
    my @temp = split /\s=\s/, $trace_strings[$#trace_strings-2];
    my $word1 = $temp[0];
    my $word_lcs_flag;
    @temp = split /\s=\s/, $trace_strings[$#trace_strings];
    my $lcs = $temp[0];
    @temp = split /\s=\s/, $trace_strings[$#trace_strings-1];
    my $word2 = $temp[0];
    my $sub;
    my @trees = grep /\shypernym\s/, @trace_strings;
    my @syns1;
    my @syns2;
    my $syn;
    my @mult_wps1_path;
    @syns1 = $self->{ querydata_interface }->find_allsyns($word1);
    my $syns_group = join " ",@syns1;
    foreach $syn (@syns1)
    {
      push @mult_wps1_path, grep(/\b$syn\b/, @trees);
    }
    my @mult_wps2_path;
    @syns2 = $self->{ querydata_interface }->find_allsyns($word2);
    foreach $syn (@syns2)
    {
      push @mult_wps2_path, grep(/\b$syn\b/, @trees);
    }
    if($#mult_wps1_path+$#mult_wps2_path+1>1)
    {
      $notebook = Gtk2::Notebook->new;
#       $notebook->signal_connect(switch_page=>sub {
#                                                     my ($self,$gui) = @_;
#                                                     my $child=$self->get_current_page;
#                                                     my @children = $self->get_children;
#                                                     $gui->{ canvas }= $children[$child];
#                                },$self);
      $mpflag = 1;
    }
    else
    {
      $notebook = Gtk2::VBox->new;
    }
    my $lcsflag=0;
    $syn = join " ",@syns1;
    if($syn =~ /\b$word2\b/)
    {
      foreach $wps1_path (@mult_wps1_path)
      {
        $lcsflag=0;
        $x=0;
        $y=0;
        $maxx=0;
        $maxy=0;
        $minx=0;
        $miny=0;
        $canvas[$k] = Gnome2::Canvas->new;
        $canvas_root[$k] = $canvas[$k]->root;
        $shortest_path_group[$k] = Gnome2::Canvas::Item->new($canvas_root[$k], "Gnome2::Canvas::Group");
        $root_group[$k] = Gnome2::Canvas::Item->new($shortest_path_group[$k], "Gnome2::Canvas::Group");
        $shortest_path_group_wps1[$k] = Gnome2::Canvas::Item->new($shortest_path_group[$k], "Gnome2::Canvas::Group");
        $shortest_path_group_wps2[$k] = Gnome2::Canvas::Item->new($shortest_path_group[$k], "Gnome2::Canvas::Group");
        %text=();
        %line=();
        $diffy = 40;
        $diffx = 0;
        $jflag=0;
        @wps= split /\shypernym\s/, $wps1_path;
        foreach $j (0...$#wps)
        {
          $word = $wps[$j];
          $y = $y-$diffy;
          if($miny>$y)
          {
            $miny = $y;
          }
          if($maxy<$y)
          {
            $maxy = $y;
          }
          if($minx>$x)
          {
            $minx = $x;
          }
          if($maxx<$x)
          {
            $maxx = $x;
          }
          $wpspos{$word}{"x"}=$x;
          $wpspos{$word}{"y"}=$y;
          @colorpos = split '#', $word;
          if($colorpos[1]=~ 'v')
          {
            $color = 'red';
          }
          elsif($colorpos[1]=~ 'n')
          {
            $color = 'dark green';
          }
          else
          {
            $color = 'purple';
          }

          $text{$word} = Gnome2::Canvas::Item->new($root_group[$k], "Gnome2::Canvas::Text",
                                            x => $x,
                                            y => $y,
                                            fill_color => $color,
                                            font => 'Sans 10',
                                            anchor => 'GTK_ANCHOR_CENTER',
                                            text => $word);
          if($word !~ /Root/)
          {
            $text{$word}->signal_connect (event => sub {
                                                        my ($self,$event,$gui) = @_;
                                                        $gui->display_tooltip($self,$event);
                                                        },$self);
          }
          if($j>0)
          {
            $sub=0;
            $line{$wps[$j-1]}{$word} = Gnome2::Canvas::Item->new($root_group[$k], "Gnome2::Canvas::Line",
                                                                  points => [$prevx,$prevy-$diffy/5,$x+$sub,$y+$diffy/5],
                                                                  width_pixels => 1,
                                                                  last_arrowhead => 1,
                                                                  arrow_shape_a => 3.57,
                                                                  arrow_shape_b => 6.93,
                                                                  arrow_shape_c => 4,
                                                                  fill_color => 'blue'
                                                                  );
          }
          $prevx = $x;
          $prevy = $y;
        }
        $hx = abs($maxx-$minx)+100;
        $hy = abs($maxy-$miny)+80;
        $canvas[$k]->set_size_request($hx,$hy);
        $canvas[$k]->set_scroll_region (0, 0, $hx, $hy);
        $shortest_path_group[$k]->set(x=>abs($minx)+60);
        $shortest_path_group[$k]->set(y=>abs($miny)+10);
        $minx = $k+1;
        if($mpflag)
        {
          $notebook->append_page($canvas[$k], "Path ".$minx);
        }
        else
        {
          $notebook->add($canvas[0]);
        }
        $k++;
      }
    }
    else
    {
      foreach $wps1_path (@mult_wps1_path)
      {
        foreach $wps2_path (@mult_wps2_path)
        {
          if($wps1_path !~ /wps2_path/ and length($wps1_path)>1 and length($wps2_path)>1)
          {
            $lcsflag=0;
            $x=0;
            $y=0;
            $maxx=0;
            $maxy=0;
            $minx=0;
            $miny=0;
            $canvas[$k] = Gnome2::Canvas->new;
            $canvas_root[$k] = $canvas[$k]->root;
            $shortest_path_group[$k] = Gnome2::Canvas::Item->new($canvas_root[$k], "Gnome2::Canvas::Group");
            $root_group[$k] = Gnome2::Canvas::Item->new($shortest_path_group[$k], "Gnome2::Canvas::Group");
            $shortest_path_group_wps1[$k] = Gnome2::Canvas::Item->new($shortest_path_group[$k], "Gnome2::Canvas::Group");
            $shortest_path_group_wps2[$k] = Gnome2::Canvas::Item->new($shortest_path_group[$k], "Gnome2::Canvas::Group");
            %text=();
            %line=();
            $diffy = 40;
            $diffx = 0;
            $jflag=0;
            @wps= split /\shypernym\s/, $wps1_path;
            foreach $j (0...$#wps)
            {
              $word = $wps[$j];
              if($wps2_path=~/$word/)
              {
                if($lcsflag==0)
                {
                  $lcs = $word;
                  $x=$x-length($word)*9;
                  $lcs_x=$x;
                  $lcs_y=$y-$diffy;
                }
              }
              $y = $y-$diffy;
              if($miny>$y)
              {
                $miny = $y;
              }
              if($maxy<$y)
              {
                $maxy = $y;
              }
              if($minx>$x)
              {
                $minx = $x;
              }
              if($maxx<$x)
              {
                $maxx = $x;
              }
              $wpspos{$word}{"x"}=$x;
              $wpspos{$word}{"y"}=$y;
              @colorpos = split '#', $word;
              if($colorpos[1]=~ 'v')
              {
                $color = 'red';
              }
              elsif($colorpos[1]=~ 'n')
              {
                $color = 'dark green';
              }
              else
              {
                $color = 'purple';
              }

              $text{$word} = Gnome2::Canvas::Item->new($root_group[$k], "Gnome2::Canvas::Text",
                                                x => $x,
                                                y => $y,
                                                fill_color => $color,
                                                font => 'Sans 10',
                                                anchor => 'GTK_ANCHOR_CENTER',
                                                text => $word);
              if($word !~ /Root/)
              {
                $text{$word}->signal_connect (event => sub {
                                                            my ($self,$event,$gui) = @_;
                                                            $gui->display_tooltip($self,$event);
                                                            },$self);
              }
              if($j>0)
              {
                $sub=0;
                if($wps2_path=~/$word/)
                {
                  if($lcsflag==0)
                  {
                    $sub=length($word)*3;
                    $lcsflag=1;
                  }
                }
                $line{$wps[$j-1]}{$word} = Gnome2::Canvas::Item->new($root_group[$k], "Gnome2::Canvas::Line",
                                                                      points => [$prevx,$prevy-$diffy/5,$x+$sub,$y+$diffy/5],
                                                                      width_pixels => 1,
                                                                      last_arrowhead => 1,
                                                                      arrow_shape_a => 3.57,
                                                                      arrow_shape_b => 6.93,
                                                                      arrow_shape_c => 4,
                                                                      fill_color => 'blue'
                                                                      );
              }
              $prevx = $x;
              $prevy = $y;
            }
            $diffx=0;
            @wps= split /\shypernym\s/,$wps2_path;
            $word_lcs_flag=0;
            $x=$lcs_x;
            $y=$lcs_y;
            $prevx = $x-length($lcs)*3;
            $prevy = $y;
            foreach $i (reverse 0...$#wps)
            {
              $word = $wps[$i];
              if($word_lcs_flag==1)
              {
                if(!exists $text{$word})
                {
                  $x = $x+$diffx;
                  $y = $y+$diffy;
                  if($miny>$y)
                  {
                    $miny = $y;
                  }
                  if($maxy<$y)
                  {
                    $maxy = $y;
                  }
                  if($minx>$x)
                  {
                    $minx = $x;
                  }
                  if($maxx<$x)
                  {
                    $maxx = $x;
                  }
                  @colorpos = split '#', $word;
                  if($colorpos[1]=~ 'v')
                  {
                    $color = 'red';
                  }
                  elsif($colorpos[1]=~ 'n')
                  {
                    $color = 'dark green';
                  }
                  else
                  {
                    $color = 'purple';
                  }
                  $text{$word} = Gnome2::Canvas::Item->new($shortest_path_group_wps2[$k], "Gnome2::Canvas::Text",
                                                            x => $x,
                                                            y => $y,
                                                            fill_color => $color,
                                                            font => 'Sans 10',
                                                            anchor => 'GTK_ANCHOR_CENTER',
                                                            text => $word);
                  if($word !~ /Root/)
                  {
                    $text{$word}->signal_connect (event => sub {
                                                                my ($self,$event,$gui) = @_;
                                                                $gui->display_tooltip($self,$event);
                                                                },$self);            }
                  $wpspos{$word}{"x"}=$x;
                  $wpspos{$word}{"y"}=$y;
                  $line{$word}{$wps[$i+1]} = Gnome2::Canvas::Item->new($shortest_path_group_wps2[$k], "Gnome2::Canvas::Line",
                                                      points => [$prevx,$prevy+$diffy/5,$x,$y-$diffy/5],
                                                      width_pixels => 1,
                                                      first_arrowhead => 1,
                                                      arrow_shape_a => 3.57,
                                                      arrow_shape_b => 6.93,
                                                      arrow_shape_c => 4,
                                                      fill_color => 'blue'
                                                      );
                  $prevx = $x;
                  $prevy = $y;
                }
                else
                {
                  my ($x1,$y1,$x2,$y2)=$text{$word}->get_bounds;
                  $x = $x1 - 5;
                  $y = $y2;
                  $prevx = $x;
                  $prevy = $y;
                  $x = $x-60;
                  $y = $y+10;
                  next;
                }
              }
              elsif($lcs =~ /$word/)
              {
                $x = $x-length($lcs)*6;
                $word_lcs_flag=1;
              }
            }
            $hx = abs($maxx-$minx)+100;
            $hy = abs($maxy-$miny)+80;
            $canvas[$k]->set_size_request($hx,$hy);
            $canvas[$k]->set_scroll_region (0, 0, $hx, $hy);
            $shortest_path_group[$k]->set(x=>abs($minx)+60);
            $shortest_path_group[$k]->set(y=>abs($miny)+10);
            $minx = $k+1;
            if($mpflag)
            {
              $notebook->append_page($canvas[$k], "Path ".$minx);
            }
            else
            {
              $notebook->add($canvas[0]);
            }
            $k++;
          }
        }
      }
    }
     $self->{ canvas } = $canvas[0];
  }
  elsif($trace_strings[0]=~/lch/)
  {
    $k=-1;
    if($#trace_strings>3)
    {
      $notebook = Gtk2::Notebook->new;
#       $notebook->signal_connect(switch_page=>sub {
#                                                     my ($self,$gui) = @_;
#                                                     my $child=$self->get_current_page;
#                                                     my @children = $self->get_children;
#                                                     $gui->{ canvas }= $children[$child];
#                                },$self);
      $mpflag = 1;
    }
    else
    {
      $notebook = Gtk2::VBox->new;
    }
    $i=0;
    my $sub=0;
    my $lcsflag=0;
    foreach $i (1...$#trace_strings-1)
    {
      if($i%2==1)
      {
        $k++;
        $x=0;
        $y=0;
        $maxx=0;
        $maxy=0;
        $minx=0;
        $miny=0;
        $canvas[$k] = Gnome2::Canvas->new;
        $canvas_root[$k] = $canvas[$k]->root;
        $shortest_path_group[$k] = Gnome2::Canvas::Item->new($canvas_root[$k], "Gnome2::Canvas::Group");
        $root_group[$k] = Gnome2::Canvas::Item->new($shortest_path_group[$k], "Gnome2::Canvas::Group");
        $shortest_path_group_wps1[$k] = Gnome2::Canvas::Item->new($shortest_path_group[$k], "Gnome2::Canvas::Group");
        $shortest_path_group_wps2[$k] = Gnome2::Canvas::Item->new($shortest_path_group[$k], "Gnome2::Canvas::Group");
        %text=();
        %line=();
        $diffy = 40;
        $diffx = 0;
        $lcsflag=0;
        $jflag=0;
        @wps= split /\shypernym\s/, $trace_strings[$i];
        $diffx=0;
        foreach $j (0...$#wps)
        {
          $word = $wps[$j];
          $y = $y-$diffy;
          if($j==$#wps)
          {
            if($lcsflag==0)
            {
              $x=$x-length($word)*9;
            }
          }
          if($miny>$y)
          {
            $miny = $y;
          }
          if($maxy<$y)
          {
            $maxy = $y;
          }
          if($minx>$x)
          {
            $minx = $x;
          }
          if($maxx<$x)
          {
            $maxx = $x;
          }
          $wpspos{$word}{"x"}=$x;
          $wpspos{$word}{"y"}=$y;
          @colorpos = split '#', $word;
          if($colorpos[1]=~ 'v')
          {
            $color = 'red';
          }
          elsif($colorpos[1]=~ 'n')
          {
            $color = 'dark green';
          }
          else
          {
            $color = 'purple';
          }
          $text{$word} = Gnome2::Canvas::Item->new($root_group[$k], "Gnome2::Canvas::Text",
                                            x => $x,
                                            y => $y,
                                            fill_color => $color,
                                            font => 'Sans 10',
                                            anchor => 'GTK_ANCHOR_CENTER',
                                            text => $word);
          if($word !~ /Root/)
          {
            $text{$word}->signal_connect (event => sub {
                                                        my ($self,$event,$gui) = @_;
                                                        $gui->display_tooltip($self,$event);
                                                        },$self);
          }
          if($j>0)
          {
            $sub=0;
            if($j==$#wps)
            {
              if($lcsflag==0)
              {
                $sub=length($word)*3;
                $lcsflag=1;
              }
            }
            $line{$wps[$j-1]}{$word} = Gnome2::Canvas::Item->new($root_group[$k], "Gnome2::Canvas::Line",
                                                                  points => [$prevx,$prevy-$diffy/5,$x+$sub,$y+$diffy/5],
                                                                  width_pixels => 1,
                                                                  last_arrowhead => 1,
                                                                  arrow_shape_a => 3.57,
                                                                  arrow_shape_b => 6.93,
                                                                  arrow_shape_c => 4,
                                                                  fill_color => 'blue'
                                                                  );
          }
          $prevx = $x;
          $prevy = $y;
        }
      }
      else
      {
        $diffx=0;
        @wps= split /\shypernym\s/,$trace_strings[$i];
        foreach $i (reverse 0...$#wps)
        {
          $word = $wps[$i];
          if(!exists $text{$word})
          {
            $x = $x+$diffx;
            $y = $y+$diffy;
            if($miny>$y)
            {
              $miny = $y;
            }
            if($maxy<$y)
            {
              $maxy = $y;
            }
            if($minx>$x)
            {
              $minx = $x;
            }
            if($maxx<$x)
            {
              $maxx = $x;
            }
            @colorpos = split '#', $word;
            if($colorpos[1]=~ 'v')
            {
              $color = 'red';
            }
            elsif($colorpos[1]=~ 'n')
            {
              $color = 'dark green';
            }
            else
            {
              $color = 'purple';
            }
            $text{$word} = Gnome2::Canvas::Item->new($shortest_path_group_wps2[$k], "Gnome2::Canvas::Text",
                                                      x => $x,
                                                      y => $y,
                                                      fill_color => $color,
                                                      font => 'Sans 10',
                                                      anchor => 'GTK_ANCHOR_CENTER',
                                                      text => $word);
            if($word !~ /Root/)
            {
              $text{$word}->signal_connect (event => sub {
                                                          my ($self,$event,$gui) = @_;
                                                          $gui->display_tooltip($self,$event);
                                                          },$self);
            }
            $wpspos{$word}{"x"}=$x;
            $wpspos{$word}{"y"}=$y;
            $line{$word}{$wps[$i+1]} = Gnome2::Canvas::Item->new($shortest_path_group_wps2[$k], "Gnome2::Canvas::Line",
                                                points => [$prevx,$prevy+$diffy/5,$x,$y-$diffy/5],
                                                width_pixels => 1,
                                                first_arrowhead => 1,
                                                arrow_shape_a => 3.57,
                                                arrow_shape_b => 6.93,
                                                arrow_shape_c => 4,
                                                fill_color => 'blue'
                                                );
            $prevx = $x;
            $prevy = $y;
          }
          else
          {
            my ($x1,$y1,$x2,$y2)=$text{$word}->get_bounds;
            $x = $x1 - 5;
            $y = $y2;
            $prevx = $x;
            $prevy = $y;
            $x = $x-60;
            $y = $y+10;
            next;
          }
        }
        $hx = abs($maxx-$minx)+100;
        $hy = abs($maxy-$miny)+80;
        $canvas[$k]->set_size_request($hx,$hy);
        $canvas[$k]->set_scroll_region (0, 0, $hx, $hy);
        $shortest_path_group[$k]->set(x=>abs($minx)+60);
        $shortest_path_group[$k]->set(y=>abs($miny)+10);
        $minx = $k+1;
        if($mpflag)
        {
          $notebook->append_page($canvas[$k], "Path ".$minx);
        }
        else
        {
          $notebook->add($canvas[0]);
        }
      }
    }
    $self->{ canvas } = $canvas[0];
  }
  elsif($trace_strings[0]=~/hso/)
  {
    $k=-1;
    if($#trace_strings>1)
    {
      $notebook = Gtk2::Notebook->new;
#       $notebook->signal_connect(switch_page=>sub {
#                                                     my ($self,$gui) = @_;
#                                                     my $child=$self->get_current_page;
#                                                     my @children = $self->get_children;
#                                                     $gui->{ canvas }= $children[$child];
#                                },$self);
      $mpflag = 1;
    }
    else
    {
      $notebook = Gtk2::VBox->new;
    }
    $i=0;
    my $sub=0;
    my $lcsflag=0;
    my $prevword;
    foreach $i (1...$#trace_strings)
    {
      $k++;
      $x=0;
      $y=0;
      $maxx=0;
      $maxy=0;
      $minx=0;
      $miny=0;
      $canvas[$k] = Gnome2::Canvas->new;
      $canvas_root[$k] = $canvas[$k]->root;
      $shortest_path_group[$k] = Gnome2::Canvas::Item->new($canvas_root[$k], "Gnome2::Canvas::Group");
      $root_group[$k] = Gnome2::Canvas::Item->new($shortest_path_group[$k], "Gnome2::Canvas::Group");
      $shortest_path_group_wps1[$k] = Gnome2::Canvas::Item->new($shortest_path_group[$k], "Gnome2::Canvas::Group");
      $shortest_path_group_wps2[$k] = Gnome2::Canvas::Item->new($shortest_path_group[$k], "Gnome2::Canvas::Group");
      %text=();
      %line=();
      $diffy = 60;
      $diffx = 0;
      $lcsflag=0;
      $jflag=0;
      @wps= split /\s/, $trace_strings[$i];
      $diffx=60;
      $prevword="";
      foreach $word (@wps)
      {
        if(length($word)>=1)
        {
          if($miny>$y)
          {
            $miny = $y;
          }
          if($maxy<$y)
          {
            $maxy = $y;
          }
          if($minx>$x)
          {
            $minx = $x;
          }
          if($maxx<$x)
          {
            $maxx = $x;
          }
          if($word=~/hypernym/)
          {
            $y=$y+$diffy;
            $x=$x+$diffx+5;
            if($prevx!=0)
            {
              $prevx+=5;
            }
            $prevy=$prevy+15;
            $line{$prevword}{$word} = Gnome2::Canvas::Item->new($root_group[$k], "Gnome2::Canvas::Line",
                                                        points => [$prevx,$prevy-$diffy/7,$x+$sub,$y-$diffy/7],
                                                        width_pixels => 1,
                                                        last_arrowhead => 1,
                                                        arrow_shape_a => 3.57,
                                                        arrow_shape_b => 6.93,
                                                        arrow_shape_c => 4,
                                                        fill_color => 'blue'
                                                        );
          }
          elsif($word=~/hyponym/)
          {
            $x=$x+$diffx;
            $y=$y-$diffy;
            if($prevx!=0)
            {
              $prevx+=5;
            }
            $line{$prevword}{$word} = Gnome2::Canvas::Item->new($root_group[$k], "Gnome2::Canvas::Line",
                                                                  points => [$prevx,$prevy-$diffy/7,$x+$sub,$y+$diffy/7],
                                                                  width_pixels => 1,
                                                                  last_arrowhead => 1,
                                                                  arrow_shape_a => 3.57,
                                                                  arrow_shape_b => 6.93,
                                                                  arrow_shape_c => 4,
                                                                  fill_color => 'green'
                                                                  );
          }
          elsif($word=~/merynym/)
          {
            $prevx = $prevx + length($prevword)*3.5;
            $x = $x+2*$diffx;
            $line{$prevword}{$word} = Gnome2::Canvas::Item->new($root_group[$k], "Gnome2::Canvas::Line",
                                                                  points => [$prevx+5,$prevy,$x-5,$y],
                                                                  width_pixels => 1,
                                                                  last_arrowhead => 1,
                                                                  arrow_shape_a => 3.57,
                                                                  arrow_shape_b => 6.93,
                                                                  arrow_shape_c => 4,
                                                                  fill_color => 'black'
                                                                  );
          }
          else
          {
            if($prevword=~/merynym/)
            {
              $x=$x+length($word)*3.5;
            }
            @colorpos = split '#', $word;
            if($colorpos[1]=~ 'v')
            {
              $color = 'red';
            }
            elsif($colorpos[1]=~ 'n')
            {
              $color = 'dark green';
            }
            else
            {
              $color = 'purple';
            }
            $text{$word} = Gnome2::Canvas::Item->new($root_group[$k], "Gnome2::Canvas::Text",
                                              x => $x,
                                              y => $y,
                                              fill_color => $color,
                                              font => 'Sans 10',
                                              anchor => 'GTK_ANCHOR_CENTER',
                                              text => $word);
            if($word !~ /Root/)
            {
              $text{$word}->signal_connect (event => sub {
                                                          my ($self,$event,$gui) = @_;
                                                          $gui->display_tooltip($self,$event);
                                                          },$self);
            }
            $prevx = $x;
            $prevy = $y;
          }
          $prevword = $word;
        }
      }
      $hx = abs($maxx-$minx)+100;
      $hy = abs($maxy-$miny)+80;
      $canvas[$k]->set_size_request($hx,$hy);
      $canvas[$k]->set_scroll_region (0, 0, $hx, $hy);
      $shortest_path_group[$k]->set(x=>abs($minx)+60);
      $shortest_path_group[$k]->set(y=>abs($miny)+10);
      $minx = $k+1;
      if($mpflag)
      {
        $notebook->append_page($canvas[$k], "Path ".$minx);
      }
      else
      {
        $notebook->add($canvas[0]);
      }
    }
    $self->{ canvas } = $canvas[0];
  }
  return $notebook;
}

sub display_tooltip
{
  my ($gui,$self,$event)=@_;
  my $px=$self->parent->parent->get("x");
  my $py=$self->parent->parent->get("y");
  my @glos = $gui->{ querydata_interface }->{ wn }->querySense($self->get("text"),"glos");
  my @text = split ";",$glos[0];
  my $length = length($text[0]);
  my ($x1,$y1,$x2,$y2)=$self->get_bounds;
  if($gui->{ toolflag } == 0)
  {
    if($event->type =~ /enter/)
    {
      my $width = $length*6.7;
      my $height = $y2-$y1+1;
      $gui->{ tooltip_label }->set_text($text[0]);
      $gui->{ tooltip_label }->set_size_request($width,$height);
      $gui->{ tooltip }->resize($width,$height);
      $gui->{ tooltip }->show_all;
      my ($posx, $posy) = $gui->{ tooltip }->get_position;
      $gui->{ tooltip }->move($posx+$width/2+7,$posy+$height);
      $gui->{ toolflag }=1;
    }
    elsif($event->type=~/leave/)
    {
      if($event->x-$px<$x1 or $event->y-$py<$y1 or $event->x-$px>$x2 or $event->y-$py>$y2)
      {
        $gui->{ tooltip }->hide;
        $gui->{ toolflag }=0;
      }
    }
  }
  else
  {
    if($event->type=~/leave/)
    {
      my ($x1,$y1,$x2,$y2)=$self->get_bounds;
      if($event->x-$px<$x1 or $event->y-$py<$y1 or $event->x-$px>$x2 or $event->y-$py>$y2)
      {
        $gui->{ tooltip }->hide;
        $gui->{ toolflag }=0;
        $gui->{ tooltip_label }->set_size_request(1,1);
        $gui->{ tooltip }->set_size_request(1,1);
      }
    }
  }
  if($event->type=~/button.press/)
  {
    my @syns = $gui->{ querydata_interface }->{ wn }->querySense($self->get("text"),"syns");
    my $string = "Glos: ".$glos[0]."\n\nSynonyms: ";
    my $syn;
    foreach $syn (@syns)
    {
      $string = $string.", ".$syn;
    }
    my $children;
    if(defined $gui->{ vpaned }->child2)
    {
      my @prev_results = $gui->{ vpaned }->child2->get_children();
      foreach $children (@prev_results)
      {
        $gui->{ vpaned }->child2->remove($children);
      }
      $gui->{ vpaned }->remove($gui->{ vpaned }->child2);
    }
    my $txtbuffer = Gtk2::TextBuffer->new();
    $txtbuffer->set_text($string);
    my $txtview = Gtk2::TextView->new;
    $txtview->set_editable(FALSE);
    $txtview->set_cursor_visible(FALSE);
    $txtview->set_wrap_mode("word");
    $txtview->set_buffer($txtbuffer);
    $gui->{ vpaned }->add2($txtview);
    ($x1,$y1,$x2,$y2)=$self->parent->parent->parent->get_bounds;
    $gui->{ vpaned }->set_position($y2+40-$y1);
    $gui->{ vpaned }->show_all;
  }
}

# sub save_file
# {
#   my ($self,$filename)=@_;
# #   my $window = Gtk2::Gdk::Drawable->new;
# #   $window = $self->{ canvas }->get_window();
#   my $pixbuf = Gtk2::Gdk::Pixbuf->new('rgb',0,8,1000,1000);
#   $pixbuf->get_from_drawable(undef,$self->{ canvas }->get_colormap(),0,0,0,0,1000,1000);
# #   my $pixbuf = Gtk2::Gdk::pixbuf->new_from_data($window,$window->get_colormap(),0,0,0,0,1000,1000);
#   pixbuf->save($filename,"png");
# }


1;
__END__



=back

=head2 Discussion

The path measure defines the semantic similarity between two concepts as the
inverse of length of the shortest path between the concepts in the hypernym
trees of WordNet. This module displays the hypernym trees for both the concepts
and the shortest path between these concepts.

The wup measure is based on the method proposed by Wu & Palmer and uses the
depth of the two concepts in the hypernym tree and the depth of the Least Common
Subscumer. It is based on the  This module enables the user to view the
hypertrees for the concepts.  The lch measure implements a semantic measure
proposed by Leacock & Chodrow. It uses the length of the shortest path between
the two concepts and scales it by the maximum depth of the tree to compute the
similarity score. For this measure this module displays the shortest path.

The hso measure measure computes the semantic relatedness between two concepts
using the method proposed Hirst & St-Onge. They define the relatedness between
two concepts based on the quality of links in the lexical chain connecting the
two concepts.

The trace output from these measures is converted to a meta-language. This
meta-language serves as the input ot the visualization module. The trace output
is not used as the input to the visualization, because it might change in the
furure versions of WordNet::Similarity, thus converting it to metalanguage
prevents any of these changes to cause a major changes in the visualization
module.

=head3 Meta-language

The first line in the meta language is the measure name. The next two line list
all the possible shortest paths between the two concepts. The synsets represent
the nodes along these paths, thile the relation names between these synsets
represent the edges. If there is more than one shortest path they are also
listed. The alternate shortest paths are seperated using the OR operator. The
rest of the lines list all the other paths in the hypernym tree. These alternate
hypernym trees also use the same system as used in the shortest path. The next
line is the maximum depth of the hypertree

    path
    cat#n#1 hypernym feline#n#1 hypernym carnivore#n#1
    dog#n#1 hypernym canine#n#2 hypernym carnivore#n#1
    carnivore#n#1 hypernym placental#n#1 hypernym mammal#n#1 hypernym vertebrate#n#1 hypernym
      chordate#n#1 hypernym animal#n#1 hypernym organism#n#1 hypernym living_thing#n#1 hypernym
      object#n#1 hypernym entity#n#1 hypernym Root#n#1
    Max Depth = 13
    Path length = 5


=head1 SEE ALSO

WordNet::Similarity
WordNet::QueryData

Mailing List: E<lt>wn-similarity@yahoogroups.comE<gt>


=head1 AUTHOR

Saiyam Kohli, University of Minnesota, Duluth
kohli003@d.umn.edu

Ted Pedersen, University of Minnesota, Duluth
tpederse@d.umn.edu


=head1 COPYRIGHT

Copyright (c) 2005-2006, Saiyam Kohli and Ted Pedersen

This program is free software; you can purpleistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 2 of the License, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to

    The Free Software Foundation, Inc.,
    59 Temple Place - Suite 330,
    Boston, MA  02111-1307, USA.

Note: a copy of the GNU General Public License is available on the web
at <http://www.gnu.org/licenses/gpl.txt> and is included in this
distribution as GPL.txt.

=cut