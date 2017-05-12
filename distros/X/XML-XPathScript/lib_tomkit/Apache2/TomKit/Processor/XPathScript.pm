package Apache2::TomKit::Processor::XPathScript;

use strict;
use warnings;
use Carp;

use base qw( Apache2::TomKit::Processor::AbstractProcessor XML::XPathScript );

use Apache2::TomKit::Processor::DefinitionProvider::FileSystemProvider;
use XML::LibXML;

our $VERSION = '1.53';

sub new {
    my $class  = shift;
    my $logger = shift;
    my $config = shift;
    my $processordef   = shift;
    my $getMappingType = shift;

    my $this = $class->SUPER::new($logger,$config);

    $this->{processordef}   = new Apache2::TomKit::Processor::DefinitionProvider::FileSystemProvider( $logger, $config, $processordef );
    $this->{stylesheet}     = undef;
    $this->{getMappingType} = $getMappingType;

    return $this;
}


sub init { }

sub setUp {
    my $this = shift;

    return if( $this->{stylesheet} );

    if( $this->{processordef}->isFile() ) {
        open my $STYLESHEET, $this->{processordef}->getInstructions();
        local $/ = undef;
        $this->set_stylesheet( <$STYLESHEET> );
    } else {
        $this->set_stylesheet( $this->{processordef}->getInstructions() );
    }
    
    $this->{logger}->debug( 9, "XPathScript: stylesheet is $this->{stylesheet}" );

}

sub process {
    my $this = shift;
    my $input = shift;

    $this->{logger}->debug( 9,
        "XPathScript: Is processing the source with stylesheet: " . $this->{processordef} );

    $this->set_xml( $input );
	$this->{logger}->debug( 9, "XPathScript: source is $input" );
	
	my $output;
	$this->{printer} = \$output;

	{
		local *ORIGINAL_STDOUT;
		*ORIGINAL_STDOUT = *STDOUT;
   		local *STDOUT;

		# Perl 5.6.1 dislikes closed but tied descriptors (causes SEGVage)
   		*STDOUT = *ORIGINAL_STDOUT if $^V lt v5.7.0; 

	   	tie *STDOUT, 'XML::XPathScript::StdoutSnatcher';
	   	my $retval = $this->compile()->( $this );
	   	untie *STDOUT;
	}
	
	$this->{logger}->debug( 9, "XPathScript: output is $output" );
	
	my $parser = XML::LibXML->new();
	return $parser->parse_string( $output );

}

sub getMTime {
    my $this = shift;
    return $this->{processordef}->getMTime();
}

sub createsXML {
    0;
}

#sub getKey {
#    return $_[0]->{processordef}->getMD5Key();
#}

sub createsDom {
    1;
}

sub getContentType {
    return "text/html";
}

sub getMappingType {
    return $_[0]->{getMappingType}
}

sub getProcessorDefinition {
    return $_[0]->{processordef}->getKey();
}


1;

__END__

=head1 NAME

Apache2::TomKit::Processor::XPathScript - XPathScript Processor for TomKit

=head1 SYNOPSIS

 # in the relevant .htaccess
 PerlSetVar AxAddProcessorMap "text/xps=>Apache2::TomKit::Processor::XPathScript"

 <Files *\.xml>
     PerlFixupHandler Apache2::TomKit
     PerlSetVar AxAddProcessorDef "text/xps=>stylesheet.xps"
 </Files>

=head1 BUGS

Please send bug reports to <bug-xml-xpathscript@rt.cpan.org>,
or via the web interface at 
http://rt.cpan.org/Public/Dist/Display.html?Name=XML-XPathScript .

=head1 AUTHOR 

Yanick Champoux <yanick@cpan.org>

Original Axkit::Apache::AxKit::Language module 
by Matt Sergeant <matt@sergeant.org>


