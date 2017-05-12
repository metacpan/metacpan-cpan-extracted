#!perl -w
#
# Tk Transaction Manager.
# Language localization
#
# makarow, demed
#

package Tk::TM::Lang;
require 5.000;
use strict;
require Exporter;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = '0.52';
@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw(txtMenu txtHelp txtMsg);

use vars qw($Lang);
$Lang   ='';      # set localization

1;


sub txtHelp {
my $txt;
$txt =
  ["-------- 'File' - File operations --------"
  ,"'Save', [S], [Shift+F2], [Ctrl+S] - save modified data."
  ,"'Reread', [<>], [F5] - reread data to screen, refresh view. Same as 'Query' but keeps current position."
  ,"'Print...', [Ctrl+P] - print data."
  ,"'Export...' - export data to file shoosen."
  ,"'Import...' - import data from file choosen."
  ,"'Close', [Alt+F4] - close window."
  ,"'Exit', [Shift+F3] - exit application."
  ,"-------- 'Edit' - Editing data --------"
  ,"'New record', [+], [Ctrl+N] - create (append) new record of data."
  ,"'Delete record', [-], [Ctrl+Y] - delete the current record of data."
  ,"'Undo edit' - undo changes made in current record."
  ,"'Prompt...', [F4] - entry help screen to choose value to enter into field."
  ,"'Cut' - cut selected text from field onto clipboard."
  ,"'Copy' - copy selected text from field onto clipboard."
  ,"'Paste' - paste text from clipboard to cursor position."
  ,"'Delete' - delete selected text."
  ,"-------- 'Actions', [..] - Actions of application --------"
  ,"Contains available application actions."
  ,"-------- 'Search' - Search, Query, Navigation --------"
  ,"'Query', [Q] - read data onto screen (query database)."
  ,"'Reread', [F5] - reread data onto screen, see this in 'File' menu above."
  ,"'Clear', [C] - clear current data on screen, new records may be entered."
  ,"'Find...', [F], [Ctrl+F] - find value in current column with regilar expression entered."
  ,"'Find Next', [Ctrl+G], [Ctrl+L] - find next value with serch entered above."
  ,"'Top', [<<], [Ctrl+Home] - go to the first record of data."
  ,"'Previos', [<], [PageUp] - go to the previos page or record of data."
  ,"'Next', [>], [PageDn] - go to the next page or record of data."
  ,"'Bottom', [>>], [Ctrl+End] - go to the last record of data."
  ,"-------- 'Help' - Help on application --------"
  ,"'Help...', [?], [F1] - info on using application."
  ,"'About...' - general info on application."
  ] if !$Lang;

$txt =
  ["-------- 'Файл' - Файловые операции --------"
  ,"'Сохранить', [S], [Shift+F2], [Ctrl+S] - сохранить измененные данные."
  ,"'Перечитать', [<>], [F5] - перечитать данные на экран, освежить экран. Аналогично 'Query' но сохраняет текущую позицию."
  ,"'Печатать...', [Ctrl+P] - печатать данные."
  ,"'Экспорт...' - экспортировать данные в выбранный файл."
  ,"'Импорт...' - импортировать данные из выбранного файла."
  ,"'Закрыть', [Alt+F4] - закрыть окно."
  ,"'Выход', [Shift+F3] - завершить приложение."
  ,"-------- 'Редактировать' - Операции редактирования --------"
  ,"'Новая запись', [+], [Ctrl+N] - создать (добавить) новую запись данных."
  ,"'Удалить запись', [-], [Ctrl+Y] - удалить текущую запись данных."
  ,"'Отменить редактирование' - отменить изменения текущей записи."
  ,"'Подсказка...', [F4] - вызвать экран подсказки заполнения текущего поля."
  ,"'Вырезать' - вырезать выбранный текст из поля в буфер обмена."
  ,"'Копировать' - скопировать выбранный текст из поля в буфер обмена."
  ,"'Вставить' - вставить текст из буфера обмена в позицию курсора."
  ,"'Удалить' - удалить выбранный текст."
  ,"-------- 'Действия', [..] - Прикладные действия --------"
  ,"Содержит имеющиеся прикладные действия."
  ,"-------- 'Поиск' - Поиск, Запросы, Навигация --------"
  ,"'Запрос', [Q] - прочитать данные на экран (запрос к базе данных)."
  ,"'Перечитать', [F5] - перечитать данные на экран, освежить экран. См. также меню 'Файл'."
  ,"'Очистить', [C] - убрать текущие данные с экрана, можно создавать новые записи."
  ,"'Найти...', [F], [Ctrl+F] - найти значение в текущем столбце, соответствующее вводимому регулярному выражению."
  ,"'Найти далее', [Ctrl+G], [Ctrl+L] - найти следующее значение в описанном выше поиске."
  ,"'Начало', [<<], [Ctrl+Home] - перейти к первой записи данных."
  ,"'Предыдущая', [<], [PageUp] - перейти к предыдущей странице или записи данных."
  ,"'Следующая', [>], [PageDn] - перейти к следующей странице или записи данных."
  ,"'Последняя', [>>], [Ctrl+End] - перейти к последней записи данных."
  ,"-------- 'Справка' - Получение справки --------"
  ,"'Справка...', [?], [F1] - сведения об использовании приложения."
  ,"'О приложении...' - основные сведения о приложении."
  ] if $Lang;

  return($txt)
}


