
use Test;
BEGIN { plan tests => 5 };

use base 'Waft';
use strict;
BEGIN { eval { require warnings } ? 'warnings'->import : ( $^W = 1 ) }

use lib 't';
require Waft::Test::STDERR;

{
    my $stderr = Waft::Test::STDERR->new;

    __PACKAGE__->warn; my $line = __LINE__;

    ok( $stderr->get =~ /\Asomething's wrong at \Q$0\E line $line\./ms );
}

{
    my $stderr = Waft::Test::STDERR->new;

    __PACKAGE__->warn(q{}); my $line = __LINE__;

    ok( $stderr->get =~ /\Asomething's wrong at \Q$0\E line $line\./ms );
}

{
    my $stderr = Waft::Test::STDERR->new;

    __PACKAGE__->warn('error'); my $line = __LINE__;

    ok( $stderr->get =~ /\Aerror at \Q$0\E line $line\./ms );
}

{
    my $stderr = Waft::Test::STDERR->new;

    __PACKAGE__->warn(q{}, undef); my $line = __LINE__;

    ok( $stderr->get =~ /\bsomething's wrong at \Q$0\E line $line\./ms );
}

{
    my $stderr = Waft::Test::STDERR->new;

    __PACKAGE__->warn('error', undef); my $line = __LINE__;

    ok( $stderr->get =~ /\berror at \Q$0\E line $line\./ms );
}
