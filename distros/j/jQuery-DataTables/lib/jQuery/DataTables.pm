package jQuery::DataTables;
use strict;
use warnings;
use utf8;
#use Data::Dump qw(ddx dd pp);

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = '0.906';
    @ISA         = qw(Exporter);
    #Give a hoot don't pollute, do not export more than needed by default
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
}


=head1 DESCRIPTION

jQuery::DataTables - серверная часть для выполнения AJAX запросов DataTables

=cut

=head1 SYNOPSYS

use strict;
use jQuery::DataTables;

...
my $dt = new jQuery::DataTables( cgi => $cgi, dbh => $c->app->dbh );
my $res = $dt->getTableData( 'SELECT DISTINCT id, col_int, col_text, col_real FROM datatable', [qw{id col_int col_text col_real}] );
$c->render( json => $res );

=cut

sub new {
	my $class = shift;
	my $self  = {};
	$self = {@_};

	die("Undefined (dbh) parameter") unless $self->{dbh} && UNIVERSAL::isa( $self->{dbh}, 'DBI::db' );
	die("Undefined (cgi) parameter") unless $self->{cgi};

	bless $self, $class;
	return $self;

} ## end sub new

=head2 prepareDataTableRequest()

Подготавливает данные из DataTable  запроса для удобного использования
и возвращает хэш с данными.
Делается это для упрощения использования странного формата, заложенного в DataTables изначально.

=head3 DataTables param() - описания из документации

    Type    Name    Info
    --------------------
    int     iDisplayStart       Display start point in the current data set.
    $iDisplayStart

    int     iDisplayLength      Number of records that the table can display in the current draw.
    $iDisplayLength             It is expected that the number of records returned will be equal to this number,
                                unless the server has fewer records to return.

    int     iColumns            Number of columns being displayed (useful for getting individual column search info)
    $iColumns

    string  sSearch             Global search field
    $sSearch

    bool    bRegex              True if the global filter should be treated as a regular expression for advanced filtering, false if not.
    $bRegex

    bool    bSearchable_(int)   Indicator for if a column is flagged as searchable or not on the client-side
    @abSearchable

    string  sSearch_(int)       Individual column filter
    @asSearch

    bool    bRegex_(int)        True if the individual column filter should be treated as a regular expression
    @abRegex                     for advanced filtering, false if not

    bool    bSortable_(int)     Indicator for if a column is flagged as sortable or not on the client-side
    @abSortable

    int     iSortingCols        Number of columns to sort on
    $iSortingCols

    int     iSortCol_(int)      Column being sorted on (you will need to decode this number for your database)
    @aiSortCol

    string  sSortDir_(int)      Direction to be sorted - "desc" or "asc".
    @asSortDir

    string  mDataProp_(int)     The value specified by mDataProp for each column. This can be useful
    @amDataProp                  for ensuring that the processing of data is independent from the order of the columns.

    string  sEcho               Information for DataTables to use for rendering.
    $sEcho

=cut

