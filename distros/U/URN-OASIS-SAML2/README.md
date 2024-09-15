# DESCRIPTION

This module provides constants which are in use by the SAML2 implementation.

# SYNOPSIS

    # All at once
    use URN::OASIS::SAML2 qw(:all);

    # or use one of the export tags

# Available export tags

## urn

    use URN::OASIS::SAML2 qw(:urn);
    use URN::OASIS::SAML2 qw(
        URN_ASSERTION
        URN_METADATA
        URN_PROTOCOL
        URN_SIGNATURE
        URN_ENCRYPTION
    );

## ns

    use URN::OASIS::SAML2 qw(:ns);
    use URN::OASIS::SAML2 qw(
        NS_ASSERTION
        NS_METADATA
        NS_PROTOCOL
        NS_SIGNATURE
        NS_ENCRYPTION
    );

## bindings

    use URN::OASIS::SAML2 qw(:binding);
    use URN::OASIS::SAML2 qw(
        BINDING_HTTP_POST
        BINDING_HTTP_ARTIFACT
        BINDING_HTTP_REDIRECT
        BINDING_SOAP
        BINDING_POAS # also available as BINDING_REVERSE_SOAP
    );

## classes

    use URN::OASIS::SAML2 qw(:class);
    use URN::OASIS::SAML2 qw(
        CLASS_UNSPECIFIED
        CLASS_PASSWORD_PROTECTED
        CLASS_M2FA_UNREGISTERED
        CLASS_M2FA_CONTRACT
        CLASS_SMARTCARD
        CLASS_SMARTCARD_PKI
    );

## nameid

    use URN::OASIS::SAML2 qw(:nameid);
    use URN::OASIS::SAML2 qw(
        NAMEID_EMAIL
        NAMEID_TRANSIENT
        NAMEID_PERSISTENT
        NAMEID_UNSPECIFIED
        NAMEID_X509_SUBJECT_NAME
        NAMEID_WINDOWS_DOMAIN_QUALIFIED_NAME
    );

## status

    use URN::OASIS::SAML2 qw(:status);
    use URN::OASIS::SAML2 qw(
        STATUS_AUTH_FAILED
        STATUS_REQUESTER
        STATUS_REQUEST_DENIED
        STATUS_RESPONDER
        STATUS_SUCCESS
        STATUS_PARTIAL_LOGOUT
    );
