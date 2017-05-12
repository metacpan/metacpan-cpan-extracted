use strict;
use Storable;

# init dictionary
`rm -f Cantonese.dict`;
my $dict = {pinyin => {},
    chars => {},
    words => {},
    word_index => {},
};
store($dict, "Cantonese.dict");

use eGuideDog::Dict::Cantonese;
my $dict = {};
bless $dict, 'eGuideDog::Dict::Cantonese';
eGuideDog::Dict::Cantonese::update_dict($dict);