sub prepareDataTableRequest {
	my $self = shift;
	my $c    = $self->{cgi};    # CGI-compatible by param()

	#ddx $c->req->params->to_hash;

	# соберём всё в более удобные объекты

	# int   iDisplayStart   Display start point in the current data set.
	my $iDisplayStart = $c->param('iDisplayStart');

	# int   iDisplayLength  Number of records that the table can display in the current draw.
	#                       It is expected that the number of records returned will be equal
	#                       to this number, unless the server has fewer records to return.
	my $iDisplayLength = $c->param('iDisplayLength');

	# int     iColumns    Number of columns being displayed
	#                     (useful for getting individual column search info)
	#                     Количество отображаемых столбцов
	#                     (удобно для получения информации о поисковых запросах отдельных столбцов)
	my $iColumns = $c->param('iColumns');

	# bool  bRegex  True if the global filter should be treated as a regular expression for advanced filtering, false if not.
	#               true если глобальный фильтр должен использоваться как регулярное выражение, false если нет.
	my $bRegex = $c->param('bRegex');

	# bool    bRegex_(int)    True if the individual column filter should be treated
	#                         as a regular expression for advanced filtering, false if not
	#                         true если индивидуальный фильтр столбца должен использоваться
	#                         как регулярное выражение, false если нет.
	my @abRegex;

	# string    sSearch     Global search field
	#                       Глобальный поисковый запрос
	my $sSearch = $c->param('sSearch');

	# string    sSearch_(int)   Individual column filter
	#                           Индивидуальные поисковые фильтры для столбцов
	my @asSearch;

	# int     iSortingCols    Number of columns to sort on
	#                         Количество столбцов для сортировки
	my $iSortingCols = $c->param('iSortingCols');

	# string    sEcho   Information for DataTables to use for rendering.
	#                   Этот параметр возвращается в ответе в неизменном виде.
	#                   Сильно рекомендуется делать его целым числом, уникальным для запросов.
	my $sEcho = $c->param('sEcho');

	# bool   bSearchable_(int)   Indicator for if a column is flagged as searchable or not on the client-side
	#                            Индикатор того, что столбец используется или не
	#                            используется в поисковом выражении на клиентской стороне
	my @abSearchable;

	# bool    bSortable_(int)     Indicator for if a column is flagged as sortable or not on the client-side
	#                             Индикатор того, что столбец используется или не используется
	#                             для сортировки на клиентской стороне
	my @abSortable;
	# int     iSortCol_(int)  Column being sorted on (you will need to decode this number for your database)
	#                         Столбец, по которому сортируем результат
	#(надо превращать этот номер в название столбца в базе данных)
	my @aiSortCol;

	# string  sSortDir_(int)  Direction to be sorted - "desc" or "asc".
	#                         Направление сортировки - DESC или ASC
	my @asSortDir;

	# string  mDataProp_(int)     The value specified by mDataProp for each column. This can be useful
	#                             for ensuring that the processing of data is independent from the order of the columns.
	my @amDataProp;

	foreach my $i ( 0 .. $iColumns - 1 ) {
		push @abSearchable, $c->param("bSearchable_$i");
		push @asSearch,     $c->param("sSearch_$i");
		push @abRegex,      $c->param("bRegex_$i");
		push @abSortable,   $c->param("bSortable_$i");
		push @aiSortCol,    $c->param("iSortCol_$i");
		push @asSortDir,    $c->param("sSortDir_$i");
		push @amDataProp,   $c->param("mDataProp_$i");
	} ## end foreach my $i ( 0 .. $iColumns...)

	my $req = {
		# параметры общего назначения
		iColumns   => $iColumns,      # количество отображаемых столбцов. Отображаемых в интерфейсе, не в запросе
		sEcho      => $sEcho,         # уникальный тэг запроса
		amDataProp => \@amDataProp,

		# LIMIT ... OFFSET
		iDisplayStart  => $iDisplayStart,     # с какой стноки начинать выдачу
		iDisplayLength => $iDisplayLength,    # сколько строк выдаавть

		# WHERE общие для всех столбцов
		bRegex  => $bRegex,                   # true == общий поиск - regex поиск
		sSearch => $sSearch,                  # общий поиск

		abSearchable => \@abSearchable,       #Индикатор того, что столбец используется
		                                      #для сортировки на клиентской стороне.
		                                      # Что это значит я не знаю...

		# WHERE индивидуальные для столбцов
		abRegex => \@abRegex,                 #true если индивидуальный фильтр столбца
		                                      #должен использоваться как регулярное выражение

		asSearch => \@asSearch,               #Индивидуальные поисковые фильтры для столбцов

		# ORDER BY
		iSortingCols => $iSortingCols, #Количество столбцов для сортировки
		abSortable   => \@abSortable,  #Индикатор того, что столбец используется для сортировки на клиентской стороне
		aiSortCol    => \@aiSortCol,   #Столбец, по которому сортируем результат
		                               #(надо превращать этот номер в название столбца в базе данных)
		asSortDir    => \@asSortDir,   #Направление сортировки - DESC или ASC

	};
	#ddx $req;
	$self->{req} = $req;
	return $req;
} ## end sub prepareDataTableRequest

=head2 getTableData ()

Мы можем вызывать эту функцию с указанием запроса и какие столбцы он возвращает, например

    getTableData ('SELECT a,b,c FROM table', ['a', 'b', 'c'])

Названия столбцов в фильтрах будут использоваться с указанием их в кавычках,
так что надо указывать имена столбцов так, чтобы база данных их правильно поняла. Многие СУБД позволяют имена столюцов
возвращать большими или маленькими буквами, по флагу FetchHashKeyName => 'NAME_lc' или FetchHashKeyName => 'NAME_uc'.

К этому запросу добавляется поисковое выражение WHERE, сортировка ORDER BY и  лимиты LIMIT ... OFFSET

Поисковое выражение может быть одно на все столбцы, либо разные выражения на разные (некоторые!) столбцы.

Поисковое выражение должно трактоваться как regexp либо для всех столбцов, либо regexp для некоторых столбцов.

Сначала выполняется общее поисковое выражение (если указано), затем для полученного результата выполняются
индивидуальные для столбцов поисковые выражения. Ясно, что лучше использовать только индивидуальные выражения.

