#!/usr/bin/perl -w
use strict;
use warnings;
use Carp;
$SIG{__DIE__} = \&confess;

use WWW::Webrobot::SelftestRunner qw(RunTestplan HttpdEcho Config);

my $config = Config(qw/Test Html/) . <<EOF;
#names=echo_url=url
# now some names that should be ignored:
names
names==no_key_defined
EOF

my $test_plan = <<'EOF';
<?xml version="1.0" encoding="iso-8859-1"?>
<plan>

    <config script="perl -w t/properties/runtime-config.pl">
    </config>
    <!--
        <description value="define the properties 'login' and 'password'"/>
    -->

    <request>
        <method value='GET'/>
        <url value='${application}/url/${login}/${password}'/>
        <assert>
            <WWW.Webrobot.Assert>
                <and>
                    <status value='200'/>
                    <regex value='my_name/secret'/>
                </and>
            </WWW.Webrobot.Assert>
        </assert>
        <description value="access the properties 'login' and 'password'"/>
    </request>

    <request>
        <method value='GET'/>
        <url value='${application}/url/${login}/${password}'/>
        <assert>
            <WWW.Webrobot.Assert>
                <and>
                    <status value='200'/>
                    <regex value='${login}/${password}'/>
                    <string value='${login}/${password}'/>
                </and>
            </WWW.Webrobot.Assert>
        </assert>
        <description value="access the properties 'login' and 'password' and expand in as many places as possible"/>
    </request>

    <request>
        <method value='GET'/>
        <url value='${application}/url/${login}/${password}'/>
        <assert>
            <WWW.Webrobot.Assert>
                <and>
                    <status value='200'/>
                    <regex value='my_name/secret'/>
                </and>
            </WWW.Webrobot.Assert>
        </assert>
        <description value="access the properties 'login' and 'password' and define a property"/>
        <property name='constant' value='a_new_value'/>
    </request>

    <request>
        <method value='GET'/>
        <url value='${application}/url/${constant}'/>
        <assert>
            <WWW.Webrobot.Assert>
                <and>
                    <status value='200'/>
                    <string value='a_new_value'/>
                </and>
            </WWW.Webrobot.Assert>
        </assert>
        <description value="access the properties 'login' and 'password' and define the same property again"/>
        <property name='constant' value='a_really_new_value'/>
    </request>

    <request>
        <method value='GET'/>
        <url value='${application}/url/${constant}'/>
        <assert>
            <WWW.Webrobot.Assert>
                <and>
                    <status value='200'/>
                    <string value='a_really_new_value'/>
                </and>
            </WWW.Webrobot.Assert>
        </assert>
        <description value="define a property by regular expression"/>
        <property name='expression' regex='a_([a-z]*)_new'/>
    </request>

    <request>
        <method value='GET'/>
        <url value='${application}/url/${expression}'/>
        <assert>
            <WWW.Webrobot.Assert>
                <and>
                    <status value='200'/>
                    <regex value='/really$'/>
                </and>
            </WWW.Webrobot.Assert>
        </assert>
        <description value="define a property by a header field"/>
        <property name='head' header='Content-Type'/>
    </request>

    <request>
        <method value='GET'/>
        <url value='${application}/url/${head}'/>
        <assert>
            <WWW.Webrobot.Assert>
                <and>
                    <status value='200'/>
                    <string value='text/plain'/>
                </and>
            </WWW.Webrobot.Assert>
        </assert>
        <description value="${head}: access the header property"/>
    </request>

    <request>
        <method value='GET'/>
        <url value='${application}/constant_html_0/'/>
        <assert>
            <WWW.Webrobot.Assert>
                <and>
                    <status value='200'/>
                    <xpath xpath='//title/text()' value='A_Static_Html_Page'/>
                </and>
            </WWW.Webrobot.Assert>
        </assert>
        <description value="define a property by an XPath expression"/>
        <property name='xp' xpath='//title/text()'/>
    </request>

    <request>
        <method value='GET'/>
        <url value='${application}/url/${xp}'/>
        <assert>
            <WWW.Webrobot.Assert>
                <and>
                    <status value='200'/>
                    <string value='A_Static_Html_Page'/>
                </and>
            </WWW.Webrobot.Assert>
        </assert>
        <description value="use the XPath property"/>
    </request>

</plan>
EOF

MAIN: {
    exit RunTestplan(HttpdEcho, $config, $test_plan);
}
