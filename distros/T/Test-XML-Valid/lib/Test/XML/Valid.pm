
package Test::XML::Valid;
use XML::LibXML;
use strict;
use Test::Builder;
use vars qw/$VERSION/;

$VERSION = "0.04";

my $Test = Test::Builder->new;

sub import {
    my $self = shift;
    my $caller = caller;
    no strict 'refs';
    *{$caller.'::xml_file_ok'}          = \&xml_file_ok;
    *{$caller.'::xml_string_ok'}        = \&xml_string_ok;

#     *{$caller.'::xml_fh_ok'}            = \&xml_fh_ok;
#     *{$caller.'::xml_html_file_ok'}     = \&xml_html_file_ok;
#     *{$caller.'::xml_html_fh_ok'}       = \&xml_html_fh_ok;
#     *{$caller.'::xml_html_string_ok'}   = \&xml_html_string_ok;
#     *{$caller.'::xml_sgml_file_ok'}     = \&xml_sgml_file_ok;
#     *{$caller.'::xml_sgml_fh_ok'}       = \&xml_sgml_fh_ok;
#     *{$caller.'::xml_sgml_string_ok'}   = \&xml_sgml_string_ok;

    $Test->exported_to($caller);
    $Test->plan(@_);
}


=head1 NAME

    Test::XML::Valid - Validate XML and XHTML

=head1 SYNOPSIS

  use Test::XML::Valid;

  xml_file_ok($xmlfilename);
  xml_string_ok($xml_string);

=head1 DESCRIPTION

Tests for Valid XHTML (using XML::LibXML). If the XML is not valid, a message
will be generated  with specific details about where the parser failed.

=head1 FUNCTIONS

=head2 xml_file_ok( I<$xmlfilename>, I<$msg> );

Checks that I<$xmlfilename> validates. I<$msg> is optional.  

=head2 xml_string_ok( I<$xmlstring>, I<$msg> );

Checks that I<$xml_string> validates. I<$msg> is optional.  

=cut


=head1 AUTHOR

    Mark Stosberg <mark@summersault.com>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

sub xml_file_ok {
    my $xmlfilename = shift;
    my $msg = shift || "$xmlfilename is valid XHTML";

    eval {  
        my $parser = XML::LibXML->new;
        $parser->validation(1);
        $parser->parse_file($xmlfilename);
    };
    
    my $ok = !$@;
    $Test->ok($ok,$msg);
    $Test->diag($@) unless $ok;
    return $ok;
}


sub xml_string_ok {
    my $xml_string = shift;
    my $msg = shift || "valid XHTML";

    eval {  
        my $parser = XML::LibXML->new;
        $parser->validation(1);
        $parser->parse_string($xml_string);
    };
    
    my $ok = !$@;
    $Test->ok($ok,$msg);
    $Test->diag($@) unless $ok;
    return $ok;
}



1; #this line is important and will help the module return a true value
__END__

