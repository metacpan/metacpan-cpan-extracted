# NAME

WWW::StationJp::API - It's a StationJP Module.

# SYNOPSIS

    use WWW::StationJp::API;

    my $station = new WWW::StationJp::API();

     my $line = $station->line({linecode => 11302});
    
    print $line->{line_name};

# DESCRIPTION

WWW::StationJp::API is a StationJP Module.

# LICENSE

Copyright (C) sue7ga.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

sue7ga <sue77ga@gmail.com>
