
my $editor_default_values =
	{
	  font_size               => 11
	, caret_width             => 1
	
	, margin_size             => 15
	, extra_margin_size       => 2
	, line_number_margin_size => 35
	
	, tab_size                => 3
	, number_of__tab_stops    => 10
	, right_margin            => 80
	, page_limit              => 120
	, horizontal_scroll_size  => 20
	, max_horizontal_position => 5
	, tool_tip_delay          => 180
	
	, escape_closes_application => 1
	, display_line_number       => 10
	, create_backup_file        => 0
	, display_page_limit        => 0
	, display_tab_stops         => 0
	, display_out_limit         => 0
	, tab_display_as_graphic    => 1

	, display_console           => 10
	, display_element_rectangle => 0
	, display_command_conflicts => 1
	, display_core_files        => 1
	, display_setup_files       => 1
	
	, setup_path                => ['Setup']
	
	, dictionary                => 'common/Db/linux.words.txt'
	
	, '.any' => Lexer::Any
	
	, '.pl'  => 'setup/perl/perl.hive'
	, '.pm'  => 'setup/perl/perl.hive'
	} ;
	
return($editor_default_values) ;