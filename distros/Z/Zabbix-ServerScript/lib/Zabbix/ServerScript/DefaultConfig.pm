$Zabbix::ServerScript::Config = {
	telegram => {
		key => undef,
	},
	api => {
		url => undef,
		timeout => 10,
		rw => {
			password => undef,
			login => undef,
		 },
	},
	graphs => {
		colors => [
				q(00C800),
				q(C80000),
				q(0000C8),
				q(C800C8),
				q(00C8C8),
				q(C8C800),
				q(C8C8C8),
				q(009600),
				q(960000),
				q(000096),
				q(960096),
				q(009696),
				q(969600),
				q(969696),
				q(00FF00),
				q(FF0000),
				q(0000FF),
				q(FF00FF),
				q(00FFFF),
				q(FFFF00),
				q(FFFFFF)
			],
	},
	pid_dir => q(/tmp),
	#log => q(/etc/log4perl.conf), #possible to use path to log4perl file
	log => \q(
		log4perl.logger.Zabbix.ServerScript = WARN, Logfile
		log4perl.logger.Zabbix.ServerScript.console = WARN, STDERR
		log4perl.logger.Zabbix.ServerScript.nolog = OFF
		log4perl.additivity.Zabbix.ServerScript = 0
		log4perl.additivity.Zabbix.ServerScript.nolog = 0

		# Appenders

		# Logfile
		log4perl.appender.Logfile = Log::Log4perl::Appender::File
		log4perl.appender.Logfile.filename = sub { $ENV{LOG_FILENAME}; }
		log4perl.appender.Logfile.mode = append
		log4perl.appender.Logfile.syswrite = 1
		log4perl.appender.Logfile.layout = Log::Log4perl::Layout::PatternLayout::Multiline
		log4perl.appender.Logfile.layout.ConversionPattern = %d{yyyy-MM-dd HH:mm:ss} %P %p> %m%n

		# STDERR
		log4perl.appender.STDERR = Log::Log4perl::Appender::Screen
		log4perl.appender.STDERR.stderr = 1
		log4perl.appender.STDERR.layout = Log::Log4perl::Layout::PatternLayout::Multiline
		log4perl.appender.STDERR.layout.ConversionPattern = %d{yyyy-MM-dd HH:mm:ss} %P %p> %m%n
	),
	log_dir => q(/tmp),
	cache_dir => q(/var/tmp),
	#config_dir => q(/etc/zabbix),
	config_dir => q(/usr/local/etc),
	http_proxy => {
		password => undef,
		timeout => undef,
		user => undef,
		port => undef,
		host => undef,
	},
	trapper => {
		host => q(localhost),
		port => q(10051),
	},
};
