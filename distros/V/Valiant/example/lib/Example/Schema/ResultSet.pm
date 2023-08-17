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

sub page_or_last($self, $page = $self->pager->current_page // 1) {
  my $paged_resultset = $self->page($page);
  my $last_page = $paged_resultset->pager->last_page;
  $paged_resultset = $paged_resultset->page($last_page)
    if $page > $last_page;

  return $paged_resultset;
}

sub filter_by_request($self, $request) {
  my $filtered_resultset = $self;
  if($request->can('page')) {
    $filtered_resultset = $filtered_resultset->page($request->page);
  } else {
    $filtered_resultset = $filtered_resultset->page(1);
  }
  return $filtered_resultset;
}

sub build($self, $attrs={}) {
  my $new = $self->new_result($attrs);
  return $new;
} 

sub new_from_request($self, $request) {
  my $new = $self->create($request->nested_params);
  return $new;
}

1;
