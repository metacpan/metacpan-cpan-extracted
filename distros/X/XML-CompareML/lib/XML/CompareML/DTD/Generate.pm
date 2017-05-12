package XML::CompareML::DTD::Generate;

use strict;
use warnings;

=head1 NAME

XML::CompareML::DTD::Generate - generate the DTD for CompareML.

=head1 SYNOPSIS

    use XML::CompareML::DTD::Generate;

    my $dtd_text = XML::CompareML::DTD::Generate::get_dtd();

=head1 FUNCTIONS

=head2 get_dtd()

Calculates and returns the DTD. Not exported.

=cut

sub get_dtd
{
    return <<"EOF";
<!ELEMENT comparison (meta,contents)>
<!ELEMENT meta (implementations,timestamp?)>
<!ELEMENT implementations (impl+)>
<!ELEMENT impl (name,url?,fullname?,vendor?)>
<!ELEMENT name (#PCDATA)>
<!ELEMENT url (#PCDATA)>
<!ELEMENT fullname (#PCDATA)>
<!ELEMENT vendor (#PCDATA)>
<!ELEMENT contents (section)>
<!ELEMENT section (title,expl?,compare?,section*)>
<!ELEMENT title (#PCDATA)>
<!ELEMENT expl (#PCDATA|a|b)*>
<!ELEMENT compare (s+)>
<!ELEMENT s (#PCDATA|a|b)*>
<!ELEMENT a (#PCDATA|b)*>
<!ELEMENT timestamp (#PCDATA)>
<!ELEMENT b (#PCDATA)>
<!ATTLIST section id ID #REQUIRED>
<!ATTLIST a href CDATA #REQUIRED>
<!ATTLIST s id CDATA #REQUIRED>
<!ATTLIST impl id CDATA #REQUIRED>
EOF
}

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/>.

=head1 SEE ALSO

L<XML::CompareML>

=head1 COPYRIGHT AND LICENSE

Copyright 2004, Shlomi Fish. All rights reserved.

You can use, modify and distribute this module under the terms of the MIT X11
license. ( L<http://www.opensource.org/licenses/mit-license.php> ).

=cut

1;
