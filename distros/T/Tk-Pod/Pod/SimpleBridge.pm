
require 5;
use strict;
package Tk::Pod::SimpleBridge;
# Interface between Tk::Pod and Pod::Simple

use vars qw($VERSION);
$VERSION = '5.07';

BEGIN {  # Make a DEBUG constant very first thing...
  if(defined &DEBUG) {
  } elsif(($ENV{'TKPODDEBUG'} || '') =~ m/^(\d+)/) { # untaint
    my $debug = $1;
    *DEBUG = sub () { $debug };
  } else {
    *DEBUG = sub () {0};
  }
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

use Pod::Simple::PullParser;
use Tk::Pod::Styles;
use vars qw(@ISA);
@ISA = qw(Tk::Pod::Styles);

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub no_op {return}

sub process { # main routine: non-handler
  my ($w,$file_or_textref, $title) = @_;  # window, filename or string ref, title (optional)

  my $p = $w->{'pod_parser'} = Pod::Simple::PullParser->new;
  $p->set_source($file_or_textref);
  my $file = !ref $file_or_textref && $file_or_textref;

  $w->toplevel->Busy;
  $w->init_styles;

  my $process_no;
  $w->{ProcessNo}++;
  $process_no = $w->{ProcessNo};

  $w->{'sections'} = [];
  $w->{'pod_tag'} = '10000'; # counter
#XXX  my $style_stack = $w->{'style_stack'} ||= []; # || is probably harmful
  my $style_stack = $w->{'style_stack'} = [];

  my @pod_marks;

  DEBUG and $file and warn "Pull-parsing $file (process number $process_no)\n";
  $w->{'pod_title'} = $p->get_short_title || $title || $file;

  my($token, $tagname, $style);
  my $last_update = Tk::timeofday();
  my $current_line;
  while($token = $p->get_token) {

    DEBUG > 7 and warn " t:", $token->dump, "\n";
    if($token->can("attr_hash") && exists $token->attr_hash->{start_line}) {
      $current_line = $token->attr_hash->{start_line};
    }

    if($token->is_text) {
      DEBUG > 10 and warn " ->pod_text( ", $token->text, ",", $current_line, ")\n";
      $w->pod_text( $token, $current_line );

    } elsif($token->is_start) {
      ($tagname = $token->tagname ) =~ tr/-:./__/;
      $style    = "style_"     . $tagname;
      $tagname  = "pod_start_" . $tagname;
      DEBUG > 7 and warn " ->$tagname & ->$style\n";
      push @pod_marks, $w->index('end -1c');
       # Yes, save the start-point for every element,
       #  for feeding to its end-tag event.

      if( $w->can($style) ) {
        push @$style_stack,  $w->$style($token);
        DEBUG > 5 and warn "Style stack after adding ->$style: ",
         join("|", map join('.',@$_), @{ $w->{'style_stack'} } ), "\n";
      }

      &{ $w->can($tagname) || next }( $w, $token );
      DEBUG > 10 and warn "   back from ->$tagname\n";

    } elsif($token->is_end) {
      ($tagname = $token->tagname ) =~ tr/-:./__/;
      $style    = "style_"   . $tagname;
      $tagname  = "pod_end_" . $tagname;

      DEBUG > 7 and warn " ->$tagname & $style\n";

      &{ $w->can($tagname) || \&no_op }( $w, $token, pop(@pod_marks) );
       # the output of that pop() is the start-point of this element
      DEBUG > 10 and warn "   back from ->$tagname\n";

      if( $w->can($style) ) {
        pop @$style_stack;
        DEBUG > 5 and warn "Style stack after popping results of ->$style: ",
         join("|", map join('.',@$_), @{ $w->{'style_stack'} } ), "\n";
      }
    }

    if (Tk::timeofday() > $last_update+0.5) { # XXX make configurable
      $w->update;
      $last_update = Tk::timeofday();
      do { warn "ABORT!"; return } if $w->{ProcessNo} != $process_no;
    }

  }

  undef $p;
  delete $w->{'pod_parser'};
  DEBUG and $file and warn "Done rendering $file\n";

  $w->parent->add_section_menu if $w->parent->can('add_section_menu');
  $w->Callback('-poddone', $file);
  # set (invisible) insertion cursor to top of file
  $w->markSet(insert => '@0,0');
  $w->toplevel->Unbusy;
}

###########################################################################

sub pod_text {
  my($w, $t, $current_line) = @_;
  if( $w->{'pod_in_X'} ) {
    # no-op
  } else {
    # Emit it with whatever styles are in effect.

    my %attributes = (map @$_, @{ $w->{'style_stack'} } );
    DEBUG > 4 and warn "Inserting <", $t->text, "> with attributes: ",
      join('/', %attributes), "\n";

    my $startpoint = $w->index('end -1c');
    $w->insert( 'end -1c', $t->text, "start_line_" . $current_line );
   
    $w->tag(
      'add',
      $w->tag_for(\%attributes),
      $startpoint => 'end -1c'
    );
  }
  return;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub pod_start_Document {
  $_[0]->toplevel->title( "Tkpod: " . $_[0]->{'pod_title'} . " (loading)");
  $_[0]->toplevel->update;
  # XXX  Is it bad form to manipulate the top level?
  return;
}

sub pod_end_Document {
  $_[0]->toplevel->title( "Tkpod: " . $_[0]->{'pod_title'});
  $_[0]->toplevel->update;
  # XXX  Is it bad form to manipulate the top level?
  return;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub nlnl { $_[0]->insert( 'end -1c', "\n\n" ); $_[0]; }
sub nl { $_[0]->insert( 'end -1c', "\n" ); $_[0]; }

sub fake_unget_bold_text {
  require Pod::Simple::PullParserStartToken;
  require Pod::Simple::PullParserTextToken;
  require Pod::Simple::PullParserEndToken;

  $_[0]{'pod_parser'}->unget_token(
    Pod::Simple::PullParserStartToken->new('B'),
    Pod::Simple::PullParserTextToken->new($_[1]),
    Pod::Simple::PullParserEndToken->new('B'),
  );
}

sub pod_start_item_bullet {
  $_[0]->fake_unget_bold_text('* ');
}
sub pod_start_item_number {
  $_[0]->fake_unget_bold_text($_[1]->attr('number') . '. ');
}

sub pod_end_Para        { $_[0]->_indent($_[2]); $_[0]->nlnl }
sub pod_end_Verbatim    { $_[0]->_indent($_[2]); $_[0]->nlnl }
sub pod_end_item_bullet { $_[0]->_indent($_[2]); $_[0]->nlnl }
sub pod_end_item_number { $_[0]->_indent($_[2]); $_[0]->nlnl }
sub pod_end_item_text   { $_[0]->_indent($_[2]); $_[0]->nl }

sub pod_end_over_text   { $_[0]->nl } # XXX ok?

sub _indent {
  my ($w, $start) = @_;

  my $indent = 0;
  foreach my $s (@{ $w->{'style_stack'} }) {
    $indent += $s->[1] if @$s and $s->[0] eq 'indent';
     # yes, indent is special -- it always has to be first
  }
  $indent = 0 if $indent < 0;
  
  DEBUG > 5 and warn "Style stack giving indent of $indent for $start: ",
         join("|", map join('.',@$_), @{ $w->{'style_stack'} } ), "\n";
  
  my $tag = "Indent" . ($indent+0);
  unless (exists $w->{'pod_indent_tag_known'}{$tag}) {
    $w->{'pod_indent_tag_known'}{$tag} = 1;
    
    $indent *= 8;  # XXX  Why 8?
    
    $w->tag('configure' => $tag,
            '-lmargin2' => $indent . 'p',
            '-rmargin'  => $indent . 'p',
            '-lmargin1' => $indent . 'p'
           );
  }
  $w->tag('add', $tag, $start, 'end -1c');
  DEBUG > 3 and warn "Applying $tag to $start\n";
  return;
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# All we need for X<...>, I think:
sub pod_start_X { $_[0]{'pod_in_X'}++; return; }
sub pod_end_X   { $_[0]{'pod_in_X'}--; return; }
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub tag_for {
  my($w, $attr) = @_;
  my $canonical_form =
    join( '~', map {; $_, $attr->{$_}}
      sort
        grep $_ ne 'indent',
          keys %$attr
  ) || 'nihil';
  
  return
    $w->{'known_tags'}{$canonical_form} ||=
    do {
      # initialize and return a new tagname
      DEBUG and warn "Making a tag for $canonical_form\n";
      $attr->{'family'}  = 'times'  unless exists $attr->{'family'};
      $attr->{'weight'}  = 'medium' unless exists $attr->{'weight'};
      $attr->{'slant'}   = 'r'      unless exists $attr->{'slant'};
      $attr->{'size'}    = 10       unless exists $attr->{'size'};
      $attr->{'spacing'} = '*'      unless exists $attr->{'spacing'};
      $attr->{'slant'}   = substr( $attr->{'slant'},0,1 );
      
      my $font_name = join ' ',
        $attr->{'family'},
        $attr->{'size'},
        ($attr->{'weight'} ne 'medium') ? 'bold'   : (),
        ($attr->{'slant'}  ne 'r'     ) ? 'italic' : (),
      ;
      
      DEBUG and warn "Defining new tag $canonical_form with font $font_name\n";
      
      $w->tagConfigure(
        $canonical_form,
        '-font' => $font_name,
        ('none' eq ($attr->{'wrap'} || '')) ? ('-wrap' => 'none') : (),
        $attr->{'underline'} ? ('-underline' => 'true') : (),
	(map { defined $attr->{$_} ? ("-$_" => $attr->{$_}) : () } qw(background borderwidth relief lmargin1 rmargin)),
      );
      DEBUG > 10 and sleep 1;
      $canonical_form;
    }
  ;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub pod_start_L {
  push @{ $_[0]->{'pod_L_attr_stack'} }, $_[1]->attr_hash;
}

sub pod_end_L   {
  my $w = $_[0];
  my $attr = pop @{ $w->{'pod_L_attr_stack'} };

  #$w->tag('add', 'L' , $_[2], 'end -1c');
  
  my $tag = # make a unique identifier for this guy:
    join "__", '!',
      map defined($_) ? $_ : '',
        @$attr{'type', 'to', 'section'};
    #"!" . $attr->{'to'}
  ;
  $tag =~ tr/ /_/;
  DEBUG > 2 and warn "Link-tag <$tag>\n";
  
  my $to      = $attr->{'to'}     ; # might be undef!
  my $section = $attr->{'section'}; # might be undef!
  
  my $methodname;
  if($attr->{'type'} eq 'pod')      {
    #$methodname = defined($to) ? 'Link' : 'Link_my_section';
    $methodname = 'Link';
  } elsif($attr->{'type'} eq 'url') {
    $methodname = 'Link_url'
  } elsif($attr->{'type'} eq 'man') {
    $methodname = 'Link_man'
  } else {
    DEBUG and warn "Unknown link-type $$attr{'type'}!\n";
  }

  $section = '' . $section if defined $section and ref $section;

  if(!defined $methodname) {
    DEBUG > 2 and warn "No method for $$attr{'type'} links.\n";
  } elsif($w->can($methodname)) {
    DEBUG > 2 and warn "Binding $tag to $methodname\n";
    $w->tag('bind', $tag, '<ButtonRelease-1>',
            [$w, $methodname, 'reuse', Tk::Ev('@%x,%y'), $to, $section]);
    $w->tag('bind', $tag, '<Shift-ButtonRelease-1>',
            [$w, $methodname, 'new',   Tk::Ev('@%x,%y'), $to, $section]);
    $w->tag('bind', $tag, '<ButtonRelease-2>',
            [$w, $methodname, 'new',   Tk::Ev('@%x,%y'), $to, $section]);
    $w->tag('bind', $tag, '<Enter>' => [$w, 'EnterLink']);
    $w->tag('bind', $tag, '<Leave>' => [$w, 'LeaveLink']);
    $w->tag('configure', $tag, '-underline' => 1, '-foreground' => 'blue' );
  } else {
    DEBUG > 2 and warn "Can't bind $tag to $methodname\n";
    # green for no-good
    $w->tag('configure', $tag, '-underline' => 1, '-foreground' => 'darkgreen' );
  }
  $w->tag('add', $tag, $_[2] ,'end -1c');
  $w->tag('add', 'pod_link', $_[2] ,'end -1c'); # needed for ButtonRelease-2 hack, see Pod/Text.pm

  return;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub pod_start_head1 { $_[0]->_common_heading('head1'); }
sub pod_start_head2 { $_[0]->_common_heading('head2'); }
sub pod_start_head3 { $_[0]->_common_heading('head3'); }
sub pod_start_head4 { $_[0]->_common_heading('head4'); }

sub pod_end_head1 {  $_[0]->nlnl }
sub pod_end_head2 {  $_[0]->nlnl }
sub pod_end_head3 {  $_[0]->nlnl }
sub pod_end_head4 {  $_[0]->nlnl }

sub _common_heading {
  my $w = $_[0];
  my $p = $w->{'pod_parser'};
  my $end_tag = $_[1];
  
  my @to_put_back;
  my $text = '';
  my $token;
  my $in_X = 0;
  while($token = $p->get_token) {
    push @to_put_back, $token;
    if( $token->is_end ) {
      last if $token->is_tag($end_tag);
      --$in_X if $token->is_tag('X');
    } elsif($token->is_start) {
      ++$in_X if $token->is_tag('X');
    } elsif($token->is_text) {
      $text .= $token->text unless $in_X;
    }
    last if @to_put_back > 40; # too complex a heading!
  }

  if(length $text) {
    my $level;
    $end_tag =~ m/(\d+)$/ or die "WHAAAT?  $end_tag!?";
    $level = $1;
    push @{$w->{'sections'}}, [$level, $text, $w->index('end')];
    DEBUG and warn "Noting section heading head$level \"$text\".\n";
  }

  $p->unget_token(@to_put_back);
  return;
}

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
1;
__END__

=head1 NAME

Tk::Pod::SimpleBridge -- render Pod::Simple events to a Tk::Pod window

=head1 SYNOPSIS

  [
    This is a class internal to Tk::Pod.
    No user-serviceable parts inside.
  ]

=head1 DESCRIPTION

This class contains methods that L<Tk::Pod> (specifically L<Tk::Pod::Text>)
uses to render a pod page's text into its window.  It uses L<Pod::Simple>
(specifically L<Pod::Simple::PullParser>) to do the parsing.

L<Tk::Pod> used to use Tk::Parse (a snapshot of an old old Pod-parser)
to do the Pod-parsing.  But it doesn't anymore -- it now uses L<Pod::Simple>
via this module.

=head1 COPYRIGHT AND DISCLAIMERS

Copyright (c) 2002 Sean M. Burke.  All rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=head1 AUTHOR

Sean M. Burke <F<sburke@cpan.org>>, with bits of Tk code cribbed from
the old Tk::Pod::Text code that Nick Ing-Simmons
<F<nick@ni-s.u-net.com>> originally wrote.

Current maintainer is Slaven ReziE<0x0107> <F<slaven@rezic.de>>.

=cut
