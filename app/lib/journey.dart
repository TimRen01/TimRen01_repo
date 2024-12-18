import 'package:flutter/material.dart';
import 'package:memolanes/src/rust/api/api.dart';
import 'package:memolanes/src/rust/api/utils.dart';
import 'package:memolanes/src/rust/journey_header.dart';
import 'package:memolanes/journey_info.dart';

class JourneyUiBody extends StatefulWidget {
  const JourneyUiBody({super.key});

  @override
  State<JourneyUiBody> createState() => _JourneyUiBodyState();
}

class _JourneyUiBodyState extends State<JourneyUiBody> {
  List<JourneyHeader> items = [];

  @override
  void initState() {
    super.initState();
    _loadList();
  }

  _loadList() async {
    var list = await listAllJourneys();
    setState(() {
      items = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(
          child: ListView(
        shrinkWrap: true,
        scrollDirection: Axis.vertical,
        children: items.map((item) {
          return ListTile(
            leading: const Icon(Icons.description),
            title: Text(naiveDateToString(date: item.journeyDate)),
            subtitle: Text(item.start?.toLocal().toString() ?? ""),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (context) {
                  return JourneyInfoPage(
                    journeyHeader: item,
                  );
                },
              )).then((refresh) =>
                  (refresh != null && refresh) ? _loadList() : null);
            },
          );
        }).toList(),
      ))
    ]);
  }
}
