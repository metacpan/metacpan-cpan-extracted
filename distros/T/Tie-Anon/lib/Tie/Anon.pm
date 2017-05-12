package Tie::Anon;
use strict;
no strict 'refs';
use warnings;
use Exporter qw(import);

our $VERSION = "0.02";

our @EXPORT = our @EXPORT_OK = qw(tiea tieh ties);

my %sigil_for = (
    tiea => '@',
    tieh => '%',
    ties => '$'
);

foreach my $method (keys %sigil_for) {
    my $sigil = $sigil_for{$method};
    *{$method} = eval(<<"DEF");
sub {
    my \$class = shift;
    my \$result = tie(my ${sigil}tied, \$class, \@_);
    return undef if not defined \$result;
    return \\${sigil}tied;
}
DEF
}

1;
__END__

=pod

=head1 NAME

Tie::Anon - tie anonymous array, hash, etc. and return it

=head1 SYNOPSIS

    use Tie::Anon qw(tiea);
    use Tie::File;
    
    for my $line (@{tiea('Tie::File', "hoge.dat")}) {
        print $line;
    }

=head1 DESCRIPTION

When I feel extremely lazy, I don't want to write

    my $tied_arrayref = do {
        tie my @a, "Tie::File", "hoge.dat";
        \@a;
    };

With L<Tie::Anon>, you can do the same by

    my $tied_arrayref = tiea("Tie::File", "hoge.dat");


=head1 EXPORTABLE FUNCTIONS

None of these functions are exported by default.
You must import them explicitly.

=head2 $tied_arrayref = tiea($class, @args)

Create an anonymous array-ref, tie that array to the C<$class> with C<@args>,
and return it.

If C<tie()> fails, it returns C<undef>.

=head2 $tied_hashref = tieh($class, @args)

Create an anonymous hash-ref, tie that hash to the C<$class> with C<@args>,
and return it.

If C<tie()> fails, it returns C<undef>.

=head2 $tied_scalarref = ties($class, @args)

Create an anonymous scalar-ref, tie that scalar to the C<$class> with C<@args>,
and return it.

If C<tie()> fails, it returns C<undef>.

=head1 SEE ALSO

=over

=item *

L<perltie>

=item *

C<tie>, C<untie> and C<tied> in L<perlfunc>

=back

=head1 REPOSITORY

L<https://github.com/debug-ito/Tie-Anon>

=head1 BUGS AND FEATURE REQUESTS

Please report bugs and feature requests to my Github issues
L<https://github.com/debug-ito/Tie-Anon/issues>.

Although I prefer Github, non-Github users can use CPAN RT
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Tie-Anon>.
Please send email to C<bug-Tie-Anon at rt.cpan.org> to report bugs
if you do not have CPAN RT account.


=head1 AUTHOR
 
Toshio Ito, C<< <toshioito at cpan.org> >>


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Toshio Ito.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

