package scriptname;
# ABSTRACT: Locate original perl script

use strict;
use warnings;
use 5.000;

my($myname, $mybase, $mydir);

BEGIN {
  our $VERSION = '0.92';
  our $AUTHORITY = 'MASSA';

  use Carp;
  use Cwd qw(realpath cwd);
  use File::Basename qw(basename dirname);

  if( $0 eq '-' || $0 eq '-e' ) {
    $mydir = cwd
  } else {
    $myname = $0 = realpath $0;
    $mybase = basename $0, qw(.t .pm .pl .perl .exe .com .bat);
    $mydir = dirname $0;
    croak 'chdir() too early' unless -f $0
  }

  use lib;
  use Exporter;
  our @EXPORT_OK = qw(myname mybase mydir);
  our %EXPORT_TAGS = (all => [@EXPORT_OK]);
}

sub myname() { $myname } ## no critic
sub mybase() { $mybase } ## no critic
sub mydir()  { $mydir  } ## no critic
sub _mylib   { map realpath("$mydir/$_"), (@_ ? @_ : qw(./lib)) }

sub import {
  my $package = shift;
  return unless @_;
  my $first_tag = shift;
  return lib->import(_mylib @_) if defined $first_tag and $first_tag eq 'lib';
  Exporter::import($package, $first_tag, @_)
}

sub unimport {
  my $package = shift;
  return unless @_;
  my $first_tag = shift;
  lib->unimport(_mylib @_) if defined $first_tag and $first_tag eq 'lib'
}

# Magic true value required at end of module
1;


__END__
=pod

=head1 NAME

scriptname - Locate original perl script

=head1 VERSION

version 0.92

=head1 SYNOPSIS

    use scriptname;
    use lib scriptname::mydir . '/../lib';

or

    use scriptname lib => '../lib';

or

    use scriptname ':all';
    my $scriptbasename = mybase;

you can also use

    no scriptname lib => '../lib';

to remove a relative path from C<@INC>. As a special case,

    use scriptname 'lib';

is equivalent to

    use scriptname lib => 'lib';

(unshift the path to the current script + 'lib' in @INC)

=head1 DESCRIPTION

Locates the full path to the current script's directory to allow the
use of of paths relative to the script's directory. Also, unshift
paths relative to the script's directory in @INC.

This allows a user to setup a directory tree for some software with
directories C<< <root>/bin >> and C<< <root>/lib >>, and then the above
example will allow the use of modules in the lib directory without knowing
where the software tree is installed, even if the name by which the script
was called is a symbolic link to the path where the C<../bin> and the
C<../lib> actually are.

If perl is invoked using the B<-e> option or the perl script is read from
C<STDIN> then the module sets C<mydir> to the current working
directory.

=head1 FUNCTIONS

=head2 myname

fully qualified path for the script (with all links resolved), undef if called
from C<-e> or C<STDIN>

=head2 mybase

basename of C<myname>, or undef

=head2 mydir

dirname of C<myname>, or the current working directory if called from C<-e> or C<STDIN>

=head2 $0

The result of C<myname> is also put in C<$0> unless called from C<-e> or C<STDIN>.

=head1 DIAGNOSTICS

=over

=item C<< chdir() too early >>

The module croaks if the script can manage to call C<chdir()> before the

  use scriptname;

Please, don't do that.

=back

=head1 KNOWN ISSUES

The module can, under some circumstances, not croak even if the
the script called C<chdir()> before the C<use>.
In that case, the returned results can be WRONG. So, as I said,
please, don't do that.

=head1 DEPENDENCIES

perl5.8 and the standard modules C<File::Basename>, C<Carp>,
C<Exporter>, C<Cwd> and C<lib>.

Also depends on C<version>.

=head1 INCOMPATIBILITIES

=head2 Differences from C<< FindBin >>

C<scriptname> does not search B<PATH>. It makes one of the following assumptions:

=over

=item C<$0> comes with an absolute filename (starting from root)

This can happen:

=over

=item *

When the script was called with B<perl -S> -- in this case, perl looked the B<PATH> for the script;

=item *

When the script was called with B<perl> I<absolute_file_name>;

=item *

When the script was called by the shebang and the shell/kernel (whoever
interpreted the shebang) was passed pathless command name -- 
when the shell/kernel searched the B<PATH> and found the file,
it passes the absolute filename to B<perl>;

=item *

When the script was called by the shebang and the shell/kernel was
passed an absolute filename --
when this is the case, the shell/kernel passes the absolute pathname unaltered to
B<perl>.

=back

=item C<$0> comes with a filename relative to the current directory

This happens:

=over

=item *

When the script was called with B<perl> I<relative_file_name> -- B<perl> will
search the filename under the current directory;

=item *

When the script was called by the shebang and the shell/kernel was
passed a relative filename -- when this is the case, the kernel/shell passes
the relative filename to B<perl>, also unaltered.

=back

=back

C<scriptname> follows symbolic links.

And C<scriptname> has the B<lib> option, to prepend library paths relative
to C<scriptname::mydir> to B<@INC>.

=head1 BUGS AND LIMITATIONS

See L<KNOWN ISSUES>.

Please report any bugs or feature requests to
C<bug-scriptname@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 THANKS

C<stevenl@cpan.org>, for pointing a silly mistake in my tests

=head1 ALTERNATIVE LICENSE TERMS

Optionally, instead of using the Perl 5 programming language licensing
terms, you are also autorized to redistribute and/or modify it under the
terms of any of the following licenses, at your will: GNU LGPLv2, GNU
LGPLv3, CC-LGPLv2, CC-By-SAv3.0.

Please notice that the alternatives given in the previous paragraph apply
B<only for this module> and other modules where explicitly stated.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=head1 AUTHOR

Humberto Massa <massa@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Humberto Massa.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

