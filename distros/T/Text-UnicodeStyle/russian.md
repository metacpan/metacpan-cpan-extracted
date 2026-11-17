# substitute-letters

Perl-модуль и CLI-утилита для замены латинских букв на похожие символы
из других диапазонов Unicode — математические алфавитные символы
(monospace, script, fraktur, doublestruck, sans-serif и их начертания),
обведённые формы (circled, parenthesized, squared и их инвертированные
варианты), fullwidth и другие. Например, `ABC` → `𝙰𝙱𝙲` (monospace)
или `𝒜ℬ𝒞` (script).

Пробелы и прочие не-буквы не изменяются —
кроме стилей `bold`, `circled`, `doublestruck`, `fullwidth`,
`monospace`, `parenthesized`, `sans_serif` и `sans_serif_bold`,
в которых также преобразуются цифры `0-9` (у `parenthesized` нет
глифа для `0`), а стиль `fullwidth` дополнительно переводит всю
печатаемую ASCII-пунктуацию (включая `_`) в полноширинную форму.
Стили `squared`, `negative_circled` и `negative_squared` покрывают
только заглавные буквы.

Английская документация: [README.md](README.md)

Репозиторий: <https://github.com/shoorick/substitute-letters> —
багрепорты и другие issues приветствуются:
<https://github.com/shoorick/substitute-letters/issues>

## Возможности

- `Text::UnicodeStyle` — API: `stylize($string, $style)` и `styles()`
- `bin/substitute-letters` — CLI-обёртка с `Getopt::Long`
- 19 стилей: `bold`, `bold_fraktur`, `bold_italic`, `bold_script`,
  `circled`, `doublestruck`, `fraktur`, `fullwidth`, `italic`,
  `monospace`, `negative_circled`, `negative_squared`, `parenthesized`,
  `sans_serif`, `sans_serif_bold`, `sans_serif_bold_italic`,
  `sans_serif_italic`, `script`, `squared`

## Использование CLI

```sh
# текст аргументами (склеиваются через пробел)
bin/substitute-letters --style script 'Hello, World!'
bin/substitute-letters -s fraktur route_id

# или через stdin
echo mkdir folder_name | bin/substitute-letters -s monospace

# список доступных стилей
bin/substitute-letters --list

# справка
bin/substitute-letters --help
```

Опции: `-s/--style STYLE` (по умолчанию `monospace`), `-l/--list`,
`-h/-?/--help`.

## Установка

Из этого репозитория (зависимостей, кроме core-модулей, нет):

```sh
perl Makefile.PL && make && sudo make install
# или просто:
cpanm .
```

После установки `Text::UnicodeStyle` и скрипт `substitute-letters`
доступны системно.

## Использование модуля

```perl
use lib 'lib';
use Text::UnicodeStyle qw( stylize styles );

say stylize('something_id', 'monospace');   # 𝚜𝚘𝚖𝚎𝚝𝚑𝚒𝚗𝚐_𝚒𝚍
say join ', ', styles();
```

`stylize` возвращает новую строку, исходник не изменяет.

## Тесты

```sh
prove -Ilib t/
```

`t/stylize.t` проверяет API и таблицы преобразований, `t/cli.t` —
поведение CLI (включая коды возврата и help).

## Пример

`example.pl` — демо-скрипт, использующий модуль.

## Структура

```
lib/Text/UnicodeStyle.pm    # API модуля
lib/Text/UnicodeStyle/*.pm  # таблицы стилей (lazy load)
bin/substitute-letters      # CLI
t/                          # тесты (Test::More + prove)
example.pl                  # пример
```

## Лицензия

[MIT](LICENSE)

## Автор

Александр Сапожников <shoorick@cpan.org> <http://shoorick.ru>

## Support the project

Если вы считаете этот проект полезным, можете поддержать разработку через [PayPal](https://paypal.me/shoorick77).
