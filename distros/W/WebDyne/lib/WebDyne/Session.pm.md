# WebDyne::Session #

# NAME #

WebDyne::Session - simple session-cookie module for the WebDyne handler chain

# SYNOPSIS #

```perl
__PERL__
use WebDyne::Session;
```

# DESCRIPTION #

`WebDyne::Session` is a chaining module that ensures each request has a session identifier stored in a browser cookie.

When imported from a page `__PERL__` block, it switches the page to `WebDyne::Chain` handling and adds itself to the active chain. At runtime it reads the configured session cookie, generates a new identifier when one is missing, and exposes the identifier through the page object.

# METHODS #

* **handler($self, $r, $param_hr)**

    Read or create the session cookie and then pass control to the next handler in the chain.

* **session_id()**

    Return the current session identifier for the active page/request object.

# CONSTANTS #

Cookie naming is controlled by `WEBDYNE_SESSION_ID_COOKIE_NAME` from `WebDyne::Session::Constant`.

# NOTES #

The current implementation uses `Crypt::URandom` to generate new session IDs.

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT #

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>
