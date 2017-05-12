package Test::HTML::Content;

require 5.005_62;
use strict;
use File::Spec;
use Carp qw(carp croak);

use HTML::TokeParser;

# we want to stay compatible to 5.5 and use warnings if
# we can
eval 'use warnings' if $] >= 5.006;
use Test::Builder;
require Exporter;

use vars qw/@ISA @EXPORT_OK @EXPORT $VERSION $can_xpath/;

@ISA = qw(Exporter);

use vars qw( $tidy );

# DONE:
# * use Test::Builder;
# * Add comment_ok() method
# * Allow RE instead of plain strings in the functions (for tag attributes and comments)
# * Create a function to check the DOCTYPE and other directives
# * Have a better way to diagnose ignored candidates in tag_ok(), tag_count
#   and no_tag() in case a test fails

@EXPORT = qw(
  link_ok no_link link_count
  tag_ok no_tag tag_count
  comment_ok no_comment comment_count
  has_declaration no_declaration
  text_ok no_text text_count
  title_ok no_title
  xpath_ok no_xpath xpath_count
  );

$VERSION = '0.09';

my $Test = Test::Builder->new;

use vars qw($HTML_PARSER_StripsTags $parsing_method);
$parsing_method = 'parse_html_string';

# Cribbed from the Test::Builder synopsis
sub import {
    my($self) = shift;
    my $pack = caller;
    $Test->exported_to($pack);
    $Test->plan(@_);
    $self->export_to_level(1, $self, @EXPORT);
}

sub __dwim_compare {
  # Do the Right Thing (Perl 6 style) with the RHS being a Regex or a string
  my ($target,$template) = @_;
  if (ref $template) { # supposedly a Regexp, but possibly blessed, so no eq comparision
    return ($target =~ $template )
  } else {
    return $target eq $template;
  };
};

sub __node_content {
  my $node = shift;
  if ($can_xpath eq 'XML::XPath') { return XML::XPath::XMLParser::as_string($node) };
  if ($can_xpath eq 'XML::LibXML') { return $node->toString };
};

sub __text_content {
  my $node = shift;
  if ($can_xpath eq 'XML::XPath') { return $node->string_value };
  if ($can_xpath eq 'XML::LibXML') { return $node->textContent };
}

sub __match_comment {
  my ($text,$template) = @_;
  $text =~ s/^<!--(.*?)-->$/$1/sm unless $HTML_PARSER_StripsTags;
  unless (ref $template eq "Regexp") {
    $text =~ s/^\s*(.*?)\s*$/$1/;
    $template =~ s/^\s*(.*?)\s*$/$1/;
  };
  return __dwim_compare($text, $template);
};

sub __count_comments {
  my ($HTML,$comment) = @_;
  my $tree;
  $tree = __get_node_tree($HTML,'//comment()');
  return (undef,undef) unless ($tree);

  my $result = 0;
  my @seen;

  foreach my $node ($tree->get_nodelist) {
    my $content = __node_content($node);
    $content =~ s/\A<!--(.*?)-->\Z/$1/gsm;
    push @seen, $content;
    $result++ if __match_comment($content,$comment);
  };

  $_ = "<!--$_-->" for @seen;
  return ($result, \@seen);
};

sub __output_diag {
  my ($cond,$match,$descr,$kind,$name,$seen) = @_;

  local $Test::Builder::Level = $Test::Builder::Level + 2;

  unless ($Test->ok($cond,$name)) {
    if (@$seen) {
      $Test->diag( "Saw '$_'" ) for @$seen;
    } else {
      $Test->diag( "No $kind found at all" );
    };
    $Test->diag( "Expected $descr like '$match'" );
  };
};

sub __invalid_html {
  my ($HTML,$name) = @_;
  carp "No test name given" unless $name;
  $Test->ok(0,$name);
  $Test->diag( "Invalid HTML:");
  $Test->diag($HTML);
};

