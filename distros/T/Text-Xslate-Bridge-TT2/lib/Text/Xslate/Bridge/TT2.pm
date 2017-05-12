package Text::Xslate::Bridge::TT2;

use 5.008_001;
use strict;
use warnings;

our $VERSION = '1.0003';

use parent qw(Text::Xslate::Bridge);
use Text::Xslate ();

use Template::VMethods ();
use Template::Filters  ();
use Carp ();

my $ThisClass    = __PACKAGE__;
my $DummyContext = bless {}, $ThisClass . '::DummyContext';

my %Function = %{$Template::Filters::FILTERS};

delete $Function{html}; # builtin
delete $Function{uri} if $Text::Xslate::VERSION >= 0.1052; # builtin

while(my($name, $filter) = each %Function) {
    if(ref($filter) eq 'ARRAY') {
        my($body, $is_dynamic) = @{$filter};

        if($is_dynamic) {
            $Function{$name} = sub {
                return $body->($DummyContext, @_);
            };
        }
    }
}

__PACKAGE__->bridge(
    scalar   => $Template::VMethods::TEXT_VMETHODS,
    array    => $Template::VMethods::LIST_VMETHODS,
    hash     => $Template::VMethods::HASH_VMETHODS,

    function => \%Function,
);

package
    Text::Xslate::Bridge::TT2::DummyContext;

sub AUTOLOAD {
    Carp::croak("Template-Toolkit specific features are not supported in $ThisClass");
}

sub DESTROY { }
1;
__END__

=for stopwords parens

=head1 NAME

Text::Xslate::Bridge::TT2 - Template-Toolkit virtual methods and filters for Xslate (deprecated)

=head1 VERSION

This document describes Text::Xslate::Bridge::TT2 version 1.0003.

=head1 SYNOPSIS

    use Text::Xslate;

    my $xslate = Text::Xslate->new(
        module => ['Text::Xslate::Bridge::TT2'],
    );

    print $xslate->render_string('<: "foo".length() :>'); # => 3

=head1 DESCRIPTION

This is B<< a demo module to extend Text::Xslate::Brige >>. Use L<Text::Xslate::Bridge::TT2Like>, which is a stand alone utilities compatible with TT2.

=head1 CAVEAT

=head2 Limitation of dynamic filters

All the dynamic filters require parens (i.e. to "call" them first),
even if you want to omit their arguments.

    [% FILTER repeat   # doesn't work! %]
    [% FILTER repeat() # works. %]

=head2 Unsupported features

Filters that require Template-Toolkit context object are not supported,
which include C<eval>, C<evaltt>, C<perl>, C<evalperl> and C<redirect>.

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<Text::Xslate>

L<Template>

L<Template::Manual::VMethods>

L<Template::Manual::Filters>

=head1 AUTHOR

Fuji, Goro (gfx) E<lt>gfuji@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010-2013, Fuji, Goro (gfx). All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See L<perlartistic> for details.

=cut
