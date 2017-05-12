
package example::BookStore::Publisher;
use base qw(example::BookStore::Object);

use strict;

1;

__END__

=pod

=begin Xmldoom

<object name="Publisher" table="publisher">
	<property name="publisher_id">
		<simple/>
	</property>
	<property name="name">
		<simple/>
	</property>

	<!-- external property -->
	<property name="book">
		<object name="Book"/>
	</property>
</object>

=end Xmldoom

=cut

