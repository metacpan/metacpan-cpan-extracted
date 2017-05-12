package Util::XML_YAML_Perl;

use warnings;
use strict;

use XML::Simple;
use YAML;
use YAML::AppConfig;

=head1 NAME

Util::XML_YAML_Perl - Interconversion between PERL,YAML and XML. 

=head1 VERSION

Version 1.0.0

=cut

our $VERSION = '1.0.0';

=head1 SYNOPSIS

This module serves as single point for all typical operations done on these three -PERL,YAML and XML. Also this doesnt degrade any of advanced features provided by independent modules.

This will serve as quick point for interconversions saving time of experimenting with atleast two independent modules.

    use XML::YAML_PERL;

    #create XML::YAML_PERL object
    my $obj=XML::YAML_PERL->new();
    
    my $perl_ref=$obj->xml_to_perl($filename);
    my $b=$obj->xml_to_perl('-');

    my $y_ref=$obj->perl_to_yaml($hash);
    $y_ref=$obj->perl_to_yaml($hash,$file);
    $y_ref->dump($file);
    $y_ref->dump();
    $y_ref->get_h;
    $y_ref->get("h");
    $y_ref->set("h",10);
    $y_ref->set_h(10);
    $y_ref->config->{h}=10;

    my $yaml_ref=$obj->xml_to_yaml($filename);

    my $xml_string=$obj->perl_to_xml($perl_ref);
    my $xml_file=$obj->perl_to_xml($perl_ref,$options);

    my $hash=$obj->yaml_to_perl('m.yml');
    my $hash=$obj->yaml_to_perl($string);

    my $xml_string=$obj->yaml_to_xml($yaml_ref);
    my $xml_file=$obj->yaml_to_xml($yaml_ref,$op);
    

    read more about methods with examples below.


=cut

=head1 METHODS

=cut

=head2 new ()

Retuns a bless object. 
This module has no exported methods to it has to be used in OOO way only.

my $obj = XML::YAML_PERL->new();

=cut

sub new {
    my $class= shift;

    return bless {}, $class;

}

=head2 xml_to_perl ( $xml_file,$options )

    Convert XML into perl hash. 

    my $perl_ref=$obj->xml_to_perl($filename);

    To read from STDIN, File name should be '-'.

    Options of XML::Simple can be used. C<$options> is a ref to array consisting of options available on XML::Simple.

    returns perl hash

=head3    EXAMPLES:

    1) 
        $ cat a.xml
        <?xml version='1.0'?>
        <employee>
        <name>John Doe</name>
        <age>43</age>
        <sex>M</sex>
        <department>Operations</department>
        </employee>

        my $b=$obj->xml_to_perl('a.xml');
        print "".Dumper($b);

        $VAR1 = { 
            'department' => 'Operations',
            'name' => 'John Doe',
            'sex' => 'M',
            'age' => '43'
        };

    2)
        my $b=$obj->xml_to_perl('-');
        #Such a call with wait for XML input to be teminated by Ctrl+d

        $ perl c.pl
        <employee>
        <name>John Doe</name>
        <age>43</age>
        <sex>M</sex>
        <department>Operations</department>
        </employee>
        [CTRL+D]
        $VAR1 = { 
            'department' => 'Operations',
            'name' => 'John Doe',
            'sex' => 'M',
            'age' => '43'
        };

=cut

sub xml_to_perl {

    my ( $self, $xml_file,$options) = @_;

    my $xs = XML::Simple->new(@$options);
    my $perl_ref = $xs->XMLin($xml_file);

    return $perl_ref;

}

=head2 perl_to_yaml($perl_ref,$file) 

    Converts perl hash into YAML string or file.

        $perl_ref - perl hash
        $file - File to write into (optional)

    returns YAML::AppConfig object


    my $hash={h=>1, m=>4};
    my $y_ref=$obj->perl_to_yaml($hash);
    $y_ref=$obj->perl_to_yaml($hash,$file);

    print $y_ref->dump();  #prints Yaml equivalent for perl object
    $y_ref->dump($file);    #prints Yaml equivalent into C<$file>for perl object

    $y_ref->get_h;   #returns value of h
    $y_ref->get("h"); #returns value of h

    # Set etc_dir in three different ways, all equivalent.  
    $y_ref->set("h",10);
    $y_ref->set_h(10);
    $y_ref->config->{h}=10;

    Above  described dump,get_*/set_* methods will work on Yaml reference objects returned by other subroutines in this module.

=cut

sub perl_to_yaml {

    my ($self,$perl_ref,$file)=@_;

    my $yaml_string=Dump($perl_ref);
    my $yaml_ref= YAML::AppConfig->new(string => $yaml_string);

    $yaml_ref->dump($file) if (defined $file);
    return $yaml_ref;

}

