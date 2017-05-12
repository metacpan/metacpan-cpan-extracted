package Try::Tiny::Except;

use 5.010000;
use strict;
use warnings;

use Try::Tiny qw/catch finally/;
BEGIN { eval "use Sub::Name; 1" or *{subname} = sub {1} }
my $try_orig;
BEGIN { $try_orig = \&Try::Tiny::try };

use Exporter 5.57 'import';

our @EXPORT = our @EXPORT_OK = qw/try catch finally/;

our $VERSION = '0.01';

our $always_propagate;

sub try (&;@) {
    if ($always_propagate) {
        my $found;
        for my $code (@_) {
            if (ref($code) eq 'Try::Tiny::Catch') {
                $found=1;
                my $sub=$$code;
                my $caller = caller;
                subname("${caller}::catch {...} " => $sub);
                my $new=sub {
                    die $_ if $always_propagate->();
                    goto &$sub;
                };
                $code=bless \$new, 'Try::Tiny::Catch';
            }
        }
        unless ($found) {
            my $new=sub {
                die $_ if $always_propagate->();
                return;
            };
            splice @_, 1, 0, bless (\$new, 'Try::Tiny::Catch');
        }
    }

    goto &$try_orig;
}

{
    no warnings 'redefine';
    *Try::Tiny::try = \&try;
}

1;
__END__

=encoding utf8

=head1 NAME

Try::Tiny::Except - a thin wrapper around Try::Tiny

=head1 SYNOPSIS

As early as possible (startup code):

 use Try::Tiny::Except ();

In normal code:

 use Try::Tiny;

Then set (or localize)

 $Try::Tiny::Except::always_propagate=sub {
   /ALARM/;                     # or whatever
 };

to have exceptions that contain C<ALARM> propgate through every C<catch>
block. C<finally> blocks are still called though.

=head1 DESCRIPTION

L<Try::Tiny> works great in most situations. However, in sometimes you
might want a certain exception being propagated always without the possibility
to catch it in a C<catch> block or to ignore it. For instance L<CGI::Compile>
or mod_perl's L<ModPerl::Registry> try to execute perl scripts in a persistent
interpreter. Hence, they have to prevent C<exit> being called by the
script. The usual way to achieve that is to turn it into a special exception.
But then you have to inspect all the C<eval>s in the code to make them aware
of that special exception. Provided your code does not use plain C<eval> but
L<Try::Tiny> instead, this is where C<Try::Tiny::Except> comes to rescue.

C<Try::Tiny::Except> can be used in 2 slightly different modes. First, you can
simply replace all C<use Try::Tiny> by C<use Try::Tiny::Except>. In that case
the C<try>, C<catch> and C<finally> functions provided by
C<Try::Tiny::Except> will be used. This is totally fine. To make sure
both modules behave exactly the same, I have copied the test suite from
L<Try::Tiny> and replaced all occurrences of C<use Try::Tiny> by
C<use Try::Tiny::Except>. The advantage of this usage is that it is obvious
to the reader which module is used. But it requires code changes.

The other usage mode is to load C<Try::Tiny::Except> as early as possible when
the interpreter is started. It loads then L<Try::Tiny> and overwrites the
C<try> function. Later in the code you can either C<use Try::Tiny> or
C<use Try::Tiny::Except>. Anyway, you'll get the C<try> function provided
by C<use Try::Tiny::Except>.

=head2 How to make an exception always propagate?

Let's use a real-life example, L<CGI::Compile>. This module overwrites
C<exit> with something like this:

 *CORE::GLOBAL::exit=sub {
   die ["EXIT\n", $_[0] || 0];
 };

So, a script performing C<exit> is actually throwing an exception
and C<$@> becomes an array with 2 elements where the first element is
the string C<"EXIT\n">.

To prevent this exception from ever being catched by a C<catch> block or
ignored by a bare C<try> block, set C<$Try::Tiny::Except::always_propagate>
like this:

 $Try::Tiny::Except::always_propagate=sub {
     ref eq 'ARRAY' and
     @$_==2 and
     $_->[0] eq "EXIT\n";
 };

Now compile and run a script:

 my $code=CGI::Compile->new(return_exit_val=>1)->compile('/path/to/script.pl');
 my $rc=$code->();

If F<script.pl> looks like this:

 use Try::Tiny;
 try {exit 19};
 12;

C<$rc> will become C<19> instead of C<12>.

=head2 EXPORT

C<try>, C<catch> and C<finally> are exported by default and on demand.

=head1 SEE ALSO

L<Try::Tiny>

=head1 AUTHOR

Torsten Förtsch E<lt>torsten.foertsch@gmx.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Torsten Förtsch

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
