package Tk::DBIx::Tree;
#------------------------------------------------
# automagically updated versioning variables -- CVS modifies these!
#------------------------------------------------
our $Revision           = '$Revision: 1.2 $';
our $CheckinDate        = '$Date: 2003/11/06 17:55:56 $';
our $CheckinUser        = '$Author: xpix $';
our $Version		= 1.5;
# we need to clean these up right here
$Revision               =~ s/^\$\S+:\s*(.*?)\s*\$$/$1/sx;
$CheckinDate            =~ s/^\$\S+:\s*(.*?)\s*\$$/$1/sx;
$CheckinUser            =~ s/^\$\S+:\s*(.*?)\s*\$$/$1/sx;
#-------------------------------------------------
#-- package Tk::DBIx::Tree -----------------------
#-------------------------------------------------


use DBIx::Tree;
use Tk::Tree;
use Tk::Compound;
use Tk::ItemStyle;
use Tk::ResizeButton;
use Term::ANSIColor;
use base qw/Tk::Derived Tk::Frame/;

use strict;

Construct Tk::Widget 'DBITree';

# ------------------------------------------
sub ClassInit
# ------------------------------------------
{
	my($class,$mw) = @_;

}

# ------------------------------------------
sub Populate {
# ------------------------------------------
	my ($obj, $args) = @_;
	my $style;

	$obj->{dbh} 		= delete $args->{'-dbh'} 	|| return error("No DB-Handle!");
	$obj->{table}		= delete $args->{'-table'} 	|| return error("No Table!");
	$obj->{debug} 		= delete $args->{'-debug'} 	|| 0;
	$obj->{idx}		= delete $args->{'-idx'}	|| return error("No IndexColumn!");
	$obj->{fields}		= delete $args->{'-fields'} 	|| return error("No Fields!");
	$obj->{textcolumn}	= delete $args->{'-textcolumn'} || return error("No Textcolumn!");
	$obj->{joiner}		= delete $args->{'-joiner'};
 	$obj->{start_id}	= delete $args->{'-start_id'} 	|| 1;
 	$obj->{command}		= delete $args->{'-command'};
	$obj->{parent_id}	= delete $args->{'-parent_id'} 	|| return error("No Parent_id!");
	$obj->{columnWidths}	= delete $args->{'-columnWidths'};
	$obj->{maxchars}	= delete $args->{'-maxchars'};
	$obj->{colNames}	= delete $args->{'-colNames'};
	$obj->{entry_create_cb}	= delete $args->{'-entry_create_cb'};
	$obj->{time_column}	= delete $args->{'-time_column'};
	$obj->{opencmd}		= delete $args->{'-opencmd'};
	$obj->{closecmd}	= delete $args->{'-closecmd'};

	my $h_style		= delete $args->{'-highlight'}	|| [-foreground => 'blue'];
	my $n_style		= delete $args->{'-normal'}	|| [-foreground => 'black'];
	$obj->{highlight}	= $obj->ItemStyle('imagetext', @{$h_style});
	$obj->{normal}		= $obj->ItemStyle('imagetext', @{$n_style});
	
	$obj->SUPER::Populate($args);

	
	my %specs;
	$specs{refresh} 	= [qw/METHOD refresh 		Refresh/, 		undef];
	$specs{close_all}	= [qw/METHOD close_all 		Close_all/, 		undef];
	$specs{listEntrys}	= [qw/METHOD listEntrys 	ListEntrys/, 		undef];
	$specs{remember}	= [qw/METHOD remember 		Remember/, 		undef];
	$specs{select_entrys}	= [qw/METHOD select_entrys 	Select_entrys/, 	undef];
	$specs{info}		= [qw/METHOD info 		Info/, 			undef];
	$specs{infozoom}	= [qw/METHOD infozoom 		InfoZoom/,		undef];
	$specs{color_all}	= [qw/METHOD color_all 		Color_All/, 		undef];
	$specs{color_clear}	= [qw/METHOD color_clear	Color_Clear/, 		undef];
	$specs{get_id}		= [qw/METHOD get_id 		Get_Id/, 		undef];
	$specs{parent_id}	= [qw/METHOD parent_id 		Parent_Id/, 		undef];
	$specs{see}		= [qw/METHOD see 		See/, 			undef];
	$specs{childs}		= [qw/METHOD childs 		Childs/, 		undef];

	$specs{neu}		= [qw/METHOD neu 		Neu/, 			undef];
	$specs{move}		= [qw/METHOD move 		Move/, 			undef];
	$specs{copy}		= [qw/METHOD copy 		Copy/, 			undef];
	$specs{dele}		= [qw/METHOD dele 		Dele/, 			undef];
	$specs{refresh_id}	= [qw/METHOD refresh_id		Refresh_Id/, 		undef];
	
        $obj->ConfigSpecs(%specs);

	$obj->{last_refresh_time} = 1;

	$obj->{tree} = $obj->Scrolled('Tree',
		-scrollbars 	=> 'osoe',
		-columns	=> scalar @{$obj->{fields}} + 1,
		-header		=> 1,
		-separator	=> ':',
	)->pack(-expand => 1,
		-fill => 'both');

	$obj->{tree}->configure(-opencmd => sub{ 
			$obj->{OPEN}->{$_[0]} = 'offen';
			my $ok = 1;
			$ok = &{$obj->{opencmd}}(@_)
				if(defined $obj->{opencmd} and ref $obj->{opencmd} eq 'CODE'); 
			if($ok) {
				$obj->refresh( undef, $_[0] );
			}
			$obj->{tree}->OpenCmd(@_)
		});
	$obj->{tree}->configure(-closecmd => sub{ 
			my $path = $_[0];
			my $ok = 1;
			foreach my $item (keys %{$obj->{OPEN}}) {
				delete $obj->{OPEN}->{$item}
					if($item =~ /^$path/);
			}
			$ok = &{$obj->{closecmd}}(@_)
				if(defined $obj->{closecmd} and ref $obj->{closecmd} eq 'CODE'); 
			if($ok) {
				$obj->{tree}->CloseCmd(@_)
			}
		});

	$obj->Advertise("tree" => $obj->{tree});

} # end Populate


