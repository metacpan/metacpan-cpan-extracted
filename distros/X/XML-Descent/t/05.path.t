#!perl
# vim:ts=2:sw=2:et:ft=perl

use strict;
use warnings;

use lib qw( t/lib );

use My::Cases;
use Test::More;
use XML::Descent;

my $source = load_cases;
my @case   = (
  {
    name   => 'Simple, deep',
    xml    => 'abcde',
    paths  => ['a/b/c/d/e'],
    expect => ['Whoop!'],
  }
);

plan tests => @case * 1;

for my $case ( @case ) {
  my $name = $case->{name};
  my $xml  = $source->{ $case->{xml} };
  my $p    = XML::Descent->new( { Input => \$xml } );
  my @got  = ();

  for my $path ( @{ $case->{paths} } ) {
    $p->on(
      $path => sub {
        push @got, tidy( $p->text );
      }
    )->walk;
  }

  is_deeply [@got], $case->{expect}, 'parse';
}

sub tidy {
  my $src = shift;
  $src =~ s/^\s+//;
  $src =~ s/\s+$//;
  $src =~ s/\s+/ /g;
  return $src;
}

__DATA__
<cases>
  <case name="abcde">
    <a>
      <b>
        <c>
          <d>
            <e>
              Whoop!
            </e>
          </d>
        </c>
      </b>
    </a>
  </case>
</cases>
