#*** Mirror.pm ***#
# Copyright (C) 2006 - 2008 by Torsten Knorr
# create-soft@tiscali.de
# All rights reserved!
#-------------------------------------------------
 package Tk::Mirror;
#-------------------------------------------------
 use strict;
 use Tk::Frame;
 use Net::UploadMirror 0.13;
 use Net::DownloadMirror 0.10;
 use Storable;
#-------------------------------------------------
 @Tk::Mirror::ISA = qw(Tk::Frame);
 $Tk::Mirror::VERSION = '0.06';
#-------------------------------------------------
 Construct Tk::Widget 'Mirror';
#-------------------------------------------------
 sub Populate
 	{
 	require Tk::Label;
 	require Tk::Entry;
 	require Tk::BrowseEntry;
 	require Tk::Tree;
 	require Tk::Button;
 	require Tk::Dialog;
 	my ($m, $args) = @_;
#-------------------------------------------------
 	if(-f 'para')
 		{
 		$m->{para} = retrieve('para');
 		}
 	else
 		{
 		$m->{para} = {};
 		}
 	for(qw/ 	-localdir
 		-remotedir
 		-ftpserver
 		-user
 		-pass
 		-debug
 		-timeout
 		-delete
 		-connection
 		-exclusions	
 		-subset
 		-filename
 		/)
 		{
 		$m->{para}{substr($_, 1)} = delete($args->{$_}) if(defined($args->{$_}));
 		}
 	$m->{upload}	= Net::UploadMirror->new(%{$m->{para}});
 	$m->{download}	= Net::DownloadMirror->new(%{$m->{para}});
 	$m->{overwrite}	= defined($args->{-overwrite}) ? delete($args->{-overwrite}) : 'none';
 	$m->SUPER::Populate($args);
#-------------------------------------------------
 	my $label_user	= $m->Label(
 		-text		=> 'Username ->',
 		)->grid(
 		-row		=> 0,
 		-column		=> 0,
 		-columnspan	=> 3,
 		-sticky		=> 'nswe',
 		);
#-------------------------------------------------
 	$m->{bentry_user}	= $m->BrowseEntry(
 		-variable		=> \$m->{para}{user},
 		-browsecmd	=> [\&UpdateAccess, $m, 'user'],
 		)->grid(
 		-row		=> 0,
 		-column		=> 3,
 		-columnspan	=> 3,
 		-sticky		=> 'nswe',
 		);
#-------------------------------------------------
	my $label_ftpserver = $m->Label(
 		-text		=> 'FTP-Server ->',
 		)->grid(
 		-row		=> 1,
 		-column		=> 0,
 		-columnspan	=> 3,
 		-sticky		=> 'nswe',
 		);
#-------------------------------------------------
 	$m->{bentry_ftpserver} = $m->BrowseEntry(
 		-variable		=> \$m->{para}{ftpserver},
 		-browsecmd	=> [\&UpdateAccess, $m, 'ftpserver'],
 		)->grid(
 		-row		=> 1,
 		-column		=> 3,
 		-columnspan	=> 3,
 		-sticky		=> 'nsew',
 		);
#-------------------------------------------------
 	my $label_pass	= $m->Label(
 		-text		=> 'Password ->',
 		)->grid(
 		-row		=> 2,
 		-column		=> 0,
 		-columnspan	=> 3,
 		-sticky		=> 'nsew',
 		);
#-------------------------------------------------
 	$m->{entry_pass} = $m->Entry(
 		-textvariable	=> \$m->{para}{pass},
 		-show		=> '*',
 		)->grid(
 		-row		=> 2,
 		-column		=> 3,
 		-columnspan	=> 3,
 		-sticky		=> 'nsew',
 		);
#-------------------------------------------------
 	my $label_local_dir = $m->Label(
 		-text		=> 'Localdirectory',
 		)->grid(
 		-row		=> 3,
 		-column		=> 0,
 		-columnspan	=> 3,
 		-sticky		=> 'nswe',
 		);
#-------------------------------------------------
 	my $label_remote_dir = $m->Label(
 		-text		=> 'Remotedirectory',
 		)->grid(
 		-row		=> 3,
 		-column		=> 3,
 		-columnspan	=> 3,
 		-sticky		=> 'nswe',
 		);
#-------------------------------------------------
 	$m->{bentry_local_dir} = $m->BrowseEntry(
 		-variable		=> \$m->{para}{localdir},
 		-browsecmd	=> [\&UpdateAccess, $m, 'localdir'],
 		)->grid(
 		-row		=> 4,
 		-column		=> 0,
 		-columnspan	=> 3,
 		-sticky		=> 'nswe',
 		);
#-------------------------------------------------
 	$m->{bentry_remote_dir} = $m->BrowseEntry(
 		-variable		=> \$m->{para}{remotedir},
 		-browsecmd	=> [\&UpdateAccess, $m, 'remotedir'],
 		)->grid(
 		-row		=> 4,
 		-column		=> 3,
 		-columnspan	=> 3,
 		-sticky		=> 'nswe',
 		);
#-------------------------------------------------
 	$m->{tree_local_dir} = $m->Scrolled(
 		"Tree",
 		-separator	=> '/',
 		-itemtype	=> 'text',
 		-selectmode	=> 'single',
 		)->grid(
 		-row		=> 5,
 		-column		=> 0,
 		-columnspan	=> 3,
 		-sticky		=> 'nswe',
 		);
#-------------------------------------------------
 	$m->{tree_remote_dir} = $m->Scrolled(
 		"Tree",
 		-separator	=> '/',
 		-itemtype	=> 'text',
 		-selectmode	=> 'single'
 		)->grid(
 		-row		=> 5,
 		-column		=> 3,
 		-columnspan	=> 3,
 		-sticky		=> 'nswe'
 		);
#-------------------------------------------------
 	$m->{label_overwrite} = $m->Label(
 		-text		=> 'overwrite'
 		)->grid(
 		-row		=> 6,
 		-column		=> 0,
 		-columnspan	=> 2,
 		-sticky		=> 'nswe'
 		);
 #------------------------------------------------
 	$m->{rbutton_none} = $m->Radiobutton(
 		-text		=> 'none',
 		-variable		=> \$m->{overwrite},
 		-value		=> 'none'
 		)->grid(
 		-row		=> 6,
 		-column		=> 2,
 		-sticky		=> 'nswe'
 		);
#-------------------------------------------------
 	$m->{rbutton_all} = $m->Radiobutton(
 		-text		=> 'all',
 		-variable		=> \$m->{overwrite},
 		-value		=> 'all',
 		)->grid(
 		-row		=> 6,
 		-column		=> 3,
 		-sticky		=> 'nwes'
 		);
#-------------------------------------------------
 	$m->{rbutton_older} = $m->Radiobutton(
 		-text		=> 'older',
 		-variable		=> \$m->{overwrite},
 		-value		=> 'older'
 		)->grid(
 		-row		=> 6,
 		-column		=> 4,
 		-sticky		=> 'nswe'
 		);
#-------------------------------------------------
 	$m->{button_upload} 	= $m->Button(
 		-text		=> 'Upload ->',
 		-command	=> [\&Upload, $m],
 		-state		=> 'disabled'
 		)->grid(
 		-row		=> 7,
 		-column		=> 0,
 		-columnspan	=> 2,
 		-sticky		=> 'nswe',
 		);
#-------------------------------------------------
 	$m->{button_compare} = $m->Button(
 		-text		=> 'Compare',
 		-command	=> [\&CompareDirectories, $m],
 		)->grid(
 		-row		=> 7,
 		-column		=> 2,
 		-columnspan	=> 2,
 		-sticky		=> 'nsew',
 		);
#-------------------------------------------------
 	$m->{button_download} = $m->Button(
 		-text		=> '<- Download',
 		-command	=> [\&Download, $m],
 		-state		=> 'disabled',
 		)->grid(
 		-row		=> 7,
 		-column		=> 4,
 		-columnspan	=> 2,
 		-sticky		=> 'nswe',
 		);
#-------------------------------------------------
 	$m->{childs} = {
 		'LabelUser'		=> $label_user,
 		'bEntryUser'		=> $m->{bentry_user},
 		'LabelFtpServer'		=> $label_ftpserver,
 		'bEntryFtpServer'		=> $m->{bentry_ftpserver},
 		'LabelPass'		=> $label_pass,
 		'EntryPass'		=> $m->{entry_pass},
 		'LabelLocalDir'		=> $label_local_dir,
 		'LabelRemoteDir'		=> $label_remote_dir,
 		'bEntryLocalDir'		=> $m->{bentry_local_dir},
 		'bEntryRemoteDir'		=> $m->{bentry_remote_dir},
 		'TreeLocalDir'		=> $m->{tree_local_dir},
 		'TreeRemoteDir'		=> $m->{tree_remote_dir},
 		'LabelOverwrite'		=> $m->{label_overwrite},
 		'rButtonNone'		=> $m->{rbutton_none},
 		'rButtonAll'		=> $m->{rbutton_all},
		'rButtonOlder'		=> $m->{rbutton_older},
 		'ButtonUpload'		=> $m->{button_upload},
 		'ButtonCompare'		=> $m->{button_compare},
 		'ButtonDownload'		=> $m->{button_download},
 		};
 	$m->Advertise($_ => $m->{childs}{$_}) for(keys(%{$m->{childs}})); 
 	$m->Delegates(
 		DEFAULT	=> $m->{tree_local_dir},
 		);	
 	$m->InsertStoredValues();
 	}
