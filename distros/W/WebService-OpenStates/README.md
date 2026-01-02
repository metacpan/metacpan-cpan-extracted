# NAME

WebService::OpenStates - client for the Plural Open States API

# DESCRIPTION

State-level legislator information for US locations, provided via the Plural
Open States API.

You must obtain an API key (free) from Open States to use this package. See
[https://open.pluralpolicy.com/accounts/login/?next=/accounts/profile/#apikey](https://open.pluralpolicy.com/accounts/login/?next=/accounts/profile/#apikey).

# SYNOPSIS

    my $client = WebService::OpenStates->new( api_key => '***' );

    my $res = $client->legislators_for_location(lat => 37.302268, lon => -78.39263);

    if ( $res->{status} eq 'error') {
        # handle the error returned (JSON obj, see below)
    }
    else {
        for my $legislator ( @{$res->{legislators} ) {
            # use the data (JSON obj, see below)
        }
    }

# METHODS

- **legislators\_for\_location (NumRange\[-90,90\] :$lat, NumRange\[-180,180\] :$lon)**

    Requires a latitude numeric value as the first argument and a longtitude numeric
    value as the second argument.

    Returns a JSON object containing the `status` key with values 'success'
    or 'error', allowing you to examine and handle any error content if the
    call does not succeed.

    If the status is 'success', the response contains a key 'legislators'
    with a list of objects providing information about the legislators returned.

    Examples:

    Fatal error with bad params:

        my $resp = $client->legislators_for_location(lat => 91, lon => 85);

        # dies with message like 'In method legislators_for_location: parameter 1 ($lat): Value "91" did not pass type constraint "NumRange["-90",90]" ...'.

    Error response with bad API key:

        my $resp = $client->legislators_for_location(lat => 37, lon => 85); # with bad API key

        { content => {detail => 'Invalid API Key. Login and visit https://openstates.org/account/profile/ for your API key.'}, status => 'error' };  

    Empty response when no results are found

        my $resp = $client->legislators_for_location(lat => 37, lon => 85);

        { status => 'sucess', 'legislators' => [] }

    Success response

        my $resp = $client->legislators_for_location(lat => 37.302268, lon => -78.39263)
            {
                'legislators' => [
                                   {
                                     'party' => 'Republican',
                                     'title' => 'United States Representative',
                                     'offices' => [
                                                    {
                                                      'address' => '1013 Longworth House Office Building, Washington, DC 20515',
                                                      'phone' => '202-225-4711',
                                                      'name' => 'Capitol Office'
                                                    },
                                                    {
                                                      'phone' => '434-791-2596',
                                                      'name' => 'District Office',
                                                      'address' => '20564 Timberlake Road, Lynchburg, VA 24502'
                                                    }
                                                  ],
                                     'links' => [
                                                  'https://mcguire.house.gov/'
                                                ],
                                     'name' => 'John McGuire',
                                     'email' => 'https://mcguire.house.gov/address_authentication?form=/contact/email-me'
                                   },
                                   {
                                     'title' => 'Virginia Senator',
                                     'offices' => [
                                                    {
                                                      'address' => 'Room 620, General Assembly Building P.O. Box 396, Richmond, VA 23218',
                                                      'name' => 'Capitol Office',
                                                      'phone' => '804-698-7510'
                                                    },
                                                    {
                                                      'phone' => '804-372-0953',
                                                      'name' => 'District Office',
                                                      'address' => 'VA'
                                                    }
                                                  ],
                                     'party' => 'Republican',
                                     'links' => [
                                                  'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S132'
                                                ],
                                     'email' => 'senatorcifers@senate.virginia.gov',
                                     'name' => 'Luther Cifers'
                                   },
                                   {
                                     'links' => [
                                                  'https://www.warner.senate.gov',
                                                  'https://www.warner.senate.gov/public/index.cfm?p=Contact',
                                                  'https://www.warner.senate.gov/public/'
                                                ],
                                     'name' => 'Mark Warner',
                                     'email' => 'https://www.warner.senate.gov/public/index.cfm?p=contact',
                                     'title' => 'United States Senator',
                                     'offices' => [
                                                    {
                                                      'address' => '703 Hart Senate Office Building, Washington, DC 20510',
                                                      'name' => 'Capitol Office',
                                                      'phone' => '202-224-2023'
                                                    },
                                                    {
                                                      'address' => '919 E. Main St. Suite 630, Richmond, VA 23219',
                                                      'phone' => '804-775-2314',
                                                      'name' => 'Capitol Office'
                                                    },
                                                    {
                                                      'phone' => '757-441-3079',
                                                      'name' => 'District Office',
                                                      'address' => '101 W. Main St. Suite 7771, Norfolk, VA 23510'
                                                    },
                                                    {
                                                      'address' => '120 Luck Ave. SW Suite 108, Roanoke, VA 24011',
                                                      'name' => 'District Office',
                                                      'phone' => '540-857-2676'
                                                    },
                                                    {
                                                      'phone' => '276-628-8158',
                                                      'name' => 'District Office',
                                                      'address' => '180 W. Main St. Suite 235, Abingdon, VA 24210'
                                                    },
                                                    {
                                                      'phone' => '703-442-0670',
                                                      'name' => 'District Office',
                                                      'address' => '8150 Leesburg Pike Suite 700, Vienna, VA 22182'
                                                    }
                                                  ],
                                     'party' => 'Democratic'
                                   },
                                   {
                                     'links' => [
                                                  'https://www.kaine.senate.gov',
                                                  'https://www.kaine.senate.gov/contact',
                                                  'https://www.kaine.senate.gov/'
                                                ],
                                     'email' => 'https://www.kaine.senate.gov/contact',
                                     'name' => 'Tim Kaine',
                                     'title' => 'United States Senator',
                                     'offices' => [
                                                    {
                                                      'address' => '231 Russell Senate Office Building, Washington, DC 20510',
                                                      'name' => 'Capitol Office',
                                                      'phone' => '202-224-4024'
                                                    },
                                                    {
                                                      'address' => '919 E. Main St. Suite 970, Richmond, VA 23219',
                                                      'name' => 'Capitol Office',
                                                      'phone' => '804-771-2221'
                                                    },
                                                    {
                                                      'name' => 'District Office',
                                                      'phone' => '276-525-4790',
                                                      'address' => '121 Russell Road Suite 2, Abingdon, VA 24210'
                                                    },
                                                    {
                                                      'address' => '222 Central Park Ave. Suite 120, Virginia Beach, VA 23462',
                                                      'name' => 'District Office',
                                                      'phone' => '757-518-1674'
                                                    },
                                                    {
                                                      'address' => '611 S. Jefferson St. Suite 5B, Roanoke, VA 24011',
                                                      'phone' => '540-682-5693',
                                                      'name' => 'District Office'
                                                    },
                                                    {
                                                      'name' => 'District Office',
                                                      'phone' => '540-369-7667',
                                                      'address' => '816 William St. Suite B, Fredericksburg, VA 22401'
                                                    },
                                                    {
                                                      'address' => '9408 Grant Ave. Suite 202, Manassas, VA 20110',
                                                      'name' => 'District Office',
                                                      'phone' => '703-361-3192'
                                                    }
                                                  ],
                                     'party' => 'Democratic'
                                   },
                                   {
                                     'party' => 'Republican',
                                     'offices' => [
                                                    {
                                                      'phone' => '804-698-1050',
                                                      'name' => 'Capitol Office',
                                                      'address' => 'Room 1109, General Assembly Building 201 N. 9th St., Richmond, VA 23219'
                                                    },
                                                    {
                                                      'name' => 'District-Mail Office',
                                                      'phone' => '434-696-3061',
                                                      'address' => 'P.O. Box 1323, Victoria, VA 23974'
                                                    }
                                                  ],
                                     'title' => 'Virginia Delegate',
                                     'email' => 'deltwright@house.virginia.gov',
                                     'name' => 'Tommy Wright',
                                     'links' => [
                                                  'https://lis.virginia.gov/cgi-bin/legp604.exe?191+mbr+H136',
                                                  'https://lis.virginia.gov/cgi-bin/legp604.exe?201+mbr+H136',
                                                  'https://lis.virginia.gov/cgi-bin/legp604.exe?221+mbr+H136',
                                                  'https://lis.virginia.gov/cgi-bin/legp604.exe?241+mbr+H136',
                                                  'https://virginiageneralassembly.gov/house/members/members.php?id=H0136'
                                                ]
                                   }
                                 ],
                'status' => 'success'
              }; 
