package Unix::setuid;

our $DATE = '2014-10-09'; # DATE
our $VERSION = '0.02'; # VERSION

use 5.010001;
use strict;
use warnings;

use POSIX qw();

use Exporter qw(import);
our @EXPORT = qw($RUID $EUID $RUSER $EUSER);

our $RUID ; tie $RUID , 'Unix::setuid::ruid'  or die "Can't tie \$RUID";
our $EUID ; tie $EUID , 'Unix::setuid::euid'  or die "Can't tie \$EUID";
our $RUSER; tie $RUSER, 'Unix::setuid::ruser' or die "Can't tie \$RUSER";
our $EUSER; tie $EUSER, 'Unix::setuid::euser' or die "Can't tie \$EUSER";

{
    package Unix::setuid::ruid;
    sub TIESCALAR { bless [], $_[0] }
    sub FETCH     { $< }
    sub STORE     { $< = $_[1] }
}

{
    package Unix::setuid::euid;
    sub TIESCALAR { bless [], $_[0] }
    sub FETCH     { $> }
    sub STORE     { $> = $_[1] }
}

{
    package Unix::setuid::ruser;
    sub TIESCALAR { bless [], $_[0] }
    sub FETCH     { my @pw = getpwuid($<); @pw ? $pw[0] : $< }
    sub STORE     {
        if ($_[1] =~ /\A\d+\z/) {
            $< = $_[1];
        } else {
            my @pw = getpwuid($_[1]);
            die "No such user '$_[1]'" unless @pw;
            $< = $pw[2];
        }
    }
}

{
    package Unix::setuid::euser;
    sub TIESCALAR { bless [], $_[0] }
    sub FETCH     { my @pw = getpwuid($>); @pw ? $pw[0] : $> }
    sub STORE     {
        if ($_[1] =~ /\A\d+\z/) {
            $> = $_[1];
        } else {
            my @pw = getpwnam($_[1]);
            die "No such user '$_[1]'" unless @pw;
            $> = $pw[2];
        }
    }
}

1;
#ABSTRACT: Get/set real/effective UID/username via (localizeable) variable

__END__

=pod

=encoding UTF-8

=head1 NAME

Unix::setuid - Get/set real/effective UID/username via (localizeable) variable

=head1 VERSION

This document describes version 0.02 of Unix::setuid (from Perl distribution Unix-setuid), released on 2014-10-09.

=head1 SYNOPSIS

 use Unix::setuid; # exports $RUID, $EUID, $RUSER, $EUSER
 say "Real      UID : $RUID";
 say "Effective UID : $EUID";
 say "Real username : $RUSER";
 say "Effective user: $EUSER";
 {
     # become UID 1000 temporarily
     local $EUID = 1000;
     # same thing
     #local $EUSER = "jajang"; # or 1000
 }
 # we're back to previous UID/user

=head1 DESCRIPTION

This module is inspired by L<File::chdir> and L<File::umask>, using a tied
scalar variable to get/set stuffs. One benefit of this is being able to use
Perl's "local" with it, effectively setting something locally.

=head1 EXPORTS

=head2 $RUID (real UID)

This will get/set C<< $< >>.

=head2 $EUID (effective UID)

This will get/set C<< $> >>.

=head2 $RUSER (real user)

Same as C<$RUID> except you will get username and you can set using
UID/username. Will return numeric UID if no user exists with that ID. Will die
if setting to non-existing username.

=head2 $EUSER (effective user)

Same as C<$EUID> except you will get username and you can set using
UID/username. Will return numeric UID if no user exists with that ID. Will die
if setting to non-existing username.

=head1 SEE ALSO

Perl's C<< $< >> and C<< $> >>.

Other modules with the same concept: L<File::chdir>, L<File::umask>,
L<Locale::Tie>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Unix-setuid>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-System-setuid>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Unix-setuid>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
