package here::install;
    use warnings;
    use strict;
    use lib '..';
    use here;

    sub croak {here::croak "here::install: @_"}

    my %installed;
    sub import {
        shift;
        @_ % 2 and croak 'even length list expected';
        my @pseudo;
        while (@_) {
            my ($name, $transform) = splice @_, 0, 2;

            $name =~ /^(?:\w+|(?<!:)::(?!:))+$/ or croak "bad package name '$name'";
            eval {\&$transform}                 or croak "in $name => not a subroutine '$transform'";

            (my $pkg = "$name.pm") =~ s!::!/!g;
            $INC{$pkg}++;
            $installed{$name} = $pkg;
            push @pseudo, $name;

            no strict 'refs';
            defined &{$name.'::import'} and croak "package '$name' not empty";
            *{$name.'::import'} = sub {
                use strict;
                shift;
                @_ = ('here', &$transform);
                goto &here::import;
            }
        }
        eval {
            require B::Hooks::EndOfScope;
            B::Hooks::EndOfScope::on_scope_end(sub {
                here::install->unimport(@pseudo)
            });
        1} or warnings::warnif all =>
            "B::Hooks::EndOfScope not available, here::install will not have lexical scope\n"
    }

    sub unimport {
        shift;
        while (@_) {
            my $name = shift;
            if (my $pkg = $installed{$name}) {
                delete $INC{$pkg};
                no strict 'refs';
                delete ${$name.'::'}{'import'};
            }
            else {croak "did not install '$name'"}
        }
    }


=head1 NAME

here::install - easily install compile time transforms

=head1 SYNOPSIS

    use here::install 'my::lvalue' => sub {
        map "my \$$_; sub $_ ():lvalue {\$$_}" => @_
    };

    use my::lvalue qw(foo bar); # my $foo; sub foo ():lvalue {$foo} my $bar; ...

    foo = 3;
    say foo;  # 3
    say $foo; # 3

    bar = 4;
    say bar++; # 4
    say $bar;  # 5

=head2 cleanup

=over 4

you can remove the pseudo-modules manually:

    no here::install 'my::lvalue';

or let the declaration fall out of scope if L<B::Hooks::EndOfScope> is installed:

    {
        use here::install ...;
        use ...; # works
    }
    use ...; # error

=back

=head1 SEE ALSO

C< here::install > is a wrapper around L<here>.

see L<here::declare> for additional examples.

=head1 AUTHOR

Eric Strom, C<< <asg at cpan.org> >>

=head1 BUGS

please report any bugs or feature requests to C<bug-here at rt.cpan.org>, or
through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=here>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 LICENSE AND COPYRIGHT

copyright 2011 Eric Strom.

this program is free software; you can redistribute it and/or modify it under
the terms of either: the GNU General Public License as published by the Free
Software Foundation; or the Artistic License.

see http://dev.perl.org/licenses/ for more information.

=cut

1
