
# NAME

WG::API - Module for work with Wargaming.net Public API

# VERSION

Version v0.8.6

# SYNOPSIS

Wargaming.net Public API is a set of API methods that provide access to Wargaming.net content, including in-game and game-related content, as well as player statistics.

This module provide access to WG Public API

    use WG::API;

    my $wg = WG::API->new( application_id => 'demo' );
    ...
    my $player = $wg->net( language => 'en' )->account_info( account_id => '1' );

# ATTRIBUTES

- _application\_id\*_

    Rerquired application id: [https://developers.wargaming.net/documentation/guide/getting-started/](https://developers.wargaming.net/documentation/guide/getting-started/)

# METHODS

- **wot**

    Returns a WoT instance

- **wowp**

    Returns A WoWp instance

- **wows**

    Returns a WoWs instance

- **net**

    Returns a NET instance

- **auth**

    Return a Auth instance

# BUGS

Please report any bugs or feature requests to `cynovg at cpan.org`, or through the web interface at [https://github.com/cynovg/WG-API/issues](https://github.com/cynovg/WG-API/issues).  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WG::API

You can also look for information at:

- RT: GitHub's request tracker (report bugs here)

    [https://github.com/cynovg/WG-API/issues](https://github.com/cynovg/WG-API/issues)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/WG-API](http://annocpan.org/dist/WG-API)

- CPAN Ratings

    [http://cpanratings.perl.org/d/WG-API](http://cpanratings.perl.org/d/WG-API)

- Search CPAN

    [http://search.cpan.org/dist/WG-API/](http://search.cpan.org/dist/WG-API/)

# ACKNOWLEDGEMENTS

...

# SEE ALSO

WG API Reference [https://developers.wargaming.net/](https://developers.wargaming.net/)

# AUTHOR

Cyrill Novgorodcev , `<cynovg at cpan.org>`

# LICENSE AND COPYRIGHT

Copyright 2015 Cyrill Novgorodcev.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

[http://www.perlfoundation.org/artistic\_license\_2\_0](http://www.perlfoundation.org/artistic_license_2_0)

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