# Class private methods;
# ------------------------------------------
sub refresh_id {
# ------------------------------------------
	my $obj = shift || return error('No Object');
	my $path = shift || return error('No Id');
	my $data = shift || $obj->info('data', $path);

	$path = $obj->id2path($path);

	return unless($obj->info('exists',$path));
	my ($id, $pid) = $obj->id($path);
	$obj->dele($path);
	$obj->neu($id, $pid, $data);
}

# ------------------------------------------
sub neu {
# ------------------------------------------
	my $obj = shift || return error('No Object');
	my $id	= shift || return error('No Id');
	my $to_parent 	= shift || return error('No To Id');
	my $data 	= shift || return error('No Data');
	my $ignore_status = shift || 0;

	$obj->debug('Neu - Id: %s, To_Parent: %s, Data %s', $id, $to_parent, $data);

	$data->{$obj->{idx}} = $id 
		unless $data->{$obj->{idx}};

	my ($iid, $pid) = $obj->id($id);
	my $new_path = sprintf('%s:%d', $to_parent, $iid );

	$obj->{tree}->setmode($to_parent, 'open')
		if($obj->{tree}->getmode($to_parent) eq 'none');

	$obj->debug('Ignore Status? <%s> Parent Exists? <%s> Getmode(Parent) <%s>', 
		($ignore_status ? 'yes' : 'no'),  
		$obj->info('exists', $to_parent), 
		$obj->{tree}->getmode($to_parent));
	return if(! $ignore_status and (! $obj->info('exists', $to_parent) or $obj->{tree}->getmode($to_parent) eq 'open'));

	$obj->{tree}->add($new_path, 
		-itemtype	=> 'imagetext', 
		-data 		=> $data, 
		-text 		=> $obj->parse_text($data->{$obj->{textcolumn}}, $obj->{textcolumn}),
		-style 		=> $obj->{normal},
		 );

	$obj->{tree}->setmode($new_path, 'open')
		if(defined $obj->{ptree}->{$iid});


	&{$obj->{entry_create_cb}}($obj->{tree}, $new_path, $data)
		if(defined $obj->{entry_create_cb} and ref $obj->{entry_create_cb} eq 'CODE');

	my $c = 1;
	foreach my $field (@{$obj->{fields}}) {
		$obj->{tree}->itemCreate( $new_path, $c++, 
			-text => $obj->parse_text($data->{$field}, $field),
			-style => $obj->{normal},
		);
	}
	push(@{$obj->{ListOfAllEntries}}, $new_path);
	$obj->{Paths}->{$id} = $new_path;
	return $new_path;
}

# ------------------------------------------
sub move {
# ------------------------------------------
	my $obj = shift || return error('No Object');
	my $from_entry 	= $obj->id2path(shift) || return error('No From Id');
	my $to_parent 	= shift || return error('No To Id');
	my $data 	= shift;

	my $to_path = $obj->{Paths}->{int $to_parent} || $obj->{Paths}->{$to_parent} || $obj->id2path($to_parent);
	my ($id, $pid) = $obj->id($from_entry);


	my $did = $obj->dele($from_entry)
		if($obj->info('exists',$from_entry));
	my $nid = $obj->neu($id, $to_path, $data)
		if($obj->info('exists',$to_path));

	$obj->{ListOfAllEntries} = $obj->rm_from_array($obj->{ListOfAllEntries}, $from_entry);
	push(@{$obj->{ListOfAllEntries}}, $nid)
		if($nid);

	return $nid;
}

# ------------------------------------------
sub copy {
# ------------------------------------------
	my $obj = shift || return error('No Object');
	my $from_entry 	= shift || return error('No From Id');
	my $to_parent 	= shift || return error('No To Id');
	my $data 	= shift;

	my ($id, $pid) = $obj->id($from_entry);
	my $to_entry = sprintf('%s:%d', $obj->{Paths}->{$to_parent}, $id);

	my $hl = $obj->{tree};

	return unless($obj->{tree}->infoExists($from_entry));
	return unless($obj->{tree}->infoExists($to_entry));

	my @entry_args;
	foreach ($hl->entryconfigure($from_entry)) {
		push @entry_args, $_->[0] => $_->[4] if defined $_->[4];
    	}

	$hl->add($to_entry, @entry_args);
	$hl->entryconfigure($to_entry, -data => $data) 
		if defined $data;

	foreach my $col (1 .. $hl->cget(-columns)-1) {
 		my @item_args;
 		foreach ($hl->itemConfigure($from_entry, $col)) {
     			push @item_args, $_->[0] => $_->[4] if defined $_->[4];
 		} 
 		$hl->itemCreate($to_entry, $col, @item_args);
    	}
	$obj->refresh_id($to_entry, $data);
	push(@{$obj->{ListOfAllEntries}}, $to_entry);
	$obj->{Paths}->{$id} = $to_entry;
	return $to_entry;
}

