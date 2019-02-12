package Unix::Sudo;

use strict;
use warnings;

our $VERSION = '2';

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(sudo);

use B::Deparse;
use Data::Dumper;
use PadWalker qw(peek_my);
use Probe::Perl;

=head1 NAME

Unix::Sudo

=head1 DESCRIPTION

Run a block of code as root

=head1 SYNOPSIS

As a normal user who can C<sudo> ...

    use Unix::Sudo qw(sudo);

    print `whoami`;          # shows your normal username
    sudo {
        eval "no tainting";
        print `whoami`;      # root
    };
    print `whoami`;          # back to normal

=head1 EXPORTS / FUNCTIONS

There is one function, which can be exported if you wish but is not exported by
default:

=head2 sudo

Takes a code-ref as its only argument. This can be in a variable, or as an
anonymous code-ref, or a block:

    my $code = sub { 1 + 2 };
    sudo($code);

    sudo(sub { 1 + 2 });

    sudo { 1 + 2 };

That code-ref will be executed as root, with no arguments, and with as much as
possible of the calling code's environment. It may return an integer value from
0 to 254. Anything else will be numified.

If you want to return something more complicated then I recommend that you
return it on STDOUT and use L<Capture::Tiny> to retrieve it.

=head1 ERRORS

A return value of 255 is special and is used to indicate that the code couldn't
be compiled for some reason. When this happens the child process will spit an
error message to STDERR, and the parent will die and attempt to tell you where
you passed dodgy code to Unix::Sudo.

See L<CAVEATS> for some hints on circumstances when this might happen.

=head1 HOW IT WORKS

Internally, your code will be de-parsed into its text form and then executed thus:

    system(
        'sudo', '-p', '...', 'perl', '-T',
        '-I...', ...
        '-e',
        "exit(do{ $your_code_here })"
    ) >> 8;

C<sudo> might have to prompt for a password. If it does, then the prompt will
make it clear that this is Unix::Sudo asking for it.

It's not just your code that is passed to the child process.  There are also a
bunch of C<-I> arguments, so that it knows about any directories in the parent
process's C<@INC>, and it will also get copies of all the lexical variables
that are in scope in the calling code.

Under the bonnet it uses L<B::Deparse> to turn your code-ref into text,
L<PadWalker>'s C<peek_my()> to get variables, and L<Data::Dumper> (and
C<$Data::Dumper::Deparse>) to turn those variables into text, all of which is
pre-pended to your code.

=head1 CAVEATS

Your code will always have C<strict> and C<warnings> turned on, and be run with
taint-checking enabled. If you need to you can turn tainting off as shown in
the synopsis. Note that you can't just say 'no tainting', the C<eval> is
required, otherwise C<no>, just like C<use>, will be run at compile-time I<in
the calling code> and not in the child process where you need it.

If your code needs to C<use> any modules, or any subroutines that are imported,
you will need to say so inside the code-ref you pass. And again, remember that
you'll have to C<eval> any C<use> statements.

The variables that are passed through to your code are read-write, but any
changes you make are local to the child process so will not be communicated
back to the parent process.

Any blessed references, tied variables, or objects that use C<overload> in
those variables may not behave as you expect.  For example, a record that has
been read from a database won't have an active database connection; something
tied to a filehandle won't have an open filehandle; an object that uses
C<overload> to make reading its value have side-effects will not have those
side-effects respected in the parent process.  In general, you should use this
to "promote" as little of your code as possible to run as root, and I<only>
your code so that you can be as aware as possible of the preceding.

=head1 DEBUGGING

If your code isn't behaving as you expect or is dieing then I recommend that
you set UNIX_SUDO_SPILLGUTS=1 in your environment. This will cause Unix::Sudo
to C<warn()> you about what it is about to execute before it does so.

=head1 SECURITY CONCERNS

This code will run potentially user-supplied code as root. I have done what I
can to avoid security hilarity, but if you allow someone to pass C<rm -rf /*>
that's your problem.

I have mitigated potential problems by:

=over

=item using the LIST form of C<system>

It shouldn't be possible to craft input that makes my code run your code as
root and then make my code run something else as root.

It is of course still possible to make my code run your code as root and for
your code to then run other stuff as root.

=item tainting is turned on

That means that any input to your code from the outside world is internally
marked as being untrusted, and you are restricted in what you can do with it.
You can of course circumvent this by untainting, either in the usual regexy
ways or as noted above via C<no tainting>.

=back

I strongly recommend that you read and understand the source code and also read
L<perlsec> before using this code.

=head1 STABILITY

I make no promises about the stability of the interface, and it is subject to
change without notice. This is because I want to strongly encourage you to
read the documentation and the source code before installing new versions of
this code.

I also therefore urge you that if you use this module in anything important
you should "pin" it to a particular version number in whatever you use for
managing your dependencies.

=head1 BUGS/FEEDBACK

Please report bugs at
L<https://github.com/DrHyde/perl-modules-Unix-Sudo/issues>, including, if
possible, a test case.

=head1 SOURCE CODE REPOSITORY

L<git://github.com/DrHyde/perl-modules-Unix-Sudo.git>

=head1 AUTHOR, COPYRIGHT and LICENCE

Copyright 2019 David Cantrell E<lt>F<david@cantrell.org.uk>E<gt>

This software is free-as-in-speech software, and may be used, distributed, and
modified under the terms of either the GNU General Public Licence version 2 or
the Artistic Licence.  It's up to you which one you use.  The full text of the
licences can be found in the files GPL2.txt and ARTISTIC.txt, respectively.

=head1 CONSPIRACY

This module is also free-as-in-mason software.

=cut

sub sudo(&) {
    my $context = peek_my(1);
    my $code = '';

    my $deparse = B::Deparse->new();

    # declare all the variables first, in case one of them is a code-ref
    # that refers to one of the others
    foreach my $variable (keys %{$context}) {
        $code .= "my $variable;\n";
    }
    # now give them their values
    foreach my $variable (keys %{$context}) {
        local $Data::Dumper::Deparse = 1;
        local $Data::Dumper::Indent  = 0;

        my $value = $context->{$variable};

        if(substr($variable, 0, 1) eq '%') {
            $code .= "$variable = %{ (), do { my ".Dumper($value)."}};\n"
        } elsif(substr($variable, 0, 1) eq '@') {
            $code .= "$variable = \@{ (), do { my ".Dumper($value)."}};\n"
        } elsif(substr($variable, 0, 1) eq '$') {
            if(
                ref($value) eq 'REF' &&
                ref(${$value}) eq 'CODE'
            ) {
                $code .= "$variable = sub ".
                    $deparse->coderef2text(${$value}).
                    ";\n";
            } else {
                $code .= "$variable = \${ scalar do { my ".Dumper($value)."}};\n"
            }
        } else {
            die("Sorry, Unix::Sudo can't cope with sigil '".
                substr($variable, 0, 1).
                "'\n");
        }
    }

    $code .= $deparse->coderef2text(shift);

    if($ENV{UNIX_SUDO_SPILLGUTS}) { warn $code }
    
    my $rv = system(
        "sudo", "-p", "Unix::Sudo needs your password: ",
        Probe::Perl->find_perl_interpreter(),
        (map { "-I$_" } grep { -d } @INC),
        "-T", "-e", "exit do { $code }"
    ) >> 8;

    if($rv == 255) {
        die(sprintf(
            "Your code didn't compile when passed to Unix::Sudo::sudo at %s line %s\n",
            (caller(1))[1, 2]
        ));
    } else {
        return $rv
    }
}

1;
