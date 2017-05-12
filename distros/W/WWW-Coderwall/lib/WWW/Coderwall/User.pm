package WWW::Coderwall::User;

use Moo;


has username => (
    is => 'ro',
);


has name => (
    is => 'ro',
);


has location => (
    is => 'ro',
);


has endorsements => (
    is => 'ro',
);


has team => (
    is => 'ro',
);


has accounts => (
    is => 'ro',
);


has badges => (
    is => 'ro',
);

1;

__END__
=pod

=head1 NAME

WWW::Coderwall::User

=head1 VERSION

version 0.003

=head1 ATTRIBUTES

=head2 username

coderwall username

=head2 name

full name

=head2 location

location set in the user's coderwall profile

=head2 endorsements

number of endorsements the user has received

=head2 team

id of the user's team

=head2 accounts

hash of accounts that the user has added in their profile

=head2 badges

array of badges that the user has earned

=head1 AUTHOR

Robert Picard <mail@robert.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Robert Picard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

