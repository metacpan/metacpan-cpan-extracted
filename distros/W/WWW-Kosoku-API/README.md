# NAME

WWW::Kosoku::API - Kosoku WebService API

# SYNOPSIS
    use WWW::Kosoku::API;

    my $kosoku = WWW::Kosoku::API->new(f => '渋谷',t => '浜松',c => '普通車');

    print $kosoku->{c} #=> 普通車
    print $kosoku->get_route_count #=> 20

    for my $subsection(@{$kosoku->get_subsection_by_routenumber_and_sectionnumber(1,0)}){
         print $subsection->{Length};
         print $subsection->{Time};
         print $subsection->{Road};
         print $subsection->{To};
         print $subsection->{From}; 
    }

# DESCRIPTION

WWW::Kosoku::API is Kosoku WebService API.

# LICENSE

Copyright (C) sue7ga.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

sue7ga <sue77ga@gmail.com>
