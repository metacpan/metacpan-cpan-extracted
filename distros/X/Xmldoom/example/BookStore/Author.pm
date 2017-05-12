
package example::BookStore::Author;
use base qw(example::BookStore::Object);

1;

__END__

=pod

=begin Xmldoom

<object name="Author" table="author">
	<property name="author_id">
		<simple/>
	</property>
	<property name="first_name">
		<simple/>
	</property>
	<property name="last_name">
		<simple/>
	</property>

	<!-- external property -->
	<property name="book">
		<object name="Book"/>
	</property>
</object>

=end Xmldoom

=cut

