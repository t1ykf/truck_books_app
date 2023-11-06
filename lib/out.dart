import 'package:flutter/material.dart';

class Out extends StatefulWidget {
  @override
  _Out createState() => _Out();
}

class _Out extends State<Out> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('完成'),
          centerTitle: true,
          backgroundColor: Colors.lightGreen,
        ),
        body: Center(
            child: Container(
          margin: EdgeInsets.only(top: 50),
          child: Column(
            children: [
              Icon(Icons.check_circle, size: 100, color: Color(0xFF67C23A)),
              Text('完成')
            ],
          ),
        )));
  }
}
