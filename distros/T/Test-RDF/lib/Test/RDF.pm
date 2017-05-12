package Test::RDF;

use warnings;
use strict;

use Carp qw(confess);
use RDF::Trine;
use RDF::Trine::Parser;
use RDF::Trine::Model;
use RDF::Trine::Graph;
use Scalar::Util qw/blessed/;

use base 'Test::Builder::Module';
our @EXPORT = qw/are_subgraphs is_rdf is_valid_rdf isomorph_graphs has_subject has_predicate has_object_uri has_uri hasnt_uri has_literal hasnt_literal pattern_target pattern_ok pattern_fail/;


=head1 NAME

Test::RDF - Test RDF data for content, validity and equality, etc.

=head1 VERSION

Version 1.20

=cut

our $VERSION = '1.20';


=head1 SYNOPSIS

 use Test::RDF;

 is_valid_rdf($rdf_string, $syntax,  'RDF string is valid according to selected syntax');
 is_rdf($rdf_string, $syntax1, $expected_rdf_string, $syntax2, 'The two strings have the same triples');
 isomorph_graphs($model, $expected_model, 'The two models have the same triples');
 are_subgraphs($model1, $model2, 'Model 1 is a subgraph of model 2' );
 has_uri($uri_string, $model, 'Has correct URI');
 hasnt_uri($uri_string, $model, "Hasn't correct URI");
 has_subject($uri_string, $model, 'Subject URI is found');
 has_predicate($uri_string, $model, 'Predicate URI is found');
 has_object_uri($uri_string, $model, 'Object URI is found');
 has_literal($string, $language, $datatype, $model, 'Literal is found');
 hasnt_literal($string, $language, $datatype, $model, 'Literal is not found');
 pattern_target($model);
 pattern_ok($pattern, '$pattern found in $model');
 pattern_fail($pattern, '$pattern not found in $model');

=head1 DESCRIPTION

This Perl module, Test::RDF, provides tools for testing code which
deals with RDF. It can test RDF for validity, check if two RDF graphs
are the same, or subgraphs of each other, if a URI is or is not in a
dataset, if it has certain subjects, predicates, objects or
literals. It can also test to see if a full pattern is present or
absent.


=head1 EXPORT

=head2 is_valid_rdf

Use to check if the input RDF string is valid in the chosen syntax

=cut

sub is_valid_rdf {
  my ($rdf, $syntax, $name) = @_;
  my $test = __PACKAGE__->builder;
  unless ($rdf) {
    $test->ok( 0, $name );
    $test->diag("No input was given.");
    return;
  }
  my $parser = RDF::Trine::Parser->new($syntax);
  eval {
    $parser->parse('http://example.org/', $rdf, sub {});
  };
  if ( my $error = $@ ) {
    $test->ok( 0, $name );
    $test->diag("Input was not valid RDF:\n\n\t$error");
    return;
  }
  else {
    $test->ok( 1, $name );
    return 1;
  }
}


=head2 is_rdf

Use to check if the input RDF strings are isomorphic (i.e. the same).

=cut


sub is_rdf {
  my ($rdf1, $syntax1, $rdf2, $syntax2, $name) = @_;
  my $test = __PACKAGE__->builder;
  unless ($rdf1) {
    $test->ok( 0, $name );
    $test->diag("No input was given.");
    return;
  }
  my $parser1 = RDF::Trine::Parser->new($syntax1);
  local $Test::Builder::Level = $Test::Builder::Level + 1;

  # First, test if the input RDF is OK
  my $model1 = RDF::Trine::Model->temporary_model;
  eval {
    $parser1->parse_into_model('http://example.org/', $rdf1, $model1);
  };
  if ( my $error = $@ ) {
    $test->ok( 0, $name );
    $test->diag("Input was not valid RDF:\n\n\t$error");
    return;
  }

  # If the expected RDF is non-valid, don't catch the exception
  my $parser2 = RDF::Trine::Parser->new($syntax2);
  my $model2 = RDF::Trine::Model->temporary_model;
  $parser2->parse_into_model('http://example.org/', $rdf2, $model2);
  return isomorph_graphs($model1, $model2, $name);
}


=head2 isomorph_graphs

Use to check if the input RDF::Trine::Models have isomorphic graphs.

=cut


