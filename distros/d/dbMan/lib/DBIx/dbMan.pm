package DBIx::dbMan;

=comment
	dbMan 0.40
	(c) Copyright 1999-2014 by Milan Sorm, sorm@is4u.cz
	All rights reserved.

	This software provides some functionality in database managing
	(SQL console).

	This program is free software; you can redistribute it and/or modify it
	under the same terms as Perl itself.
=cut

use strict;
use DBIx::dbMan::Config;	# configuration handling package
use DBIx::dbMan::Lang;		# I18N package - EXPERIMENTAL
use DBIx::dbMan::DBI;		# dbMan DBI interface package
use DBIx::dbMan::MemPool;	# dbMan memory management system package
use Data::Dumper;

our $VERSION = '0.40';

# constructor, arguments are hash of style -option => value, stored in internal attributes hash
sub new {
	my $class = shift;
	my $obj = bless { @_ }, $class;
	return $obj;
}

# main loop of dbMan life-cycle, called from exe file
sub start {
	my $obj = shift;	# main dbMan core object

	$obj->{-trace} = $ENV{DBMAN_TRACE} || 0; # standard extension tracing activity - DISABLED

	# what interface exe file want ??? making package name from it
	my $interface = $obj->{-interface};
	$interface = 'DBIx/dbMan/Interface/'.$interface.'.pm';

	# we try to require interface package - found in @INC, syntax check,
	# load it by require instead of use because we know only filename
	eval { require $interface; };
	if ($@) { 			# if something goes wrong
		$interface =~ s/\//::/g;  $interface =~ s/\.pm$//;

		# bad information for user :-(
		print STDERR "Can't locate interface module $interface\n";
		return;		# see you later...
	}

	# making class name from interface package filename
	$interface =~ s/\//::/g;  $interface =~ s/\.pm$//;

	# creating memory management object - mempool
	$obj->{mempool} = new DBIx::dbMan::MemPool;

	# creating configuration object
	$obj->{config} = new DBIx::dbMan::Config;

	# creating I18N specifics object with configuration object as argument
	$obj->{lang} = new DBIx::dbMan::Lang -config => $obj->{config};

	# creating loaded interface object, all objects as arguments
	# included dbMan core object
	$obj->{interface} = $interface->new(-config => $obj->{config},
		-lang => $obj->{lang}, -mempool => $obj->{mempool}, -core => $obj);

	# we have interface now, we can produce messages and errors by object
	# method $obj->{interface}->print('what we can say to user...')

	# dbMan interface, please introduce us to our user (welcome message, splash etc.)
	$obj->{interface}->hello();

	# creating dbMan DBI object - encapsulation of DBI with multiple connections
	# support, configuration, interface and mempool as arguments
	$obj->{dbi} = new DBIx::dbMan::DBI -config => $obj->{config},
		-interface => $obj->{interface}, -mempool => $obj->{mempool};

	# looking for and loading all extensions
	$obj->load_extensions;

	# we say to the interface that extensions are loaded and menu can be build
	$obj->{interface}->rebuild_menu();

	# main loop derived by interface - get_action & handle_action calling cycle
	# NOT CALLED if we are in $main::TEST mode (tested initialization from make test)
	$obj->{interface}->loop() unless defined $main::TEST && $main::TEST;

	# unloading all loaded extensions
	$obj->unload_extensions;

	# close all opened DBI connections by dbMan DBI object
	$obj->{dbi}->close_all();

	# dbMan interface, please say good bye to our user...
	$obj->{interface}->goodbye();

	# test result OK if we are in $main::TEST mode (tested initialization from make test)
	$main::TEST_RESULT = 1 if defined $main::TEST && $main::TEST;

	# program must correctly exit if we want 'test ok' for make test' tests
	exit if $main::TEST_RESULT;
}

