import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:quiz_app/models/question_model.dart';
import 'package:quiz_app/screens/results.dart';
import 'package:quiz_app/service/database.dart';
import 'package:quiz_app/widgets/appbar.dart';
import 'package:quiz_app/widgets/quiz_play_widgets.dart';

class QuizPlay extends StatefulWidget {
  @override
  _QuizPlayState createState() => _QuizPlayState();
}

int _correct = 0;
int _incorrect = 0;
int _notAttempted = 0;
int total = 0;

/// Stream
Stream infoStream;

class _QuizPlayState extends State<QuizPlay> {
  var _connectionStatus = 'Unknown';
  Connectivity connectivity;
  ConnectivityResult connectivityResultStatus;
  StreamSubscription<ConnectivityResult> subscription;

  QuerySnapshot questionSnaphot;
  DatabaseService databaseService = new DatabaseService();

  bool isLoading = true;

  @override
  void initState() {
    connectivity = new Connectivity();
    subscription =
        connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      _connectionStatus = result.toString();
      print("_connectionStatus $_connectionStatus");
      if (result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile) {
        setState(() {
          connectivityResultStatus = result;
        });
      }
    });

    databaseService.getQuestionData().then((value) {
      questionSnaphot = value;
      print("valuevalue $value");
      _notAttempted = questionSnaphot.docs.length;
      _correct = 0;
      _incorrect = 0;
      isLoading = false;
      total = questionSnaphot.docs.length;
      setState(() {});
    });

    if (infoStream == null) {
      infoStream = Stream<List<int>>.periodic(Duration(milliseconds: 100), (x) {
        return [_correct, _incorrect];
      });
    }

    super.initState();
  }

  QuestionModel getQuestionModelFromDatasnapshot(
      DocumentSnapshot questionSnapshot) {
    QuestionModel questionModel = new QuestionModel();

    questionModel.question = questionSnapshot.data()["question"];

    /// shuffling the options
    List<String> options = [
      questionSnapshot.data()["option1"],
      questionSnapshot.data()["option2"],
      questionSnapshot.data()["option3"],
      questionSnapshot.data()["option4"]
    ];
    options.shuffle();

    questionModel.option1 = options[0];
    questionModel.option2 = options[1];
    questionModel.option3 = options[2];
    questionModel.option4 = options[3];
    questionModel.correctOption = questionSnapshot.data()["correct_answer"];
    questionModel.answered = false;

    return questionModel;
  }

  @override
  void dispose() {
    infoStream = null;
    subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppBarName(),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        brightness: Brightness.light,
        elevation: 0.0,
      ),
      floatingActionButton: Builder(builder: (BuildContext context) {
        // this.context = context;
        return FloatingActionButton(
          backgroundColor: Colors.green,
          child: Icon(
            Icons.check,
            color: Colors.white,
          ),
          onPressed: () {
            if (connectivityResultStatus == ConnectivityResult.none) {
              final snackBar = SnackBar(
                  content: Text('You are offline, Please try again later.'));

              Scaffold.of(context).showSnackBar(snackBar);
              return;
            }
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => Results(
                          correct: _correct,
                          incorrect: _incorrect,
                          total: total,
                        )));
          },
        );
      }),
      body: Container(
        child: Column(
          children: [
            questionSnaphot == null
                ? Container()
                : InfoHeader(
                    length: questionSnaphot.docs.length,
                  ),
            SizedBox(
              height: 10,
            ),
            questionSnaphot == null || questionSnaphot.docs.length == 0
                ? Container(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                : Container(
                    margin: EdgeInsets.only(top: 20.0),
                    height: 400.0,
                    child: PageView.builder(
                        itemCount: questionSnaphot.docs.length,
                        // shrinkWrap: true,
                        physics: ClampingScrollPhysics(),
                        itemBuilder: (context, index) {
                          return QuizPlayTile(
                            questionModel: getQuestionModelFromDatasnapshot(
                                questionSnaphot.docs[index]),
                            index: index,
                          );
                        }),
                  )
          ],
        ),
      ),
    );
  }
}

class InfoHeader extends StatefulWidget {
  final int length;

  InfoHeader({@required this.length});

  @override
  _InfoHeaderState createState() => _InfoHeaderState();
}

