package bitflag;

use 5.008007;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw ( getmask );
our @EXPORT = qw( );
our $VERSION = 0.01;

no strict 'refs';

    my ($caller,%FLAGMAP);
    my ($igcase,$mask) = (0,1);

sub import
{
    my $class = shift;
    return unless @_;
    $caller = caller; # i.e. = caller[0]

#    print "bitflag::import from caller $caller\n";

    my ($head) = @_;

    # begin optiomally assign $igcase,$mask using an options hash as first argument
    if ( ref($head) eq 'HASH' )
    {
        $igcase = $head->{ic} if exists $head->{ic};
        $head->{sm} = delete $head->{startmask}  if exists $head->{startmask};
        $mask = $head->{sm} if exists $head->{sm};
        shift;
    }
    else
    #   or only $mask simply with a numeric first argument
    {
        if ($head =~ qr{\A\d+\Z})
        {
            $mask = shift  ;
        }
    }
    # end   optiomally assign ...

    foreach my $flagname (@_)
    {
        *{$caller.'::'.$flagname} = sub () {$mask};
        my $flagalias = $igcase ? lc($flagname) : $flagname;
        $FLAGMAP{$flagalias} = $mask;
        $mask <<= 1
    }

#    $class->export_to_level(2,$class,'getmask');
    *{$caller.'::getmask'} =
    sub
    {
        my $r = 0;
        foreach my $v (@_)
        {
            my $vkey = $igcase ? lc($v) : $v;
            if ( exists $FLAGMAP{$vkey} )
            {
                $r |= $FLAGMAP{$vkey};
            }
            else
            {
                warn "unknown flagname: $v\n";
            }
        }
        $r
    }
    unless defined *{$caller.'::getmask'};
}


1;
__END__

=head1 NAME

bitflag - Simplify export of bitflag names

=head1 SYNOPSIS

=over

=item    C<package SomeModule;>

    use bitflag qw(V1 V2 ...);

Series of constants C<V1,V2,V3 ...> now available with values C<1,2,4,..>

    do  something with constants V1, V3|~V4 and the like ;
    sub anyFunc
    {
        $v = getmask @_;
        ...
    }

=item    C<package AnotherModule;>

    use SomeModule;
    SomeModule::anyFunc(qw(V3 V5 V11 ...))

Inside C<SomeModule::anyFunc> with assignment C<$v=getmask(@_)>  these arguments arrive as C<V3|V5|V11>

=back

=head1 DESCRIPTION

=head3 Core Features

C<use bitflag qw(V1 V2 ...)> defines a series of constants which denote different bitflag in
the calling module, say C<package SomeModule>.
The constants are used as ordinary names, usually making up boolean expressions by bitwise
operation-combinations.
If  C<AnotherModule> calls C<SomeModule>  and refers to the flagnames, export of the names would be demanded.
Yet unlike in C<SomeModule> the binary 'or' will be the only opreation needed to combine the flags.
E.g., if C<alfa, beta, gamma, delta, fi> are names for C<1,2,4,8,16>, a choice term C<beta|delta|fi>
could be used in C<AnotherModule>.
Pragma C<bitflag> makes the export of the flagnames dispensable, as it represents the choice term as
S<C<getmask(qw(beta delta fi))>>.
C<getmask()> converts a list of strings containing names of flags into the boolean union of those flags.
Thus the export of a lot of symbols is reduced to the export of a sole subname,
C<getmask()>, which is defined in C<package bitflag> and exported by default to C<SomeModule>.
Coupling of packages is diminished this way.

=head3 Special Features

Multiple uses of "C<bitflag>" may occur in a package.
C<use bitflag @thislist> and C<use bitflag @thatlist>,
regardless whether adjacent or separated in code,
do the same as C<use bitflag @thislist,@thatlist>.
However, a second statement could also determine values of a separate range.
If, in contrast to above specifications, the first argument of C<use bitflag> is a hash and not a string,
it represents a collection of options that can

=over 4

=item 1.

override the value of the starting flag -- apply option C<sm=E<gt>$m>

=item 2.

allow deviation of the case of characters in arguments of C<getmask> -- with option C<ic=E<gt>1>.

=back

One can write, e.g., C<use bitflag {sm=E<gt>128, ic=E<gt>1}...>

Furthermore, C<use bitflag {sm=E<gt>$m}...> can be abbreviated to C<use bitflag $m...>.

=head3 Multiple uses

By option C<sm=E<gt>$number> one can define another name for a value already
assigned by a prior C<use bitflag>.

Furthermore C<use bitflag> could be called from different packages in one
application run. If so, the module loaded later shall continue counting
where the earlier module stopped, i.e. if C<ModuleA::LASTFLAG> is 256, calling
C<use bitflag FIRSTFLAG, ...> in C<ModuleB> makes C<ModuleB::FIRSTFLAG> being 512.
If C<ModuleB> use other names independently to C<ModuleA> it makes sense to restart
with value 1 by using C<{sm=E<gt>1}> as first parameter.

=head1 AUTHOR

Josef SchE<ouml>nbrunner E<lt>j.schoenbrunner@schule.atE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008  by Josef SchE<ouml>nbrunner
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut