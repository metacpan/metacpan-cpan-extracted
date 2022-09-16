package Valiant::HTML::TagBuilder;

use warnings;
use strict;
use Exporter 'import';
use Valiant::HTML::SafeString ':all';
use Scalar::Util 'blessed';

our $ATTRIBUTE_SEPARATOR = ' ';
our %SUBHASH_ATTRIBUTES = map { $_ => 1} qw(data aria);
our %ARRAY_ATTRIBUTES = map { $_ => 1 } qw(class);
our %HTML_VOID_ELEMENTS = map { $_ => 1 } qw(area base br col circle embed hr img input keygen link meta param source track wbr);
our %BOOLEAN_ATTRIBUTES = map { $_ => 1 } qw(
  allowfullscreen allowpaymentrequest async autofocus autoplay checked compact controls declare default
  defaultchecked defaultmuted defaultselected defer disabled enabled formnovalidate hidden indeterminate
  inert ismap itemscope loop multiple muted nohref nomodule noresize noshade novalidate nowrap open
  pauseonexit playsinline readonly required reversed scoped seamless selected sortable truespeed
  typemustmatch visible);

our %HTML_CONTENT_ELEMENTS = map { $_ => 1 } qw(
  a abbr acronym address apple article aside audio
  b basefont bdi bdo big blockquote body button
  canvas caption center cite code colgroup
  data datalist dd del details dfn dialog dir div dl dt
  em
  fieldset figcaption figure font footer form frame frameset
  head header hgroup h1 h2 h3 h4 5 h6 html
  i iframe ins
  kbd label legend li
  main map mark menu menuitem meter
  nav noframes noscript
  object ol optgroup option output
  p picture pre progress
  q
  rp rt ruby
  s samp script section select small span strike strong style sub summary sup svg
  table tbody td template textarea tfoot th thead time title  tt
  u ul
  var video);

our @ALL_HTML_TAGS = ('trow', keys(%HTML_VOID_ELEMENTS), keys(%HTML_CONTENT_ELEMENTS));
our @ALL_FLOW_CONTROL = (qw(cond otherwise over loop));
our @EXPORT_OK = (qw(tag content_tag capture), @ALL_HTML_TAGS, @ALL_FLOW_CONTROL);
our %EXPORT_TAGS = (
  all => \@EXPORT_OK,
  utils => ['tag', 'content_tag', 'capture', @ALL_FLOW_CONTROL],
  html => \@ALL_HTML_TAGS,
  form =>[qw/form input select options button datalist fieldset label legend meter optgroup output progress textarea/],
  headers => [qw/h1 h2 h3 h4 5 h6 header/],
  table => [qw/table td th tbody thead tfoot trow caption/],
);

sub _dasherize {
  my $value = shift;
  my $copy = $value;
  $copy =~s/_/-/g;
  return $copy;
}

sub _tag_options {
  my (%attrs) = @_;
  return '' unless %attrs;
  my @attrs = ('');
  foreach my $attr (sort keys %attrs) {
    if($BOOLEAN_ATTRIBUTES{$attr}) {
      push @attrs, $attr if $attrs{$attr};
    } elsif($SUBHASH_ATTRIBUTES{$attr}) {
      foreach my $subkey (sort keys %{$attrs{$attr}}) {
        push @attrs, _tag_option("${attr}-@{[ _dasherize $subkey ]}", $attrs{$attr}{$subkey});
      }
    } elsif($ARRAY_ATTRIBUTES{$attr}) {
      my $class = ((ref($attrs{$attr})||'') eq 'ARRAY') ? join(' ', @{$attrs{$attr}}) : $attrs{$attr};
      push @attrs, _tag_option($attr, $class);
    } else {
      push @attrs, _tag_option($attr, $attrs{$attr});
    }
  }
  return join $ATTRIBUTE_SEPARATOR, @attrs;
}

sub _tag_option {
  my ($attr, $value) = @_;
  return qq[${attr}="@{[ escape_html(( defined($value) ? $value : '' )) ]}"];
}

sub tag {
  my ($name, $attrs) = (@_, +{});
  if(exists $attrs->{omit_tag}) {
    my $omit_tag = delete $attrs->{omit_tag};
    return '' if $omit_tag;
  }

  die "'$name' is not a valid VOID HTML element" unless $HTML_VOID_ELEMENTS{$name};
  return raw "<${name}@{[ _tag_options(%{$attrs}) ]}/>";
}

