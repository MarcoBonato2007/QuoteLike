import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:email_validator/email_validator.dart';

import 'package:quotelike/utilities/enums.dart';

/// The user uses this class to input the properties of the forms they want to create.
/// 
/// The id doubles as the hint text. 
/// Note that this means no two fields can have the same hint text.
class Field {
  final String id;
  final Icon prefixIcon;
  final bool obscure;
  final String? Function(String? inputtedValue) validator;
  final Widget? counter;
  final List<TextInputFormatter>? inputFormatters;
  final bool expandsVertically;

  const Field(
    this.id,
    this.prefixIcon,
    this.obscure,
    this.validator,
    {
      this.counter,
      this.inputFormatters,
      this.expandsVertically = false
    }
  );
}

/// The standard field for an email (always the same)
class EmailField extends Field {
  EmailField(String hintText) : super(
    hintText,
    Icon(Icons.email),
    false,
    (String? inputtedValue) {
      if (inputtedValue == "" || inputtedValue == null) {
        return "Please enter an email";
      }
      if (!EmailValidator.validate(inputtedValue)) {
        return "Invalid email format";
      }
      else {
        return null;
      }
    },  
  );
}

/// The standardized widget for making an input form
class ValidatedForm extends StatefulWidget {
  final List<Field> fields;
  const ValidatedForm(this.fields, {super.key});

  @override
  State<ValidatedForm> createState() => ValidatedFormState();
}

class ValidatedFormState extends State<ValidatedForm> {
  // All of these map the id of a field to some property about them
  Map<String, TextEditingController> controllers = {};
  Map<String, GlobalKey<FormFieldState>> keys = {};
  Map<String, ErrorCode?> fieldErrors = {};
  Map<String, bool> obscurity = {};

  @override
  void initState() {
    for (Field field in widget.fields) {
      controllers[field.id] = TextEditingController();
      keys[field.id] = GlobalKey<FormFieldState>();
      fieldErrors[field.id] = null;
      obscurity[field.id] = field.obscure;
    }

    super.initState();
  }

  @override
  void dispose() {
    for (TextEditingController controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  } 

  void setError(String fieldId, ErrorCode? newError) => setState(() {
    fieldErrors[fieldId] = newError;
  });

  void setObscurity(String fieldId, bool newObscurity) => setState(() {
    obscurity[fieldId] = newObscurity;
  });

  void removeErrors() => setState(() {
    for (Field field in widget.fields) {
      fieldErrors[field.id] = null;
    }
  });

  /// Retrieve the text within the specified field
  String text(String fieldId) => controllers[fieldId]!.text;

  /// Return whether the input given to the specified field is valid
  /// 
  /// The given field displays a red error message if not
  bool validate(String fieldId) => keys[fieldId]!.currentState!.validate();

  /// Return whether all fields have valid input
  /// 
  /// Fields without valid input show a red error message
  bool validateAll() {
    bool allValid = true;
    for (Field field in widget.fields) {
      bool fieldValid = validate(field.id);
      allValid = allValid && fieldValid;
    }
    return allValid;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [for (Field field in widget.fields) 
        Column(
          children: [
            TextFormField(
              controller: controllers[field.id]!,
              maxLines: field.expandsVertically ? null : 1,
              key: keys[field.id],
              inputFormatters: field.inputFormatters,
              onChanged: (String? inputtedValue) => removeErrors(),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: field.validator,
              obscureText: obscurity[field.id]!,
              decoration: InputDecoration(
                helperText: "",
                errorMaxLines: 3,
                border: OutlineInputBorder(),
                hintText: field.id,
                errorText: fieldErrors[field.id]?.errorText,
                prefixIcon: field.prefixIcon,
                counter: field.counter,
                // if obscure is enabled from the start, show an eye button to (de)obscure the field
                suffixIcon: field.obscure ?
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: IconButton.outlined(
                      color: ColorScheme.of(context).primary,
                      icon: obscurity[field.id]! ? Icon(Icons.visibility_off) : Icon(Icons.visibility),
                      onPressed: () => setState(() => obscurity[field.id] = !obscurity[field.id]!),
                      style: IconButton.styleFrom(
                        side: BorderSide(
                          width: 2.0, 
                          color: ColorScheme.of(context).primary,
                        ), 
                      ),
                    ),
                  )
                : null
              ),
            ),
            // if not last field, add spacing (this spaces the fields in the form apart)
            field.id != widget.fields.last.id ? SizedBox(height: 5) : SizedBox.shrink()
          ]
        ),
      ] 
    );
  }
}
