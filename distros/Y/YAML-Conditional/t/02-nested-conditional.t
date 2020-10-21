use Test::More;

use YAML::Conditional;

my $struct = q|
else:
    then:
        ghi: 789
        nested:
            if:
                eq: test
                key: other
                then:
                    abc: 123
                    nested_array:
                    - if:
                            elsif:
                                elsif:
                                    key: again
                                    ne: test
                                    then:
                                        level: 3
                                key: again
                                ne: yay
                                then:
                                    level: 2
                            key: again
                            ne: yay
                            then:
                                level: 1
elsif:
    key: test
    m: other
    then:
        def: 456
if:
    key: test
    m: test
    then:
        abc: 123
overlord: 1
|;

my $compiled = YAML::Conditional->new->compile($struct, { 
	test => "again", 
	other => "test", 
	again => "yay" 
}, 1);

my $hash = {
	overlord => 1,
	ghi => 789,
	nested => {
		abc => 123,
		nested_array => [
			{
				level => 3
			}
		],
	}
};

is_deeply($compiled, $hash);

done_testing;
