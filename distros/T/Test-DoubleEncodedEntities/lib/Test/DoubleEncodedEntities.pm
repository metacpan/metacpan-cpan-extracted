package Test::DoubleEncodedEntities;
use base qw(Exporter);

use 5.006;
use strict;
use warnings;

our @EXPORT;
our $VERSION = "2.00";

use HTML::TokeParser::Simple;
use Test::DoubleEncodedEntities::Entities;

use Carp qw(croak);

use Test::Builder;
my $tester = Test::Builder->new();

my $entities = join "|", @entities;

sub ok_dee {
  my $input = shift;
  my $name  = shift || "double encoded entity test";

  # parse the input
  my $p = HTML::TokeParser::Simple->new( \$input )
   or croak "Can't parse input";

  $p->unbroken_text(1);

  # search all text bits for problems
  my %oops;
  while ( my $token = $p->get_token ) {
    next unless $token->is_text;
    my $string = $token->as_is;

    # look for bad entities
    $oops{$_}++ foreach $string =~ m/(&(?:amp|\#0*38);(?:$entities|\#\d+);)/gox;
  }

  # did we get away okay?
  unless(%oops) {
    return $tester->ok(1,$name)
  }

  # report the problem
  $tester->ok(0, $name);
  foreach (sort { $a cmp $b } keys %oops) {
    $tester->diag(qq{Found $oops{$_} "$_"\n})
  }

  # return 0 as we got an error
  return 0;
}
push @EXPORT, "ok_dee";

=head1 NAME

Test::DoubleEncodedEntities - check for double encoded entities

=head1 SYNOPSIS

  use Test::More tests => 1;
  use Test::DoubleEncodedEntities;

  ok_dee('<html><body>&amp;eacute;</body></html>', "ent test");

=head1 DESCRIPTION

This testing module huristically checks for double
encoded HTML entities in your string.

=head2 Functions

This module automatically exports the following function:

=over

=item ok_dee($string)

=item ok_dee($string, $test_description)

This module knows about all the entities defined in the HTML5
working draft and numerical entities.

=back

=head1 BUGS

This module only checks the body text;  Entities in attributes
are ignored as often you may want to double encoded entities on
purpose in things like URLs.

Bugs (and requests for new features) can be reported though the CPAN
RT system:
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-DoubleEncodedEntities>

Alternatively, you can simply fork this project on github and
send me pull requests.  Please see L<http://github.com/2shortplanks/Test-DoubleEncodedEntities>

=head1 AUTHOR

Written by Mark Fowler B<mark@twoshortplanks.com>

Copyright Mark Fowler 2004, 2011, 2012.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Test::DoubleEncodedEntities::Entities>

=cut

1;
