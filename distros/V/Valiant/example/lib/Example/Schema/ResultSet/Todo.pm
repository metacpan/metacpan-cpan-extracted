package Example::Schema::ResultSet::Todo;

use Example::Syntax;
use base 'Example::Schema::ResultSet';

__PACKAGE__->mk_group_accessors('simple' => qw/status/);

sub available($self) {
  return $self->search_rs({status=>{'!='=>'archived'}});
}
sub newer_first($self) {
  return $self->search_rs({},{order_by=>{-desc=>'id'}});
}

sub filter_by_request($self, $request) {
  my $filtered_resultset = $self->next::method($request);
  $filtered_resultset = $filtered_resultset->search({status=>$request->status}) unless $request->status_all;
  $filtered_resultset->status($request->status);
  return $filtered_resultset; 
}

sub get_last_page($self) {
  my $new_resultset = $self->page($self->pager->last_page);
  $new_resultset->status($self->status);
  return $new_resultset; 
}

sub new_todo($self) {
  return $self->new_result(+{status=>'active'});
}

1;
