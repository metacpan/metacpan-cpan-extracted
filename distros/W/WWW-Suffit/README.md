[//]: # ( README.md Fri 21 Jul 2023 12:24:22 MSK )

# WWW::Suffit

The Suffit core library

This library provides common functionality for all sub projects of the Suffit metasystem

## RU

Выпуск библиотеки WWW::Suffit

Состоялся релиз библиотеки [WWW::Suffit](https://metacpan.org/pod/WWW::Suffit), а также других библитек пространства имён WWW::Suffit::* таких как [WWW::Suffit::Server](https://metacpan.org/pod/WWW::Suffit::Server) и [WWW::Suffit::Client](https://metacpan.org/pod/WWW::Suffit::Client).
Библиотеки семейства WWW::Suffit позволяют:

- создавать легковесные Mojolicious приложения в стиле Suffit;
- создавать клиенты и серверы, работающие по стандарту Suffit API;
- освободиться от множества тяжелых зависимостей, в том числе от CTK

Библиотека [WWW::Suffit](https://metacpan.org/pod/WWW::Suffit) полностью совместима с последней версией [Mojolicious](https://metacpan.org/pod/Mojolicious) 9.35

Стандарт **Suffit API** это условный протокол обмена сообщениями между сервером и клиентом поверх HTTP, который основывется на использовании JSON в качестве языкы сериализации данных и RESTful методологиях самого общения клиента и сервера. Из основных особенностей Suffit API можно отметить минималистичность и полное соответствие спецификации OpenAPI. На дату написания этого поста актуальна OpenAPI спецификации Suffit API версии 1.00

Пример обмена сообщениями между сервером и клиентом по спецификации стандарта **Suffit API**

**Request JSON:**

```json
{
  "base_url": "https://localhost:8695",
  "code": "E0000",
  "datetime": "2023-07-27T16:26:39Z",
  "message": "Ok",
  "remote_addr": "127.0.0.1",
  "requestid": "3a8cbe4f",
  "status": true,
  "time": 1682764944,
  "version": "1.00"
}
```

**Response JSON (Ok):**

```json
{
  "code": "E0000",
  "message": "Ok",
  "status": true
}
```

**Response JSON (Error):**

```json
{
  "code": "E0001",
  "message": "Oops",
  "status": false
}
```

### WWW::Suffit::Const

Модуль определяет константы стандарта Suffit API, помимо этого в этом модуле реализован простой PurePerl механизм получения констант [FHS](https://www.pathname.com/fhs/pub/fhs-2.3.html), наименования констант позаимствованы из документа [Installation Directory Variables](http://www.gnu.org/software/autoconf/manual/html_node/Installation-Directory-Variables.html). Например, константа *SHAREDSTATEDIR* содержит вычисленное значение `/var/lib`

### WWW::Suffit::Util

Модуль содержит несколько простых утилитарных функций, частично позаимствованных из модуля [CTK::Util](https://metacpan.org/pod/CTK::Util). При написании модуля было учтено, что большая часть утилитарных функций уже имеется в таких модулях, как [Mojo::Util](https://metacpan.org/pod/Mojo::Util). Из наиболее критично-важных функций можно отметить следующие: `dformat`, `fbytes`, `fduration`, `human2bytes`, `parse_time_offset`, `parse_expire`. Список функций будет расти со временем, об этом я буду писать на страницах блога отдельными постами

### WWW::Suffit::RefUtil

Этот модуль объеденяет в себе сразу несколько модулей [Data::Util::PurePerl](https://metacpan.org/pod/Data::Util::PurePerl), [Params::Classify](https://metacpan.org/pod/Params::Classify), [Ref::Util](https://metacpan.org/pod/Ref::Util) и [CTK::TFVals](https://metacpan.org/pod/CTK::TFVals) но позаимствовано из них только самое важное и часто используемое. Большая часть приведенных модулей использует XS функции, когда как я поставил перед собой задачу реализовать функции на чистом Perl (PurePerl) жертвуя производительностью в пользу лёгкого портирования. Идеология [Mojolicious](https://metacpan.org/pod/Mojolicious) целиком и полностью мной овладела и аккуратно вписалась в мой новый подход к написанию приложений. Очень надеюсь, что вы его тоже поддержите

### WWW::Suffit::API

Это семейство подмодулей реализовано с целью документирования стандартных запросов и ответов. Модуль WWW::Suffit::API является автономным модулем и представляет собой документацию. В дальнейшем этот модуль будет пополняться новыми подмодулями и их описаниями. На текущий момент это просто "заглушка"

### WWW::Suffit::Client

Еще один автономный модуль, созданный как наследних другого автономного модуля - [WWW::Suffit::UserAgent](https://metacpan.org/pod/WWW::Suffit::UserAgent). [WWW::Suffit::Client](https://metacpan.org/pod/WWW::Suffit::Client) реализует возможность общения с серверами, работающими по стандарту Suffit API. На сегодня реализовано 2 подмодуля - V1 и NoAPI. V1 модуль содержит методы Suffit API версии 1.xx (`authn`, `authz`, `pubkey`); NoAPI модуль содержит методы не являющиеся Suffit API методами, например: `manifest`, `download`, `upload` и `remove`

### WWW::Suffit::Server

Этот автономный модуль реализует серверные хелперы и обработчики, например, ServerInfo. Помимо этого модуль реализует некоторые плагины [Mojolicious](https://metacpan.org/pod/Mojolicious)

### WWW::Suffit::UserAgent

Автономный модуль-враппер [Mojo::UserAgent](https://metacpan.org/pod/Mojo::UserAgent). Этот модуль оформлен в объектном стиле с учётом возможной миграции на другой базовый модуль агента. [WWW::Suffit::UserAgent](https://metacpan.org/pod/WWW::Suffit::UserAgent) реализует методы полуения статуса и ошибок согласно спецификации стандарта Suffit API, помимо этого модуль реализует метод проверки доступности API сервере - `check`