sub __output_comment {
  my ($check,$expectation,$HTML,$comment,$name) = @_;
  my ($result,$seen) = __count_comments($HTML,$comment);

  if (defined $result) {
    $result = $check->($result);
    __output_diag($result,$comment,$expectation,"comment",$name,$seen);
  } else {
    local $Test::Builder::Level = $Test::Builder::Level +2;
    __invalid_html($HTML,$name);
  };

  $result;
};

sub comment_ok {
  my ($HTML,$comment,$name) = @_;
  __output_comment(sub{shift},"at least one comment",$HTML,$comment,$name);
};

sub no_comment {
  my ($HTML,$comment,$name) = @_;
  __output_comment(sub{shift == 0},"no comment",$HTML,$comment,$name);
};

sub comment_count {
  my ($HTML,$comment,$count,$name) = @_;
  __output_comment(sub{shift == $count},"exactly $count comments",$HTML,$comment,$name);
};

sub __match_text {
  my ($text,$template) = @_;
  unless (ref $template eq "Regexp") {
    $text =~ s/^\s*(.*?)\s*$/$1/;
    $template =~ s/^\s*(.*?)\s*$/$1/;
  };
  return __dwim_compare($text, $template);
};

sub __count_text {
  my ($HTML,$text) = @_;
  my $tree = __get_node_tree($HTML,'//text()');
  return (undef,undef) unless $tree;

  my $result = 0;
  my @seen;

  foreach my $node ($tree->get_nodelist) {
    my $content = __node_content($node);
    push @seen, $content
      unless $content =~ /\A\r?\n?\Z/sm;
    $result++ if __match_text($content,$text);
  };

  return ($result, \@seen);
};

sub __output_text {
  my ($check,$expectation,$HTML,$text,$name) = @_;
  my ($result,$seen) = __count_text($HTML,$text);

  if (defined $result) {
    local $Test::Builder::Level = $Test::Builder::Level;
    $result = $check->($result);
    __output_diag($result,$text,$expectation,"text",$name,$seen);
  } else {
    local $Test::Builder::Level = $Test::Builder::Level +2;
    __invalid_html($HTML,$name);
  };

  $result;
};

sub text_ok {
  my ($HTML,$text,$name) = @_;
  __output_text(sub{shift > 0}, "at least one text element",$HTML,$text,$name);
};

sub no_text {
  my ($HTML,$text,$name) = @_;
  __output_text(sub{shift == 0}, "no text elements",$HTML,$text,$name);
};

sub text_count {
  my ($HTML,$text,$count,$name) = @_;
  __output_text(sub{shift == $count}, "exactly $count elements",$HTML,$text,$name);
};

sub __match {
  my ($attrs,$currattr,$key) = @_;
  my $result = 1;

  if (exists $currattr->{$key}) {
    if (! defined $attrs->{$key}) {
      $result = 0; # We don't want to see this attribute here
    } else {
      $result = 0 unless __dwim_compare($currattr->{$key}, $attrs->{$key});
    };
  } else {
    if (! defined $attrs->{$key}) {
      $result = 0 if (exists $currattr->{$key});
    } else {
      $result = 0;
    };
  };
  return $result;
};

sub __get_node_tree {
  my ($HTML,$query) = @_;

  croak "No HTML given" unless defined $HTML;
  croak "No query given" unless defined $query;

  my ($tree,$find,$result);
  if ($HTML !~ m!\A\s*\Z!ms) {
    eval {
      require XML::LibXML; XML::LibXML->import;
      my $parser = XML::LibXML->new();
      $parser->recover(1);
      $tree = $parser->$parsing_method($HTML);
      $find = 'findnodes';
      $HTML_PARSER_StripsTags = 1;
    };
    unless ($tree) {
      eval {
        require XML::XPath; XML::XPath->import;
        require XML::Parser;

        my $p = XML::Parser->new( ErrorContext => 2, ParseParamEnt => 0, NoLWP => 1 );
        $tree = XML::XPath->new( parser => $p, xml => $HTML );
        $find = 'find';
      };
    };
    undef $tree if $@;

    if ($tree) {
      eval {
        $result = $tree->$find($query);
        unless ($result) {
          $result = {};
          bless $result, 'Test::HTML::Content::EmptyXPathResult';
        };
      };
      warn $@ if $@;
    };
  } else { };
  return $result;
};

