# Time::Moment::Epoch
Convert various epoch times to `Time::Moment` times in Perl.

For example, running this code

```perl
#!/usr/bin/env perl

use v5.10;
use strict;
use warnings;
use Time::Moment::Epoch;

say Time::Moment::Epoch::unix(1234567890);

say Time::Moment::Epoch::chrome(12879041490654321);
```

would give

```
2009-02-13T23:31:30Z
2009-02-13T23:31:30.654321Z
```

**Update:** Now there are functions in the other direction too! For example, running this

```perl
#!/usr/bin/env perl

use v5.10;
use strict;
use warnings;
use Time::Moment::Epoch;

say Time::Moment::Epoch::to_unix('2009-02-13T23:31:30Z');

say Time::Moment::Epoch::to_chrome('2009-02-13T23:31:30.654321Z');
```

gives

```
1234567890
12879041490654321
```

## Contributors

[@noppers](https://github.com/noppers) originally worked out how to do the Google Calendar calculation.

[@regina-verbae](https://github.com/regina-verbae) made numerous improvements to the code, tests, and documentation.

[@iopuckoi](https://github.com/iopuckoi) added a link and fixed quotes.

## History

This project was first done with [DateTime](http://p3rl.org/DateTime). Then it was refactored to use [Time::Piece](http://p3rl.org/Time::Piece), which is in the standard library. When I found out about [Time::Moment](http://p3rl.org/Time::Moment), I just had to refactor it again. Dependencies be damned-- I like this one the best!

## See Also

See [the Time::Moment::Epoch web page](http://oylenshpeegul.github.io/Time-Moment-Epoch/) for motivation.

[Time::Moment::Epoch](https://metacpan.org/pod/Time::Moment::Epoch/) is now available on CPAN.

There are also similar things in
- [Go](https://github.com/oylenshpeegul/epochs)
- [Elixir](https://github.com/oylenshpeegul/Epochs-elixir)
- [PowerShell](https://github.com/oylenshpeegul/Epochs-powershell)
- [Rust](https://github.com/oylenshpeegul/Epochs-rust)