sub isomorph_graphs {
  my ($model1, $model2, $name) = @_;
  confess 'No valid models given in test' unless ((blessed($model1) && $model1->isa('RDF::Trine::Model'))
																	&& (blessed($model2) && $model2->isa('RDF::Trine::Model')));
  my $g1 = RDF::Trine::Graph->new( $model1 );
  my $g2 = RDF::Trine::Graph->new( $model2 );
  my $test = __PACKAGE__->builder;

  if ($g1->equals($g2)) {
    $test->ok( 1, $name );
    return 1;
  } else {
    $test->ok( 0, $name );
    $test->diag('Graphs differ:');
    $test->diag($g1->error);
    return;
  }
}

=head2 are_subgraphs

Use to check if the first RDF::Trine::Models is a subgraph of the second.

=cut

sub are_subgraphs {
  my ($model1, $model2, $name) = @_;
  confess 'No valid models given in test' unless ((blessed($model1) && $model1->isa('RDF::Trine::Model'))
																	&& (blessed($model2) && $model2->isa('RDF::Trine::Model')));
  my $g1 = RDF::Trine::Graph->new( $model1 );
  my $g2 = RDF::Trine::Graph->new( $model2 );
  my $test = __PACKAGE__->builder;

  if ($g1->is_subgraph_of($g2)) {
    $test->ok( 1, $name );
    return 1;
  } else {
    $test->ok( 0, $name );
    $test->diag('Graph not subgraph: ' . $g1->error) if defined($g1->error);
    $test->diag('Hint: There are ' . $model1->size . ' statement(s) in model1 and ' . $model2->size . ' statement(s) in model2');
    return;
  }
}

=head2 has_subject

Check if the string URI passed as first argument is a subject in any
of the statements given in the model given as second argument.

=cut

sub has_subject {
  my ($uri, $model, $name) = @_;
  confess 'No valid model given in test' unless (blessed($model) && $model->isa('RDF::Trine::Model'));
  my $resource = _resource_uri_checked($uri, $name);
  return $resource unless ($resource);
  my $count = $model->count_statements($resource, undef, undef);
  return _single_uri_tests($count, $name);
}


=head2 has_predicate

Check if the string URI passed as first argument is a predicate in any
of the statements given in the model given as second argument.

=cut

sub has_predicate {
  my ($uri, $model, $name) = @_;
  confess 'No valid model given in test' unless (blessed($model) && $model->isa('RDF::Trine::Model'));
  my $resource = _resource_uri_checked($uri, $name);
  return $resource unless ($resource);
  my $count = $model->count_statements(undef, $resource, undef);
  return _single_uri_tests($count, $name);
}

=head2 has_object_uri

Check if the string URI passed as first argument is a object in any
of the statements given in the model given as second argument.

=cut

sub has_object_uri {
  my ($uri, $model, $name) = @_;
  confess 'No valid model given in test' unless (blessed($model) && $model->isa('RDF::Trine::Model'));
  my $resource = _resource_uri_checked($uri, $name);
  return $resource unless ($resource);
  my $count = $model->count_statements(undef, undef, $resource);
  return _single_uri_tests($count, $name);
}

=head2 has_literal

Check if the string passed as first argument, with corresponding
optional language and datatype as second and third respectively, is a
literal in any of the statements given in the model given as fourth
argument.

language and datatype may not occur in the same statement, so the test
fails if they are both set. If none are used, use C<undef>, like e.g.

 has_literal('A test', undef, undef, $model, 'Simple literal');

A test for a typed literal may be done like

 has_literal('42', undef, 'http://www.w3.org/2001/XMLSchema#integer', $model, 'Just an integer');

and a language literal like

 has_literal('This is a Another test', 'en', undef, $model, 'Language literal');


=cut

sub has_literal {
  my ($string, $lang, $datatype, $model, $name) = @_;
  confess 'No valid model given in test' unless (blessed($model) && $model->isa('RDF::Trine::Model'));
  my $literal;
  my $test = __PACKAGE__->builder;
  eval {
    $literal = RDF::Trine::Node::Literal->new($string, $lang, $datatype);
  };
  if ( my $error = $@ ) {
    $test->ok( 0, $name );
    $test->diag("Invalid literal:\n\n\t$error");
    return;
  }

  if ($model->count_statements(undef, undef, $literal) > 0) {
    $test->ok( 1, $name );
    return 1;
  } else {
    $test->ok( 0, $name );
    $test->diag('No matching literals found in model');
    return 0;
  }
}


