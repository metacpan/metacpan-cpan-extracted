# NAME

WebService::ILS - Standardised library discovery/circulation services

# SYNOPSIS

    use WebService::ILS::<Provider Subclass>;
    my $ils = WebService::ILS::<Provider Subclass>->new({
        client_id => $client_id,
        client_secret => $client_secret
    });
    my %search_params = (
        query => "Some keyword",
        sort => "rating",
    );
    my $result = $ils->search(\%search_params);
    foreach (@{ $result->{items} }) {
        ...
    }
    foreach (2..$result->{pages}) {
        $search_params{page} = $_;
        my $next_results = $ils->search(\%search_params);
        ...
    }

    or

    my $native_result = $ils->native_search(\%native_search_params);

# DESCRIPTION

WebService::ILS is an attempt to create a standardised interface for
online library services providers.

In addition, native API interface is provided.

Here we will describe constructor parameters and methods common to all
service providers. Diversions and native interfaces are documented
in corresponding modules.

## Supported service providers

- **WebService::ILS::OverDrive::Library**

    OverDrive Library API [https://developer.overdrive.com/discovery-apis](https://developer.overdrive.com/discovery-apis)

- **WebService::ILS::OverDrive::Patron**

    OverDrive Circulation API [https://developer.overdrive.com/circulation-apis](https://developer.overdrive.com/circulation-apis)

# TESTING ENVIRONMENT

Testing `WebService::ILS` modules is extremely difficult. It requires
test accounts with vendors, sometimes special setup for handling
redirect URLs.

In that respect for building purposes, all tests are skipped by default.
If you want to run tests for vendor specific modules during the build,
you need to set the corresponding WEBSERVICE\_ILS\_TEST\_\* env vars to true,
and supply values in vendor specific env vars. Those vendor specific vars
correspond to [CONSTRUCTOR](https://metacpan.org/pod/CONSTRUCTOR) params.

# TESTING OverDrive API

- **WEBSERVICE\_ILS\_TEST\_OVERDRIVE\_LIBRARY**

    When set to true turns on tests from t/overdrve\_library.t, which test
    `WebService::ILS::OverDrive::Library` module

- **WEBSERVICE\_ILS\_TEST\_OVERDRIVE\_PATRON**

    When set to true turns on tests from t/overdrve\_patron.t, which test
    `WebService::ILS::OverDrive::Patron` module

- **WEBSERVICE\_ILS\_TEST\_OVERDRIVE\_AUTH**

    When set to true turns on tests from t/overdrve\_auth.t, which test
    OverDrive Granted (3-legged) authentication mechanism. It is separated
    because of the challenges it presents

## OverDrive account vars

- **OVERDRIVE\_TEST\_CLIENT\_ID**
- **OVERDRIVE\_TEST\_CLIENT\_SECRET**
- **OVERDRIVE\_TEST\_LIBRARY\_ID**          library and auth
- **OVERDRIVE\_TEST\_WEBSITE\_ID**          patron only
- **OVERDRIVE\_TEST\_AUTHORIZATION\_NAME**  patron only
- **OVERDRIVE\_TEST\_USER\_ID**             patron only
- **OVERDRIVE\_TEST\_USER\_PASSWORD**       patron only
- **OVERDRIVE\_TEST\_AUTH\_REDIRECT\_URL**   auth only

# TESTING OneClickDigital API

- **WEBSERVICE\_ILS\_TEST\_ONECLICKDIGITAL\_PARTNER**

    When set to true turns on tests from t/oneclickdigital.t, which test
    `WebService::ILS::OneClickDigital::Partner` and
    `WebService::ILS::OneClickDigital::PartnerPatron` modules

- **WEBSERVICE\_ILS\_TEST\_ONECLICKDIGITAL\_PATRON**

    When set to true turns on tests from t/oneclickdigital.t, which test
    `WebService::ILS::OneClickDigital::Patron` module

- **WEBSERVICE\_ILS\_TEST\_ONECLICKDIGITAL**

    When set to true turns on all tests from t/overdrve\_auth.t.
    Same as `WEBSERVICE_ILS_TEST_ONECLICKDIGITAL_PARTNER` and
    `WEBSERVICE_ILS_TEST_ONECLICKDIGITAL_PATRON` both set to true.

## OneClickDigital account vars

- **ONECLICKDIGITAL\_TEST\_CLIENT\_SECRET**
- **ONECLICKDIGITAL\_TEST\_LIBRARY\_ID**
- **ONECLICKDIGITAL\_TEST\_USER\_ID**             patron only
- **ONECLICKDIGITAL\_TEST\_USER\_PASSWORD**       patron only
- **ONECLICKDIGITAL\_TEST\_USER\_EMAIL**          partner only
- **ONECLICKDIGITAL\_TEST\_USER\_BARCODE**        partner only

Only one of `ONECLICKDIGITAL_TEST_USER_EMAIL` (preferred) and
`ONECLICKDIGITAL_TEST_USER_BARCODE` needs to be supplied.

# POD ERRORS

Hey! **The above document had some coding errors, which are explained below:**

- Around line 109:

    You forgot a '=back' before '=head1'
