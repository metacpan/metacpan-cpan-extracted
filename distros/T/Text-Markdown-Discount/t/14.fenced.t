use strict;
use warnings;
use utf8;
use Test::More;

use Text::Markdown::Discount;

is(Text::Markdown::Discount::markdown(
    '```javascript
console.log("hi")
```'), '<pre><code class="javascript">console.log("hi")
</code></pre>
');

done_testing;
