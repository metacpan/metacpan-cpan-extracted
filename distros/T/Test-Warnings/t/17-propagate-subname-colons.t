use strict;
use warnings;

# checks handling of a warning handler named '::warning_capturer'

my $code = do {
    open(my $fh, 't/14-propagate-subname.t') or die "cannot open t/14-propagate-subname.t for reading: $!";
    local $/;
    <$fh>
};

$code =~ s/\$SIG\{__WARN__\} = 'warning_capturer'/\$SIG\{__WARN__\} = '::warning_capturer'/;

eval $code;
die $@ if $@;
