package Test::XML::Simple;

use strict;
use warnings;

our $VERSION = '1.05';

use Test::Builder;
use Test::More;
use Test::LongString;
use XML::LibXML;

my $Test = Test::Builder->new();
my $Xml;

sub import {
   my $self = shift;
   my $caller = caller;
   no strict 'refs';
   *{$caller.'::xml_valid'}          = \&xml_valid;
   *{$caller.'::xml_node'}           = \&xml_node;
   *{$caller.'::xml_is'}             = \&xml_is;
   *{$caller.'::xml_is_long'}        = \&xml_is_long;
   *{$caller.'::xml_is_deeply'}      = \&xml_is_deeply;
   *{$caller.'::xml_is_deeply_long'} = \&xml_is_deeply_long;
   *{$caller.'::xml_like'}           = \&xml_like;
   *{$caller.'::xml_like_long'}      = \&xml_like_long;

   $Test->exported_to($caller);
   $Test->plan(@_);
}

sub xml_valid($;$) {
  my ($xml, $comment) = @_;
  my $parsed_xml = _valid_xml($xml);
  return 0 unless $parsed_xml;

  ok $parsed_xml, $comment;
}

sub _valid_xml {
  my $xml = shift;
 
  local $Test::Builder::Level = $Test::Builder::Level + 2; 
  return fail("XML is not defined") unless defined $xml;
  return fail("XML is missing")     unless $xml;
  if ( ref $xml ) {
      return fail("accept only 'XML::LibXML::Document' as object") unless ref $xml eq 'XML::LibXML::Document';
      $Xml = $xml;
  }
  else {
    return fail("string can't contain XML: no tags") 
      unless ($xml =~ /</ and $xml =~/>/);
    eval { $Xml = XML::LibXML->new->parse_string($xml); };
    do { chomp $@; return fail($@) } if $@;
  }
  return $Xml;
}

sub _find {
  my ($xml_xpath, $xpath) = @_;
  my @nodeset = $xml_xpath->findnodes($xpath);
  local $Test::Builder::Level = $Test::Builder::Level + 2; 
  return fail("Couldn't find $xpath") unless @nodeset;
  wantarray ? @nodeset : \@nodeset;
}
  

sub xml_node($$;$) {
  my ($xml, $xpath, $comment) = @_;

  my $parsed_xml = _valid_xml($xml);
  return 0 unless $parsed_xml;

  my $nodeset = _find($parsed_xml, $xpath);
  return 0 if !$nodeset;

  ok(scalar @$nodeset, $comment);
}


sub xml_is($$$;$) {
  return _xml_is( \&is_string, @_ );
}

sub xml_is_long($$$;$) {
  _xml_is(\&is, @_);
}

sub _xml_is {
  my ($comp_sub, $xml, $xpath, $value, $comment) = @_;

  local $Test::Builder::Level = $Test::Builder::Level + 2; 
  my $parsed_xml = _valid_xml($xml);
  return 0 unless $parsed_xml;

  my $nodeset = _find($parsed_xml, $xpath);
  return 0 if !$nodeset;

  my $ok = 1;
  foreach my $node (@$nodeset) {
    my @kids = $node->getChildNodes;
    my $node_ok;
    if (@kids) {
      $node_ok = $comp_sub->( $kids[0]->toString, $value, $comment );
    }
    else {
      my $got = $node->toString;
      $got =~ s/^.*="(.*)"/$1/;
      $node_ok = is $got, $value, $comment;
    }

    # returns NOT OK if even one of tests fails
    $ok = 0 unless $node_ok;
  }

  return $ok;
}

sub xml_is_deeply($$$;$) {
  _xml_is_deeply(\&is_string, @_);
}

sub xml_is_deeply_long($$$;$) {
  _xml_is_deeply(\&is, @_);
}

sub _xml_is_deeply {
  my ($is_sub, $xml, $xpath, $candidate, $comment) = @_;

  my $parsed_xml = _valid_xml($xml);
  return 0 unless $parsed_xml;

  my $candidate_xp;
  eval {$candidate_xp = XML::LibXML->new->parse_string($candidate) };
  return 0 unless $candidate_xp; 

  my $parsed_thing    = $parsed_xml->findnodes($xpath)->[0];
  my $candidate_thing = $candidate_xp->findnodes('/')->[0];

  $candidate_thing = $candidate_thing->documentElement
    if $parsed_thing->isa('XML::LibXML::Element');

  $is_sub->($parsed_thing->toString, 
            $candidate_thing->toString,
            $comment);
}

sub xml_like($$$;$) {
  _xml_like(\&like_string, @_);
}

