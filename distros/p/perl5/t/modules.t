use lib (-e 't' ? 't' : 'test') . '/lib';

use Test::More 0.88;

BEGIN {
    # in the unlikely event someone is running this on a perl prior to 5.6.1
    plan skip_all => 'File::Temp is not installed' unless eval { require File::Temp };
}
File::Temp->import('tempfile');

use perl5 ();
use Module::Runtime qw< require_module >;


my @TESTS =
(
##  Load this module        with these args         and then run this code  which should produce this result.
##
##                          (no args means no       (no single quotes
##                          import list, and *not*  in this code!!!)        (undef means no output/errors)
##                          an empty list!)

#     ['strict',              [],                     '$foo = 1',             qr/requires explicit package name/,     ],
#     ['warnings',            [ FATAL => 'all' ],     '6 + "foo"',            qr/Argument "foo" isn't numeric/,       ],
#     ['TryCatch',            [],                     'try {die} catch {};',  undef,                                  ],
    ['Path::Class',         [],                     'dir("foo", "bar")',    undef,                                  ],
    ['Const::Fast',         [],                     'const my $x => 1',     undef,                                  ],
    ['MooseX::Declare',     [],                     'class Foo {}',         undef,                                  ],
    ['Method::Signatures',  [],                     'func foo ($x) {}',     undef,                                  ],
);


foreach (@TESTS)
{
    my ($module, $args, $code, $pattern) = @$_;
    my $imports = @$args ? "'$module' => [" . join(',', @$args) . "]" : "'$module'";

    SKIP:
    {
        # don't try to test this module if the user doesn't have it
        # (if you're patching, however, please make sure you have all the modules)
        eval { require_module($module) } or skip "$module required for this test", 1;

        # okay, we're going to create a temp file and build a perl5 subclass that imports the module
        # must use template arg to tempfile, else might end up with modules that start with digits
        # must put the file in our test lib dir
        # has to end with .pm
        # should get gone when the test is over
        my $t = -d 't' ? 't' : 'test';
        my ($fh, $name) = tempfile( 'testXXXXX', DIR => "$t/lib/perl5", SUFFIX => '.pm', UNLINK => 1 );
        $name =~ m{/(\w+)\.pm};
        $base = $1;

        # now build the contents of our temporary module
        # this is fairly basic: base of the classname is the base of the filename we built
        # imports() is the module plus any args (built up above)
        my $test_pkg = qq{
            package perl5::$base;
            use base 'perl5';
            sub imports { $imports }
            1;
        };

        # now create the actual file
        # not sure if the close is strictly necessary, but it can't hurt
        print $fh $test_pkg;
        close($fh);

        # use a separate Perl instance to test the module importing
        # that's the only way to get this to work (trust me)
        # don't want to use 2>&1 here for fear it won't work on Windows
        # so just eval the code and print the error
        # no error, no output
        my $err = `$^X -It/lib -e 'use perl5-$base; eval q{$code}; print \$\@'`;

        # now just test our output
        # it either needs to match our pattern, or needs to be empty
        my $testname = "successful import of $module";
        if (defined $pattern)
        {
            like $err, $pattern, $testname;
        }
        else
        {
            is $err, '', $testname;
        }
    }
}


done_testing;
