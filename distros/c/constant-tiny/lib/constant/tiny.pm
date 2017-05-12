package constant::tiny;
return 1 if $INC{"constant.pm"};
$INC{"constant.pm"} = $INC{+__FILE__};
$VERSION = "1.02";

package # hide from PAUSE
        constant;
use 5.010;
use strict;


$constant::VERSION = $constant::tiny::VERSION;

my %forbidden = map +($_, 1), qw<
    BEGIN INIT CHECK END DESTROY AUTOLOAD UNITCHECK
    STDIN STDOUT STDERR ARGV ARGVOUT ENV INC SIG
>;

my $normal_constant_name = qr/^_?[A-Za-z0-9][A-Za-z0-9_]+\z/;


#
# import()
# ------
# import symbols into user's namespace
#
# What we actually do is define a function in the caller's namespace
# which returns the value. The function we create will normally
# be inlined as a constant, thereby avoiding further sub calling 
# overhead.
#
*import = sub {
    my $class = shift;
    return unless @_;  # ignore "use constant;"

    if (not defined $_[0]) {
        require Carp;
        Carp::croak("Can't use undef as constant name");
    }

    my $multiple = ref $_[0];
    if ($multiple and $multiple ne "HASH") {
        require Carp;
        Carp::croak("Invalid reference type '$multiple'");
    }

    my $constants = $multiple ? shift : { shift() => undef };
    my $flush_mro;
    my $pkg = caller();
    my $symtab;
    { no strict 'refs'; $symtab = \%{$pkg . '::'} }

    foreach my $name (keys %$constants) {
        # Normal constant name
        if ($name !~ $normal_constant_name or $forbidden{$name}) {
            require Carp;
            Carp::croak("Invalid name '$name'");
        }

        no strict 'refs';
        my $full_name = "${pkg}::$name";

        if ($multiple || @_ == 1) {
            my $scalar = $multiple ? $constants->{$name} : $_[0];

            if ($symtab && !exists $symtab->{$name}) {
                Internals::SvREADONLY($scalar, 1);
                $symtab->{$name} = \$scalar;
                ++$flush_mro;
            } else {
                my $scalar = $scalar;
                *$full_name = sub () { $scalar };
            }
        } elsif (@_) {
            my @list = @_;
            *$full_name = sub () { @list };
        } else {
            *$full_name = sub () { };
        }
    }

    mro::method_changed_in($pkg) if $flush_mro;
};


q< IN CONSTANT TIME >

__END__

=head1 NAME

constant::tiny - Perl pragma to declare constants

=head1 SYNOPSIS

    use constant::tiny;
    use constant PI    => 4 * atan2(1, 1);
    use constant DEBUG => 0;

    print "Pi equals ", PI, "...\n" if DEBUG;


=head1 DESCRIPTION

This module is a lightweight version of the Perl standard module
C<constant.pm>. Here are the keys differences:

=over

=item *

only works on Perl 5.10+ in order to simplify a good part of the code

=item *

doesn't support Unicode names; please use the standard C<constant.pm>
module if you need to create constants with Unicode names

=item *

stricter rules about valid names, only allow names with alphanums
(C<[a-zA-Z0-9]> and underscore (C<_>), allowing one optional leading
underscore

=back

In order to simplify its usage, C<constant:tiny> uses the normal
C<constant> API. The main advatange is that switching your code
to C<constant::tiny> means simply adding it before the first
C<use constant>. The disadvantage is that, obviously, both modules
can't be used at the same time. If the normal C<constant> was
loaded before C<constant::tiny>, the latter won't do anything,
letting the normal C<constant> do the work.

Other than this, the usage is (nearly) exactly the same as with the
standard C<constant> module. For more details, please read L<constant>.


=head2 Rationale

The original reason to write this module was that, starting with
version 1.24, C<constant> always loaded F<utf8_heavy.pl>, which
consumes some memory. Usually, this is not problematic, but in
some particular cases (embedded Perl, frequently forked programs
I<E<agrave> la> CGI), the increased memory cost can become a concern.

Therefore, this module was written as a alternative solution,
with no support for Unicode names, so that programs working in
memory constrained environments could have a better control.

Funnily enough, the day C<constant::tiny> was released on CPAN
(the code had been written two months earlier as a proof of
concept), Brad Gilbert proposed a patch for C<constant> in order
to delay loading F<utf8_heavy.pl> until necessary.

Therefore C<constant::tiny> is less useful (which is good news),
but can still address specific needs, if you want to restrict
constant names to alphanums only.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc constant::tiny

You can also look for information at:

=over

=item * Search CPAN

L<http://search.cpan.org/dist/constant-tiny/>

=item * Meta CPAN

L<https://metacpan.org/module/constant::tiny>

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/Public/Dist/Display.html?Name=constant-tiny>.

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/constant-tiny>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/constant-tiny>

=back


=head1 BUGS

Please report any bugs or feature requests to
C<contant-tiny at rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=constant-tiny>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.


=head1 ACKNOWLEDGEMENTS

This module is heavily based on C<constant.pm>, originaly written
by Tom Phoenix, Casey West, Nicholas Clark, Zefram and many other
folks from the Perl 5 Porters.


=head1 AUTHOR

SE<eacute>bastien Aperghis-Tramoni C<< <sebastien at aperghis.net> >>


=head1 LICENSE

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.

=cut