=head2 xml_to_yaml($xml_file,$options) 

    Converts XML string/file into YAML string or file.

        $xml_file- XML file path
        $options- to be drawn from XML::Simple[optional]

    returns YAML::AppConfig object

    dump()
    get_*()
    set_*()

    read how above methods work from perl_to_yaml().

=cut


sub xml_to_yaml {

    my ($self,$xml_file,$options) = @_;

    my $xs = XML::Simple->new(@$options);
    my $perl_ref = $xs->XMLin($xml_file);

    my $yaml_string=Dump($perl_ref);
    my $yaml_ref= YAML::AppConfig->new(string => $yaml_string);

    return $yaml_ref;

}

=head2 perl_to_xml($perl_ref,$options)

    Converts perl hashes  into XML string/File
    
        $perl_ref - refernce to perl hash
        $options- to be drawn from XML::Simple[optional]

    returns XML string
    returns 1 if file written.

    open my $fh, '>:encoding(iso-8859-1)', $path or die "open($path): $!";
    my $op=[OutputFile => $fh];

    my $return_val=$obj->perl_to_xml($perl_ref,$options)

=head3  EXAMPLES:

    my $hash={h=>1, m=>4};
    my $d=$obj->perl_to_xml($hash);


    open(my $fh,">","ur.xml") or die $!;
    my $op=[OutputFile => $fh];
    my $d=$obj->perl_to_xml($hash,$op);

=cut

sub perl_to_xml {

    my ($self,$perl_ref,$options)=@_;
    
    my $xs = XML::Simple->new(@$options);
    my $xml= $xs->XMLout($perl_ref) or die $!;

    return $xml;

}

=head2  yaml_to_perl($yaml_ref)

    Converts YAML hashes into perl.
    
         $yaml_ref - can be YAML string /YAML syntax file
    
    returns  reference to perl hash

=head3    EXAMPLES:
    
    1)
        $cat m.yaml
        ---
        age: 43
        department: Operations
        name: John Doe
        sex: M

        my $b=$obj->yaml_to_perl('m.yml');
        print Dumper($b);

        $VAR1 = { 
            'department' => 'Operations',
            'name' => 'John Doe',
            'sex' => 'M',
            'age' => '43'
        };
    2)
        my $string='---
        age: 43
        department: Operations
        name: John Doe
        sex: M
        ';

        my $b=$obj->yaml_to_perl($string);
        print Dumper($b);

        $VAR1 = {
            'department' => 'Operations',
            'name' => 'John Doe',
            'sex' => 'M',
            'age' => '43'
        };

=cut

sub yaml_to_perl {
    
    my ( $self, $yaml_ref)=@_;
   
    my $perl_ref;

    if( $yaml_ref =~ m/.*\n.*/){

        $perl_ref= YAML::Load($yaml_ref);

    }elsif(-e $yaml_ref){

        $perl_ref= YAML::LoadFile($yaml_ref);
    }else {

        die "YAML file/string not found for conversion\n";

    }

   return $perl_ref;
}


=head2  yaml_to_xml($yaml_ref,$options)
    
    Convert YAML string/file into XML file/string
        
         $yaml_ref - can be YAML string /YAML syntax file
         $options  - you are free to use XML::Simple options
                     [ OutputFile => $file_handle ]

    Returns XML string. Incase of writing to file returns 1;

=head3    EXAMPLES:
    
    my $xml_string=$obj->yaml_to_xml($yaml_ref);

    #to write XML to file 
    open ( $c,">", "kl.xml") or die $!;
    my $op=[OutputFile=>$c];
    my $return_val=$obj->yaml_to_xml($yaml_ref,$op); #returns 1 on success

=cut


sub yaml_to_xml {

    my ( $self,$yaml_ref,$options) =@_;

    my $perl_ref;

    if( $yaml_ref =~ m/.*\n.*/){

        $perl_ref= YAML::Load($yaml_ref);

    }elsif(-e $yaml_ref){

        $perl_ref= YAML::LoadFile($yaml_ref);
    } else {

        die "YAML file/string not found for conversion\n";

    }
 
    my $xs = XML::Simple->new(@$options);
    my $xml= $xs->XMLout($perl_ref) or die $!;

    return $xml;

}

=head1 AUTHOR

Feel free to abuse or praise me.

Ravi Chandra. M, C<< <rchandram\ at cpan.org> >>

=head1 CHANGES

2011-08-18, v1.0.0 - rchandram

=head1 BUGS

Please report any bugs or feature requests to C<bug-util-xml_yaml_perl at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Util-XML_YAML_Perl>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Util::XML_YAML_Perl


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Util-XML_YAML_Perl>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Util-XML_YAML_Perl>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Util-XML_YAML_Perl>

=item * Search CPAN

L<http://search.cpan.org/dist/Util-XML_YAML_Perl/>

=back


=cut

1;