#-------------------------------------------------
 sub DESTROY
 	{
 	my ($self) = @_;
 	print($self || ref($self) . "object destroyed\n") if($self->{_debug});
 	}
#-------------------------------------------------
 sub GetChilds
 	{
 	return $_[0]->{childs};
 	}
#-------------------------------------------------
 sub SetParams
  	{
  	my ($self) = @_;
  	unless(-d $self->{para}{localdir})
 		{
 		$self->Dialog(
 			-text	=> "Localdirectory $self->{para}{localdir} not found",
 			-title	=> 'INPUT-ERROR'
 			)->Show();
 		return;
 		}
 	for(qw/user ftpserver pass remotedir/)
 		{
 		unless($self->{para}{$_})
 			{
 			$self->Dialog(
 				-text	=> "parameter: $_  undefined",
 				-title	=> 'INPUT-ERROR'
 				)->Show();
 			return;
 			}
 		}
 	$self->{upload}->SetUser($self->{para}{user});
  	$self->{upload}->SetFtpServer($self->{para}{ftpserver});
  	$self->{upload}->SetPass($self->{para}{pass});
  	$self->{upload}->SetLocalDir($self->{para}{localdir});
  	$self->{upload}->SetRemoteDir($self->{para}{remotedir});
  	$self->{download}->SetUser($self->{para}{user});
 	$self->{download}->SetFtpServer($self->{para}{ftpserver});
 	$self->{download}->SetPass($self->{para}{pass});
 	$self->{download}->SetLocalDir($self->{para}{localdir});
 	$self->{download}->SetRemoteDir($self->{para}{remotedir});	
 	return 1;
 	}
