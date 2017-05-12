# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 20;
BEGIN { use_ok('Text::Cipher') };


#########################

my $domain  = join("",("a".."z"));
my $mapping = join("",("z","a".."y"));
my $obj = Text::Cipher->new($domain,$mapping);
my $trobj = Regexp::Tr->new($domain,$mapping);

# Test constructor
{
    ok($obj, "Something exists.");
    ok(ref($obj), "Variable is a reference.");
    ok(ref($obj) eq "Text::Cipher", "Variable is correct class.");
}

# Test encipher
{
    ok($obj->can("encipher"), "Method 'encipher' exists.");
    my $storage = $obj->encipher("some string");
    ok($storage, "Encipher returned something");
    ok($storage eq $trobj->trans("some string"), "Return value is correct.");
}
    
# Test encipher_scalar
{
    ok($obj->can("encipher_scalar"), "Method 'encipher_scalar' exists.");
    my $string = my $some_scalar = "some string";
    $obj->encipher_scalar(\$some_scalar);
    $trobj->bind(\$string);
    ok($some_scalar eq $string, "Return value is correct.");
}

# Test encipher_list
{
    ok($obj->can("encipher_list"), "Method 'encipher_list' exists.");
    my @list = ("and another", "and more", "yet more");
    my @bigstorage = $obj->encipher_list(@list);
    ok(scalar(@list) == scalar(@bigstorage), "Produced correct number"); 
    for my $n (0..scalar(@list)-1) {
	ok($trobj->trans($list[$n]) eq $bigstorage[$n],
	   "List encipherment ".($n+1)." correct.");
    }
}

# Test encipher_array
{
    ok($obj->can("encipher_array"), "Method 'encipher_array' exists.");
    my @tmp = my @some_array = 
	("string", "string again", "string again again");
    $obj->encipher_array(\@some_array);
    ok(scalar(@tmp) == scalar(@some_array), "Produced correct number");
    for my $n (0..scalar(@tmp)-1) {
	ok($trobj->trans($tmp[$n]) eq $some_array[$n],
	   "Array encipherment ".($n+1)." correct.");
    }
}

# Test clean
{
    ok(Text::Cipher->can("clean"), "Method 'clean' exists.");
    Text::Cipher->clean();
}

