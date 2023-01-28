import 'package:flutter/material.dart';
import 'package:flash_chat_flutter_master/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends StatefulWidget {
  static String id = "chat";
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _auth = FirebaseAuth.instance;
  late User loggedInUser;
  late String text;
  final _firestore = FirebaseFirestore.instance;
  final controller = TextEditingController();
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCurrentUser();
    dataStream();
  }

  void getCurrentUser() async {
    final user = await _auth.currentUser;
    if (user != null) {
      loggedInUser = user;
      print(loggedInUser.email);
    }
  }

  // void getData() async {
  //   final data = await _firestore.collection('messages').get();
  //   for (var message in data.docs) {
  //     print(message.data());
  //   }
  // }
  void dataStream() async {
    // _firestore.collection('messages').orderBy(FieldValue.serverTimestamp());
    await for (var snapshot in _firestore.collection('messages').snapshots()) {
      for (var message in snapshot.docs) {
        print(message.data());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                //Implement logout functionality
                _auth.signOut();
                Navigator.pop(context);
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Container(
          color: Colors.white,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('messages')
                    .orderBy('time')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(
                        backgroundColor: Colors.lightBlueAccent,
                      ),
                    );
                  }
                  final messages = snapshot.data?.docs.reversed;
                  List<bubble> widgets = [];
                  for (var m in messages!) {
                    final text = m.get('text');
                    final sender = m.get('sender');
                    final currentUser = loggedInUser.email;
                    final widget = bubble(
                      sender: sender,
                      text: text,
                      isMe: currentUser == sender,
                    );

                    widgets.add(widget);
                  }
                  return Expanded(
                    child: ListView(
                      reverse: true,
                      padding: EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 10,
                      ),
                      children: widgets,
                    ),
                  );
                },
              ),
              Container(
                decoration: kMessageContainerDecoration,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: controller,
                        onChanged: (value) {
                          //Do something with the user input.
                          text = value;
                        },
                        style: TextStyle(
                          color: Colors.black,
                        ),
                        decoration: kMessageTextFieldDecoration,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        //Implement send functionality.
                        controller.clear();
                        _firestore.collection('messages').add({
                          'text': text,
                          'sender': loggedInUser.email,
                          'time': FieldValue.serverTimestamp(),
                        });
                      },
                      child: Text(
                        'Send',
                        style: kSendButtonTextStyle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class bubble extends StatelessWidget {
  bubble({this.sender, this.text, required this.isMe});
  late final text;
  late final sender;
  late final bool isMe;

  Color backColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    if (isMe) {
      backColor = Colors.lightBlueAccent;
    }
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            '$sender',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          Material(
            elevation: 5,
            color: backColor,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(isMe ? 0 : 30),
              topLeft: Radius.circular(isMe ? 30 : 0),
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 10.0,
                horizontal: 20,
              ),
              child: Text(
                '$text',
                style: TextStyle(
                  fontSize: 20,
                  color: isMe ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