# ------------------------------------------
sub dele {
# ------------------------------------------
	my $obj = shift || return error('No Object');
	my $id = shift || return error('No Id');

	my $parent = $obj->info('parent', $id) || return;

	$obj->{tree}->deleteEntry($id);
	$obj->{ListOfAllEntries} = $obj->rm_from_array($obj->{ListOfAllEntries}, $id);
	$obj->{tree}->setmode($parent, 'none')
		if( ! $obj->info('children', $parent) );

	my ($iid, $pid) = $obj->id($id);
	delete $obj->{Paths}->{ $iid };

	return $id;
}

# ------------------------------------------
sub refresh {
# ------------------------------------------
	my $obj = shift || return error('No Object');
	my $redraw = shift || $obj->Table_is_Change($obj->{last_refresh_time}, $obj->{table});
	my $item = shift;

	$obj->Busy;

	$obj->debug('Refresh: redraw = %s, item = %s', 
		(defined $redraw ? $redraw : 'NONE'), 
		(defined $item ? $item : 'NONE')
	);
	
	return if(! defined $redraw && ! defined $item);

	if(defined $redraw and $redraw) {
		$obj->debug('Redraw! %s', $item);
		@{$obj->{ListOfAllEntries}} = ();
		$obj->{Paths} = {};
		$obj->{tree}->delete('all');
	}
	
	unless(defined $obj->{tree_buttons}) {
		my $c = -1;
		foreach my $name ($obj->{textcolumn}, @{$obj->{fields}}) {
			$c++;
			$obj->{tree_buttons}->{$name} = $obj->{tree}->ResizeButton( 
			  -text 	=> $obj->{colNames}->[$c] || $name, 
			  -relief 	=> 'flat', 
			  -border	=> -2,
			  -pady 	=> -10, 
			  -padx 	=> 10, 
			  -widget 	=> \$obj->{tree},
			  -column 	=> $c,
			);

			$obj->Advertise(sprintf("HB_%s",$name) => $obj->{tree_buttons}->{$name});

			$obj->{tree}->headerCreate($c, 
				-itemtype => 'window',
				-widget	  => $obj->{tree_buttons}->{$name}, 
			);

			$obj->{tree}->columnWidth($c, $obj->{columnWidths}->[$c]) 
				if(defined $obj->{columnWidths}->[$c]);

		}	
	}
	
	$obj->{dbtree} = DBIx::Tree->new( 
		connection => $obj->{dbh}, 
		sql	   => $obj->makeSql,
	        method     => sub { $obj->make_tree_list(@_) },
	        columns    => [$obj->{idx}, $obj->{textcolumn}, $obj->{parent_id}],
	        start_id   => $obj->{start_id},
		recursive  => 0,
        ); 

	$obj->{fieldtypes} = $obj->getFieldTypes
		unless(defined $obj->{fieldtypes});

	$obj->{tree}->configure(-command => $obj->{command})
		if(defined $obj->{command} and ref $obj->{command} eq 'CODE');

	$obj->remember();
	$obj->list({
		item => $item, 
		redraw => $redraw,
	});

	$obj->{tree}->focus;
#	$obj->select_entrys($obj->{FoundEntrys});

	if($obj->{zoom} and scalar @{$obj->{FoundEntrys}}) {
		$obj->{zoom} = 0;
		$obj->zoom();
	}

	$obj->Unbusy;
	
	$obj->{last_refresh_time} = time;
}

# ------------------------------------------
sub select_entrys {
# ------------------------------------------
	my $obj = shift || return error('No Object');
	$obj->{FoundEntrys} = shift || return $obj->{FoundEntrys};
	$obj->color_all();
	$obj->zoom if($obj->infozoom);	

	my @found;
	foreach my $id (@{$obj->{FoundEntrys}} ) {
		 my $entry = $obj->id2path($id);
		 push(@found, $entry)
		 	if(defined $entry);
	}
	$obj->{FoundEntrys} = \@found;

	foreach (@found) { 
		$obj->to_parent_open($_);
		$obj->color_row($_, $obj->{highlight});
	}
	my $entry = $found[0] || return;

	if($obj->info('exists', $entry)) {
		$obj->{tree}->anchorSet($entry);
		$obj->{tree}->selectionSet($entry);
		$obj->{tree}->see($entry);
	}
}

# ------------------------------------------
sub see {
# ------------------------------------------
	my $obj = shift || return error('No Object');
	my $ids = shift || return debug('No Id in see()!');
	my @ret;
	$obj->{tree}->selectionClear();
	undef $obj->{FoundEntrys};
	foreach my $id ( split(/[^0-9A-Za-z]/, $ids) ) {
		next unless($id);
		my $entry = $obj->id2path($id) || next;
		push(@{$obj->{FoundEntrys}}, $id);
		$obj->debug('%s: = %s', $id, $entry);
		$obj->to_parent_open($entry);
		$obj->{tree}->selectionSet($entry);
		push(@ret, $entry);
	}

	my $last = $ret[0] or return error('No Id to see!');
	$obj->{tree}->OpenCmd(1) 
		if($obj->{tree}->getmode(1) eq 'open');
	$obj->{tree}->see($last);
	$obj->{tree}->anchorSet($last);
	$obj->color_row($last, $obj->{highlight});

	$obj->select_entrys( \@ret )
		if(scalar @ret > 1);	
	return @ret;
}


# ------------------------------------------
sub color_row {
# ------------------------------------------
	my $obj = shift || return error('No Object');
	my $id = shift || return error('No Id');
	my $color = shift || $obj->{normal};
	
	$id = $obj->id2path($id)
		unless($id =~ /\:/);
	return unless($obj->info('exists', $id));

	my $i = 0;
	foreach ($obj->{textcolumn}, @{$obj->{fields}}) {
		$obj->{tree}->itemConfigure($id, $i, -style => $color);
		$i++;
	}
}