# looking for and loading extensions
sub load_extensions {
	my $obj = shift;		# main dbMan core object

	$obj->{extensions} = [];	# currently loaded extensions = no extensions

	# 1st phase : candidate searching algorithm
	my %candidates = ();		# what are my candidates for extensions ?
	for my $dir ($obj->extensions_directories) {	# all extensions directories
		opendir D,$dir;				# search in directory
		for (grep /\.pm$/,readdir D) { 		# for each found package
			eval { require "$dir/$_"; };	# try to require
			next if $@;			# not candidate if fail
			s/\.pm$//;			# make class name from filename
			my $candidate = "DBIx::dbMan::Extension::".$_;

			# search for extension version limit (class method) - low and high
			my ($low,$high) = ('',''); 
			eval { ($low,$high) = $candidate->for_version(); };

			# not candidate if our version isn't between low and high
			# we must delete filename from include list
			if (($low and $VERSION < $low) or ($high and $VERSION > $high)) 
				{ delete $INC{"$dir/$_.pm"};  next; }

			# fetching identification from extension (class method)
			my $id = '';  eval { $id = $candidate->IDENTIFICATION(); };

			# not candidate if identification not specified
			unless ($id or $@) { delete $INC{"$dir/$_.pm"};  next; }

			# parsing identification AUTHOR-MODULE-VERSION
			my ($ident,$ver) = ($id =~ /^(.*)-(.*)$/);

			# not candidate if AUTHOR-MODULE isn't overloaded
			if ($ident eq '000001-000001') { delete $INC{"$dir/$_.pm"};  next; }

			# deleting filename from include list
			delete $INC{"$dir/$_.pm"};

			# not candidate if exist this identification with same or higher version
			next if exists $candidates{$ident} && $candidates{$ident}->{-ver} >= $ver;

			# save candidate to candidates list
			$candidates{$ident} = 
				{ -file => "$dir/$_.pm", -candidate => $candidate, -ver => $ver }; 
		};
		
		closedir D;			# close searched directory
	}

	# 2nd phase : candidate loading algorithm
	my %extensions = ();			# all objects of extensions

	$obj->{extension_iterator} = 0;		# randomize iterator
	for my $candidate (keys %candidates) {	# for each candidate
		my $ext = undef;		# undefined extension
		eval {				# try require file and create object
			require $candidates{$candidate}->{-file};

			# object pass all five instances of base objects as argument
			$ext = $candidates{$candidate}->{-candidate}->new(
				-config => $obj->{config}, 
				-interface => $obj->{interface},
				-dbi => $obj->{dbi},
				-core => $obj,
				-mempool => $obj->{mempool});

			die unless $ext->load_ok();
		};
		if (defined $ext and not $@) {	# successful loading ?
			my $preference = 0;	# standard preference level
			eval { $preference = $ext->preference(); }; # trying to fetch preference

			# sorting criteria are: preference, random iterator
			# saving sort criteria for later using
			$ext->{'___sort_criteria___'} = $preference.'_'.$obj->{extension_iterator};

			# save instance of object to hash indexed by preference
			$extensions{$preference.'_'.$obj->{extension_iterator}} = $ext;

			++$obj->{extension_iterator};	# increase random iterator
		}
	}

	# 3rd phase : building candidates list sorted by preference (for action handling)
	for (sort { 	# sorting criteria - first time by preference, second time loading order
			my ($fa,$sa,$fb,$sb) = split /_/,$a.'_'.$b; 
			($fa == $fb)?($sa <=> $sb):($fb <=> $fa);
		} keys %extensions) {		# for all loaded extensions

		# save extension into sorted list
		push @{$obj->{extensions}},$extensions{$_};

		# call init() for initializing extension (all extensions in correct order)
		$extensions{$_}->init();
	}

	# all extensions are loaded and sorted by preference into $obj->{extensions} list
}

# unloading all extensions
sub unload_extensions {
	my $obj = shift;		# main dbMan core object

	for (@{$obj->{extensions}}) {	# for all extensions in standard order
		$_->done();		# call done() for finalizing extension
		undef $_; 		# destroy extension instance of object
	}
}

# produce list of all extensions directories
sub extensions_directories {
	my $obj = shift;		# main dbMan core object

	# grep criteria - only directories which contains DBIx/dbMan/Extension subfolder are wanted
	# tested dirs are: @INC, extensions_dir configuration directive, current folder
	# WARNING: i must call extensions_dir in list context if I want list of directories
	return grep { -d $_ } map { my $t = $_;  $t =~ s/\/$//; "$t/DBIx/dbMan/Extension" } 
		(@INC,($obj->{config}->extensions_dir?($obj->{config}->extensions_dir):()),'.');
}

# show tracing record via interface object
sub trace {
	my ($obj,$direction,$where,%action) = @_;	# main dbMan core object,
	# direction string (passed to interface), extension object and action record

	# change $where to readable form
	$where =~ s/=.*$//;  $where =~ s/^DBIx::dbMan::Extension:://;  my $params = '';
	for (sort keys %action) {	# for all actions
		next if $_ eq 'action';	# action tag ignore
		my $p = $action{$_};  $p = "'$p'" if $p !~ /^[-a-z0-9_.]+$/i;	# stringify
		$params .= ", " if $params;  $params .= "$_: $p";	# concat
	}

	# change non-selected chars in $params to <hexa> style
	$params = join '',		# joining transformed chars
		map { ($_ >= 32 && $_ <= 254 && $_ != 127)?chr:sprintf "<%02x>",$_; }
		unpack "C*",$params;		# disassemble $params into chars

	# sending tracing report via interface object
	$obj->{interface}->trace("$direction $where / $action{action} / $params\n");
}

# main loop for handling one action
sub handle_action {
	my ($obj, %action) = @_;		# main dbMan core object, action to process

	$action{processed} = undef;		# save signature of old action for deep recursion test
	my $oldaction = \%action;
	
	for my $ext (@{$obj->{extensions}}) {	# going down through all extensions in preference order
		$action{processed} = 1;
		last if $action{action} eq 'NONE';	# stop on NONE actions

		my $acts = undef;
		eval { $acts = $ext->known_actions; };	# hack - which actions extension want ???
		next if $@ || (defined $acts && ref $acts eq 'ARRAY' && 
				! grep { $_ eq $action{action} } @$acts);   # use hacked knowledge

		$obj->trace("<==",$ext,%action) if $obj->{-trace};	# trace if user want

		$action{processed} = undef;		# standard behaviour - action not processed
		eval { %action = $ext->handle_action(%action); };	# handling action
		if ($@) { # error - exception
			$obj->{interface}->print("Exception catched: $@\n");
			$action{processed} = 1;
			$action{action} = 'NONE';
		}

		$obj->trace("==>",$ext,%action) if $obj->{-trace};	# trace if user want

		last unless $action{processed};		# action wasn't processed corectly 
			# ... prefix probably set - return to get_event (and called once again we hope)
	}

	$obj->{-deep_detected} = 0;

	# deep recursion detection
	unless ($action{processed}) {
		my $newaction = \%action;
		if ($obj->compare_struct($oldaction,$newaction)) {
			if ($obj->{-deep_detected} >= 100) {
				$obj->trace("Deep recursion detected...\n",'- new:',%action);
				$obj->trace("",'- old:',%$oldaction);
				$action{processed} = 1;
			} else {
				++$obj->{-deep_detected};
			}
		}
	}

	# action processed correctly, good bye with modified action record
	return %action;
}

# return 1 if structs are identical
sub compare_struct {
	my $obj = shift;
	my ($a,$b) = @_;

	my $first = Data::Dumper->Dump([$a]);
	my $second = Data::Dumper->Dump([$b]);
	return $a eq $b;

	return 0;
}

1;	# all is O.K.
