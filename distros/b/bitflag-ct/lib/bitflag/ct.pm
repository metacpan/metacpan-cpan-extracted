package bitflag::ct;

use 5.008007;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw ( getmask );
our @EXPORT = qw( );
our $VERSION = 0.01;

no strict 'refs';

my %pkgDefaultHandle;
my ($caller);

    sub inithandle    # constructor
    {
        my $class = shift;
        my $option = takeHASH(shift);
        $option->{sm} = delete $option->{startmask}  if exists $option->{startmask};
        $option->{sm} = 1 unless exists $option->{sm};
        bless { option=>$option, flagmap => {}}, $class;
    }

{
    sub takeHASH
    {
        my $v = shift;
        ref($v) eq 'HASH' ? $v : ref($v) eq 'ARRAY' ? {@$v} : undef;
    }

    sub casealias
    {
        {
            'uc'        => sub {uc $_[0]},
            'ucfirst'   => sub {ucfirst $_[0]},
            'lc'        => sub {lc $_[0]},
        }
    }
}

sub import
{
    my $class = shift;
    $caller = caller; # i.e. = caller[0]
    my $option = takeHASH ($_[0]);

    if ( defined $option )
    {
        shift;
        # for compatibility wrt. "package bitflag"
        if ( $option->{ic} ) { $option->{alias} = 'uc' }
        if ( exists $option->{alias} )
        {
            if (exists casealias->{$option->{alias}} )
            {
                $option->{alias} = casealias->{$option->{alias}}
            }
            elsif (defined $option->{alias})
            {
                die sprintf('$option->{alias}=%s must be a CODE',$option->{alias})
                unless ref($option->{alias}) eq 'CODE';
            }
        }
    }


    *{$caller.'::getmask'} = \&{$class.'::getmask'}
        unless defined *{$caller.'::getmask'};

    my $handle;
    my $handle_isnew; # = 0;

    if ( exists $option->{handle} )
    {
        my $refhandle= delete $option->{handle};
#        die "handle=>$refhandle must be a ref\n" unless ref($refhandle);

        if
        (
            $handle_isnew =
            ref($refhandle)? ref($$refhandle) ne $class : !defined(*{$caller.'::'.$refhandle})
        )
        {
            #  create and call import with handle

            if ( $option->{default} && exists $pkgDefaultHandle{$caller} )
            {
                delete $option->{default};
                $option = {%{$pkgDefaultHandle{$caller}{option}},@$option}
            }

            # create new $handle by constructor
            $handle = $class->inithandle($option);

            if (ref($refhandle))
            {
                # usage case : handle => \$variable_for_handle
                $$refhandle = $handle;
            }
            else
            {
                # usage case : handle => 'symbolname_for_handle'
                *{$caller.'::'.$refhandle} = sub () {$handle};
            }
        }
        else
        {
            # recall import with already created handle

            if (ref($refhandle))
            {
                # usage case : handle => \$variable_for_handle
                $handle = $$refhandle;
            }
            else
            {
                # usage case : handle => 'symbolname_for_handle'
                $handle = &{$caller.'::'.$refhandle};
            }
        }
    }
    else
    {
        if ($handle_isnew = !(exists $pkgDefaultHandle{$caller}))
        {
            $handle = $class->inithandle($option);
            $pkgDefaultHandle{$caller} = $handle;

        }
        else
        {
            $handle = $pkgDefaultHandle{$caller};
        }
    }

    unless ($handle_isnew)
    {
#       @{$handle->{option}}{keys %$option} = values %$option;
#       but as 'sm' is the only key to be considered ..
        if ( exists $option->{sm} )
        {
            $handle->{option}{sm} = $option->{sm};
        }
        $option = $handle->{option};
    }

    return unless @_;
    my $mask = ($_[0] =~ qr{\A\d+\Z}) ? shift : $option->{sm};
    my $alias = $handle->{option}{alias};

    foreach my $flagname (@_)
    {
        if ( exists ${$caller.'::'}{$flagname} )
        {
            my $elsecode = \&{$caller.'::'.$flagname};
            undef *{$caller.'::'.$flagname};
            delete ${$caller.'::'}{$flagname};
            *{$caller.'::'.$flagname} =
            sub
            {
                my ($context) = @_;
                $context==$handle ? $mask : $elsecode->(@_);
            };

#            print "\$mask=$mask\t\$elsecode=$elsecode =run=> ".&$elsecode."\n";
        }
        else
        {
            *{$caller.'::'.$flagname} = sub {$mask};
        }
        $handle->{flagmap}{defined $alias ? $alias->($flagname) : $flagname} = $mask;
        $mask <<= 1
    }

    $handle->{option}{sm} = $mask;
}

    sub getmask
    {
        my $cand = shift;
        my $handle = ref($cand) ? $cand : $pkgDefaultHandle{$cand};
        die 'getmask needs a preceding "use bitflag::ct"' unless defined $handle;
        undef $cand;
        my $option= $handle->{option};
        my $r = 0;
        my $alias= $option->{alias};
        my $nameslist = defined $alias ? [map $alias->($_),@_] : \@_;
        foreach my $v (@$nameslist)
        {
            if ( exists $handle->{flagmap}{$v} )
            {
                $r |= $handle->{flagmap}{$v}
            }
            else
            {
                warn "unknown flagname: $v\n";
            }
        }
        $r
    }

    sub pkghandle
    {
        $pkgDefaultHandle{$_[1]}
    }

