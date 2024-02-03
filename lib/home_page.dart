import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'model/issue_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();
  TextEditingController searchTextEditingController = TextEditingController();
  bool isLoading = false;
  bool hasMore = true;
  int displayLimit = 6;
  List<Issue> allFetchedIssues = [];
  List<Issue> displayedIssues = [];

  void _onScroll() {
    // Check if we have reached the end of the list
    if(_scrollController.position.maxScrollExtent == _scrollController.offset){
      loadMoreIssues();
    }
  }

  Future fetchData() async {
    final url = Uri.parse('https://api.github.com/repos/flutter/flutter/issues');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List jsonResponse = json.decode(response.body);
      allFetchedIssues = jsonResponse.map((issue) => Issue.fromJson(issue)).toList();
      displayedIssues = allFetchedIssues.take(displayLimit).toList(); // Fetching the first 6(displayLimit) items
      setState(() {});
    }
  }

  void loadMoreIssues() {
    // Condition only work when there are more items to load
    if (displayedIssues.length < allFetchedIssues.length) {
      // Retrieving nextBatchSize
      int nextBatchSize = (displayedIssues.length + displayLimit > allFetchedIssues.length)
          ? allFetchedIssues.length - displayedIssues.length
          : displayLimit;

      List<Issue> nextBatch = allFetchedIssues.sublist(displayedIssues.length, displayedIssues.length + nextBatchSize);
      setState(() {
        displayedIssues.addAll(nextBatch); // Adding the nextBatch Issues to displayedIssues List
        // When there all the issues are fetched
        if (displayedIssues.length == allFetchedIssues.length) {
          hasMore = false;
        }
      });
    }
  }

  void filterIssuesByLabel(String label) {
    if (label.isEmpty) {
      // If the search query is empty, showing the initial batch of issues
      displayedIssues = allFetchedIssues.take(displayLimit).toList();
    }

    else {
      // Filtering issues by checking if the label list contains the search label
      displayedIssues = allFetchedIssues.where((issue) {
        return issue.labels.contains(label);
      }).toList();
    }

    // Assigning bool based on if there are more items to fetch
    setState(() {
      hasMore = displayedIssues.length >= displayLimit;
    });
  }

  String getIssuePreview(String body, {int previewLength = 40}) {
    // Check if the body is empty or null
    if (body.isEmpty) {
      return 'No description provided.';
    }
    // Return the beginning of the issue text up to the previewLength or the full body if it's shorter than the previewLength
    return body.length > previewLength ? '${body.substring(0, previewLength)}...' : body;
  }

  String convertToDateFormat(String dateToConvert){
    DateFormat inputFormat = DateFormat("yyyy-MM-ddTHH:mm:ssZ");
    DateFormat outputFormat = DateFormat("MM/dd/yyyy");

    DateTime dateTime = inputFormat.parseUtc(dateToConvert);
    String formattedDate = outputFormat.format(dateTime);

    return formattedDate;
  }

  Future refreshMethod() async{
    setState(() {
      hasMore = true;
      displayedIssues.clear();
      allFetchedIssues.clear();
    });

    await fetchData();
  }

  @override
  void initState() {
    super.initState();
    fetchData(); // Fetch initial data
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Always dispose of your controllers
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8,vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                text('Issues List', 30),
                const SizedBox(height: 20,),
                Material(
                  elevation: 5.0,
                  borderRadius: const BorderRadius.all(Radius.circular(30)),
                  child: SizedBox(
                    height: 45,
                    child: TextFormField(
                      controller: searchTextEditingController,
                      onChanged: (textTyped) {
                        filterIssuesByLabel(searchTextEditingController.text.trim());
                      },

                      decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search,color: Colors.black,),
                          hintText: "Search by Label",
                          hintStyle: const TextStyle(fontSize: 14),
                          suffixStyle: const TextStyle(color: Colors.black),
                          fillColor: Colors.white,
                          filled: true,
                          suffixIcon: searchTextEditingController.text.isEmpty ?
                          Container(width: 0) : IconButton(
                            icon: const Icon(Icons.close,color: Colors.black,),
                            onPressed: () {
                              searchTextEditingController.clear();
                              filterIssuesByLabel('');
                            },
                          ),
                          enabledBorder:OutlineInputBorder(
                              borderSide: BorderSide(
                                  width: 1.5,
                                  color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(10)
                          ),

                          focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  width: 1.5,
                                  color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(10)
                          ),
                          contentPadding: const EdgeInsets.all(0)),

                    ),
                  ), // Sea,
                ),
                const SizedBox(height: 20,),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: refreshMethod,
                    child: ListView.separated(
                      controller: _scrollController,
                      itemCount: displayedIssues.length + 1,
                      padding: const EdgeInsets.symmetric(horizontal: 8,vertical: 16),
                      itemBuilder: (context, index) {
                        if(index < displayedIssues.length){
                          final issue = displayedIssues[index];
                          return ListTile(
                            title: text(issue.title, 16),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  text2(getIssuePreview(issue.body), 15),
                                  const SizedBox(height: 10,),
                                  Wrap(
                                    spacing: 8.0,
                                    children: issue.labels.map<Widget>((label) => Chip(label: Text(label))).toList(),
                                  ),
                                ],
                              ),
                            ),

                            trailing: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                                text(convertToDateFormat(issue.createdAt), 16),
                                const SizedBox(height: 5),
                                text2(issue.userName, 15)
                              ],
                            ),
                          );
                        }

                        else{
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                                child: hasMore ? const CircularProgressIndicator() : text("No more data found", 15)
                            ),
                          );
                        }
                      },

                      separatorBuilder: (BuildContext context, int index) => const Divider(thickness: 1.5,height: 40,),
                    ),
                  ),
                )
              ],
            ),
          ),
        )
    );
  }

  Widget text(String text, double fontSize){
    return Text(
      text,
      style: GoogleFonts.raleway(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget text2(String text,double fontSize){
    return Text(
      text,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.montserrat(
        fontSize: fontSize,
        color: Colors.grey.shade800,
      ),
    );
  }
}
