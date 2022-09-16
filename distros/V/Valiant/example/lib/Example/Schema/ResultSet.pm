package Example::Schema::ResultSet;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';
use Example::Syntax;

__PACKAGE__->load_components(qw/
  Valiant::ResultSet
  Helper::ResultSet::Shortcut
  Helper::ResultSet::Me
  Helper::ResultSet::SetOperations
  Helper::ResultSet::IgnoreWantarray
  ResultSet::SetControl
/);

sub to_array($self) {
  return $self->search(
    {},
    {result_class => 'DBIx::Class::ResultClass::HashRefInflator'}
  )->all;
}

sub debug($self) {
  $self->result_source->schema->debug;
  return $self;
}

sub page_or_last($self, $page) {
  my $paged_resultset = $self->page($page);
  my $last_page = $paged_resultset->pager->last_page;

  $paged_resultset = $paged_resultset->page($last_page)
    if $page > $last_page;

  return $paged_resultset;
}

1;