=head2 hasnt_literal

This is like the above, only the opposite: It checks if a literal
doesn't exist. Like the above, the test will fail if the literal is
invalid, however.

=cut

sub hasnt_literal {
  my ($string, $lang, $datatype, $model, $name) = @_;
  confess 'No valid model given in test' unless (blessed($model) && $model->isa('RDF::Trine::Model'));
  my $literal;
  my $test = __PACKAGE__->builder;
  eval {
    $literal = RDF::Trine::Node::Literal->new($string, $lang, $datatype);
  };

  if ( my $error = $@ ) {
    $test->ok( 0, $name );
    $test->diag("Invalid literal:\n\n\t$error");
    return;
  }

  if ($model->count_statements(undef, undef, $literal) > 0) {
    $test->ok( 0, $name );
    $test->diag('Matching literals found in model');
    return 0;
  } else {
    $test->ok( 1, $name );
    return 1;
  }
}



=head2 has_uri

Check if the string URI passed as first argument is present in any of
the statements given in the model given as second argument.

=cut

sub has_uri {
  my ($uri, $model, $name) = @_;
  confess 'No valid model given in test' unless (blessed($model) && $model->isa('RDF::Trine::Model'));
  my $test = __PACKAGE__->builder;
  my $resource = _resource_uri_checked($uri, $name);
  return $resource unless ($resource);
  if ($model->count_statements(undef, undef, $resource) > 0
      || $model->count_statements(undef, $resource, undef) > 0
      || $model->count_statements($resource, undef, undef) > 0) {
    $test->ok( 1, $name );
    return 1;
  } else {
    $test->ok( 0, $name );
    $test->diag('No matching URIs found in model');
    return 0;
  }
}


=head2 hasnt_uri

Check if the string URI passed as first argument is not present in any
of the statements given in the model given as second argument.

=cut

sub hasnt_uri {
  my ($uri, $model, $name) = @_;
  confess 'No valid model given in test' unless (blessed($model) && $model->isa('RDF::Trine::Model'));
  my $test = __PACKAGE__->builder;
  my $resource;
  eval {
	  $resource = RDF::Trine::Node::Resource->new($uri);
  };
  if (($resource) && ($model->count_statements(undef, undef, $resource) > 0
      || $model->count_statements(undef, $resource, undef) > 0
      || $model->count_statements($resource, undef, undef)) > 0) {
    $test->ok( 0, $name );
    $test->diag('Matching URIs found in model');
    return 0;
  } else {
    $test->ok( 1, $name );
    return 1;
  }
}


sub _single_uri_tests {
  my ($count, $name) = @_;
  my $test = __PACKAGE__->builder;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  if ($count > 0) {
    $test->ok( 1, $name );
    return 1;
  } else {
    $test->ok( 0, $name );
    $test->diag('No matching URIs found in model');
    return 0;
  }
}

sub _resource_uri_checked {
	my ($uri, $name) = @_;
	my $resource;
	eval {
		$resource = RDF::Trine::Node::Resource->new($uri);
	};
	if ( my $error = $@ ) {
		my $test = __PACKAGE__->builder;
		local $Test::Builder::Level = $Test::Builder::Level + 1;
		$test->ok( 0, $name );
		$test->diag("No matching URIs found in model");
		return 0;
	}
	return $resource;
}

		



=head2 pattern_target

Tests that the object passed as its parameter is an RDF::Trine::Model or
RDF::Trine::Store. That is, tests that it is a valid thing to match basic
graph patterns against.

Additionally, this test establishes the target for future C<pattern_ok> tests.

=head2 pattern_ok

Tests that the pattern passed matches against the target established by
C<pattern_target>. The pattern may be passed as an RDF::Trine::Pattern, or
a list of RDF::Trine::Statement objects.

 use Test::RDF;
 use RDF::Trine qw[iri literal blank variable statement];
 use My::Module;

 my $foaf = RDF::Trine::Namespace->new('http://xmlns.com/foaf/0.1/');
 pattern_target(My::Module->get_model); # check isa RDF::Trine::Model
 pattern_ok(
   statement(
     variable('who'),
     $foaf->name,
     literal('Kjetil Kjernsmo')
     ),
   statement(
     variable('who'),
     $foaf->page,
     iri('http://search.cpan.org/~kjetilk/')
     ),
   "Data contains Kjetil's details."
   );

