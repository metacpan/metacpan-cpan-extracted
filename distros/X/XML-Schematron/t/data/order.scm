<?xml version="1.0"?>
<schema>
 <pattern>
    <rule context="/">
        <assert test="order">Root element should be named 'order'</assert>
    </rule>
    <rule context="order">
        <assert test="date_created">Order element must contain a 'date_created' element</assert>
        <assert test="order_authorizations">Order element must contain an 'order_authorizations' element.</assert>        
    </rule>
    <rule context="order_authorizations">
        <assert test="order_authorization">order_authorizations element must contain at least one 'order_authorization' element.</assert>
    </rule>

    <rule context="order_authorization">
        <assert test="tttaddress">Each order_authorization must contain and address element.</assert>
    </rule>
 </pattern>
</schema>