sub __get_node_content {
  my ($node,$name) = @_;

  if ($name eq '_content') {
    return __text_content( $node )
#    return $node->textContent()
  } else {
    return $node->getAttribute($name)
  };
};

sub __build_xpath_query {
  my ($query,$attrref) = @_;
  my @postvalidation;
  if ($attrref) {
    my @query;
    for (sort keys %$attrref) {
      my $name = $_;
      my $value = $attrref->{$name};
      my $xpath_name = '@' . $name;
      if ($name eq '_content') { $xpath_name = "text()" };
      if (! defined $value) {
        push @query, "not($xpath_name)"
      } elsif ((ref $value) ne 'Regexp') {
        push @query, "$xpath_name = \"$value\"";
        push @postvalidation, sub {
          return __get_node_content( shift,$name ) eq $value
        };
      } else {
        push @query, "$xpath_name";
        push @postvalidation, sub {
          return __get_node_content( shift,$name ) =~ $value
        };
      };
    };
    $query .= "[" . join( " and ", map {"$_"} @query ) . "]"
      if @query;
  };
  my $postvalidation = sub {
    my $node = shift;
    my $test;
    for $test (@postvalidation) {
      return () unless $test->($node);
    };
    return 1;
  };
  ($query,$postvalidation);
};

sub __count_tags {
  my ($HTML,$tag,$attrref) = @_;
  $attrref = {} unless defined $attrref;

  my $fallback = lc "//$tag";
  my ($query,$valid) = __build_xpath_query( lc "//$tag", $attrref );
  my $tree = __get_node_tree($HTML,$query);
  return (undef,undef) unless $tree;

  my @found = grep { $valid->($_) } ($tree->get_nodelist);

  # Collect the nodes we did see for later reference :
  my @seen;
  foreach my $node (__get_node_tree($HTML,$fallback)->get_nodelist) {
    push @seen, __node_content($node);
  };
  return scalar(@found),\@seen;
};

sub __tag_diag {
  my ($tag,$num,$attrs,$found) = @_;
  my $phrase = "Expected to find $num <$tag> tag(s)";
  $phrase .= " matching" if (scalar keys %$attrs > 0);
  $Test->diag($phrase);
  $Test->diag("  $_ = " . (defined $attrs->{$_} ? $attrs->{$_} : '<not present>'))
    for sort keys %$attrs;
  if (@$found) {
    $Test->diag("Got");
    $Test->diag("  " . $_) for @$found;
  } else {
    $Test->diag("Got none");
  };
};

sub __output_tag {
  my ($check,$expectation,$HTML,$tag,$attrref,$name) = @_;
  ($attrref,$name) = ({},$attrref)
    unless defined $name;
  $attrref = {}
    unless defined $attrref;
  croak "$attrref dosen't look like a hash reference for the attributes"
    unless ref $attrref eq 'HASH';
  my ($currcount,$seen) = __count_tags($HTML,$tag,$attrref);
  my $result;
  if (defined $currcount) {
    if ($currcount eq 'skip') {
      $Test->skip($seen);
    } else {
      local $Test::Builder::Level = $Test::Builder::Level +1;
      $result = $check->($currcount);
      unless ($Test->ok($result, $name)) {
        __tag_diag($tag,$expectation,$attrref,$seen) ;
      };
    };
  } else {
    local $Test::Builder::Level = $Test::Builder::Level +2;
    __invalid_html($HTML,$name);
  };

  $result;
};

