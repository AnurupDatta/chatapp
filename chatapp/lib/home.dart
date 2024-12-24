import 'dart:io';
import 'dart:convert';

import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:image_picker/image_picker.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final Gemini gemini = Gemini.instance;
  List<ChatMessage> messages = [];
  ChatUser currentUser = ChatUser(id: "0", firstName: "Anurup");
  ChatUser geminiuser =
      ChatUser(id: "1", firstName: "Gemini", profileImage: "assets/spidy.jpg");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        centerTitle: true,
        title: Text(
          "BroTalk",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    return DashChat(
        inputOptions: InputOptions(trailing: [
          IconButton(
            onPressed: _sendMediaMessage,
            icon: Icon(Icons.image),
          )
        ]),
        currentUser: currentUser,
        onSend: _sendMessage,
        messages: messages);
  }

  void _sendMessage(ChatMessage chatMessage) {
    setState(() {
      messages = [chatMessage, ...messages];
    });

    try {
      String question = chatMessage.text;

      // Encode images as base64 strings if available
      List<String> base64Images = [];
      if (chatMessage.medias?.isNotEmpty ?? false) {
        base64Images = chatMessage.medias!
            .map((media) => base64Encode(File(media.url).readAsBytesSync()))
            .toList();
      }

      // Combine the question text and images into a single string or structured format
      String prompt = question;
      if (base64Images.isNotEmpty) {
        prompt += "\nImages: ${base64Images.join(", ")}";
      }

      // Send the prompt to the Gemini `promptStream`
      gemini.promptStream(parts: [Part.text(prompt)]).listen(
        (event) {
          ChatMessage? lastMessage =
              messages.isNotEmpty && messages.first.user == geminiuser
                  ? messages.removeAt(0)
                  : null;

          String response = event?.output ?? "";

          if (lastMessage != null) {
            // Append the response to the existing Gemini message.
            lastMessage.text += response;
            setState(() {
              messages = [lastMessage, ...messages];
            });
          } else {
            // Create a new message for the Gemini response.
            ChatMessage message = ChatMessage(
              user: geminiuser,
              createdAt: DateTime.now(),
              text: response,
            );
            setState(() {
              messages = [message, ...messages];
            });
          }
        },
      );
    } catch (e) {
      print("Error in _sendMessage: $e");
    }
  }

  void _sendMediaMessage() async {
    ImagePicker picker = ImagePicker();
    XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      ChatMessage chatMessage = ChatMessage(
          user: currentUser,
          createdAt: DateTime.now(),
          text: "Describe this picture",
          medias: [
            ChatMedia(url: file.path, fileName: "", type: MediaType.image)
          ]);
      _sendMessage(chatMessage);
    }
  }
}
