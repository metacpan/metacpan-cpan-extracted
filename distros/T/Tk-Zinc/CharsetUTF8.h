/*
 * These chars are those found in iso8859-15 and iso8859-1.
 * They are encoded in UTF8 right in this file and sorted
 * by Unicode point, _keep_ them sorted this way, a dichotomic
 * search rely on this to locate the glyphs and infos.
 */
static unsigned char *ZnDefaultCharset =
  " !\"#$%&'()*+,-./"
  "0123456789"
  ":;<=>?@"
  "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  "[\\]^_`"
  "abcdefghijklmnopqrstuvwxyz"
  "{|}~"
  "¡¢£¤¥¦§¨©ª«¬­®¯°±²³´µ¶·¸¹º»¼½¾¿"
  "ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞß"
  "àáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ"
  "ŒœŠšŸŽž―€↗↘";

/*
 * Local Variables:
 * coding: utf-8
 * End:
 *
 */
