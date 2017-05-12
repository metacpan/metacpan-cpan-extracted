%#
%# !!! ƒл€ нормальной работы autohandler.mc в корневом каталоге календарной
%# папки должен непосредственно ссылатьс€ на мен€ через inherit. “аким образом
%# мы сможем определить путь до его корневой папки.
%#
%#
%#
%#
%#
%#
%#
%#
%#
%#
%#
%#
%#----------------------------------------------------------------------------
%	my @date = $C->date;
%	if (! -d "$base_path/". join('/', @date)) {
  <% pick_lang(
			rus => "<b>ƒанных за " . sprintf("%02d.%02d.%04d", reverse @date) . " нет.</b>",
			eng => "<b>No data for " . sprintf("%02d.%02d.%04d", reverse @date) . "</b>") %>
% } else {
	<% $m->call_next %>
%}
%return;


%#=== @metags HTMLhead ====================================================
<%method HTMLhead>
%	my @date = $C->date;
%	if (! -d "$gdata{base_path}/". join('/', @date)) {
	<meta name="robots" content="noindex, nofollow">
% }
</%method>



%#== @METAGS MenuItems =======================================================
%#
<%method MenuItems><%perl>
	my (@menu, @date);

	push @menu, @{ $m->comp("PARENT:MenuItems")};
	@date = $C->date;

	# Look is any data exists for specific day of month
	#
	my @days = map { $_? "$base_uri/$date[0]/$date[1]/$_/": undef}
			($m->comp('.days', dir=> "$base_path/$date[0]/$date[1]"));

	for (1..31) {
		$C->url( $_, $days[$_]);
	}

	push @menu, ['html' => $C->draw	];

#push @menu, ['html' =>
#"<br> source_dir: " . $m->callers(1)->source_dir .
#"<br> path: ". $m->callers(1)->path .
#"<br> dir_path: ". $m->callers(1)->dir_path .
#"<br> dhandler_arg: ". $m->dhandler_arg .
#"<br> filename: ". $r->filename .
#"<br> script_name: ". $ENV{SCRIPT_NAME} .
#"<br> uri: ".$r->uri ];

	return [@menu];
</%perl></%method>






%#=== @METAGS onStartRequest =================================================
<%method onStartRequest><%perl>
	my $uri = $r->uri;
	my @date = (0,0,0);
  my %args = $m->request_args;
  $C = new ePortal::HTML::Calendar( m => $m );

  # $base_uri is a base directory not including trailing slash
	# where year directories are placed
	# $base_uri is required to be!
	$base_uri = undef;
	unless ( ($base_uri) = ($uri =~ (m|^(.*)/\d\d\d\d/|))) {
		$base_uri = $r->uri;
		$base_uri =~ s|/$||o;
	}
	# remove /last
	$base_uri =~ s|/last$||o;

	# look for physical path
	my $subr = $r->lookup_uri( $base_uri . "/" );
	$base_path = $subr->filename;
	if (! -e $base_path) {
		logline('error', "$uri is not a 'like-calendar' directory. base directory doesn't exists");
		return "/index.htm";
	}


	# Calendar was adjusted via URL parameters. Do redirect
	if ($C->date_source eq "url") {
		return $base_uri . "/" . join("/", $C->date) . "/";
	}


	if (($uri =~ m|/last$|) or (exists $args{last})) {
		@date = $m->current_comp->owner->call_method("lastday", path => $base_path);
		if (! $date[0]) {
			logline('error', "No year folder for $base_uri");
			return "/index.htm";
		}

	} elsif ($uri =~ m|/(\d\d\d\d)/(\d\d?)/(\d\d?)/?|o) {
		$C->set_date( $1, $2, $3 );

	} else {
		# The current uri is not yet proper. We need a redirect in any case
		if ($uri =~ m|/(\d\d\d\d)/(\d\d?)/?|o) {
			@date = $m->current_comp->owner->call_method("firstday", path => $base_path, year => $1, month => $2);
    }
		if (! $date[0] and $uri =~ m|/(\d\d\d\d)/?|o) {
			@date = $m->current_comp->owner->call_method("firstday", path => $base_path, year => $1);
    }
		return "$base_uri/last" if (! $date[0]);
	}

	# @date is defined if we need a redirect
	if ($date[1] > 0) {
		$C->set_date(@date);
		return $base_uri . "/" . join("/", @date) . "/";
	}

	# ѕередаем управление нашему родителю.
	$m->comp("PARENT:onStartRequest", %ARGS);
</%perl></%method>






%#== @METAGS .lastday ========================================================
%# ѕоиск последнего (максимального) дн€ во всем разделе.
<%method lastday><%perl>
	my @date = ();
	my $path = $ARGS{path};

	$path =~ s|/$||o;			# Remove last slash

	# Find last year
	opendir (D, $path);
	while(my $file = readdir D) {
		next unless $file =~ /\d\d\d\d/;
		$date[0] = $file if ($file > $date[0]);
	}
	closedir D;
	$path .= "/$date[0]";

	# Find last month and last day
	for my $i(1..2) {
		opendir (D, $path);
		while(my $file = readdir D) {
			next unless $file =~ /\d\d?/;
			$date[$i] = $file if ($file > $date[$i]);
		}
		closedir D;
		$path .= "/$date[$i]";
	}

	if ($date[0] == 0 or $date[1] == 0 or $date[2] == 0) {
		@date = ();
	}

	return @date;
</%perl></%method>


%#== @METAGS firstday ========================================================
%# Find fist day for the year
<%method firstday><%perl>
	my $path = $ARGS{path};
	my $year = $ARGS{year};
	my $month = $ARGS{month};
	my @date = ($year, $month, 0);

	$path .= "/" unless $path =~ m|/$|o;
	$path .= $year;

	# Find last month and last day
	for my $i(1..2) {
		opendir (D, $path);
		while(my $file = readdir D) {
			next unless $file =~ /\d\d?/;
			$date[$i] = $file if ($file < $date[$i] or $date[$i] == 0);
		}
		closedir D;
		$path .= "/$date[$i]";
	}

	if ($date[0] == 0 or $date[1] == 0 or $date[2] == 0) {
		@date = ();
	}

	return @date;
</%perl></%method>




%#============================================================================
<%def .days><%perl>   # @METAGS .days
# Description: «аполн€ет массив таким образом, что если за
# какое-то число есть данные, то этот элемент массива = 1
# Parameters: dir path
# Returns: Array or arrayref (wantarray)
############################################################################
	my $dir = $ARGS{dir};
	my @days = ();

	return wantarray? @days : \@days unless (-d $dir);

	# --------------------------------------------------------------------
	# ѕеребираем все вложенные каталоги (1..31) и включаем только те,
	# в которых есть какие-то файлы.
	for my $d (1..31) {
		if (opendir (DD, "$dir/$d")) {
			while(readdir DD) {
				next if /^\./;
				$days[$d] = $d;
				last;
			}
			closedir DD;
		}
	}

	return wantarray? @days : \@days;
</%perl></%def>



%#=== @METAGS once =========================================================
<%once>
our $C;
our $base_uri;
our $base_path;
</%once>


%#=== @METAGS flags =========================================================
<%flags>
inherit => '/autohandler.mc'
</%flags>


%#=== @METAGS attr =========================================================
<%attr>
dir_columns => ['icon', 'description']
</%attr>
