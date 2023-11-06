import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:truck_book/logs.dart';
import 'package:intl/intl.dart';
import 'package:truck_book/config.dart';

class Logs extends StatefulWidget {
  @override
  _Logs createState() => _Logs();
}

class _Logs extends State<Logs> {
  List<dynamic> jsonData = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('全部订单'),
        centerTitle: true,
        backgroundColor: Colors.lightGreen,
      ),
      body: Container(
          padding: EdgeInsets.only(top: 10, bottom: 10),
          child: ListView.separated(
            itemCount: jsonData.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> item = jsonData[index];
              String formattedDate = DateFormat("yyyy-MM-dd").format(
                  DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSZ")
                      .parse(item['createdAt']));
              return ListTile(
                title: Text(item['title'] + '（' + item['target'] + '）'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('垫付：${item['out_money']} 运费： ${item['fare']} '),
                      ],
                    ),
                    Row(
                      children: [Text('描述: ${item['desc']}')],
                    ),
                    Text('${formattedDate}')
                  ],
                ),
                trailing: item['settle']
                    ? Text('已收', style: TextStyle(color: Colors.green))
                    : Text('待收', style: TextStyle(color: Colors.red)),
              );
            },
            separatorBuilder: (context, index) {
              return Divider(
                color: Color(0xFFE6E8EB),
              );
            },
          )),
    );
  }

  void fetchData() async {
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

    // T1后端云分页查询
    var request = http.Request(
      'GET',
      Uri.parse('https://dev.t1y.net/api/v5/classes/' +
          T1YClient().table +
          '?page=1&size=1000'),
    );

    request.headers.addAll(headers);

    try {
      final response = await http.Client().send(request);
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        print(responseBody);
        Map<String, dynamic> jsonMap = json.decode(responseBody);
        setState(() {
          jsonData = jsonMap['data']['data'];
        });
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