sub txtMenu {
  return(
  ['File','~Save','~Reread','~Print...','~Export...','~Import...','~Close','~Exit'
  ,'Edit','~New record','~Delete record','~Undo record','~Prompt...','~Undo','Cu~t','~Copy','~Paste','De~lete','Select ~All'
  ,'Actions'
  ,'Search','~Query','~Reread','~Clear','Con~dition...','~Find...','Find ~Next','~Top','~Previos','Ne~xt','~Bottom'
  ,'Help','~Help...','~About...'
  ]
  ) if !$Lang;

  return(
  ['Файл','~Сохранить','~Перечитать','~Печатать...','~Экспорт...','~Импорт...','~Закрыть','~Выход'
  ,'Редактировать','~Новая запись','~Удалить запись','~Отменить редактирование','~Подсказка...','~Undo','~Вырезать','~Копировать','Вст~авить','~Удалить','Select ~All'
  ,'Действия'
  ,'Поиск','~Запрос','~Перечитать','~Очистить','~Условие...','~Найти...','~Найти далее','~Начало','~Предыдущая','~Следующая','~Последняя'
  ,'Справка','~Справка...','~О приложении...'
  ]
  ) if $Lang;
}


sub txtMsg {
 return($_[0]) if !$Lang;
 my %msg =(
  'About application' => 'О приложении'
 ,'Cancel' => 'Отменить'
 ,'Choose' => 'Выбрать'
 ,'Close' => 'Закрыть'
 ,'Closing' => 'Закрытие'
 ,'Condition' => 'Условие'
 ,'Data was modified' => 'Данные были изменены'
 ,'Database' => 'База данных'
 ,'Error' => 'Ошибка'
 ,'Find' => 'Найти'
 ,'Function not released' => 'Функция не реализована'
 ,'Help' => 'Справка'
 ,'Load data from file' => 'Загрузить данные из файла'
 ,'Login' => 'Регистрация'
 ,'Ok' => 'Исполнить'
 ,'Opening' => 'Открытие'
 ,'Operation' => 'Деятельность'
 ,'Order by' => 'Сортировка'
 ,'Pardon' => 'Извините'
 ,'Password' => 'Пароль'
 ,'Save changes?' => 'Сохранить изменения?'
 ,'Save data into file' => 'Сохранить данные в файл'
 ,'User' => 'Пользователь'
 ,'Where condition' => 'Условие'
 ,'Writing' => 'Запись'
 );
 return($msg{$_[0]} || $_[0]);
}

