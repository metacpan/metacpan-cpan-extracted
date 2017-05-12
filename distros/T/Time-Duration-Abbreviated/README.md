[![Build Status](https://travis-ci.org/moznion/Time-Duration-Abbreviated.png?branch=master)](https://travis-ci.org/moznion/Time-Duration-Abbreviated) [![Coverage Status](https://coveralls.io/repos/moznion/Time-Duration-Abbreviated/badge.png?branch=master)](https://coveralls.io/r/moznion/Time-Duration-Abbreviated?branch=master)
# NAME

Time::Duration::Abbreviated - Describe time duration in abbreviated English

# SYNOPSIS

    use Time::Duration::Abbreviated;

    duration(12345, 2); # => "3 hrs 26 min"
    earlier(12345, 2);  # => "3 hrs 26 min ago"
    later(12345, 2);    # => "3 hrs 26 min later"

    duration_exact(12345); # => "3 hrs 25 min 45 sec"
    earlier_exact(12345);  # => "3 hrs 25 min 45 sec ago"
    later_exact(12345);    # => "3 hrs 25 min 45 sec later"

# DESCRIPTION

Time::Duration::Abbreviated is a abbreviated version of [Time::Duration](https://metacpan.org/pod/Time::Duration).

# SEE ALSO

[Time::Duration](https://metacpan.org/pod/Time::Duration)

# LICENSE

Copyright (C) moznion.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

moznion <moznion@gmail.com>
