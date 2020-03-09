use Test2::V0 -no_srand => 1;
use Win32::Vcpkg;
use Win32::Vcpkg::List;
use Path::Tiny ();

delete $ENV{PERL_WIN32_VCPKG_DEBUG};

subtest 'basic' => sub {

  my $mock = mock 'Win32::Vcpkg' => (
    override => [
      root => sub {
        Path::Tiny->new('corpus', 'root2')->absolute;
      },
    ],
    override => [
      perl_triplet => sub {
        'x64-windows',
      },
    ],
  );

  my $list = Win32::Vcpkg::List->new;
  isa_ok $list, 'Win32::Vcpkg::List';
  isa_ok $list->root, 'Path::Tiny';

  is(
    $list,
    object {
      call root => object {
        call is_dir => T();
      };
      call_list triplets => [ 'x64-windows', 'x86-windows' ];
      call [search => 'libffi'] => object {
        call root => object {
          call is_dir => T();
        };
        call name    => 'libffi';
        call version => '3.3';
        call triplet => 'x64-windows';
        call cflags  => match qr{^-I.*/x64-windows/include$};
        call libs    => match qr{^-LIBPATH:.*/x64-windows/lib libffi\.lib$};
      };
      call [search => 'libffi', debug => 1] => object {
        call root => object {
          call is_dir => T();
        };
        call name    => 'libffi';
        call version => '3.3';
        call triplet => 'x64-windows';
        call cflags  => match qr{^-I.*/x64-windows/include$};
        call libs    => match qr{^-LIBPATH:.*/x64-windows/debug/lib libffi\.lib$};
      };
      call [search => 'libffi', triplet => 'x86-windows'] => object {
        call root => object {
          call is_dir => T();
        };
        call name    => 'libffi';
        call version => '3.3';
        call triplet => 'x86-windows';
        call cflags  => match qr{^-I.*/x86-windows/include$};
        call libs    => match qr{^-LIBPATH:.*/x86-windows/lib libffi\.lib$};
      };
      call [search => 'foo'] => U();
    },
  );

};

done_testing;


