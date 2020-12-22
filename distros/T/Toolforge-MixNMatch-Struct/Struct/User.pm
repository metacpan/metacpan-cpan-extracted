package Toolforge::MixNMatch::Struct::User;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;
use Toolforge::MixNMatch::Object::User;

Readonly::Array our @EXPORT_OK => qw(obj2struct struct2obj);

our $VERSION = 0.04;

sub obj2struct {
	my $obj = shift;

	if (! defined $obj) {
		err "Object doesn't exist.";
	}
	if (! $obj->isa('Toolforge::MixNMatch::Object::User')) {
		err "Object isn't 'Toolforge::MixNMatch::Object::User'.";
	}

	my $struct_hr = {
		'cnt' => $obj->count,
		'uid' => $obj->uid,
		'username' => $obj->username,
	};

	return $struct_hr;
}

sub struct2obj {
	my $struct_hr = shift;

	my $obj = Toolforge::MixNMatch::Object::User->new(
		'count' => $struct_hr->{'cnt'},
		'uid' => $struct_hr->{'uid'},
		'username' => $struct_hr->{'username'},
	);

	return $obj;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Toolforge::MixNMatch::Struct::User - Mix'n'match user structure serialization.

=head1 SYNOPSIS

 use Toolforge::MixNMatch::Struct::User qw(obj2struct struct2obj);

 my $struct_hr = obj2struct($obj);
 my $obj = struct2obj($struct_hr);

=head1 DESCRIPTION

This conversion is between object defined in Toolforge::MixNMatch::Object::User and structure
serialized via JSON to Mix'n'match application.

=head1 SUBROUTINES

=head2 C<obj2struct>

 my $struct_hr = obj2struct($obj);

Convert Toolforge::MixNMatch::Object::User instance to structure.

Returns reference to hash with structure.

=head2 C<struct2obj>

 my $obj = struct2obj($struct_hr);

Convert structure of time to object.

Returns Toolforge::MixNMatch::Object::User instance.

=head1 ERRORS

 obj2struct():
         Object doesn't exist.
         Object isn't 'Toolforge::MixNMatch::Object::User'.

=head1 EXAMPLE1

 use strict;
 use warnings;

 use Data::Printer;
 use Toolforge::MixNMatch::Object::User;
 use Toolforge::MixNMatch::Struct::User qw(obj2struct);

 # Object.
 my $obj = Toolforge::MixNMatch::Object::User->new(
         'count' => 6,
         'uid' => 1,
         'username' => 'Skim',
 );

 # Get structure.
 my $struct_hr = obj2struct($obj);

 # Dump to output.
 p $struct_hr;

 # Output:
 # \ {
 #     cnt        6,
 #     uid        1,
 #     username   "Skim"
 # }

=head1 EXAMPLE2

 use strict;
 use warnings;

 use Toolforge::MixNMatch::Struct::User qw(struct2obj);

 # Time structure.
 my $struct_hr = {
        'cnt' => 6,
        'uid' => 1,
        'username' => 'Skim',
 };

 # Get object.
 my $obj = struct2obj($struct_hr);

 # Get count.
 my $count = $obj->count;

 # Get user UID.
 my $uid = $obj->uid;

 # Get user name.
 my $username = $obj->username;

 # Print out.
 print "Count: $count\n";
 print "User UID: $uid\n";
 print "User name: $username\n";

 # Output:
 # Count: 6
 # User UID: 1
 # User name: Skim

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<Readonly>,
L<Toolforge::MixNMatch::Struct::User>.

=head1 SEE ALSO

=over

=item L<Toolforge::MixNMatch::Struct>

Toolforge Mix'n'match tool structures.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Toolforge-MixNMatch-Struct>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© Michal Josef Špaček 2020

BSD 2-Clause License

=head1 VERSION

0.04

=cut
