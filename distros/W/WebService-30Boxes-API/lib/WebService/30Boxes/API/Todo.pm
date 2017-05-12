package WebService::30Boxes::API::Todo;

use strict;
use warnings;
use Carp qw/croak/;

our $VERSION = '1.05';

sub new {
	my ($class, $result, $success, $error_code, $error_message) = @_;
	croak "The response from 30Boxes was not a success" unless $result->{'success'};

	#%{$result->{'_xml'}->{'todoList'}->{'todo'}} is a hash with todo ids as keys
	my $self = {	todo => $result->{'_xml'}->{'todoList'}->{'todo'},
			todoIds => [sort keys %{$result->{'_xml'}->{'todoList'}->{'todo'}}],
			todoIndex => -1,
			success => $success,
			error_code => $error_code,
			error_message => $error_message,
	};
	bless $self, $class;
	return $self;
}

#return an array of todo ids
sub get_todoIds {
	my ($self) = @_;
	return @{$self->{'todoIds'}};
}

#return a reference to an array of todo ids
sub get_ref_todoIds {
	my ($self) = @_;
	return $self->{'todoIds'};
}

#advance the todoIndex
sub nextTodoId {
	my ($self) = @_;
	return 0 if $self->{'todoIndex'} == scalar(@{$self->{'todoIds'}}) - 1;
	return $self->{'todoIds'}->[$self->{'todoIndex'}++];
}
	
#returns a list of tags
sub get_tags {
	my ($self, $todoId) = @_;
	$todoId = $self->{'todoIds'}->[$self->{'todoIndex'}] if 0 == $#_;
	my $temp = $self->{'todo'}->{$todoId}->{'tags'};
	return "" if ref($temp);#it's a hash if empty
	$temp =~ s/\s+/ /;
	return split(/ /, $temp);
}

#gets the title for the todos
sub get_title {
	my ($self, $todoId) = @_;
	$todoId = $self->{'todoIds'}->[$self->{'todoIndex'}] if 0 == $#_;
	return $self->{'todo'}->{$todoId}->{'summary'};
}

#get if the the todo is marked as done
#returns 1 if yes, 0 if not
sub isDone {
	my ($self, $todoId) = @_;
	$todoId = $self->{'todoIds'}->[$self->{'todoIndex'}] if 0 == $#_;
	return $self->{'todo'}->{$todoId}->{'done'};
}

#returns the position of the todo in the list
sub get_position {
	my ($self, $todoId) = @_;
	$todoId = $self->{'todoIds'}->[$self->{'todoIndex'}] if 0 == $#_;
	return $self->{'todo'}->{$todoId}->{'position'};
}

sub get_externalUID {
	my ($self, $todoId) = @_;
	$todoId = $self->{'todoIds'}->[$self->{'todoIndex'}] if 0 == $#_;
	my $temp = $self->{'todo'}->{$todoId}->{'externalUID'};
	return "" if ref($temp);#it's a hash if empty
	$temp =~ s/\s+/ /;
	return split(/ /, $temp);
}


1;
__END__

=head1 NAME

WebService::30Boxes::API::Todo - Object returned by WebService::30Boxes::API::call("todo.Get")

=head1 SYNOPSIS

  #$api_key and $auth_token are defined before
  my $boxes = WebService::30Boxes::API->new(api_key => $api_key);
  
  my $todos = $boxes->call('todos.Get', {authorizedUserToken => $auth_token});
  if($todos->{'success'}){
  	#while ($todos->nextTodoId){ - if you use this, you don't need to specify
  	#$_ as an argument
  	#foreach (@{$todos->get_ref_todoIds}){
  	foreach ($todos->get_todoIds){
  		print "Todo id: $_\n";
  		print "Title: " . $todos->get_title($_) . "\n";
  		print "Tags: ";
  		foreach ($todos->get_tags($_)){print "$_\n";}
  		print "Done: " . $todos->isDone($_) . "\n";
  		print "Position: " . $todos->get_position($_) . "\n";
  		print "External UID: " . $todos->get_externalUID($_) . "\n";
  	}
  }
  else{
  	print "An error occured (" . $todos->{'error_code'} . ": " .
  		$todos->{'error_msg'} . ")\n";
  }

=head1 DESCRIPTION

An object of this type is returned by the WebService::30Boxes::API::call("todos.Get") function

=head2 METHODS

The following methods can be used

=head3 new

Create a new C<WebService::30Boxes::API::Todo> object.

=over 5

=item result

(B<Mandatory>) Result must be the the hash function returned by the XML parser. 
Results are undefined if some other hash is passed in.

=item success

(B<Mandatory>) If the API call was successful or not.

=item error_code

(B<Optional>) If success is false, this must be supplied

=item error_message

(B<Optional>) If success is false, this must be supplied

=back

=head3 get_todoIds

Returns an array of todo ids.

You can then use this to call any of the following functions.

=head3 get_ref_todoIds

Returns a reference to an array of todo ids.

You can then use this to call any of the following functions.

=head3 nextTodoId

Advances the todo index and returns the new todoID (for convenience)

Arguments:

=over 5

=item todoId

(B<Optional>) The todoId of the todo for which you want to retreive the information. 
If not present, the next todoId will be used as an index. The next todoId is set by calling nextTodoId.

=back

=head3 get_tags

Returns a list of tags.

Arguments:

=over 5

=item todoId

(B<Optional>) The todoId of the todo for which you want to retreive the information. 
If not present, the next todoId will be used as an index. The next todoId is set by calling nextTodoId.

=back

=head3 get_title

Returns the title for the todo. 

Arguments:

=over 5

=item todoId

(B<Optional>) The todoId of the todo for which you want to retreive the information. 
If not present, the next todoId will be used as an index. The next todoId is set by calling nextTodoId.

=back

=head3 isDone

Returns the todo is done or not
Returns 1 if yes, 0 if not

Arguments:

=over 5

=item todoId

(B<Optional>) The todoId of the todo for which you want to retreive the information. 
If not present, the next todoId will be used as an index. The next todoId is set by calling nextTodoId.

=back

=head3 get_position

Returns the position of the todo as the user defined it

Arguments:

=over 5

=item todoId

(B<Optional>) The todoId of the todo for which you want to retreive the information. 
If not present, the next todoId will be used as an index. The next todoId is set by calling nextTodoId.

=back

=head3 get_externalUID

Returns the user defined ID for this todo
The return value is a string

Arguments:

=over 5

=item todoId

(B<Optional>) The todoId of the todo for which you want to retreive the information. 
If not present, the next todoId will be used as an index. The next todoId is set by calling nextTodoId.

=back

=head1 TODO

Add more error checking. Compact the code and make it more efficient. Please email me for feature requests.

=head1 BUGS

Please notify chitoiup@umich.edu of any bugs.

=head1 SEE ALSO

L<http://30boxes.com/>, L<http://30boxes.com/api/>

L<WebService::30Boxes::API>

L<WebService::30Boxes::API::Event>

=head1 AUTHOR

Robert Chitoiu, E<lt>chitoiup@umich.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Robert Chitoiu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
