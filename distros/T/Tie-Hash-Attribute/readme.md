Tie::Hash::Attribute
====================
Just another HTML attribute generator. [![CPAN Version](https://badge.fury.io/pl/Tie-Hash-Attribute.svg)](https://metacpan.org/pod/Tie::Hash::Attribute)

Synopsis
--------
```perl
use Tie::Hash::Attribute;

tie my %tag, 'Tie::Hash::Attribute';
%tag = (
    table => { border => 0 },
    tr => {
        style => { color => 'red', align => 'right' },
    },
    td => {
        style => {
            align => [qw( left right )],
            color => [qw( red blue green )],
        }
    },
);
 
print $tag{-table};
  # border: 0

print $tag{-tr};
  # style="align: right; color: red;"

print $tag{-td} for 1 .. 4;
  # style="align: left; color: red;"',
  # style="align: right; color: blue;"',
  # style="align: left; color: green;"',
  # style="align: right; color: red;"',

# or emit all attributes at once
tie my %tr_tag, 'Tie::Hash::Attribute';

%tr_tag = ( style => {
    align => [qw(left right)],
    color => [qw(red blue green)]
} );

print scalar %tr_tag for 1 .. 4;
  # style="align: left; color: red;"
  # style="align: right; color: blue;"
  # style="align: left; color: green;"
  # style="align: right; color: red;"
```

Installation
------------
To install this module, you should use CPAN. A good starting
place is [How to install CPAN modules](http://www.cpan.org/modules/INSTALL.html).

If you truly want to install from this github repo, then
be sure and create the manifest before you test and install:
```
perl Makefile.PL
make
make manifest
make test
make install
```

Support and Documentation
-------------------------
After installing, you can find documentation for this module with the
perldoc command.
```
perldoc Tie::Hash::Attribute
```
You can also find documentation at [metaCPAN](https://metacpan.org/pod/Tie::Hash::Attribute).

License and Copyright
---------------------
See [source POD](/lib/Tie/Hash/Attribute.pm).
