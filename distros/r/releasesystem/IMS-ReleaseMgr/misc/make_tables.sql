rem
rem  Create the tables for the Oracle side of the release manager
rem

drop table mirror_pool_host_list;

create table mirror_pool_host_list
(
        mirror_pool             varchar2(50) not null,
        physical_host           varchar2(50) not null,
        host_name               varchar2(50) not null,
        server_port             number,
        unique (host_name)
);

drop table mirror_specification;

create table mirror_specification
(
        mirror_name             varchar2(50) primary key not null,
        description             varchar2(256),
        server_root             varchar2(256),
        document_root           varchar2(256),
        cgi_root                varchar2(256),
        fcgi_root               varchar2(256),
        scripts_root            varchar2(256),
        start_scripts_root      varchar2(256),
        staging_dir             varchar2(256),
        incoming_dir            varchar2(256),
        logging_dir             varchar2(256),
        pkg_logging_dir         varchar2(256),
        owner_uid               varchar2(12),
        group_gid               varchar2(12),
        signature_type          varchar2(8),
        webmaster               varchar2(50),
        scan_period_secs        number,
        max_child_procs         number,
        weblist_file            varchar2(24),
        no_translate_cgi        number,
        http_auth_user          varchar2(12),
        http_auth_passwd        varchar2(12),
        upload_url              varchar2(40),
        upload_realm            varchar2(40),
        ftp_host                varchar2(50),
        ftp_user                varchar2(12),
        ftp_passwd              varchar2(12),
        ftp_dir                 varchar2(256),
        compression             number,
        stage_1_tool            varchar2(24),
        stage_2_tool            varchar2(24),
        stage_3_tool            varchar2(24)
);

exit
