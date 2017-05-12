use strict;
use Test::More tests => 27;
BEGIN { use_ok('Text::Printf') };

# Make sure the documentation examples are correct,
# so as not to confuse anyone.

sub begins_with
{
    my ($actual, $expected, $test_name) = @_;

    $actual = substr($actual, 0, length $expected);
    @_ =  ($actual, $expected, $test_name);
    goto &is;
}


my ($template, $letter1, $letter2);

# Doco from the README
eval
{
    $template = Text::Printf->new(<<END_TEMPLATE);
Dear {{to}},
    Have a {{day_type}} day.
Your {{relation}},
{{from}}
END_TEMPLATE
};

is $@, q{},   q{Simple template creation didn't die};

eval
{
    $letter1 = $template->fill (
        {to       => 'Professor Dumbledore',
         relation => 'friend',
         day_type => 'swell',
         from     => 'Harry',
    });
};

is $@, q{},     q{Simple template fill didn't die};
is $letter1, <<END_RESULT,  q{First simple template fill worked.};
Dear Professor Dumbledore,
    Have a swell day.
Your friend,
Harry
END_RESULT

eval
{
    $letter2 = $template->fill (
        {to       => 'Lord Voldemort',
         relation => 'sworn enemy',
         day_type => 'rotten',
         from     => 'Harry',
    });
};

is $@, q{},     q{Second simple template fill didn't die};
is $letter2, <<END_RESULT,  q{Second simple template fill worked.};
Dear Lord Voldemort,
    Have a rotten day.
Your sworn enemy,
Harry
END_RESULT


# Doco from the POD

my ($book_t, $bibl_1, $bibl_2, $bibl_3, $bibl_4);
eval
{
    $book_t = Text::Printf->new('<i>{{title}}</i>, by {{author}}');
};

is ($@, q{}, q{No exception for bibliography template});

eval
{
    $bibl_1 = $book_t->fill({author => "Stephen Hawking",
                             title  => "A Brief History of Time"});
};

is ($@, q{}, q{No exception for creating bibliography 1});

is ($bibl_1, "<i>A Brief History of Time</i>, by Stephen Hawking",
    q{Correct result for bibliography 1});

eval
{
    $bibl_2 = $book_t->fill({author => "Dr. Seuss",
                             title  => "Green Eggs and Ham"});
};

is ($@, q{}, q{No exception for creating bibliography 2});

is ($bibl_2, "<i>Green Eggs and Ham</i>, by Dr. Seuss",
    q{Correct result for bibliography 2});

eval
{
    $bibl_3 = $book_t->fill({author => 'Isaac Asimov'});
};

my $x = $@;
isnt ($x, q{}, q{Exception when creating bibliography 3});

ok (Text::Printf::X->caught(), q{Proper base exception caught});
ok (Text::Printf::X::KeyNotFound->caught(), q{Proper specific exception caught});

is_deeply($x->symbols, ['title'], q{Missing symbols returned});

begins_with ($@, q{Could not resolve the following symbol: title},
             q{Exception-as-string formatted properly});

eval
{
    $bibl_4 = $book_t->fill({author => 'Isaac Asimov',
                             title  => $DONTSET });
};

is ($@, q{}, q{No exception for creating bibliography 4});

is ($bibl_4, "<i>{{title}}</i>, by Isaac Asimov",
    q{Correct result for bibliography 4});


# Add'l docs added 8/12/2005

my ($fh1, $fh2, $report_line, $line);
eval
{
    $report_line = Text::Printf->new('{{Name:-20s}} {{Grade:10d}}');
    open $fh1, '>fh1' or die "Can't write 'fh1': $!";
    open $fh2, '>fh2' or die "Can't write 'fh2': $!";
    select $fh1;
};

my $eval1 = $@;

eval
{
    # Example using format specification:
    print $report_line->fill({Name => 'Susanna', Grade => 4});
    # prints "Susanna                       4"

    $line = tsprintf '{{Name:-20s}} {{Grade:10d}}', {Name=>'Gwen', Grade=>6};
    # $line is now "Gwen                          6"

    tprintf $fh2, '{{number:-5.2f}}', {number => 7.4};
    # prints " 7.40" to STDERR.
};

my $eval2 = $@;

print "--end-of-test";   # ensure $fh1 still selected
select STDOUT;

is ($eval1, q{}, q{Set up for format/printf tests});
is ($eval2, q{}, q{Execute format/printf tests});

my ($str1, $str2);
eval
{
    close $fh1 or die;
    close $fh2 or die;
    undef $fh1;
    undef $fh2;
    open $fh1, '<fh1' or die "Can't read 'fh1': $!";
    open $fh2, '<fh2' or die "Can't read 'fh2': $!";

    local $/ = undef;
    $str1 = <$fh1>;
    $str2 = <$fh2>;
    close $fh1 or die;
    close $fh2 or die;
};

is ($@, q{}, q{Grabbed test resuts});

is ($str1, "Susanna                       4--end-of-test", q{Susanna okay});
is ($line, "Gwen                          6", q{Gwen okay});
is ($str2, "7.40 ", q{7.40 okay});

eval
{
    unlink 'fh1';
    unlink 'fh2';
};
is ($@, q{}, q{removed test files okay});


# Extended formatting example, added 9/8/2005
my $str;
eval
{
    $str = tsprintf '{{widgets:%10d:,}} at {{price:%.2f:,$}} each',
                     {widgets => 1e6, price => 1234};
};
is ($@, q{}, q{Extended format printf: no error});
is ($str, ' 1,000,000 at $1,234.00 each', 'Extended format printf: correct value.');