sub content_tag {
  my $name = shift;
  die "'$name' is a VOID HTML element" if $HTML_VOID_ELEMENTS{$name};
  my $block = ref($_[-1]) eq 'CODE' ? pop(@_) : undef;
  my $attrs = ref($_[-1]) eq 'HASH' ? pop(@_) : +{};
  my $content = flattened_safe(defined($block) ? $block->() : (shift || ''));

  if(exists $attrs->{omit_tag}) {
    my $omit_tag = delete $attrs->{omit_tag};
    return $content if $omit_tag;
  }

  return raw "<${name}@{[ _tag_options(%{$attrs}) ]}>$content</${name}>";
}

sub capture {
  my $block = shift;
  return flattened_safe $block->(@_);
}

## TODO 
## trinary or some sort of otherwise for cond
## better $index for things like is_last is_first is_even/odd, etc

sub html_content_tag {
  my $tag = shift;
  my $attrs = (ref($_[0])||'') eq 'HASH' ? shift(@_) : +{};
  my $content;

  if(exists $attrs->{cond}) {
    my $cond = delete $attrs->{cond};
    unless($cond) {
      shift @_ unless $HTML_VOID_ELEMENTS{$tag}; # throw away the content if a content tag
      return @_;
    }
  }

  if(exists $attrs->{map}) {
    my $map = delete $attrs->{map};
    my $code = shift @_; # must be code.

    my $index = 0;
    my @content = ();
    if(blessed($map) && $map->can('next')) {
      while (my $next = $map->next) {
        push @content, content_tag($tag, $code->($next, $index), $attrs);
        $index++;
      }
      $map->reset if $map->can('reset');
    } else {
      foreach my $item (@$map) {
        push @content, content_tag($tag, $code->($item, $index), $attrs);
        $index++;
      }
    }
    return \@content, @_;
  }

  if( (ref(\$_[0])||'') eq 'SCALAR' ) {  # or isa SafeString...
    $content = shift(@_);
  } elsif(blessed($_[0]) && $_[0]->isa('Valiant::HTML::SafeString') ) {
    $content = shift(@_);
  } elsif( (ref($_[0])||'') eq 'ARRAY' ) {
    $content = concat(@{shift(@_)});
  } elsif( (ref($_[0])||'') eq 'CODE' ) {
    my $code = shift;
    if(my $repeated = delete $attrs->{repeat}) {
      my $index = 0;
      my @content = ();
      if(blessed($repeated) && $repeated->can('next')) {
        while (my $next = $repeated->next) {
          push @content, $code->($next, $index);
          $index++;
        }
        $repeated->reset if $repeated->can('reset');
      } else {
        foreach my $item (@$repeated) {

          push @content, $code->($item, $index);
          $index++;
        }
      }
      $content = concat(@content);
    }
    $content = concat(shift->()) unless $content;
  }


  return defined($content) ?
    (content_tag($tag, $content, $attrs), @_) :
    (tag($tag, $attrs), @_);
}

sub html_tag {
  my $tag = shift;
  my $attrs = (ref($_[0])||'') eq 'HASH' ? shift(@_) : +{};

  if(exists $attrs->{cond}) {
    my $cond = delete $attrs->{cond};
    unless($cond) {
      shift @_ unless $HTML_VOID_ELEMENTS{$tag}; # throw away the content if a content tag
      return @_;
    }
  }

  if(exists $attrs->{map}) {
    my $map = delete $attrs->{map};
    my $index = 0;
    my @content = ();
    if(blessed($map) && $map->can('next')) {
      while (my $next = $map->next) {
        foreach my $key (keys %$attrs) {
          $attrs->{$key} = $attrs->{$key}->($next, $index) if (ref($attrs->{$_})||'') eq 'CODE';
        }
        push @content, tag($tag, $attrs);
        $index++;
      }
      $map->reset if $map->can('reset');
    } else {
      foreach my $item (@$map) {
        foreach my $key (keys %$attrs) {
          $attrs->{$key} = $attrs->{$key}->($item, $index) if (ref($attrs->{$_})||'') eq 'CODE';
        }
        push @content, tag($tag, $attrs);
        $index++;
      }
    }
    return \@content, @_;
  }

  return (tag($tag, $attrs), @_);
}

foreach my $e (keys %HTML_CONTENT_ELEMENTS) {
  eval "sub $e { html_content_tag('$e', \@_) }";
}

foreach my $e (keys %HTML_VOID_ELEMENTS) {
  eval "sub $e { html_tag('$e', \@_) }";
  die $@ if $@; 
}

sub trow { html_content_tag('tr', @_) }

## Util tags