sub tag_count {
  my ($HTML,$tag,$attrref,$count,$name) = @_;
  __output_tag(sub { shift == $count }, "exactly $count",$HTML,$tag,$attrref,$name);
};

sub tag_ok {
  my ($HTML,$tag,$attrref,$name) = @_;
  __output_tag(sub { shift > 0 }, "at least one",$HTML,$tag,$attrref,$name);
};

sub no_tag {
  my ($HTML,$tag,$attrref,$name) = @_;
  __output_tag(sub { shift == 0 }, "no",$HTML,$tag,$attrref,$name);
};

sub link_count {
  my ($HTML,$link,$count,$name) = @_;
  local $Test::Builder::Level = 2;
  return tag_count($HTML,"a",{href => $link},$count,$name);
};

sub link_ok {
  my ($HTML,$link,$name) = (@_);
  local $Test::Builder::Level = 2;
  return tag_ok($HTML,'a',{ href => $link },$name);
};

sub no_link {
  my ($HTML,$link,$name) = (@_);
  local $Test::Builder::Level = 2;
  return no_tag($HTML,'a',{ href => $link },$name);
};

sub title_ok {
  my ($HTML,$title,$name) = @_;
  local $Test::Builder::Level = 2;
  return tag_ok($HTML,"title",{_content => $title},$name);
};

sub no_title {
  my ($HTML,$title,$name) = (@_);
  local $Test::Builder::Level = 2;
  return no_tag($HTML,'title',{ _content => $title },$name);
};

sub __match_declaration {
  my ($text,$template) = @_;
  $text =~ s/^<!(.*?)>$/$1/ unless $HTML_PARSER_StripsTags;
  unless (ref $template eq "Regexp") {
    $text =~ s/^\s*(.*?)\s*$/$1/;
    $template =~ s/^\s*(.*?)\s*$/$1/;
  };
  return __dwim_compare($text, $template);
};

sub __count_declarations {
  my ($HTML,$doctype) = @_;
  my $result = 0;
  my $seen = [];

  my $p = HTML::TokeParser->new(\$HTML);
  my $token;
  while ($token = $p->get_token) {
    my ($type,$text) = @$token;
    if ($type eq "D") {
      push @$seen, $text;
      $result++ if __match_declaration($text,$doctype);
    };
  };

  return $result, $seen;
};

sub has_declaration {
  my ($HTML,$declaration,$name) = @_;
  my ($result,$seen) = __count_declarations($HTML,$declaration);

  if (defined $result) {
    __output_diag($result == 1,$declaration,"exactly one declaration","declaration",$name,$seen);
  } else {
    local $Test::Builder::Level = $Test::Builder::Level +1;
    __invalid_html($HTML,$name);
  };

  $result;
};

sub no_declaration {
  my ($HTML,$declaration,$name) = @_;
  my ($result,$seen) = __count_declarations($HTML,$declaration);

  if (defined $result) {
    __output_diag($result == 0,$declaration,"no declaration","declaration",$name,$seen);
  } else {
    local $Test::Builder::Level = $Test::Builder::Level +1;
    __invalid_html($HTML,$name);
  };

  $result;
};

sub __count_xpath {
  my ($HTML,$query,$fallback) = @_;

  $fallback = $query unless defined $fallback;
  my $tree = __get_node_tree($HTML,$query);
  return (undef,undef) unless $tree;

  my @found = ($tree->get_nodelist);

  # Collect the nodes we did see for later reference :
  my @seen;
  foreach my $node (__get_node_tree($HTML,$fallback)->get_nodelist) {
    push @seen, __node_content($node);
  };
  return scalar(@found),\@seen;
};

sub __xpath_diag {
  my ($query,$num,$found) = @_;
  my $phrase = "Expected to find $num nodes matching on '$query'";
  if (@$found) {
    $Test->diag("Got");
    $Test->diag("  $_") for @$found;
  } else {
    $Test->diag("Got none");
  };
};