#-------------------------------------------------
 sub CompareDirectories
 	{
 	my ($self) = @_;
 	return unless($self->SetParams());
 	return unless($self->{upload}->Connect());
 	my $debug = $self->{upload}->GetDebug();
 	$self->StoreParams();
 	($self->{rh_lf}, $self->{rh_ld}) = $self->{upload}->ReadLocalDir();
 	if($debug)
 		{
 		print("local files : $_\n") for(sort keys %{$self->{rh_lf}});
 		print("local dirs : $_\n") for(sort keys %{$self->{rh_ld}});
 		}
 	($self->{rh_rf}, $self->{rh_rd}) = $self->{upload}->ReadRemoteDir();
 	if($debug)
 		{
 		print("remote files : $_\n") for(sort keys %{$self->{rh_rf}});
 		print("remote dirs : $_\n") for(sort keys %{$self->{rh_rd}});
 		};
 	$self->{ra_rfnil} = $self->{upload}->RemoteNotInLocal($self->{rh_lf}, $self->{rh_rf});
 	if($debug)
 		{
 		print("remote files not in local: $_\n") for(@{$self->{ra_rfnil}});
 		}
 	$self->{ra_rdnil} = $self->{upload}->RemoteNotInLocal($self->{rh_ld}, $self->{rh_rd});
 	if($debug)
 		{
 		print("remote dirs not in local: $_\n") for(@{$self->{ra_rdnil}});
 		}
 	$self->{ra_lfnir} = $self->{upload}->LocalNotInRemote($self->{rh_lf}, $self->{rh_rf});
 	if($debug)
 		{
 		print("local files not in remote : $_\n") for(@{$self->{ra_lfnir}});
 		}
 	$self->{ra_ldnir} = $self->{upload}->LocalNotInRemote($self->{rh_ld}, $self->{rh_rd});
 	if($debug)
 		{
 		print("new local dirs : $_\n") for(@{$self->{ra_ldnir}});
 		}
 	my $rh_temp_up = {};
 	%{$rh_temp_up} = %{$self->{rh_lf}};
 	delete(@{$rh_temp_up}{@{$self->{ra_lfnir}}});
 	$self->{ra_mlf} = $self->{upload}->CheckIfModified($rh_temp_up);
 	if($debug)
 		{
 		print("modified local files : $_\n") for(@{$self->{ra_mlf}});
 		}
 	my $rh_temp_down = {};
 	%{$rh_temp_down} = %{$self->{rh_rf}};
 	delete(@{$rh_temp_down}{@{$self->{ra_rfnil}}});
 	$self->{ra_mrf} = $self->{download}->CheckIfModified($rh_temp_down);
 	if($debug)
 		{
 		print("modified remote files : $_\n") for(@{$self->{ra_mrf}});
 		}
 	$self->{upload}->Quit();
 	$self->{button_upload}->configure(-state => 'normal');
 	$self->{button_download}->configure(-state => 'normal');
 	$self->InsertLocalTree();
 	$self->InsertRemoteTree();
 	return 1;
 	}
