#!perl
use strict;
use warnings;
use Test::More;

# Test::Dependencies is a bit idiotic when it comes to locating
# metadata files.
my @CLEANUP;
if (!-f 'META.yml') {
    if (-f 'MYMETA.yml') {
        link 'MYMETA.yml', 'META.yml';
        push @CLEANUP, sub { unlink 'META.yml' };
    }
    else {
        plan skip_all =>
          'Either META.yml or MYMETA.yml is required for this test';
    }
}

eval {
    require Test::Dependencies;
    import Test::Dependencies
      style   => 'heavy',
      exclude => [
          'Tripletail',
          't'
         ];
};
if ($@) {
    plan skip_all =>
      'Test::Dependencies required for this test';
}

# B::PerlReq fails to run any END blocks so some temporary files end
# up being left unremoved.
push @CLEANUP, sub {
    opendir my $dh, 't' or die $!;
    while (defined(my $fname = readdir $dh)) {
        if ($fname =~ m/\Atmp\d+\.ini\z/) {
            unlink "t/$fname";
        }
    }
};

ok_dependencies();

END {
    $_->() foreach @CLEANUP;
}
