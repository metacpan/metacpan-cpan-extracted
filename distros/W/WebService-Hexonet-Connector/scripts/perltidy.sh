#!/bin/bash
perltidy -pro=.perltidyrc Makefile.PL
perltidy -pro=.perltidyrc lib/WebService/Hexonet.pm
perltidy -pro=.perltidyrc lib/WebService/Hexonet/Connector.pm
perltidy -pro=.perltidyrc lib/WebService/Hexonet/Connector/APIClient.pm
perltidy -pro=.perltidyrc lib/WebService/Hexonet/Connector/Column.pm
perltidy -pro=.perltidyrc lib/WebService/Hexonet/Connector/Logger.pm
perltidy -pro=.perltidyrc lib/WebService/Hexonet/Connector/Record.pm
perltidy -pro=.perltidyrc lib/WebService/Hexonet/Connector/Response.pm
perltidy -pro=.perltidyrc lib/WebService/Hexonet/Connector/ResponseParser.pm
perltidy -pro=.perltidyrc lib/WebService/Hexonet/Connector/ResponseTemplate.pm
perltidy -pro=.perltidyrc lib/WebService/Hexonet/Connector/ResponseTemplateManager.pm
perltidy -pro=.perltidyrc lib/WebService/Hexonet/Connector/SocketConfig.pm
perltidy -pro=.perltidyrc t/Hexonet-connector.t