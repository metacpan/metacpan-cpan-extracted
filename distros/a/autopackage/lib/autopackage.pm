package autopackage;
{
  $autopackage::VERSION = '0.01';
}
use strict;
use warnings;

# ABSTRACT: Automatically set your package based on how your module was loaded.


use B::Hooks::Parser  0.08   qw();
use Carp              0      qw(confess);

sub import {

    # figure out where we're called from
    my (undef, $filename) = caller(0);

    # figure out where it got loaded via %INC.
    my $pkg;
    for my $k (sort keys %INC)
    {
        if ($INC{$k} eq $filename)
        {
            $pkg = $k;
            $pkg =~ s<[/\\]><::>g;
            $pkg =~ s<\.pm$><>i; # can this be uppercase on some platforms?
            last;
        }
    }

    confess("autopackage could not determine package for filename '$filename', died")
        unless defined $pkg;

    B::Hooks::Parser::inject("; package $pkg;");
};

1;

__END__
=pod

=head1 NAME

autopackage - Automatically set your package based on how your module was loaded.

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    use autopackage;

=head1 DESCRIPTION

Ever have seriously deep package structure?  And then typos between the
file/pathname and the package name in your module?  This happens to me all
the time.  And, worse, I sometimes need to re-seat a module - moving it from
one namespace to another.  Guess what happens then: I forget to change the
package line.  And then it takes me 5 minutes to figure out why it's not
working (it used to take longer, but it happens so often now I generally
figure it out sooner).

Lo and behold, a pragma.  Simply C<use autopackage;> at the top of your
module, and you get your package declared for you at runtime.  Don't specify
the package anymore, and you can't end up with a misspelling.

This really works well for plugins where the name of the module is
figured out dynamically anyway, other modules are harder to rename.  But
it still can be useful there as it's one less thing to change.

=head1 AUTHOR

Darin McBride, C<< <dmcbride at cpan.org> >>

=head1 BUGS

This also probably will break CPAN's indexer.  So it may not be so useful
for packages you want CPAN to index.

Please report any bugs or feature requests to C<bug-autopackage at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=autopackage>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc autopackage

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=autopackage>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/autopackage>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/autopackage>

=item * Search CPAN

L<http://search.cpan.org/dist/autopackage/>

=back

=head1 COPYRIGHT

    Copyright (c) 2012, Darin McBride. All Rights Reserved.
    This module is free software. It may be used, redistributed
    and/or modified under the same terms as Perl itself.

=head1 AUTHOR

Darin McBride <dmcbride@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Darin McBride.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

