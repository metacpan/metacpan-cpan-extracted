use strict;
use warnings;

use re '/aa';

use 5.014;

use Test::More;

use Perl::Critic;
use Perl::Critic::Policy::ProhibitUnusedImports;

# -profile => q{} because Perl::Critic otherwise walks up from cwd looking for
# a .perlcriticrc, finds this dist's own, and runs every policy in it against
# these snippets -- which then fail for want of POD rather than for imports.
# Note the hyphen in -single-policy: -single_policy is accepted and silently
# ignored, leaving all 200-odd policies switched on.
# -allow-unsafe because reading @EXPORT means loading the module.
my $critic = Perl::Critic->new(
    -profile         => q{},
    '-single-policy' => 'ProhibitUnusedImports',
    -severity        => 1,
    '-allow-unsafe'  => 1,
);

sub violations {
    my ($source) = @_;
    return scalar $critic->critique( \$source );
}

my %prohibited = (
    'empty parens, name never used' => qq{use FindBin();\nprint "hi";\n},
    'named import never called'     => qq{use List::Util qw{first};\nmy \$x = 1;\n},
    'hidden behind a sibling use'   => qq{use FindBin();\nuse FindBin::libs;\nmy \$x = 1;\n},
    'several, none called'          => qq{use List::Util qw{first any};\nmy \$x = 1;\n},
    'default import never used'     => qq{use File::Basename;\nmy \$x = 1;\n},
);

foreach my $case ( sort keys %prohibited ) {
    is( violations( $prohibited{$case} ), 1, "$case is a violation" );
}

my %allowed = (
    'package variable used' => qq{use FindBin();\nprint \$FindBin::Bin;\n},
    'used inside a string'  => qq{use FindBin();\nmy \$p = "\$FindBin::Bin/../lib";\n},
    'used inside a heredoc' => qq{use FindBin();\nmy \$p = <<"END";\n\$FindBin::Bin\nEND\n},
    'fully qualified call'  => qq{use POSIX();\nPOSIX::floor(1.5);\n},
    'class method call'     => qq{use Trog::Thing();\nTrog::Thing->new();\n},
    'named import called'   => qq{use List::Util qw{any};\nany { \$_ } \@x;\n},
    'one of several used'   => qq{use List::Util qw{first any};\nany { \$_ } \@x;\n},
    'default import used'   => qq{use File::Basename;\nbasename('/a/b');\n},
    'a pragma'              => qq{use strict;\nmy \$x = 1;\n},
    'warnings'              => qq{use warnings;\nmy \$x = 1;\n},
    'FindBin::libs'         => qq{use FindBin::libs;\nmy \$x = 1;\n},
    'Test::NoWarnings'      => qq{use Test::NoWarnings;\nmy \$x = 1;\n},
    'Test2 NoWarnings'      => qq{use Test2::Plugin::NoWarnings;\nmy \$x = 1;\n},
    'Mojo::Base flags'      => qq{use Mojo::Base -base, -signatures;\nmy \$x = 1;\n},
    'a version check'       => qq{use 5.014;\nmy \$x = 1;\n},
    'parent'                => qq{use parent qw{Some::Base};\nmy \$x = 1;\n},
    'constant'              => qq{use constant PI => 3;\nmy \$x = 1;\n},
    'import tag'            => qq{use POSIX qw{:sys_wait_h};\nWNOHANG();\n},
    'ampersand call'        => qq{use List::Util qw{first};\n\&first;\n},
);

foreach my $case ( sort keys %allowed ) {
    is( violations( $allowed{$case} ), 0, "$case is not a violation" );
}

is(
    violations(qq{use FindBin();  ## no critic (ProhibitUnusedImports)\nprint "hi";\n}),
    0, 'an explicit no-critic is what signs it off'
);

# The exemption list is configurable, for modules whose whole job is a side effect.
{
    my $configured = Perl::Critic->new(
        -profile         => \"[ProhibitUnusedImports]\nallow = My::Bootstrap\n",
        '-single-policy' => 'ProhibitUnusedImports',
        -severity        => 1,
        '-allow-unsafe'  => 1,
    );

    is(
        scalar $configured->critique( \qq{use My::Bootstrap();\nmy \$x = 1;\n} ),
        0, 'a configured module is exempt'
    );

    # Configuring `allow` says "this too", not "these instead" -- otherwise
    # naming one bootstrap module of your own starts reporting `use strict`.
    is(
        scalar $configured->critique( \qq{use strict;\nmy \$x = 1;\n} ),
        0, 'the default exemptions survive a configured allow'
    );
    is(
        scalar $configured->critique( \qq{use FindBin::libs;\nmy \$x = 1;\n} ),
        0, 'and so do the non-pragma ones'
    );
    is(
        scalar $configured->critique( \qq{use FindBin();\nprint "hi";\n} ),
        1, 'and nothing else got exempted along the way'
    );
}

done_testing();
