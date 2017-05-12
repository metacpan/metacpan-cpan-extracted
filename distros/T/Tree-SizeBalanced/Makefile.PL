use 5.008009;
use ExtUtils::MakeMaker;

my @key = qw(int num str any);
my @value = qw(void int num any);
my %shorter = (qw(
    int i
    num n
    str s
    any a
    void
), '');
my %type_name = (
    'int' => 'signed integers (32bits or 64bits according to your perl version)',
    'num' => 'numeric numbers (floating point numbers)',
    'str' => 'strings',
    'any' => 'any scalars',
);

my @generated_file;

my @method;
{
    my $f;
    open $f, 'SizeBalanced.xs.gen';
    local $/;
    my $xs = <$f>;
    close $f;

    my($static_code, $member_proto) = $xs =~ /(.*\nINCLUDE:.*?\n)(.*)/s;

    @method = $member_proto =~ /(\w+) *\(.*\)/g;

    open $f, '>SizeBalanced.xs';
    print $f $static_code;
    for my $key (@key) {
        for my $value (@value) {
            my $member_proto = $member_proto;
            $member_proto =~ s[(\w+) *\((.*)\)]{
                my($method, $proto) = ($1, $2);
                my $args = $proto;
                $args =~ s/(^|,)[^,]*?(\w+)\s*(?:|=[^,]*)(?=$|,)/$1$2/g;

                "void\n".
                "$method\_$key\_$value($proto)\n".
                "    PPCODE:\n".
                "        SP = $method\_$key\_$value(aTHX_ SP, $args);\n"
            }ge;
            print $f $member_proto;
        }
    }
    close $f;

    push @generated_file, 'SizeBalanced.xs';
}

mkdir 'lib/Tree/SizeBalanced';
for my $key (@key) {
    for my $value (@value) {
        my $f;
        open $f, ">lib/Tree/SizeBalanced/$key\_$value.pm";

        print $f <<".";
package Tree::SizeBalanced::$key\_$value;

use strict;
use warnings;

use Tree::SizeBalanced;

.
        for my $method (@method) {
            print $f "*$method = \\&Tree::SizeBalanced::Core::$method\_$key\_$value;\n";
        }
        print $f "\n1;\n";

        close $f;

        push @generated_file, "lib/Tree/SizeBalanced/$key\_$value.pm";
    }
}