Данная реализация не учитывает флаг bRegex - так как пока непонятно, как обеспечить исполнение этого флага для разных СУБД.

=cut

sub getTableData {
	my $self    = shift;
	my $query   = shift;    # запрос, возвращающий данные до фильтрации и сортировки
	my $columns = shift;    # имена столбцов, возвращаемые запросом.
	                        # Если не указано, то будет определено автоматически,
	                        # выполняя запрос "$query LIMIT 0"

	my $c   = $self->{cgi};                       # CGI-compatible by param()
	my $dbh = $self->{dbh};
	my $r   = $self->prepareDataTableRequest();

	# LIMIT ... OFFSET
	my @limits;
	push @limits, "LIMIT $r->{iDisplayLength}" if ( $r->{iDisplayLength} );
	push @limits, "OFFSET $r->{iDisplayStart}" if ( $r->{iDisplayStart} && $r->{iDisplayStart} > 0 );
	my $limit = join ' ', @limits;
	# WHERE общие для всех столбцов

	#   Ordering

	my @where;

	my $abSearchable = $r->{abSearchable};
	my $sSearch      = $r->{sSearch};
	if ( defined $sSearch and $sSearch ne '' ) {

		for ( my $i = 0; $i < scalar(@$abSearchable); $i++ ) {
			if ( $abSearchable->[$i] and $abSearchable->[$i] eq 'true' ) {

				if ( $r->{bRegex} eq 'true' ) {
					push @where, qq{"$columns->[$i]" like '\%$sSearch\%'};

				} ## end if ( $r->{bRegex} eq 'true')
				else {
					push @where, qq{"$columns->[$i]" like '\%$sSearch\%'};
				} ## end else [ if ( $r->{bRegex} eq 'true')]
			} ## end if ( $abSearchable->[$i...])
		} ## end for ( my $i = 0; $i < scalar...)
	} ## end if ( defined $sSearch ...)

	# WHERE индивидуальные для столбцов

	for ( my $i = 0; $i < scalar(@$abSearchable); $i++ ) {
		my $asSearch = $r->{asSearch};
		my $abRegex  = $r->{abRegex};

		if ( $abSearchable->[$i] and $abSearchable->[$i] eq 'true' and $asSearch->[$i] ne '' ) {
			if ( $abRegex->[$i] eq 'true' ) {
				push @where, qq{"$columns->[$i]" like '\%$asSearch->[$i]\%'};

			} ## end if ( $abRegex->[$i] eq...)
			else {
				push @where, qq{"$columns->[$i]" like '\%$asSearch->[$i]\%'};
			} ## end else [ if ( $abRegex->[$i] eq...)]
		} ## end if ( $abSearchable->[$i...])
	} ## end for ( my $i = 0; $i < scalar...)

	my $where = join ' and ', @where;
	$where = ' WHERE ' . $where if $where;

	# ORDER BY

	my @order;

	my $aiSortCol = $r->{aiSortCol};
	my $asSortDir = $r->{asSortDir};
	if (@$aiSortCol) {

		for ( my $i = 0; $i < scalar(@$aiSortCol); $i++ ) {
			my $column    = $columns->[ $aiSortCol->[$i] ];
			my $direction = $asSortDir->[$i];
			$direction = ( $direction eq 'asc' ) ? 'asc' : 'desc';

			push @order, qq{"$column" $direction};
		} ## end for ( my $i = 0; $i < scalar...)
	} ## end if (@$aiSortCol)

	my $order = join ' , ', @order;
	$order = 'ORDER BY ' . $order if $order;

	# iTotalRecords - Total records, after filtering (not just the records on this page, all of them)
	# iTotalDisplayRecords - Total records, before filtering

	my $query_iTotalRecords = <<END;
select count(*) from(
    $query
)
END

	#ddx $query_iTotalRecords;
	my ($iTotalRecords) = $dbh->selectrow_array($query_iTotalRecords);

	my $query_iTotalDisplayRecords = <<END;
select count(*) from(
    $query
    $where
)
END

	#ddx $query_iTotalDisplayRecords;
	my ($iTotalDisplayRecords) = $dbh->selectrow_array($query_iTotalDisplayRecords);

	my $query_result = <<END;
$query
$where
$order
$limit
END

	#ddx $query_result;
	my $aaData = $dbh->selectall_arrayref( $query_result, {}, );
	return {
		"sEcho"                => $r->{'sEcho'},
		"iTotalRecords"        => $iTotalRecords,
		"iTotalDisplayRecords" => $iTotalDisplayRecords,
		"aaData"               => $aaData,
		}

} ## end sub getTableData

=head1 AUTHORS

Konstantin Tokar <konstantin@tokar.ru>

=cut

1;
