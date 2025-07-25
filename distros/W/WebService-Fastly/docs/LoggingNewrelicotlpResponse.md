# WebService::Fastly::Object::LoggingNewrelicotlpResponse

## Load the model package
```perl
use WebService::Fastly::Object::LoggingNewrelicotlpResponse;
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**name** | **string** | The name for the real-time logging configuration. | [optional] 
**placement** | **string** | Where in the generated VCL the logging call should be placed. If not set, endpoints with `format_version` of 2 are placed in `vcl_log` and those with `format_version` of 1 are placed in `vcl_deliver`.  | [optional] 
**response_condition** | **string** | The name of an existing condition in the configured endpoint, or leave blank to always execute. | [optional] 
**format** | **string** | A Fastly [log format string](https://www.fastly.com/documentation/guides/integrations/streaming-logs/custom-log-formats/). | [optional] [default to &#39;{&quot;timestamp&quot;:&quot;%{begin:%Y-%m-%dT%H:%M:%S}t&quot;,&quot;time_elapsed&quot;:&quot;%{time.elapsed.usec}V&quot;,&quot;is_tls&quot;:&quot;%{if(req.is_ssl, \&quot;true\&quot;, \&quot;false\&quot;)}V&quot;,&quot;client_ip&quot;:&quot;%{req.http.Fastly-Client-IP}V&quot;,&quot;geo_city&quot;:&quot;%{client.geo.city}V&quot;,&quot;geo_country_code&quot;:&quot;%{client.geo.country_code}V&quot;,&quot;request&quot;:&quot;%{req.request}V&quot;,&quot;host&quot;:&quot;%{req.http.Fastly-Orig-Host}V&quot;,&quot;url&quot;:&quot;%{json.escape(req.url)}V&quot;,&quot;request_referer&quot;:&quot;%{json.escape(req.http.Referer)}V&quot;,&quot;request_user_agent&quot;:&quot;%{json.escape(req.http.User-Agent)}V&quot;,&quot;request_accept_language&quot;:&quot;%{json.escape(req.http.Accept-Language)}V&quot;,&quot;request_accept_charset&quot;:&quot;%{json.escape(req.http.Accept-Charset)}V&quot;,&quot;cache_status&quot;:&quot;%{regsub(fastly_info.state, \&quot;^(HIT-(SYNTH)|(HITPASS|HIT|MISS|PASS|ERROR|PIPE)).*\&quot;, \&quot;\\2\\3\&quot;) }V&quot;}&#39;]
**log_processing_region** | **string** | The geographic region where the logs will be processed before streaming. Valid values are `us`, `eu`, and `none` for global. | [optional] [default to &#39;none&#39;]
**format_version** | **string** | The version of the custom logging format used for the configured endpoint. The logging call gets placed by default in `vcl_log` if `format_version` is set to `2` and in `vcl_deliver` if `format_version` is set to `1`.  | [optional] [default to &#39;2&#39;]
**token** | **string** | The Insert API key from the Account page of your New Relic account. Required. | [optional] 
**region** | **string** | The region to which to stream logs. | [optional] [default to &#39;US&#39;]
**url** | **string** | (Optional) URL of the New Relic Trace Observer, if you are using New Relic Infinite Tracing. | [optional] [default to &#39;null&#39;]
**created_at** | **DateTime** | Date and time in ISO 8601 format. | [optional] [readonly] 
**deleted_at** | **DateTime** | Date and time in ISO 8601 format. | [optional] [readonly] 
**updated_at** | **DateTime** | Date and time in ISO 8601 format. | [optional] [readonly] 
**service_id** | **string** |  | [optional] [readonly] 
**version** | **string** |  | [optional] [readonly] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


