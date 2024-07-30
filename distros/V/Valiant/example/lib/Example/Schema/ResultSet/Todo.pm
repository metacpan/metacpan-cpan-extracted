package Example::Schema::ResultSet::Todo;

use Example::Syntax;
use base 'Example::Schema::ResultSet';

sub status($self, $status = undef) {
  $self->{attrs}{status} = $status if defined $status;
  return $self->{attrs}{status};
}

sub available($self) {
  return $self->search_rs({status=>{'!='=>'archived'}});
}
sub newer_first($self) {
  return $self->search_rs({},{order_by=>{-desc=>'id'}});
}

sub filter_by_request($self, $request) {
  return $self->next::method($request)
    ->by_status($request->status);
}

sub by_status($self, $status = 'all') {
  $self->status($status);
  return $self if $status eq 'all';
  return $self->search_rs({status=>$status}); 
}

sub get_last_page($self) {
  return $self->page($self->pager->last_page);
}

sub new_todo($self) {
  return $self->new_result(+{status=>'active'});
}

1;
