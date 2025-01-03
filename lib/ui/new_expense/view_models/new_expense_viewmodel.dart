import 'dart:async';
import 'dart:io';

import 'package:finance_ai/adapters/generative_ai/generative_ai_adapter.dart';
import 'package:finance_ai/domain/expanse/models/expense.dart';
import 'package:finance_ai/domain/expanse/models/expense_amount_details.dart';
import 'package:finance_ai/domain/expanse/usecases/expense_create_use_case.dart';
import 'package:finance_ai/utils/command.dart';
import 'package:finance_ai/utils/result.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';

class NewExpenseViewModel extends ChangeNotifier {
  NewExpenseViewModel({
    required IGenerativeAIAdapter generativeAIService,
    required ExpenseCreateUseCase expenseCreateUseCase,
  })  : _generativeAIService = generativeAIService,
        _expenseCreateUseCase = expenseCreateUseCase {
    getImage = Command1(_getImage);
    processImageToText = Command0(_processImage);
    transformRecognizedTextToJsonByAI =
        Command0(_transformRecognizedTextToJsonByAI);
    createExpense =
        Command1<void, (String title, String category, String wallet)>(
            _createExpense);
  }

  final _log = Logger('NewExpenseViewModel');

  final IGenerativeAIAdapter _generativeAIService;
  final ExpenseCreateUseCase _expenseCreateUseCase;

  late Command1<void, ImageSource> getImage;
  late Command0<void> processImageToText;
  late Command0<void> transformRecognizedTextToJsonByAI;
  late Command1 createExpense;

  File? _image;
  String? _path;
  String? _textImage;
  ExpenseAmountDetails? _expenseAmountDetailsRecognized;

  File? get image => _image;
  ExpenseAmountDetails? get expenseAmountDetailsRecognized =>
      _expenseAmountDetailsRecognized;

  bool get hasCommandLoading =>
      transformRecognizedTextToJsonByAI.running ||
      getImage.running ||
      createExpense.running;

  final _imagePicker = ImagePicker();

  /// Get image from [source].
  ///
  /// After executing this command, the image file is saved in [image] and the
  /// path to the image file is saved in [path].
  Future<Result<void>> _getImage(ImageSource source) async {
    try {
      _log.info('Getting image from source: $source');

      _image = null;
      _path = null;

      final pickedFile = await _imagePicker.pickImage(source: source);

      if (pickedFile != null && pickedFile.path.isNotEmpty) {
        _path = pickedFile.path;
        _image = File(pickedFile.path);

        _log.info('Image loaded from source: $source');
      }

      return const Result.ok(null);
    } catch (e) {
      _log.severe('Error getting image from source: $source. Error: $e');

      return Result.error(
        Exception('Error getting image from source: $source. Error: $e'),
      );
    } finally {
      notifyListeners();
    }
  }

  /// Process the image to text.
  ///
  /// To process the image to recognized text, we use the [TextRecognizer] from google_mlkit_text_recognition.
  /// Image-to-text recognition is a routine that runs on the device's processor. This way, it works offline and
  /// without the need to communicate with external APIs and free of charge.
  ///
  /// If the image is processed successfully, the [_textImage] will be set.
  /// If the path of image is not set, an error will be returned.
  Future<Result<void>> _processImage() async {
    if (_path == null) {
      return Result.error(
        Exception('No path image to process.'),
      );
    }

    _log.info('Processing image to text.');

    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      _textImage = null;

      final inputImage = InputImage.fromFilePath(_path!);

      final recognizedText = await textRecognizer.processImage(inputImage);
      _textImage = recognizedText.text;

      _log.info('Image processed to text.');

      return const Result.ok(null);
    } catch (e) {
      _log.severe('Error to procces image to text. Error: $e');

      return Result.error(
        Exception('Error to procces image to text. Error: $e'),
      );
    } finally {
      textRecognizer.close();
      notifyListeners();
    }
  }

  /// Transform the recognized text to json by AI.
  ///
  /// To transform the recognized text to json by AI, we use the [transformRecognizedTextToJson] from [OpenAIService].
  Future<Result<void>> _transformRecognizedTextToJsonByAI() async {
    if (_textImage == null) {
      _log.warning('No text image to transform.');
      return Result.error(
        Exception('No text image to transform.'),
      );
    }

    _log.info('Transforming recognized text to json by AI.');

    try {
      final result = await _generativeAIService
          .transformTextToEntity<ExpenseAmountDetails>(
        _textImage!,
        ExpenseAmountDetails.jsonTemplate,
        ExpenseAmountDetails.fromJson,
      );

      _expenseAmountDetailsRecognized = result;

      return const Result.ok(null);
    } catch (e) {
      _log.severe(
        'Error transforming recognized text to json by AI. Error: $e',
      );

      return Result.error(
        Exception(
          'Error transforming recognized text to json by AI. Error: $e',
        ),
      );
    } finally {
      notifyListeners();
    }
  }

  Future<Result<void>> _createExpense(
      (String, String, String) credentials) async {
    if (_expenseAmountDetailsRecognized == null) {
      return Result.error(
        Exception('No recognized amount details to create expense.'),
      );
    }

    final (title, category, wallet) = credentials;

    final expense = Expense(
      createdAt: DateTime.now(),
      title: title,
      category: category,
      wallet: wallet,
      amountDetails: _expenseAmountDetailsRecognized!,
    );

    final result = await _expenseCreateUseCase.createFrom(expense);
    switch (result) {
      case Ok<Expense>():
        notifyListeners();
        return const Result.ok(null);
      case Error<Expense>():
        _log.warning('Create Expense error: ${result.error}');
        notifyListeners();
        return Result.error(result.error);
    }
  }

  /// Set the [image] and [path] to null.
  void removeImage() {
    _image = null;
    _path = null;
    notifyListeners();
  }
}
