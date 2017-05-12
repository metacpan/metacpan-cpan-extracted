    use WWW::Wuala;
	
  $wu = WWW::Wuala->new();
  
  $counter = $wu->wualaFilescounter();
  print $counter . "\n";

  @search = $wu->search('Wuala',5,1);
  foreach $pr (@search) {
  print $pr . "\n";
  }

  $wu->server(1) || die "wtf";
  chomp($fname = <STDIN>);
  $wu->download('Perforin/Images/WUALA3.JPG',$fname) || die "wtf";

  #$wu->preview_xml("Perforin"); 

  %prev = $wu->preview("Perforin");
  print "@{ $prev{name} }\n"; # Show only the Name
  print "@{ $prev{publicGroups_name} }\n"; # Show only the public group names
  for $all ( keys %prev ) { print "@{ $prev{$all} }\n"; } # Show everything