#-------------------------------------------------
 sub InsertLocalTree
 	{
 	my ($self) = @_;
 	$self->{tree_local_dir}->delete('all');
 	$self->InsertPaths(
 		$self->{tree_local_dir},
 		[keys(%{$self->{rh_ld}}), keys(%{$self->{rh_lf}})]
 		);
 	$self->InsertLocalModifiedTimes([keys(%{$self->{rh_lf}})]);
 	$self->InsertProperties(
 		$self->{tree_local_dir},
 		$self->{ra_ldnir}, 
 		'<not in remote>'
 		);
 	$self->InsertProperties(
 		$self->{tree_local_dir},
 		$self->{ra_lfnir},
 		'<not in remote>'
 		);
 	$self->InsertProperties(
 		$self->{tree_local_dir},
 		$self->{ra_mlf},
 		'<modified>'
 		);
 	return 1;
  	}
#-------------------------------------------------
 sub InsertRemoteTree
 	{
 	my ($self) = @_;
 	$self->{tree_remote_dir}->delete('all');
 	$self->InsertPaths(
 		$self->{tree_remote_dir},
 		[keys(%{$self->{rh_rd}}), keys(%{$self->{rh_rf}})]
 		);
 	$self->InsertRemoteModifiedTimes([keys(%{$self->{rh_rf}})]);
 	$self->InsertProperties(
 		$self->{tree_remote_dir},
 		$self->{ra_rdnil},
 		'<not in local>'
 		);
 	$self->InsertProperties(
 		$self->{tree_remote_dir},
 		$self->{ra_rfnil},
 		'<not in local>'
 		);
 	$self->InsertProperties(
 		$self->{tree_remote_dir},
 		$self->{ra_mrf},
 		'<modified>'
 		);
 	return 1;
 	}
#-------------------------------------------------
 sub InsertPaths
 	{
 	my ($self, $tree, $ra_paths) = @_;
 	my ($full_path, $temp_path);
 	for(@$ra_paths)
 		{
 		$full_path = $_;
		$full_path =~ s!^/+!!;
 		$temp_path = '';
 		for(split('/', $full_path)) 
 			{
 			$temp_path .= $_;
 			unless($tree->infoExists($temp_path))
 				{
				$tree->add($temp_path, -text => $_,);
 				$tree->setmode($temp_path, 'close');
 				$tree->close($temp_path);
 				}
 			$temp_path .= '/';
 			}
 		}
 	return 1;
 	}
#-------------------------------------------------
 sub InsertProperties
 	{
 	my ($self, $tree, $ra_paths, $pro) = @_;
 	my $path;
	for(@$ra_paths)
 		{
 		$path = $_;
 		$path =~ s!^/+!!;
 		$tree->addchild($path, -text => $pro);
 		}
 	return 1;
 	}
#-------------------------------------------------
 sub DeleteProperties
 	{
 	my ($self, $tree, $ra_paths) = @_;
 	my $path;
 	for(@$ra_paths)
 		{
 		$path = $_;
 		$path =~ s!^/+!!;
 		$tree->deleteSiblings($path);
 		}
 	return 1;
 	}
#-------------------------------------------------
 sub InsertLocalModifiedTimes
 	{
 	my ($self, $ra_lf) = @_;
	my $rh_last_mt = $self->{upload}->GetLast_Modified();
 	my $path;
 	for(@$ra_lf)
 		{
 		$path = $_;
		$path =~ s!^/+!!;
 		if(-e $_)
 			{
 			$self->{tree_local_dir}->addchild(
 				$path,
 				-text	=> localtime((stat($_))[9]) . ' current'
 				);
 			}
 		if(defined($rh_last_mt->{$_}) && $rh_last_mt->{$_} =~ m/^\d+$/)
 			{
 			$self->{tree_local_dir}->addchild(
 				$path,
 				-text	=> localtime($rh_last_mt->{$_}) . ' last'
 				);
 			}
 		}
 	return 1;
 	}
#-------------------------------------------------
 sub InsertRemoteModifiedTimes
 	{
 	my ($self, $ra_rf) = @_;
 	my $rh_last_mrt		= $self->{download}->GetLast_Modified();
 	my $rh_current_mrt	= $self->{download}->GetCurrent_Modified();
 	my $path;
 	for(@$ra_rf)
 		{
 		$path = $_;
		$path =~ s!^/+!!;
		if(defined($rh_current_mrt->{$_}) && $rh_current_mrt->{$_} =~ m/^\d+$/)
 			{
 			$self->{tree_remote_dir}->addchild(
 				$path,
 				-text	=> localtime($rh_current_mrt->{$_}) . ' current'
 				);
 			}
 		if(defined($rh_last_mrt->{$_}) && $rh_last_mrt->{$_} =~ m/^\d+$/)
 			{
 			$self->{tree_remote_dir}->addchild(
 				$path,
 				-text	=> localtime($rh_last_mrt->{$_}) . ' last'
 				);
 			}
 		}
 	return 1;
 	}