# ------------------------------------------
sub color_clear {
# ------------------------------------------
	my $obj = shift || return error('No Object');
	my $entrys = shift || $obj->{FoundEntrys} || return;
	my $color = shift || $obj->{normal};

	foreach my $entry (sort @{$entrys}) {
		$obj->color_row($entry, $color);
	}
}


# ------------------------------------------
sub color_all {
# ------------------------------------------
	my $obj = shift || return error('No Object');
	my $color = shift || $obj->{normal};

	foreach my $entry (sort @{$obj->{ListOfAllEntries}}) {
		$obj->color_row($entry, $color);
	}
}

# ------------------------------------------
sub remember {
# ------------------------------------------
	my $obj = shift || return error('No Object');
	my $rem = shift;
	my $ret;
	unless( $rem ) {
		$ret->{status} = $obj->{OPEN};
		$ret->{version} = $Version;
		my $i = 0;
		my $conf;
		foreach my $spalte ($obj->{textcolumn}, @{$obj->{fields}}) {
			push(@{$ret->{widths}}, $obj->{tree}->columnWidth($i++));
		}
	} else {
		return $obj->debug('This configuration (V: %s) isn\'t compatible with this (V: %s). Ignoring.',
			(defined $rem->{version} ? $rem->{version} : 'NoVersion'), 
			$Version) 
			if(! defined $rem->{version} or (defined $rem->{version} and $Version > $rem->{version}));

		$obj->{OPEN} = $obj->{tree}->{status} = $rem->{status}
			if(defined $rem->{status});

		$obj->{widths} = $rem->{widths}
			if(defined $rem->{widths});
	}
	return $ret;
}

# ------------------------------------------
sub make_tree_list {
# ------------------------------------------
	my $obj = shift || return error('No Object');
	my %parms = @_;

	my @parent_ids = @{ $parms{parent_id} };
		
	my $treeval = '';
	foreach (@parent_ids) {
		$treeval .= "$_:";
	}
	$treeval .= $parms{id};
	push(@{$obj->{ListOfAllEntries}}, $treeval);
}

# ------------------------------------------
sub get_id {
# ------------------------------------------
	my $obj = shift || return error('No Object');
	my $w = shift || return error('No Widget!');
	my $ev = $w->XEvent;
	my $id = $w->nearest($ev->y);
	$obj->{tree}->anchorSet($id);
	$obj->{tree}->selectionClear();
	$obj->{tree}->selectionSet($id);
	my ($col, $col_nr) = $obj->x2col( $ev->x + $w->xview() );
	my $wert = $w->itemCget($id, $col_nr, -text);
	return ($id, $col, $col_nr, $wert);
}

# ------------------------------------------
sub x2col {                                                       
# ------------------------------------------
	my $obj = shift || return error('No Object');
	my $x = shift;
	my $c = 0;
	my $von = 0;
	foreach my $name ($obj->{textcolumn}, @{$obj->{fields}}) {
		my $breite = $obj->{tree}->columnWidth( $c);
		my $bis = $von + $breite;
		return (($obj->{colNames}->[$c] || $name), $c) 
			if($x >= $von && $x <= $bis);
		$von += $breite; 
		$c++;
	}
}

# ------------------------------------------
sub infozoom {
# ------------------------------------------
	my $obj = shift || return error('No Object');
	$obj->debug('Zoom is %s', ( $obj->{zoom} ? 'on' : 'off' ));
 	return $obj->{zoom};
}

# ------------------------------------------
sub zoom {
# ------------------------------------------
	my $obj = shift || return error('No Object');
	return unless($obj->{FoundEntrys});
	$obj->Busy;
	$obj->{zoom} = ($obj->{zoom} ? undef : 1);
	if($obj->{zoom}) {
		foreach my $entry (sort @{$obj->{ListOfAllEntries}}) {
			next unless($entry);
			my $search = $entry;
			$search =~ s/\:/\\:/sig;
			unless(grep(/^$search/, @{$obj->{FoundEntrys}})) {
				unless($obj->info('hidden', $entry)) {
					$obj->{tree}->hide('entry', $entry);
					push(@{$obj->{HiddenEntrys}}, $entry);
				}
			}
		}
	} else {
		foreach my $entry (@{$obj->{HiddenEntrys}}) {
			$obj->{tree}->show('entry', $entry)
				if($obj->info('hidden', $entry));
		}
		@{$obj->{HiddenEntrys}} = qw//;
	}
	$obj->Unbusy;
}


# ------------------------------------------
sub makeSql {
# ------------------------------------------
	my $obj = shift || return error('No Object');
	my $sql;

	if($obj->{joiner}) {
		$sql = sprintf('SELECT %s, %s, %s, %s FROM %s LEFT JOIN %s ON %s ORDER BY %s',
				  $obj->{idx}, $obj->{textcolumn},join(',', @{$obj->{fields}}), $obj->{parent_id},
				  $obj->{table}->[0], $obj->{table}->[1],
				  $obj->{joiner},
				  $obj->{textcolumn}
				  );	
	} else {
		$sql = sprintf('select %s, %s, %s, %s from %s %s ORDER BY %s, %s',
				$obj->{idx}, $obj->{textcolumn} ,join(',', @{$obj->{fields}}), $obj->{parent_id},
				$obj->{table}, 
				sprintf('WHERE %s in (%s)', $obj->{parent_id}, join(',', @{$obj->search_unique_ids($obj->{OPEN})} ) ),
				$obj->{parent_id}, $obj->{idx}
				); 
	}
	$obj->debug('makeSql: %s', $sql)
		if($obj->{debug});
	return $sql;
}


