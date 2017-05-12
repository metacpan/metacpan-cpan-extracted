package Text::Slidez;
$VERSION = v0.0.1;

use warnings;
use strict;
use Carp;

use base 'Shebangml';
use Class::Accessor::Classy;
lw 'slides';
no  Class::Accessor::Classy;

use XML::Bits qw(T);

=head1 NAME

Text::Slidez - format slideshows into XHTML

=head1 SYNOPSIS

See L<slidez> for the command-line frontend.

  use Text::Slidez;

  my $slidez = Text::Slidez->new;
  $slidez->load('my_slides.hbml');
  foreach my $slide ($slidez->slides) {
    ...
  }

=cut


=head2 load

  $slidez->load('my_slides.hbml');

=cut

sub load {
  my $self = shift;
  my $input = shift;

  local $self->{ctx};
  local $self->{started};

  $self->process($input);

  # bit of cleanup on the innards:
  foreach my $slide ($self->slides) {
    my @kids =
      grep({not ($_->tag eq '' and "$_" eq '')} $slide->children);
    shift(@kids) while($kids[0] =~ m/^\s+$/);
    pop(@kids) if($kids[-1] =~ m/^\n\s*$/);
    $slide->{children} = [@kids];
  }

  #warn join("\n---\n", @{$self->{slides}});
  return($self);
} # load ###############################################################

=head2 dump

Dump a marked-up version of the raw data.

  warn $slidez->dump;

=cut

sub dump {
  my $self = shift;
  return join("\n---\n",
    map({join("|", map({"($_)=" . $_->tag} $_->children))}
      $self->slides)
  ), "\n";
} # dump ###############################################################

=head2 format_slide

Format a single slide for output.

  my $xhtml = $slidez->format_slide($slide, %opts);

=cut

