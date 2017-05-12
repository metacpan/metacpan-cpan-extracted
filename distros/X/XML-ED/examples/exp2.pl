#!/usr/bin/perl

use lib qw (blib/lib blib/arch);

use XML::ED::Bare qw/xmlin/;

my $text = qq(<xml>value1<value value="value_att">value_con</value>value2</xml>);
my $text = <<EOP;
<?xml version="1.0" ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<?nxml version="1.0" ?>
<note>
<to>Tove</to>
<from>Jani</from>
<!-- bob -->
<heading bob="bob" joe='jack' >Reminder</heading>
<!-- bill -->
<body>Don't forget me
<bob  bob    =  "joe">this</bob>
weekend!</body>
<bill>this</bill>
<?bill version="1.0" ?>
<![CDATA[
this is c data
]]>
</note>
EOP

my ( $xml, $root ) = XML::ED::Bare->new( text => $text );

use Data::Dumper;
die Dumper $root;

#print Dumper xmlin($text);

use Data::Dumper;

#print Dumper $xml, $root, $simple;

sub attributes
{
   my $object = shift;

   my @keys = grep {!/^_/} keys %$object;

   return @keys ? ' ' . join(' ', map({ sprintf(qq($_="%s"), $object->{$_}->{value}) } sort @keys)) : '';
}

sub render
{
    my $object = shift;

    my @data = ();
    for my $obj (@$object) {
        if ($obj->{_type} == 0) {
	    push @data, render($obj->{_data}); 
        } elsif ($obj->{_type} == 1) {
	    if ($obj->{_data}) {
		push @data, (sprintf("<%s%s>",  $obj->{_name}, attributes( $obj )), render($obj->{_data}), sprintf("</%s%s>",  $obj->{_name})); 
	    } else {
		push @data, sprintf("<%s%s/>",  $obj->{_name}, attributes( $obj )); 
	    }
	} elsif ($obj->{_type} == 5) {
	    push @data, $obj->{_value};
	} elsif ($obj->{_type} == 12) {
	    push @data, sprintf("<!--%s-->",  $obj->{_value}); 
	} elsif ($obj->{_type} == 10) {
	    push @data, sprintf("<!%s>",  $obj->{_value}); 
	} elsif ($obj->{_type} == 2) {
	    push @data, sprintf("<?%s%s?>",  $obj->{_name}, attributes( $obj )); 
	} else {
	    push @data, $obj->{_type};
	}
    }
    return @data;
}

print "-----";
print join '', render( [ $root ] );

