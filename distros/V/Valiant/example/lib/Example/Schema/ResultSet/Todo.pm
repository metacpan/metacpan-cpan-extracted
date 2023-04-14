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
  my $todos = $request->status_all ?
    $self : $self->search_rs({status=>$request->status});
  $todos = $todos->page_or_last($request->page); 
  $todos->status($request->status);
  return $todos;
}

sub new_todo($self) {
  return $self->new_result(+{status=>'active'});
}

1;
