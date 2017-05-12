package gma.util;

/**
 * <p>Title: </p>
 * <p>Description: StringUtil is a utility class for string manipulation.</p>
 * <p>Copyright: Copyright (c) 2004 I. Dan Melamed</p>
 * <p>Company: Department of Computer Science, New York University</p>
 * @author Luke Shen
 */

public class StringUtil {

  /**
   * Normalizes string.
   * @param source                    source string for normalization
   * @return                          normalized string
   */
  public static String norm(String source) {
    String destination = "";
    for (int index = 0; index < source.length(); index++) {
      char c = source.charAt(index);
      switch (c) {
        case 'À': destination += 'A'; break;
        case 'Á': destination += 'A'; break;
        case 'Â': destination += 'A'; break;
        case 'Ã': destination += 'A'; break;
        case 'Ä': destination += 'A'; break;
        case 'Å': destination += 'A'; break;
        case 'Ç': destination += 'C'; break;
        case 'È': destination += 'E'; break;
        case 'É': destination += 'E'; break;
        case 'Ê': destination += 'E'; break;
        case 'Ë': destination += 'E'; break;
        case 'Î': destination += 'I'; break;
        case 'Í': destination += 'I'; break;
        case 'Ì': destination += 'I'; break;
        case 'Ï': destination += 'I'; break;
        case 'Ñ': destination += 'N'; break;
        case 'Ô': destination += 'O'; break;
        case 'Ò': destination += 'O'; break;
        case 'Ó': destination += 'O'; break;
        case 'Õ': destination += 'O'; break;
        case 'Ö': destination += 'O'; break;
        case 'Ø': destination += 'O'; break;
        case 'Û': destination += 'U'; break;
        case 'Ú': destination += 'U'; break;
        case 'Ù': destination += 'U'; break;
        case 'Ü': destination += 'U'; break;
        case 'à': destination += 'a'; break;
        case 'â': destination += 'a'; break;
        case 'ä': destination += 'a'; break;
        case 'á': destination += 'a'; break;
        case 'å': destination += 'a'; break;
        case 'æ': destination += "ae"; break;
        case 'ç': destination += 'c'; break;
        case 'è': destination += 'e'; break;
        case 'é': destination += 'e'; break;
        case 'ê': destination += 'e'; break;
        case 'ë': destination += 'e'; break;
        case 'î': destination += 'i'; break;
        case 'í': destination += 'i'; break;
        case 'ì': destination += 'i'; break;
        case 'ï': destination += 'i'; break;
        case 'ñ': destination += 'n'; break;
        case 'ô': destination += 'o'; break;
        case 'ó': destination += 'o'; break;
        case 'ò': destination += 'o'; break;
        case 'ö': destination += 'o'; break;
        case 'ø': destination += 'o'; break;
        case 'ß': destination += "ss"; break;
        case 'ù': destination += 'u'; break;
        case 'ú': destination += 'u'; break;
        case 'û': destination += 'u'; break;
        case 'ü': destination += 'u'; break;
        case 'ÿ': destination += 'y'; break;
        default: destination += c; break;
      }
    }
    return destination;
  }
}