# ------------------ 
sub search_unique_ids {
# ------------------ 
	my $obj = shift || return error ('No Object!' );
	my $ids = shift;
	my $ret;

	foreach my $item (keys %$ids) {
		foreach(split(':', $item)) {
			$ret->{$_} = 1;			
		};
	}
	my @r = (0,$obj->{start_id}, keys %$ret);
	return \@r;
}


# ------------------------------------------
sub getFieldTypes {
# ------------------------------------------
	my $obj 	= shift or return warn("No object");
	my $dbh 	= $obj->{dbh};
	my $table	= ref $obj->{table} ? $obj->{table}->[0] : $obj->{table};

	return $obj->{$table}->{fieldtypes}
		if(defined $obj->{$table}->{fieldtypes});
	
	$obj->{$table}->{fieldtypes} = $dbh->selectall_hashref("show fields from $table", 'Field')
		or return $obj->debug($dbh->errstr);

	return $obj->{$table}->{fieldtypes};
}


# ------------------------------------------
sub list {
# ------------------------------------------
	my $obj = shift || return error('No Object');
	my $arg = shift;

	my $item = $arg->{item};
	my $redraw = $arg->{redraw};
	
	return if(defined $item and $obj->info('exists', $item) and $obj->info('children', $item));
	my $idx = ( index($obj->{idx}, '.') ? ( split( '\.', $obj->{idx} ) )[-1] : $obj->{idx});
	my $iname = $1 if($idx =~ /([a-z_]+)/si);
	my $len = $1 if($obj->getFieldTypes->{$iname}->{Type} =~ /(\d+)/);

	if($DBIx::Tree::VERSION < 1) {
		$obj->{dbtree}->do_query;	
		$obj->{dbtree}->tree;
	} else {
		$obj->{dbtree}->traverse;	
	}
	
	my $sql = $obj->makeSql;

        my $DATA = $obj->{dbh}->selectall_hashref( $sql, $idx) 
        		or return error($obj->{dbh}->errstr);

	foreach my $id (sort @{$obj->{ListOfAllEntries}}) { 
		my ($item_id, $pid) = $obj->id($id);
		next if(! $obj->{tree}->infoExists($pid) and $pid);
		next if($obj->{tree}->infoExists($id));

		$obj->{Paths}->{$item_id} = $id;
		my $row = $DATA->{$item_id} || $DATA->{sprintf("%0${len}d", $item_id)} || error('Error: No Data for %s', $item_id);		
		$obj->{tree}->add($id, 
			-itemtype	=> 'imagetext', 
			-data 		=> $row, 
			-text 		=> $obj->parse_text($row->{$obj->{textcolumn}}, $obj->{textcolumn}),
			-style 		=> $obj->{normal},
			 ) if($row);

		&{$obj->{entry_create_cb}}($obj->{tree}, $id, $row)
			if(defined $obj->{entry_create_cb} and ref $obj->{entry_create_cb} eq 'CODE');

		my $c = 1;
		foreach my $field (@{$obj->{fields}}) {
			$obj->{tree}->itemCreate( $id, $c++, 
				-text => $obj->parse_text($row->{$field}, $field),
				-style => $obj->{normal},
			);
		}
	}

	# Draw Indicators
	$obj->{tree}->autosetmode;


	# Check is exists Ptree or Table is change, then reload
	$sql = sprintf('select %s, %s from %s GROUP BY %s', 
				$obj->{idx}, $obj->{parent_id}, 
				(ref $obj->{table} ? join(',', @{$obj->{table}}) : $obj->{table}), 
				$obj->{parent_id}
	); 

	$obj->debug($sql);
	$obj->{ptree} = $obj->{dbh}->selectall_hashref($sql, $obj->{parent_id})
				if($redraw);

	# Set the modes from every tree
	foreach my $entry (@{$obj->{ListOfAllEntries}}) {
		my ($id, $pid) = $obj->id($entry);

		if( defined $obj->{ptree}->{$id} and $obj->{tree}->getmode($entry) eq 'none') {
			$obj->{tree}->setmode($entry, 'open');
		} 
		if( defined $obj->{ptree}->{$id} and $obj->{tree}->getmode($entry) eq 'close') {
			$obj->{tree}->setmode($entry, 'close');
		} 
		if(! defined $obj->{ptree}->{$id}) {
			$obj->{tree}->setmode($entry, 'none');
		}			
	}

}

# ------------------------------------------
sub close_all {
# ------------------------------------------
	my $obj = shift || return error('No Object');
	return unless(ref $obj->{ListOfAllEntries} eq 'ARRAY');
	foreach my $entry (sort @{$obj->{ListOfAllEntries}}) {
		$obj->{tree}->close($entry);
	}
}

# ------------------------------------------
sub to_parent_open{
# ------------------------------------------
	my $obj = shift || return error('No Object');
	my $entry = shift || return error('No Entry!');
	$entry = $obj->id2path($entry) || return error('This Entry <%s> is not exist!', $entry);

	my ($id, $pid) = $obj->id($entry);
	my $path = $obj->{start_id};
	foreach my $e (split(/\:/, $entry)) {
		next if($e eq $obj->{start_id});
		next if($e eq $id);
		$path .= sprintf(':%d', $e);		
		$obj->{tree}->open($path)
			if($obj->info('exists', $path));
	}
}

# ------------------------------------------
sub parse_text {
# ------------------------------------------
	my $obj = shift;
	my $text = shift || return ' ';
	my $field = shift || return error('No FieldName!');
	my $maxchars = 
		(ref $obj->{maxchars} eq 'HASH' 
			? $obj->{maxchars}->{$field} 
			: $obj->{maxchars} 
		) || 0;
	$text = substr($text, 0, $maxchars).'...' 
		if($maxchars and length($text)>$maxchars);
	$text =~ s/(\r|\n)//sig;
	return $text;
} 

