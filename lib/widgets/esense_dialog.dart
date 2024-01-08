import 'package:flutter/material.dart';

class ESenseDialog extends StatelessWidget {
  static const String prefix = 'eSense-';
  final TextEditingController _controller = TextEditingController();

  ESenseDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        height: 200,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Connect ESense Earable",
              style: TextStyle(fontSize: 20),
            ),
            Container(
              margin: const EdgeInsets.all(10),
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  labelText: 'Enter your ESense Device Name',
                  prefix: Text(prefix),
                ),
              ),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Close")),
              ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(prefix + _controller.text);
                  },
                  child: const Text("Connect")),
            ]),
          ],
        ),
      ),
    );
  }
}
