package lexically;
use strict;
use warnings;

our $VERSION = '0.03';

use Exporter::Lexical 0.02 ();
use Module::Runtime 'require_module';

=head1 NAME

C<lexically> - lexically import functions from non-lexical exporters

=head1 SYNOPSIS

  package Foo;
  use Moose;
  use lexically 'Scalar::Util' => 'reftype';

=head1 DESCRIPTION

This pragma turns normal package-based exporter modules into lexical exporters.
This can be useful to ensure that your package namespace doesn't get polluted
(preventing the need for something like L<namespace::clean> entirely).

=cut

our $INDEX = 0;

sub import {
    shift;
    my ($package, @args) = @_;

    my $index = $INDEX++;
    my $scratchpad = "lexically::scratchpad_$index";
    my $stash = do {
        no strict 'refs';
        \%{ $scratchpad . '::' }
    };

    require_module($package);

    eval qq[package $scratchpad; '$package'->import(\@args)];
    die if $@;

    my @exports = grep {
        ref(\$stash->{$_}) ne 'GLOB' || defined(*{ $stash->{$_} }{CODE})
    } keys %$stash;

    my $import = Exporter::Lexical::build_exporter({
        -exports => \@exports,
    }, $scratchpad);

    $import->($package, @args);

    delete $lexically::{"scratchpad_${index}::"};
}

=head1 BUGS

No known bugs.

Please report any bugs to GitHub Issues at L<https://github.com/leonerd/p5-lexically/issues>.

=head1 SEE ALSO

L<Exporter::Lexical>

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc lexically

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/release/lexically>

=item * Github

L<https://github.com/leonerd/p5-lexically>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=lexically>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/lexically>

=back

=head1 AUTHOR

Originally written by Jesse Luehrs <doy@tozt.net>

Currently maintained by Paul Evans <leonerd@leonerd.org.uk>

=cut

1;
