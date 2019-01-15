import 'package:flutter/material.dart';
import 'package:map_native/map_native.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final inline0 = new Card(
        child: new Stack(
      children: [
        new MapView(
            initialLocation: const LatLong(37.386051, -122.083855),
            inititialZoom: 9.0),
        new Align(
            alignment: Alignment.bottomRight,
            child: new Padding(
                padding: const EdgeInsets.all(16.0),
                child: new FloatingActionButton(
                    backgroundColor: Colors.white,
                    onPressed: () {},
                    child: new Icon(Icons.my_location, color: Colors.purple))))
      ],
    ));

    final inline1 = new Card(
        child: new Stack(
      children: [
        new MapView(
            initialLocation: const LatLong(37.386051, -122.083855),
            inititialZoom: 9.0),
        new Align(
            alignment: Alignment.bottomRight,
            child: new Padding(
                padding: const EdgeInsets.all(16.0),
                child: new FloatingActionButton(
                    backgroundColor: Colors.white,
                    onPressed: () {},
                    child: new Icon(Icons.my_location, color: Colors.purple))))
      ],
    ));

    return new MaterialApp(
        title: 'MapView Demo',
        theme: new ThemeData(
          primarySwatch: Colors.purple,
        ),
        home: new Scaffold(
            appBar: new AppBar(
              title: const Text("MapView Demo"),
            ),
            body: new Column(children: [
              new Padding(
                  padding: const EdgeInsets.all(4.0),
                  child:
                      new AspectRatio(child: inline0, aspectRatio: 16.0 / 9.0)),
              new Padding(
                  padding: const EdgeInsets.all(4.0),
                  child:
                      new AspectRatio(child: inline1, aspectRatio: 16.0 / 9.0)),
            ])));
  }
}