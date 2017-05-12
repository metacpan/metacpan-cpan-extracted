package Tk::MIMEApp;
use base qw(Tk::Derived Tk::NoteBook);
use IO::File;
use MIME::Multipart::Parse::Ordered;
use Tk::MarkdownTk;
use YAML::Perl;
use Tk qw(Ev);

use 5.006;
use strict;
use warnings FATAL => 'all';

=head1 NAME

Tk::MIMEApp - The great new Tk::MIMEApp!

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

our @Shelf = (); # we'll put our books here!

Construct Tk::Widget 'MIMEApp';

=head1 SYNOPSIS

ISA Tk::Notebook.  Can load MIME Multipart file with
application/x-ptk.markdown parts, converting them to
Tk (with Tk::MarkdownTk) for document-driven applications.

=head1 SUBROUTINES/METHODS

=head2 loadMultipart

Method that takes a filehandle and adds a page to the notebook
for each application/x-ptk.markdown part.  Will also add menu items
to the toplevel menu for application/x-yaml.menu parts.

=cut

sub loadMultipart {
  # load a MIME-multipart-style file containing at least one application/x-ptk.markdown
  my ($o,$fh) = @_;
  $o->{Objects} = {};
  push @Shelf, $o;
  my $mmps = MIME::Multipart::Parse::Ordered->new();
  my $parts = $o->{parts} = $mmps->parse($fh); # now an array... content is in $parts->[$i]->{Body}

  foreach my $part(@$parts){
    my $ct = $part->{'Content-Type'};
    if($ct eq "application/x-ptk.markdown"){

      # work out the IDs
      my $id = exists $part->{'ID'} ? $part->{'ID'} : "O$part";
      my $textid = $id.'_text';
      my $pageid = $id.'_page';

      # set up the page
      my $name = exists $part->{"Title"} ? $part->{"Title"} : "$part";
      my %u = ();
      if($name =~ /_/){
        %u = (-underline=>length($`) );
        $name = $`.$';
      }
      my $page = $o->add($id, -label=>$name, -state=>'normal', %u); # more options needed here!
      
      # set up the text
      my $text = $page->Scrolled('MarkdownTk',-scrollbars=>'se')->pack(-expand=>1,-fill=>'both');
      $text->insert('end',$part->{Body});
      
      # add the objects to the Objects property
      $o->{Objects}->{$textid} = $text;
      $o->{Objects}->{$pageid} = $page;
    }
    elsif($ct eq "multipart/mixed"){
      if($part->{"Title"}){
        $o->toplevel->configure(-title=>$part->{"Title"});
      }
      $o->{Objects}->{Main} = $part;
    }
    elsif($ct eq 'application/x-yaml.menu'){
      $o->toplevel->configure(
        -menu => yaml2menu(
          $part->{Body},  
          $o->toplevel->Menu(-tearoff=>0,-type=>'menubar')
        )
      );
    }
    elsif($ct eq 'application/x-perl'){
      eval ($part->{Body});
    }
  }
}

=head2 yaml2menu

Accepts some yaml (scalar) and a Tk::Menu as arguments, and populates
the menu from the yaml.  Uses YAML::Perl for parsing.

=cut

sub yaml2menu {
  # convert a yaml-like text to a tk menu
  my ($yaml,$menu) = @_;
  my $data = Load $yaml;
  return array2menuitems($menu,$data);
}

=head2 array2menuitems

Takes a Tk::Menu and and arrayref describing
items and implements them.  Called by yaml2menu.

=cut

sub array2menuitems {
  my ($menu, $array) = @_;
  my @opts = qw/activebackground activeforeground accelerator background bitmap columnbreak compound 
            command font foreground hidemargin image indicatoron label menu offvalue onvalue selectcolor 
            selectimage state underline value variable /;
  my $patt = join('|',@opts);
  my $re = qr/^-(?:$patt)$/;
  foreach my $a(@$array){
    my %v = map {'-'.$_ => $a->{$_}} keys %$a;
    my $type = 'command';
    foreach (keys %v){
      if(! /$re/){          ## if this key is not a regular key...
        $v{'-label'} = substr($_,1);  ### use as label ... removing the leading '-'
        my $p = $v{$_};     ### save value
        delete $v{$_};      ### delete
        if(ref $p){         # it's an array... make a cascade menu...
          $type = 'cascade';
          $v{'-menu'} = array2menuitems(
            $menu->Menu(-type=>'normal',-tearoff=>0),
            $p
          );
        }
        else {
          $v{'-command'} = $p;
        }
      } # endif
    } # innerloop
    ### now we should have a set of options...

    ## setting up labels and indicides...
    if($v{'-label'} =~ /_/){
      $v{'-underline'} = length($`);
      $v{'-label'} = $`.$';
    }

    ## separators...
    if($v{'-label'} =~ /^-+$/){
      %v = (); # delete all parameters!
      $type = 'separator';
    }

    $menu->add($type, %v);

  } # outerloop
  return $menu;
}



### these few subs are taken directly from ROText...

=head2 ClassInit

Used internally

=cut

sub ClassInit
{
  my ($class,$mw) = @_;
  # class binding does not work right due to extra level of
  # widget hierachy
  $mw->bind($class,'<ButtonPress-1>', ['MouseDown',Ev('x'),Ev('y')]);
  $mw->bind($class,'<ButtonRelease-1>', ['MouseUp',Ev('x'),Ev('y')]);

  $mw->bind($class,'<B1-Motion>', ['MouseDown',Ev('x'),Ev('y')]);
  $mw->bind($class,'<Left>', ['FocusNext','prev']);
  $mw->bind($class,'<Right>', ['FocusNext','next']);

  $mw->bind($class,'<Return>', 'SetFocusByKey');
  $mw->bind($class,'<space>', 'SetFocusByKey');
  return $class;
}

=head2 Populate

Used internally

=cut

sub Populate
{
  my ($self,$args) = @_;
  $self->SUPER::Populate($args);
  $self->ConfigSpecs(-background=>['SELF'], -foreground=>['SELF'],);
  # do other stuff here...
}




=head1 AUTHOR

jimi, C<< <jimi at webu.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-tk-mimeapp at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tk-MIMEApp>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tk::MIMEApp


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tk-MIMEApp>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Tk-MIMEApp>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Tk-MIMEApp>

=item * Search CPAN

L<http://search.cpan.org/dist/Tk-MIMEApp/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 jimi.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Tk::MIMEApp
