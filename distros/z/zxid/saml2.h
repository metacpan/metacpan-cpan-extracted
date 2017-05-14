/* saml2.h  -  Widely used SAML 2.0 constants
 * Copyright (c) 2011 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * Copyright (c) 2006-2008 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: saml2.h,v 1.3 2008-04-14 04:23:58 sampo Exp $
 *
 * 26.8.2006,  created --Sampo
 * 14.4.2008,  added SimpleSign --Sampo
 * 10.12.2011, added OAuth2, OpenID Connect, and UMA support --Sampo
 */

#ifndef _saml2_h
#define _saml2_h

#define SAML2_PROTO "urn:oasis:names:tc:SAML:2.0:protocol"
#define SAML2_VERSION "2.0"

/* TOP LEVEL STATUS CODES */
#define SAML2_SC_SUCCESS    "urn:oasis:names:tc:SAML:2.0:status:Success"
#define SAML2_SC_REQUESTER  "urn:oasis:names:tc:SAML:2.0:status:Requester"
#define SAML2_SC_RESPONDER  "urn:oasis:names:tc:SAML:2.0:status:Responder"
#define SAML2_SC_VERSION    "urn:oasis:names:tc:SAML:2.0:status:VersionMismatch"

/* SECOND LEVEL STATUS CODES */
#define SAML2_SC_AUTHNFAIL  "urn:oasis:names:tc:SAML:2.0:status:AuthnFailed"
#define SAML2_SC_INVATTRNV  "urn:oasis:names:tc:SAML:2.0:status:InvalidAttrnameOrValue"
#define SAML2_SC_INVNIDPOL  "urn:oasis:names:tc:SAML:2.0:status:InvalidNameIDPolicy"
#define SAML2_SC_NOAUTNCTX  "urn:oasis:names:tc:SAML:2.0:status:NoAuthnContext"
#define SAML2_SC_NOAVALIDP  "urn:oasis:names:tc:SAML:2.0:status:NoAvailableIDP"
#define SAML2_SC_NOPASSIVE  "urn:oasis:names:tc:SAML:2.0:status:NoPassive"
#define SAML2_SC_NOSUPPIDP  "urn:oasis:names:tc:SAML:2.0:status:NoSupportedIDP"
#define SAML2_SC_PARLOGOUT  "urn:oasis:names:tc:SAML:2.0:status:PartialLogout"
#define SAML2_SC_PROXYCEXC  "urn:oasis:names:tc:SAML:2.0:status:ProxyCountExceeded"
#define SAML2_SC_REQDENIED  "urn:oasis:names:tc:SAML:2.0:status:RequestDenied"
#define SAML2_SC_REQUNSUPP  "urn:oasis:names:tc:SAML:2.0:status:RequestUnsupported"
#define SAML2_SC_REQVERDEP  "urn:oasis:names:tc:SAML:2.0:status:RequestVersionDeprecated"
#define SAML2_SC_REQVERHIG  "urn:oasis:names:tc:SAML:2.0:status:RequestVersionTooHigh"
#define SAML2_SC_REQVERLOW  "urn:oasis:names:tc:SAML:2.0:status:RequestVersionTooLow"
#define SAML2_SC_RESONRECG  "urn:oasis:names:tc:SAML:2.0:status:ResourceNotRecognized"
#define SAML2_SC_TOOMNYRES  "urn:oasis:names:tc:SAML:2.0:status:TooManyResponses"
#define SAML2_SC_UNKATTPRO  "urn:oasis:names:tc:SAML:2.0:status:UnknownAttributeProfile"
#define SAML2_SC_UNKPRNCPL  "urn:oasis:names:tc:SAML:2.0:status:UnknownPrincipal"
#define SAML2_SC_UNSUPPBIN  "urn:oasis:names:tc:SAML:2.0:status:UnsupportedBinding"

/* Authentication contexts: how was the user authenticated, or how dowe want him authenticated. */

#define SAML_AUTHCTX_PASSWORDPROTECTED "urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport"
#define SAML_AUTHCTX_PASSWORD          "urn:oasis:names:tc:SAML:2.0:ac:classes:Password"
#define SAML_AUTHCTX_SSL_TLS_CERT      "urn:oasis:names:tc:SAML:2.0:ac:classes:TLSClient"
#define SAML_AUTHCTX_PREVSESS          "urn:oasis:names:tc:SAML:2.0:ac:classes:PreviousSession"
#define SAML_AUTHCTX_UNSPCFD           "urn:oasis:names:tc:SAML:2.0:ac:classes:unspecified"
#define SAML_AUTHCTX_INPROT            "urn:oasis:names:tc:SAML:2.0:ac:classes:InternetProtocol"

