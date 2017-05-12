package Test::HTML::Content::NoXPath;

require 5.005_62;
use strict;
use File::Spec;
use HTML::TokeParser;

# we want to stay compatible to 5.5 and use warnings if
# we can
eval 'use warnings;' if ($] >= 5.006);
use vars qw( $HTML_PARSER_StripsTags $VERSION @exports );

$VERSION = '0.09';

BEGIN {
  # Check whether HTML::Parser is v3 and delivers the comments starting
  # with the <!--, even though that's implied :
  my $HTML = "<!--Comment-->";
  my $p = HTML::TokeParser->new(\$HTML);
  my ($type,$text) = @{$p->get_token()};
  if ($text eq "<!--Comment-->") {
    $HTML_PARSER_StripsTags = 0
  } else {
    $HTML_PARSER_StripsTags = 1
  };
};

# import what we need
{ no strict 'refs';
  *{$_} = *{"Test::HTML::Content::$_"}
    for qw( __dwim_compare __output_diag __invalid_html );
};

@exports = qw( __match_comment __count_comments __match_text __count_text
               __match __count_tags __match_declaration __count_declarations );

sub __match_comment {
  my ($text,$template) = @_;
  $text =~ s/^<!--(.*?)-->$/$1/ unless $HTML_PARSER_StripsTags;
  unless (ref $template eq "Regexp") {
    $text =~ s/^\s*(.*?)\s*$/$1/;
    $template =~ s/^\s*(.*?)\s*$/$1/;
  };
  return __dwim_compare($text, $template);
};

sub __count_comments {
  my ($HTML,$comment) = @_;
  my $result = 0;
  my $seen = [];

  my $p = HTML::TokeParser->new(\$HTML);
  my $token;
  while ($token = $p->get_token) {
    my ($type,$text) = @$token;
    if ($type eq "C") {
      push @$seen, $token->[1];
      $result++ if __match_comment($text,$comment);
    };
  };

  return ($result, $seen);
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
  my $result = 0;
  my $seen = [];

  my $p = HTML::TokeParser->new(\$HTML);
  $p->unbroken_text(1);

  my $token;
  while ($token = $p->get_token) {
    my ($type,$foundtext) = @$token;
    if ($type eq "T") {
      push @$seen, $token->[1];
      $result++ if __match_text($foundtext,$text);
    };
  };

  return $result,$seen;
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

sub __count_tags {
  my ($HTML,$tag,$attrref) = @_;
  $attrref = {} unless defined $attrref;
  return ('skip','XML::LibXML or XML::XPath not loaded')
    if exists $attrref->{_content};

  my $result = 0;
  $tag = lc $tag;

  my $p = HTML::TokeParser->new(\$HTML);
  my $token;
  my @seen;
  while ($token = $p->get_token) {
    my ($type,$currtag,$currattr,$attrseq,$origtext) = @$token;
    if ($type eq "S" && $tag eq $currtag) {
      my (@keys) = keys %$attrref;
      my $key;
      my $complete = 1;
      foreach $key (@keys) {
        $complete = __match($attrref,$currattr,$key) if $complete;
      };
      $result += $complete;
      # Now munge the thing to resemble what the XPath variant returns :
      push @seen, $token->[4];
    };
  };

  return $result,\@seen;
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

sub import {
  goto &install;
};

sub install {
  for (@exports) {
    no strict 'refs';
    *{"Test::HTML::Content::$_"} = *{"Test::HTML::Content::NoXPath::$_"};
  };
  $Test::HTML::Content::can_xpath = 0;
};

1;

__END__

=head1 NAME

Test::HTML::Content::NoXPath - HTML::TokeParser fallback for Test::HTML::Content

=head1 SYNOPSIS

=for example begin

  # This module is implicitly loaded by Test::HTML::Content
  # if XML::XPath or HTML::Tidy::Simple are unavailable.

=for example end

=head1 DESCRIPTION

This is the module that gets loaded when Test::HTML::Content
can't find its prerequisites :

    XML::XPath
    HTML::Tidy

=head2 EXPORT

Nothing. It stomps over the Test::HTML::Content namespace.

=head1 LICENSE

This code may be distributed under the same terms as Perl itself.

=head1 AUTHOR

Max Maischein, corion@cpan.org

=head1 SEE ALSO

L<Test::Builder>,L<Test::Simple>,L<HTML::TokeParser>,L<Test::HTML::Lint>,L<XML::XPath>

=cut
