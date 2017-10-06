# Win32::AutoItX

Win32::AutoItX is a perl wrapper for the AutoItX (COM/ActiveX version of the
well-known utility [AutoIt v3](https://www.autoitscript.com/site/autoit/) for
automating the Windows GUI).

## Requirements

* Installed [AutoIt v3](https://www.autoitscript.com/site/autoit/downloads/) or
registered AutoItX3.dll library
* [Win32::OLE](https://metacpan.org/pod/Win32::OLE)
* [Win32::API](https://metacpan.org/pod/Win32::API)
* [Scalar::Util](https://metacpan.org/pod/Scalar::Util) (Perl core module)
* [Carp](https://metacpan.org/pod/Carp) (Perl core module)

## Installation

```
perl Makefile.PL && make install
```

## Usage

```perl
#!/usr/bin/perl

use strict;
use warnings;

use Win32::AutoItX;

my $a = Win32::AutoItX->new;

### AutoItX native methods ###

# Run an application
my $pid = $a->Run('calc.exe');

# Manage the clipboard
my $clipboard_text = $a->ClipGet;
$a->ClipPut("Win32::AutoItX rulez!");

# Work with screen pixels
my $color = $a->PixelGetColor(42, 42);

### Perlish methods ###

# Find window by title
my $window = $a->get_window('Calculator');
$window->wait;

# Show info about all window's controls
for my $control ($window->find_controls) {
    local $\ = "\n";
    print "Control $control";
    print "\thandle: ", $control->handle;
    print "\ttext: ", $control->text;
    print "\tx: ", $control->x, "\ty: ", $control->y;
    print "\twidth: ", $control->width, "\theight: ", $control->height;
}

# Get controls by text and class (optionally)
my $button_2 = $window->find_controls('2', class => 'Button');
my $button_3 = $window->find_controls('3', class => 'Button');
my $button_plus = $window->find_controls('+', class => 'Button');
my $button_eq = $window->find_controls('=', class => 'Button');
my $result = $window->find_controls('0', class => 'Static');

# Interact with controls
$button_2->click;
$button_3->click;
$button_plus->click;
$button_3->click;
$button_2->click;
$button_eq->click;

print "23 + 32 = ", $result->text, "\n";
```

## See also

[AutoIt v3 online documentation](https://www.autoitscript.com/autoit3/docs/)

## Author

[Mikhail Telnov](mailto:Mikhail.Telnov@gmail.com)

## Licensing

Please see the file called LICENSE.
