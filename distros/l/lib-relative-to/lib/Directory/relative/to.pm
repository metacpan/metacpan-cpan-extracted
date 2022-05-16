package Directory::relative::to;

use strict;
use warnings;

use lib::relative::to ();

use Cwd;
use Exporter 'import';

our @EXPORT_OK = qw(relative_dir);
our $VERSION = '1.1000';

=head1 NAME

Directory::relative::to

=head1 DESCRIPTION

Find paths relative to something else

=head1 SYNOPSIS

Both of these will look up through the parent directories of the file that
contains this code until it finds the root of a git repository, then return
the absolute paths of the 'lib' and 't/lib' directories in that repository.

    use Directory::relative::to (relative_dir);

    my @dirs = relative_dir( GitRepository => qw(lib t/lib) );

or:

    use Directory::relative::to;

    my @dirs = Directory::relative::to->relative_dir(
        ParentContaining => '.git/config' => qw(lib t/lib)
    );

Yes, it's practically identical to how you'd invoke C<lib::relative::to>.
This module is just a very thin wrapper around that.

=head1 WHY?

Just like how I got fed up with Sam for the reasons explained in
L<lib::relative::to> I have a new colleague who wrote:

    use FindBin qw($Bin);
    ...
    my $fixture_path = "$Bin/../../fixtures";

That string of repeated C<../>s is an abomination unto the Lord.

=head1 FUNCTIONS

=head2 relative_dir

Can be invoked either as a class method or can I<optionally> be exported
and called as a normal function.

This takes the several arguments, the first of which is the name of a
C<lib::relative::to> plugin, the remainder being arguments to that plugin.
In general the argument list will take the form:

=over

=item plugin_name

=item plugin_configuration

=item list_of_directories

=back

Note that under the bonnet this function uses L<lib::relative::to>'s undocumented private functions.

It normally returns a list of fully-qualified directory names,
but if there is only one directory to be returned and you call
it in scalar context you will get a scalar name.

If there aer multiple directory names but you use scalar
context that is a fatal error.

=cut

sub relative_dir {
    shift if($_[0] eq __PACKAGE__);
    my($plugin, @plugin_args) = @_;

    # l::r::to needs to know where *this code* is being called
    # from instead of from where *it* is called.
    $lib::relative::to::called_from = Cwd::abs_path((caller(0))[1]);
    my @results = lib::relative::to->_load_plugin($plugin)
                                   ->_find(@plugin_args);

    # this isn't done on function entry cos we might want to
    # throw exceptions because the user did something silly
    return if(!defined(wantarray));

    if(@results > 1 && !wantarray) {
        die(__PACKAGE__.": Multiple results but you wanted a scalar\n");
    }

    return wantarray ? @results : $results[0];
}

1;

=head1 BUGS

I only have access to Unix machines for development and debugging. There may be
bugs lurking that affect users of exotic platforms like Amiga, Windows, and
VMS. I welcome patches, preferably in the form of a pull request. Ideally any
patches will be accompanied by tests, and those tests will either skip or pass
on Unix.

=head1 AUTHOR, COPYRIGHT and LICENCE

Copyright 2022 David Cantrell E<lt>david@cantrell.org.ukE<gt>.

This software is free-as-in-speech as well as free-as-in-beer, and may be used,
distributed, and modified under the terms of either the GNU General Public
Licence version 2 or the Artistic Licence. It's up to you which one you use.
The full text of the licences can be found in the files GPL2.txt and
ARTISTIC.txt, respectively.

=head1 CONSPIRACY

This software is also free-as-in-mason.

=cut
