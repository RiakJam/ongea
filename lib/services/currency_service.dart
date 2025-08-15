import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class CurrencyService {
  final Function(String, String) updateCurrency;
  final NumberFormat numberFormat;
  
  CurrencyService({
    required this.updateCurrency,
    required this.numberFormat,
  });

  Future<void> detectCurrency() async {
    try {
      final response = await http.get(Uri.parse('http://ip-api.com/json'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final countryCode = data['countryCode'] ?? 'US';
        
        final currencyInfo = _getCurrencyInfo(countryCode);
        updateCurrency(currencyInfo['code'] ?? 'USD', currencyInfo['symbol'] ?? '\$');
      }
    } catch (e) {
      print('Error detecting currency: $e');
      updateCurrency('USD', '\$');
    }
  }

  Map<String, String> _getCurrencyInfo(String countryCode) {
    // A comprehensive map of country codes to currency information
    final currencyMap = {
      'AD': {'code': 'EUR', 'symbol': '€'}, // Andorra
      'AE': {'code': 'AED', 'symbol': 'د.إ'}, // United Arab Emirates
      'AF': {'code': 'AFN', 'symbol': '؋'}, // Afghanistan
      'AG': {'code': 'XCD', 'symbol': '\$'}, // Antigua and Barbuda
      'AI': {'code': 'XCD', 'symbol': '\$'}, // Anguilla
      'AL': {'code': 'ALL', 'symbol': 'L'}, // Albania
      'AM': {'code': 'AMD', 'symbol': '֏'}, // Armenia
      'AO': {'code': 'AOA', 'symbol': 'Kz'}, // Angola
      'AR': {'code': 'ARS', 'symbol': '\$'}, // Argentina
      'AS': {'code': 'USD', 'symbol': '\$'}, // American Samoa
      'AT': {'code': 'EUR', 'symbol': '€'}, // Austria
      'AU': {'code': 'AUD', 'symbol': '\$'}, // Australia
      'AW': {'code': 'AWG', 'symbol': 'ƒ'}, // Aruba
      'AX': {'code': 'EUR', 'symbol': '€'}, // Åland Islands
      'AZ': {'code': 'AZN', 'symbol': '₼'}, // Azerbaijan
      'BA': {'code': 'BAM', 'symbol': 'KM'}, // Bosnia and Herzegovina
      'BB': {'code': 'BBD', 'symbol': '\$'}, // Barbados
      'BD': {'code': 'BDT', 'symbol': '৳'}, // Bangladesh
      'BE': {'code': 'EUR', 'symbol': '€'}, // Belgium
      'BF': {'code': 'XOF', 'symbol': 'CFA'}, // Burkina Faso
      'BG': {'code': 'BGN', 'symbol': 'лв'}, // Bulgaria
      'BH': {'code': 'BHD', 'symbol': '.د.ب'}, // Bahrain
      'BI': {'code': 'BIF', 'symbol': 'FBu'}, // Burundi
      'BJ': {'code': 'XOF', 'symbol': 'CFA'}, // Benin
      'BL': {'code': 'EUR', 'symbol': '€'}, // Saint Barthélemy
      'BM': {'code': 'BMD', 'symbol': '\$'}, // Bermuda
      'BN': {'code': 'BND', 'symbol': '\$'}, // Brunei
      'BO': {'code': 'BOB', 'symbol': 'Bs.'}, // Bolivia
      'BQ': {'code': 'USD', 'symbol': '\$'}, // Caribbean Netherlands
      'BR': {'code': 'BRL', 'symbol': 'R\$'}, // Brazil
      'BS': {'code': 'BSD', 'symbol': '\$'}, // Bahamas
      'BT': {'code': 'BTN', 'symbol': 'Nu.'}, // Bhutan
      'BW': {'code': 'BWP', 'symbol': 'P'}, // Botswana
      'BY': {'code': 'BYN', 'symbol': 'Br'}, // Belarus
      'BZ': {'code': 'BZD', 'symbol': 'BZ\$'}, // Belize
      'CA': {'code': 'CAD', 'symbol': '\$'}, // Canada
      'CC': {'code': 'AUD', 'symbol': '\$'}, // Cocos Islands
      'CD': {'code': 'CDF', 'symbol': 'FC'}, // DR Congo
      'CF': {'code': 'XAF', 'symbol': 'FCFA'}, // Central African Republic
      'CG': {'code': 'XAF', 'symbol': 'FCFA'}, // Republic of the Congo
      'CH': {'code': 'CHF', 'symbol': 'CHF'}, // Switzerland
      'CI': {'code': 'XOF', 'symbol': 'CFA'}, // Ivory Coast
      'CK': {'code': 'NZD', 'symbol': '\$'}, // Cook Islands
      'CL': {'code': 'CLP', 'symbol': '\$'}, // Chile
      'CM': {'code': 'XAF', 'symbol': 'FCFA'}, // Cameroon
      'CN': {'code': 'CNY', 'symbol': '¥'}, // China
      'CO': {'code': 'COP', 'symbol': '\$'}, // Colombia
      'CR': {'code': 'CRC', 'symbol': '₡'}, // Costa Rica
      'CU': {'code': 'CUP', 'symbol': '\$'}, // Cuba
      'CV': {'code': 'CVE', 'symbol': '\$'}, // Cape Verde
      'CW': {'code': 'ANG', 'symbol': 'ƒ'}, // Curaçao
      'CX': {'code': 'AUD', 'symbol': '\$'}, // Christmas Island
      'CY': {'code': 'EUR', 'symbol': '€'}, // Cyprus
      'CZ': {'code': 'CZK', 'symbol': 'Kč'}, // Czech Republic
      'DE': {'code': 'EUR', 'symbol': '€'}, // Germany
      'DJ': {'code': 'DJF', 'symbol': 'Fdj'}, // Djibouti
      'DK': {'code': 'DKK', 'symbol': 'kr'}, // Denmark
      'DM': {'code': 'XCD', 'symbol': '\$'}, // Dominica
      'DO': {'code': 'DOP', 'symbol': '\$'}, // Dominican Republic
      'DZ': {'code': 'DZD', 'symbol': 'د.ج'}, // Algeria
      'EC': {'code': 'USD', 'symbol': '\$'}, // Ecuador
      'EE': {'code': 'EUR', 'symbol': '€'}, // Estonia
      'EG': {'code': 'EGP', 'symbol': '£'}, // Egypt
      'ER': {'code': 'ERN', 'symbol': 'Nfk'}, // Eritrea
      'ES': {'code': 'EUR', 'symbol': '€'}, // Spain
      'ET': {'code': 'ETB', 'symbol': 'Br'}, // Ethiopia
      'FI': {'code': 'EUR', 'symbol': '€'}, // Finland
      'FJ': {'code': 'FJD', 'symbol': '\$'}, // Fiji
      'FK': {'code': 'FKP', 'symbol': '£'}, // Falkland Islands
      'FM': {'code': 'USD', 'symbol': '\$'}, // Micronesia
      'FO': {'code': 'DKK', 'symbol': 'kr'}, // Faroe Islands
      'FR': {'code': 'EUR', 'symbol': '€'}, // France
      'GA': {'code': 'XAF', 'symbol': 'FCFA'}, // Gabon
      'GB': {'code': 'GBP', 'symbol': '£'}, // United Kingdom
      'GD': {'code': 'XCD', 'symbol': '\$'}, // Grenada
      'GE': {'code': 'GEL', 'symbol': '₾'}, // Georgia
      'GF': {'code': 'EUR', 'symbol': '€'}, // French Guiana
      'GG': {'code': 'GBP', 'symbol': '£'}, // Guernsey
      'GH': {'code': 'GHS', 'symbol': 'GH₵'}, // Ghana
      'GI': {'code': 'GIP', 'symbol': '£'}, // Gibraltar
      'GL': {'code': 'DKK', 'symbol': 'kr'}, // Greenland
      'GM': {'code': 'GMD', 'symbol': 'D'}, // Gambia
      'GN': {'code': 'GNF', 'symbol': 'FG'}, // Guinea
      'GP': {'code': 'EUR', 'symbol': '€'}, // Guadeloupe
      'GQ': {'code': 'XAF', 'symbol': 'FCFA'}, // Equatorial Guinea
      'GR': {'code': 'EUR', 'symbol': '€'}, // Greece
      'GT': {'code': 'GTQ', 'symbol': 'Q'}, // Guatemala
      'GU': {'code': 'USD', 'symbol': '\$'}, // Guam
      'GW': {'code': 'XOF', 'symbol': 'CFA'}, // Guinea-Bissau
      'GY': {'code': 'GYD', 'symbol': '\$'}, // Guyana
      'HK': {'code': 'HKD', 'symbol': '\$'}, // Hong Kong
      'HN': {'code': 'HNL', 'symbol': 'L'}, // Honduras
      'HR': {'code': 'HRK', 'symbol': 'kn'}, // Croatia
      'HT': {'code': 'HTG', 'symbol': 'G'}, // Haiti
      'HU': {'code': 'HUF', 'symbol': 'Ft'}, // Hungary
      'ID': {'code': 'IDR', 'symbol': 'Rp'}, // Indonesia
      'IE': {'code': 'EUR', 'symbol': '€'}, // Ireland
      'IL': {'code': 'ILS', 'symbol': '₪'}, // Israel
      'IM': {'code': 'GBP', 'symbol': '£'}, // Isle of Man
      'IN': {'code': 'INR', 'symbol': '₹'}, // India
      'IO': {'code': 'USD', 'symbol': '\$'}, // British Indian Ocean Territory
      'IQ': {'code': 'IQD', 'symbol': 'ع.د'}, // Iraq
      'IR': {'code': 'IRR', 'symbol': '﷼'}, // Iran
      'IS': {'code': 'ISK', 'symbol': 'kr'}, // Iceland
      'IT': {'code': 'EUR', 'symbol': '€'}, // Italy
      'JE': {'code': 'GBP', 'symbol': '£'}, // Jersey
      'JM': {'code': 'JMD', 'symbol': '\$'}, // Jamaica
      'JO': {'code': 'JOD', 'symbol': 'د.ا'}, // Jordan
      'JP': {'code': 'JPY', 'symbol': '¥'}, // Japan
      'KE': {'code': 'KES', 'symbol': 'KSh'}, // Kenya
      'KG': {'code': 'KGS', 'symbol': 'сом'}, // Kyrgyzstan
      'KH': {'code': 'KHR', 'symbol': '៛'}, // Cambodia
      'KI': {'code': 'AUD', 'symbol': '\$'}, // Kiribati
      'KM': {'code': 'KMF', 'symbol': 'CF'}, // Comoros
      'KN': {'code': 'XCD', 'symbol': '\$'}, // Saint Kitts and Nevis
      'KP': {'code': 'KPW', 'symbol': '₩'}, // North Korea
      'KR': {'code': 'KRW', 'symbol': '₩'}, // South Korea
      'KW': {'code': 'KWD', 'symbol': 'د.ك'}, // Kuwait
      'KY': {'code': 'KYD', 'symbol': '\$'}, // Cayman Islands
      'KZ': {'code': 'KZT', 'symbol': '₸'}, // Kazakhstan
      'LA': {'code': 'LAK', 'symbol': '₭'}, // Laos
      'LB': {'code': 'LBP', 'symbol': 'ل.ل'}, // Lebanon
      'LC': {'code': 'XCD', 'symbol': '\$'}, // Saint Lucia
      'LI': {'code': 'CHF', 'symbol': 'CHF'}, // Liechtenstein
      'LK': {'code': 'LKR', 'symbol': 'Rs'}, // Sri Lanka
      'LR': {'code': 'LRD', 'symbol': '\$'}, // Liberia
      'LS': {'code': 'LSL', 'symbol': 'L'}, // Lesotho
      'LT': {'code': 'EUR', 'symbol': '€'}, // Lithuania
      'LU': {'code': 'EUR', 'symbol': '€'}, // Luxembourg
      'LV': {'code': 'EUR', 'symbol': '€'}, // Latvia
      'LY': {'code': 'LYD', 'symbol': 'ل.د'}, // Libya
      'MA': {'code': 'MAD', 'symbol': 'د.م.'}, // Morocco
      'MC': {'code': 'EUR', 'symbol': '€'}, // Monaco
      'MD': {'code': 'MDL', 'symbol': 'L'}, // Moldova
      'ME': {'code': 'EUR', 'symbol': '€'}, // Montenegro
      'MF': {'code': 'EUR', 'symbol': '€'}, // Saint Martin
      'MG': {'code': 'MGA', 'symbol': 'Ar'}, // Madagascar
      'MH': {'code': 'USD', 'symbol': '\$'}, // Marshall Islands
      'MK': {'code': 'MKD', 'symbol': 'ден'}, // North Macedonia
      'ML': {'code': 'XOF', 'symbol': 'CFA'}, // Mali
      'MM': {'code': 'MMK', 'symbol': 'K'}, // Myanmar
      'MN': {'code': 'MNT', 'symbol': '₮'}, // Mongolia
      'MO': {'code': 'MOP', 'symbol': 'P'}, // Macau
      'MP': {'code': 'USD', 'symbol': '\$'}, // Northern Mariana Islands
      'MQ': {'code': 'EUR', 'symbol': '€'}, // Martinique
      'MR': {'code': 'MRU', 'symbol': 'UM'}, // Mauritania
      'MS': {'code': 'XCD', 'symbol': '\$'}, // Montserrat
      'MT': {'code': 'EUR', 'symbol': '€'}, // Malta
      'MU': {'code': 'MUR', 'symbol': '₨'}, // Mauritius
      'MV': {'code': 'MVR', 'symbol': 'ރ.'}, // Maldives
      'MW': {'code': 'MWK', 'symbol': 'MK'}, // Malawi
      'MX': {'code': 'MXN', 'symbol': '\$'}, // Mexico
      'MY': {'code': 'MYR', 'symbol': 'RM'}, // Malaysia
      'MZ': {'code': 'MZN', 'symbol': 'MT'}, // Mozambique
      'NA': {'code': 'NAD', 'symbol': '\$'}, // Namibia
      'NC': {'code': 'XPF', 'symbol': '₣'}, // New Caledonia
      'NE': {'code': 'XOF', 'symbol': 'CFA'}, // Niger
      'NF': {'code': 'AUD', 'symbol': '\$'}, // Norfolk Island
      'NG': {'code': 'NGN', 'symbol': '₦'}, // Nigeria
      'NI': {'code': 'NIO', 'symbol': 'C\$'}, // Nicaragua
      'NL': {'code': 'EUR', 'symbol': '€'}, // Netherlands
      'NO': {'code': 'NOK', 'symbol': 'kr'}, // Norway
      'NP': {'code': 'NPR', 'symbol': '₨'}, // Nepal
      'NR': {'code': 'AUD', 'symbol': '\$'}, // Nauru
      'NU': {'code': 'NZD', 'symbol': '\$'}, // Niue
      'NZ': {'code': 'NZD', 'symbol': '\$'}, // New Zealand
      'OM': {'code': 'OMR', 'symbol': 'ر.ع.'}, // Oman
      'PA': {'code': 'PAB', 'symbol': 'B/.'}, // Panama
      'PE': {'code': 'PEN', 'symbol': 'S/.'}, // Peru
      'PF': {'code': 'XPF', 'symbol': '₣'}, // French Polynesia
      'PG': {'code': 'PGK', 'symbol': 'K'}, // Papua New Guinea
      'PH': {'code': 'PHP', 'symbol': '₱'}, // Philippines
      'PK': {'code': 'PKR', 'symbol': '₨'}, // Pakistan
      'PL': {'code': 'PLN', 'symbol': 'zł'}, // Poland
      'PM': {'code': 'EUR', 'symbol': '€'}, // Saint Pierre and Miquelon
      'PN': {'code': 'NZD', 'symbol': '\$'}, // Pitcairn Islands
      'PR': {'code': 'USD', 'symbol': '\$'}, // Puerto Rico
      'PS': {'code': 'ILS', 'symbol': '₪'}, // Palestine
      'PT': {'code': 'EUR', 'symbol': '€'}, // Portugal
      'PW': {'code': 'USD', 'symbol': '\$'}, // Palau
      'PY': {'code': 'PYG', 'symbol': '₲'}, // Paraguay
      'QA': {'code': 'QAR', 'symbol': 'ر.ق'}, // Qatar
      'RE': {'code': 'EUR', 'symbol': '€'}, // Réunion
      'RO': {'code': 'RON', 'symbol': 'lei'}, // Romania
      'RS': {'code': 'RSD', 'symbol': 'дин'}, // Serbia
      'RU': {'code': 'RUB', 'symbol': '₽'}, // Russia
      'RW': {'code': 'RWF', 'symbol': 'FRw'}, // Rwanda
      'SA': {'code': 'SAR', 'symbol': 'ر.س'}, // Saudi Arabia
      'SB': {'code': 'SBD', 'symbol': '\$'}, // Solomon Islands
      'SC': {'code': 'SCR', 'symbol': '₨'}, // Seychelles
      'SD': {'code': 'SDG', 'symbol': 'ج.س.'}, // Sudan
      'SE': {'code': 'SEK', 'symbol': 'kr'}, // Sweden
      'SG': {'code': 'SGD', 'symbol': '\$'}, // Singapore
      'SH': {'code': 'SHP', 'symbol': '£'}, // Saint Helena
      'SI': {'code': 'EUR', 'symbol': '€'}, // Slovenia
      'SJ': {'code': 'NOK', 'symbol': 'kr'}, // Svalbard and Jan Mayen
      'SK': {'code': 'EUR', 'symbol': '€'}, // Slovakia
      'SL': {'code': 'SLL', 'symbol': 'Le'}, // Sierra Leone
      'SM': {'code': 'EUR', 'symbol': '€'}, // San Marino
      'SN': {'code': 'XOF', 'symbol': 'CFA'}, // Senegal
      'SO': {'code': 'SOS', 'symbol': 'Sh'}, // Somalia
      'SR': {'code': 'SRD', 'symbol': '\$'}, // Suriname
      'SS': {'code': 'SSP', 'symbol': '£'}, // South Sudan
      'ST': {'code': 'STN', 'symbol': 'Db'}, // São Tomé and Príncipe
      'SV': {'code': 'USD', 'symbol': '\$'}, // El Salvador
      'SX': {'code': 'ANG', 'symbol': 'ƒ'}, // Sint Maarten
      'SY': {'code': 'SYP', 'symbol': '£'}, // Syria
      'SZ': {'code': 'SZL', 'symbol': 'L'}, // Eswatini
      'TC': {'code': 'USD', 'symbol': '\$'}, // Turks and Caicos Islands
      'TD': {'code': 'XAF', 'symbol': 'FCFA'}, // Chad
      'TG': {'code': 'XOF', 'symbol': 'CFA'}, // Togo
      'TH': {'code': 'THB', 'symbol': '฿'}, // Thailand
      'TJ': {'code': 'TJS', 'symbol': 'ЅМ'}, // Tajikistan
      'TK': {'code': 'NZD', 'symbol': '\$'}, // Tokelau
      'TL': {'code': 'USD', 'symbol': '\$'}, // Timor-Leste
      'TM': {'code': 'TMT', 'symbol': 'm'}, // Turkmenistan
      'TN': {'code': 'TND', 'symbol': 'د.ت'}, // Tunisia
      'TO': {'code': 'TOP', 'symbol': 'T\$'}, // Tonga
      'TR': {'code': 'TRY', 'symbol': '₺'}, // Turkey
      'TT': {'code': 'TTD', 'symbol': 'TT\$'}, // Trinidad and Tobago
      'TV': {'code': 'AUD', 'symbol': '\$'}, // Tuvalu
      'TW': {'code': 'TWD', 'symbol': 'NT\$'}, // Taiwan
      'TZ': {'code': 'TZS', 'symbol': 'TSh'}, // Tanzania
      'UA': {'code': 'UAH', 'symbol': '₴'}, // Ukraine
      'UG': {'code': 'UGX', 'symbol': 'USh'}, // Uganda
      'US': {'code': 'USD', 'symbol': '\$'}, // United States
      'UY': {'code': 'UYU', 'symbol': '\$'}, // Uruguay
      'UZ': {'code': 'UZS', 'symbol': 'so\'m'}, // Uzbekistan
      'VA': {'code': 'EUR', 'symbol': '€'}, // Vatican City
      'VC': {'code': 'XCD', 'symbol': '\$'}, // Saint Vincent and the Grenadines
      'VE': {'code': 'VES', 'symbol': 'Bs.S'}, // Venezuela
      'VG': {'code': 'USD', 'symbol': '\$'}, // British Virgin Islands
      'VI': {'code': 'USD', 'symbol': '\$'}, // U.S. Virgin Islands
      'VN': {'code': 'VND', 'symbol': '₫'}, // Vietnam
      'VU': {'code': 'VUV', 'symbol': 'VT'}, // Vanuatu
      'WF': {'code': 'XPF', 'symbol': '₣'}, // Wallis and Futuna
      'WS': {'code': 'WST', 'symbol': 'T'}, // Samoa
      'YE': {'code': 'YER', 'symbol': '﷼'}, // Yemen
      'YT': {'code': 'EUR', 'symbol': '€'}, // Mayotte
      'ZA': {'code': 'ZAR', 'symbol': 'R'}, // South Africa
      'ZM': {'code': 'ZMW', 'symbol': 'ZK'}, // Zambia
      'ZW': {'code': 'USD', 'symbol': '\$'}, // Zimbabwe
    };

    return currencyMap[countryCode] ?? {'code': 'USD', 'symbol': '\$'};
  }

  Future<double> convertPrice(double originalPrice, String fromCurrency, String toCurrency) async {
    if (fromCurrency == toCurrency) return originalPrice;
    
    try {
      // Use a free currency conversion API (like exchangerate-api.com)
      final response = await http.get(
        Uri.parse('https://api.exchangerate-api.com/v4/latest/$fromCurrency')
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'];
        final rate = rates[toCurrency] ?? 1.0;
        return originalPrice * rate;
      } else {
        // Fallback to hardcoded rates if API fails
        return _convertWithHardcodedRates(originalPrice, fromCurrency, toCurrency);
      }
    } catch (e) {
      print('Error converting currency: $e');
      // Fallback to hardcoded rates if API fails
      return _convertWithHardcodedRates(originalPrice, fromCurrency, toCurrency);
    }
  }

  double _convertWithHardcodedRates(double originalPrice, String fromCurrency, String toCurrency) {
    // Hardcoded rates as fallback (these should be updated periodically)
    final rates = {
      'USD': {
        'EUR': 0.85,
        'GBP': 0.73,
        'JPY': 110.0,
        'CNY': 6.5,
        'INR': 75.0,
        'AUD': 1.35,
        'CAD': 1.25,
      },
      'EUR': {
        'USD': 1.18,
        'GBP': 0.86,
        'JPY': 129.5,
        'CNY': 7.65,
        'INR': 88.2,
      },
      'GBP': {
        'USD': 1.37,
        'EUR': 1.16,
        'JPY': 150.7,
        'CNY': 8.9,
        'INR': 102.7,
      },
      // Add more currencies and rates as needed
    };

    // If we have direct rate
    if (rates.containsKey(fromCurrency)) {
      if (rates[fromCurrency]!.containsKey(toCurrency)) {
        return originalPrice * rates[fromCurrency]![toCurrency]!;
      }
    }
    
    // If we can convert via USD
    if (rates.containsKey(fromCurrency) && rates[fromCurrency]!.containsKey('USD') && 
        rates.containsKey('USD') && rates['USD']!.containsKey(toCurrency)) {
      final usdAmount = originalPrice * rates[fromCurrency]!['USD']!;
      return usdAmount * rates['USD']![toCurrency]!;
    }

    // Default to no conversion if we don't have rates
    return originalPrice;
  }
}