1;
__END__

=head1 NAME

bitflag::ct - = bitflag + grouping

=head1 SYNOPSIS

=head3 Group of Flags by handle variable

=over

=item C<package A1;>

    require Exporter;
    EXPPORT_OK = qw( getmask $mc1 $mc2 );
    our ($mc1,$mc2);
    use bitflag::ct {handle=>\$mc1}, qw(I1 I2 I3 ...);
    use bitflag::ct {handle=>\$mc2}, qw(J1 J2 J3 ...);

=item C<package C1;>

    use A1 qw(getmask $mc1 $mc2);
    $u = $mc1->getmask(qw(K3 K5 K11 ...));
    $v = $mc2->getmask(qw(L3 L8 L5 ...));

=back

=head3 Group of Flags by handle constant

=over

=item C<package A2;>

    require Exporter;
    EXPPORT_OK = qw( getmask fgroupG fgroupH );
    use bitflag::ct { handle => 'fgroupG' }, qw(I1 I2 I3 ...);
    use bitflag::ct { handle => 'fgroupH' }, qw(J1 J2 J3 ...);

=item C<package C2;>

    use A2 qw( getmask fgroupG fgroupH );
    $u = fgroupG->getmask(qw(K3 K5 K11 ...));
    $v = fgroupH->getmask(qw(L3 L8 L5 ...));

=back

=head3 Group associated to module name

=over

=item    C<package A3; >

    use bitflag::ct qw(K1 K2 ...);

Series of constants C<K1,K2,K3 ...> now available with values C<1,2,4,..>

    do  something with constants K1, K3|~K4 and the like
    sub f
    {
        $v = getmask A @_
        ...
    }

=item    C<package B3; >

    use bitflag::ct qw(L1 L2 ...);

    sub g
    {
        $w = getmask B @_
        ...
    }

=item C<package C3;>

    use A3;
    use B3;
    A3::f(qw(K3 K5 K11 ...));    # sample choices
    B3::g(qw(L3 L8 L5 ...));

Inside C<A3::f> from C<$v=getmask A3 @_>  the arguments arrive as C<K3|K5|K11>,
Likewise C<B3::g> from C<$w=getmask B3 @_>  as C<L3|L8|L5>.

=back

=head1 DESCRIPTION

Have a look at pragma 'bitflag' before reading this.
If just one group of names for different bitflag are considered in an application
then module 'bitflag' is the slim solution.
Only if different groups of bitflag need either distinct namespaces or individual options
this class is the right solution.

When necessity arise to upgrade from using 'bitflag' to 'bitflag::ct' this can easily be done:
If a second group will be required in the same package, handles must be introduced, one for each group.
This handle can be referred to either by a variable or a constant.
Code-snippets before upgrade look like

    package A;
    use bitflag qw(V1 V2 ...);         (1)     define in package A

    package C;
    A:getmask qw(...);                  (2)     call from package C

upgrading replaces above code lines (1),(2) by

    use bitflag::ct {handle=>\$vhandle} qw(V1 V2 ...); (1)
    $vhandle->getmask qw(...);                          (2)

or by

    use bitflag::ct {handle=>'hc'} qw(V1 V2 ...);      (1)
    hc->getmask qw(...);                                (2)

If the second group is located in another package, say C<B>, the clause
C<use bitflag::ct> can be applied without C<'handle'> in which case the package
names C<A, B> shall replace the handle object in front of its method C<getmask>.
Doing so, a default handle is automatically created for the surrounding package.
When expression C<A-E<gt>gethandle(...)> gets evaluated by the interpreter,
the token C<A> first will be substituted by the default handle provided in
package C<A>.

=head1 OPTIONS

As with L<bitflag> a hash may be given as first argument in order to specify options.
Option names C<sm> and C<ic> are described in manpage L<bitflag>, the new option C<handle>
was presented now. A further new option is

    alias => \&reducer

Similar to 'ic' this allow using alias definitions of the flagnames when used
as arguments of C<getmask>. That is, if a bitflag name, say 'CHECK_X', is introduced with

    use bitflag::ct ... CHECK_X ...

a string C<$cx> is accepted as C<CHECK_X>, if C<reducer($cx)=reducer('CHECK_X')>.
The string representation of the builtin functions C<uc,lc,ucfirst> can be used
as reducers in place of C<sub {uc $_[0]}, ...>.

=head1 AUTHOR

Josef SchE<ouml>nbrunner E<lt>j.schoenbrunner@schule.atE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008  by Josef SchE<ouml>nbrunner
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut