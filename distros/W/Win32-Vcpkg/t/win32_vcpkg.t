use Test2::V0 -no_srand => 1;
use Win32::Vcpkg;

my $root            = Win32::Vcpkg->root;
my $perl_triplet    = Win32::Vcpkg->perl_triplet;
my $default_triplet = Win32::Vcpkg->default_triplet;

diag '';
diag '';
diag '';

diag "Win32::Vcpkg->root            = @{[ defined $root ? $root->canonpath : 'undefined' ]}";
diag "Win32::Vcpkg->perl_triplet    = @{[ $perl_triplet ]}";
diag "Win32::Vcpkg->default_triplet = @{[ $default_triplet ]}";

diag '';
diag '';

subtest 'root method' => sub {
  skip_all 'root not found' unless defined $root;

  ok -d $root;
  ok -f $root->child('.vcpkg-root');

};

done_testing;