sub format_slide {
  my $self = shift;
  my ($slide, %opts) = @_;

  my @parts = $self->_part_slide($slide);

  # see if we can deduce a title from the first time we see one
  unless($opts{title} or $self->{title}) {
    if($parts[2] and @{$parts[1]} == 0) {
      my $text = join('', @{$parts[0]});
      ($text) = split(/\n/, $text);
      $text =~ s/<[^>]+>//g;
      $self->{title} = $text;
    }
  }

  my $page = T{html =>
    T{head =>
      T{title => $opts{title}||$self->{title}||'slidez'},
      T{meta =>
        ['http-equiv' => "Content-Type",
          content => "text/html;charset=utf-8"]},
      T{meta =>
        ['http-equiv'=>"Content-Style-Type",
          content => "text/css"]},
      T{link =>
        [rel=> 'stylesheet', href => 'style.css', type => 'text/css']},
      T{script => [type => 'text/javascript'],
        $self->_mk_script(%opts);
      },
    },
    T{body =>}
  };
  $page->set_doctype('html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
  "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd"');

  my $div = $page->child(-1)->create_child(div => [class => 'slide']);

  $self->_handle_parts($div, \@parts,
    calc_width => sub {
      my $n = $self->_calc_width(shift);
      $n > 20 ? '900px' : $n . 'em';
    },
  );

  return($page);
  
} # format_slide #######################################################

=head2 as_single_page

  $slidez->as_single_page;

=cut

sub as_single_page {
  my $self = shift;

  my @slides = $self->slides;

  my $page = T{html =>
    T{head =>
      T{title => },
      T{meta =>
        ['http-equiv' => "Content-Type",
          content => "text/html;charset=utf-8"]},
      T{meta =>
        ['http-equiv'=>"Content-Style-Type",
          content => "text/css"]},
      T{link =>
        [rel=> 'stylesheet', href => 'style-flat.css', type => 'text/css']},
    },
    T{body =>}
  };
  $page->set_doctype('html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
  "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd"');

  my $title = $page->child(0)->child(0);
  my $body = $page->child(-1);
  my $outer = $body->create_child(div => [style=> "width: 600px"]);

  for my $i (0..$#slides) {
    my $div = $outer->create_child(div => [class => 'slide']);

    my @parts = $self->_part_slide($slides[$i]);
    unless($i) { # look for title on the first slide
      if($parts[2] and @{$parts[1]} == 0) {
        my $text = join('', @{$parts[0]});
        ($text) = split(/\n/, $text);
        $text =~ s/^\s+//;
        $text =~ s/<[^>]+>//g;
        $title->create_child(''=> $text);
      }
    }

    #warn "\n\nhandle $i\n\n\n";
    $self->_handle_parts($div, \@parts,
      calc_width => sub {
        my $n = $self->_calc_width(shift);
        $n > 20 ? '500px' : $n . 'em';
      },
    );

    $outer->create_child(div =>
      [class => 'wee', style => "width:100%; text-align: right"],
    )->create_child('' => 
      '' => $i+1 . ' / ' . scalar(@slides));
    $outer->create_child(hr =>);
  }

  return($page);
} # as_single_page #####################################################

my %span_map = (
  L => 'large',
  M => 'medium',
  S => 'small',
);

sub _atag {
  my $self = shift;
  my ($tag, $atts) = @_;

  my @attr = $atts ? $atts->atts : ();
  if(my $class = $span_map{$tag}) {
    $tag = 'span';
    push(@attr, class => $class);
  }

  my $el = XML::Bits->new($tag, @attr ? \@attr : ());

  if($self->{ctx}) {
    croak("no nested slides") if($tag eq 'slide');
    $self->{ctx}->add_child($el);
    $self->{ctx} = $el;
  }
  else {
    if($tag eq 'slide') {
      croak("no start element") unless($self->{started});
      my $sl = $self->{slides} ||= [];
      $self->{ctx} = $el;
      push(@$sl, $el);
    }
    elsif($tag eq 'slides') {
      $self->{started} = 1;
    }
    else {
      croak("content '$tag' outside of slide!");
    }
  }

  return($el);
}

=head2 do_code

  $slidez->do_code($tag, $atts, $string);

=cut

sub do_code {
  my $self = shift;
  my ($tag, $atts, $string) = @_;

  my %atts = $atts ? $atts->atts : ();

  my $make = sub {
    my $pre = $self->{ctx}->create_child(pre => [%atts]);
    $pre->create_child('' => $_) for(@_);
  };

  my $ft = delete($atts{type});

  require Text::VimColor;
  my $cache;
  if($string) {
    # XXX how to do the caching?
    # warn "string code is slow: $string\n";
  }
  else {
    my $src = delete $atts{src} or croak("must have src");
    my $input = File::Fu->file($src);
    my $cache_dir = File::Fu->dir('.cache');
    if($cache_dir->d) {
      $cache = $cache_dir + $input->file;
      if($cache->e and $cache->stat->mtime >= $input->stat->mtime) {
        warn "load $input from cache\n";
        return($make->(scalar $cache->read));
      }
    }
    my %ftmap = (
      html => 'html',
      hbml => 'hbml',
      pl   => 'perl',
      pm   => 'perl',
    );
    unless($ft) {
      my ($ext) = $input =~ m/\.([^\.]+)$/;
      $ft = $ftmap{$ext} if($ftmap{$ext});
    }
    $string = $input->read;
  }
  my $html = Text::VimColor->new(
    string   => $string,
    $ft ? (filetype => $ft) : (),
  )->html;

  # leading whitespace cleanup
  $html =~ s{<span[^>]*>(\s+)</span>}{$1}g;
  # pull whitespace out front
  $html =~ s{^(<span [^>]+>)(\s+)}{$2$1}mg;
  $html =~ s/\n+$//;
  $make->($html);
  $cache->write($html) if($cache);
    
} # do_code ############################################################

=head1 Shebangml Callbacks

These are really part of the parser class and not the API.

=head2 put_tag

  $slidez->put_tag($tag, $atts, $string);

=cut

sub put_tag {
  my $self = shift;
  my ($tag, $atts, $string) = @_;

  return $self->do_code(@_) if($tag eq 'code');
  return $self->do_include($atts) if($tag eq '.include');

  my $el = $self->_atag($tag, $atts);

  $el->create_child('' => $self->escape_text($string))
    if(defined($string));

  $self->{ctx} = $el->parent;

} # put_tag ############################################################

=head2 put_tag_start

  $slidez->put_tag_start($tag, $atts);

=cut

sub put_tag_start {
  my $self = shift;
  my ($tag, $atts) = @_;

  my $el = $self->_atag($tag, $atts);

} # put_tag_start ######################################################

=head2 put_tag_end

  $slidez->put_tag_end($tag);

=cut

sub put_tag_end {
  my $self = shift;
  my ($tag) = @_;

  $tag = 'span' if($span_map{$tag});

  my $ctx = delete($self->{ctx});
  return() if($tag eq 'slides');
  ($ctx->tag eq $tag) or croak($ctx->tag, " is not a $tag!");
  croak("context fail $tag")
    unless($self->{ctx} = $ctx->parent or $tag eq 'slide');

} # put_tag_end ########################################################

=head2 put_text

  $slidez->put_text($text);

=cut

sub put_text {
  my $self = shift;
  my ($text) = @_;

  my $ctx = $self->{ctx} or return;
  $ctx->create_child('',
    length($text) ? $self->escape_text($text) : '');
  # TODO escaped text might actually contain some certain tags :-/

} # put_text ###########################################################

=head2 _part_slide

  my @parts = $self->_part_slide($slide);

=cut

sub _part_slide {
  my $self = shift;
  my ($slide) = @_;

  my @children = $slide->children;
  pop(@children) if($children[-1] =~ m/^\s*$/);
  my @parts = ([]);
  my $sp;
  # warn join(",", map({$_->type} @children));
  # if($children[0]->is_text) { # undenting :-/
  #   $children[0]->{content} =~ s/^(\s+)//;
  #   $sp = $1;
  # }
  # warn "sp is >$sp<\n";
  while(@children) {
    my $bit = shift(@children);
    if($bit->is_text and $bit->{content} =~ s/\n$//) {
      #$bit->{content} =~ s/^$sp// if(defined($sp));
      push(@{$parts[-1]}, $bit) if(length($bit));
      push(@parts, []); # start a new group
    }
    else {
      #if($bit->is_text) { $bit->{content} =~ s/^$sp// if(defined($sp)); }
      push(@{$parts[-1]}, $bit);
    }
  }

  foreach my $part (@parts) {
    next unless(@$part);
    shift(@$part)
      while($part->[0]->is_text and $part->[0] =~ m/^\s+$/);
  }

  # drop the trailing chunk
  pop(@parts) if(@{$parts[-1]} == 0);

  if(0) {
    warn "slide:\n";
    warn join("\n---\n", map({join('|', @$_)} @parts)), "\n";
    warn "\n\n\n";
  }

  return(@parts);
} # _part_slide ########################################################

=head2 _calc_width

  my $n = $self->_calc_width($text);

=cut

sub _calc_width {
  my $self = shift;
  my $text = shift;

  my @lines = split(/\n|<br\s*\/>/, $text);
  my ($width) = sort({$b <=> $a}
    map({s/<[^>]+>//g; s/&[^;]+;/./g; length($_)} @lines));
  $width *= 0.625; # emperical em-width adjustment
} # _calc_width ########################################################

=head2 _handle_parts

  $self->_handle_parts($ctx, \@parts, %opts);

=cut

sub _handle_parts {
  my $self = shift;
  my ($ctx, $parts, %opts) = @_;

  my @parts = @$parts;
  my $calc_width = $opts{calc_width};

  if($parts[2] and @{$parts[1]} == 0) {
    my $title_chunk = shift(@parts);
    shift(@parts); # scrap
    $ctx->create_child(div => [class => 'title'], @$title_chunk);
    $ctx->create_child('br');
  }
  else {
    # center the whole thing vertically
    $ctx = $ctx->create_child(div => [class => 'cell']);
  }

  while(@parts) {
    my $part = shift(@parts);
    next unless(@$part);
    if(@$part == 1 and $part->[0] =~ m/^[^<]*<hr\s*\/>[^<]*$/) {
      $ctx->add_child($part->[0]);
      next;
    }
    # pre fixup
    if(@$part == 1 and $part->[0]->tag eq 'pre') {
      my ($pre) = @$part;
      my $text = join('', $pre->children);
      $text =~ s/^\n//;
      if($text =~ s/^(\s+)//) {
        my $sp = $1;
        $text =~ s/^$sp//mg;
      }
      my %atts = $pre->atts;
      my $class = $atts{class} || '';
      $pre->{children} = [];
      $pre->create_child('' => $text);
      my $width = $calc_width->($text);
      my $inner = $ctx->create_child(
        div => [class => "auto left $class",
          style => "width: $width"]);
      $inner->add_child($pre);
      next;
    }
    # bullet points
    if($part->[0] =~ m/^(\s*)\* /) {
      my $sp = $1;
      my @points = $part;
      # then go back to the well:
      while(@parts and $parts[0][0] =~ m/^\s*\* /) {
        push(@points, shift(@parts));
      }
      foreach my $point (@points) {
        $point->[0]->is_text or die;
        $point->[0]->{content} =~ s/^$sp//;
      }

      my $width = $calc_width->(join("\n", map({@$_} @points)));
      my $inner = $ctx->create_child(
        div => [class => "auto left", style => "width: $width"]);
      my $top = $inner->create_child(ul =>);
      my @d = ($top);
      foreach my $point (@points) {
        $point->[0]->{content} =~ s/(\s*)\*\s+//;
        my $ws = length($1)/2;
        # warn "ws: $ws ($point->[0]->{content})\n";
        if($ws) {
          $d[$ws] ||= $d[$ws-1]->child(-1)->create_child(ul =>);
        }
        else {
          @d = ($top);
        }
        $d[$ws]->create_child(li => @$point);
      }
      # warn "yay: $top\n";
      next;
    }
    my $inner = $ctx->create_child(div =>);
    $inner->add_child($_) for(@$part);
  }

} # _handle_parts ######################################################

=head2 _mk_script

  $self->_mk_script(%opts);

=cut

sub _mk_script {
  my $self = shift;
  my (%opts) = @_;

  my $script =
  ($opts{next} ? qq(var next="$opts{next}"\n) .
    "var down=0; document.onmousedown=function(e) { down=1 }\n".
    "           document.onmousemove=function(e) { down=0; }\n".
    "document.onmouseup=function(e) {\n" .
    "if(down == 1) {window.location = next;}; }\n" : ''
  ) .
  ($opts{prev}  ? qq(var prev="$opts{prev}"\n) : '') .
  ($opts{first} ? qq(var first="$opts{first}"\n) : '') .
  ($opts{last}  ? qq(var last="$opts{last}"\n) : '');
  my $func = <<'  ---';
  document.onkeypress=function(e) {
    var e=window.event || e
    var n=e.keyCode || e.which
    switch (n) {
      -SWITCH-
    }
  }
  ---
  my $switch = join("\n", map({$_ . ' break;'}
    ($opts{next}  ? 'case 32 : window.location = next;' : ()),
    ($opts{prev}  ? 'case 8  : window.location = prev;' : ()),
    ($opts{first} ? 'case 36 : window.location = first;' : ()),
    ($opts{last}  ? 'case 35 : window.location = last;'  : ()),
  ));
  $func =~ s/-SWITCH-/$switch/;

  return($script . $func);
} # _mk_script #########################################################

=head1 AUTHOR

Eric Wilhelm @ <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 BUGS

If you found this module on CPAN, please report any bugs or feature
requests through the web interface at L<http://rt.cpan.org>.  I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

If you pulled this development version from my /svn/, please contact me
directly.

=head1 COPYRIGHT

Copyright (C) 2009 Eric L. Wilhelm, All Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# vi:ts=2:sw=2:et:sta
1;
