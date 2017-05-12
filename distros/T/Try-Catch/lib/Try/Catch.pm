package Try::Catch;
use strict;
use warnings;
use Carp;
$Carp::Internal{+__PACKAGE__}++;
use base 'Exporter';
our @EXPORT = our @EXPORT_OK = qw(try catch finally);
our $VERSION = '1.1.0';

sub _default_catch {
    croak $_[0];
}

sub try(&;@) {
    my $wantarray =  wantarray;
    my $try       = shift;
    my $caller    = pop;
    my $finally   = pop;
    my $catch     = pop;

    if (!$caller || $caller ne __PACKAGE__){
        croak "syntax error after try block \n" .
                "usage : \n" .
                "try { ... } catch { ... }; \n" .
                "try { ... } finally { ... }; \n" .
                "try { ... } catch { ... } finally { ... }; ";
    }

    #sane behaviour is to throw an error
    #if there is no catch block
    if (!$catch){
        $catch = \&_default_catch;
    }

    my @ret;
    my $prev_error = $@;
    my $fail = not eval {
        $@ = $prev_error;
        if (!defined $wantarray) {
            $try->();
        } elsif (!$wantarray) {
            $ret[0] = $try->();
        } else {
            @ret = $try->();
        }
        return 1;
    };

    my $error = $@;

    if ($fail) {
        my $ret = not eval {
            $@ = $prev_error;
            for ($error) {
                if (!defined $wantarray) {
                    $catch->($error);
                } elsif (!$wantarray) {
                    $ret[0] = $catch->($error);
                } else {
                    @ret = $catch->($error);
                }
                last; ## seems to boost speed by 7%
            }
            return 1;
        };

        if ($ret){
            my $catch_error = $@;
            if ($finally) {
                $@ = $prev_error;
                $finally->($error);
            }
            croak $catch_error;
        }
    }

    if ($finally) {
        $@ = $prev_error;
        $finally->( $fail ? $error : () );
    }

    $@ = $prev_error;
    return $wantarray ? @ret : $ret[0];
}

sub catch(&;@) {
    croak 'Useless bare catch()' unless wantarray;
    if (@_ > 1){
        croak "syntax error after catch block - maybe a missing semicolon"
            if !$_[2] || $_[2] ne __PACKAGE__;
    } else {
        return ( shift,  undef, __PACKAGE__);
    }
    return (@_);
}

sub finally(&;@) {
    croak 'Useless bare finally()' unless wantarray;
    if (@_ > 1) {
        croak "syntax error after finally block - maybe a missing semicolon";
    }
    return ( shift, __PACKAGE__ );
}

1;

__END__
=head1 NAME

Try::Catch - Try Catch exception handler based on Try::Tiny But faster

=for html
<a href="https://travis-ci.org/mamod/try-catch"><img src="https://travis-ci.org/mamod/try-catch.svg?branch=master"></a>

=head1 SYNOPSIS

    use Try::Catch;

    try {
        die "something went wrong";
    } catch {

    } finally {

        ##some cleanup code

    }; ##<--- semi colon is required.

=head1 DESCRIPTION

A small, fast, try catch blocks for perl, it's inspired and mostly copied from L<Try::Tiny> but with some
modifications to boost execution speed, see L</Benchmarks>.

I published a new module instead of contributing to Try::Tiny directly because I had to break some
features available in Try::Tiny some to boost speed and some because I didn't like.

=head1 Differences

=over 4

=item no multiple finally blocks

=item try must be followed by catch, catch then finally, or finally

this behaves exactly as how other implementations of try catch blocks

=item if there is no catch block error will throw

in case of try followed by finally block and no catch block, finally block will be fired
then an exception will be thrown, this is also the default behaviour of try catch in other
languages.

=back

=head1 CAVEATS

Same as L<Try::Tiny/CAVEATS>

=head1 Benchmarks

This is not totally fair but please consider Try::Catch a stripped Try::Tiny version
with no blessing and no usage of Sub::Name, so it must be faster, right! :)

This is a simple test with just a try catch blocks with no exception

    |  Module:      | Rate          | %         |
    |-------------------------------------------|
    |  Try::Tiny    | 98425/s       | -68%      |
    |  Try::Catch   | 304878/s      | 210%      |


Test with Try Catch, Finally Blocks, No Exception

    |  Module:      | Rate          | %         |
    |-------------------------------------------|
    |  Try::Tiny    | 60423/s       | -75%      |
    |  Try::Catch   | 245700/s      | 304%      |


Test with Try, Catch, Finally Blocks, AND Exception

    |  Module:      | Rate          | %         |
    |-------------------------------------------|
    |  Try::Tiny    | 41288/s       | -65%      |
    |  Try::Catch   | 116414/s      | 182%      |


I've also tested against L<TryCatch> and the results were good, considering
that L<TryCatch> is an XS module

    |  Module:      |  timing 500000 iterations                              |
    |----------------------------------------------------------------------- |
    |  TryCatch     |  1 secs (0.58 usr + 0.00 sys = 0.58 CPU) @ 865051.90/s |
    |  Try::Catch   |  2 secs (1.73 usr + 0.00 sys = 1.73 CPU) @ 288350.63/s |
    |  Try::Tiny    |  6 secs (6.16 usr + 0.02 sys = 6.17 CPU) @ 81011.02/s  |


Benchmarks included in this dist inside bench folder

=head1 See Also

=over 4

=item L<Try::Tiny>

=item L<TryCatch>

=back

=head1 Known Bugs

When doing block jump from try { } or catch { } then finally will not be called.

For example

    use Try::Catch;
    for (1) {
        try {
            die;
        } catch {
            goto skip;
        } finally {
            #finally will not be called
            print "finally was called\n";
        }
    }
    skip:

finally will work in most cases unless there is a block jump (last, goto, exit, ..)
so I recommend avoid using finally at all as it's planned to be removed in v2.0.0

=head1 AUTHOR

Mamod A. Mehyar, E<lt>mamod.mehyar@gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself
