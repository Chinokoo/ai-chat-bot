import 'package:ai_chat_app/pages/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

void main() async {
  try {
    //loading the .env in the dotenv
    await dotenv.load(fileName: ".env");

    //initializing the gemini
    Gemini.init(apiKey: dotenv.get("GEMINI_API_KEY"));
    //running the app
    runApp(const MainApp());
  } catch (e) {
    print('Intialization error: $e');
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}
