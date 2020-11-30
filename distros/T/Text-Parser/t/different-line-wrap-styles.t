
use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
    use_ok('Text::Parser');
    use_ok('Text::Parser::Error');
}

lives_ok {
    my $parser = Text::Parser->new( line_wrap_style => 'spice' );
    isa_ok $parser, 'Text::Parser';
    is( $parser->multiline_type, 'join_last',
        'Correctly set multiline_type to join_last' );
    $parser->add_rule( if => 'substr($1, 0, 1) eq "*"', dont_record => 1 );
    $parser->add_rule(
        if => 'uc(substr($1, 0, 1)) eq "M"',
        do => 'chomp; $_;'
    );
    $parser->multiline_type(undef);
    $parser->read('t/example-2.sp');
    is_deeply [ $parser->get_records ],
        [ "Minst net1", ],
        'Spice line-wrap settings, but changed back to undef';
    $parser->line_wrap_style('spice');
    $parser->read('t/example-2.sp');
    is_deeply(
        [ $parser->get_records ],
        ['Minst net1 net2 net3 net4 nmos l=0.09u w=0.13u'],
        'Spice unwrapping worked'
    );
}
'Spice line-wrapping tests pass';

lives_ok {
    my $parser = Text::Parser->new( line_wrap_style => 'trailing_backslash' );
    isa_ok $parser, 'Text::Parser';
    is( $parser->multiline_type, 'join_next',
        'Correctly set multiline_type to join_next' );
    $parser->read('t/continued.txt');
    is_deeply(
        [ $parser->get_records ],
        [   "Some text on this line is being continued on the next line with the back-slash character. This is more readable than having the whole text on one single line.\n"
        ],
        'Unwrapped lines with trailing backslash properly'
    );
}
'trailing_backslash line-wrapping tests pass';

lives_ok {
    my $parser = Text::Parser->new( line_wrap_style => 'slurp' );
    isa_ok $parser, 'Text::Parser';
    is( $parser->multiline_type, 'join_last', 'Correctly set unwrapper' );
    $parser->read('t/example.plaintext.txt');
    is( scalar( $parser->get_records ), 1, 'slurped in the whole file' );
}
'slurping passes correctly';

lives_ok {
    my $parser = Text::Parser->new( line_wrap_style => 'just_next_line' );
    isa_ok $parser, 'Text::Parser';
    is( $parser->multiline_type, 'join_last', 'Correctly set unwrapper' );
    $parser->read('t/example-wrapped.txt');
    is scalar( $parser->get_records ), 3,
        'slurped in the whole paragraph as one record';
}
'slurping whole paragraphs passes properly';

my $is_wrapped_routine = sub {
    my ( $self, $this_line ) = @_;
    $this_line =~ /^[~]/;
};
my $unwrap_routine = sub {
    my ( $self, $last_line, $this_line ) = @_;
    chomp $last_line;
    $last_line =~ s/\s*$//g;
    $this_line =~ s/^[~]\s*//g;
    "$last_line $this_line";
};
lives_ok {
    my $parser = Text::Parser->new( line_wrap_style => 'spice' );
    throws_ok {
        $parser->custom_line_unwrap_routines(
            is_wrapped     => $is_wrapped_routine,
            unwrap_routine => $unwrap_routine
        );
    }
    'Text::Parser::Error',
        'Throws exception for calling custom line unwrap methods when line_wrap_style is spice';
}
'custom line-wrapping routines cannot be set when line_wrap_style is not custom';

lives_ok {
    my $parser = Text::Parser->new( line_wrap_style => 'custom' );
    isa_ok $parser, 'Text::Parser';
    is( $parser->multiline_type, undef,
        'Correctly set the wrapper when line_wrap_style is explicitly set to custom'
    );
    lives_ok {
        $parser->read('t/example-custom-line-wrap.txt');
    }
    'Reads the file fine without dying even if multiline_type is undef';
    $parser->multiline_type('join_last');
    is( $parser->multiline_type, 'join_last', 'Correctly set unwrapper' );
    throws_ok {
        $parser->read('t/example-custom-line-wrap.txt');
    }
    'Text::Parser::Error';
    throws_ok {
        $parser->custom_line_unwrap_routines();
    }
    'Text::Parser::Error';
    throws_ok {
        $parser->custom_line_unwrap_routines( 1, 2, 3, 4 );
    }
    'Text::Parser::Error';
    throws_ok {
        $parser->custom_line_unwrap_routines( is_wrapped => 2, 3, 4 );
    }
    'Text::Parser::Error';
    throws_ok {
        $parser->custom_line_unwrap_routines( unwrap_routine => 2, 3, 4 );
    }
    'Text::Parser::Error';
    throws_ok {
        $parser->custom_line_unwrap_routines(
            unwrap_routine => 2,
            is_wrapped     => 4
        );
    }
    'Text::Parser::Error';
    my $unwrap_routine = sub {
        my ( $self, $last_line, $this_line ) = @_;
        chomp $last_line;
        $last_line =~ s/\s*$//g;
        $this_line =~ s/^[~]\s*//g;
        "$last_line $this_line";
    };
    $parser->custom_line_unwrap_routines(
        is_wrapped     => $is_wrapped_routine,
        unwrap_routine => $unwrap_routine,
    );
    $parser->_unwrap_routine(undef);
    throws_ok {
        $parser->read('t/example-custom-line-wrap.txt');
    }
    'Text::Parser::Error';
    $parser->_unwrap_routine($unwrap_routine);
    $parser->read('t/example-custom-line-wrap.txt');
    is_deeply [ $parser->get_records ],
        [
        "This is a long line that is wrapped around with a custom character - the tilde. It is unusual, but hey, we're showing an example.\n"
        ], 'Custom line-wrapped file is now parsed properly';
    $parser->line_wrap_style(undef);
    $parser->read('t/example-custom-line-wrap.txt');
    is_deeply [ $parser->get_records ],
        [
        "This is a long line that is wrapped around with a custom\n",
        "~ character - the tilde. It is unusual, but hey, we\'re\n",
        "~ showing an example.\n",
        ],
        'You can unset line-unwrapping';
}
'custom line unwrapping works well';

lives_ok {
    my $parser = Text::Parser->new();
    $parser->line_wrap_style(undef);
    isa_ok $parser, 'Text::Parser';
    is $parser->line_wrap_style, undef, 'Stays undef if nothing is set';
}
'Just bring coverage to 100% for the branch';

lives_ok {
    my $parser = Text::Parser->new();
    $parser->custom_line_unwrap_routines(
        is_wrapped     => $is_wrapped_routine,
        unwrap_routine => $unwrap_routine,
    );
    $parser->read('t/example-custom-line-wrap.txt');
    is_deeply [ $parser->get_records ],
        [
        "This is a long line that is wrapped around with a custom\n",
        "~ character - the tilde. It is unusual, but hey, we\'re\n",
        "~ showing an example.\n",
        ],
        'Line-unwrapping is not enabled unless multiline_type is set by the user';
}
'Everything works even if you forget to set multiline_type';

done_testing;
