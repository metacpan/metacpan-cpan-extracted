############################################################
#
#   $Id: Dilbert.pm,v 1.3 2006/01/09 21:34:19 nicolaw Exp $
#   WWW::Comic::Plugin::Dilbert - Dilbert of the Day plugin for WWW::Comic
#
#   Copyright 2006 Nicola Worthington
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
############################################################

package WWW::Comic::Plugin::Dilbert;
# vim:ts=4:sw=4:tw=78

use strict;
use WWW::Dilbert qw();

use vars qw($VERSION @ISA %COMICS);
$VERSION = sprintf('%d.%02d', q$Revision: 1.3 $ =~ /(\d+)/g);
@ISA = qw(WWW::Comic::Plugin);
%COMICS = ( dilbert => 'Dilbert of the Day' );

sub new {
	my $class = shift;
	my $self = { comics => \%COMICS };
	bless $self, $class;
	return $self;
}

sub strip_url {
	my $class = shift;
	my %param = @_;
	return WWW::Dilbert::strip_url($param{id});
}

sub get_strip {
	my $class = shift;
	my %param = @_;
	return WWW::Dilbert::get_strip($param{url} || $param{id});
}

sub mirror_strip {
	my $class = shift;
	my %param = @_;
	my @opts = ();
	push @opts, $param{filename} if exists $param{filename};
	push @opts, $param{url} if exists $param{url};
	push @opts, $param{id} if exists $param{id};
	return WWW::Dilbert::mirror_strip(@opts);
}

1;

=pod

=head1 NAME

WWW::Comic::Plugin::Dilbert - Dilbert of the Day plugin for WWW::Comic

=head1 SYNOPSIS

See L<WWW::Comic>.

This plugin requires L<WWW::Dilbert>.

=head1 VERSION

$Id: Dilbert.pm,v 1.3 2006/01/09 21:34:19 nicolaw Exp $

=head1 AUTHOR

Nicola Worthington <nicolaw@cpan.org>

L<http://perlgirl.org.uk>

=head1 COPYRIGHT

Copyright 2006 Nicola Worthington.

This software is licensed under The Apache Software License, Version 2.0.

L<http://www.apache.org/licenses/LICENSE-2.0>

=cut

