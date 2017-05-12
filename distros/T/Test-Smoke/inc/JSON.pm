package JSON;
use warnings;
use strict;

our $VERSION = 0.01;

=head1 NAME

JSON - A JSON:PP/JSON::XS Factory Class

=head1 SYNOPSIS

    use JSON;
    my $json = JSON->new->utf8->pretty->encode(\%data);

=head1 DESCRIPTION

This is purely a fallback factory class that helps keep our code clean.

This is for people with a clean perl 5.14+ install that have L<JSON::PP> but not
JSON. Also people that installed L<JSON::XS> on a pre-5.14 system.

=cut

use Exporter 'import';
our @EXPORT = qw/encode_json decode_json/;

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

=head2 my $class = JSON->find_base_class()

On success returns one of: B<JSON::XS>, B<JSON::PP>

Returns undef on failure.

=cut

sub find_base_class {
    for my $try_class (qw/JSON::XS JSON::PP/) {
        eval "use $try_class";
        next if $@;
        return $try_class;
        last;
    }
    return;
}

=head2 my $obj = JSON->new(<arguments>)

If a base class is found, will return an instantiated object.

This will die() if no base class could be found.

=cut

sub new {
    my $class = shift;
    return $json_base_class->new(@_);
}

1;

=head1 COPYRIGHT

(c) 2014, All rights reserved.

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