sub __output_xpath {
  my ($check,$expectation,$HTML,$query,$fallback,$name) = @_;
  ($fallback,$name) = ($query,$fallback) unless $name;
  my ($currcount,$seen) = __count_xpath($HTML,$query,$fallback);
  my $result;
  if (defined $currcount) {
    if ($currcount eq 'skip') {
      $Test->skip($seen);
    } else {
      local $Test::Builder::Level = $Test::Builder::Level +1;
      $result = $check->($currcount);
      unless ($Test->ok($result, $name)) {
        __xpath_diag($query,$expectation,$seen) ;
      };
    };
  } else {
    local $Test::Builder::Level = $Test::Builder::Level +1;
    __invalid_html($HTML,$name);
  };

  $result;
};

sub xpath_count {
  my ($HTML,$query,$count,$fallback,$name) = @_;
  __output_xpath( sub {shift == $count},"exactly $count",$HTML,$query,$fallback,$name);
};

sub xpath_ok {
  my ($HTML,$query,$fallback,$name) = @_;
  __output_xpath( sub{shift > 0},"at least one",$HTML,$query,$fallback,$name);
};

sub no_xpath {
  my ($HTML,$query,$fallback,$name) = @_;
  __output_xpath( sub{shift == 0},"no",$HTML,$query,$fallback,$name);
};

sub install_xpath {
  require XML::XPath;
  XML::XPath->import();
  die "Need XML::XPath 1.13 or higher"
    unless $XML::XPath::VERSION >= 1.13;
  $can_xpath = 'XML::XPath';
};

sub install_libxml {
  local $^W;
  require XML::LibXML;
  XML::LibXML->import();
  $can_xpath = 'XML::LibXML';
};

# And install our plain handlers if we have to :
sub install_pureperl {
  require Test::HTML::Content::NoXPath;
  Test::HTML::Content::NoXPath->import;
};

BEGIN {
  # Load the XML-variant if our prerequisites are there :
     eval { install_libxml }
  or eval { install_xpath }
  or install_pureperl;
};

{
  package Test::HTML::Content::EmptyXPathResult;
  sub size { 0 };
  sub get_nodelist { () };
};

1;

__END__

=head1 NAME

Test::HTML::Content - Perl extension for testing HTML output

=head1 SYNOPSIS

  use Test::HTML::Content( tests => 13 );

=for example begin

  $HTML = "<html><title>A test page</title><body><p>Home page</p>
           <img src='http://www.perl.com/camel.png' alt='camel'>
           <a href='http://www.perl.com'>Perl</a>
           <img src='http://www.perl.com/camel.png' alt='more camel'>
           <!--Hidden message--></body></html>";

  link_ok($HTML,"http://www.perl.com","We link to Perl");
  no_link($HTML,"http://www.pearl.com","We have no embarassing typos");
  link_ok($HTML,qr"http://[a-z]+\.perl.com","We have a link to perl.com");

  title_count($HTML,1,"We have one title tag");
  title_ok($HTML,qr/test/);

  tag_ok($HTML,"img", {src => "http://www.perl.com/camel.png"},
                        "We have an image of a camel on the page");
  tag_count($HTML,"img", {src => "http://www.perl.com/camel.png"}, 2,
                        "In fact, we have exactly two camel images on the page");
  no_tag($HTML,"blink",{}, "No annoying blink tags ..." );

  # We can check the textual contents
  text_ok($HTML,"Perl");

  # We can also check the contents of comments
  comment_ok($HTML,"Hidden message");

  # Advanced stuff

  # Using a regular expression to match against
  # tag attributes - here checking there are no ugly styles
  no_tag($HTML,"p",{ style => qr'ugly$' }, "No ugly styles" );

  # REs also can be used for substrings in comments
  comment_ok($HTML,qr"[hH]idden\s+mess");

  # and if you have XML::LibXML or XML::XPath, you can
  # even do XPath queries yourself:
  xpath_ok($HTML,'/html/body/p','HTML is somewhat wellformed');
  no_xpath($HTML,'/html/head/p','HTML is somewhat wellformed');

