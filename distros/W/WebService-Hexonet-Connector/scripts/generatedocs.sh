#!/bin/bash
rm -rf docs/*.html >/dev/null 2>&1
perldoc -oHTML -ddocs/hexonet.html WebService::Hexonet
perldoc -oHTML -ddocs/connector.html WebService::Hexonet::Connector
perldoc -oHTML -ddocs/apiclient.html WebService::Hexonet::Connector::APIClient
perldoc -oHTML -ddocs/column.html WebService::Hexonet::Connector::Column
perldoc -oHTML -ddocs/record.html WebService::Hexonet::Connector::Record
perldoc -oHTML -ddocs/response.html WebService::Hexonet::Connector::Response
perldoc -oHTML -ddocs/responseparser.html WebService::Hexonet::Connector::ResponseParser
perldoc -oHTML -ddocs/responsetemplate.html WebService::Hexonet::Connector::ResponseTemplate
perldoc -oHTML -ddocs/responsetemplatemanager.html WebService::Hexonet::Connector::ResponseTemplateManager
perldoc -oHTML -ddocs/socketconfig.html WebService::Hexonet::Connector::SocketConfig

