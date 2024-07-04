{
	wrapper => 'WithStatus',
	resources => {
		'ShowcaseOpenAPI' => {
			path => '/api',
			name => 'Whelk OpenAPI',
			description => 'Testing OpenAPI integration',
		},
		'Requests' => {
			path => '/requests',
			name => 'Requests test',
			description => 'Various request routes',
		},
		'Test' => '/t',
	},

	openapi => {
		path => '/',
		formatter => 'YAML',
		info => {
			title => 'OpenApi/Swagger integration for Whelk',
			description =>
				'An API (Application Programming Interface) is a set of protocols, tools, and definitions that allows different software applications to communicate with each other. APIs define the methods and data formats that applications can use to request and exchange information, enabling seamless integration between diverse systems. By providing a standardized way for applications to interact, APIs simplify the development process, allowing developers to leverage existing functionalities without having to build them from scratch. This can significantly enhance the efficiency and scalability of software projects.

APIs can be designed for various purposes, including web services, operating systems, libraries, and databases. Web APIs, for example, enable web applications to communicate with servers over the internet, often using HTTP/HTTPS protocols. They typically follow REST (Representational State Transfer) or SOAP (Simple Object Access Protocol) architectures, each with its own conventions and best practices. RESTful APIs use standard HTTP methods like GET, POST, PUT, and DELETE, and usually return data in JSON or XML formats. By providing a clear and consistent interface, APIs empower developers to create robust, flexible, and interoperable applications that can easily integrate with other services and platforms.',
			contact => {
				email => 'snail@whelk.com',
			},
			version => '1.0.1',
		}
	},
}

