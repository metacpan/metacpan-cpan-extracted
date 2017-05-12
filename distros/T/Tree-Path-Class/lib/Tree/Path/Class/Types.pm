use utf8;
use Modern::Perl;

package Tree::Path::Class::Types;
{
    $Tree::Path::Class::Types::DIST = 'Tree-Path-Class';
}
use strict;

our $VERSION = '0.007';    # VERSION
use Carp;
use Path::Class;
use MooseX::Types -declare => [qw(TreePath TreePathValue Tree)];
use MooseX::Types::Moose qw(ArrayRef Maybe Str);
use MooseX::Types::Path::Class qw(Dir is_Dir to_Dir File is_File to_File);
## no critic (Subroutines::ProhibitCallsToUndeclaredSubs)

class_type Tree,     { class => 'Tree' };
class_type TreePath, { class => 'Tree::Path::Class' };
subtype TreePathValue,
    as Maybe [ Dir | File ];    ## no critic (Bangs::ProhibitBitwiseOperators)

coerce TreePath, from Tree, via {
    my $tree = $_;
    my $tpc  = Tree::Path::Class->new( $tree->value );
    for my $child ( $tree->children ) { $tpc->add_child($child) }
    return $tpc;
};

coerce TreePathValue,
    from Dir,      via { dir($_) },
    from File,     via { file($_) },
    from ArrayRef, via { _coerce_val( @{$_} ) },
    from Str,      via { _coerce_val($_) };

sub _coerce_val {
    return if !( my @args = @_ );
    for my $arg ( grep {$_} @args ) {
        if ( not( is_Dir($arg) or is_File($arg) ) ) {
            $arg = to_Dir($arg)
                or croak; ## no critic (ErrorHandling::RequireUseOfExceptions)
        }
    }
    return is_File( $args[-1] ) ? to_File( \@args ) : to_Dir( \@args );
}

1;

# ABSTRACT: Type library for Tree::Path::Class

__END__

=pod

=encoding UTF-8

=for :stopwords Mark Gardner eBay Enterprise cpan testmatrix url annocpan anno bugtracker
rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 NAME

Tree::Path::Class::Types - Type library for Tree::Path::Class

=head1 VERSION

version 0.007

=head1 SYNOPSIS

    use Moose;
    use Tree::Path::Class::Types 'TreePath';

    has tree => (is => 'ro', isa => TreePath, coerce => 1);

=head1 DESCRIPTION

This is a L<Moose type library|MooseX::Types> for
L<Tree::Path::Class|Tree::Path::Class>.

=head1 TYPES

=head2 TreePath

An object of L<Tree::Path::Class|Tree::Path::Class>.  Can coerce from
L<Tree|Tree>, where it will also coerce the tree's children.

=head2 TreePathValue

Can either be undefined. a L<Path::Class::Dir|Path::Class::Dir> or a
L<Path::Class:File|Path::Class::File>.  Handles all the coercions that
L<MooseX::Types::Path::Class|MooseX::Types::Path::Class> handles.

=head2 Tree

A L<Tree|Tree> object.

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Tree::Path::Class

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Tree-Path-Class>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/Tree-Path-Class>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Tree-Path-Class>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Tree-Path-Class>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/T/Tree-Path-Class>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Tree-Path-Class>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Tree::Path::Class>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the web
interface at L<https://github.com/mjgardner/Tree-Path-Class/issues>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/mjgardner/Tree-Path-Class>

  git clone git://github.com/mjgardner/Tree-Path-Class.git

=head1 AUTHOR

Mark Gardner <mjgardner@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by eBay Enterprise.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
