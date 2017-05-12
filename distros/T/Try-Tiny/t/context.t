use strict;
use warnings;

use Test::More;
use Try::Tiny;

plan tests =>
  (4+1) * 2 # list/scalar with exception (try + catch + 2 x finally) + is_deeply
+ 4         # void with exception
+ (3+1) * 2 # list/scalar no exception (try + 2 x finally) + is_deeply
+ 3         # void no exception
;

my $ctx_index = {
  VOID => undef,
  LIST => 1,
  SCALAR => '',
};
my ($ctx, $die);

for (sort keys %$ctx_index) {
  $ctx = $_;
  for (0,1) {
    $die = $_;
    if ($ctx_index->{$ctx}) {
      is_deeply(
        [ run() ],
        [ $die ? 'catch' : 'try' ],
      );
    }
    elsif (defined $ctx_index->{$ctx}) {
      is_deeply(
        [ scalar run() ],
        [ $die ? 'catch' : 'try' ],
      );
    }
    else {
      run();
      1;
    }
  }
}

sub run {
  try {
    is (wantarray, $ctx_index->{$ctx}, "Proper context $ctx in try{}");
    die if $die;
    return 'try';
  }
  catch {
    is (wantarray, $ctx_index->{$ctx}, "Proper context $ctx in catch{}");
    return 'catch';
  }
  finally {
    is (wantarray, undef, "Proper VOID context in finally{} 1");
    return 'finally';
  }
  finally {
    is (wantarray, undef, "Proper VOID context in finally{} 2");
    return 'finally';
  };
}
