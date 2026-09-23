import 'package:file_picker/file_picker.dart';
void main() async {
  var x = await FilePicker.pickFile();
  print(x.runtimeType);
}
