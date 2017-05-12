/*
 * These chars are those found in iso8859-15.
 * They are encoded in iso8859-15 right in this file and sorted
 * by ascending value, _keep_ them sorted this way, a dichotomic
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
  "ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏĞÑÒÓÔÕÖ×ØÙÚÛÜİŞß"
  "àáâãäåæçèéêëìíîïğñòóôõö÷øùúûüışÿ"
  "¾";
