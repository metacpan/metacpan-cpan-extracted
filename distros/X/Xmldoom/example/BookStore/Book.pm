
package example::BookStore::Book;
use base qw(example::BookStore::Object);

use example::BookStore::BookAgeProperty;
use strict;

1;

__END__

=pod

=begin Xmldoom

<object name="Book" table="book">
	<property name="book_id">
		<simple/>
	</property>
	<property name="title">
		<simple/>
	</property>
	<property name="isbn">
		<simple/>
	</property>
	<property name="publisher">
		<object name="Publisher">
			<options
				inclusive="true"
				property="name"/>
		</object>
	</property>
	<property name="author">
		<object name="Author"/>
	</property>
		
	<!-- a custom property type! -->
	<property name="age">
		<custom perl:class="example::BookStore::BookAgeProperty"/>
	</property>

	<!-- a simple property with slightly complex options -->
	<property name="publisher_id">
		<simple>
			<options
				inclusive="true"
				table="publisher"
				column="name">
					<!-- put them in reverse order, cuz we can! -->
					<criteria>
						<order-by>
							<attribute name="publisher/name"/>
						</order-by>
					</criteria>
			</options>
		</simple>
	</property>
</object>

=end Xmldoom

=cut

