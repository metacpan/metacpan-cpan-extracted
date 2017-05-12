
=head1 NAME

SaveAs

=head1 SUMMARY

#
#bochner@das.harvard.edu (Harry Bochner) 
#
#Re: Q: How to get FileSelect results
#************************************
#
#6 Dec 1995 22:31:34 GMT Aiken Computation Lab, Harvard University 
#
#Newsgroups: 
#   comp.lang.perl.tk 
#References: 
#   <4a2794$5dv@styx.uwa.edu.au> <30C4C824.41C6@lns62.lns.cornell.edu> 
#
#
#
#In article <30C4C824.41C6@lns62.lns.cornell.edu>, Peter Prymmer  writes:
#|> A while back Mark Elston posted "FileSave.pm" it is available on the
#|>  http://sun20.ccd.bnl.gov/~ptk/archive/ptk.1995.10/0093.html
#
#Thanks, I had missed that. Here's what I'm currently using; instead of replacing
#all the existing code in FileSelect, it subclasses it to rearrange the widgets
#and change their behavior slightly.
#
#In my version a click in the file list copies the entry to file_entry widget;
#accept then accepts whatever's in that widget, whether it was typed or copied
#there.
#
#Comments on subclassing technique welcome.
#

=head1 DATE

6 Dec 1995 22:31:34 GMT Aiken Computation Lab, Harvard University 

=head1 AUTHOR 
 
Harry Bochner
bochner@das.harvard.edu

=cut

package SaveAs;
use Tk::FileSelect;
@ISA = qw(Tk::FileSelect);
Tk::Widget->Construct('SaveAs');

sub Populate {
  my($w, $args) = @_;
  my($e);

  $w->InheritThis($args);

  $e = $w->subwidget('file_entry');
  $e->pack(-side => "top");
  $e->bind("" => [$w, "Accept"]);

  $w->subwidget('dir_entry')->pack(-side => "bottom");
  $w->subwidget('file_list')->bind("", [$w, 'file_click']);
}

sub file_click {
  my($z) = @_;
  my($str) = $z->subwidget('file_list')->Getselected;
  my($e)   = $z->subwidget('file_entry');

  $e->delete(0, "end");
  $e->insert(0, $str);
}

sub Accept {
  my($z) = @_;

  $z->{Selected} = [join("/",
                         $z->cget('-directory'),
                         $z->subwidget('file_entry')->get)];
}

1;

__END__

