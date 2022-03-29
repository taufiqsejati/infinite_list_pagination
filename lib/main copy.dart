import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:infinite_list_pagination/model/article_data.dart';
import 'package:infinite_list_pagination/model/passenger_data.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentPage = 0;
  late int totalPages;

  // List<Passenger> passengers = [];
  List<Article> articles = [];
  final RefreshController refreshController =
      RefreshController(initialRefresh: true);
  Future<bool> getPassengerData({bool isRefresh = false}) async {
    if (isRefresh) {
      currentPage = 0;
    } else {
      if (currentPage >= totalPages) {
        refreshController.loadNoData();
        return false;
      }
    }

    // final Uri uri = Uri.parse(
    //     "https://api.instantwebtools.net/v1/passenger?page=$currentPage&size=10");
    final Uri uri2 = Uri.parse(
        "http://114.141.50.163:8080/api/listArticles?page=$currentPage&size=6");
    final response = await http.get(uri2);

    if (response.statusCode == 200) {
      // final result = welcomeFromJson(response.body);
      final result = articleFromJson(response.body);
      if (isRefresh) {
        articles = result.rows;
      } else {
        articles.addAll(result.rows);
      }

      currentPage++;

      totalPages = result.count;

      print(totalPages);
      setState(() {});
      return true;
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Infinite List Pagination'),
        ),
        body: SmartRefresher(
          controller: refreshController,
          header: const WaterDropHeader(),
          footer: CustomFooter(
            builder: ((context, mode) {
              Widget body;
              if (mode == LoadStatus.idle) {
                body = Text("pull up load");
              } else if (mode == LoadStatus.loading) {
                body = CupertinoActivityIndicator();
              } else if (mode == LoadStatus.failed) {
                body = Text("Load Failed!Click retry!");
              } else if (mode == LoadStatus.canLoading) {
                body = Text("release to load more");
              } else {
                body = Text("No more Data");
              }
              return Container(
                height: 55.0,
                child: Center(child: body),
              );
            }),
          ),
          enablePullUp: true,
          onRefresh: () async {
            final result = await getPassengerData(isRefresh: true);
            if (result) {
              refreshController.refreshCompleted();
            } else {
              refreshController.refreshFailed();
            }
          },
          onLoading: () async {
            final result = await getPassengerData();
            if (result) {
              refreshController.loadComplete();
            } else {
              refreshController.loadFailed();
            }
          },
          child: ListView(
            physics: const BouncingScrollPhysics(),
            shrinkWrap: true,
            // padding: const EdgeInsets.only(bottom: 16),
            children: [
              GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                // childAspectRatio: 1,
                padding: const EdgeInsets.all(15),
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: articles
                    .map((e) => Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                                color: Colors.blueAccent.shade100,
                                width: 0.75)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 125,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  image: DecorationImage(
                                      fit: BoxFit.cover,
                                      image: NetworkImage(
                                          'http://114.141.50.163:8080/uploads/news/${e.image}'))),
                            ),
                            Text(e.title),
                            Text(e.category),
                            Text(e.createdAt.toString()),
                          ],
                        )))
                    .toList(),
              ),
            ],
          ),

          // child: ListView.separated(
          //   shrinkWrap: true,
          //   itemBuilder: (context, index) {
          //     final article = articles[index];
          //     return ListTile(
          //       title: Text(article.title.toString()),
          //       subtitle: Text(article.category.toString()),
          //       trailing: Text(article.image.toString()),
          //     );
          //   },
          //   separatorBuilder: (context, index) => Divider(),
          //   itemCount: articles.length,
          // ),
        ));
  }
}
