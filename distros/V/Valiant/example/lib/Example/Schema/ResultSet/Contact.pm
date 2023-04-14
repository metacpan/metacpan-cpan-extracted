package Example::Schema::ResultSet::Contact;

use Example::Syntax;
use base 'Example::Schema::ResultSet';

sub new_contact($self) {
  my $contact =  $self->new_result(+{});
  return $contact;
}

sub filter_by_request($self, $request) {
  return $self->page_or_last($request->page);
}

1;
