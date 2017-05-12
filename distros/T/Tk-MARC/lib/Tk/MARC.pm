package Tk::MARC;

our $VERSION = '1.5';

use Tk::MARC::Record;

1;
__END__

=head1 NAME

Tk::MARC - Perl/Tk widget set for editing MARC::Records

=head1 SYNOPSIS

 use Tk;
 use Tk::MARC::Record;
 use MARC::Record
 use MARC::File::USMARC;

 # Get a record
 my $file = MARC::File::USMARC->in( "records.mrc" );
 my $record = $file->next();
 $file->close();
 undef $file

 my $mw = MainWindow->new;
 my $TkMARC = $mw->MARC_Record(-record => $record)->pack;

 my $new_rec;
 $mw->Button(-text = "Save", -command => sub { $new_rec = $TkMARC->get() } );

 MainLoop;


=head1 CONTENTS

 Tk::MARC::Record
 Tk::MARC::Field
 Tk::MARC::Subfield
 Tk::MARC::Indicators
 Tk::MARC::Leader

=head1 DESCRIPTION

 A collection of Perl/Tk widgets for editing MARC::Record objects.

 A little short on POD right now... 
 See the examples in the pl/ directory (especially the sample app
 'marvin.pl', rough though it is).

=head1 SEE ALSO

MARC::Record
MARC::Descriptions

=head1 AUTHOR

David A. Christensen, DChristensenSPAMLESS@westman.wave.ca

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by David A. Christensen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