sub xml_like_long($$$;$) {
  _xml_like(\&like, @_);
}

sub _xml_like {
  my ($like_sub, $xml, $xpath, $regex, $comment) = @_;

  my $parsed_xml = _valid_xml($xml);
  return 0 unless $parsed_xml;

  my $nodeset = _find($parsed_xml, $xpath);
  return 0 if !$nodeset;

  foreach my $node (@$nodeset) {
    my @kids = $node->getChildNodes;
    my $found;
    if (@kids) {
      foreach my $kid (@kids) {
        if ($kid->toString =~ /$regex/) {
          $found = 1;
          return $like_sub->($kid->toString, $regex, $comment);
        }
      }
      if (! $found) {
        $comment = "(no comment)" unless defined $comment;
	local $Test::Builder::Level = $Test::Builder::Level + 2;
        return ok(0, "$comment - no match in tag contents (including CDATA)");
      }
    }
    else {
      my $got =  $node->toString;
      $got =~ s/^.*="(.*)"/$1/;
      local $Test::Builder::Level = $Test::Builder::Level + 2;
      return $like_sub->( $got, $regex, $comment );
    }
  }
}

1;
__END__

=head1 NAME

Test::XML::Simple - easy testing for XML

=head1 SYNOPSIS

  use Test::XML::Simple tests => 8;

  # pass string with XML as argument
  xml_valid $xml, "Is valid XML";
  xml_node $xml, "/xpath/expression", "specified xpath node is present";
  xml_is, $xml, '/xpath/expr', "expected value", "specified text present";
  xml_like, $xml, '/xpath/expr', qr/expected/, "regex text present";
  xml_is_deeply, $xml, '/xpath/expr', $xml2, "structure and contents match";

  # XML::LibXML::Document can be passed as argument too
  #  that allow you to test a big documents with several tests
  my $xml_doc = XML::LibXML->createDocument( '1.0' );
  xml_valid $xml_doc, 'Is valid XML';
  xml_node $xml_doc, '/xpath/expression', 'specified xpath node is present';
  xml_like, $xml_doc, '/xpath/expression', qr/expected result/, 'regex present';

  # Not yet implemented:
  # xml_like_deeply would be nice too...

=head1 DESCRIPTION

C<Test::XML::Simple> is a very basic class for testing XML. It uses the XPath
syntax to locate nodes within the XML. You can also check all or part of the
structure vs. an XML fragment.
All routines accept as first argument string with XML or XML::LibXML::Document object.

=head1 TEST ROUTINES

=head2 xml_valid $xml, 'test description'

Pass an XML file or fragment to this test; it succeeds if the XML (fragment)
is valid.

=head2 xml_node $xml, $xpath, 'test description'

Checks the supplied XML to see if the node described by the supplied XPath
expression is present. Test fails if it is not present.

=head2 xml_is_long $xml, $xpath, $value, 'test description'

Finds the node corresponding to the supplied XPath expression and
compares it to the supplied value. Succeeds if the two values match.
Uses Test::More's C<is> function to do the comparison.

=head2 xml_is $xml, $xpath, $value, 'test description'

Finds the node corresponding to the supplied XPath expression and
compares it to the supplied value. Succeeds if the two values match.
Uses Test::LongString's C<is_string> function to do the test.

=head2 xml_like_long $xml, $xpath, $regex, 'test description'

Find the XML corresponding to the the XPath expression and check it
against the supplied regular expression. Succeeds if they match.
Uses Test::More's C<like> function to do the comparison.

=head2 xml_like $xml, $xpath, $regex, 'test description'

Find the XML corresponding to the the XPath expression and check it
against the supplied regular expression. Succeeds if they match.
Uses Test::LongString's C<like_string> function to do the test.

=head2 xml_is_deeply_long $xml, $xpath, $xml2, 'test description'

Find the piece of XML corresponding to the XPath expression,
and compare its structure and contents to the second XML
(fragment) supplied. Succeeds if they match in structure and
content. Uses Test::More's C<is> function to do the comparison.

=head2 xml_is_deeply $xml, $xpath, $xml2, 'test description'

Find the piece of XML corresponding to the XPath expression,
and compare its structure and contents to the second XML
(fragment) supplied. Succeeds if they match in structure and
content. Uses Test::LongString's C<is_string> function to do the test.

=head1 AUTHOR

Joe McMahon, E<lt>mcmahon@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2005-2013 by Yahoo! and Joe McMahon

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.6.1 or, at
your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

L<XML::LibXML>, L<Test::More>, L<Test::Builder>.

=cut
