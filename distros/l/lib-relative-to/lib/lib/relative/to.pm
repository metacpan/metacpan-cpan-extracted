package lib::relative::to;

use strict;
use warnings;

use Cwd;
use File::Spec;

use lib ();

our $VERSION = '1.1000';
our $called_from;

sub import {
    my($class, $plugin, @plugin_args) = @_;

    # in case we're inherited and someone isn't careful about
    # C<use>ing their module
    return unless($class eq __PACKAGE__);

    $called_from = Cwd::abs_path((caller(0))[1]);

    lib->import(
        $class->_load_plugin($plugin)
              ->_find(@plugin_args)
    ) if($plugin);
}

sub _load_plugin {
    my($class, $plugin) = @_;

    $plugin = __PACKAGE__ . "::$plugin";
    eval "require $plugin";
    die($@) if($@);
    return $plugin;
}

sub parent_dir {
    my $class = shift;
    my($volume, $dir) = File::Spec->splitpath(shift);
    File::Spec->catdir(
        grep { length($_) } ($volume, $dir)
    );
}

1;

=head1 NAME

lib::relative::to

=head1 DESCRIPTION

Add paths to C<@INC> that is relative to something else

=head1 SYNOPSIS

Both of these will look up through the parent directories of the file that
contains this code until it finds the root of a git repository, then add the
'lib' and 't/lib' directories in that repository's root to C<@INC>.

    use lib::relative::to
        GitRepository => qw(lib t/lib);

    use lib::relative::to
        ParentContaining => '.git/config' => qw(lib t/lib);

=head1 WHY?

I used to work with someone (hi Sam!) who would C<chdir> all over the place
while working on our product, and expected to be able to run tests no matter
where he was in our repository.

Normal people, of course, stay in the repository root and invoke their tests
thus:

    prove t/wibble/boing/frobnicate.t

and if that test file wanted to be able to load modules stored in a C<lib>
directory alongside C<t> and from C<t/lib> it would just say:

    use lib qw(t/lib lib);

But because of Sam, who liked to do this:

    cd t/wibble/boing
    prove frobnicate.t

We instead had to have nonsense like this:

    use lib::abs qw(../../../lib ../../lib);

which is just plain hideous. Not only is it ugly, it's hard to read (it's not
immediately clear which directories are being included) and it's hard to write
- did I get the right number of C<../../>? Did I remember to update the Morse
code when I moved a file? Who knows! Hence the
L<GitRepository|lib::relative::to::GitRepository> plugin. And because I wanted
to support Mercurial (see the L<HgRepository|lib::relative::to::HgRepository>
plugin) as well, I abstracted out most of the functionality.

Of course, I B<used to> work with Sam, so this is too late to save my sanity,
but writing it at least made me feel better.

=head1 METHODS

=head2 import

Takes numerous arguments, the first of which is the name of a plugin, the rest
are arguments to that plugin. It will load the plugin (or die if it can't) and
then pass the rest of the arguments to the plugin.

In general the argument list takes the form:

=over

=item plugin_name

=item plugin_configuration

=item list_of_directories

=back

and the plugin will use the C<plugin_configuration> to add C<list_of_directories> to
C<@INC>. In the L</SYNOPSIS> above you can see that
L<ParentContaining|lib::relative::to::ParentContaining> and
L<GitRepository|lib::relative::to::GitRepository> are plugins, that
C<.git/config> is plugin configuration (the C<GitRepository> plugin takes no
configuration), and that in both cases we want
to add C<lib> and C<t/lib> to C<@INC>.

=head2 parent_dir

Class method, takes a file or directory name as its argument, returns the directory
containing that object.

=head1 WRITING PLUGINS

You are encouraged to write your own plugins. I would appreciate, but do not
require, that you tell me about your plugins.

You can upload your own plugins to the CPAN, or you can send them to me and I
will include them in this distribution. The best way of sending them to me is
via a Github pull request, but any other way of getting the files to me works.
If you want your code to be included in this distribution you B<must> include
tests and appropriate fixtures.

=head2 NAMING

Plugin names must take the form C<lib::relative::to::YourPluginName>.

The C<lib::relative::to::ZZZ::*> namespace is reserved.

=head2 FUNCTIONS

Your plugin must implement a class method called C<_find>, which will be called when your plugin has been loaded, and will have the remainder of the argument list passed to it. That is to say that when your plugin is invoked thus:

    use lib::relative::to YourPluginName => qw(foo bar baz);

your C<_find> method will be called thus:

    lib::relative::to::YourPluginName->_find(qw(foo bar baz));

NB that your C<import> method, if any, will B<not> be called.

Your C<_find> method should return a list of absolute paths to be added to C<@INC>. You will probably find L<Cwd::abs_path|Cwd#abs_path> and L<File::Spec> useful. Both modules will have already been loaded so you don't need to C<use> them yourself. You may also want to use C</parent_dir> - you can get access to it either by inheriting from C<lib::relative::to> or by calling it directly:

    my $directory = lib::relative::to->parent_dir(...);

=head2 CONTEXT

C<$lib::relative::to::called_from> will contain the absolute name of the file from which your plugin was invoked.

=head2 INHERITANCE

The most useful class to inherit from is probably going to be the L<ParentContaining|lib::relative::to::ParentContaining> plugin. Indeed, that is what the L<GitRepository|lib::relative::to::GitRepository> and L<HgRepository|lib::relative::to::HgRepository> plugins do. The source for the C<HgRepository> plugin reads, in its entirety:

    package lib::relative::to::HgRepository;
    
    use strict;
    use warnings;
     
    use parent 'lib::relative::to::ParentContaining';
    
    sub _find {
        my($class, @args) = @_;
        $class->SUPER::_find('.hg/store', @args);
    }
    1;

=head1 BUGS

I only have access to Unix machines for development and debugging. There may be
bugs lurking that affect users of exotic platforms like Amiga, Windows, and
VMS. I welcome patches, preferably in the form of a pull request. Ideally any
patches will be accompanied by tests, and those tests will either skip or pass
on Unix.

=head1 AUTHOR, COPYRIGHT and LICENCE

Copyright 2020 David Cantrell E<lt>david@cantrell.org.ukE<gt>.

This software is free-as-in-speech as well as free-as-in-beer, and may be used,
distributed, and modified under the terms of either the GNU General Public
Licence version 2 or the Artistic Licence. It's up to you which one you use.
The full text of the licences can be found in the files GPL2.txt and
ARTISTIC.txt, respectively.

=head1 CONSPIRACY

This software is also free-as-in-mason.

=cut
