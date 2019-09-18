package vars::i;
use 5.006001;

our $VERSION = '2.000000';  # Prerelease leading to v2.0.0

use strict qw(vars subs);
use warnings;

# Turn a scalar, arrayref, or hashref into a list
sub _unpack {
    if( ref $_[0] eq 'ARRAY' ){
        return @{$_[0]};
    }
    elsif( ref $_[0] eq 'HASH' ){
        return %{$_[0]};
    }
    else {
        return ($_[0]);
    }
} #_unpack

sub import {
    return if @_ < 2;
    my( $pack, $first_var, @value ) = @_;
    my $callpack = caller;

    my %definitions;

    if( not @value ){
        if( ref $first_var eq 'ARRAY' ){  # E.g., use vars [ foo=>, bar=>... ];
            %definitions = @$first_var;
        }
        elsif( ref $first_var eq 'HASH' ){  # E.g., use vars { foo=>, bar=>... };
            %definitions = %$first_var;
        }
        else {
            return;     # No value given --- no-op; not an error.
        }
    }
    elsif(@value == 1) {        # E.g., use vars foo => <str/hashref/arrayref>
        %definitions = ( $first_var => $value[0] );
    }
    else {
        %definitions = ( $first_var => [@value] );
    }

    #require Data::Dumper;   # For debugging
    #print Data::Dumper->Dump([\%definitions], ['definitions']);

    while( my ($var, $val) = each %definitions ){

        if( my( $ch, $sym ) = $var =~ /^([-\$\@\%\*\&])(.+)$/ ){
            if( $ch eq '-' ){   # An option
                require Carp;
                Carp::croak('vars::i does not yet support any options!');
            }
            elsif( $sym !~ /^(\w+(::|'))+\w+$/ && $sym =~ /\W|(^\d+$)/ ){
                #    ^^ Skip fully-qualified names  ^^ Check special names

                # A variable name we can't or won't handle
                require Carp;

                if( $sym =~ /^\w+[[{].*[]}]$/ ){
                    Carp::croak("Can't declare individual elements of hash or array");
                }
                elsif( $sym =~ /^(\d+|\W|\^[\[\]A-Z\^_\?]|\{\^[a-zA-Z0-9]+\})$/ ){
                    Carp::croak("Refusing to initialize special variable $ch$sym");
                }
                else {
                    Carp::croak("I can't recognize $ch$sym as a variable name");
                }
            }

            $sym = "${callpack}::$sym" unless $sym =~ /::/;

            if( $ch eq '$' ){
                *{$sym} = \$$sym;
                ${$sym} = $val;
            }
            elsif( $ch eq '@' ){
                *{$sym} = \@$sym;
                @{$sym} = _unpack $val;
            }
            elsif( $ch eq '%' ){
                *{$sym} = \%$sym;
                %{$sym} = _unpack $val;
            }
            elsif( $ch eq '*' ){
                *{$sym} = \*$sym;
                (*{$sym}) = $val;
            }
            else {   # $ch eq '&'; guaranteed by the regex above.
                my ($param) = $val;
                if(ref $param) {
                    # NOTE: for now, permit any ref, since we can't determine
                    # refs overload &{}.  If necessary, we can later use
                    # Scalar::Util 1.25+'s blessed(), and allow CODE refs
                    # or blessed refs.
                    *{$sym} = $param;
                }
                else {
                    require Carp;
                    Carp::croak("Can't assign non-reference " .
                        (defined($param) ? $param : '<undef>') .
                        " to $sym");
                }
            }
            # There is no else, because the regex above guarantees
            # that $ch has one of the values we tested.

        }
        else {    # Name didn't match the regex above
            require Carp;
            Carp::croak("'$var' is not a valid variable or option name");
        }
    }
} #import()

1;
__END__

=head1 NAME

vars::i - Perl pragma to declare and simultaneously initialize global variables.

=head1 SYNOPSIS

    use Data::Dumper;
    $Data::Dumper::Deparse = 1;

    use vars::i '$VERSION' => 3.44;
    use vars::i '@BORG' => 6 .. 6;
    use vars::i '%BORD' => 1 .. 10;
    use vars::i '&VERSION' => sub(){rand 20};
    use vars::i '*SOUTH' => *STDOUT;

    BEGIN {
        print SOUTH Dumper [
            $VERSION, \@BORG, \%BORD, \&VERSION
        ];
    }

    use vars::i [ # has the same effect as the 5 use statements above
        '$VERSION' => 3.66,
        '@BORG' => [6 .. 6],
        '%BORD' => {1 .. 10},
        '&VERSION' => sub(){rand 20},
        '*SOUTH' => *STDOUT,
    ];

    print SOUTH Dumper [ $VERSION, \@BORG, \%BORD, \&VERSION ];

=head1 DESCRIPTION

For whatever reason, I once had to write something like

    BEGIN {
        use vars '$VERSION';
        $VERSION = 3;
    }

or

    our $VERSION;
    BEGIN { $VERSION = 3; }

and I really didn't like typing that much.  With this package, I can say:

    use vars::i '$VERSION' => 3;

and get the same effect.

Also, I like being able to say

    use vars::i '$VERSION' => sprintf("%d.%02d", q$Revision: 1.3 $ =~ /: (\d+)\.(\d+)/);

    use vars::i [
     '$VERSION' => sprintf("%d.%02d", q$Revision: 1.3 $ =~ /: (\d+)\.(\d+)/),
     '$REVISION'=> '$Id: GENERIC.pm,v 1.3 2002/06/02 11:12:38 _ Exp $',
    ];

Like with C<use vars;>, there is no need to fully qualify the variable name.
However, you may if you wish.

=head1 NOTES

=over

=item *

Specifying a variable but not a value will succeed silently, and will B<not>
create the variable.  E.g., C<use vars::i '$foo';> is a no-op.

Now, you might expect that C<< use vars::i '$foo'; >> would behave the same
way as C<< use vars '$foo'; >>.  That would not be an unreasonable expectation.
However, C<< use vars::i qw($foo $bar); >> has a very different
effect than does C<< use vars qw($foo $bar); >>!  In order to avoid
subtle errors in the two-parameter case, C<vars::i> also rejects the
one-parameter case.

=item *

Trying to create a special variable is fatal.  E.g., C<use vars::i '$@', 1;>
will die at compile time.

=item *

The sigil is taken into account (context sensitivity!)  So:

    use vars::i '$foo' => [1,2,3];  # now $foo is an arrayref
    use vars::i '@bar' => [1,2,3];  # now @bar is a three-element list

=back

=head1 SEE ALSO

See L<vars>, L<perldoc/"our">, L<perlmodlib/Pragmatic Modules>.

=head1 VERSIONING

Since version 1.900000, this module is numbered using
L<Semantic Versioning 2.0.0|https://semver.org>,
packed in the compatibility format of C<< vX.Y.Z -> X.00Y00Z >>.

This version supports Perl 5.6.1+.  If you are running an earlier Perl:

=over

=item Perl 5.6:

Use version 1.10 of this module
(L<CXW/vars-i-1.10|https://metacpan.org/pod/release/CXW/vars-i-1.10/lib/vars/i.pm>).

=item Pre-5.6:

Use version 1.01 of this module
(L<PODMASTER/vars-i-1.01|https://metacpan.org/pod/release/PODMASTER/vars-i-1.01/lib/vars/i.pm>).

=back

=head1 DEVELOPMENT

This module uses L<Minilla> for release management.  When developing, you
can use normal C<prove -l> for testing based on the files in C<lib/>.  Before
submitting a pull request, please:

=over

=item *

make sure all tests pass under C<minil test>

=item *

add brief descriptions to the C<Changes> file, under the C<{{$NEXT}}> line.

=item *

update the C<.mailmap> file to list your PAUSE user ID if you have one, and
if your git commits are not under your C<@cpan.org> email.  That way you will
be properly listed as a contributor in MetaCPAN.

=back

=head1 AUTHORS

D.H. <podmaster@cpan.org>

Christopher White <cxw@cpan.org>

=head2 Thanks

Thanks to everyone who has worked on L<vars>, which served as the basis for
this module.

=head1 SUPPORT

Please report any bugs at L<https://github.com/cxw42/Perl-vars-i/issues>.

You can also see the old bugtracker at
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=vars-i> for older bugs.

=head1 LICENSE

Copyright (c) 2003--2019 by D.H. aka PodMaster, and contributors.
All rights reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
