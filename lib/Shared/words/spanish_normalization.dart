import 'package:diacritic/diacritic.dart';

String removeAccentsButKeepEnye(String input) {
  input = input.replaceAll('ñ', '__ENYE__').replaceAll('Ñ', '__ENYE_UP__');
  input = removeDiacritics(input);
  input = input.replaceAll('__ENYE__', 'ñ').replaceAll('__ENYE_UP__', 'Ñ');
  return input.replaceAll('’', "'");
}
