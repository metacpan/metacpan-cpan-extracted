package Valiant::HTML::TagBuilder;

use warnings;
use strict;
use Exporter 'import';
use Valiant::HTML::SafeString ':all';

our @EXPORT_OK = qw(tag content_tag capture);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

our $ATTRIBUTE_SEPARATOR = ' ';
our %SUBHASH_ATTRIBUTES = map { $_ => 1} qw(data aria);
our %HTML_VOID_ELEMENTS = map { $_ => 1 } qw(area base br col circle embed hr img input keygen link meta param source track wbr);
our %BOOLEAN_ATTRIBUTES = map { $_ => 1 } qw(
  allowfullscreen allowpaymentrequest async autofocus autoplay checked compact controls declare default
  defaultchecked defaultmuted defaultselected defer disabled enabled formnovalidate hidden indeterminate
  inert ismap itemscope loop multiple muted nohref nomodule noresize noshade novalidate nowrap open
  pauseonexit playsinline readonly required reversed scoped seamless selected sortable truespeed
  typemustmatch visible);

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
  die "'$name' is not a valid VOID HTML element" unless $HTML_VOID_ELEMENTS{$name};
  return raw "<${name}@{[ _tag_options(%{$attrs}) ]}/>";
}

sub content_tag {
  my $name = shift;
  my $block = ref($_[-1]) eq 'CODE' ? pop(@_) : undef;
  my $attrs = ref($_[-1]) eq 'HASH' ? pop(@_) : +{};
  my $content = flattened_safe($block ? $block->() : (shift || ''));
  return raw "<${name}@{[ _tag_options(%{$attrs}) ]}>$content</${name}>";
}

sub capture {
  my $block = shift;
  return flattened_safe $block->(@_);
}


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