#-------------------------------------------------
 sub DeletePaths
 	{
 	my ($self, $tree, $ra_paths) = @_;
 	my $path;
 	for(@$ra_paths)
 		{
 		$path = $_;
		$path =~ s!^/+!!;
 		$tree->deleteEntry($path);
 		}
 	return 1;
 	}
#-------------------------------------------------
 sub Download
 	{
 	my ($self) = @_;
 	return unless($self->SetParams());
 	return unless($self->{download}->Connect());
 	$self->{download}->MakeDirs($self->{ra_rdnil});
 	$self->{download}->StoreFiles($self->{ra_rfnil});
 	$self->{upload}->UpdateLastModified($self->{upload}->RtoL($self->{ra_rfnil}));
 	if($self->{overwrite} eq 'none')
 		{
 		$self->{ra_mrf} = [];
 		}
 	elsif($self->{overwrite} eq 'all')
 		{
 		$self->{download}->StoreFiles($self->{ra_mrf});
 		$self->{upload}->UpdateLastModified($self->{upload}->RtoL($self->{ra_mrf}));
 		}
 	elsif($self->{overwrite} eq 'older')
 		{
 		my $rh_current_mrt = $self->{download}->GetCurrent_Modified();
 		my $ra_lf	= $self->{download}->RtoL($self->{ra_mrf});
 		my $ra_newer	= [];
 		for(my $i = 0; $i <= $#{$self->{ra_mrf}}; $i++)
 			{
			push(@$ra_newer, $_)
 				if(
 				defined($rh_current_mrt->{$self->{ra_mrf}[$i]})
 				&& (-e $ra_lf->[$i])
 				&& ($rh_current_mrt->{$self->{ra_mrf}[$i]} > (stat($ra_lf->[$i]))[9])
 				);
 			}
 		$self->{download}->StoreFiles($ra_newer);
 		$self->{upload}->UpdateLastModified($self->{upload}->RtoL($ra_newer));
 		@{$self->{ra_mrf}} = @$ra_newer;
 		}
 	else
 		{
 		$self->Dialog(
 			-text	=> "overwrite behavior:  unknown",
 			-title	=> 'INPUT-ERROR'
 			)->Show();
 		return;
 		}
 	$self->{download}->Quit();
 	my $rh_ld	= {};
 	%$rh_ld		= %{$self->{rh_ld}};
 	my $rh_lf	= {};
 	%$rh_lf		= %{$self->{rh_lf}};
 	if($self->{download}->GetDelete())
 		{
 		$self->{download}->DeleteFiles($self->{ra_lfnir});
 		$self->{download}->RemoveDirs($self->{ra_ldnir});
 		delete(@{$rh_ld}{@{$self->{ra_ldnir}}});
 		delete(@{$rh_lf}{@{$self->{ra_lfnir}}});
 		}
# local tree
 	$self->{tree_local_dir}->deleteAll();
# old paths
 	$self->InsertPaths(
 		$self->{tree_local_dir},
 		[keys(%$rh_ld), keys(%$rh_lf)]
 		);
#new paths 	
 	$self->InsertPaths(
 		$self->{tree_local_dir},
 		$self->{download}->RtoL($_)
 		) for($self->{ra_rdnil}, $self->{ra_rfnil});
 	$self->InsertProperties(
 		$self->{tree_local_dir},
 		$self->{download}->RtoL($_),
 		'<downloaded>'
 		) for($self->{ra_rfnil}, $self->{ra_mrf});
 	$self->InsertProperties(
 		$self->{tree_local_dir},
 		$self->{download}->RtoL($self->{ra_rdnil}),
 		'<made>'
 		);
# remote tree
	$self->{tree_remote_dir}->deleteAll();
 	$self->InsertPaths(
 		$self->{tree_remote_dir},
 		[keys(%{$self->{rh_rd}}), keys(%{$self->{rh_rf}})]
 		);
 	$self->InsertProperties(
 		$self->{tree_remote_dir},
 		$_,
 		'<downloaded>'
 		) for($self->{ra_rfnil}, $self->{ra_mrf});
 	$self->InsertProperties(
 		$self->{tree_remote_dir},
 		$self->{ra_rdnil},
 		'<made in local>'
 		);
 	return 1;
 	}
#-------------------------------------------------
 sub Upload
 	{
 	my ($self) = @_;
 	return unless($self->SetParams());
 	return unless($self->{upload}->Connect());
 	$self->{upload}->MakeDirs($self->{ra_ldnir});
 	$self->{upload}->StoreFiles($self->{ra_lfnir});
 	$self->{download}->UpdateLastModified($self->{download}->LtoR($self->{ra_lfnir}));
 	if($self->{overwrite} eq 'none')
 		{
 		$self->{ra_mlf} = [];
 		}
 	elsif($self->{overwrite} eq 'all')
 		{
 		$self->{upload}->StoreFiles($self->{ra_mlf});
 		$self->{download}->UpdateLastModified($self->{download}->LtoR($self->{ra_mlf}));
 		}
 	elsif($self->{overwrite} eq 'older')
 		{
		my $rh_current_mrt = $self->{download}->GetCurrent_Modified();
 		my $ra_rf = $self->{upload}->LtoR($self->{ra_mlf});
 		my $ra_newer = [];
 		for(my $i = 0; $i <= $#{$self->{ra_mlf}}; $i++)
 			{
 			push(@$ra_newer, $_)
 				if(
 				defined($rh_current_mrt->{$ra_rf->[$i]})
 				&& (-e $self->{ra_mlf}[$i])
 				&& ($rh_current_mrt->{$ra_rf->[$i]} < (stat($self->{ra_mlf}[$i]))[9])
 				);
 			}
  		$self->{upload}->StoreFiles($ra_newer);
 		$self->{download}->UpdateLastModified($self->{download}->LtoR($ra_newer));
 		@{$self->{ra_mlf}} = @$ra_newer;
 		}
 	else
 		{
 		$self->Dialog(
 			-text	=> "overwrite behavior:  unknown",
 			-title	=> 'INPUT-ERROR'
 			)->Show();
 		return;
 		}
 	my $rh_rd	= {};
 	%$rh_rd		= %{$self->{rh_rd}};
 	my $rh_rf	= {};
 	%$rh_rf		= %{$self->{rh_rf}};
 	if($self->{upload}->GetDelete())
 		{
 		$self->{upload}->DeleteFiles($self->{ra_rfnil});
 		$self->{upload}->RemoveDirs($self->{ra_rdnil});
		delete(@{$rh_rd}{@{$self->{ra_rdnil}}});
 		delete(@{$rh_rf}{@{$self->{ra_rfnil}}});
 		$self->DeletePaths(
 			$self->{tree_remote_dir},
 			$_
 			) for($self->{ra_rfnil}, $self->{ra_rdnil});
 		}
 	$self->{upload}->Quit();
# remote tree
 	$self->{tree_remote_dir}->deleteAll();
# old paths
	$self->InsertPaths(
 		$self->{tree_remote_dir},
 		[keys(%$rh_rd), keys(%$rh_rf)]
 		);
# new paths
 	$self->InsertPaths(
 		$self->{tree_remote_dir},
 		$self->{upload}->LtoR($_)
 		) for($self->{ra_ldnir}, $self->{ra_lfnir});
 	$self->InsertProperties(
 		$self->{tree_remote_dir},
 		$self->{upload}->LtoR($_),
 		'<uploaded>'
 		) for($self->{ra_lfnir}, $self->{ra_mlf});
 	$self->InsertProperties(
 		$self->{tree_remote_dir},
 		$self->{upload}->LtoR($self->{ra_ldnir}),
 		'<made>'
 		); 
# local tree
 	$self->{tree_local_dir}->deleteAll();
 	$self->InsertPaths(
 		$self->{tree_local_dir},
 		[keys(%{$self->{rh_ld}}), keys(%{$self->{rh_lf}})]
 		);
 	$self->InsertProperties(
 		$self->{tree_local_dir},
 		$_,
 		'<uploaded>'
 		) for($self->{ra_lfnir}, $self->{ra_mlf});
 	$self->InsertProperties(
 		$self->{tree_local_dir},
 		$self->{ra_ldnir},
 		'<made in remote>'
 		);
 	return 1;
 	}
#-------------------------------------------------
# $self->{para}{access}{attribute}{value} = [user, ftpserver, pass, localdir, remotedir];
#-------------------------------------------------
 sub UpdateAccess
 	{
 	my ($self, $attr, $bentry, $value) = @_;
 	if(defined($self->{para}{access}{$attr}))
 		{
 		$self->{para}{user}	= $self->{para}{access}{$attr}{$value}[0];
 		$self->{para}{ftpserver}	= $self->{para}{access}{$attr}{$value}[1];
 		$self->{para}{pass}	= $self->{para}{access}{$attr}{$value}[2];
 		$self->{para}{localdir}	= $self->{para}{access}{$attr}{$value}[3];
 		$self->{para}{remotedir}	= $self->{para}{access}{$attr}{$value}[4];
 		}
 	return 1;
 	}
#-------------------------------------------------
 sub StoreParams
 	{
 	my ($self) = @_;
 	for(qw/user ftpserver pass localdir remotedir/)
 		{
 		$self->{para}{access}{$_}{$self->{para}{$_}} =
 			[
 			$self->{para}{user}, 
 			$self->{para}{ftpserver},
 			$self->{para}{pass},
 			$self->{para}{localdir},
 			$self->{para}{remotedir},
 			];
 		} 	
 	store($self->{para}, 'para');
 	return 1;
 	}
#-------------------------------------------------
 sub InsertStoredValues
 	{
 	my ($self) = @_;
 	$self->{bentry_user}->insert(	'end', $_) for(keys(%{$self->{para}{access}{user}}));
 	$self->{bentry_ftpserver}->insert(	'end', $_) for(keys(%{$self->{para}{access}{ftpserver}}));
 	$self->{bentry_local_dir}->insert(	'end', $_) for(keys(%{$self->{para}{access}{localdir}}));
 	$self->{bentry_remote_dir}->insert(	'end', $_) for(keys(%{$self->{para}{access}{remotedir}}));
 	return 1;
 	}
#------------------------------------------------- 
1;
#-------------------------------------------------
__END__

=head1 NAME

Tk::Mirror - Perl extension for a graphic user interface to up- or download local and remote directories

=head1 SYNOPSIS

# in the simplest kind and manner

 use Tk::Mirror;
 use Tk;
 my $mw->MainWindow->new();
 $mw->Mirror()->grid();
 MainLoop();

# in a detailed kind

 use Tk;
 use Tk::Mirror;
 my $mw = MainWindow->new();
 my $mirror = $mw->Mirror(
	-localdir		=> 'D:\\Homepage',
	-remotedir	=> 'www.tiscali.de/name',
	-user		=> 'my_ftp@username.de'
	-ftpserver	=> 'ftp.server.de',
	-pass		=> 'my_password',
 	-debug		=> 1,		# default	= 1
 	-delete		=> 'enable',	# default	= 'disabled'
 	-exclusions	=> ["private.txt", "secret.txt"],
 	-subset		=> [qr/(?i:HOME)(?i:DOC)?/, '.html'],
 	-timeout		=> 60,
 	-connection	=> undef, # or a connection  to a ftp-server 
 	-overwrite	=> 'older', 	# 'none', 'all', 'older', default = 'none'
 	)->grid();
 for(keys(%{$mirror->GetChilds()}))
 	{
	$mirror->Subwidget($_)->configure(
 		-font	=> "{Times New Roman} 14 {bold}",
 		);
 	}
 for(qw/
 	TreeLocalDir
 	TreeRemoteDir
 	/)
 	{
 	$mirror->Subwidget($_)->configure(
 		-background	=> "#FFFFFF",
 		-width		=> 40,
 		-height		=> 20,
 		);
 	}
 for(qw/
 	bEntryUser
 	EntryPass
 	bEntryFtpServer
 	bEntryLocalDir
 	bEntryRemoteDir
 	/)
 	{
 	$mirror->Subwidget($_)->configure(
 		-background	=> "#FFFFFF",
 		);
 	}
 MainLoop();
 
=head1 DESCRIPTION

This is a graphic user interface to compare, up- or download local and remote directories.

=head1 CONSTRUCTOR and INITIALIZATION

=item (widget-Mirror-object) MainWindowObject->Mirror (options)

=head2 OPTIONS

=item -ftpserver
the hostname of the ftp-server

=item -user	
the username for authentification

=item -pass
password for authentification

=item -localdir
local directory selecting information from, default '.'

=item -remotedir
remote location selecting information from, default '/' 

=item -debug
set it true for more information about the ftp-process, default 1 

=item -timeout
the timeout for the ftp-serverconnection

=item -delete
set this to "enable" to allow the deletion of files, default "disabled" 

=item -connection
 A Net::FTP-object, you should not use that. default = undef

=item -exclusions
 A reference to a list of strings interpreted as regular-expressios ("regex") 
 matching to something in the pathnames, you do not want to list. 
 default = empty list [ ]

=item -subset
 A reference to a list of strings interpreted as regular-expressios 
 matching to something in the local or remote pathnames,
 pathnames NOT matching will be ignored.
 You can also use a regex object [qr/TXT/i, "name", qr/MY_FILES/i, $regex]
 default = empty list [ ]

=item -overwrite
 Set the behavior for up- and download. 'none', 'all', 'older'
 default = 'none'
 The option 'older' will work only correctly, when both the FTP-Server
 and the computer using the same time-zone.

=head2 METHODS

=item (ref_hash_all_childs) Tk::MirrorObject->GetChilds (void)
returns a hash of all childs used in the put-together widget,
on which you can call the "configure" function.

 KEYS			VALUES
 'LabelUser'		=> $label_user,
 'bEntryUser'		=> $m->{bentry_user},
 'LabelFtpServer'		=> $label_ftpserver,
 'bEntryFtpServer'		=> $m->{bentry_ftpserver},
 'LabelPass'		=> $label_pass,
 'EntryPass'		=> $m->{entry_pass},
 'LabelLocalDir'		=> $label_local_dir,
 'LabelRemoteDir'		=> $label_remote_dir,
 'bEntryLocalDir'		=> $m->{bentry_local_dir},
 'bEntryRemoteDir'	=> $m->{bentry_remote_dir},
 'TreeLocalDir'		=> $m->{tree_local_dir},
 'TreeRemoteDir'		=> $m->{tree_remote_dir},
 'LabelOverwrite'		=> $m->{label_overwrite},
 'rButtonNone'		=> $m->{rbutton_none},
 'rButtonAll'		=> $m->{rbutton_all},
 'rButtonOlder'		=> $m->{rbutton_older},
 'ButtonUpload'		=> $m->{button_upload},
 'ButtonCompare'		=> $m->{button_compare},
 'ButtonDownload'		=> $m->{button_download},

=item (ref_scalar_child) MirrorObject->Subwidget(above shown key)
returns a reference of a child widget you can call the configure
method

=head2 You should NOT use the following methods directly!!!

=item (1|undef) Tk::MirrorObject->CompareDirectories (void)
 Compares the localdirectory with the remotedirectory and draws 
 the directory trees.
 
=item (1|undef) Tk::MirrorObject->Download (void)
 Download the remote directory to local hard disk, and draws the
 directory trees again.

=item (1|undef) Tk::MirrorObject->Upload (void)
 Upload the local directory from hard disk to the remote FTP-location,
 and draws the directory trees again.

=item (1|undef) Tk::MirrorObject->SetParams (void)
 Hands over the parameter, entered in the graphic user interface,
 to the Net::Download- and Net::Upload-Object.
 
=item (1) Tk::MirrorObject->StoreParams (void)
 Stores the values, entered in the graphic user intervace.

=item (1) Tk::MirrorObject->UpdateAccess (attribute, browseentry, value)
 Called by the BrowseEntry-Widget to update other widgets.
 
=item (1) Tk::MirrorObject->InsertLocalTree (void)
 Insert the local directory-tree after a call to the Compare() method. 
 
=item (1) Tk::MirrorObject->InsertRemoteTree (void)
 Insert the remote directory-tree after a call to the Compare() method.

=item (1) Tk::MirrorObject->InsertStoredValues (void)
 Insert the stored parameters in the BrowseEntry-Widgets.

=item (1) Tk::MirrorObject->InsertPaths (tree-widget, ref_array_paths)
 Takes a tree-widget and a array-reference of pathnames 
 to insert them in the directory tree.

=item (1) Tk::MirrorObject->DeletePaths (tree-widget, ref_array_paths)
 Takes a tree-widget and a array-reference of pathnames 
 to delete them from the directory tree.
 
=item (1) Tk::MirrorObject->InsertProperties (tree-widget, ref_array_paths, property)
 Takes a tree-widget, a array-reference of pathnames and a string.
 The string will be added to all pathnames.

=item (1) Tk::MirrorObject->DeleteProperties (tree-widget, ref_array_pahts)
 Takes a tree-widget and a array-reference of pathnames.
 All strings, added to the pathnames, will be deleted. 

=item (1) Tk::MirrorObject->InsertRemoteModifiedTimes (ref_array_remote_files)
 Takes a array-reference of remote files.
 The last- and current modified-times from the remote files, will be added.

=item (1) Tk::MirrorObject->InsertLocalModifiedTimes (ref_array_local_files)
 Takes a array-reference of local files.
 The last- and current modified-times from the local files, will be added.

=head2 EXPORT

None by default.

=head1 SEE ALSO

 Tk
 Net::MirrorDir
 Net::UploadMirror
 Net::DownloadMirror
 http://freenet-homepage.de/torstenknorr/index.html

=head1 BUGS

Maybe you'll find some. Let me know.

=head1 REPORTING BUGS

 When reporting bugs/problems please include as much information as possible.

=head1 AUTHOR

Torsten Knorr, E<lt>create-soft@tiscali.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 - 2008 by Torsten Knorr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.9.2 or,
at your option, any later version of Perl 5 you may have available.

=cut




