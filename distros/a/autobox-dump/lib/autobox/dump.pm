package autobox::dump;
# vi: ht=4 sw=4 ts=4 et :

use warnings;
use strict;

use base "autobox";

our $VERSION = '20090426.1746';

our @options = qw/Indent Terse Useqq Sortkeys Deparse/;

sub options {
    #let them call it autobox::dump::options or autobox::dump->options
    shift @_ if $_[0] eq 'autobox::dump';
    @options = @_;
}

sub import {
    my $class = shift;

    my $dumper = "autobox::dump::inner";

    $class->SUPER::import(
        SCALAR => $dumper,
        ARRAY  => $dumper,
        HASH   => $dumper,
        CODE   => $dumper,
    );
}

{
    package autobox::dump::inner;

    sub perl {
        require Data::Dumper;
        #use Test::More;

        my $self    = shift;
        my @options = @_ ? @_ : @autobox::dump::options;

        my $dumper = Data::Dumper->new([$self]);

        for my $option (@options) {
            my ($opt, @opt_args) = ref $option ? @$option : ($option, 1);
                
            $dumper->$opt(@opt_args) if $dumper->can($opt);
        }

        return $dumper->Dump;
    }
}


=head1 NAME

autobox::dump - human/perl readable strings from the results of an EXPR

=head1 VERSION

Version 20090426.1746

=head1 SYNOPSIS

The autobox::dump pragma adds, via the autobox pragma, a method to 
normal expression (such as scalars, arrays, hashes, math, literals, etc.)
that produces a human/perl readable representation of the value of that
expression. 


    use autobox::dump;

    my $foo = "foo";
    print $foo->perl;   # "foo";

    print +(5*6)->perl; # 30;

    my @a = (1..3);

    print @a->perl;
    # [
    #  1,
    #  2,
    #  3
    # ];

    print {a=>1, b=>2}->perl;
    # {
    #  "a" => 1,
    #  "b" => 2
    # };
    
    sub func {
        my ($x, $y) = @_;
        return $x + $y;
    }

    my $func = \&func;
    print $func->perl;
    #sub {
    #    BEGIN {
    #        $^H{'autobox_scope'} = q(154456408);
    #        $^H{'autobox'} = q(HASH(0x93a3e00));
    #        $^H{'autobox_leave'} = q(Scope::Guard=ARRAY(0x9435078));
    #    }
    #    my($x, $y) = @_;
    #    return $x + $y;
    #}
    
    You can set Data::Dumper options by passing either arrayrefs of option
    and value pairs or just keys (in which case the option will be set to
    1).  The default options are C<qw/Indent Terse Useqq Sortkeys Deparse/>.

    print ["a", 0, 1]->perl([Indent => 3], [Varname => "a"], qw/Useqq/);
    #$a1 = [
    #        #0
    #        "a",
    #        #1
    #        0,
    #        #2
    #        1
    #      ];

    You can also call the class method ->options to set a different default.

    #set Indent to 0, but leave the rest of the options
    autobox::dump->options([Indent => 0], qw/Terse Useqq Sortkeys Deparse/);

    print ["a", 0, 1]->perl; #["a",0,1]

=head1 AUTHOR

Chas. J Owens IV, C<< <chas.owens at gmail.com> >>

=head1 BUGS

Has all the issues L<autobox> has.

Has all the issues L<Data::Dumper> has.

This pragma errs on the side of human readable to the detriment of
Perl readable.  In particular it uses the terse and deparse options
of Data::Dumper by default.  These options may create code that cannot 
be eval'ed.  For best eval results, set options to C<qw/Purity/>.
Note, this turns off coderef dumping.

Please report any bugs or feature requests to 
http://github.com/cowens/autobox-dump/issues

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc autobox::dump

=head1 ACKNOWLEDGEMENTS

Michael Schwern for starting the perl5i pragma which prompted me to add
a feature I wanted to autobox.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Chas. J Owens IV, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of autobox::dump
