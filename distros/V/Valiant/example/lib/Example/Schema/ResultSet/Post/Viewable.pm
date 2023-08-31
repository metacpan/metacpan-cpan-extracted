package Example::Schema::ResultSet::Post::Viewable;

use Example::Syntax;
use base 'Example::Schema::ResultSet';


sub find_with_author_and_comments($self, $id) {
  return $self->find($id => {prefetch=>['author', {comments=>'person'}]});
}

1;
