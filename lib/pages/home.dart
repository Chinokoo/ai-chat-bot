import 'dart:io';
import 'dart:typed_data';

import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:image_picker/image_picker.dart';
import 'package:internet_connectivity_checker/internet_connectivity_checker.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //create a gemini instance to interact with the chatbot
  final Gemini gemini = Gemini.instance;
  //bool for checking if the chatbot is typing
  bool isGeminiTyping = false;

  //users to display in the dash chat
  ChatUser currentUser = ChatUser(id: "0", firstName: "User");
  ChatUser geminiUser = ChatUser(
      id: "1",
      firstName: "Bot",
      profileImage:
          "https://i.pinimg.com/474x/1e/b0/5f/1eb05f325ec50a15c8b045f3428d6d5e.jpg");

  //messages to display in the dash chat
  List<ChatMessage> messages = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        centerTitle: true,
        title: const Text(
          "Chat Bot",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: ConnectivityBuilder(
          interval: const Duration(seconds: 5),
          builder: (ConnectivityStatus status) {
            if (status == ConnectivityStatus.online) {
              return _chatUI();
            } else if (status == ConnectivityStatus.offline) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.wifi_off,
                      color: Colors.green,
                      size: 80,
                    ),
                    Text(
                      "Offline",
                      style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 20),
                    )
                  ],
                ),
              );
            } else {
              //connectivity status is checking
              return const Center(
                child: SizedBox(
                  width: 25,
                  height: 25,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.green,
                  ),
                ),
              );
            }
          }),
    );
  }

  Widget _chatUI() {
    return Stack(
      children: <Widget>[
        DashChat(
          currentUser: currentUser,
          onSend: sendTextMessage,
          messages: messages,
          messageOptions: const MessageOptions(
              containerColor: Colors.lightGreen,
              textColor: Colors.white,
              timeTextColor: Colors.green,
              currentUserTimeTextColor: Colors.green,
              currentUserContainerColor: Colors.green),
          inputOptions: InputOptions(
              inputTextStyle: const TextStyle(color: Colors.green),
              sendOnEnter: true,
              trailing: [
                IconButton(
                    onPressed: sendMediaMessage,
                    icon: const Icon(
                      Icons.image,
                      color: Colors.green,
                    ))
              ],
              sendButtonBuilder: (onSend) => IconButton(
                    onPressed: onSend,
                    icon: const Icon(
                      Icons.send,
                      color: Colors.green,
                    ),
                  ),
              inputDecoration: InputDecoration(
                  focusColor: Colors.green,
                  hintText: "Ask me anything . . .",
                  hintStyle: const TextStyle(color: Colors.lightGreen),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide:
                        const BorderSide(color: Colors.lightGreen, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                  ))),
        ),
        if (isGeminiTyping)
          Positioned(
            bottom: 70,
            left: 0,
            right: 0,
            child: _typingIndicator(),
          ),
      ],
    );
  }

  //function to send a message
  void sendTextMessage(ChatMessage chatMessage) async {
    isGeminiTyping = true;
    setState(() {
      messages = [chatMessage, ...messages];
    });
    try {
      //code to send message to the chatbot
      String question = chatMessage.text;

      //List to store image data as bytes
      List<Uint8List>? images;

      //Check if the chat message contains any media attachments
      if (chatMessage.medias?.isNotEmpty ?? false) {
        //If media exists, read the first image file and convert to bytes
        images = [
          File(chatMessage.medias!.first.url).readAsBytesSync(),
        ];
      }

      //gemini generating response
      gemini.streamGenerateContent(question, images: images).listen((event) {
        ChatMessage? lastMessage = messages.firstOrNull;
        if (lastMessage != null && lastMessage.user == geminiUser) {
          lastMessage = messages.removeAt(0);
          String response = event.content?.parts?.fold(
                  "", (previous, current) => "$previous ${current.text}") ??
              "";
          lastMessage.text += response;
          setState(() {
            messages = [lastMessage!, ...messages];
            isGeminiTyping = false;
          });
        } else {
          String response = event.content?.parts?.fold(
                  "", (previous, current) => "$previous ${current.text}") ??
              "";
          ChatMessage message = ChatMessage(
              user: geminiUser, createdAt: DateTime.now(), text: response);
          setState(() {
            messages = [message, ...messages];
            isGeminiTyping = false;
          });
        }
      });
    } catch (e) {
      print('failed to send message: $e');
    }
  }

  //sending media message
  void sendMediaMessage() async {
    ImagePicker picker = ImagePicker();
    XFile? file = await picker.pickImage(source: ImageSource.gallery);

    if (file != null) {
      ChatMessage chatMessage = ChatMessage(
          user: currentUser,
          createdAt: DateTime.now(),
          text: "Describe this Image?",
          medias: [
            ChatMedia(url: file.path, fileName: "", type: MediaType.image)
          ]);
      sendTextMessage(chatMessage);
    }
  }

  //custom widget to show a loading circular bar is message from gemini is loading
  Widget _typingIndicator() {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(right: 365, top: 80, left: 10),
      decoration: BoxDecoration(
        color: Colors.lightGreen,
        borderRadius: BorderRadius.circular(5),
      ),
      child: const SizedBox(
        //width: 5,
        height: 10,
        child: CircularProgressIndicator(
          strokeWidth: 1,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }
}
