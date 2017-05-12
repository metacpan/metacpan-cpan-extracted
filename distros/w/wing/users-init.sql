--
-- Initialise user tables.
-- Must be run as root (not the PostgreSQL superuser).
--

drop index users_username_ix;
drop index users_uid_ix;
drop table users;

create table users (
	username	char8		not null,
	uid		int		not null,
	gid		int		not null,
	sender		text		-- canonical sender email address
);
create unique index users_username_ix on users (username);
create unique index users_uid_ix on users (uid);

--
-- Once we do a grant, PostgreSQL removes the implicit right that
-- the table creator has on the table. Blech. We have to explicitly
-- grant ourselves access rights.
--
grant all on users, users_username_ix, users_uid_ix to root;
grant select on users, users_username_ix, users_uid_ix to public;

drop index groups_name_ix;
drop index groups_gid_ix;
drop table groups;

create table groups (
	name		char8		not null,
	gid		int		not null
);
create unique index groups_name_ix on groups (name);
create unique index groups_gid_ix on groups (gid);

grant all on groups, groups_name_ix, groups_gid_ix to root;
grant select on groups, groups_name_ix, groups_gid_ix to public;
