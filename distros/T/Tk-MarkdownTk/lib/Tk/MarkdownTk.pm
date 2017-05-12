package Tk::MarkdownTk;

use 5.006;
use strict;
use warnings FATAL => 'all';

=head1 NAME

Tk::MarkdownTk - a Tk::Markdown with tk widget tag support

=head1 VERSION

Version 0.07

=cut

our $VERSION = '0.07';

use Tk::Markdown;
use base qw(Tk::Derived Tk::Markdown);
Construct Tk::Widget 'MarkdownTk';






=head1 SYNOPSIS

	use Tk;
	use Tk::MarkdownTk;

	my $mw = new MainWindow();
    my $mdt = $mw->MarkdownTk();

	$mdt->insert(q{
		some markdown here

		with tags like this: <Tk::Button -text="Click me!">
	});

=head1 SUBROUTINES/METHODS

=head2 insert

Whenever insert is called on the MarkdownTk, 
some translation is done on the text in order to
diplay it nicely as markdown.  Tables are reformatted
(if the line starts with a bar) and headers are
tagged with different fonts.

This module is currently under development and
there's plenty to do, e.g. links, images, etc.

In MarkdownTk, html-ish tags are also transformed
into Tk widgets.

=cut


sub insert
{
  my ($self,$index,$content) = @_;
  my $res = $self->SUPER::insert($index,Tk::Markdown::FormatMarkdown($content));
  if(! $self->{inserting}){ ### don't allow recursion...
    $self->{inserting} = 1;
    $self->PaintMarkdown();
    $self->TransformTk();
    $self->see("1.0");
    $self->{inserting} = 0;
  }
  return $res;
}

=head2 TransformTk

This is called internally.  It parses out HTML-like tags that define Widgets to be drawn
in the text.

eg

	<Tk::Button -text="Click Me">

Also, perl can be run from the document... a Tk::Markdown allows <% %> which
is run prior to insertion (good for formatting) but Tk::MarkdownTk adds running
perl from <? ?>, which gets replaced inline, after insertion.  This is good for
adding named subs in the same namespace as the buttons and other tk widgets
added to the text area.  Eg:

	<Tk::Button -text="Click me" -command="run_this">
	<? sub run_this { print "Hello, world!\n"; } ?>

So remember:
	
	% formatted
	
	? subs


=cut

### look for <tags> (the other kind of tags) to be tranformed into actual widgets
sub TransformTk {
  my $self = shift;
  ### this is to find <tk::widget attributes>, or <? ?> script.
  my $re = qr/<Tk\:\:\w+[^>]*>|<\?.*?\?>/s;
  $self->FindAll('-regexp','-case', $re);
  my @i = $self->tagRanges('sel');
  #print map {"$_\n"} @i;
  for(my $i = @i-2; $i >= 0; $i-=2){
    my ($s,$e) = ($i[$i], $i[$i+1]);
    my $string = $self->get($s,$e);
    if($string =~ /<Tk\:\:(\w+)(.*)>/){
      my ($w,$a) = ($1,$2);
      my %a = parseAttrs($a);
      $self->delete($s,$e);
      my $t = $self->$w(%a);
      $self->windowCreate($s,-window=>$t);
    }
    elsif($string =~ /<\?=(.*)\?>/s){
      my $sub;
      eval("\$sub = sub { $1 }");
      die "$@ - somewhere in: $1" if $@;
      $self->delete($s,$e);
      $self->insert($s,&$sub());
    }
    elsif($string =~ /<\?(.*)\?>/s){
      $self->delete($s,$e);
      eval("$1");
      die "$@ - somewhere in: $1" if $@;
      die $@ if $@;
    }
  }
}

=head2 parseAttrs

A helper function for TransformTk.

=cut

### parse some attributes
sub parseAttrs {
  my ($attrs) = @_;
  my %attrs = ();
  while($attrs =~ /\G.*?([\w-]+)(=""|=''|=".*?[^\\]"|='.*?[^\\]'|=[^"']\S*|)/g){
    my ($k,$v) = ($1,$2);
    $v ||= 1;
    $v =~ s/^=//;
    $v =~ s/^(["'])(.*)\1$/$2/;
    if($k =~ /^-(?:command)$/){
      eval(" \$v = sub { $v }; ");
      die "$@ - somewhere in: $v" if $@;
      #print "COMMAND: $v\n";
    }
    $attrs{$k} = $v;
  }
  return %attrs;
}


=head2 clipEvents

This copied directly from Tk::ROText

=cut

sub clipEvents
{
  return qw[Copy];
}

=head2 ClassInit

This is copied directly from Tk::ROText.

=cut

sub ClassInit
{
  my ($class,$mw) = @_;
  my $val = $class->bindRdOnly($mw);
  my $cb = $mw->bind($class,'<Next>');
  $mw->bind($class,'<space>',$cb) if (defined $cb);
  $cb = $mw->bind($class,'<Prior>');
  $mw->bind($class,'<BackSpace>', $cb) if (defined $cb);
  $class->clipboardOperations($mw,'Copy');
  return $val;
}

=head2 Populate

This is copied and modified from Tk::ROText.  The modification is the addition
of a call to setDefaultStyles.  That's all.

=cut

sub Populate
{
  my ($self,$args) = @_;
  $self->SUPER::Populate($args);
}


=head2 Tk::Widget::ScrlMarkdownTk

Copied and adapted from Tk::ROText

=cut

sub Tk::Widget::ScrlMarkdownTk { shift->Scrolled('MarkdownTk' => @_) }



=head1 AUTHOR

jimi, C<< <jimi at webu.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-tk-markdowntk at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tk-MarkdownTk>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tk::MarkdownTk


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tk-MarkdownTk>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Tk-MarkdownTk>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Tk-MarkdownTk>

=item * Search CPAN

L<http://search.cpan.org/dist/Tk-MarkdownTk/>

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

1; # End of Tk::MarkdownTk
