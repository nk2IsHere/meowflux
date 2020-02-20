import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:meowflux/meowflux.dart';

import '2_watcher/values_actions.dart';
import '2_watcher/values_reducer.dart';
import '2_watcher/values_state.dart';
import '2_watcher/values_tester.dart';
import '2_watcher/values_tester_watcher.dart';
import '2_watcher/values_watcher.dart';
import '3_ui/note_list_actions.dart';
import '3_ui/note_list_reducer.dart';
import '3_ui/note_list_state.dart';
import '3_ui/note_list_worker.dart';
import '3_ui/note_model.dart';
import 'common/store_logger.dart';

import '1_basic_store/root_actions.dart';
import '1_basic_store/root_reducer.dart';
import '1_basic_store/root_state.dart';

void main() {
  test('1. basic counter test', () async {
    final store = Store(
      reducer: RootReducer,
      initialState: RootState(value: 0),
      middleware: [
        storeLogger
      ]
    );

    print('TEST retrieve value');
    final initialState = await store.getState();
    print('TEST value: $initialState');
    expect(initialState.value, 0);

    print('TEST edit value');
    await store.dispatch(RootIncreaseAction());
    await store.dispatch(RootIncreaseAction());
    await store.dispatch(RootDescreaseAction());
    
    print('TEST retrieve value');
    final resultState = await store.getState();
    print('TEST value: $resultState');
    expect(resultState.value, 1);
  });

  test('2. workers and watchers communication test', () async {
    final tester = ValuesTester();
    final store = Store(
      reducer: ValuesReducer,
      initialState: ValuesState(values: []),
      middleware: [
        storeLogger,
        WorkerMiddleware<ValuesState>([
          ValuesTesterWatcher(ValuesTesterWorker(tester)),
          ValuesWatcher(ValuesWorker)
        ])
      ]
    );

    print('TEST run worker:');
    store.dispatch(ValuesAddValueAction(value: "apple"));
    store.dispatch(ValuesAddValueAction(value: "koala"));
    store.dispatch(ValuesAddValueAction(value: "browney"));
    store.dispatch(ValuesAddValueAction(value: "watch"));

    print('TEST await all workers to finish');
    await Future.delayed(Duration(seconds: 7), () => "");

    print("TEST 'tester' shows this: ${tester.render()}");

    expect(tester.render(), "APPLEKOALABROWNEYWATCH");
  });

  test('3. worker and ui listening test', () async {
    //
    //Note that we are going to block the test thread, so all state updates are expected to arrive late
    //
    List<Note> ui = [];

    final store = Store(
      reducer: NoteListReducer,
      initialState: NoteListState(noteList: []),
      middleware: [
        storeLogger,
        WorkerMiddleware<NoteListState>([
          NoteListWatcher(NoteListWorker)
        ])
      ]
    );

    store.channel
      .listen((state) { 
        print('TEST update notes: ${state.noteList}');
        ui = state.noteList;
      });

    print('TEST update notes');
    store.dispatch(NoteListAddAction(id: 1, title: "1. Run test!", text: "Hope this works..."));
    store.dispatch(NoteListAddAction(id: 2, title: "2. Wait for test to finish!", text: "State is changing... at least"));
    store.dispatch(NoteListRemoveAction(id: 1));
    store.dispatch(NoteListAddAction(id: 1, title: "1. Run UI test!", text: "Hope this works #2..."));
    store.dispatch(NoteListAddAction(id: 3, title: "3. Finish!", text: "Your bets, please, gentlemen."));
    store.dispatch(NoteListEditAction(id: 1, text: "Hope workers work as intended..."));

    await Future.delayed(Duration(seconds: 3), () => "");
    print("TEST 'ui' shows this: $ui");
    expect(ui, [
      Note(id: 2, title: "2. Wait for test to finish!", text: "State is changing... at least"),
      Note(id: 1, title: "1. Run UI test!", text: "Hope workers work as intended..."),
      Note(id: 3, title: "3. Finish!", text: "Your bets, please, gentlemen.")
    ]);
  });
}
