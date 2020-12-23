package Toolforge::MixNMatch::Print::User;

use strict;
use warnings;

use Error::Pure qw(err);

our $VERSION = 0.04;

sub print {
	my $obj = shift;

	if (! defined $obj) {
		err "Object doesn't exist.";
	}
	if (! $obj->isa('Toolforge::MixNMatch::Object::User')) {
		err "Object isn't 'Toolforge::MixNMatch::Object::User'.";
	}

	my $print = $obj->username.' ('.$obj->uid.'): '.$obj->count;

	return $print;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Toolforge::MixNMatch::Print::User - Mix'n'match user structure print.

=head1 SYNOPSIS

 use Toolforge::MixNMatch::Print::User qw(print);

 my $print = print($obj);

=head1 SUBROUTINES

=head2 C<print>

 my $print = print($obj);

Print Toolforge::MixNMatch::Object::User instance to user output.

Returns string.

=head1 ERRORS

 obj2struct():
         Object doesn't exist.
         Object isn't 'Toolforge::MixNMatch::Object::User'.

=head1 EXAMPLE

 use strict;
 use warnings;

 use Data::Printer;
 use Toolforge::MixNMatch::Object::User;
 use Toolforge::MixNMatch::Print::User;

 # Object.
 my $obj = Toolforge::MixNMatch::Object::User->new(
         'count' => 6,
         'uid' => 1,
         'username' => 'Skim',
 );

 # Print.
 print Toolforge::MixNMatch::Print::User::print($obj)."\n";

 # Output:
 # Skim (1): 6

=head1 DEPENDENCIES

L<Error::Pure>.

=head1 SEE ALSO

=over

=item L<Toolforge::MixNMatch::Print>

Toolforge Mix'n'match tool object print routines.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Toolforge-MixNMatch-Print>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© Michal Josef Špaček 2020

BSD 2-Clause License

=head1 VERSION

0.04

=cut
