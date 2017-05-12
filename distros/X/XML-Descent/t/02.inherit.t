#!perl
# vim:ts=2:sw=2:et:ft=perl

use strict;
use warnings;

use XML::Descent;
use Data::Dumper;
use Test::More tests => 4;
use Test::Differences;

my $td = test_data(
  do { local $/; <DATA> }
);

# inherit
{
  ok my $p = XML::Descent->new( Input => \$td->{t1} );
  my @got = ();
  $p->on(
    link => sub {
      my ( $elem, $attr, $ctx ) = @_;
      push @got, [ $p->get_path, $attr ];
    },
    name => sub {
      my ( $elem, $attr, $ctx ) = @_;
      push @got, [ $p->get_path, $attr ];
    },
    nested => sub {
      my ( $elem, $attr, $ctx ) = @_;
      $p->on(
        '*' => sub {
          my ( $elem, $attr, $ctx ) = @_;
          push @got, [ '*', $p->get_path, $attr ];
        }
      )->inherit( 'name' )->walk;
    },
  )->walk;

  my @expect = (
    [ '/root/link', { 'href' => 'http://hexten.net/' } ],
    [ '/root/name', {} ],
    [ '*', '/root/nested/link', { 'href' => 'http://perl.org/' } ],
    [ '/root/nested/name', {} ],
    [ '*', '/root/nested/froob', { 'id' => '2' } ]
  );

  unless ( eq_or_diff \@got, \@expect, 'inherit' ) {
    diag Dumper( \@got );
  }
}

# before/after
{
  ok my $p = XML::Descent->new( Input => \$td->{t1} );
  my @got = ();
  $p->on(
    link => sub {
      my ( $elem, $attr, $ctx ) = @_;
      push @got, [ $p->get_path, $attr ];
    },
    name => sub {
      my ( $elem, $attr, $ctx ) = @_;
      push @got, [ $p->get_path, $attr ];
    },
    nested => sub {
      my ( $elem, $attr, $ctx ) = @_;
      $p->before( link => sub { push @got, 'before link' } );
      $p->after( name => sub { push @got, 'after name' } );
      $p->on(
        froob => sub {
          my ( $elem, $attr, $ctx ) = @_;
          push @got, [ $p->get_path, $attr ];
        }
      );
      $p->after( froob => sub { push @got, 'after froob' } );
      $p->before( froob => sub { push @got, 'before froob' } );
      push @got,
       {
        scope_handlers => [ $p->scope_handlers ],
        all_handlers   => [ $p->all_handlers ]
       };
      $p->walk;
    },
  )->walk;

  my @expect = (
    [ '/root/link', { 'href' => 'http://hexten.net/' } ],
    [ '/root/name', {} ],
    {
      'all_handlers'   => [ 'froob', 'link', 'name', 'nested' ],
      'scope_handlers' => [ 'froob', 'link', 'name' ]
    },
    'before link',
    [ '/root/nested/link', { 'href' => 'http://perl.org/' } ],
    [ '/root/nested/name', {} ],
    'after name',
    'before froob',
    [ '/root/nested/froob', { 'id' => '2' } ],
    'after froob'
  );

  unless ( eq_or_diff \@got, \@expect, 'before/after' ) {
    diag Dumper( \@got );
  }
}

sub test_data {
  my $xml = shift;
  my $td  = {};
  my $p   = XML::Descent->new( Input => \$xml );
  $p->on(
    test => sub {
      my ( $elem, $attr, $ctx ) = @_;
      $td->{ $attr->{id} } = $p->xml;
    }
  )->walk;
  return $td;
}

__DATA__
<tests>
  <test id="t1">
    <root>
      <link href="http://hexten.net/">Hexten</link>
      <name>Horse Fingers</name>
      <froob id="1" />
      <nested>
        <link href="http://perl.org/">Perl</link>
        <name>Providence</name>
        <froob id="2" />
      </nested>
    </root>
  </test>
  <test id="t2">
    <root>
    </root>
  </test>
</tests>
