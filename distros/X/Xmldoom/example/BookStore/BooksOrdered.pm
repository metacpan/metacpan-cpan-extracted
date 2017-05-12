
package example::BookStore::BooksOrdered;
use base qw(example::BookStore::Object);

use example::BookStore::Book;
use strict;

1;

__END__

=pod

=begin Xmldoom

<object name="BooksOrdered" table="books_ordered">
	<property name="book">
		<object name="Book"/>
	</property>
	<property name="quantity">
		<simple/>
	</property>
</object>

=end Xmldoom

=cut