class _InfoHeaderState extends State<InfoHeader> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: infoStream,
        builder: (context, snapshot) {
          return snapshot.hasData
              ? Container(
                  height: 40,
                  margin: EdgeInsets.only(left: 14),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                    children: <Widget>[
                      NoOfQuestionTile(
                        text: "Total",
                        number: widget.length,
                      ),
                      NoOfQuestionTile(
                        text: "Correct",
                        number: _correct,
                      ),
                      NoOfQuestionTile(
                        text: "Incorrect",
                        number: _incorrect,
                      ),
                      NoOfQuestionTile(
                        text: "NotAttempted",
                        number: _notAttempted,
                      ),
                    ],
                  ),
                )
              : Container();
        });
  }
}

class QuizPlayTile extends StatefulWidget {
  final QuestionModel questionModel;
  final int index;

  QuizPlayTile({@required this.questionModel, @required this.index});

  @override
  _QuizPlayTileState createState() => _QuizPlayTileState();
}

class _QuizPlayTileState extends State<QuizPlayTile> {
  String optionSelected = "";

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Q${widget.index + 1} ${widget.questionModel.question}",
              style:
                  TextStyle(fontSize: 18, color: Colors.black.withOpacity(0.8)),
            ),
          ),
          SizedBox(
            height: 12,
          ),
          GestureDetector(
            onTap: () {
              if (!widget.questionModel.answered) {
                ///correct
                if (widget.questionModel.option1 ==
                    widget.questionModel.correctOption) {
                  setState(() {
                    optionSelected = widget.questionModel.option1;
                    widget.questionModel.answered = true;
                    _correct = _correct + 1;
                    _notAttempted = _notAttempted - 1;
                  });
                } else {
                  setState(() {
                    optionSelected = widget.questionModel.option1;
                    widget.questionModel.answered = true;
                    _incorrect = _incorrect + 1;
                    _notAttempted = _notAttempted - 1;
                  });
                }
              }
            },
            child: OptionTile(
              option: "A",
              description: "${widget.questionModel.option1}",
              correctAnswer: widget.questionModel.correctOption,
              optionSelected: optionSelected,
            ),
          ),
          SizedBox(
            height: 4,
          ),
          GestureDetector(
            onTap: () {
              if (!widget.questionModel.answered) {
                ///correct
                if (widget.questionModel.option2 ==
                    widget.questionModel.correctOption) {
                  setState(() {
                    optionSelected = widget.questionModel.option2;
                    widget.questionModel.answered = true;
                    _correct = _correct + 1;
                    _notAttempted = _notAttempted - 1;
                  });
                } else {
                  setState(() {
                    optionSelected = widget.questionModel.option2;
                    widget.questionModel.answered = true;
                    _incorrect = _incorrect + 1;
                    _notAttempted = _notAttempted - 1;
                  });
                }
              }
            },
            child: OptionTile(
              option: "B",
              description: "${widget.questionModel.option2}",
              correctAnswer: widget.questionModel.correctOption,
              optionSelected: optionSelected,
            ),
          ),
          SizedBox(
            height: 4,
          ),
          GestureDetector(
            onTap: () {
              if (!widget.questionModel.answered) {
                ///correct
                if (widget.questionModel.option3 ==
                    widget.questionModel.correctOption) {
                  setState(() {
                    optionSelected = widget.questionModel.option3;
                    widget.questionModel.answered = true;
                    _correct = _correct + 1;
                    _notAttempted = _notAttempted - 1;
                  });
                } else {
                  setState(() {
                    optionSelected = widget.questionModel.option3;
                    widget.questionModel.answered = true;
                    _incorrect = _incorrect + 1;
                    _notAttempted = _notAttempted - 1;
                  });
                }
              }
            },
            child: OptionTile(
              option: "C",
              description: "${widget.questionModel.option3}",
              correctAnswer: widget.questionModel.correctOption,
              optionSelected: optionSelected,
            ),
          ),
          SizedBox(
            height: 4,
          ),
          GestureDetector(
            onTap: () {
              if (!widget.questionModel.answered) {
                ///correct
                if (widget.questionModel.option4 ==
                    widget.questionModel.correctOption) {
                  setState(() {
                    optionSelected = widget.questionModel.option4;
                    widget.questionModel.answered = true;
                    _correct = _correct + 1;
                    _notAttempted = _notAttempted - 1;
                  });
                } else {
                  setState(() {
                    optionSelected = widget.questionModel.option4;
                    widget.questionModel.answered = true;
                    _incorrect = _incorrect + 1;
                    _notAttempted = _notAttempted - 1;
                  });
                }
              }
            },
            child: OptionTile(
              option: "D",
              description: "${widget.questionModel.option4}",
              correctAnswer: widget.questionModel.correctOption,
              optionSelected: optionSelected,
            ),
          ),
          SizedBox(
            height: 20,
          ),
        ],
      ),
    );
  }
}
