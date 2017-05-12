use XML::QL;

print XML::QL->query(<<'EOT');
        WHERE
							<tla>
                <billkey>
                        <state>$state</state>
                        <session_id>$session_id</session_id>
                        <legtype>$legtype</legtype>
                        <bill_number>$bill_number</bill_number>
                </billkey>
                <last_alteration>$lastalteration</last_alteration>
							</tla>
        IN 'stevefarris.xml'
        CONSTRUCT 
$state|$session_id|$legtype|$bill_number|$lastalteration
|
EOT


__END__

