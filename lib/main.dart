import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:truck_book/in.dart';
import 'package:truck_book/logs.dart';
import 'package:truck_book/out.dart';
import 'package:truck_book/config.dart';

main() {
  runApp(MaterialApp(
    theme: ThemeData.light(), // 黑暗模式
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  var money = 0;
  var settle = 0;
  var str = '累计盈亏';
  @override
  void initState() {
    super.initState();
    getMoney();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Truck Books',
          ),
          centerTitle: true,
          backgroundColor: Colors.lightGreen,
        ),
        body: Column(
          children: [
            Center(
              child: Image.asset(
                'images/home.png',
                width: 250,
                height: 250,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '¥ ',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF67C23A)),
                ),
                Text(
                  money.toString(),
                  style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF67C23A)),
                ),
              ],
            ),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    str,
                  ),
                  Text(
                    '（' + settle.toString() + '笔待收）',
                    style: TextStyle(color: Color(0xFFF56C6C)),
                  )
                ],
              ),
            ),
            Center(
              child: Container(
                margin: EdgeInsets.only(top: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context, MaterialPageRoute(builder: (_) => Logs()));
                      },
                      child: Text(
                        '查看全部 >>',
                        style: TextStyle(color: Color(0xFF67C23A)),
                      ),
                    )
                  ],
                ),
              ),
            ),
            Center(
              child: Container(
                width: 250,
                height: 45,
                margin: EdgeInsets.only(top: 50),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                        context, MaterialPageRoute(builder: (_) => In()));
                  },
                  child: Text('收入'),
                  style: ButtonStyle(
                      backgroundColor:
                          MaterialStatePropertyAll(Color(0xFF67C23A))),
                ),
              ),
            ),
            Center(
              child: Container(
                width: 250,
                height: 45,
                margin: EdgeInsets.only(top: 20),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                        context, MaterialPageRoute(builder: (_) => Out()));
                  },
                  child: Text('支出'),
                  style: ButtonStyle(
                      backgroundColor:
                          MaterialStatePropertyAll(Color(0xFFF56C6C))),
                ),
              ),
            )
          ],
        ));
  }

  void getMoney() async {
    var timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    var headers = {
      'X-T1Y-Application-ID': T1YClient().appId.toString(),
      'X-T1Y-Api-Key': T1YClient().apiKey,
      'X-T1Y-Safe-NonceStr': generateMd5(timestamp.toString()),
      'X-T1Y-Safe-Timestamp': timestamp.toString(),
      'X-T1Y-Safe-Sign': generateMd5('/v5/classes/' +
          T1YClient().table +
          '/aggregate' +
          T1YClient().appId.toString() +
          T1YClient().apiKey +
          generateMd5(timestamp.toString()) +
          timestamp.toString() +
          T1YClient().secretKey),
      'Content-Type': 'application/json'
    };

    var request = http.Request(
      'POST',
      Uri.parse('https://dev.t1y.net/api/v5/classes/' +
          T1YClient().table +
          '/aggregate'),
    );

    // 构造T1后端云聚合查询结构体
    request.body = json.encode([
      {
        "\$group": {
          "_id": "\$settle",
          "totalFare": {"\$sum": "\$fare"},
          "totalOutMoney": {"\$sum": "\$out_money"},
          "count": {"\$sum": 1}
        }
      },
      {
        "\$project": {
          "type": "\$_id",
          "totalAmount": {
            "\$add": ["\$totalFare", "\$totalOutMoney"]
          },
          "totalFare": 1,
          "totalOutMoney": 1,
          "count": 1,
          "_id": 0
        }
      }
    ]);

    request.headers.addAll(headers);

    try {
      final response = await http.Client().send(request);
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        print(responseBody);
        Map<String, dynamic> jsonMap = json.decode(responseBody);
        setState(() {
          money = jsonMap['data']['data'][1]['totalAmount'] -
              jsonMap['data']['data'][0]['totalAmount']; // 总收入减去总支出得到净利润
          settle = jsonMap['data']['data'][0]['count']; // 支出笔数统计
        });
      } else {
        // 聚合查询失败（code不等于200）
        print(response.reasonPhrase);
      }
    } catch (error) {
      // 网络错误等原因
      print("Error: $error");
    }
  }

  String generateMd5(String input) {
    var content = Utf8Encoder().convert(input);
    var digest = md5.convert(content);
    return digest.toString();
  }
}