B<Note:> C<pattern_target> must have been tested before any C<pattern_ok> tests.

=head2 pattern_fail

The same as above, but tests if the pattern returns no results instead.

=cut

{ # scope for $target
  my $target;
  sub pattern_target {
    my $t = shift;
    my $test = __PACKAGE__->builder;
    if (blessed($t) && $t->isa('RDF::Trine::Model')) {
      $target = $t;
      $test->ok(1, 'Data is an RDF::Trine::Model.');
      return 1;
    }
    elsif (blessed($t) && $t->isa('RDF::Trine::Store')) {
      $target = $t;
      $test->ok(1, 'Data is an RDF::Trine::Store.');
      return 1;
    }
    else {
      $test->ok(0, 'Data is not an RDF::Trine::Model or RDF::Trine::Store.');
      return 0;
    }
  }

  sub pattern_ok {
    my $message = undef;
    $message = pop @_ if !ref $_[-1];
    unless (defined $message and length $message) {
      $message = "Pattern match";
    }
    my $test = __PACKAGE__->builder;
    unless (blessed($target)) {
      $test->ok(0, $message);
      $test->diag("No target defined for pattern match. Call pattern_target test first.");
      return 0;
    }
    my $pattern = (blessed($_[0]) and $_[0]->isa('RDF::Trine::Pattern'))
                ? $_[0]
                : RDF::Trine::Pattern->new(@_);
	 my $s = RDF::Trine::Serializer::Turtle->new();

    my $iter    = $target->get_pattern($pattern);
    if ($iter->materialize->length > 0) {
      $test->ok(1, $message);
      return 1;
    }
	 # The test result is now known, return diagnostics
	 my $noreturns;
	 foreach my $triple ($pattern->triples) {
		 my @triple;
		 foreach my $node ($triple->nodes) {
			 if ($node->is_variable) {
				 push(@triple, undef);
			 } else {
				 push(@triple, $node);
			 }
		 }
		 next if ($target->count_statements(@triple));
		 $noreturns .= $triple->as_string . "\n";
	 }
    $test->ok(0, $message);
	 if ($noreturns) {
		 $test->diag("Triples that had no results:\n$noreturns");
	 } else {
		 $test->diag('Pattern as a whole did not match');
	 }
    return 0;
  }

  sub pattern_fail {
    my $message = undef;
    $message = pop @_ if !ref $_[-1];
    unless (defined $message and length $message) {
      $message = "Pattern doesn't match";
    }
    my $test = __PACKAGE__->builder;
    unless (blessed($target)) {
      $test->ok(0, $message);
      $test->diag("No target defined for pattern match. Call pattern_target test first.");
      return 0;
    }
    my $pattern = (blessed($_[0]) and $_[0]->isa('RDF::Trine::Pattern'))
                ? $_[0]
                : RDF::Trine::Pattern->new(@_);
    my $iter = $target->get_pattern($pattern)->materialize;

    if ($iter->length == 0) {
      $test->ok(1, $message);
      return 1;
    }
	 # The test result is now known, return diagnostics
    $test->ok(0, $message);
	 $test->diag("These triples had results:\n" . $iter->as_string);
    return 0;
  }
} # /scope for $target


=head1 NOTE

Graph isomorphism is a complex problem, so do not attempt to run the
isomorphism tests on large datasets. For more information see
L<http://en.wikipedia.org/wiki/Graph_isomorphism_problem>.


=head1 AUTHOR

Kjetil Kjernsmo, C<< <kjetilk at cpan.org> >>

=head1 BUGS

Please report any bugs using L<github|https://github.com/kjetilk/Test-RDF/issues>


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::RDF

You may find the Perl and RDF community L<website|http://www.perlrdf.org/> useful.

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-RDF>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-RDF>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-RDF/>

=item * MetaCPAN

L<https://metacpan.org/module/Test::RDF>

=back


=head1 ACKNOWLEDGEMENTS

Michael Hendricks wrote the first Test::RDF. The present module is a
complete rewrite from scratch using Gregory Todd William's
L<RDF::Trine::Graph> to do the heavy lifting.

Toby Inkster has submitted the pattern_* functions.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 ABC Startsiden AS.
Copyright 2010, 2011, 2012, 2013, 2014 Kjetil Kjernsmo.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Test::RDF
