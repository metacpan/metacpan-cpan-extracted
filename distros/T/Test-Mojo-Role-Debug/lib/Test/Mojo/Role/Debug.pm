package Test::Mojo::Role::Debug;

use Mojo::Base -base;
use Role::Tiny;
use Carp qw/croak/;
use Test::More ();

our $VERSION = '1.003004'; # VERSION

sub d {
    my ( $self, $selector ) = @_;
    return $self->success ? $self : $self->da( $selector );
}

sub da {
    my ( $self, $selector ) = @_;
    my $markup = length($selector//'')
        ? $self->tx->res->dom->at($selector)
        : $self->tx->res->dom;

    unless ( defined $markup and length $markup ) {
        Test::More::diag "\nDEBUG DUMPER: the selector ($selector) you provided "
            . "did not match any elements\n\n";
        return $self;
    }

    Test::More::diag "\nDEBUG DUMPER:\n$markup\n\n";

    $self;
}

q|
The optimist says: "The glass is half full"
The pessimist says: "The glass is half empty"
The programmer says: "The glass is twice as large necessary"
|;

__END__

=encoding utf8

=for stopwords Znet Zoffix app DOM

=head1 NAME

Test::Mojo::Role::Debug - Test::Mojo role to make debugging test failures easier

=head1 SYNOPSIS

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-code.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

    use Test::More;
    use Test::Mojo::WithRoles 'Debug';
    my $t = Test::Mojo::WithRoles->new('MyApp');

    $t->get_ok('/')->status_is(200)
        ->element_exists('existant')
        ->d         # Does nothing, since test succeeded
        ->element_exists('non_existant')
        ->d         # Dump entire DOM on fail
        ->d('#foo') # Dump a specific element on fail
        ->da        # Always dump
    ;

    done_testing;

=for html  </div></div>

=head1 DESCRIPTION

When you chain up a bunch of tests and they fail, you really want an easy
way to dump up your markup at a specific point in that chain and see
what's what. This module comes to the rescue.

=head1 METHODS

You have all the methods provided by L<Test::Mojo>, plus these:

=head2 C<d>

    $t->d;         # print entire DOM on failure
    $t->d('#foo'); # print a specific element on failure

B<Returns> its invocant.
On failure of previous tests (see L<Mojo::DOM/"success">),
dumps the DOM of the current page to the screen. B<Takes> an optional
selector to be passed to L<Mojo::DOM/"at">, in which case, only
the markup of that element will be dumped.

=head2 C<da>

    $t->da;
    $t->da('#foo');

Same as L</d>, except it always dumps, regardless of whether the previous
test failed or not.

=head1 SEE ALSO

L<Test::Mojo> (L<Test::Mojo/"or"> in particular), L<Mojo::DOM>

=for html <div style="background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/hr.png);height: 18px;"></div>

=head1 REPOSITORY

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-github.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

Fork this module on GitHub:
L<https://github.com/zoffixznet/Test-Mojo-Role-Debug>

=for html  </div></div>

=head1 BUGS

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-bugs.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

To report bugs or request features, please use
L<https://github.com/zoffixznet/Test-Mojo-Role-Debug/issues>

If you can't access GitHub, you can email your request
to C<bug-test-mojo-role-debug at rt.cpan.org>

=for html  </div></div>

=head1 AUTHOR

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-author.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

=for html   <span style="display: inline-block; text-align: center;"> <a href="http://metacpan.org/author/ZOFFIX"> <img src="http://www.gravatar.com/avatar/328e658ab6b08dfb5c106266a4a5d065?d=http%3A%2F%2Fwww.gravatar.com%2Favatar%2F627d83ef9879f31bdabf448e666a32d5" alt="ZOFFIX" style="display: block; margin: 0 3px 5px 0!important; border: 1px solid #666; border-radius: 3px; "> <span style="color: #333; font-weight: bold;">ZOFFIX</span> </a> </span>

=for html  </div></div>

=head1 CONTRIBUTORS

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-contributors.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

=for html   <span style="display: inline-block; text-align: center;"> <a href="http://metacpan.org/author/JBERGER"> <img src="http://www.gravatar.com/avatar/cc767569f5863a7c261991ee5b23f147?d=http%3A%2F%2Fwww.gravatar.com%2Favatar%2F28d0d015d88863cd15e9fd69e0885fc0" alt="JBERGER" style="display: block; margin: 0 3px 5px 0!important; border: 1px solid #666; border-radius: 3px; "> <span style="color: #333; font-weight: bold;">JBERGER</span> </a> </span>

=for html  </div></div>

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut
