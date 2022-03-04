/*
 * Copyright 2022 cPanel, LLC. (copyright@cpanel.net)
 * Author: Felipe Gasper
 *
 # Copyright (c) 2022, cPanel, LLC.
 # All rights reserved.
 # http://cpanel.net
 #
 # This is free software; you can redistribute it and/or modify it under the
 # same terms as Perl itself. See L<perlartistic>.
 */

// ----------------------------------------------------------------------

/*
 * ICU, as of v70, doesn’t expose MessageFormat::getArgTypeList,
 * so its umsg.cpp uses a trick like this to gain “backdoor” access
 * in order to implement formatting. PHP mimicks it to achieve the same
 * goal (cf. ext/intl/msgformat/msgformat_helpers.cpp).
 *
 * We should thus be OK to use the same trick; if they “move our cheese”
 * they’ll likely ship a (hopefully better) replacement.
 */

U_NAMESPACE_BEGIN
class MessageFormatAdapter {
public:
    static const Formattable::Type* perl_uicu_getArgTypeList(
        const MessageFormat& m,
        int32_t& count
    );
};

const Formattable::Type*
MessageFormatAdapter::perl_uicu_getArgTypeList(const MessageFormat& m,
                                     int32_t& count) {
    return m.getArgTypeList(count);
}
U_NAMESPACE_END
