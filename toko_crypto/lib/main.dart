import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crypto Price List',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.teal).copyWith(secondary: Colors.orangeAccent),
        textTheme: TextTheme(
          bodyText1: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.black87),
          bodyText2: TextStyle(fontSize: 16.0, color: Colors.grey[600]),
        ),
      ),
      home: CryptoList(),
    );
  }
}

class CryptoList extends StatefulWidget {
  @override
  CryptoListState createState() => CryptoListState();
}

class CryptoListState extends State<CryptoList> {
  List _cryptoList = [];
  final _saved = Set<Map>();
  bool _loading = false;

  Future<void> getCryptoPrices() async {
    print('getting crypto prices');
    String apiURL = "https://api.coinlore.net/api/tickers/";
    setState(() {
      _loading = true;
    });

    try {
      Uri uri = Uri.parse(apiURL);
      http.Response response = await http.get(uri);

      if (response.statusCode == 200) {
        setState(() {
          _cryptoList = jsonDecode(response.body)['data'];
          _loading = false;
          print('Crypto data loaded: $_cryptoList');
        });
      } else {
        throw Exception('Failed to load crypto prices: ${response.statusCode}');
      }
    } catch (error) {
      setState(() {
        _loading = false;
      });
      print('Error fetching crypto prices: $error');
    }
  }

  String cryptoPrice(Map crypto) {
    int decimals = 2;
    int fac = pow(10, decimals).toInt();
    double d = double.parse(crypto['price_usd']);
    return "\$" + (d = (d * fac).round() / fac).toString();
  }

  CircleAvatar _getLeadingWidget(String name) {
    final Random random = Random();
    final Color color = Color.fromARGB(
      255,
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
    );
    return CircleAvatar(
      backgroundColor: color,
      child: Text(
        name[0],
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  _getMainBody() {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    } else {
      return RefreshIndicator(
        child: _buildCryptoList(),
        onRefresh: getCryptoPrices,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    getCryptoPrices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal, Colors.tealAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text('CryptoList', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        actions: <Widget>[
          IconButton(icon: Icon(Icons.list), onPressed: _pushSaved),
        ],
      ),
      body: _getMainBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: getCryptoPrices,
        child: Icon(Icons.refresh),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }

  void _pushSaved() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          final Iterable<ListTile> tiles = _saved.map(
            (crypto) {
              return ListTile(
                leading: _getLeadingWidget(crypto['name']),
                title: Text(
                  crypto['name'],
                  style: Theme.of(context).textTheme.bodyText1,
                ),
                subtitle: Text(
                  cryptoPrice(crypto),
                  style: Theme.of(context).textTheme.bodyText2,
                ),
              );
            },
          );
          final List<Widget> divided = ListTile.divideTiles(
            context: context,
            tiles: tiles,
          ).toList();
          return Scaffold(
            appBar: AppBar(
              title: const Text('Saved Cryptos'),
            ),
            body: ListView(children: divided),
          );
        },
      ),
    );
  }

  Widget _buildCryptoList() {
    return ListView.builder(
      itemCount: _cryptoList.length,
      padding: const EdgeInsets.all(16.0),
      itemBuilder: (context, i) {
        final index = i;
        print(index);
        return _buildRow(_cryptoList[index]);
      },
    );
  }

  Widget _buildRow(Map crypto) {
    final bool favourited = _saved.contains(crypto);

    void _fav() {
      setState(() {
        if (favourited) {
          _saved.remove(crypto);
        } else {
          _saved.add(crypto);
        }
      });
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      elevation: 10.0,
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 5.0),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade50, Colors.teal.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
          leading: _getLeadingWidget(crypto['name']),
          title: Text(
            crypto['name'],
            style: Theme.of(context).textTheme.bodyText1,
          ),
          subtitle: Text(
            cryptoPrice(crypto),
            style: Theme.of(context).textTheme.bodyText2,
          ),
          trailing: IconButton(
            icon: Icon(favourited ? Icons.favorite : Icons.favorite_border),
            color: favourited ? Colors.red : null,
            onPressed: _fav,
          ),
        ),
      ),
    );
  }
}
