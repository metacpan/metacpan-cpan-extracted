--
-- Initialise WING tables.
-- Must be run as the httpd user.
--

drop index sessions_id_ix;
drop index sessions_username_ix;
drop table sessions;

create table sessions (
    id		char(24),       -- session id
    start	timestamp,      -- when session was started
    username	char8,          -- username
    host	varchar(15),    -- dotted-quad IP address of peer
    server	varchar(64),    -- hostname of server for this session
    pid		int             -- PID of session daemon on server
);
create unique index sessions_id_ix on sessions (id);
create unique index sessions_username_ix on sessions (username);

grant all on sessions, sessions_id_ix, sessions_username_ix to httpd;
grant rule on sessions to root;

drop sequence abook_ids_seq;
create sequence abook_ids_seq;

drop index abook_ids_idx;
drop table abook_ids;
create table abook_ids (
	id	int     default nextval('abook_ids_seq') not null,
	owner	int,
	tag	text
);
create unique index abook_ids_idx on abook_ids (owner, tag);

drop index abook_perms_idx;
drop table abook_perms;
create table abook_perms (
	id	int	not null,
	permit	int     not null
);
create unique index abook_perms_idx on abook_perms (id, permit);

drop index abook_aliases_idx;
drop table abook_aliases;
create table abook_aliases (
	id	int	not null,
	alias	text,
	comment	text,
	address	text
);
create unique index abook_aliases_idx on abook_aliases (id, alias);

drop index options_ix;
drop table options;

create table options (
	username	char8	not null,
	signature	text,	-- mail sig to append
	abooklist	text,	-- default address book search list
	composeheaders	text,	-- default headers for compose screen
	listsize	int,	-- default lines per screen for list
	copyoutgoing	bool	-- copy outgoing mail to sent-mail mailbox
);
create unique index options_ix on options (username);

grant all on options, options_ix to httpd;
grant select on options, options_ix to public;
grant all on options, options_ix to root;
