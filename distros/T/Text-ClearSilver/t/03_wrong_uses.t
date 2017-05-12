#!perl -w

use strict;
use Test::More;

use Test::Requires qw(Mouse::Meta::Class);
use Text::ClearSilver;

note "for Text::ClearSilver::HDF";
foreach my $method(Mouse::Meta::Class->initialize('Text::ClearSilver::HDF')->get_method_list){
    next if $method eq 'new';
    next if $method eq uc($method); # special methods such as CLONE

    eval {
        Text::ClearSilver::HDF->$method();
    };
    isnt $@, '', "call $method as a class method";

    eval {
        Text::ClearSilver::HDF->$method("");
    };
    isnt $@, '', "call $method as a class method";

    eval {
        Text::ClearSilver::HDF->$method("", "");
    };
    isnt $@, '', "call $method as a class method";
}

note "for Text::ClearSilver::CS";
foreach my $method(Mouse::Meta::Class->initialize('Text::ClearSilver::CS')->get_method_list){
    next if $method eq 'new';
    next if $method eq 'bootstrap';
    next if $method eq uc($method); # special methods such as CLONE

    eval {
        Text::ClearSilver::CS->$method();
    };
    isnt $@, '', "call $method as a class method";

    eval {
        Text::ClearSilver::CS->$method("");
    };
    isnt $@, '', "call $method as a class method";

    eval {
        Text::ClearSilver::CS->$method("", "");
    };
    isnt $@, '', "call $method as a class method";
}

eval {
    my $cs = Text::ClearSilver::CS->new({ foo => 'bar' });
    $cs->parse_string("<?cs var:foo"); # syntax error
};
like $@, qr/\b ParseError \b/xms;

note "for Text::ClearSilver";

eval {
    Text::ClearSilver->new(qw(foo bar baz));
};
like $@, qr/odd number of parameters/, 'parameters';

eval {
    Text::ClearSilver->new([]);
};
like $@, qr/must be a HASH ref/, 'parameters';

my $tcs = Text::ClearSilver->new();

eval {
    $tcs->process($0, {}, \*STDOUT, qw(foo bar baz));
};
like $@, qr/odd number of parameters/;

eval {
    $tcs->process($0, {}, \*STDOUT, []);
};
like $@, qr/must be a HASH ref/;

eval {
    $tcs->process(\'<?cs var:foo', {});
};
like $@, qr/\b ParseError \b/xms, 'check error';

done_testing;
