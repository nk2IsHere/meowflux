import 'package:dataclass/dataclass.dart';
import 'package:meowchannel/meowchannel.dart';

import 'todo_actions.dart';
import 'todo_fakes.dart';

part 'todo_store.g.dart';

@dataClass 
class Todo extends _$Todo {
  final int id;
  final String title;
  final String text;

  Todo({
    this.id,
    this.title,
    this.text
  });
}

@dataClass
class TodoState extends _$TodoState {
  final List<Todo> todos;

  TodoState({
    this.todos = const <Todo>[]
  });
}

final Reducer<TodoState> TodoReducer = CombinedReducer<TodoState>([
  TypedReducer<TodoUpdateUiAction, TodoState>(
    (action, previousState) => previousState.copyWith(
      todos: action.todos
    )
  ),
  TypedReducer<TodoAddUiAction, TodoState>(
    (action, previousState) => previousState.copyWith(
      todos: [action.todo] + previousState.todos
    )
  ),
  TypedReducer<TodoEditUiAction, TodoState>(
    (action, previousState) => previousState.copyWith(
      todos: previousState.todos.map((todo) => todo.id == action.id? action.todo : todo)
        .toList()
    )
  ),
  TypedReducer<TodoRemoveUiAction, TodoState>(
    (action, previousState) => previousState.copyWith(
      todos: previousState.todos.where((todo) => todo.id != action.id)
        .toList()
    )
  ),
]);

Watcher<TodoAction, TodoState> TodoWatcher(
  Worker<TodoAction, TodoState> worker
) =>
  watcher(worker, (actionStream, context) {
    return actionStream.where((action) => action is TodoAction)
      .cast<TodoAction>();
  });

Worker<TodoAction, TodoState> TodoWorker(
  TodoRepository todoRepository
) =>
  CombinedWorker([
    TypedWorker<TodoAction, TodoListAction, TodoState>(worker((context, action) async {
      final todos = await todoRepository.list();

      context.put(TodoUpdateUiAction(
        todos: todos
      ));
    })),
    TypedWorker<TodoAction, TodoAddAction, TodoState>(worker((context, action) async {
      final todo = await todoRepository.add(
        id: action.id,
        title: action.title,
        text: action.text
      );

      context.put(TodoAddUiAction(
        todo: todo
      ));
    })),
    TypedWorker<TodoAction, TodoEditAction, TodoState>(worker((context, action) async {
      final todo = await todoRepository.edit(
        id: action.id,
        title: action.title,
        text: action.text
      );

      context.put(TodoEditUiAction(
        id: action.id,
        todo: todo
      ));
    })),
    TypedWorker<TodoAction, TodoRemoveAction, TodoState>(worker((context, action) async {
      await todoRepository.remove(
        id: action.id
      );

      context.put(TodoRemoveUiAction(
        id: action.id
      ));
    }))
  ]);