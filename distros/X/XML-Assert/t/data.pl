sub xml {
    my $xml = <<'EOF';
<?xml version="1.0"?>
<catalog>
  <cd barcode="5-901234-123457">
    <title>Empire Burlesque</title>
    <artist>Bob Dylan</artist>
    <country>USA</country>
    <company>Columbia</company>
    <price>10.90</price>
    <year>1985</year>
    <rating>5</rating>
  </cd>
  <cd barcode="9-400097-038275" genre="Pop">
    <title>Hide your heart</title>
    <artist>Bonnie Tyler</artist>
    <country>UK</country>
    <company>CBS Records</company>
    <price>9.90</price>
    <year>1988</year>
  </cd>
  <cd barcode="9-414982-021013" genre="Country">
    <title>Greatest Hits</title>
    <artist>Dolly Parton</artist>
    <country>USA</country>
    <company>RCA</company>
    <price>9.90</price>
    <year>1982</year>
    <rating>4</rating>
  </cd>
</catalog>
EOF
    return $xml;
}

sub xml_ns {
    my $xml_ns = <<'EOF';
<?xml version="1.0"?>
<catalog xmlns="urn:catalog">
  <cd barcode="5-901234-123457">
    <title>Empire Burlesque</title>
    <artist>Bob Dylan</artist>
    <country>USA</country>
    <company>Columbia</company>
    <price>10.90</price>
    <year>1985</year>
    <rating>5</rating>
  </cd>
  <cd barcode="9-400097-038275" genre="Pop">
    <title>Hide your heart</title>
    <artist>Bonnie Tyler</artist>
    <country>UK</country>
    <company>CBS Records</company>
    <price>9.90</price>
    <year>1988</year>
  </cd>
  <cd barcode="9-414982-021013" genre="Country">
    <title>Greatest Hits</title>
    <artist>Dolly Parton</artist>
    <country>USA</country>
    <company>RCA</company>
    <price>9.90</price>
    <year>1982</year>
    <rating>4</rating>
  </cd>
</catalog>
EOF
    return $xml_ns;
}

1;
