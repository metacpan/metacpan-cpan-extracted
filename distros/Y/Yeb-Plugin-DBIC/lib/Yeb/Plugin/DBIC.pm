package Yeb::Plugin::DBIC;
BEGIN {
  $Yeb::Plugin::DBIC::AUTHORITY = 'cpan:GETTY';
}
# ABSTRACT: Yeb Plugin for DBIx::Class
$Yeb::Plugin::DBIC::VERSION = '0.001';
use Moo;
use Carp;
use DBIx::Class;
use Safe::Isa;
use Module::Runtime qw( use_module );
 
has app => ( is => 'ro', required => 1 );
has class => ( is => 'ro', required => 1 );

has schema_from => ( is => 'ro', required => 1, init_arg => 'schema' );
has connect => ( is => 'lazy', builder => sub {[]} );

has schema => ( is => 'lazy', init_arg => undef );

sub _build_schema {
  my ( $self ) = @_;
  return $self->schema_from if $self->schema_from->$_isa('DBIx::Class::Schema');
  my @args = @{$self->connect};
  use_module($self->schema_from);
  return $self->schema_from->connect(@args);
}

sub BUILD {
  my ( $self ) = @_;
  $self->app->register_function('schema',sub { $self->schema });
  my $resultset_sub = sub { $self->schema->resultset(@_) };
  $self->app->register_function('resultset',$resultset_sub);
  $self->app->register_function('rs',$resultset_sub);
  for my $schema_function (qw(
    source
    sources
    storage
    schema_version
  )) {
    $self->app->register_function($schema_function,sub {
      $self->schema->$schema_function(@_);
    });
  }
  for my $storage_function (qw(
    txn_do
    txn_scope_guard
    txn_begin
    txn_commit
    txn_rollback
  )) {
    $self->app->register_function($storage_function,sub {
      $self->schema->storage->$storage_function(@_);
    });
  }
}

1;

__END__

=pod

=head1 NAME

Yeb::Plugin::DBIC - Yeb Plugin for DBIx::Class

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  package MyYeb;

  use Yeb;

  BEGIN {
    plugin DBIC => (
      schema => 'MyApp::DB',
      connect => [
        'dbi:Pg:'.$ENV{MYAPP_DB_DSN},
        $ENV{MYAPP_DB_USERNAME},
        $ENV{MYAPP_DB_PASSWORD},
        {
          quote_char => '"',
          name_sep => '.',
          cursor_class => 'DBIx::Class::Cursor::Cached',
          pg_enable_utf8 => 1,
        },
      ],
    );
  }

  r "/" => sub {
    text join("\n",resultset('Blog')->search({},{
      order_by => 'dated'
    })->get_column('title')->all);
  };

  1;

=encoding utf8

=head1 PLUGIN ATTRIBUTES

=head2 schema

Can take a schema class name, which gets loaded and used for generating the
connected L<DBIx::Class::Schema> object, or it can take an already connected
schema object.

=head1 FRAMEWORK FUNCTIONS

=head2 schema

Access to the connected L<DBIx::Class::Schema> object.

=head2 resultset / rs

L<DBIx::Class::Schema/resultset>

=head2 source

L<DBIx::Class::Schema/source>

=head2 sources

L<DBIx::Class::Schema/sources>

=head2 storage

L<DBIx::Class::Schema/storage>

=head2 schema_version

L<DBIx::Class::Schema/schema_version>

=head2 txn_do

L<DBIx::Class::Storage/txn_do>

=head2 txn_scope_guard

L<DBIx::Class::Storage/txn_scope_guard>

=head2 txn_begin

L<DBIx::Class::Storage/txn_begin>

=head2 txn_commit

L<DBIx::Class::Storage/txn_commit>

=head2 txn_rollback

L<DBIx::Class::Storage/txn_rollback>

=head1 SUPPORT

IRC

  Join #sycontent on irc.perl.org. Highlight Getty for fast reaction :).

Repository

  http://github.com/Getty/p5-yeb-plugin-dbic
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/Getty/p5-yeb-plugin-dbic/issues

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
