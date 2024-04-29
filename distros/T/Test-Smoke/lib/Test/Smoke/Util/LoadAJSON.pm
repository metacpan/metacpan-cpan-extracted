package Test::Smoke::Util::LoadAJSON;
use warnings;
use strict;

our $VERSION = '0.04';

=head1 NAME

Test::Smoke::Util::LoadAJSON - A Cpanel::JSON::XS/JSON:PP/JSON::XS Factory Class

=head1 SYNOPSIS

    use Test::Smoke::Util::LoadAJSON;
    my $json = Test::Smoke::Util::LoadAJSON->new->utf8->pretty->encode(\%data);

=head1 DESCRIPTION

This is purely a fallback factory class that helps keep our code clean.

This is for people with a clean perl 5.14+ install that have L<JSON::PP> but not
JSON. Also people that installed L<JSON::XS> on a pre-5.14 system.

Also checks for C<$ENV{PERL_JSON_BACKEND}> to force either of the two.

=cut

use Exporter 'import';
our @EXPORT = qw/encode_json decode_json JSON/;

no warnings 'redefine';
my $json_base_class;
sub import {
    my ($class) = @_;
    $json_base_class = $class->find_base_class;

    die "Could not find a supported JSON implementation.\n"
        if !$json_base_class;

    {
        no warnings 'redefine', 'once';
        *encode_json = \&{$json_base_class."::encode_json"};
        *decode_json = \&{$json_base_class."::decode_json"};
    }
    goto &Exporter::import;
}

=head2 my $class = Test::Smoke::Util::LoadAJSON->find_base_class()

On success returns one of: B<Cpanel::JSON::XS>, B<JSON::PP>, B<JSON::XS>

Returns undef on failure.

=cut

sub find_base_class {
    my @backends = $ENV{PERL_JSON_BACKEND}
        ? ($ENV{PERL_JSON_BACKEND})
        : qw/Cpanel::JSON::XS JSON::PP JSON::XS/;
    for my $try_class (@backends) {
        eval "use $try_class";
        next if $@;
        return $try_class;
        last;
    }
    return;
}

=head2 JSON

Returns the current C<$json_base_class>.

=cut

sub JSON { $json_base_class }

=head2 my $obj = Test::Smoke::Util::LoadAJSON->new(<arguments>)

If a base class is found, will return an instantiated object.

This will die() if no base class could be found.

=cut

sub new {
    my $class = shift;
    return $json_base_class->new(@_);
}

1;

=head1 COPYRIGHT

E<copy> MMXIV-MMXXIII, All rights reserved.

  * Abe Timmerman <abeltje@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See:

=over 4

=item * L<http://www.perl.com/perl/misc/Artistic.html>

=item * L<http://www.gnu.org/copyleft/gpl.html>

=back

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
