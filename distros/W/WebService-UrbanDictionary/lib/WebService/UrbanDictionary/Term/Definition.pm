package WebService::UrbanDictionary::Term::Definition;

use Moo;

has 'defid'        => ( is => 'ro' );
has 'word'         => ( is => 'ro' );
has 'author'       => ( is => 'ro' );
has 'permalink'    => ( is => 'ro' );
has 'definition'   => ( is => 'ro' );
has 'example'      => ( is => 'ro' );
has 'thumbs_up'    => ( is => 'ro' );
has 'thumbs_down'  => ( is => 'ro' );
has 'current_vote' => ( is => 'ro' );

1;

__END__

=pod

=head1 NAME

WebService::UrbanDictionary::Term::Definition

=head1 VERSION

version 2.015

=head1 SYNOPSIS

	use WebService::UrbanDictionary;

	my $ud = WebService::UrbanDictionary->new;

	my $results = $ud->request('perl'); 

	for my $each (@{ $results->definitions }) {
		printf "Definition: %s\n(by %s)\n\n", $each->definition, $each->author;
	}

=head1 DESCRIPTION

WebService::UrbanDictionary::Term::Definition provides methods for accessing the data stored within 
L<WebService::UrbanDictionary::Term> objects, which are in turn returned from a L<WebService::UrbanDictionary> object's C< request(word) > method.

=head2 Methods

=over 12

=item C<< defid >>

Returns the definition ID for the definition.

=item C<< word >>

Returns the word queried.

=item C<< author >>

Returns the author of the definition.

=item C<< permalink >>

Returns a permalink (URL) to the definition.

=item C<< definition >>

Returns the definition itself.

=item C<< example >>

Returns the example used in the definition, if one exists.

=item C<< thumbs_up >>

Returns the number of thumbs ups given to the definition.

=item C<< thumbs_down >>

Returns the number of thumbs downs given to the definition.

=item C<< current_vote >>

Returns the current vote for the definition, if it exists.

=back

=head1 NAME

WebService::UrbanDictionary::Term::Definition - Wrapper for retreiving data from L<WebService::UrbanDictionary::Term> objects.

=head1 SEE ALSO

L<WebService::UrbanDictionary>

L<WebService::UrbanDictionary::Term>

=head1 AUTHOR

William Woodruff <william@tuffbizz.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by William Woodruff.

This is free software, licensed under:

  The MIT (X11) License

=cut
