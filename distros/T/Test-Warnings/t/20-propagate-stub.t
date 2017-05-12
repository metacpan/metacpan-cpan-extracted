use strict;
use warnings;

my $code = do {
    open(my $fh, 't/19-propagate-nonexistent-subname.t') or die "cannot open t/19-propagate-nonexistent-subname.t for reading: $!";
    local $/;
    <$fh>
};

$code =~ s/(use Test::More;)/$1\n\nsub does_not_exist;/;

eval $code;
die $@ if $@;
