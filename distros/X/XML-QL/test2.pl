use XML::QL;

print XML::QL->query(<<'EOT');
WHERE <INTRODUCTION> $intro </INTRODUCTION>
         <PROPER-USE> $use </PROPER-USE>
IN 'steth.xml'
  CONSTRUCT $intro
            $use
EOT
