package Test::Proto::Role::Tagged;
use 5.008;
use strict;
use warnings;
use Moo::Role;

=head1 NAME

Test::Proto::Role::Tags - Role containing methods for tagging cases and prototypes

=head1 SYNOPSIS

This class is not for public consumption, only its methods are. 

It is a role used to provide for accessing 'tags', which are flags associated with a test case (L<Test::Proto::TestCase>) or prototype (L<Test::Proto::Base>) to give clues to the runner or formatter to indicate how to deal with the object.

=head1 METHODS


=head3 tags

	$object->tags; # returns ['tag1', 'tag2'], etc.

Returns the associated tags.

=cut

has tags    => is  => 'rw',
	default => sub { [] };

=head3 add_tag

	$object->add_tag('author_testing');

Adds the tag to the object, and returns the object.

=cut

sub add_tag {
	my ( $self, $tag ) = @_;
	my $tags = $self->tags;
	push @$tags, $tag unless grep { $_ eq $tag } @$tags;
	return $self;
}

=head3 has_tag

	$object->has_tag('author_testing'); # returns 0 or 1

Determines if the object has this tag. Exact matches only. 

=cut

sub has_tag {
	my ( $self, $tag ) = @_;
	foreach my $t ( @{ $self->tags } ) {
		return 1 if $t eq $tag;
	}
	return 0;
}

=head3 remove_tag

	$object->remove_tag('author_testing');

Removes the tag and returns the object. Does nothing if the tag was not present to begin with. 

=cut

sub remove_tag {
	my ( $self, $tag ) = @_;
	my $tags = $self->tags;
	return $self unless @$tags;
	for my $i ( 0 .. $#{$tags} ) {
		if ( $tag eq $tags->[$i] ) {
			delete $tags->[$i];
		}
	}
	return $self;
}

=head1 OTHER INFORMATION

For author, version, bug reports, support, etc, please see L<Test::Proto>. 

=cut

1;