=for example end

=head1 DESCRIPTION

This is a module to test the HTML output of your programs in simple
test scripts. It can test a scalar (presumably containing HTML) for
the presence (or absence, or a specific number) of tags having (or
lacking) specific attributes. Unspecified attributes are ignored,
and the attribute values can be specified as either scalars (meaning
a match succeeds if the strings are identical) or regular expressions
(meaning that a match succeeds if the actual attribute value is matched
by the given RE) or undef (meaning that the attribute must not
be present).

If you want to specify or test the deeper structure
of the HTML (for example, META tags within the BODY) or the (textual)
content of tags, you will have to resort to C<xpath_ok>,C<xpath_count>
and C<no_xpath>, which take an XPath expression. If you find yourself crafting
very complex XPath expression to verify the structure of your output, it is
time to rethink your testing process and maybe use a template based solution
or simply compare against prefabricated files as a whole.

The used HTML parser is HTML::TokeParser, the used XPath module
is XML::XPath or XML::LibXML. XML::XPath needs valid xHTML, XML::LibXML
will try its best to force your code into xHTML, but it is best to
supply valid xHTML (snippets) to the test functions.

If no XPath parsers/interpreters are available, the tests will automatically
skip, so your users won't need to install XML::XPath or XML::LibXML. The module
then falls back onto a crude implementation of the core functions for tags,
links, comments and text, and the diagnostic output of the tests varies a bit.

The test functionality is derived from L<Test::Builder>, and the export
behaviour is the same. When you use Test::HTML::Content, a set of
HTML testing functions is exported into the namespace of the caller.

=head2 EXPORT

Exports the bunch of test functions :

  link_ok() no_link() link_count()
  tag_ok() no_tag() tag_count()
  text_ok no_text() text_count()
  comment_ok() no_comment() comment_count()
  xpath_ok() no_xpath() xpath_count()
  has_declaration() no_declaration()

=head2 CONSIDERATIONS

The module reparses the HTML string every time a test function is called.
This will make running many tests over the same, large HTML stream relatively
slow. A possible speedup could be simple minded caching mechanism that keeps the most
recent HTML stream in a cache.

=head2 CAVEATS

The test output differs between XPath and HTML parsing, because XML::XPath
delivers the complete node including the content, where my HTML parser only
delivers the start tag. So don't make your tests depend on the _exact_
output of my tests. It was a pain to do so in my test scripts for this module
and if you really want to, take a look at the included test scripts.

The title functions C<title_ok> and C<no_title> rely on the XPath functionality
and will thus skip if XPath functionality is unavailable.

=head2 BUGS

Currently, if there is text split up by comments, the text will be seen
as two separate entities, so the following dosen't work :

  is_text( "Hello<!-- brave new--> World", "Hello World" );

Whether this is a real bug or not, I don't know at the moment - most likely,
I'll modify text_ok() and siblings to ignore embedded comments.

=head2 TODO

My things on the todo list for this module. Patches are welcome !

=over 4

=item * Refactor the code to fold some of the internal routines

=item * Implement a cache for the last parsed tree / token sequence

=item * Possibly diag() the row/line number for failing tests

=item * Allow RE instead of plain strings in the functions (for tags themselves). This
one is most likely useless.

=back

=head1 LICENSE

This code may be distributed under the same terms as Perl itself.

=head1 AUTHOR

Max Maischein E<lt>corion@cpan.orgE<gt>

=head1 SEE ALSO

perl(1), L<Test::Builder>,L<Test::Simple>,L<Test::HTML::Lint>.

=cut
