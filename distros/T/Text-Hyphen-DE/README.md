# NAME

Text::Hyphen::DE - determine hyphenation positions in german words

# SYNOPSIS

This module is an implementation of Knuth-Liang hyphenation algorithm
for german text using patterns from groff package.

    use Text::Hyphen::DE;
    my $hyphenator = Text::Hyphen::DE->new;
    print $hyphenator->hyphenate($word, '-');

See [Text::Hyphen](https://metacpan.org/pod/Text::Hyphen) for the interface documentation. This module only
provides german patterns.

# COPYRIGHT AND LICENSE 

Copyright 2019 Mario Domgoergen `<mario@domgoergen.com>`

This program is free software: you can redistribute it and/or modify it 
under the terms of the GNU General Public License as published by the   
Free Software Foundation, either version 3 of the License, or (at your  
option) any later version.                                              

This program is distributed in the hope that it will be useful,         
but WITHOUT ANY WARRANTY; without even the implied warranty of          
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU       
General Public License for more details.                                

You should have received a copy of the GNU General Public License along 
with this program.  If not, see &lt;http://www.gnu.org/licenses/>.         
