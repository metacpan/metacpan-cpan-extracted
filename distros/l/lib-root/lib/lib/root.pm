package lib::root;
use strict;
use warnings;
use Path::Tiny;
use Cwd;

our $VERSION = "0.06";
my $root;

sub import
{
  my ( $package, %args ) = @_;
  my $rootfile    = $args{ rootfile } || '.libroot';
  my $callback    = $args{ callback };
  my $perldir     = $args{ perldir };
  my $caller_file = $args{ caller_file } || Cwd::realpath( ( caller )[ 1 ] );
  my $path        = path( $caller_file )->parent;

  $path = $path->realpath->absolute;
  my $found;
  my $lib_paths;

  my @children = grep { defined } ( $perldir, $rootfile );
  while ( !$found && $path ne $path->rootdir )
  {
    if ( -e $path->child( @children ) )
    {
      $found     = $path->child( @children );
      $lib_paths = $path->child( @children )->parent->child( '/*/lib' );
      last;
    }
    elsif ( -e $path->child( $rootfile )
      && $perldir
      && -d $path->child( $perldir ) )
    {
      $found     = $path->child( $rootfile );
      $lib_paths = $path->child( $perldir, '/*/lib' );
      last;
    }
    $path = $path->parent;

  }

  if ( $found )
  {
    $root = $found->parent;
    push @INC, glob $lib_paths;
    $callback->( $lib_paths, $found )
      if $callback;
  }
  else
  {
    warn
      "lib::root error: Could not find rootfile [ $rootfile ]. lib::root loaded from [ $caller_file ].";
  }
}

sub root
{
  return $root;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

lib::root - find perl root and push lib modules path to @INC

=head1 VERSION

version 0.06

=head1 SYNOPSIS

lib::root looks for a .libroot file on parent directories and pushes ./*/lib to @INC.

When a file does C<use lib::root>, lib::root will try to read the file parent directories and look for a rootfile (default is .libroot) that is usually located inside a /some/dir/perl that contains many modules used by your app. Many apps have a /some/dir/perl/.perl-version file inside a perl directory, when that is the case, the app can piggy back on that filename and look for that file instead of .libroot with the example below:

  use lib::root rootfile => '.perl-version';

To use the defaults, create an empty file named .libroot and place it in your /app/dir/perl/.libroot

  use lib::root;

  ... or use another custom file to determine a libroot

  use lib::root; # rootfile defaults to .libroot
  use lib::root rootfile => '.perl-version';

  ... or add a callback if needed

  use lib::root callback => sub { ... };

  ... or look for a given file in approot and use a perl root dir to push to inc

  use lib::root rootfile => '.app-root', perldir => 'perl';

=head1 WHY IS THIS USEFUL

lib::root can be useful when your application perl modules are not installed globally.

When your app uses lib::root, the lib::root will look for the .libroot file into parent directories relative to the file using it.

For example, your app has the following structure:

  /dir/myapp/perl/MyApp-Thing/lib/...
  /dir/myapp/perl/MyApp-Another/lib/...
  /dir/myapp/perl/MyApp-Stuff/lib/...
  /dir/myapp/perl/.perl-version
  /dir/myapp/bin/some_script.pl
  /dir/myapp/bin/another_script.pl
  /dir/myapp/.app-root

... and the app needs to push all those perl/*/lib to @INC. There are some ways to do that

Add the directory to env PERLLIB or PERL5LIB

  PERLLIB=$PERLLIB:/dir/myapp/perl/MyApp-Thing/lib:/dir/myapp/perl/MyApp-Another/lib

Or use -I

  perl -I/dir/myapp/perl/MyApp-Thing/lib -I/dir/myapp/perl/MyApp-Another/lib

Or use a BEGIN block:

  BEGIN { push @INC, glob "/dir/myapp/perl/*/lib"; }

Or use lib::root:

  use lib::root rootfile => '.perl_is_here';

lib::root can also be instructed to look in a cousin dir relative to C<bin> in the structure above

  use lib::root perldir => '../perl';

Or use lib

  use FindBin qw($Bin);
  use lib "$Bin/../lib";
  use lib "/home/user/MyApp/lib";

Or some other way ...

=head2 USAGE

For a project with the following strucutre:

  /dir/myapp/perl/MyApp-Thing/lib/MyApp/Thing.pm
  /dir/myapp/perl/MyApp-Another/lib/MyApp/Another.pm
  /dir/myapp/perl/MyApp-Stuff/lib/MyApp/Stuff.pm
  /dir/myapp/perl/.libroot
  /dir/myapp/perl/.perl-version
  /dir/myapp/bin/some_script.pl
  /dir/myapp/bin/another_script.pl
  /dir/myapp/.app-root

=head3 EXAMPLE 1 - DEFAULT USAGE

When using /dir/myapp/perl/MyApp-Thing/lib/MyApp/Thing.pm its possible to include perl/*/lib to @INC by adding the following to Thing.pm

  use lib::root;

The above will detect the location of Thing.pm and go recursively to parent directories and look for the default C<.libroot> file. Given that the .libroot file exists under /dir/myapp/perl/.libroot (/dir/myapp/perl/) , lib::root will do: push @INC, glob "/dir/myapp/perl/*/lib";

=head3 EXAMPLE 2 - CUSTOM lib::root FILE

Some plenv projects have a C<.perl-version> file sitting under the perl dir ie. /perl/.perl-version (see structure above). If thats the case, lib::root can piggy back on the .perl-version file with:

  use lib::root rootfile => '.perl-version';

=head3 EXAMPLE 3 - CALLING FROM SCRIPT OUTSIDE perl DIRECTORY

If the project has C<bin> directories like the structure above, and the file /dir/myapp/bin/some_script.pl needs to use lib::root, the file is outside the C<perl> dir. It will use the C<.app-root> file with a custom perl C<perldir> to push libs to @INC, ie:

  use lib::root rootfile => '.app-root', perldir => 'perl';

The lib::root call insite the script in C<bin> will look for a directory that contains C<.app-root> and then it will use the child directory C<perl> (the perldir option) to push the modules to @INC;

The same could be done to make the .pm files above also use the C<.app-root> instead of the C<.libroot>. Or, also, use C<.libroot> with a custom C<perldir>, ie:

  use lib::root perldir => 'perl';
  use lib::root perldir => 'dir1/dir2/dir3/perl';
  use lib::root perldir => '../perl';

=head3 EXAMPLE 4 - CALLBACKS

If necessary, lib::root also accepts a callback as an option. The callback is executed after libs are pushed to @INC ie:

  use lib::root callback => sub { ... };

=head3 EXAMPLE 5 - GET ROOT DIR

IT is also possible to get the root dir calling the root sub:

  my $rootdir = lib::root->root;

=head3 EXAMPLE 5 - GET ROOT DIR

IT is also possible to get the root dir calling the root sub:

  my $rootdir = lib::root->root;

=head2 SEE ALSO

Similar ideas have been implemented before in the modules below and possibly others

=over

=item * RepRoot

L<https://metacpan.org/pod/RepRoot>

=item * lib::glob

L<https://metacpan.org/pod/lib::glob>

=back

=head1 LICENSE

Copyright (C) Hernan Lopes.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Hernan Lopes

=cut

