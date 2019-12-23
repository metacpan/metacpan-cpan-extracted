# NAME

Text::Hyphen::GenderInclusive - get hyphenation positions with inclusive gender markers

# SYNOPSIS

This module handles words with inclusive gender markers.

    use Text::Hyphen::GenderInclusive;
    my $hyphenator = Text::Hyphen::GenderInclusive->new(class => 'Text::Hyphen::DE');
    print $hyphenator->hyphenate("Arbeiter*innen", '-');

See [Text::Hyphen](https://metacpan.org/pod/Text::Hyphen) for the interface documentation.

# ATTRIBUTES

- class

    Base class for hyphenation. This attribute is required.

- re

    Regexp that matches the gender markers. Defaults to _\[\*:\_\]_.

# COPYRIGHT AND LICENSE 

Copyright 2019 Mario Domgoergen \`<mario@domgoergen.com>\`

This program is free software: you can redistribute it and/or modify it 
under the terms of the GNU General Public License as published by the   
Free Software Foundation, either version 3 of the License, or (at your  
option) any later version.                                              

This program is distributed in the hope that it will be useful,         
but WITHOUT ANY WARRANTY; without even the implied warranty of          
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU       
General Public License for more details.                                

You should have received a copy of the GNU General Public License along 
with this program.  If not, see &amp;lt;http://www.gnu.org/licenses/>.         
