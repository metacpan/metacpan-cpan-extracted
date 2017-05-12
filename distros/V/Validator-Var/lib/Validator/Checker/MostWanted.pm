package Validator::Checker::MostWanted;
use 5.006;
use strict;
use warnings;
use Scalar::Util qw(blessed);


=head1 NAME

Validator::Checker::MostWanted - "most wanted" checkers for Validator::Var.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(Ref Type Can Base Min Max Between Regexp Length);

sub Ref     { [\&_ref,     'Ref',     'is reference' ] }
sub Type    { [\&_ref,     'Type',    'is reference'] }
sub Can     { [\&_can,     'Can',     'has method'] }
sub Base    { [\&_base,    'Base',    'inherit class'] }
sub Min     { [\&_min,     'Min',     'is grater than'] }
sub Max     { [\&_max,     'Max',     'is less than'] }
sub Between { [\&_between, 'Between', 'is between'] }
sub Regexp  { [\&_regexp,  'Regexp',  'match regexp'] }
sub Length  { [\&_length,  'Length',  'has length equal to' ] }


=head1 SYNOPSIS

see Validator::Var

=head1 EXPORT

This package exports "most wanted" checkers for Validator::Var.

=head2 Ref @refs

variable is a reference to one of listed in @refs

=head2 Type @types

equivalent to C<Ref> checker

=head2 Can @methods

variable is blessed and has methods listed in @methods

=head2 Base @base_classes

variable is an object and inherited from all classes listed in @base_classes

=head2 Min $min_val

variable is a scalar and it's value is grater or equal to $min_val

=head2 Max $max_val

variable is a scalar and it's value is less or equal to $max_val

=head2 Between $min_val $max_val

variable is a scalar and it's value is bitween $min_val and $max_val (inclusive)

=head2 Regexp $re

variable is a scalar and matches regexp $re

=head2 Length $len_val

variable is a scalar and it's length is equal to $len_val

=cut

#
# returns true if $var is the reference to one from @refnames
#
sub _ref
{
    my ($var, @refnames) = @_;
    return 0 unless ref $var;
    return 0 unless scalar @refnames;
    my $refvar = ref $var;

    foreach( @refnames ) {
        return 1 if $refvar eq $_;
    }
    return 0;
}

#
# returns true if $var is reference and it has methods listed in @methods
#
sub _can {
    my ($var, @methods) = @_;
    return 0 unless blessed $var;
    return 0 unless scalar @methods;

    foreach( @methods ) {
        return 0 unless $var->can($_);
    }
    return 1;
}

sub _base {
    my ($var, @base_classes) = @_;
    return 0 unless ref $var;
    return 0 unless scalar @base_classes;

    foreach( @base_classes ) {
        return 0 unless $var->isa($_);
    }
    return 1;
}

sub _min($$) {
    return 0 if ref $_[0];
    return $_[0] >= $_[1];
}

sub _max($$) {
    return 0 if ref $_[0];
    return $_[0] <= $_[1];
}

sub _between($$$)
{
    return 0 if ref $_[0];
    my $rc = $_[0] >= $_[1] && $_[0] <= $_[2];
    return $rc;
}

sub _regexp($$)
{
    return 0 if ref $_[0];
    return $_[0] =~ $_[1] ? 1 : 0;
}

sub _length($$) {
    return 0 if ref $_[0];
    return length $_[0] == $_[1];
}

=head1 AUTHOR

Fedor Semenov, C<< <fedor.v.semenov at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-validator-var at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Validator-Var>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Validator::Checker::MostWanted


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Validator-Var>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Validator-Var>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Validator-Var>

=item * Search CPAN

L<http://search.cpan.org/dist/Validator-Var/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Fedor Semenov.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Validator::Checker::MostWanted
