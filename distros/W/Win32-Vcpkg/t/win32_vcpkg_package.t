use Test2::V0 -no_srand => 1;
use Win32::Vcpkg;
use Win32::Vcpkg::Package;
use Path::Tiny ();

subtest 'basic' => sub {

  my $mock = mock 'Win32::Vcpkg' => (
    override => [
      root => sub {
        Path::Tiny->new('corpus', 'root1')->absolute;
      },
    ],
    override => [
      perl_triplet => sub {
        'x64-windows',
      },
    ],
  );

  foreach my $debug (0,1)
  {
    subtest "debug = $debug" => sub {
      my $package = Win32::Vcpkg::Package->new(
        lib   => ['foo'],
        debug => $debug,
      );

      isa_ok $package->root, 'Path::Tiny';

      note "root    = ", $package->root;
      note "triplet = ", $package->triplet;
      note "cflags  = ", $package->cflags;
      note "libs    = ", $package->libs;

      is(
        $package,
        object {
          call triplet => 'x64-windows';
          call cflags  => match qr/^-I/;
          call libs    => match qr/^-LIBPATH:.* foo.lib/i
        }
      ) || return;

      my($foo_h)   = map { Path::Tiny->new($_)->child('foo.h')   } $package->cflags =~ /^-I(.*)$/;
      my($foo_lib) = map { Path::Tiny->new($_)->child('foo.lib') } $package->libs   =~ /^-LIBPATH:(.*) foo.lib$/i;

      is(
        $foo_h,
        object {
          call is_file => T();
          call slurp   => match qr/#define FOO 1/;
        },
      );

      is(
        $foo_lib,
        object {
          call is_file => T();
          call slurp   => match ($debug ? qr/faux dbg foo/ : qr/faux opt foo/);
        },
      );
    };
  }

  subtest 'not found' => sub {

    like
      dies { Win32::Vcpkg::Package->new( lib => ['bar'] ) },
      qr/unable to find bar/,
    ;

  };
};

done_testing;