# ------------------------------------------
sub parent_id {
# ------------------------------------------
	my $obj = shift || return error('No Object');
	my $path = shift || return error('No Path');
	my $parent = $obj->info('parent', $path)
		or return error('Parent not found!');
	return (split( /:/, $parent ))[-1];
}


# ------------------------------------------
sub id {
# ------------------------------------------
	my $obj = shift || return error('No Object');
	my $path = shift || return error('No Path');
	
	
	return $path if(index($path, ':') == -1);
	my @elms = split(':', $path);
	my $id = pop @elms;
	my $pid = join(':', @elms);
	return ($id, $pid);
}

# ------------------ 
sub childs {
# ------------------ 
	my $obj = shift || return error ('No Object!' );
	my ($i, $p) = $obj->id(shift);
	my $id = int($i) || return error ('No Id!' );
	$obj->debug('childs -  Id: %s', $id);
	my @ret;

	# Caching	
	return @{$obj->{children}->{$id}}
		if(defined $obj->{children}->{$id});
	
	if(defined $obj->{ptree}->{$id}) {
		my $sql = sprintf('select %s from %s where %s = %d', 
			$obj->{idx}, $obj->{table}, $obj->{parent_id}, $id);
		my $chields = $obj->getSqlArray($sql);			
		foreach my $child (@{$chields}) {
			push(@ret, $child->[0]);				
			my @ch = $obj->childs($child->[0])
				if(defined $obj->{ptree}->{$child->[0]});			
			push(@ret, @ch);				
		}
	}
	# Caching
	$obj->{children}->{$id} = \@ret;
	return @ret;
}



# ------------------------------------------
sub id2path {
# ------------------------------------------
	my $obj = shift || return error('No Object');
	my $id = shift || return debug('No ID');

	return $id
		if($id =~ /\:/);

	return $obj->{Paths}->{$id}
		if(defined $obj->{Paths}->{$id} and $obj->{Paths}->{$id} =~ /\:/ and $obj->{Paths}->{$id} ne $obj->{start_id});

	$id = int($id);

	my @tree;	
	my $parent_id = $obj->sqlv("select %s from %s where %s = '%s'", 
		$obj->{parent_id}, 
		(ref $obj->{table} ? join(',', @{$obj->{table}}) : $obj->{table}), 
		$obj->{idx}, $id);	
	return error('No found!')
		unless(defined $parent_id);
			
	unshift(@tree, $parent_id, $id);


	my $maxdeep;
	while($parent_id) {
		last if($maxdeep++ >= 10);
		my $vater_parent_id = $obj->sqlv('select %s from %s where %s = "%s"', 
		$obj->{parent_id}, $obj->{table}, $obj->{idx}, $parent_id) || last;
		unshift(@tree, $vater_parent_id);
		$parent_id = $vater_parent_id;
	}

	# Cache this Information
	$obj->{Paths}->{$id} = join(':', @tree);
	return $obj->{Paths}->{$id};	
	
}

# ------------------------------------------
sub listEntrys {
# ------------------------------------------
	my $obj = shift;
	return $obj->{ListOfAllEntries};
} 

# ------------------------------------------
sub info {
# ------------------------------------------
	my $obj = shift or return error("No object");
	my $typ = shift or return error("No Type");
	my $entry = shift;

#	$obj->debug('info: %s - %s', $typ, $entry);

	if($typ =~ /^(selection|anchor|dragsite|dropsite)$/si) {
		my @ids = $obj->{tree}->info($typ);
		return \@ids;
	}

	if($entry and $entry !~ /\:/) {
		$entry = $obj->id2path($entry)
			or return error('Can\'t find <%s> in Paths!', $entry);
	}

	return error('Can\'t find Id: %s', $entry)
		if($typ ne 'exists' and ! $obj->{tree}->info('exists', $entry));
	my $answ = $obj->{tree}->info($typ, $entry);
#	$obj->debug('info: Answer = <%s>', $answ);
	return $answ;
} 


# ------------------------------------------
sub getSqlArray {
# ------------------------------------------
	my $obj = shift or return error("No object");
	my $sql = shift or return error('No Sql');
	my $dbh = $obj->{dbh};

	$obj->debug($sql);
	my $sth = $dbh->prepare($sql) or return error("$DBI::errstr - $sql");
	$sth->execute or return error("$DBI::errstr - $sql");
	return $sth->fetchall_arrayref;
}

# ------------------------------------------
sub Table_is_Change {
# ------------------------------------------
	my $obj 	= shift or return error("No object");
	my $lasttime	= shift || $obj->{last_refresh_time};	# No last time, first request!
	my $table	= shift || $obj->{table} || $obj->{table}->[0];

	my $dbh 	= $obj->{dbh};
	my $ret = 0;

	my $data = $dbh->selectall_hashref(sprintf("SHOW TABLE STATUS LIKE '%s'", $table),'Name')
		or return $obj->debug($dbh->errstr);

	my $unixtime = $obj->sqlv("select UNIX_TIMESTAMP('%s')", $data->{$table}->{Update_time})
		if(defined $data->{$table}->{Update_time});

	$obj->{last_refresh_time} = time;

	if(defined $unixtime and $unixtime > $lasttime) {
		return 1;
	}
}

# ------------------------------------------
sub rm_from_array {
# ------------------------------------------
	my $obj = shift || return error('No Object');
	my $arr = shift || return error('No Array');
	my $id  = shift || return error('No Id');
	$obj->debug('rm_from_array - Arr: %s, Id: %s', $arr, $id);	
	my @new_array = grep(!/$id/, @$arr);
	
	return \@new_array;
}

