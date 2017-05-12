package VUser::Test;
use warnings;
use strict;

# Copyright 2004 Randy Smith
# $Id: Test.pm,v 1.5 2006-01-04 21:57:48 perlstalker Exp $

our $REVISION = (split (' ', '$Revision: 1.5 $'))[1];
our $VERSION = "0.3.0";

use vars qw(@ISA);
use VUser::Extension;
use VUser::Log qw(:levels);
use VUser::Meta;
use VUser::ResultSet;
push @ISA, 'VUser::Extension';

my $log;

sub revision
{
    my $self = shift;
    my $type = ref($self) || $self;
    no strict 'refs';
    return ${$type."::REVISION"};
}

sub version
{
    my $self = shift;
    my $type = ref($self) || $self;
    no strict 'refs';
    return ${$type."::VERSION"};
}

sub init
{
    my $eh = shift;
    my %cfg = @_;

    $log = $main::log;

    my %meta = ('foo', VUser::Meta->new(name => 'foo',
					description => 'Random option',
					type => 'string')
		);

    $eh->register_keyword('test', 'Test keyword. Don\'t use in production.');

    $eh->register_meta('test', VUser::Meta->new(name => 'bar',
						description => 'option bar',
						type => 'string')
	);

    $eh->register_action('test', '*');
    $eh->register_option('test', '*', $meta{foo});
    $eh->register_task('test', '*', \&test_task);

    $eh->register_action('test', 'meta', 'Dump meta data');
    $eh->register_option('test', 'meta', $meta{foo});
    $eh->register_option('test', 'meta', VUser::Meta->new(name => 'keyword',
							  description => "See meta data for this keyword",
							  type => 'string'));
    $eh->register_option('test', 'meta', $eh->get_meta('test', 'bar'));
    $eh->register_task('test', 'meta', \&dump_meta);

    $eh->register_action('test', 'rs', 'Test ::ResultSet');
    $eh->register_task('test', 'rs', \&test_rs);
}

sub unload { return; }

sub test_task
{
    my ($cfg, $opts, $action, $eh) = @_;

    print "This is only a test. action $action\n";
    use Data::Dumper; print Dumper $opts;
    
    $log->log(LOG_NOTICE, "Testing action %s", $action);
}

sub dump_meta
{
    my ($cfg, $opts, $action, $eh) = @_;

    my $key = $opts->{keyword} || 'test';
    
    print "Dumping meta data for keyword '$key':\n";

    my @meta = $eh->get_meta($key);
    use Data::Dumper; print Dumper \@meta;
}

sub test_rs {
    my ($cfg, $opts, $action, $eh) = @_;

    my $rs = VUser::ResultSet->new();

    $rs->add_meta(VUser::Meta->new('name' => 'str',
				   'type' => 'string',
				   'description' => 'A string'));
    $rs->add_meta(VUser::Meta->new('name' => 'int',
				   'type' => 'integer',
				   'description' => 'An int'));

    $rs->add_data(["blue", 2]);
    $rs->add_data(["answer", 42]);

    $rs->error_code(97);
    $rs->add_error("foo: %s", "bar");

    return $rs;
}

1;

__END__

=head1 NAME

VUser::Test - A test extension.

=head1 DESCRIPTION

=head1 METHODS

=head2 init

Called when an extension is loaded when vuser starts.

init() will be passed an reference to an ExtHandler object which may be
used to register keywords, actions, etc. and the tied config object.

=head2 unload

Called when an extension is unloaded when vuser exits.

=head2 revision

Returns the extension's revision. This is may return an empty string;

=head2 version

Returns the extensions official version. This man not return an empty string.

=head1 AUTHOR

Randy Smith <perlstalker@gmail.com>

=head1 LICENSE
 
 This file is part of vuser.
 
 vuser is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 vuser is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with vuser; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut
