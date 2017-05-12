use WWW::Splunk::XMLParser;
use XML::LibXML;
use Test::More tests => 5;

my $case1 = XML::LibXML->load_xml (string => <<EOF);
<response>
	<dict>
		<key name="remoteSearch">search index=default readlevel=2 foo</key>
		<key name="remoteTimeOrdered">true</key>
	</dict>
	<list>
		<item>
			<dict>
				<key name="overridesTimeOrder">false</key>
				jjjjjjjjjjjjjjjjjjjj<key name="isStreamingOpRequired">false</key>

			</dict>
		</item>
		<item>
			<dict>
			</dict>
			<dict>
			</dict>
		</item>
	</list>
</response>
EOF
is_deeply ([ WWW::Splunk::XMLParser::parse ($case1) ], [
	{
		'remoteSearch' => 'search index=default readlevel=2 foo',
		'remoteTimeOrdered' => 'true'
	},
	[
		{
		'isStreamingOpRequired' => 'false',
		'overridesTimeOrder' => 'false'
		},
		{},
		{}
	],
	], "Structured document parsed correctly");

my $case2 = XML::LibXML->load_xml (string => <<EOF);
<?xml version="1.0" encoding="UTF-8"?>
<!--This is to override browser formatting; see server.conf[httpServer] to disable. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .-->
<?xml-stylesheet type="text/xml" href="/static/atom.xsl"?>
<entry xmlns="http://www.w3.org/2005/Atom" xmlns:s="http://dev.splunk.com/ns/rest" xmlns:opensearch="http://a9.com/-/spec/opensearch/1.1/">
  <title>search index=* source=/mnt/log/httpd/access_log |stats count by http_status_code</title>
  <id>https://splunk.example.net:8089/services/search/jobs/1336417395.8763.example-user</id>
  <updated>2012-05-07T21:03:16.000+02:00</updated>
  <link href="/services/search/jobs/1336417395.8763.example-user" rel="alternate"/>
  <published>2012-05-07T21:03:16.000+02:00</published>
  <link href="/services/search/jobs/1336417395.8763.example-user/search.log" rel="search.log"/>
  <link href="/services/search/jobs/1336417395.8763.example-user/events" rel="events"/>
  <author>
    <name>nobody</name>
  </author>
  <content type="text/xml">
    <s:dict>
      <s:key name="bundleVersion">6012424754159105074</s:key>
      <s:key name="cursorTime">2038-01-19T04:14:07.000+01:00</s:key>
      <s:key name="messages">
        <s:dict/>
      </s:key>
      <s:key name="request">
        <s:dict>
          <s:key name="earliest_time">2012-05-07T21:02:13</s:key>
        </s:dict>
      </s:key>
      <s:key name="eai:acl">
        <s:dict>
          <s:key name="perms">
            <s:dict>
              <s:key name="read">
                <s:list>
                  <s:item>nobody</s:item>
                </s:list>
              </s:key>
              <s:key name="write">
                <s:list>
                  <s:item>nobody</s:item>
                </s:list>
              </s:key>
            </s:dict>
          </s:key>
          <s:key name="owner">nobody</s:key>
          <s:key name="delegate"/>
          <s:key name="modifiable">true</s:key>
          <s:key name="sharing">global</s:key>
          <s:key name="app">search</s:key>
          <s:key name="can_write">true</s:key>
        </s:dict>
      </s:key>
      <s:key name="searchProviders">
        <s:list/>
      </s:key>
    </s:dict>
  </content>
</entry>
EOF
is_deeply (WWW::Splunk::XMLParser::parse ($case2), {
	request => { earliest_time => '2012-05-07T21:02:13' },
	messages => {},
	searchProviders => [],
	'eai:acl' => {
		sharing => 'global',
		modifiable => 'true',
		delegate => undef,
		owner => 'nobody',
		app => 'search',
		can_write => 'true',
		perms => {
			read => [ 'nobody' ],
			write => [ 'nobody' ]
		}
	},
	cursorTime => '2038-01-19T04:14:07.000+01:00',
	bundleVersion => '6012424754159105074',
	}, 'Atom wrapped document parsed correctly');

my $case3 = XML::LibXML->load_xml (string => <<EOF);
<?xml version=\'1.0\' encoding=\'UTF-8\'?>
<response><sid>666</sid></response>
EOF
isa_ok (WWW::Splunk::XMLParser::parse ($case3),
	'XML::LibXML::Document', "Raw document 1");

my $case4 = XML::LibXML->load_xml (string => <<EOF);
<response>
	<messages>
		<msg type='FATAL'>Unknown sid.</msg>
	</messages>
</response>
EOF
isa_ok (WWW::Splunk::XMLParser::parse ($case4),
	'XML::LibXML::Document', "Raw document 2");

my $case5 = XML::LibXML->load_xml (string => <<EOF);
<?xml version="1.0" encoding="UTF-8"?>
<results preview="0">
        <meta>
                <fieldOrder>
                        <field>http_status_code</field>
                        <field>count</field>
                </fieldOrder>
        </meta>
        <result offset="0">
                <field k="http_status_code">
                        <value><text>200</text></value>
                </field>
                <field k="count">
                        <value><text>666</text></value>
                </field>
        </result>
        <result offset="1">
                <field k="http_status_code">
                        <value><text>204</text></value>
                </field>
                <field k="count">
                        <value><text>8086</text></value>
                </field>
		<field k="_raw">
			<v xml:space="preserve" trunc="0">fnfnfn</v>
		</field>
        </result>
</results>
EOF
is_deeply ([ WWW::Splunk::XMLParser::parse ($case5) ], [
	{ count => '666', http_status_code => '200' },
	{ count => '8086', http_status_code => '204', _raw => 'fnfnfn' }
	], 'Results structure parsed fine');
