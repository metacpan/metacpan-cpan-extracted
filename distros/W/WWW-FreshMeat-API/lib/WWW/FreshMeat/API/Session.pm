package WWW::FreshMeat::API::Session;
use Moose::Role;

our $VERSION = '0.01';

has 'session' => ( isa => 'HashRef', is => 'rw', default => sub { +{} } );
has 'fatal'   => ( isa => 'Bool', is => 'rw', default => 1 );

sub sid { $_[0]->session->{ SID } }

sub lifetime { $_[0]->session->{ Lifetime } }

sub api { $_[0]->session->{ 'API Version' } }

sub clear_session { 
    $_[0]->{session} = {};
}


no Moose::Role;

1;


__END__


=head1 NAME

WWW::FreshMeat::API::Session - Session role for WWW::FreshMeat::API

=head1 VERSION

Version 0.01


=head1 SYNOPSIS

    use Moose;

    with 'WWW::FreshMeat::API::Session';
    

=head1 DESCRIPTION

This is a Moose role used by WWW::FreshMeat::API providing session attributes & methods.


=head1 EXPORT

None.


=head1 ATTRIBUTES

=head2 session

=head2 fatal

Not implemented yet.


=head1 METHODS

=head2 sid

=head2 lifetime

=head2 api

=head2 clear_session


=head1 AUTHOR

Barry Walsh, C<< <draegtun at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-freshmeat-api at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-FreshMeat-API>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::FreshMeat::API::Session


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-FreshMeat-API>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-FreshMeat-API>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-FreshMeat-API>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-FreshMeat-API/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 SEE ALSO

=head2 Other WWW::FreshMeat::API modules

L<WWW::FreshMeat::API>


=head1 COPYRIGHT & LICENSE

Copyright 2009 Barry Walsh (Draegtun Systems Ltd), all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

