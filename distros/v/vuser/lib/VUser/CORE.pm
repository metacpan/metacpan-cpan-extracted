package VUser::CORE;
use warnings;
use strict;

# Copyright 2004 Randy Smith
# $Id: CORE.pm,v 1.26 2007-09-21 20:40:19 perlstalker Exp $

use vars qw(@ISA);

our $REVISION = (split (' ', '$Revision: 1.26 $'))[1];
our $VERSION = "0.4.4";

use Pod::Usage;

use VUser::Meta;
use VUser::ResultSet;
use VUser::Extension;
push @ISA, 'VUser::Extension';

sub config_file
{
    my $cfg = shift;
    my $opts = shift;

    print ("Current config file: ", tied (%$cfg)->GetFileName, "\n");
}

sub config_sample
{
    my $cfg = shift;
    my $opts = shift;

    my $fh;
    if (defined $opts->{file}) {
	open ($fh, ">".$opts->{file})
	    or die "Can't open '".$opts->{file}."': $!\n";
    } else {
	$fh = \*STDOUT;
    }

    print $fh <<'CONFIG';
[vuser]
# Enable debugging
debug = yes

# Space delimited list of extensions to load
# extensions = asterisk courier
extensions = courier

CONFIG

    if (defined $opts->{file}) {
	close $fh;
    }
}

sub config_inc {
    my $cfg = shift;
    my $opts = shift;

    my $rs = VUser::ResultSet->new();
    $rs->add_meta(VUser::Meta->new('name' => 'path',
				   'type' => 'string',
				   'description' => 'Include path')
		  );
    foreach my $path (@INC) {
	$rs->add_data([$path]);
    }

    return $rs;
}

sub version
{
    my $cfg = shift;
    my $opts = shift;

    my $rs = VUser::ResultSet->new();
    $rs->add_meta(VUser::Meta->new('name' => 'extension',
				   'type' => 'string',
				   'description' => 'Extension name'));
    $rs->add_meta(VUser::Meta->new('name' => 'version',
				   'type' => 'string',
				   'description' => 'Version number'));
    $rs->add_data(['CORE', $VERSION]);
    return $rs;
}

sub revision
{
    my $cfg = shift;
    my $opts = shift;

    my $rs = VUser::ResultSet->new();
    $rs->add_meta(VUser::Meta->new('name' => 'extension',
				   'type' => 'string',
				   'description' => 'Extension name'));
    $rs->add_meta(VUser::Meta->new('name' => 'version',
				   'type' => 'string',
				   'description' => 'Revision number'));
    $rs->add_data(['CORE', $REVISION]);
    return $rs;
}

sub help
{
#    pod2usage('-verbose' => 1);
    my $cfg = shift;
    my $opts = shift;
    my $keyword = shift; # The 'action' for help is the keyword see details of
    my $eh = shift;

    use FindBin;

    my @keywords = $eh->get_keywords();
    if ($keyword and $eh->is_keyword($keyword)) {
	my $descr = $eh->get_description($keyword);
	print "Run '$FindBin::Script help' to see all available keywords.\n";
	print "Options marked with '*' are required.\n";
	printf "** $keyword - %s\n", defined $descr? $descr : 'No description';
	my @actions = $eh->get_actions($keyword);
	foreach my $action (@actions) {
	    $descr = $eh->get_description($keyword, $action)
		|| 'No description';
	    printf ("%8s - %s\n", $action, $descr);
	    my @opts = $eh->get_options($keyword, $action);
	    foreach my $opt (@opts) {
		$descr = $eh->get_description($keyword, $action, $opt)
		    || 'No Description';
		printf("\t%-16s %s - %s\n",
		       "--$opt",
		       ($eh->is_required($keyword, $action, $opt))? '*' : ' ',
		       $descr);
	    }
	}
    } else {
	print "Run '$FindBin::Script help <keyword>' for more details.\n";
	print "Keywords: \n";
	foreach my $keyword (@keywords) {
	    my $descr = $eh->get_description($keyword) || 'No description';
	    printf ("%18s - %s\n", $keyword, $descr);
		    
	}
    }
}

sub man
{
    my $cfg = shift;
    my $opts = shift;
    my $keyword = shift; # The 'action' for help is the keyword see details of
    my $eh = shift;

    if ($keyword) {
	local $ENV{PERL5LIB} .= ':'.join ':',@INC;
	system('perldoc', 'VUser::'.$keyword);
    } else {
        pod2usage('-verbose' => 2);
    }
}

sub init
{
    my $eh = shift; # ExtHandler
    my %cfg = @_;

    # Config
    $eh->register_keyword('config', 'Get information about the configuration.');
    $eh->register_action('config', 'file', 'Print the current config file.');
    $eh->register_task('config', 'file', \&config_file, 0);

#    $eh->register_action('config', 'sample', 'Print a sample config file.');
#    $eh->register_task('config', 'sample', \&config_sample, 0);
#    $eh->register_option('config', 'sample', 'file', '=s', 0, 'Write the sample to this file.');

    $eh->register_action('config', 'inc', 'Get the include paths');
    $eh->register_task('config', 'inc', \&config_inc, 0);

    # Help
    $eh->register_keyword('help', 'Print help/usage information.');
    $eh->register_action('help', '*', 'Get help for specific keyword.');
    $eh->register_task('help', '*', \&help);

    # Man
    $eh->register_keyword('man', 'Print documentation');
    $eh->register_action('man', '*');
    $eh->register_task('man', '*', \&man);

    # Version
    $eh->register_keyword('version', 'Show version information.');
    $eh->register_action('version', '');
    $eh->register_task('version', '', \&version);
}

sub unload { };

1;

__END__

=head1 NAME

CORE - vuser core extensions

=head1 DESCRIPTION

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