sub cond(&;@) {
  my $check = shift;
  my $block = shift;
  my $otherwise = ( blessed($_[0]) && $_[0]->isa('Valiant::HTML::TagBuilder::otherwise') ) ? shift(@_) : undef;
  my $result = $check->();

  if($result) {
    my @block = (ref($block)||'') eq 'CODE' ? ($block->($result)) : ($block);
    return (@block, @_);
  } else {
    if($otherwise) {
      return ($otherwise->($result), @_);
    } else {
      return @_;
    }
  }
}

sub otherwise {
  my $result = shift;
  my $code = (ref($result)||'') eq 'CODE' ? $result : sub { $result };
  return (bless($code, 'Valiant::HTML::TagBuilder::otherwise'), @_);
}

sub over {
  my $item_proto = shift;
  my $function = shift;

  my @items = ();
  my $i = 0;
  if(blessed($item_proto) && $item_proto->can('next')) {
    while (my $next = $item_proto->next) {
      push @items, $function->($next, $i);
      $i++;
    }
  } elsif( (ref($item_proto)||'') eq 'ARRAY' ) {
    foreach my $next( @$item_proto ) {
      push @items, $function->($next, $i);
      $i++;
    }
  } else {
    die "Not sure how to loop over $item_proto";
  }

  return (concat(@items), @_);
}  

sub loop(&;@) {
  my $function = shift;
  my $item_proto = shift;
  
  my @items = ();
  my $i = 0;
  if(blessed($item_proto) && $item_proto->can('next')) {
    while (my $next = $item_proto->next) {
      push @items, $function->($next, $i);
      $i++;
    }
  } elsif( (ref($item_proto)||'') eq 'ARRAY' ) {
    foreach my $next( @$item_proto ) {
      push @items, $function->($next, $i);
      $i++;
    }
  } else {
    die "Not sure how to loop over $item_proto";
  }

  return (concat(@items), @_);
}


sub css { }
sub js { }

# a, img select ul ol ?? dl???
#       ul \%attrs, \@items, sub {
#         li "item# $_[0]";
#       },

1;

=head1 NAME

Valiant::HTML::TagBuilder - Safely build HTML tags

=head1 SYNOPSIS

  use Valiant::HTML::TagBuilder ':all';

=head1 DESCRIPTION

Protecting your templates from the various types of character injection attacks is
a prime concern for anyone working with the HTML user interface.  This class provides
some methods and exports to make this job easier.

=head1 EXPORTABLE FUNCTIONS

The following functions can be exported by this library:

=head2 tag

  tag $name;
  tag $name, \%attrs;

Returns an instance of L<Valiant::HTML::SafeString> which is representing an html tag. Example:

  tag 'hr';                               # <hr/>
  tag img => +{src=>'/images/photo.jpg'}; # <img src='/images/photo.jpg' />

Generally C<\%attrs> should be a list of key / values where a value is a plain scalar; However
C<data-*> and C<aria-*> attributes can be set with a single data or aria key pointing to a hash of
sub-attributes.  Example:

  tag article => { id=>'main', data=>+{ user_id=>100 } };

Renders as:

  <article id='main', data-user-id='100' />

Note that underscores in the C<data-*> or C<aria-*> sub hashref keys are converted to '-' for
rendering.

=head2 content_tag

  content_tag $name, \%attrs, \&block;
  content_tag $name, \&block;
  content_tag $name, $content, \%attrs;
  content_tag $name, $content;

Returns an instance of L<Valiant::HTML::SafeString> which is representing an html tag with content.
Content will be escaped via L<Valiant::HTML::SafeString>'s C<safe> function (unless already marked
safe by the user.  Example:

  content_tag 'a', 'the link', +{href=>'a.html'}; # <a href="a.html">the link</a>;
  content_tag div => sub { 'The Lurker Above' };  # <div>The Lurker Above</div>

For the block version of thie function, the coderef is permitted to return an array of strings
all of which we processed for safeness and finally everything will be concatenated into a single
string encapulated by L<Valiant::HTML::SafeString>.

=head2 capture

  capture \&block;
  capture \&block, @args;

Returns a L<Valiant::HTML::SafeString> encapsulated string which is the return value (or array of
values) returned by C<block>. Any additional arguments passed to the function will be passed to the 
coderef at execution time.  Useful when you need to have some custom logic in your tag building
code.  Example:

    capture sub {
      if(shift) {
        return content_tag 'a', +{ href=>'profile.html' };
      } else {
        return content_tag 'a', +{ href=>'login.html' };
      }
    }, 1;

Would return:

    <a href="profile.html">Profile</a>

=head1 SEE ALSO
 
L<Valiant>, L<Valiant::HTML::FormBuilder>

=head1 AUTHOR
 
See L<Valiant>

=head1 COPYRIGHT & LICENSE
 
See L<Valiant>

=cut