{
    my $insert_code = <<'.';
our @EXPORT_OK = qw(sbtree);
our %EXPORT_TAGS = (
    'all' => ['sbtree'],
    'short' => ['sbtree'],
    'long' => [],
);

.
    for my $key (@key) {
        for my $value (@value) {
            my $package = "Tree::SizeBalanced::$key\_$value";
            my $short = "sbtree$shorter{$key}$shorter{$value}";
            my $long = "sbtree_$key\_$value";
            my $proto = $key eq 'any' ? '&' : '';
            my $new_trailing = $key eq 'any' ? " sub { \$a cmp \$b }" : '';
            my $func_trailing = $key eq 'any' ? " { \$a cmp \$b }" : '';

            my($desc, $key_value_arg, $key_value_ret);
            if( $value eq 'void' ) {
                $desc = "Tree set with key type $type_name{$key}.";
                $key_value_arg = '($key)';
                $key_value_ret = '$key or ($key1, $key2, ...)';
            } else {
                $desc = "Tree map with key type $type_name{$key} and value type $type_name{$value}.";
                $key_value_arg = '($key, $value)';
                $key_value_ret = '$key or ($key1, $value1, $key2, $value2, ...)';
            }

            $insert_code .= <<".";

=head3 $package

$desc

=over 4

=item \$tree = $package\->new$new_trailing

=item \$tree = $long$func_trailing

=item \$tree = $short$func_trailing

Creat a new empty tree.

=item \$tree->insert$key_value_arg

=item \$tree->insert_after$key_value_arg

Insert an entry into the tree.
If there are any entries with the same key size,
insert the new one after them.

=item \$tree->insert_before$key_value_arg

Insert an entry into the tree.
If there are any entries with the same key size,
insert the new one before them.

=item \$tree->delete(\$key)

=item \$tree->delete_last(\$key)

Delete one entry whose key is equal to \$key.
If there ary more than one entry with the same key size,
delete the last inserted one.

=item \$tree->delete_first(\$key)

Delete one entry whose key is equal to \$key.
If there ary more than one entry with the same key size,
delete the first inserted one.

=item \$size = \$tree->size

Get the number of entries in the tree

=item $key_value_ret = \$tree->find(\$key, \$limit=1)

=item $key_value_ret = \$tree->find_first(\$key, \$limit=1)

Get entries with key sizes equal to \$key,
from the first inserted one to the last inserted one.

The optional \$limit (default 1) indicates the maximum entry number you will get,
\$limit=-1 means unlimited.

=item $key_value_ret = \$tree->find_last(\$key, \$limit=1)

Get entries with key sizes equal to \$key,
from the last inserted one to the first inserted one.

The optional \$limit (default 1) indicates the maximum entry number you will get,
\$limit=-1 means unlimited.

=item $key_value_ret = \$tree->find_lt(\$key, \$limit=1)

Get entries, whose keys are smaller than \$key, from the largest entry.

The optional \$limit (default 1) indicates the maximum entry number you will get,
\$limit=-1 means unlimited.

=item $key_value_ret = \$tree->find_le(\$key, \$limit=1)

Get entries, whose keys are smaller than or equal to \$key, from the largest entry.

The optional \$limit (default 1) indicates the maximum entry number you will get,
\$limit=-1 means unlimited.

=item $key_value_ret = \$tree->find_gt(\$key, \$limit=1)

Get entries, whose keys are greater than \$key, from the smallest one.

The optional \$limit (default 1) indicates the maximum entry number you will get,
\$limit=-1 means unlimited.

=item $key_value_ret = \$tree->find_ge(\$key, \$limit=1)

Get entries, whose keys are greater than or equal to \$key, from the smallest one.

The optional \$limit (default 1) indicates the maximum entry number you will get,
\$limit=-1 means unlimited.

=item $key_value_ret = \$tree->find_gt_lt(\$lower_key, \$upper_key)

Get entries, whose keys are greater than \$lower_key and smaller than \$upper_key,
from the smallest one to the largest one.

=item $key_value_ret = \$tree->find_gt_le(\$lower_key, \$upper_key)

Get entries, whose keys are greater than \$lower_key and smaller than or equal to \$upper_key,
from the smallest one to the largest one.

=item $key_value_ret = \$tree->find_ge_lt(\$lower_key, \$upper_key)

Get entries, whose keys are greater than or equal to \$lower_key and smaller than \$upper_key,
from the smallest one to the largest one.

=item $key_value_ret = \$tree->find_ge_le(\$lower_key, \$upper_key)

Get entries, whose keys are greater than or equal to \$lower_key and smaller than or equal to \$upper_key,
from the smallest one to the largest one.

=item $key_value_ret = \$tree->find_min(\$limit=1)

Get entries from the one with smallest key.
If there are more than one entries with smallest key,
begin from the first inserted one.

The optional \$limit (default 1) indicates the maximum entry number you will get,
\$limit=-1 means unlimited.

=item $key_value_ret = \$tree->find_max(\$limit=1)

Get entries from the one with largest key.
If there are more than one entries with smallest key,
begin from the last inserted one.

The optional \$limit (default 1) indicates the maximum entry number you will get,
\$limit=-1 means unlimited.

=item $key_value_ret = \&tree->skip_l(\$offset, \$limit=1)

Get the first entry from one with the smallest key after skipping \$offset entries.

The optional \$limit (default 1) indicates the maximum entry number you will get,
\$limit=-1 means unlimited.

=item $key_value_ret = \&tree->skip_g(\$offset, \$limit=1)

Get the first entry from one with the largest key after skipping \$offset entries.

The optional \$limit (default 1) indicates the maximum entry number you will get,
\$limit=-1 means unlimited.

=item \$count = \$tree->count_lt(\$key)

Get the number of entries whose keys are smaller than \$key.

=item \$count = \$tree->count_le(\$key)

Get the number of entries whose keys are smaller than or equal to \$key.

=item \$count = \$tree->count_gt(\$key)

Get the number of entries whose keys are greater than \$key.

=item \$count = \$tree->count_ge(\$key)

Get the number of entries whose keys are greater than or equal to \$key.

=item \$dump_str = \$tree->dump

Get a string which represent the whole tree structure. For debug use.

=item (\$order_consistent, \$size_consistent, \$balanced) = \$tree->check

Check the tree property. For debug use.

=item \$ever_height = \$tree->ever_height

Get the maximum height the tree has ever been. For debug use

=back

=cut

use Tree::SizeBalanced::$key\_$value;

sub $long($proto) {
    unshift \@_, '$package';
    goto \\&$package\::new;
}

sub $short($proto) {
    unshift \@_, '$package';
    goto \\&$package\::new;
}

push \@EXPORT_OK, qw($long $short);
push \@{\$EXPORT_TAGS{'all'}}, qw($long $short);
push \@{\$EXPORT_TAGS{'short'}}, qw($short);
push \@{\$EXPORT_TAGS{'long'}}, qw($long);

.
        }
    }
    $insert_code .= <<".";
sub sbtree(;&) {
    if( ref($_[0]) eq 'CODE' ) {
        goto \\&sbtreeaa;
    } else {
        goto \\&sbtreeia;
    }
}

sub new {
    shift;
    if( ref($_[0]) eq 'CODE' ) {
        goto \\&sbtreeaa;
    } else {
        goto \\&sbtreeia;
    }
}
.

    my $f;
    open $f, 'lib/Tree/SizeBalanced.pm.gen';
    local $/;
    my $src = <$f>;
    close $f;

    $src =~ s/"INSERT POINT";/$insert_code/;

    open $f, '>lib/Tree/SizeBalanced.pm';
    print $f $src;
    close $f;

    push @generated_file, 'lib/Tree/SizeBalanced.pm';
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Tree::SizeBalanced',
    VERSION_FROM      => 'lib/Tree/SizeBalanced.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Tree/SizeBalanced.pm', # retrieve abstract from module
    AUTHOR            => 'Cindy Wang (CindyLinz) <cindy@cpan.org>',
    #LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '-std=c99', #'-g -O0', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    OBJECT            => '$(O_FILES)', # link all the C files too
    clean             => {FILES => \@generated_file},
);
if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw());
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Tree::SizeBalanced',
                                     NAMES        => \@names,
                                     DEFAULT_TYPE => 'IV',
                                     C_FILE       => 'const-c.inc',
                                     XS_FILE      => 'const-xs.inc',
                                  );

}
else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}

