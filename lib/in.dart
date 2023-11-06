import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:truck_book/logs.dart';
import 'package:intl/intl.dart';
import 'package:truck_book/out.dart';
import 'package:truck_book/config.dart';

class In extends StatefulWidget {
  @override
  _In createState() => _In();
}

class _In extends State<In> {
  var data = TextEditingController();
  @override
  void initState() {
    super.initState();
    data.text =
        '{"desc":"无","fare":150,"out_money":400,"settle":false,"target":"主车","title":"标题"}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('收入记账'),
          centerTitle: true,
          backgroundColor: Colors.lightGreen,
        ),
        body: Container(
            margin: EdgeInsets.all(10),
            child: Column(
              children: [
                TextField(
                  controller: data,
                  maxLines: 10,
                  decoration: InputDecoration(hintText: '标题'),
                ),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          pushLog();
                        },
                        child: Text('确定'),
                        style: ButtonStyle(
                            backgroundColor:
                                MaterialStatePropertyAll(Color(0xFF67C23A))),
                      ),
                    )
                  ],
                )
              ],
            )));
  }

  void pushLog() async {
    var timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    var headers = {
      'X-T1Y-Application-ID': T1YClient().appId.toString(),
      'X-T1Y-Api-Key': T1YClient().apiKey,
      'X-T1Y-Safe-NonceStr': generateMd5(timestamp.toString()),
      'X-T1Y-Safe-Timestamp': timestamp.toString(),
      'X-T1Y-Safe-Sign': generateMd5('/v5/classes/' +
          T1YClient().table +
          T1YClient().appId.toString() +
          T1YClient().apiKey +
          generateMd5(timestamp.toString()) +
          timestamp.toString() +
          T1YClient().secretKey),
      'Content-Type': 'application/json'
    };

    var request = http.Request(
      'POST',
      Uri.parse('https://dev.t1y.net/api/v5/classes/' + T1YClient().table),
    );

    request.body = data.text;

    request.headers.addAll(headers);

    try {
      final response = await http.Client().send(request);
      final responseBody = await response.stream.bytesToString();
      print(responseBody);
      if (response.statusCode == 200) {
        print(responseBody);
        Navigator.push(context, MaterialPageRoute(builder: (_) => Out()));
      } else {
        print(response.reasonPhrase);
      }
    } catch (error) {
      print("Error: $error");
    }
  }

  String generateMd5(String input) {
    var content = Utf8Encoder().convert(input);
    var digest = md5.convert(content);
    return digest.toString();
  }
}
