
package example::BookStore::Order;
use base qw(example::BookStore::Object);

use example::BookStore::BooksOrdered;
use strict;

1;

__END__

=pod

=begin Xmldoom

<object name="Order" table="orders">
	<property name="date_opened">
		<simple/>
	</property>
	<property name="date_shipped">
		<simple/>
	</property>
	<property name="books_ordered"
		get_name="get_books_ordered"
		set_name="add_book_ordered">
			<object name="BooksOrdered"/>
	</property>
	<property name="book">
		<object name="Book" inter_table="books_ordered"/>
	</property>
</object>

=end Xmldoom

=cut

