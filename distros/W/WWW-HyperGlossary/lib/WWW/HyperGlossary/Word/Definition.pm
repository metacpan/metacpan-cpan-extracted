package WWW::HyperGlossary::Word::Definition;
use base qw(WWW::HyperGlossary::Base);
use Class::Std;
use Class::Std::Utils;
use DBI;
use DBIx::MySperql qw(DBConnect SQLExec $dbh);
use Digest::MD5 qw (md5_hex);

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.2');

{
	my %definition_id_of : ATTR( :init_arg<definition_id> );
	my %word_id_of     : ATTR( :init_arg<word_id> );
	my %language_id_of : ATTR( :init_arg<language_id> );
	my %word_of        : ATTR( :init_arg<word> );

	sub get_word_id       { my ($self)  = @_; return $word_id_of{ident $self}; }
	sub get_language_id   { my ($self)  = @_; return $language_id_of{ident $self}; }
	sub get_word          { my ($self)  = @_; return $word_of{ident $self}; }
	sub get_definition_id { my ($self)  = @_; return $definition_id_of{ident $self}; }

	sub BUILD {      
		my ($self, $ident, $arg_ref) = @_;

		return;
	}

	sub get_definitions {
	}
	
}

1; # Magic true value required at end of module
__END__

=head1 NAME

WWW::HyperGlossary::Word::Definition - Online Hyperglossary for Eductation


=head1 VERSION

This document describes WWW::HyperGlossary::Word version 0.0.2


=head1 SYNOPSIS

    use WWW::HyperGlossary;

  
=head1 DESCRIPTION

The HyperGlossary inserts links on glossary-specific words with definitions and 
related multi-media resources.

=head1 DEPENDENCIES

 Class::Std
 Class::Std::Utils
 YAML
 Carp
 LWP::Simple
 DBIx::MySperql
 Digest::MD5

=head1 AUTHORS

Feel free to email the authors with questions or concerns. Please be patient for a reply.

=over 

=item * Roger Hall (roger@iosea.com), (rahall2@ualr.edu) 

=item * Michael Bauer (mbkodos@gmail.com), (mabauer@ualr.edu) 

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009, the Authors

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
