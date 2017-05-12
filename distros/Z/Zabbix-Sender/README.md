# NAME

Zabbix::Sender - A pure-perl implementation of zabbix-sender.

# SYNOPSIS

This code snippet shows how to send the value "OK" for the item "my.zabbix.item"
to the zabbix server/proxy at "my.zabbix.server.example" on port "10055".

    use Zabbix::Sender;

    my $Sender = Zabbix::Sender->new({
       'server' => 'my.zabbix.server.example',
       'port' => 10055,
    });
    $Sender->send('my.zabbix.item','OK');

# SUBROUTINES/METHODS

## hostname

Name of the host for which to submit items to Zabbix.  Initialized by \_init\_hostname. You can set it either using

    $Sender->hostname('another.hostname');

or during creation time of Zabbix::Sender

    my $Sender = Zabbix::Sender->new({
        'server' => 'my.zabbix.server.example',
        'hostname' => 'another.hostname',
    });

You can also query the current setting using

    my $current_hostname = $Sender->hostname();

## strict

Use the strict setting to make Zabbix::Sender check the return values from
Zabbix:

    $Sender->strict(1);

You can also query the current setting using

    my $is_strict = $Sender->strict();

## \_init\_json

Zabbix 1.8 uses a JSON encoded payload after a custom Zabbix header.
So this initializes the JSON object.

## \_init\_hostname

The hostname of the sending instance may be given in the constructor.

If not it is detected here.

## zabbix\_template\_1\_8

ZABBIX 1.8 TEMPLATE

a4 - ZBXD
b  - 0x01
V - Length of Request in Bytes (64-bit integer), aligned left, padded with 0x00, low 32 bits
V - High 32 bits of length (always 0 in Zabbix::Sender)
a\* - JSON encoded request

This may be changed to a HashRef if future version of zabbix change the header template.

## \_encode\_request

This method encodes values as a json string and creates
the required header according to the template defined above.

## \_check\_info

Checks the return value from the Zabbix server (or Zabbix proxy),
which states the number of processed, failed and total values.
Returns undef if everything is alright, a message otherwise.

This method is called when the strict setting of Zabbix::Sender
is active:

    my $Sender = Zabbix::Sender->new({
        'server' => 'my.zabbix.server.example',
        'strict' => 1,
    });

## \_decode\_answer

This method tries to decode the answer received from the server.

Returns true if response indicates success, false if response indicates
failure, undefined value if response was empty or cannot be decoded.

Method "response" may be used to return decoded response.

## send

Send the given item with the given value to the server.

Takes two or three scalar arguments: item key, value and clock (clock is
optional).

## bulk\_buf\_add

Adds values to the stack of values to bulk\_send.

It accepts arguments in forms:

$sender->bulk\_buf\_add($key, $value, $clock, ...);
$sender->bulk\_buf\_add(\[$key, $value, $clock\], ...);
$sender->bulk\_buf\_add($hostname, \[ \[$key, $value, $clock\], ...\], ...);

Last form allows to add values for several hosts at once.

$clock is optional and may be undef, empty or omitted.

Returns true if successful or undef if invalid arguments are specified.

## bulk\_buf\_clear

Clear bulk\_send buffer.

## bulk\_send

Send accumulated values to the server.

It accepts the same arguments as bulk\_buf\_add. If arguments are specified,
they are added to the buffer before sending.

## DEMOLISH

Disconnects any open sockets on destruction.

# AUTHOR

"Dominik Schulz", `<"lkml at ds.gauner.org">`

# BUGS

Please report any bugs or feature requests to `bug-zabbix-sender at rt.cpan.org`, or through
the web interface at [http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Zabbix-Sender](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Zabbix-Sender).  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Zabbix::Sender

You can also look for information at:

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=Zabbix-Sender](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Zabbix-Sender)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Zabbix-Sender](http://annocpan.org/dist/Zabbix-Sender)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Zabbix-Sender](http://cpanratings.perl.org/d/Zabbix-Sender)

- Search CPAN

    [http://search.cpan.org/dist/Zabbix-Sender/](http://search.cpan.org/dist/Zabbix-Sender/)

# ACKNOWLEDGEMENTS

This code is based on the documentation and sample code found at:

- http://www.zabbix.com/documentation/1.8/protocols

# LICENSE AND COPYRIGHT

Copyright 2011 Dominik Schulz.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
