package Test::NoOverride;
use strict;
use warnings;
use Module::Functions;
use Test::More;

our $VERSION = '0.04';

sub import {
    my $class = shift;

    my $caller = caller;
    no strict 'refs'; ## no critic
    for my $func (qw/ no_override /) {
        *{"${caller}::$func"} = \&{ __PACKAGE__. "::_$func" };
    }
}

sub _no_override {
    my ($klass, %opt) = @_;

    my %exclude;
    if (exists $opt{exclude}) {
        $exclude{$_} = 1 for @{$opt{exclude}};
    }
    my %exclude_overridden;
    if (exists $opt{exclude_overridden}) {
        $exclude_overridden{$_} = 1 for @{$opt{exclude_overridden}};
    }
    unless ($opt{new}) {
        $exclude{new} = 1; # default ignore 'new' method
    }

    _load_class($klass);
    my @functions = _get_functions($klass);

    my @methods;
    _isa_list(\@methods, $klass);

    my $fail = 0;
    for my $func (@functions) {
        for my $m (@methods) {
            my ($class, $method) = %{$m};
            if ($func eq $method) {
                if (!$exclude{$func} && !$exclude_overridden{"$class\::$method"} ) {
                    fail("[$klass\::$func] overrides [$class\::$method]");
                    $fail++;
                }
            }
        }
    }

    ok(1, "No Override: $klass") unless $fail;
}

sub _load_class {
    my $class = shift;

    my $class_path = $class;
    $class_path =~ s!::!/!g;
    require "$class_path\.pm"; ## no critic
    $class->import;
}

sub _isa_list {
    my ($methods, @klass_list) = @_;

    my @parents;
    for my $klass (@klass_list) {
        {
            no strict 'refs'; ## no critic
            push @parents, @{"$klass\::ISA"};
        }
        for my $parent_klass (@parents) {
            my @functions = _get_functions($parent_klass);
            for my $func (@functions) {
                push @{$methods}, { $parent_klass => $func };
            }
        }
    }

    if ( scalar @parents ) {
        _isa_list($methods, @parents);
    }

}

sub _get_functions {
    my $package = shift;

    my @functions = get_public_functions($package);

    {
        no strict 'refs'; ## no critic
        my %class = %{"${package}::"};
        while (my ($k, $v) = each %class) {
            push @functions, $k if $k =~ /^_.+/;
        }
    }

    return @functions;
}

1;

__END__

=head1 NAME

Test::NoOverride - stop accidentally overriding


=head1 SYNOPSIS

    use Test::NoOverride;

    no_override('Some::Class');

    no_override(
        'Some::Class',
        exclude => [qw/ method /], # methods which you override specifically.
    );

    no_override(
        'Some::Class',
        exclude_overridden => [qw/ Foo::Bar::method /], # ignore to be overridden.
    );


=head1 DESCRIPTION

No more accidentally overriding.

Note that private method (like '_foo') and (import|BEGIN|UNITCHECK|CHECK|INIT|END) methods are ignored (means that these are not checked). Moreover, C<new> method is ignored by default. If you would like to check overriding 'new' method, then you should set the C<new> param like below.

    no_override(
        'Some::Class',
        new => 1, # The 'new' method will be checked.
    );


=head1 REPOSITORY

Test::NoOverride is hosted on github: L<http://github.com/bayashi/Test-NoOverride>

Welcome your patches and issues :D


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

L<Module::Functions>

=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