# ------------------ 
sub sqlv {
# ------------------ 
	my $obj = shift || return error ('No Object!' );
	my $sql = sprintf(shift, @_) || return error ('No Sql' );

	$obj->debug($sql);
	return $obj->getSqlArray($sql)->[0][0]; 
}



# ------------------------------------------
sub debug {
# ------------------------------------------
	my $obj = shift;
	return unless($obj->{debug});
        my ($package, $filename, $line, $subroutine, $hasargs,
                $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller(1);
	print color 'green';
	printf '#%d: ', $line;
	printf @_ if(scalar @_);
	print "\n";
	print color 'reset';
} 

# ------------------------------------------
sub error {
# ------------------------------------------
	my $msg = shift;
        my ($package, $filename, $line, $subroutine, $hasargs,
                $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller(1);
	my $error = sprintf("ERROR in %s %s #%d: <%s>\n",
                (defined $package ? $package : 'nopackage'), 
                (defined $subroutine ? $subroutine : 'nosub'), 
                (defined $line ? $line : 'noline'), 
                (defined $msg ? sprintf($msg, @_) : 'no message')
                );
	print color 'bold red';
	print $error;
	print color 'reset';
	return undef;
} 


1;


=head1 NAME

Tk::DBIx::Tree - Megawidget to display a table column in a tree.

=head1 SYNOPSIS

  use Tk;
  use Tk::DBIx::Tree;

  my $top = MainWindow->new;
  my $tkdbi = $top->DBITree(
		-dbh   		=> $dbh,
		-table		=> 'Inventory',
		-textcolumn	=> 'name',
		-idx		=> 'id',
		-columnWidths	=> [undef, undef, undef, 150],
		-fields		=> [qw(changed_by changed_at descr)],
		-parent_id	=> 'parent_id',
		-start_id	=> 1,
		-maxchars	=> { descr => 25 },
		)->pack(-expand => 1, 
		  	-fill => 'both');

  MainLoop;

=head1 DESCRIPTION

This is a megawidget to display a sql statement from your database in a tree view
widget. When you've got one of those nasty self-referential tables that you
want to bust out into a tree, this is the module to check out.

=head1 WIDGET-SPECIFIC OPTIONS

=head2 -dbh => $ref_on_database_handle

A database handle, this will return an error if it is'nt defined.

=head2 -debug => [I<0>|1]

This is a switch to turn on debug output to the standard console (STDOUT)

=head2 -table => 'tablename'

The table to display.

=head2 -idx => 'index_column'

The index column from the table.

=head2 -fields => [col0, col1, col2, ...]

List of additional fields to display. 

=head2 -colNames => [col0, col1, col2, ...]

List of alternative names for every column. This will display on header.

=head2 -where => 'WHERE foo == 1, ...'

Additional where statement for choice rows in table.

=head2 -textcolumn => colname

The name of the column to be displayed in the tree..

=head2 -start_id => integer

The id, where the widget will start to create the tree. Default is 1.

=head2 -columnWidths => [colWidth_0, colWidth_1, colWidth_2, ...]

Default field column width.

=head2 -highlight => I<[-foreground => 'blue']>

Style for founded Entries.

=head2 -normal => I<[-foreground => 'black']>

Default style for Entries.

=head2 -maxchars => number or {col1 =number}

Maximum number of characters to be displayed within the cells. Global
validity or set only for named columns.
I.E.:

  -maxchars => {
	 descr => 25,
	 name => 10,
  },
  # or ....
  -maxchars => 25, # global for all fields


=head2 -time_column => $name_from_time_column

Maximum number of characters to be displayed within the cells. Global
validity or set only for named columns.
I.E.:

  -maxchars => {
	 descr => 25,
	 name => 10,
  },
  # or ....
  -maxchars => 25, # global for all fields

=head1 METHODS

These are the methods you can use with this Widget.

=head2 $DBITree->refresh('reload');

Refresh the tree. if you call this method with the parameter reload 
then this will reload the table from database. If you call this without parameter, then 
look this widget is the table changed (update date) at the last refresh. If this true, then
load this the complete table and redraw the tree.

=head2 $DBITree->refresh_id( I<entry>, I<data> );

This will refresh (delete -> new) a Tree item.

=head2 $DBITree->copy( I<entry>, I<to_parent_entry>, I<data> );

Copy an entry (entry) to a parent branch (to_parent_entry) with data (data);

=head2 $DBITree->move( I<entry>, I<to_parent_entry>, I<data> );

Move an entry (from_entry) to a parent branch (to_parent_entry) with data (data);

=head2 $DBITree->dele( I<entry> );

Delete a entry.

=head2 $DBITree->neu( I<entry>, I<to_parent_entry>, I<data> );

Create a entry.

=head2 $DBITree->close_all;

close all tree branches.

=head2 $DBITree->info('anchor, bbox, children, B<data>, dragsite, dropsite ...', $id);

This is a wrapper to the HList Method ->info. The default method is info('data', ...).
Please read the manual from Tk::HList.

=head2 $DBITree->id2path(I<id>);

This returns the path for given id.

=head2 $DBITree->ListEntrys;

This returnd a sorted ref array with all entrys in the tree.

=head2 $DBITree->select_entrys([en1, en2, en3, ...]);

This returns a sorted ref array with all selected entries
in the tree or you can set an array of selected entries.
Also you can use only the id's, i.e.:

  $dbitree->select_entrys([qw/1:2 1:3 1:4/]);
  
  # or ... 
  
  $dbitree->select_entrys([qw/2 3 4/]);

These is friendly if you use i.e. a statement 'select id from table where foo == bla'
and you have only the id's without the pathinformation. Tk::DBIx::Tree know, select only
the entries have at last position this id in path.

=head2 $DBITree->zoom;

Shrink or unshrink tree to display only founded entries.

=head2 $DBITree->infozoom;

Returnd true if zoom active.

=head2 $DBITree->color_all([style]);

Set all entries to normal style without parameters. 
You can put a new Style to all entries.

i.e:

  $DBITree->color_clear([qw/1 2 3/], [-background => 'gray50']);

=head2 $DBITree->color_clear([entrys], style);

Remove all higlighted styles from the functions see and select_entrys.
if you don't give entrys, tree take the internal foundentrys.
if you don't give style, tree take the normal style.

i.e:

  $DBITree->color_clear([-background => 'gray50']);


=head2 $DBITree->get_id;

select the row under mouseposition and returnd following parameters.

=over 4

=item path - The path from the entry under mouseposition.

=item col - Column name under mouseposition.

=item path - Column number under mouseposition.

=item value - Cell value under mouseposition.

=back

=head2 $DBITree->childs($item);

Return an array with paths from childs for $item, include $item.

=head2 $DBITree->parent_id($path);

Return the actually id from the parentree (only the integer id, not the hole path)

=head2 $DBITree->see($id);

Jump to id (only database id)

=head2 $DBITree->remember( $hash );

This method is very useful, when you want to remember the last tree status
and column widths for the resize button. This returns a ref hash with following
keys, if this call is done without parameters.

=over 4

=item widths - a ref array including the width of each column.

=item stats - a ref hash with status information(open close none) for each entry.

=back

You can give an old Hash (may eval-load at program start) and the tree
remembers this status.

I.E.:

  $tree->rembember( $tree->rembember );

  # or ...

  $tree->remember( {
	 status => {
		  '0:1' ='open',
		  '0:1:2' ='close',
		  ...
	 },
 	 widths =[165, 24, 546],
  } );

=head1 CALLBACKS

=head2 -command => sub{ ... }

Callback on TreeWidget at browsing.

=head2 -entry_create_cb => sub{ ... }

Callback if an entry created. The routine have 2 parameters:

=over 4

=item entry - a ref to created entry

=item data - a ref hash with row information.

=back

i.e;

  -entry_create_cb => sub{
	my($w, $path, $row) = @_;
	if(exists $DOC->{ $row->{id} } and exists $EVENT->{ $row->{id} } ) {
		$w->entryconfigure($path, -image => $pics{'icon_document_event'});
	}
  },

=head2 -opencmd => sub{ ... }

Callback on TreeWidget if this entry activate(from User or Automatic) to open. 
if this return false, then Tree doesn't refresh the tree.
i.E.
	-opencmd	=> sub{ &display_prj_items( @_ ) },


=head2 -closecmd => sub{ ... }

Callback on TreeWidget if this entry activate(from User or Automatic) to close.


=head1 ADVERTISED WIDGETS

=head2 'tree' => Tree-Widget

This is a normal Tree widget. I.e.:

 $DBITree->Subwidget('tree')->configure(
	-background => 'gray50',
 };

=head2 'HB_<column name>' => ResizeButton-Widget

This is a (Resize)Button widget.

=head1 CHANGES

  $Log: Tree.pm,v $
  Revision 1.2  2003/11/06 17:55:56  xpix
  ! bugfixes in refresh_id
  * not hudge load for tree

  Revision 1.1  2003/10/24 10:46:28  xpix
  * new Name for CPAN
  * new Parser for tree, at ths time is possible only read a one Tree

  !! new cvs name !!

  Revision 1.11  2003/08/13 12:58:13  xpix
  * colored debug output
  * new method childs, output an array with complete paths from childs
  * new methods neu, move, dele to transfering from entrys
  * new option maxchars
  ! many, many bug fixes

  Revision 1.8  2003/07/18 16:14:15  xpix
  ! Fehler im Table_is_Change algo, fix
  ! Komplett refresh bei TreeStatusaenderung
  ! to_parent_open macht jetzt wirklich nur die Vaeter und nicht noch den Sohn auf ;-)
  ! unit. value in Form.pm

  Revision 1.10  2003/07/17 14:59:54  xpix
  ! many little bugfixes

  Revision 1.3  2003/06/24 16:38:44  xpix
  * add symbolic to cvs
  * new loking mechanism in Form.pm

  Revision 1.9  2003/06/23 16:15:22  xpix
  ! cvs error

  Revision 1.8  2003/06/18 15:31:47  xpix
  * new methods: copy, move, neu ... dele. This will work only on the Tree Widget (not in table)
  * change a little bit the docu

  Revision 1.7  2003/06/16 12:58:01  xpix
  ! No Error, if the id ot exists in selct_entrys

  Revision 1.6  2003/05/23 13:47:46  xpix
  ! No debug if debug = 0

  Revision 1.5  2003/05/20 13:51:50  xpix
  * add field parent_id to data entry

  Revision 1.4  2003/05/11 16:33:47  xpix
  * new option -colNames
  * new option -entry_create_cb
  * new option -higlight
  * new option -normal
  * new method info
  * new method infozoom
  * new method color_all
  * new method get_id
  ! much bugfixes
  * better select_entrys (without pathinformation)

  Revision 1.3  2003/05/05 16:02:06  xpix
  * correct the documentation and write a little more ;-)

  Revision 1.2  2003/05/04 23:38:25  xpix
  ! bug in make_tree_list

  Revision 1.1  2003/05/04 20:52:13  xpix
  * New Widget for display a table in a tree

=head1 AUTHOR

Copyright (C) 2003 , Frank (xpix) Herrmann. All rights reserved.

http://www.xpix.de

This program is free software; you can redistribute it and/or