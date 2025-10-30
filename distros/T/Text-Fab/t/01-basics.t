# t/01-core.t
use strict;
use warnings;
use Test::More;
use Test::Exception;

use_ok('Text::Fab');

# Test 1: Basic instantiation
my $fab = Text::Fab->new();
isa_ok($fab, 'Text::Fab');

# Test 2: Basic section reshuffling
my $input2 = <<'END';
#target_section A
This is A.
#target_section B
This is B.
#emb A in _main
END
$fab = Text::Fab->new();
$fab->process_string($input2);
is($fab->assemble('_main:B'), "This is B.\nThis is A.", 'Test 2: Basic reshuffling assembles correctly');
is(scalar keys %{$fab->{sections}{_main}}, 2, 'Test 2 (Armor): Only expected sections exist');

# Test 3: Custom Parser
my $default_callbacks = Text::Fab->new->cfg__get('Fab/callbacks');
my $custom_parser = sub {
    my ($fab, $buffer, $offset) = @_;
    if (substr($buffer, $offset) =~ /^SET (\w+) TO (\w+)/) {
        $fab->cfg__set($1, $2);
        return $offset + length($&);
    }
    my $line_end = index($buffer, "\n", $offset);
    return $line_end == -1 ? length($buffer) : $line_end + 1;
};
my $custom_config = {
    'Fab/callbacks' => {
        %$default_callbacks,
        interleaver      => sub { my $p=index($_[0],'SET ',$_[1]); $p==-1?undef:$p },
        directive_parser => $custom_parser,
    }
};
$fab = Text::Fab->new(config => $custom_config);
$fab->process_string("Content A. SET mykey TO myvalue. Content B.");
is($fab->cfg__get('mykey'), 'myvalue', 'Test 3: Custom parser sets config value');
my $full_content = join '', map { $_->[0] eq 'text' ? $_->[1] : '' } @{$fab->{sections}{_main}{body}};
# FIX: The expected string must match the actual, correct output.
is($full_content, 'Content A. . Content B.', 'Test 3 (Armor): Core loop processes all content chunks');

# Test 4: Configuration set (using default parser)
my $input4 = '#set site_title=My Site';
$fab = Text::Fab->new();
$fab->process_string($input4);
is($fab->cfg__get('site_title'), 'My Site', 'Test 4: #set directive via default parser');
ok(!exists $fab->{sections}{_main}, 'Test 4 (Armor): #set creates no output');

# Test 5: Grouping reverts configuration
my $input5 = "#set foo=initial\n#start_group test\n#set foo=changed\n#end_group test";
$fab = Text::Fab->new();
$fab->process_string($input5);
is($fab->cfg__get('foo'), 'initial', 'Test 5: Grouping primitives work');

# Test 6: Simple inheritance
my $input6 = "#target_section body in Parent\nParent Content\n#set_parents Child Parent";
$fab = Text::Fab->new();
$fab->process_string($input6);
is($fab->assemble('Child:body'), 'Parent Content', 'Test 6: Simple inheritance');

# Test 7: Inheritance with override
my $input7 = "#target_section body in Parent\nParent Content\n#target_section body in Child\nChild Content\n#set_parents Child Parent";
$fab = Text::Fab->new();
$fab->process_string($input7);
is($fab->assemble('Child:body'), 'Child Content', 'Test 7: Inheritance with override');

# Test 8: Circular dependency detection
my $input8 = "#target_section body in A\n#emb body in A";
$fab = Text::Fab->new();
$fab->process_string($input8);
throws_ok { $fab->assemble('A:body') } qr/Circular dependency/, 'Test 8: Circular dependency detection';

# Test 9: Consecutive directives
my $input9 = "#set key1=val1\n#set key2=val2";
$fab = Text::Fab->new();
$fab->process_string($input9);
is($fab->cfg__get('key1'), 'val1', 'Test 9: Consecutive directives - first is processed');
is($fab->cfg__get('key2'), 'val2', 'Test 9: Consecutive directives - second is processed');

# Test 10: Malformed/unknown directives are fatal by default
my $input10_malformed = "# set key=val";
my $input10_unknown = "#bogusdirective foo";
throws_ok { Text::Fab->new->process_string($input10_malformed) } qr/malformed_directive/, 'Test 10: Malformed directive dies by default';
throws_ok { Text::Fab->new->process_string($input10_unknown) } qr/unknown_directive/, 'Test 10: Unknown directive dies by default';

# Test 11: Custom error handler
my $error_collector = sub {
    my ($fab, $type, $details) = @_;
    $fab->cfg__append('collected_errors', "$type: $details->{line}");
};
my $custom_error_config = {
    'Fab/callbacks' => {
        %$default_callbacks,
        error_handler => $error_collector,
    },
    'Fab/list_keys' => { collected_errors => 1 }
};
$fab = Text::Fab->new(config => $custom_error_config);
lives_ok { $fab->process_string("#bogus\n# set foo") } 'Test 11: Processing lives with custom error handler';
is_deeply($fab->cfg__get('collected_errors'),
    [ 'unknown_directive: #bogus', 'malformed_directive: # set foo' ],
    'Test 11 (Armor): Custom error handler collected errors correctly');

# Test 12: Mismatched group end is not yet implemented (and doesn't die)
$fab = Text::Fab->new();
$fab->group__start('flavor_A');
lives_ok { $fab->group__end('flavor_B') } 'Test 12: Mismatched group__end lives (feature unimplemented)';

# Test 13: Dangling end_group dies, as expected
dies_ok { Text::Fab->new->process_string('#end_group') } 'Test 13: Dangling #end_group dies';

done_testing();