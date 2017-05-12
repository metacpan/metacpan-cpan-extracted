package here;
    use warnings;
    use strict;
    use Filter::Util::Call qw(filter_add filter_del);
        # fear not a filter that filters not not a filter be
    our $DEBUG;

    sub import {
        shift;
        if (@_) {
            my $code = join ';' => map {(my $x = $_) =~ s/;\s*$//; $x} @_;
            my (undef, $file, $line) = caller;
            filter_add sub {
                if ($DEBUG) {
                    (my $msg = $code) =~ s/\s+/ /g;
                    warn "use here: $msg at $file line $line.\n";
                }
                $_ = "# line $line\n$code;\n# line $line\n\n";
                filter_del;
                1
            }
        }
    }

    sub croak {
        s/\s+/ /g for my $msg = "@_";
        my $i;
        1 while (caller ++$i) =~ /^here(::.+)?$/;
        my (undef, $file, $line) = caller $i;
        die "$msg at $file line $line.\n"
    }

    my ($key, %data);
    sub store {
        $data{++$key} = $_[0];
        "here::fetch($key)"
    }

    sub fetch {
        if (exists $data{$_[0]}) {
            delete $data{$_[0]}
        }
        else {croak "here::fetch: invalid key '$_[0]'"}
    }

    our $VERSION = '0.03';


=head1 NAME

here - insert generated source here

=head1 VERSION

version 0.03

=head1 SYNOPSIS

this module replaces a call to C< use here LIST; > with the contents of
C< LIST > at compile time.  perl then compiles C< LIST > and the remaining code.
there is B<not> an implicit block around C< LIST >

an example is probably best:

    my $x;
    use here 'my $y';
    my $z;

is exactly equivalent to:

    my $x;
    my $y;
    my $z;

the important thing here is that C< $y > is still in scope, which would not be
the case with a runtime C< eval >:

    my $x;
    eval 'my $y';
    my $z; # $y is not in scope here!

=head1 EXPORT

this module does not export anything, and must always be invoked at compile time
as:

    use here LIST;

it is intended to be used with a transformation function to allow new syntactic
sugar:

    sub my_0 {map {"my \$$_ = 0"} @_}

    use here my_0 qw(x y z);

which results in perl compiling:

    my $x = 0; my $y = 0; my $z = 0;

note the inserted semicolons (between every element of C<LIST> and at the end).

you can utilize the C< here::install > mechanism to make the code even shorter:

    use here::install my_0 => sub {map {"my \$$_ = 0"} @_};

    use my_0 qw(x y z);

C< here::install > has dynamic lexical scope if L<B::Hooks::EndOfScope> is
available. otherwise it is global and you can call:

    no here::install 'my_0';

when you are done with the macro if you want to clean up.

=head1 SEE ALSO

see L<here::install> and L<here::declare> for additional examples.

see L<here::debug> to view what C<here> is doing.

=head1 AUTHOR

Eric Strom, C<< <asg at cpan.org> >>

=head1 BUGS

code following a C< use here ...; > line must be placed on a new line if that
code needs to be in the scope of the C< use here >

    $first->()
    use here '$second->()'; # comments are fine
    $third->();

    $first->();
    use here '$third->()'; $second->(); # but this is out of order
    $fourth->();

    use here 'my $x = 1'; # $x not in scope
    # $x in scope

as far as i can tell, this is a limitation of perl /C< Filter::Util::Call > and
not of this module.  patches welcome if this is not the case.

please don't fear that i've mentioned that this module uses
L<Filter::Util::Call>, since this module filters naught.  all it does is insert
C< LIST > at the top of perl's queue of lines to compile.  the filter is removed
at the same time, never to be called again. so fear not a filter that filters
not not a filter be.

write C< use here::debug; > before a C< use here LIST; > line to carp the
contents of C< LIST > when it is inserted into the source.

please report any bugs or feature requests to C<bug-here at rt.cpan.org>, or
through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=here>. I will be notified, and
then you'll automatically be notified of progress on your bug as I make changes.

=head1 LICENSE AND COPYRIGHT

copyright 2011 Eric Strom.

this program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1