/* NameID formats */

#define SAML2_UNSPECIFIED_NID_FMT "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified"
#define SAML2_EMAILADDR_NID_FMT   "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"
#define SAML2_X509_NID_FMT        "urn:oasis:names:tc:SAML:1.1:nameid-format:X509SubjectName"
#define SAML2_WINDOMAINQN_NID_FMT "urn:oasis:names:tc:SAML:1.1:nameid-format:WindowsDomainQualifiedName"
#define SAML2_KERBEROS_NID_FMT    "urn:oasis:names:tc:SAML:2.0:nameid-format:kerberos"
#define SAML2_ENTITY_NID_FMT      "urn:oasis:names:tc:SAML:2.0:nameid-format:entity"
#define SAML2_PERSISTENT_NID_FMT  "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent"
#define SAML2_TRANSIENT_NID_FMT   "urn:oasis:names:tc:SAML:2.0:nameid-format:transient"

/* Protocol profiles and bindings identify various negotiable subprotocols. */

#define SAML2_SSO_BRWS "urn:oasis:names:tc:SAML:2.0:profiles:SSO:browser"
#define SAML2_SSO_ECP  "urn:oasis:names:tc:SAML:2.0:profiles:SSO:ecp"
#define SAML2_SLO      "urn:oasis:names:tc:SAML:2.0:profiles:SSO:logout"
#define SAML2_NIREG    "urn:oasis:names:tc:SAML:2.0:profiles:SSO:nameid-mgmt"
#define SAML2_NIMAP    "urn:oasis:names:tc:SAML:2.0:profiles:SSO:nameidmapping"
#define SAML2_ARTIFACT "urn:oasis:names:tc:SAML:2.0:profiles:SSO:artifact"
#define SAML2_QUERY    "urn:oasis:names:tc:SAML:2.0:profiles:SSO:query"

#define SAML2_PAOS     "urn:oasis:names:tc:SAML:2.0:bindings:PAOS"
#define SAML2_SOAP     "urn:oasis:names:tc:SAML:2.0:bindings:SOAP"
#define SAML2_REDIR    "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect"
#define SAML2_ART      "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Artifact"
#define SAML2_POST     "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
#define SAML2_POST_SIMPLE_SIGN "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST-SimpleSign"
#define SAML2_URI      "urn:oasis:names:tc:SAML:2.0:bindings:URI"

/* OAUTH2.0 or OpenID-Connect 1.0 specifics */

#define OAUTH2_REDIR   "urn:zxid:OAUTH:2.0:bindings:HTTP-Redirect"

/* Attribute types describe how attributes are encoded. */

#define SAML2_AP_BASIC "urn:oasis:names:tc:SAML:2.0:profiles:attribute:basic"
#define SAML2_AP_X500  "urn:oasis:names:tc:SAML:2.0:profiles:attribute:X500"
#define SAML2_AP_UUID  "urn:oasis:names:tc:SAML:2.0:profiles:attribute:UUID"
#define SAML2_AP_DCE   "urn:oasis:names:tc:SAML:2.0:profiles:attribute:DCE"
#define SAML2_AP_XACML "urn:oasis:names:tc:SAML:2.0:profiles:attribute:XACML"

#define ATTRNAME_UNSPECIFIED "urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified"
#define ATTRNAME_BASIC       "urn:oasis:names:tc:SAML:2.0:attrname-format:basic"

/* Misc. */

#define SOAP_ACTOR_NEXT   "http://schemas.xmlsoap.org/soap/actor/next"
#define SAML2_BEARER      "urn:oasis:names:tc:SAML:2.0:cm:bearer"
#define SAML2_SOAP_ACTION "http://www.oasis-open.org/committees/security"

#define ACTION_RW      "urn:oasis:names:tc:SAML:1.0:action:rwedc"
#define ACTION_RWN     "urn:oasis:names:tc:SAML:1.0:action:rwedc-negation"
#define ACTION_GHPP    "urn:oasis:names:tc:SAML:1.0:action:ghpp"
#define ACTION_UNIX    "urn:oasis:names:tc:SAML:1.0:action:unix"

#define PAOS_CONTENT   "application/vnd.paos+xml"

#endif
